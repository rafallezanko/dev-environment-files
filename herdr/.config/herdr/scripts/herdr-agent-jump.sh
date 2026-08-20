#!/usr/bin/env bash
# Inteligentny skok po agentach (bind w config.toml). W przeciwieństwie do
# wbudowanego next_agent/previous_agent (alt+shift+j/k), który leci po WSZYSTKICH
# rzędach agentów po kolei, ten skacze tylko po tych, które wymagają uwagi,
# wg priorytetu blocked > done > working (pierwsza niepusta grupa wygrywa):
#   1. jeśli są agenci `blocked` → cyklicznie po nich,
#   2. inaczej jeśli są `done`  → cyklicznie po nich,
#   3. inaczej jeśli są `working` → cyklicznie po nich,
#   4. jeśli żadna z powyższych grup → nic (no-op; idle/unknown ignorujemy).
# Skacze do KONKRETNEGO pane'a agenta (herdr agent focus <pane_id>), nie tylko
# do workspace — przy kilku agentach w jednym workspace ląduje w tym właściwym.
# Kolejność cyklu = kolejność sidebara (workspace wg workspace list z worktree
# pogrupowanymi per repo, w obrębie workspace kolejność paneli). Skok jest
# RELATYWNY do aktualnie zfokusowanego agenta: bierze pierwszego pasującego PO
# nim (z zawinięciem), więc kolejne wciśnięcia przelatują po wszystkich blocked,
# a gdy je odblokujesz — po done, potem po working.
set -euo pipefail

# workspace list oddzielnie i przez export — prefiks VAR=... przed pipeline'em
# ustawiłby zmienną tylko dla pierwszego członu (herdr agent list), nie dla python3.
export HERDR_WS_JSON="$(herdr workspace list)"
pane=$(herdr agent list | python3 -c '
import json, os, sys

agents = json.load(sys.stdin)["result"]["agents"]
if not agents:
    sys.exit(0)

# Ranking workspace_id wg sidebara (roots w kolejności herdr, linked worktree
# podpięte pod swoje repo — tak jak picker) → cykl agentów idzie jak sidebar.
ws = json.loads(os.environ["HERDR_WS_JSON"])["result"]["workspaces"]
roots, children = [], {}
for w in ws:
    wt = w.get("worktree")
    if wt and wt.get("is_linked_worktree"):
        children.setdefault(wt["repo_name"], []).append(w)
    else:
        roots.append(w)
ws_order = []
def kids(repo):
    for k in children.pop(repo, []):
        ws_order.append(k["workspace_id"])
for w in roots:
    ws_order.append(w["workspace_id"])
    kids(w["worktree"]["repo_name"] if w.get("worktree") else w["label"])
for repo in list(children):
    kids(repo)
rank = {wid: i for i, wid in enumerate(ws_order)}

# Sort: workspace wg sidebara, w obrębie workspace kolejność z agent list
# (kolejność paneli). Stabilny sort po rank zachowuje oryginalną kolejność.
agents.sort(key=lambda a: rank.get(a["workspace_id"], len(rank)))

n = len(agents)
focused = next((i for i, a in enumerate(agents) if a.get("focused")), -1)

def idxs(status):
    return [i for i, a in enumerate(agents) if a.get("agent_status") == status]

target = set(idxs("blocked") or idxs("done") or idxs("working"))
if not target:
    sys.exit(0)  # nic nie wymaga uwagi

# pierwszy z target ściśle PO focused (z zawinięciem); focused=-1 → od początku
for step in range(1, n + 1):
    j = (focused + step) % n
    if j in target:
        print(agents[j]["pane_id"])
        break
') || exit 0

[ -z "$pane" ] && exit 0
exec herdr agent focus "$pane"
