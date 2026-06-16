#!/bin/bash
# Coder dev-workspace only ($REPO_DIR set): make the interactive claude-code TUI
# start at the prompt instead of the theme/onboarding + "trust this folder?"
# dialogs, by marking onboarding complete and trusting the cloned repo in
# ~/.claude.json (claude's onboarding/trust state, which is not chezmoi-managed).
#
# No-op anywhere REPO_DIR is unset (laptops), so it never mutates local agent
# state. codex's equivalent trust lives in dot_codex/config.toml.tmpl.
set -euo pipefail

[ -n "${REPO_DIR:-}" ] || exit 0
command -v jq >/dev/null 2>&1 || { echo "agent-headless: jq missing, skipping" >&2; exit 0; }

f="$HOME/.claude.json"
[ -f "$f" ] || printf '{}' >"$f"

tmp="$(mktemp)"
jq --arg d "$REPO_DIR" '
  .hasCompletedOnboarding = true
  | .projects[$d] = ((.projects[$d] // {}) + {
      hasTrustDialogAccepted: true,
      hasCompletedProjectOnboarding: true
    })
' "$f" >"$tmp" && mv "$tmp" "$f"

echo "agent-headless: claude onboarding complete + $REPO_DIR trusted"
