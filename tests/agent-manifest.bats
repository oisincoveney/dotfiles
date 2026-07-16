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
  "api repos/oisin-ee/agent/commits/main --jq .sha")
    printf '%s\n' '8e8212534439dc810fc5d350129119f307c8ad62'
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
  chezmoi execute-template <"$ROOT/run_onchange_after_04-agent-harness-sync.sh.tmpl" >"$rendered"

  run bash "$rendered"

  [ "$status" -eq 0 ]
  [[ "$output" == *"managed yeet sync"* ]]
  [[ "$output" != *"stale PATH yeet invoked"* ]]
  [ "$(cat "$BATS_TEST_TMPDIR/mise-calls")" = "$HOME/.config/mise/agent.toml|which yeet
$HOME/.config/mise/agent.toml|exec -- yeet agent sync" ]
}
