#!/usr/bin/env bats
# shellcheck shell=bash disable=SC2030,SC2031

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export CMD_LOG="$BATS_TEST_TMPDIR/commands.log"
  export CAPTURE_DIR="$BATS_TEST_TMPDIR/captures"
  export STUB_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$STUB_BIN" "$CAPTURE_DIR"
  : >"$CMD_LOG"

  export PATH="$STUB_BIN:$PATH"
  export MAC_BURST_LIB="$ROOT/dot_local/share/mac-burst/lib.sh"
  export MAC_BURST_VALUES_DIR="$ROOT/dot_local/share/mac-burst"
  export MAC_BURST_STATE_DIR="$BATS_TEST_TMPDIR/state"
  export MAC_BURST_GITHUB_CONFIG_URL="https://github.com/oisin-ee"
  export STUB_K3D_CLUSTER_EXISTS=0

  write_stub gh <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  "auth token") printf '%s\n' 'ghp_test_token_secret' ;;
  "api user --jq .login") printf '%s\n' 'oisin-bot' ;;
  *) echo "gh $*" >>"$CMD_LOG" ;;
esac
STUB

  write_stub docker <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
printf 'docker %s\n' "$*" >>"$CMD_LOG"
STUB

  write_stub k3d <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'k3d %s\n' "$*" >>"$CMD_LOG"
if [ "${1:-}" = "cluster" ] && [ "${2:-}" = "list" ]; then
  if [ "${STUB_K3D_CLUSTER_EXISTS:-1}" = 1 ]; then
    printf 'NAME\tSERVERS\tAGENTS\nmac-burst\t1/1\t0/0\n'
    exit 0
  fi
  exit 1
fi
if [ "${1:-}" = "kubeconfig" ] && [ "${2:-}" = "write" ]; then
  printf 'apiVersion: v1\nclusters: []\ncontexts: []\n'
fi
STUB

  write_stub helm <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'helm %s\n' "$*" >>"$CMD_LOG"
if [ "${1:-}" = "show" ] && [ "${2:-}" = "chart" ]; then
  printf 'Digest: sha256:testdigest\n'
  exit 0
fi
if [ "${1:-}" = "upgrade" ]; then
  release="${3:-unknown}"
  if [ "${STUB_HELM_FAIL_RELEASE:-}" = "$release" ]; then
    exit 42
  fi
  index=0
  for arg in "$@"; do
    if [ "$arg" = "--values" ]; then
      index=$((index + 1))
      continue
    fi
    if [ "$index" -gt 0 ]; then
      cp "$arg" "$CAPTURE_DIR/${release}.values.yaml"
      index=0
    fi
  done
fi
STUB

  write_stub kubectl <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'kubectl %s\n' "$*" >>"$CMD_LOG"
if [ "${1:-}" = "apply" ]; then
  cat >/dev/null
  exit 0
fi
if [ "${1:-}" = "get" ] && [ "${2:-}" = "pods" ]; then
  if [ "${STUB_ACTIVE_PODS:-0}" = 1 ]; then
    printf 'runner-a 1/1 Running 0 10s\n'
  else
    printf 'runner-done 0/1 Succeeded 0 10s\n'
  fi
  exit 0
fi
if [ "${1:-}" = "get" ]; then
  printf 'Running\n'
fi
STUB

  write_stub caffeinate <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'caffeinate %s\n' "$*" >>"$CMD_LOG"
STUB
}

teardown() {
  if [ -d "${MAC_BURST_STATE_DIR:-}" ] && [ -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]; then
    pid="$(cat "$MAC_BURST_STATE_DIR/caffeinate.pid")"
    if [ "$pid" != "$$" ]; then
      kill "$pid" 2>/dev/null || true
    fi
  fi
  pids="$(jobs -pr || true)"
  if [ -n "$pids" ]; then
    while IFS= read -r pid; do
      kill "$pid" 2>/dev/null || true
    done <<EOF_PIDS
$pids
EOF_PIDS
  fi
  wait 2>/dev/null || true
}

write_stub() {
  local name="$1"
  cat >"$STUB_BIN/$name"
  chmod +x "$STUB_BIN/$name"
}

assert_output_contains() {
  local expected="$1"
  [[ "$output" == *"$expected"* ]]
}

refute_output_contains() {
  local unexpected="$1"
  [[ "$output" != *"$unexpected"* ]]
}

refute_file_contains() {
  local unexpected="$1" file="$2"
  if grep -q "$unexpected" "$file"; then
    printf 'unexpected content found in %s: %s\n' "$file" "$unexpected" >&2
    return 1
  fi
}

