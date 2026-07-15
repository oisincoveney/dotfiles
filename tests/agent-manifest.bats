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
