#!/usr/bin/env bash
# Fuzzy picker spaces dla herdr (popup pod alt+w, patrz [[keys.command]]
# w config.toml). Worktree zgrupowane per repo jak w sidebarze; pisanie
# filtruje (worktree także po nazwie repo — przygaszony sufiks), ctrl+j/k
# chodzi po liście, enter skacze. `--list` wypisuje tylko listę (debug).
#
# Format linii: <workspace_id>\t<wyświetlane drzewo>. fzf pokazuje i szuka
# tylko po kolumnie 2 (--with-nth transformuje linię, więc --nth po
# oryginalnych polach NIE działa — stąd repo w ANSI dim zamiast ukrytej
# kolumny). Ctrl+h zostaje backspace'em fzf — nie bindować!
set -euo pipefail

build_list() {
  herdr workspace list | python3 -c '
import json, sys

ws = json.load(sys.stdin)["result"]["workspaces"]
DIM, RESET = "\033[2m", "\033[0m"

# Zachowaj kolejność herdr, ale podepnij linked worktree pod ich repo.
roots, children = [], {}
for w in ws:
    wt = w.get("worktree")
    if wt and wt.get("is_linked_worktree"):
        children.setdefault(wt["repo_name"], []).append(w)
    else:
        roots.append(w)

out = []
def emit(w, display):
    mark = "*" if w["focused"] else " "
    out.append(f"{w['"'"'workspace_id'"'"']}\t{mark} {display}")

def emit_kids(repo):
    kids = children.pop(repo, [])
    for i, k in enumerate(kids):
        glyph = "└" if i == len(kids) - 1 else "├"
        emit(k, f"  {glyph} {k['"'"'label'"'"']} {DIM}{repo}{RESET}")

for w in roots:
    repo = w["worktree"]["repo_name"] if w.get("worktree") else w["label"]
    emit(w, w["label"])
    emit_kids(repo)

# Repo, których główny checkout nie jest otwarty jako workspace.
for repo in list(children):
    out.append(f"-\t  {DIM}{repo}/{RESET}")
    emit_kids(repo)

print("\n".join(out))
'
}

if [ "${1:-}" = "--list" ]; then
  build_list
  exit 0
fi

selected=$(build_list | fzf \
  --ansi --delimiter '\t' --with-nth 2 \
  --layout=reverse --info=hidden --no-multi \
  --prompt 'space> ' \
  ) || exit 0

id=$(printf '%s' "$selected" | cut -f1)
[ "$id" = "-" ] && exit 0
exec herdr workspace focus "$id"
