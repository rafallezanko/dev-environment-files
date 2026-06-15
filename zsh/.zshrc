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

alias zdev='zellij --layout ~/.config/zellij/layouts/dev.kdl attach -c "$(basename "$PWD")"'
# Funkcja do odpalania środowiska Zellij z układem 70/30
# zdev() {
#     # Pobiera nazwę aktualnego folderu jako nazwę sesji
#     local session_name="$(basename "$PWD")"
#
#     # Sprawdza, czy sesja o tej nazwie działa już w tle
#     if zellij list-sessions 2>/dev/null | grep -q "$session_name"; then
#         # Jeśli tak -> po prostu się do niej podłącz
#         zellij attach "$session_name"
#     else
#         # Jeśli nie -> stwórz nową od zera, wymuszając układ z pliku
#         zellij --session "$session_name" --layout ~/.config/zellij/layouts/dev.kdl
#     fi
# }

PYTHON_VENV_NAME=".venv"
PYTHON_VENV_NAMES=($PYTHON_VENV_NAME venv)

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git common-aliases python docker gradle)

source $ZSH/oh-my-zsh.sh

export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export JDTLS_JVM_ARGS="-javaagent:$HOME/.local/share/nvim/mason/share/jdtls/lombok.jar"

export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
