#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export STUB_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$STUB_BIN"
  export PATH="$STUB_BIN:$PATH"

  cat >"$STUB_BIN/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  "api repos/oisin-ee/agent/contents/mise/mise.toml?ref=main --jq .content")
    printf '%s\n' 'IyByZW5kZXJlZCBhZ2VudCBtYW5pZmVzdAo='
    ;;
  "auth token")
    printf '%s\n' 'ghp_test_token_secret'
    ;;
  *)
    printf 'unexpected gh invocation: %s\n' "$*" >&2
    exit 64
    ;;
esac
STUB
  chmod +x "$STUB_BIN/gh"
}

@test "agent manifest fetch keeps GitHub credentials out of external URLs and rendered output" {
  [ ! -e "$ROOT/.chezmoiexternal.toml.tmpl" ]

  run bash -c 'chezmoi execute-template < "$1"' _ "$ROOT/dot_config/mise/agent.toml.tmpl"

  [ "$status" -eq 0 ]
  [ "$output" = "# rendered agent manifest" ]
  [[ "$output" != *"ghp_test_token_secret"* ]]
  ! grep -q 'oauth2:' "$ROOT/dot_config/mise/agent.toml.tmpl"
}

@test "chezmoi never manages OpenCode auth or multi-auth account material" {
  grep -qxF '**/auth.json' "$ROOT/.chezmoiignore"
  grep -qxF '**/oc-codex-multi-auth-accounts.json' "$ROOT/.chezmoiignore"
}

@test "retired OpenCode user config is removed declaratively" {
  source_dir="$BATS_TEST_TMPDIR/source"
  destination_dir="$BATS_TEST_TMPDIR/home"
  state_file="$BATS_TEST_TMPDIR/chezmoi-state.boltdb"
  mkdir -p "$source_dir" "$destination_dir/.config/opencode/plugins"
  cp "$ROOT/.chezmoiremove" "$source_dir/"
  printf '%s\n' 'obsolete user config' >"$destination_dir/.config/opencode/opencode.json"
  printf '%s\n' 'obsolete generated plugin' >"$destination_dir/.config/opencode/plugins/generated.js"

  run chezmoi --config /dev/null --config-format toml --source "$source_dir" \
    --destination "$destination_dir" --persistent-state "$state_file" apply

  [ "$status" -eq 0 ]
  [ ! -e "$destination_dir/.config/opencode" ]
  [ ! -e "$ROOT/dot_config/opencode/opencode.jsonc" ]
  [ ! -e "$ROOT/dot_config/opencode/package.json" ]
}

@test "identical chezmoi applies isolate Moka Codex and OpenCode writes" {
  mise_install="$ROOT/run_after_03-mise-install.sh.tmpl"
  harness_sync="$ROOT/run_after_04-agent-harness-sync.sh.tmpl"
  moka_sync="$ROOT/run_after_05-moka-adapters.sh.tmpl"
  [ -f "$mise_install" ]
  [ -f "$harness_sync" ]
  [ -f "$moka_sync" ]

  source_dir="$BATS_TEST_TMPDIR/source"
  destination_dir="$BATS_TEST_TMPDIR/home"
  state_file="$BATS_TEST_TMPDIR/chezmoi-state.boltdb"
  mkdir -p "$source_dir" "$destination_dir"
  cp "$mise_install" "$harness_sync" "$moka_sync" "$source_dir/"
  export CLAUDE_CONFIG_DIR="$destination_dir/.claude"
  export CALLER_CODEX_HOME="$destination_dir/.codex"
  export CALLER_OPENCODE_CONFIG_DIR="$destination_dir/.config/opencode"
  export CODEX_HOME="$CALLER_CODEX_HOME"
  export OPENCODE_CONFIG_DIR="$CALLER_OPENCODE_CONFIG_DIR"
  mkdir -p "$CODEX_HOME" "$OPENCODE_CONFIG_DIR"
  printf '%s\n' 'keep-codex' >"$CODEX_HOME/sentinel"
  printf '%s\n' 'keep-opencode' >"$OPENCODE_CONFIG_DIR/sentinel"

  cat >"$STUB_BIN/mise" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$BATS_TEST_TMPDIR/mise-calls"
case "$*" in
  "install -y")
    ;;
  "which yeet")
    printf '%s\n' '/managed/mise/yeet'
    ;;
  "exec -- yeet agent sync")
    ;;
  "which nubx")
    printf '%s\n' '/managed/mise/nubx'
    ;;
  "exec -- nubx -y -p @oisincoveney/pipeline@3.24.3 --cwd $HOME moka init")
    [ "$CODEX_HOME" != "$CALLER_CODEX_HOME" ]
    [ "$OPENCODE_CONFIG_DIR" != "$CALLER_OPENCODE_CONFIG_DIR" ]
    printf '%s|%s\n' "$CODEX_HOME" "$OPENCODE_CONFIG_DIR" >>"$BATS_TEST_TMPDIR/moka-isolation-roots"
    mkdir -p "$CLAUDE_CONFIG_DIR"
    printf '{}\n' >"$CLAUDE_CONFIG_DIR/settings.json"
    ;;
  *)
    printf 'unexpected mise invocation: %s\n' "$*" >&2
    exit 64
    ;;
