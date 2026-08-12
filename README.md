# dev-environment-files

Dotfiles zarządzane przez [GNU Stow](https://www.gnu.org/software/stow/). Każdy katalog to „pakiet" stow odwzorowujący strukturę `$HOME`.

```zsh
brew install stow

git clone git@github.com:rafallezanko/dev-environment-files.git ~/dotfiles

cd ~/dotfiles

stow */
```

## helix — LSP

Pakiet `helix/` konfiguruje language servery w `languages.toml`. Binarki trzeba doinstalować osobno:

```zsh
# edytor
brew install helix

# Python — ruff (lint/format) + basedpyright (typy, completion) + uv (venvy)
brew install ruff basedpyright uv

# Go — toolchain + gopls (LSP), golangci-lint (linter), goimports (formatter), dlv (debugger)
brew install go gopls golangci-lint golangci-lint-langserver
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/go-delve/delve/cmd/dlv@latest

# weryfikacja — wszystko powinno być na zielono
hx --health python
hx --health go
```

basedpyright czyta pakiety z venva projektu — w repo bez venva (`uv sync` / `uv venv`) completion obejmuje tylko stdlib.

## herdr — automatyczny layout dla worktree

Pakiet `herdr/` dostarcza deklaratywny layout dla [herdr](https://herdr.dev): każdy worktree utworzony przez `herdr worktree create` otwiera się z układem `dev` — edytor `hx .` po lewej, Claude w prawej kolumnie (35%), shell pod nim. Robi to plugin **workspace-manager**, którego config linkujemy przez stow do kanonicznej ścieżki `~/.config/herdr/plugins/config/herdr-plugin-workspace-manager/config.yml` (linkowany jest tylko `config.yml` — resztę `~/.config/herdr/` tworzy sam herdr).

### Co musi być zainstalowane

| Co | Po co | Jak |
|----|-------|-----|
| **herdr** ≥ 0.7.5 | sam multiplekser | zgodnie z instrukcją herdr |
| **Rust / `cargo`** na `PATH` | plugin to program w Ruście, który **kompiluje się przy pierwszym użyciu** — bez `cargo` każdy event pada po cichu z `cargo not found` i layout się nie aplikuje | `brew install rust` (cargo ląduje w `/opt/homebrew/bin`, już na `PATH`) |
| **plugin workspace-manager** | to on aplikuje layout na `worktree.created` | `herdr plugin install razajamil/herdr-plugin-workspace-manager` |

### Instalacja (kolejność ma znaczenie)

```zsh
# 1. config w miejscu (stow linkuje tylko config.yml)
stow herdr

# 2. Rust — MUSI być, zanim plugin spróbuje się zbudować
brew install rust
cargo --version

# 3. plugin
herdr plugin install razajamil/herdr-plugin-workspace-manager

# 4. jeśli herdr już działał — przeładuj serwer, żeby złapał plugin
herdr server stop && herdr
```

### Weryfikacja

```zsh
# powinno wypisać rozpoznane layouts/workspaces i "Config is valid."
herdr plugin action invoke herdr-plugin-workspace-manager.validate

# tu widać ewentualne błędy pluginu (np. "cargo not found")
herdr plugin log

# test na żywo — powinny wejść 3 panele
herdr worktree create --branch test
```

Layout jest catch-all (`path: ~/.herdr/worktrees` → `dev`), więc dotyczy **każdego** worktree dowolnego repo i nie zawiera nazw projektów. Dotyczy tylko worktree (nie głównego checkoutu repo — tak działa plugin).

### Komendy `hw` i `hdev` (z `zsh/.zshrc`)

- **`hw [branch] [repo]`** — tworzy worktree (repo domyślnie = bieżący katalog) z layoutem `dev` i przeskokiem (`--focus`). Działa od razu po powyższej instalacji.
- **`hdev [layout]`** — nakłada layout `dev` na **bieżący** workspace herdr, bez worktree. Odpalaj wewnątrz panelu herdr, najlepiej na świeżym oknie (przebudowuje pierwszy tab).

`hdev` używa **standalone CLI** pluginu (`herdr-workspace-manager`), którego **nie ma w repo** — to symlink tworzony per-maszyna. Na każdej nowej maszynie dołóż go po instalacji pluginu:

```zsh
# wymaga zainstalowanego pluginu (krok 3 wyżej); symlinkuje CLI do ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/razajamil/herdr-plugin-workspace-manager/main/install.sh | sh
hash -r   # żeby shell zobaczył nową komendę
```

`~/.local/bin` na PATH oraz `HERDR_WSM_CONFIG` (żeby standalone CLI znalazł config — serwerowy plugin go nie potrzebuje) ustawia już `zsh/.zshrc`.
