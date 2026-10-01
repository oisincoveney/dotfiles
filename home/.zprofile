if [[ "$(uname -s)" == "Darwin" ]]; then
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
fi

# Login shells that never reach a prompt (`ssh host cmd`, agent runners, `zsh -lc`)
# get tools through the shims; interactive shells replace this with full
# activation in tools.zsh. https://mise.jdx.dev/dev-tools/shims.html
command -v mise >/dev/null && eval "$(mise activate zsh --shims)"

# An agent started by momo-agent keeps its gh wrapper first; brew shellenv and
# path_helper above reorder PATH. See ~/dev/agent/docs/agent-identity.md.
[[ -n ${MOMO_AGENT_BIN-} ]] && path=("$MOMO_AGENT_BIN" $path)