esac
STUB
  chmod +x "$STUB_BIN/mise"

  run chezmoi --config /dev/null --config-format toml --source "$source_dir" \
    --destination "$destination_dir" --persistent-state "$state_file" apply
  [ "$status" -eq 0 ]

  run chezmoi --config /dev/null --config-format toml --source "$source_dir" \
    --destination "$destination_dir" --persistent-state "$state_file" apply
  [ "$status" -eq 0 ]

  [ "$(cat "$CODEX_HOME/sentinel")" = "keep-codex" ]
  [ "$(cat "$OPENCODE_CONFIG_DIR/sentinel")" = "keep-opencode" ]
  [ "$(wc -l <"$BATS_TEST_TMPDIR/moka-isolation-roots")" -eq 2 ]
  while IFS='|' read -r isolated_codex isolated_opencode; do
    [ ! -e "$isolated_codex" ]
    [ ! -e "$isolated_opencode" ]
  done <"$BATS_TEST_TMPDIR/moka-isolation-roots"

  [ "$(cat "$BATS_TEST_TMPDIR/mise-calls")" = "install -y
which yeet
exec -- yeet agent sync
which nubx
exec -- nubx -y -p @oisincoveney/pipeline@3.24.3 --cwd $HOME moka init
install -y
which yeet
exec -- yeet agent sync
which nubx
exec -- nubx -y -p @oisincoveney/pipeline@3.24.3 --cwd $HOME moka init" ]
}

@test "managed sync scripts fail when mise is unavailable" {
  empty_bin="$BATS_TEST_TMPDIR/empty-bin"
  mkdir -p "$empty_bin"

  for template in \
    "$ROOT/run_after_03-mise-install.sh.tmpl" \
    "$ROOT/run_after_04-agent-harness-sync.sh.tmpl" \
    "$ROOT/run_after_05-moka-adapters.sh.tmpl"; do
    rendered="$BATS_TEST_TMPDIR/$(basename "${template%.tmpl}")"
    chezmoi execute-template <"$template" >"$rendered"

    run /usr/bin/env PATH="$empty_bin" /bin/bash "$rendered"

    [ "$status" -ne 0 ]
    [[ "$output" == *"mise not installed"* ]]
    [[ "$output" != *"skipping"* ]]
  done
}

@test "agent harness sync fails when yeet is unavailable through mise" {
  cat >"$STUB_BIN/mise" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  "which yeet")
    exit 1
    ;;
  *)
    printf 'unexpected mise invocation: %s\n' "$*" >&2
    exit 64
    ;;
esac
STUB
  chmod +x "$STUB_BIN/mise"

  rendered="$BATS_TEST_TMPDIR/agent-harness-sync.sh"
  chezmoi execute-template <"$ROOT/run_after_04-agent-harness-sync.sh.tmpl" >"$rendered"

  run bash "$rendered"

  [ "$status" -ne 0 ]
  [[ "$output" == *"yeet not installed through mise"* ]]
  [[ "$output" != *"skipping"* ]]
}

@test "agent harness sync resolves yeet through the managed mise toolset" {
  cat >"$STUB_BIN/mise" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s|%s\n' "${MISE_SYSTEM_CONFIG_FILE:-unset}" "$*" >>"$BATS_TEST_TMPDIR/mise-calls"
case "$*" in
  "which yeet")
    printf '%s\n' '/managed/mise/yeet'
    ;;
  "exec -- yeet agent sync")
    printf '%s\n' 'managed yeet sync'
    ;;
  *)
    printf 'unexpected mise invocation: %s\n' "$*" >&2
    exit 64
    ;;
esac
STUB
  cat >"$STUB_BIN/yeet" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' 'stale PATH yeet invoked' >&2
exit 99
STUB
  chmod +x "$STUB_BIN/mise" "$STUB_BIN/yeet"

  rendered="$BATS_TEST_TMPDIR/agent-harness-sync.sh"
  chezmoi execute-template <"$ROOT/run_after_04-agent-harness-sync.sh.tmpl" >"$rendered"

  run bash "$rendered"

  [ "$status" -eq 0 ]
  [[ "$output" == *"managed yeet sync"* ]]
  [[ "$output" != *"stale PATH yeet invoked"* ]]
  [ "$(cat "$BATS_TEST_TMPDIR/mise-calls")" = "$HOME/.config/mise/agent.toml|which yeet
$HOME/.config/mise/agent.toml|exec -- yeet agent sync" ]
}


