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
if [ "${1:-}" = "cluster" ] && [ "${2:-}" = "create" ] && [ "${STUB_K3D_FAIL_CREATE:-0}" = 1 ]; then
  exit 46
fi
if [ "${1:-}" = "cluster" ] && [ "${2:-}" = "delete" ] && [ "${STUB_K3D_FAIL_DELETE:-0}" = 1 ]; then
  exit 45
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
if [ "${1:-}" = "uninstall" ] && [ "${STUB_HELM_FAIL_UNINSTALL_RELEASE:-}" = "${2:-}" ]; then
  exit 43
fi
if [ "${1:-}" = "uninstall" ] && [ "${STUB_HELM_REQUIRE_KUBECONFIG:-0}" = 1 ] \
  && [ ! -s "${KUBECONFIG:-}" ]; then
  exit 48
fi
if [ "${1:-}" = "uninstall" ] && [ "${STUB_HELM_NOT_FOUND_RELEASE:-}" = "${2:-}" ]; then
  case " $* " in
    *' --ignore-not-found '*) exit 0 ;;
    *) exit 44 ;;
  esac
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
  if [ "${STUB_KUBECTL_FAIL_PODS:-0}" = 1 ]; then
    printf 'runner pod discovery unavailable\n' >&2
    exit 47
  fi
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

