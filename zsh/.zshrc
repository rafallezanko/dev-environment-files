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

zdev() {
    local session_name="$(basename "$PWD")"
    
    # Jeśli podasz argument "reset", niszczymy zapisany stan (cache) tej sesji
    if [[ "$1" == "reset" ]]; then
        echo "Wyczyszczono pamięć sesji: $session_name. Odpalam świeży układ..."
        zellij delete-session "$session_name" --force >/dev/null 2>&1
    fi
    
    # Zellij sam zajmie się resztą: podłączy, wskrzesi lub użyje layoutu do nowej sesji
    zellij --layout ~/.config/zellij/layouts/dev.kdl attach -c "$session_name"
}

# hw — herdr worktree: tworzy worktree (z layoutem `dev`) pytając o branch i repo.
#   hw                   # pyta o branch; repo = bieżący katalog
#   hw feature-x         # branch z argumentu; repo = bieżący katalog
#   hw feature-x ~/proj  # jawny branch i repo/lokalizacja
hw() {
    local branch="$1" repo="$2"

    [[ -z "$branch" ]] && read "branch?Branch: "
    if [[ -z "$branch" ]]; then
        echo "hw: anulowano — brak nazwy brancha." >&2
        return 1
    fi

    [[ -z "$repo" ]] && read "repo?Repo/lokalizacja [$PWD]: "
    repo="${repo:-$PWD}"
    repo="${repo/#\~/$HOME}"                       # rozwiń ~

    if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "hw: '$repo' to nie jest repo git." >&2
        return 1
    fi
    if ! git -C "$repo" rev-parse HEAD >/dev/null 2>&1; then
        echo "hw: repo '$repo' nie ma jeszcze commita (worktree wymaga HEAD)." >&2
        echo "    np.: git -C \"$repo\" commit --allow-empty -m init" >&2
        return 1
    fi

    herdr worktree create --cwd "$repo" --branch "$branch" --focus
}

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
