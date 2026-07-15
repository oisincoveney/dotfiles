#!/usr/bin/env bash
# mac-burst/lib.sh — shared library for INFRA-107.03 Mac burst runner lease scripts.
# Sourced by mac-burst-up/down/status; callers own `set -euo pipefail`.

MAC_BURST_CLUSTER="${MAC_BURST_CLUSTER:-mac-burst}"
MAC_BURST_K3S_IMAGE="${MAC_BURST_K3S_IMAGE:-rancher/k3s:v1.36.2-k3s1}"
MAC_BURST_ARC_VERSION="${MAC_BURST_ARC_VERSION:-0.14.2}"
MAC_BURST_GITHUB_CONFIG_URL="${MAC_BURST_GITHUB_CONFIG_URL:-https://github.com/oisin-ee}"
MAC_BURST_RUNNER_GROUP="${MAC_BURST_RUNNER_GROUP:-Mac Burst}"
MAC_BURST_RUNNER_SCALE_SET_NAME="${MAC_BURST_RUNNER_SCALE_SET_NAME:-infra-k8s-runner}"
MAC_BURST_RUNNER_IMAGE="${MAC_BURST_RUNNER_IMAGE:-ghcr.io/oisin-ee/kaya-runner-k8s:latest}"

MAC_BURST_CONTROLLER_RELEASE="${MAC_BURST_CONTROLLER_RELEASE:-arc-controller}"
MAC_BURST_SCALE_SET_RELEASE="${MAC_BURST_SCALE_SET_RELEASE:-arc-runner-set}"
MAC_BURST_CONTROLLER_NAMESPACE="${MAC_BURST_CONTROLLER_NAMESPACE:-arc-systems}"
MAC_BURST_RUNNER_NAMESPACE="${MAC_BURST_RUNNER_NAMESPACE:-arc-runners}"
MAC_BURST_ARC_SECRET="${MAC_BURST_ARC_SECRET:-mac-burst-arc-secret}"
MAC_BURST_GHCR_PULL_SECRET="${MAC_BURST_GHCR_PULL_SECRET:-ghcr-pull-secret}"

MAC_BURST_CHART_REGISTRY="${MAC_BURST_CHART_REGISTRY:-oci://ghcr.io/actions/actions-runner-controller-charts}"
MAC_BURST_CONTROLLER_CHART="${MAC_BURST_CONTROLLER_CHART:-$MAC_BURST_CHART_REGISTRY/gha-runner-scale-set-controller}"
MAC_BURST_SCALE_SET_CHART="${MAC_BURST_SCALE_SET_CHART:-$MAC_BURST_CHART_REGISTRY/gha-runner-scale-set}"
MAC_BURST_CONTROLLER_DIGEST="${MAC_BURST_CONTROLLER_DIGEST:-\
sha256:3081ba15c41f0aa791058dedd2a7406fece24c9aeaa94956c268e5099427a452}"
MAC_BURST_SCALE_SET_DIGEST="${MAC_BURST_SCALE_SET_DIGEST:-\
sha256:579e3a1bdf4032b3c3de3e9b0880a4a6d3c1989a67c06010f680c1cc49524d11}"

MAC_BURST_STATE_DIR="${MAC_BURST_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/mac-burst}"
MAC_BURST_DATA_DIR="${MAC_BURST_VALUES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mac-burst}"
MAC_BURST_TEMPLATE_FILE="${MAC_BURST_TEMPLATE_FILE:-$MAC_BURST_DATA_DIR/scale-set-runner-template.yaml}"
MAC_BURST_KUBECONFIG="$MAC_BURST_STATE_DIR/kubeconfig"
MAC_BURST_CAFFEINATE_PID_FILE="$MAC_BURST_STATE_DIR/caffeinate.pid"
MAC_BURST_DOCKER_CONFIG_LINK="$MAC_BURST_STATE_DIR/docker-config"

MAC_BURST_MODE_ROWS='canary|self-hosted linux arm64 mac-burst-canary|1
production|self-hosted linux k8s-runner arm64|1
capacity|self-hosted linux k8s-runner arm64|2'

mb_log() { printf 'mac-burst: %s\n' "$*" >&2; }
mb_warn() { printf 'mac-burst: warn: %s\n' "$*" >&2; }
mb_die() { printf 'mac-burst: error: %s\n' "$*" >&2; exit 1; }

mb_require() {
  local name
  for name in "$@"; do
    command -v "$name" >/dev/null 2>&1 || mb_die "$name CLI not found"
  done
}

mb_validate_scalar() {
  local name="$1" value="$2"
  [ -n "$value" ] || mb_die "$name is empty"
  case "$value" in
    *$'\n'*|*$'\r'*|*$'\t'*) mb_die "$name contains control whitespace" ;;
  esac
}

mb_validate_image() {
  mb_validate_scalar "MAC_BURST_RUNNER_IMAGE" "$MAC_BURST_RUNNER_IMAGE"
  case "$MAC_BURST_RUNNER_IMAGE" in
    *[!A-Za-z0-9._:/@+-]*) mb_die "MAC_BURST_RUNNER_IMAGE contains unsafe characters" ;;
  esac
}