@test "Moka adapter sync force-replaces newer Claude adapters" {
  claude_root="$BATS_TEST_TMPDIR/claude"
  caller_codex="$BATS_TEST_TMPDIR/codex"
  caller_opencode="$BATS_TEST_TMPDIR/opencode"
  mkdir -p "$claude_root/commands" "$caller_codex" "$caller_opencode"
  cat >"$claude_root/commands/moka-execute.md" <<'MOKA'
<!-- Generated by @oisin-ee/moka. -->
<!-- @oisin-ee/moka:host=claude-code -->
MOKA
  printf '%s\n' 'keep-codex' >"$caller_codex/sentinel"
  printf '%s\n' 'keep-opencode' >"$caller_opencode/sentinel"
  export CALLER_CODEX_HOME="$caller_codex"
  export CALLER_OPENCODE_CONFIG_DIR="$caller_opencode"

  cat >"$STUB_BIN/mise" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s|%s\n' "${MISE_SYSTEM_CONFIG_FILE:-unset}" "$*" >>"$BATS_TEST_TMPDIR/mise-calls"
case "$*" in
  "which nubx")
    printf '%s\n' '/managed/mise/nubx'
    ;;
  "exec -- nubx -y -p @oisincoveney/pipeline@3.24.3 --cwd $HOME moka init --force")
    [ "$CODEX_HOME" != "$CALLER_CODEX_HOME" ]
    [ "$OPENCODE_CONFIG_DIR" != "$CALLER_OPENCODE_CONFIG_DIR" ]
    ;;
  *)
    printf 'unexpected mise invocation: %s\n' "$*" >&2
    exit 64
    ;;
esac
STUB
  chmod +x "$STUB_BIN/mise"

  rendered="$BATS_TEST_TMPDIR/moka-adapters.sh"
  chezmoi execute-template <"$ROOT/run_after_05-moka-adapters.sh.tmpl" >"$rendered"

  run env CLAUDE_CONFIG_DIR="$claude_root" CODEX_HOME="$caller_codex" \
    OPENCODE_CONFIG_DIR="$caller_opencode" bash "$rendered"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Migrating Claude adapter ownership"* ]]
  [ "$(cat "$caller_codex/sentinel")" = "keep-codex" ]
  [ "$(cat "$caller_opencode/sentinel")" = "keep-opencode" ]
  [ "$(cat "$BATS_TEST_TMPDIR/mise-calls")" = "$HOME/.config/mise/agent.toml|which nubx
$HOME/.config/mise/agent.toml|exec -- nubx -y -p @oisincoveney/pipeline@3.24.3 --cwd $HOME moka init --force" ]
}

@test "Moka adapter sync fails when nubx is unavailable through mise" {
  cat >"$STUB_BIN/mise" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  "which nubx")
    exit 1
    ;;
  *)
    printf 'unexpected mise invocation: %s\n' "$*" >&2
    exit 64
    ;;
esac
STUB
  chmod +x "$STUB_BIN/mise"

  rendered="$BATS_TEST_TMPDIR/moka-adapters.sh"
  chezmoi execute-template <"$ROOT/run_after_05-moka-adapters.sh.tmpl" >"$rendered"

  run bash "$rendered"

  [ "$status" -ne 0 ]
  [[ "$output" == *"nubx not installed through mise"* ]]
  [[ "$output" != *"skipping"* ]]
}

@test "harness settings are owned only by yeet" {
  [ ! -e "$ROOT/dot_codex/modify_private_config.toml" ]
  [ ! -e "$ROOT/dot_claude/modify_private_settings.json" ]
}

@test "SSH config bootstrap preserves tool-generated hosts" {
  source_dir="$BATS_TEST_TMPDIR/source"
  destination_dir="$BATS_TEST_TMPDIR/home"
  state_file="$BATS_TEST_TMPDIR/chezmoi-state.boltdb"
  mkdir -p "$source_dir/private_dot_ssh" "$destination_dir/.ssh"
  cp "$ROOT/private_dot_ssh/create_config.tmpl" "$source_dir/private_dot_ssh/"
  cat >"$destination_dir/.ssh/config" <<'CONFIG'
# entry generated by okteto
Host runtime.okteto
  HostName localhost
  Port 54321
CONFIG

  run chezmoi --config /dev/null --config-format toml --source "$source_dir" \
    --destination "$destination_dir" --persistent-state "$state_file" apply

  [ "$status" -eq 0 ]
  grep -qxF 'Host runtime.okteto' "$destination_dir/.ssh/config"
  grep -qxF '  Port 54321' "$destination_dir/.ssh/config"
}

@test "repository tests are never deployed into home" {
  grep -qxF 'tests' "$ROOT/.chezmoiignore"
}