@test "mac-burst-up cluster-create failure skips Helm and deletes a possible partial cluster" {
  export STUB_K3D_FAIL_CREATE=1
  export STUB_HELM_REQUIRE_KUBECONFIG=1

  run "$ROOT/dot_local/bin/executable_mac-burst-up" --mode canary

  [ "$status" -eq 46 ]
  refute_file_contains 'helm uninstall' "$CMD_LOG"
  grep -q 'k3d cluster delete mac-burst' "$CMD_LOG"
  [ ! -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
}

@test "mac-burst-up reports partial cluster retention when create and delete both fail" {
  export STUB_K3D_FAIL_CREATE=1
  export STUB_K3D_FAIL_DELETE=1
  export STUB_HELM_REQUIRE_KUBECONFIG=1

  run "$ROOT/dot_local/bin/executable_mac-burst-up" --mode canary

  [ "$status" -eq 46 ]
  assert_output_contains 'startup cluster deletion failed; retained cluster=mac-burst'
  assert_output_contains 'kubeconfig not created; retry k3d cluster delete mac-burst'
  assert_output_contains "startup-phase=$MAC_BURST_STATE_DIR/startup-phase"
  [ "$(cat "$MAC_BURST_STATE_DIR/startup-phase")" = 'cluster-delete-required' ]
  refute_file_contains 'helm uninstall' "$CMD_LOG"
  grep -q 'k3d cluster delete mac-burst' "$CMD_LOG"
}

@test "mac-burst-up removes local credentials and caffeinate after pre-kubeconfig failure" {
  export STUB_K3D_FAIL_CREATE=1
  export STUB_HELM_REQUIRE_KUBECONFIG=1

  run "$ROOT/dot_local/bin/executable_mac-burst-up" --mode capacity

  [ "$status" -eq 46 ]
  [ ! -e "$MAC_BURST_STATE_DIR/docker-config" ]
  [ -z "$(find "$MAC_BURST_STATE_DIR" -maxdepth 1 -name 'docker-config.*' -print -quit 2>/dev/null)" ]
  [ ! -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
  [ ! -d "$MAC_BURST_STATE_DIR" ]
}

@test "mac-burst-up failed startup removes kubeconfig, temp creds, caffeinate, and cluster" {
  export STUB_HELM_FAIL_RELEASE=arc-runner-set

  run "$ROOT/dot_local/bin/executable_mac-burst-up" --mode production

  [ "$status" -eq 42 ]
  [ ! -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ ! -d "$MAC_BURST_STATE_DIR/docker-config" ]
  [ ! -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
  grep -q 'k3d cluster delete mac-burst' "$CMD_LOG"
}

@test "mac-burst-up retains cluster and local state when startup Helm cleanup fails" {
  export STUB_HELM_FAIL_RELEASE=arc-runner-set
  export STUB_HELM_FAIL_UNINSTALL_RELEASE=arc-controller

  run "$ROOT/dot_local/bin/executable_mac-burst-up" --mode production

  [ "$status" -eq 42 ]
  assert_output_contains 'controller uninstall failed; retained controller=arc-controller'
  assert_output_contains 'retained controller=arc-controller cluster=mac-burst'
  assert_output_contains "kubeconfig=$MAC_BURST_STATE_DIR/kubeconfig"
  assert_output_contains "state=$MAC_BURST_STATE_DIR"
  [ -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ -L "$MAC_BURST_STATE_DIR/docker-config" ]
  [ -f "$MAC_BURST_STATE_DIR/scale-set-values.yaml" ]
  [ -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
  refute_file_contains 'helm uninstall arc-runner-set' "$CMD_LOG"
  grep -q 'helm uninstall arc-controller' "$CMD_LOG"
  refute_file_contains 'k3d cluster delete' "$CMD_LOG"
}

@test "mac-burst-up retains retry state but removes disposable local state when startup cluster deletion fails" {
  export STUB_HELM_FAIL_RELEASE=arc-runner-set
  export STUB_K3D_FAIL_DELETE=1

  run "$ROOT/dot_local/bin/executable_mac-burst-up" --mode production

  [ "$status" -eq 42 ]
  assert_output_contains 'startup cluster deletion failed; retained cluster=mac-burst'
  assert_output_contains "kubeconfig=$MAC_BURST_STATE_DIR/kubeconfig"
  assert_output_contains "state=$MAC_BURST_STATE_DIR"
  [ -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ ! -e "$MAC_BURST_STATE_DIR/docker-config" ]
  [ ! -f "$MAC_BURST_STATE_DIR/scale-set-values.yaml" ]
  [ ! -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
  [ "$(cat "$MAC_BURST_STATE_DIR/startup-phase")" = 'cluster-delete-required' ]
  refute_file_contains 'helm uninstall arc-runner-set' "$CMD_LOG"
  grep -q 'helm uninstall arc-controller' "$CMD_LOG"
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

@test "mac-burst-down refuses unknown pod state even when forced" {
  export STUB_KUBECTL_FAIL_PODS=1
  mkdir -p "$MAC_BURST_STATE_DIR/docker-config.test"
  ln -s "$MAC_BURST_STATE_DIR/docker-config.test" "$MAC_BURST_STATE_DIR/docker-config"
  printf 'apiVersion: v1\n' >"$MAC_BURST_STATE_DIR/kubeconfig"
  printf 'githubConfigUrl: https://github.com/oisin-ee\n' >"$MAC_BURST_STATE_DIR/scale-set-values.yaml"
  printf '999999\n' >"$MAC_BURST_STATE_DIR/caffeinate.pid"

  run "$ROOT/dot_local/bin/executable_mac-burst-down" --force

  [ "$status" -eq 47 ]
  assert_output_contains 'runner pod discovery unavailable'
  assert_output_contains 'runner pod discovery failed status=47; teardown refused because runner state is unknown'
  assert_output_contains '--force does not override unknown runner state'
  assert_output_contains 'retained scale-set=arc-runner-set controller=arc-controller cluster=mac-burst'
  assert_output_contains "kubeconfig=$MAC_BURST_STATE_DIR/kubeconfig"
  assert_output_contains "state=$MAC_BURST_STATE_DIR"
  [ -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ -L "$MAC_BURST_STATE_DIR/docker-config" ]
  [ -f "$MAC_BURST_STATE_DIR/scale-set-values.yaml" ]
  [ -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
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

@test "mac-burst-down retains controller cluster and local state when scale set uninstall fails" {
  export STUB_HELM_FAIL_UNINSTALL_RELEASE=arc-runner-set
  mkdir -p "$MAC_BURST_STATE_DIR/docker-config.test"
  ln -s "$MAC_BURST_STATE_DIR/docker-config.test" "$MAC_BURST_STATE_DIR/docker-config"
  printf 'apiVersion: v1\n' >"$MAC_BURST_STATE_DIR/kubeconfig"
  printf 'githubConfigUrl: https://github.com/oisin-ee\n' >"$MAC_BURST_STATE_DIR/scale-set-values.yaml"
  printf '999999\n' >"$MAC_BURST_STATE_DIR/caffeinate.pid"

  run "$ROOT/dot_local/bin/executable_mac-burst-down"

  [ "$status" -ne 0 ]
  assert_output_contains 'scale set uninstall failed; retained scale-set=arc-runner-set controller=arc-controller'
  assert_output_contains 'retained controller=arc-controller cluster=mac-burst'
  assert_output_contains "kubeconfig=$MAC_BURST_STATE_DIR/kubeconfig"
  assert_output_contains "state=$MAC_BURST_STATE_DIR"
  [ -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ -L "$MAC_BURST_STATE_DIR/docker-config" ]
  [ -f "$MAC_BURST_STATE_DIR/scale-set-values.yaml" ]
  [ -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
  grep -q 'helm uninstall arc-runner-set' "$CMD_LOG"
  refute_file_contains 'helm uninstall arc-controller' "$CMD_LOG"
  refute_file_contains 'k3d cluster delete' "$CMD_LOG"
}

@test "mac-burst-down retains cluster and local state when controller uninstall fails" {
  export STUB_HELM_FAIL_UNINSTALL_RELEASE=arc-controller
  mkdir -p "$MAC_BURST_STATE_DIR/docker-config.test"
  ln -s "$MAC_BURST_STATE_DIR/docker-config.test" "$MAC_BURST_STATE_DIR/docker-config"
  printf 'apiVersion: v1\n' >"$MAC_BURST_STATE_DIR/kubeconfig"
  printf 'githubConfigUrl: https://github.com/oisin-ee\n' >"$MAC_BURST_STATE_DIR/scale-set-values.yaml"
  printf '999999\n' >"$MAC_BURST_STATE_DIR/caffeinate.pid"

  run "$ROOT/dot_local/bin/executable_mac-burst-down"

  [ "$status" -ne 0 ]
  assert_output_contains 'controller uninstall failed; retained controller=arc-controller'
  assert_output_contains 'retained controller=arc-controller cluster=mac-burst'
  [ -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ -L "$MAC_BURST_STATE_DIR/docker-config" ]
  [ -f "$MAC_BURST_STATE_DIR/scale-set-values.yaml" ]
  [ -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
  grep -q 'helm uninstall arc-runner-set' "$CMD_LOG"
  grep -q 'helm uninstall arc-controller' "$CMD_LOG"
  refute_file_contains 'k3d cluster delete' "$CMD_LOG"
}

@test "mac-burst-down retries controller teardown after scale set was already removed" {
  export STUB_HELM_NOT_FOUND_RELEASE=arc-runner-set
  mkdir -p "$MAC_BURST_STATE_DIR/docker-config"
  printf 'apiVersion: v1\n' >"$MAC_BURST_STATE_DIR/kubeconfig"
  printf '999999\n' >"$MAC_BURST_STATE_DIR/caffeinate.pid"

  run "$ROOT/dot_local/bin/executable_mac-burst-down"

  [ "$status" -eq 0 ]
  grep -q 'helm uninstall arc-runner-set' "$CMD_LOG"
  grep -q 'helm uninstall arc-controller' "$CMD_LOG"
  grep -q 'k3d cluster delete mac-burst' "$CMD_LOG"
  [ ! -e "$MAC_BURST_STATE_DIR/kubeconfig" ]
  [ ! -d "$MAC_BURST_STATE_DIR/docker-config" ]
  [ ! -f "$MAC_BURST_STATE_DIR/caffeinate.pid" ]
}

@test "mac-burst-status labels configured chart digests as expected not live verified" {
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
  assert_output_contains 'configured chart digests (expected, not live-verified):'
  assert_output_contains 'controller-chart=sha256:'
  assert_output_contains 'scale-set-chart=sha256:'
  refute_output_contains 'digest: controller='
}