mb_select_mode() {
  local requested="$1" mode labels max_runners
  while IFS='|' read -r mode labels max_runners; do
    [ -n "$mode" ] || continue
    if [ "$requested" = "$mode" ]; then
      # shellcheck disable=SC2034 # consumed by sourcing executables after this function returns.
      MB_MODE="$mode"
      MB_SCALE_SET_LABELS="$labels"
      MB_MAX_RUNNERS="$max_runners"
      return 0
    fi
  done <<EOF_ROWS
$MAC_BURST_MODE_ROWS
EOF_ROWS
  mb_die "unsupported mode '$requested' (expected canary, production, or capacity)"
}

mb_export_kubeconfig() {
  mkdir -p "$MAC_BURST_STATE_DIR"
  mb_use_kubeconfig
}

mb_use_kubeconfig() {
  export KUBECONFIG="$MAC_BURST_KUBECONFIG"
}

mb_start_caffeinate() {
  mkdir -p "$MAC_BURST_STATE_DIR"
  if [ -s "$MAC_BURST_CAFFEINATE_PID_FILE" ] && kill -0 "$(cat "$MAC_BURST_CAFFEINATE_PID_FILE")" 2>/dev/null; then
    mb_log "caffeinate already running pid=$(cat "$MAC_BURST_CAFFEINATE_PID_FILE")"
    return 0
  fi
  caffeinate -dimsu </dev/null >/dev/null 2>&1 &
  printf '%s\n' "$!" >"$MAC_BURST_CAFFEINATE_PID_FILE"
  mb_log "caffeinate pid=$(cat "$MAC_BURST_CAFFEINATE_PID_FILE")"
}

mb_stop_caffeinate() {
  [ -s "$MAC_BURST_CAFFEINATE_PID_FILE" ] || return 0
  local pid
  pid="$(cat "$MAC_BURST_CAFFEINATE_PID_FILE")"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$MAC_BURST_CAFFEINATE_PID_FILE"
}

mb_make_temp_credentials() {
  mkdir -p "$MAC_BURST_STATE_DIR"
  umask 077
  MB_TEMP_CRED_DIR="$(mktemp -d "$MAC_BURST_STATE_DIR/docker-config.XXXXXX")"
  rm -f "$MAC_BURST_DOCKER_CONFIG_LINK"
  ln -s "$MB_TEMP_CRED_DIR" "$MAC_BURST_DOCKER_CONFIG_LINK"
  MB_TOKEN_FILE="$MB_TEMP_CRED_DIR/github-token"
  gh auth token >"$MB_TOKEN_FILE"
  [ -s "$MB_TOKEN_FILE" ] || mb_die "gh auth token returned empty token"
  MB_GITHUB_USER="$(gh api user --jq .login)"
  mb_validate_scalar "GitHub username" "$MB_GITHUB_USER"
  DOCKER_CONFIG="$MB_TEMP_CRED_DIR" docker login ghcr.io --username "$MB_GITHUB_USER" --password-stdin \
    <"$MB_TOKEN_FILE" >/dev/null
}

mb_delete_temp_credentials() {
  rm -rf "$MAC_BURST_DOCKER_CONFIG_LINK"
  rm -rf "$MAC_BURST_STATE_DIR"/docker-config.*
}

mb_create_namespace() {
  local namespace="$1"
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
}

mb_apply_secret_files() {
  mb_create_namespace "$MAC_BURST_CONTROLLER_NAMESPACE"
  mb_create_namespace "$MAC_BURST_RUNNER_NAMESPACE"
  kubectl create secret generic "$MAC_BURST_ARC_SECRET" \
    --namespace "$MAC_BURST_RUNNER_NAMESPACE" \
    --from-file=github_token="$MB_TOKEN_FILE" \
    --dry-run=client \
    -o yaml | kubectl apply -f - >/dev/null
  kubectl create secret generic "$MAC_BURST_GHCR_PULL_SECRET" \
    --namespace "$MAC_BURST_RUNNER_NAMESPACE" \
    --type=kubernetes.io/dockerconfigjson \
    --from-file=.dockerconfigjson="$MB_TEMP_CRED_DIR/config.json" \
    --dry-run=client \
    -o yaml | kubectl apply -f - >/dev/null
}

