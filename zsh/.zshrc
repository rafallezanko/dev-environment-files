autoload -Uz compinit
compinit
export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# Ensure Go-installed binaries (gopls, dlv, goimports, golangci-lint-langserver) are in PATH.
if command -v go >/dev/null 2>&1; then
  export GOPATH="${GOPATH:-$(go env GOPATH)}"
  case ":$PATH:" in
    *":$GOPATH/bin:"*) ;;
    *) export PATH="$PATH:$GOPATH/bin" ;;
  esac
fi

PYTHON_VENV_NAME=".venv"
PYTHON_VENV_NAMES=($PYTHON_VENV_NAME venv)

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git common-aliases python docker gradle)

source $ZSH/oh-my-zsh.sh
