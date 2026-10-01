[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"
export MISE_SYSTEM_CONFIG_FILE="$HOME/dev/agent/agent-runtime.toml"

ASYNCAPI_AC_BASH_SETUP_PATH="$HOME/Library/Caches/@asyncapi/cli/autocomplete/bash_setup"
[[ -r "$ASYNCAPI_AC_BASH_SETUP_PATH" ]] && source "$ASYNCAPI_AC_BASH_SETUP_PATH"
unset ASYNCAPI_AC_BASH_SETUP_PATH

# An agent started by momo-agent keeps its gh wrapper first; path_helper in
# /etc/profile reorders PATH. See ~/dev/agent/docs/agent-identity.md.
[ -n "${MOMO_AGENT_BIN-}" ] && PATH="$MOMO_AGENT_BIN:$PATH"