@test "mac-burst-up canary renders pinned ARC/k3d values without leaking gh token" {
  run "$ROOT/dot_local/bin/executable_mac-burst-up" --mode canary

  [ "$status" -eq 0 ]
  refute_output_contains 'ghp_test_token_secret'
  refute_file_contains 'ghp_test_token_secret' "$CMD_LOG"
  grep -q 'k3d cluster create mac-burst' "$CMD_LOG"
  grep -q -- '--image rancher/k3s:v1.36.2-k3s1' "$CMD_LOG"
  grep -q -- '--kubeconfig-switch-context=false' "$CMD_LOG"
  grep -q -- '--kubeconfig-update-default=false' "$CMD_LOG"
  grep -q 'helm upgrade --install arc-controller' "$CMD_LOG"
  grep -q 'helm upgrade --install arc-runner-set' "$CMD_LOG"
  grep -q -- '--version 0.14.2' "$CMD_LOG"
  grep -q -- '--atomic --wait' "$CMD_LOG"
  grep -q 'docker login ghcr.io --username oisin-bot --password-stdin' "$CMD_LOG"
  grep -q 'runnerGroup: Mac Burst' "$CAPTURE_DIR/arc-runner-set.values.yaml"
  grep -q 'runnerScaleSetName: infra-k8s-runner' "$CAPTURE_DIR/arc-runner-set.values.yaml"
  grep -q 'maxRunners: 1' "$CAPTURE_DIR/arc-runner-set.values.yaml"
  grep -q 'mac-burst-canary' "$CAPTURE_DIR/arc-runner-set.values.yaml"
  grep -q 'name: docker-storage' "$CAPTURE_DIR/arc-runner-set.values.yaml"
  grep -q 'sizeLimit: 10Gi' "$CAPTURE_DIR/arc-runner-set.values.yaml"
  grep -q 'memory: 4Gi' "$CAPTURE_DIR/arc-runner-set.values.yaml"
  grep -q 'memory: 2Gi' "$CAPTURE_DIR/arc-runner-set.values.yaml"
}

@test "mac-burst-up failed startup removes kubeconfig, temp creds, caffeinate, and cluster" {
  export STUB_HELM_FAIL_RELEASE=arc-runner-set

  run "$ROOT/dot_local/bin/executable_mac-burst-up" --mode production

  [ "$status" -ne 0 ]
  [ ! -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ ! -d "$MAC_BURST_STATE_DIR/docker-config" ]
  [ ! -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
  grep -q 'k3d cluster delete mac-burst' "$CMD_LOG"
}

@test "mac-burst-down refuses active pods unless forced" {
  export STUB_ACTIVE_PODS=1
  mkdir -p "$MAC_BURST_STATE_DIR"
  printf 'apiVersion: v1\n' >"$MAC_BURST_STATE_DIR/kubeconfig"

  run "$ROOT/dot_local/bin/executable_mac-burst-down"

  [ "$status" -ne 0 ]
  assert_output_contains 'active runner pods remain'
  refute_file_contains 'helm uninstall' "$CMD_LOG"
  refute_file_contains 'k3d cluster delete' "$CMD_LOG"
}

@test "mac-burst-down --force uninstalls scale set before controller and deletes local state" {
  export STUB_ACTIVE_PODS=1
  mkdir -p "$MAC_BURST_STATE_DIR/docker-config"
  printf 'apiVersion: v1\n' >"$MAC_BURST_STATE_DIR/kubeconfig"
  printf '999999\n' >"$MAC_BURST_STATE_DIR/caffeinate.pid"

  run "$ROOT/dot_local/bin/executable_mac-burst-down" --force

  [ "$status" -eq 0 ]
  [ ! -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ ! -d "$MAC_BURST_STATE_DIR/docker-config" ]
  [ ! -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
  python3 - "$CMD_LOG" <<'PY'
import sys
log = open(sys.argv[1]).read()
scale = log.index('helm uninstall arc-runner-set')
controller = log.index('helm uninstall arc-controller')
cluster = log.index('k3d cluster delete mac-burst')
assert scale < controller < cluster, log
PY
}

@test "mac-burst-status reports cluster runner pods caffeinate and chart digest" {
  export STUB_K3D_CLUSTER_EXISTS=1
  mkdir -p "$MAC_BURST_STATE_DIR"
  printf 'apiVersion: v1\n' >"$MAC_BURST_STATE_DIR/kubeconfig"
  printf '%s\n' "$$" >"$MAC_BURST_STATE_DIR/caffeinate.pid"

  run "$ROOT/dot_local/bin/executable_mac-burst-status"

  [ "$status" -eq 0 ]
  assert_output_contains 'cluster:'
  assert_output_contains 'runner:'
  assert_output_contains 'pods:'
  assert_output_contains 'caffeinate:'
  assert_output_contains 'digest:'
  assert_output_contains 'sha256:'
}