mb_render_scale_set_values() {
  mb_validate_scalar "MAC_BURST_GITHUB_CONFIG_URL" "$MAC_BURST_GITHUB_CONFIG_URL"
  mb_validate_image
  [ -r "$MAC_BURST_TEMPLATE_FILE" ] || mb_die "runner template not readable: $MAC_BURST_TEMPLATE_FILE"
  {
    printf 'githubConfigUrl: %s\n' "$MAC_BURST_GITHUB_CONFIG_URL"
    printf 'githubConfigSecret: %s\n' "$MAC_BURST_ARC_SECRET"
    printf 'runnerGroup: %s\n' "$MAC_BURST_RUNNER_GROUP"
    printf 'runnerScaleSetName: %s\n' "$MAC_BURST_RUNNER_SCALE_SET_NAME"
    printf 'scaleSetLabels:\n'
    local label
    for label in $MB_SCALE_SET_LABELS; do
      printf -- '- %s\n' "$label"
    done
    printf 'minRunners: 0\n'
    printf 'maxRunners: %s\n' "$MB_MAX_RUNNERS"
    printf 'controllerServiceAccount:\n'
    printf '  namespace: %s\n' "$MAC_BURST_CONTROLLER_NAMESPACE"
    printf '  name: %s-gha-rs-controller\n' "$MAC_BURST_CONTROLLER_RELEASE"
    sed "s#__MAC_BURST_RUNNER_IMAGE__#$MAC_BURST_RUNNER_IMAGE#g" "$MAC_BURST_TEMPLATE_FILE"
  }
}

mb_install_arc() {
  local values_file="$MAC_BURST_STATE_DIR/scale-set-values.yaml"
  mb_render_scale_set_values >"$values_file"
  helm upgrade --install "$MAC_BURST_CONTROLLER_RELEASE" "$MAC_BURST_CONTROLLER_CHART" \
    --namespace "$MAC_BURST_CONTROLLER_NAMESPACE" \
    --create-namespace \
    --version "$MAC_BURST_ARC_VERSION" \
    --atomic --wait
  helm upgrade --install "$MAC_BURST_SCALE_SET_RELEASE" "$MAC_BURST_SCALE_SET_CHART" \
    --namespace "$MAC_BURST_RUNNER_NAMESPACE" \
    --create-namespace \
    --version "$MAC_BURST_ARC_VERSION" \
    --values "$values_file" \
    --atomic --wait
}

mb_uninstall_arc() {
  if ! helm uninstall "$MAC_BURST_SCALE_SET_RELEASE" \
    --namespace "$MAC_BURST_RUNNER_NAMESPACE" --wait --ignore-not-found; then
    mb_warn "scale set uninstall failed; retained scale-set=$MAC_BURST_SCALE_SET_RELEASE" \
      "controller=$MAC_BURST_CONTROLLER_RELEASE"
    return 1
  fi
  if ! helm uninstall "$MAC_BURST_CONTROLLER_RELEASE" \
    --namespace "$MAC_BURST_CONTROLLER_NAMESPACE" --wait --ignore-not-found; then
    mb_warn "controller uninstall failed; retained controller=$MAC_BURST_CONTROLLER_RELEASE"
    return 1
  fi
}

mb_delete_cluster() {
  k3d cluster delete "$MAC_BURST_CLUSTER"
}

mb_cleanup_local_state() {
  mb_stop_caffeinate
  mb_delete_temp_credentials
  rm -f "$MAC_BURST_KUBECONFIG" "$MAC_BURST_STATE_DIR/scale-set-values.yaml"
  rmdir "$MAC_BURST_STATE_DIR" 2>/dev/null || true
}

mb_failed_startup_cleanup() {
  mb_warn "startup failed; attempting ordered Helm, cluster, and local-state cleanup"
  if ! mb_uninstall_arc; then
    mb_warn "startup cleanup stopped; retained controller=$MAC_BURST_CONTROLLER_RELEASE cluster=$MAC_BURST_CLUSTER"
    mb_warn "retained kubeconfig=$MAC_BURST_KUBECONFIG state=$MAC_BURST_STATE_DIR for diagnosis and retry"
    return 1
  fi
  if ! mb_delete_cluster; then
    mb_warn "startup cluster deletion failed; retained cluster=$MAC_BURST_CLUSTER kubeconfig=$MAC_BURST_KUBECONFIG"
    mb_warn "retained state=$MAC_BURST_STATE_DIR for diagnosis and retry"
    return 1
  fi
  mb_cleanup_local_state
}

mb_active_runner_pods() {
  [ -s "$MAC_BURST_KUBECONFIG" ] || return 0
  kubectl get pods --namespace "$MAC_BURST_RUNNER_NAMESPACE" --no-headers \
    | awk '$3 ~ /^(Pending|Running|Unknown)$/ { print $1 " " $3 }'
}

mb_caffeinate_status() {
  if [ -s "$MAC_BURST_CAFFEINATE_PID_FILE" ]; then
    local pid
    pid="$(cat "$MAC_BURST_CAFFEINATE_PID_FILE")"
    if kill -0 "$pid" 2>/dev/null; then
      printf 'running pid=%s\n' "$pid"
      return 0
    fi
    printf 'stale pid=%s\n' "$pid"
    return 0
  fi
  printf 'stopped\n'
}

mb_digest_report() {
  printf 'controller-chart=%s scale-set-chart=%s\n' \
    "$MAC_BURST_CONTROLLER_DIGEST" "$MAC_BURST_SCALE_SET_DIGEST"
}
