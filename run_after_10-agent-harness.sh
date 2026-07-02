#!/bin/bash
# Install the agent harness (skills/hooks/rules/settings) from the oisin-ee/agent
# checkout that .chezmoiexternal clones into ~/.local/share/agent. The repo owns
# the install logic (bin/install-harness.mjs) — this script is a thin, HEAD-gated
# trigger, the single owner of the on-disk harness on laptop and in runner pods.
#
# Replaces the old `moka init --force` auto-fork: synchronous (so failures surface
# on `chezmoi apply`, never silently), non-destructive (the installer reconciles
# to the exact source set / full-resets settings — it never deletes the live store
# before the replacement is staged), and sourced from git, not a private re-fetch.
set -euo pipefail

src="${XDG_DATA_HOME:-$HOME/.local/share}/agent"
installer="$src/bin/install-harness.mjs"

# No-op where the harness source isn't present (machine chezmoi doesn't manage the
# external on, or a first apply racing the clone) — never fail the whole apply.
if [ ! -f "$installer" ]; then
  echo "agent-harness: installer not found at $installer; skipping."
  exit 0
fi
if ! command -v node >/dev/null 2>&1; then
  echo "agent-harness: node not on PATH; skipping (mise provides it)."
  exit 0
fi

# HEAD gate: only reinstall when the harness checkout actually changed, so routine
# applies stay cheap. Falls through to install when the repo HEAD can't be read.
head="$(git -C "$src" rev-parse HEAD 2>/dev/null || true)"
stamp="${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness-version"
if [ -n "$head" ] && [ "$head" = "$(cat "$stamp" 2>/dev/null || true)" ]; then
  exit 0
fi

echo "agent-harness: installing from $src ($head)…"
node "$installer" --source "$src"

mkdir -p "$(dirname "$stamp")"
printf '%s\n' "$head" >|"$stamp"
echo "agent-harness: done."
