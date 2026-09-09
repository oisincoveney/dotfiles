#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export STUB_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$STUB_BIN"
  export PATH="$STUB_BIN:$PATH"
}

@test "mise bootstrap installs the pinned version through the official installer" {
  pinned="$(awk -F'"' '/^version = /{print $2}' "$ROOT/.chezmoidata.toml")"
  [ -n "$pinned" ]

  cat >"$STUB_BIN/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CURL_CALLS"
printf '%s\n' 'printf "MISE_VERSION=%s MISE_INSTALL_PATH=%s MISE_INSTALL_SKIP_IF_EXISTS=%s\\n" "$MISE_VERSION" "$MISE_INSTALL_PATH" "$MISE_INSTALL_SKIP_IF_EXISTS"'
printf '%s\n' 'mkdir -p "$(dirname "$MISE_INSTALL_PATH")"'
printf '%s\n' 'printf "#!/bin/sh\necho stub-mise\n" >"$MISE_INSTALL_PATH"; chmod +x "$MISE_INSTALL_PATH"'
STUB
  chmod +x "$STUB_BIN/curl"
  export CURL_CALLS="$BATS_TEST_TMPDIR/curl-calls"

  rendered="$BATS_TEST_TMPDIR/mise-bootstrap.sh"
  chezmoi --source "$ROOT" execute-template <"$ROOT/run_onchange_after_00-mise-bootstrap.sh.tmpl" >"$rendered"

  HOME="$BATS_TEST_TMPDIR/home" run bash "$rendered"

  [ "$status" -eq 0 ]
  [ "$(cat "$CURL_CALLS")" = "-fsSL https://mise.run" ]
  [[ "$output" == *"MISE_VERSION=v$pinned MISE_INSTALL_PATH=$BATS_TEST_TMPDIR/home/.local/bin/mise MISE_INSTALL_SKIP_IF_EXISTS=1"* ]]
  [[ "$output" == *"stub-mise"* ]]
}

@test "no other installer owns the mise binary" {
  ! grep -q '^brew "mise"' "$ROOT/dot_config/Brewfile"
  ! grep -q 'mise.run' "$ROOT/run_once_01-install-packages.sh.tmpl"
}

@test "mise bootstrap runs after the package step that installs curl and before the tool sync" {
  # chezmoi runs before_ scripts, then in-place scripts, then after_ scripts, each phase in
  # target-name order. The package step installs curl, which the bootstrap needs, and the tool
  # sync needs the bootstrapped binary, so the run order must be packages, bootstrap, tool sync.
  bootstrap="$(cd "$ROOT" && ls run_*mise-bootstrap.sh.tmpl)"
  packages="$(cd "$ROOT" && ls run_*install-packages.sh.tmpl)"
  toolsync="$(cd "$ROOT" && ls run_*mise-install.sh.tmpl)"
  [ "$(wc -l <<<"$bootstrap")" -eq 1 ]

  # Sort key that reproduces chezmoi's run order: phase first, then target name.
  run_key() {
    local phase=1
    [[ "$1" == run_*before_* ]] && phase=0
    [[ "$1" == run_*after_* ]] && phase=2
    printf '%s %s\n' "$phase" "$(sed -E 's/^run_(once_|onchange_)?(before_|after_)?//; s/\.tmpl$//' <<<"$1")"
  }
  [[ "$(run_key "$packages")" < "$(run_key "$bootstrap")" ]]
  [[ "$(run_key "$bootstrap")" < "$(run_key "$toolsync")" ]]
}
