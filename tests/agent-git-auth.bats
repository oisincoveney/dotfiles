#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
}

@test "all interactive agent aliases enter the scoped Git launcher" {
  run grep -E '^alias (cc|co|ki|oc|pi)="agent-run ' "$ROOT/dot_config/zsh/aliases.zsh"

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
}

@test "chezmoi installs agent-run as the shared Agent repository launcher" {
  run cat "$ROOT/dot_local/bin/symlink_agent-run.tmpl"

  [ "$status" -eq 0 ]
  [ "$output" = '{{ .chezmoi.homeDir }}/.pi/agent/bin/agent-run' ]
}

@test "ordinary git aliases remain outside the scoped launcher" {
  run grep -E '^alias (amend|commit|pull|push)=' "$ROOT/dot_config/zsh/aliases.zsh"

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 4 ]
  [[ "$output" != *"agent-run"* ]]
}
