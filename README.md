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

## nvim — LSP

Pakiet `nvim/` zarządza language serverami i narzędziami przez [Mason](https://github.com/williamboman/mason.nvim) — `terraformls`, `bashls`, `helm_ls`, `shfmt`, `shellcheck` (i reszta) instalują się **automatycznie przy pierwszym starcie nvim** (albo ręcznie przez `:Mason`). Część serwerów potrzebuje jednak zewnętrznych binarek, których Mason nie dostarcza:

```zsh
# Terraform — `terraform fmt` (format-on-save) + walidacja w terraformls
brew install terraform

# Helm — funkcje helm_ls (render/lookup wykresów)
brew install helm
```

Bash: diagnostykę daje `shellcheck` (Mason), a `bashls` podpina go sam; formatuje `shfmt` (Mason). Helm: szablony (`Chart.yaml`, `values.yaml`, `templates/*.yaml`) wykrywa plugin `vim-helm` jako `ft=helm` — bez formatera (Go templates w YAML-u).

## herdr — automatyczny layout dla worktree

Pakiet `herdr/` dostarcza deklaratywny layout dla [herdr](https://herdr.dev): każdy worktree utworzony przez `herdr worktree create` otwiera się z układem `dev` — edytor `nvim .` po lewej, Claude w prawej kolumnie (35%), shell pod nim. Robi to plugin **workspace-manager**, którego config linkujemy przez stow do kanonicznej ścieżki `~/.config/herdr/plugins/config/herdr-plugin-workspace-manager/config.yml` (linkowany jest tylko `config.yml` — resztę `~/.config/herdr/` tworzy sam herdr).

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

### ctrl+hjkl przez splity neovim i panele herdr (herdr-splits)

Plugin [herdr-splits.nvim](https://github.com/lmilojevicc/herdr-splits.nvim) (port smart-splits.nvim): w panelu z neovimem ctrl+hjkl chodzi po splitach nvim, a na krawędzi przeskakuje do sąsiedniego panelu herdr; w pozostałych panelach zwykła zmiana panelu z zawijaniem. Strona nvim (`nvim/.../plugins/herdr-splits.lua`, aktywna tylko przy `HERDR_ENV=1` — poza herdr klawisze trzyma smart-splits) i bindy `[[keys.command]]` w `config.toml` są w repo. Na nowej maszynie doinstaluj plugin serwerowy:

```zsh
herdr plugin install lmilojevicc/herdr-splits.nvim
herdr server reload-config
```

Resize (alt+hjkl z README pluginu) celowo pominięty — lewy option+j/k ma docierać do aplikacji w panelu.

### alt+w — Workspace finder (fuzzy picker spaces)

Własny picker workspace'ów w popupie (`herdr/.config/herdr/scripts/herdr-space-picker.sh`): worktree zgrupowane per repo jak w sidebarze, `*` oznacza fokus, każdy workspace ma kolorowy status agenta (`working`/`blocked`/`done`/`idle`). Pisanie filtruje po nazwie, repo **i statusie** (np. `blocked` albo `idle mono`), ctrl+j/k chodzi po liście, enter skacze, esc zamyka.

Popup otwiera mini-plugin lokalny `herdr/.config/herdr/local-plugins/herdr-space-picker/` (sam manifest) — tylko pluginowe panele mają konfigurowalny tytuł ramki ("Workspace finder"; zwykły `type="popup"` ma zahardkodowane "popup"). Na nowej maszynie:

```zsh
brew install fzf   # picker stoi na fzf
herdr plugin link ~/.config/herdr/local-plugins/herdr-space-picker
herdr server reload-config
```

### alt+d — skok do agenta wymagającego uwagi

Skrypt `herdr/.config/herdr/scripts/herdr-agent-jump.sh` (bind `alt+d` w `config.toml`) przeskakuje po agentach wg priorytetu **blocked > done > working**: wybiera pierwszą niepustą grupę i cyklicznie leci po niej (`idle`/`unknown` ignoruje, brak kandydatów = no-op). Skacze do **konkretnego pane'a** agenta (`herdr agent focus <pane_id>`), nie tylko do workspace — przy kilku agentach w jednym workspace ląduje w tym właściwym. Skok jest relatywny do zfokusowanego agenta (pierwszy pasujący po nim, z zawinięciem), kolejność jak w sidebarze/pickerze. Uzupełnia wbudowane `alt+shift+j/k` (next/previous_agent), które lecą po **wszystkich** rzędach agentów.

Nic do doinstalowania (czysty `herdr agent list` + `herdr workspace list` na kolejność + `python3`). Uwaga: herdr łapie `alt+d` globalnie, więc w panelach tracisz readline `kill-word`.

### Agent skill — Claude steruje herdr

Oficjalny [agent skill herdr](https://herdr.dev/docs/agent-skill/) uczy Claude Code (i inne agenty) sterowania herdr z wnętrza panelu: inspekcja workspace'ów/tabów/paneli, `herdr worktree create` (worktree innego repo otwiera się jako nowy workspace widoczny w sidebarze), start agentów w panelach (`herdr agent start --kind claude`), zlecanie im zadań (`herdr agent prompt <target> "<zadanie>" --wait`) i czekanie na ich stan. Dzięki temu z sesji Claude'a w jednym repo (np. hive-mind) można zlecić zadanie w innym (np. monorepo) na świeżym worktree — bez symlinków; wbudowanych worktree Claude'a (EnterWorktree) herdr nie widzi, więc zawsze przez `herdr worktree create`.

Skill nie jest plikiem w tym repo — instaluje się per-maszyna (jak standalone CLI pluginu wyżej):

```zsh
# instaluje do ~/.agents/skills/herdr + symlink ~/.claude/skills/herdr
npx -y skills add herdrdev/herdr --skill herdr -g
```

Skill aktywuje się tylko, gdy w prompcie padnie „herdr", i wymaga `HERDR_ENV=1` (herdr ustawia to w swoich panelach automatycznie). Z pluginem workspace-manager składa się w całość: `herdr worktree create` → layout `dev` sam startuje Claude'a jako agenta `main` → `herdr agent prompt` zleca mu zadanie.

## rtk — mniej tokenów w Claude Code

[rtk](https://github.com/rtk-ai/rtk) to proxy na komendy CLI, które kompresuje ich output zanim trafi do kontekstu agenta.

```zsh
brew install rtk

# hook auto-rewrite dla Claude Code (git status → rtk git status itd.)
rtk init -g
```

Po `rtk init -g` zrestartuj Claude Code. Weryfikacja: `rtk gain` pokazuje zaoszczędzone tokeny.
