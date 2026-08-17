#!/usr/bin/env bash
# Inteligentny skok po agentach (bind w config.toml). W przeciwieństwie do
# wbudowanego next_agent/previous_agent (alt+shift+j/k), który leci po WSZYSTKICH
# rzędach agentów po kolei, ten skacze tylko po tych, które wymagają uwagi,
# wg priorytetu blocked > done > working (pierwsza niepusta grupa wygrywa):
#   1. jeśli są agenci `blocked` → cyklicznie po nich,
#   2. inaczej jeśli są `done`  → cyklicznie po nich,
#   3. inaczej jeśli są `working` → cyklicznie po nich,
#   4. jeśli żadna z powyższych grup → nic (no-op; idle/unknown ignorujemy).
# Kolejność cyklu = kolejność sidebara (worktree pogrupowane per repo, jak
# w herdr-space-picker), więc kolejne wciśnięcia lecą przewidywalnie w dół.
# Skok jest RELATYWNY do aktualnie zfokusowanego workspace: bierze pierwszy
# pasujący PO nim (z zawinięciem), więc trzymając klawisz przelatujesz po
# wszystkich blocked, a gdy je odblokujesz — po working.
set -euo pipefail

id=$(herdr workspace list | python3 -c '
import json, sys

ws = json.load(sys.stdin)["result"]["workspaces"]

# Ta sama kolejność co picker/sidebar: roots w kolejności herdr, linked
# worktree podpięte zaraz pod swoje repo.
roots, children = [], {}
for w in ws:
    wt = w.get("worktree")
    if wt and wt.get("is_linked_worktree"):
        children.setdefault(wt["repo_name"], []).append(w)
    else:
        roots.append(w)

order = []
def emit_kids(repo):
    for k in children.pop(repo, []):
        order.append(k)
for w in roots:
    order.append(w)
    repo = w["worktree"]["repo_name"] if w.get("worktree") else w["label"]
    emit_kids(repo)
for repo in list(children):  # repo bez otwartego głównego checkoutu
    emit_kids(repo)

n = len(order)
if n == 0:
    sys.exit(0)

focused = next((i for i, w in enumerate(order) if w.get("focused")), -1)

def idxs(status):
    return [i for i, w in enumerate(order) if w.get("agent_status") == status]

target = set(idxs("blocked") or idxs("done") or idxs("working"))
if not target:
    sys.exit(0)  # nic nie wymaga uwagi

# pierwszy z target ściśle PO focused (z zawinięciem); focused=-1 → od początku
for step in range(1, n + 1):
    j = (focused + step) % n
    if j in target:
        print(order[j]["workspace_id"])
        break
') || exit 0

[ -z "$id" ] && exit 0
exec herdr workspace focus "$id"
