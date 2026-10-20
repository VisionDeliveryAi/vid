#!/bin/sh
# Purpose: selftest case — the test queue now (v0.26.10.6 spec R6). The viewer fixture, no .vid/budget, and planted
# requests: one running whose run folder holds slot 1 (records 24 limits: silence, startup, limit), one waiting with
# a holders file, one waiting without, and an older one running with `cap=` and `startup=` (an estimate's term then,
# not a limit). Convicts unless environments is null, the slot is taken by its request since its holder's start with
# its working copy's folder name, the running and waiting requests carry their type, role (runrole first), try, rows,
# since (running-at, else created) and limits as recorded — the older one's cap alone — and a waiting request's why is
# its holders file's lines as written, null without one. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-queue: $*" >&2; exit 1; }
view_project "$T/repo"
rm -f .vid/budget
rq() { mkdir -p ".vid/requests/$1"; printf '%s\n' "$3" | tr ' ' '\n' > ".vid/requests/$1/request"; printf '%s\n' "$2" > ".vid/requests/$1/state"; }
rq 20260101T110000Z-aaaa running 'type=iterate role=builder runrole=fixer try=1-fixer-1 rows=3 silence=600 startup=300 limit=7200 created=1767265200'
printf '1767265260\n' > .vid/requests/20260101T110000Z-aaaa/running-at; printf '%s/.vid/runs/R1\n' "$PWD" > .vid/requests/20260101T110000Z-aaaa/run
mkdir -p .vid/runs/R1; printf 'pid=1\nstart=1767265270\nkind=scoped\nworktree=/w/.claude/worktrees/agent-abc\nslot=1\nproject=vid-s1-abc\n' > .vid/runs/R1/holder
rq 20260101T110500Z-bbbb queued 'type=deployed role=fixer rows=2 silence=600 startup=300 limit=7200 created=1767265500'
printf 'stack.1: held by pid 1 — repository /w, compose project vid-s1-abc, for 30 s\n' > .vid/requests/20260101T110500Z-bbbb/holders
rq 20260101T110600Z-cccc queued 'type=iterate role=grader rows=1 silence=600 startup=300 limit=7200 created=1767265560'
rq 20260101T090000Z-dddd running 'type=iterate role=builder rows=16 estimate=1235 cap=2470 startup=35 created=1767258000'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
Q=$(vdata "$N" | grep -F '"queue":{')
printf '%s' "$Q" | grep -qF '"queue":{"environments":null,"taken":[{"slot":1,"ticket":"20260101T110000Z-aaaa","since":"2026-01-01T11:01:10Z","workingCopy":"agent-abc"}]' || fail "the environments or the slot taken: $Q"
printf '%s' "$Q" | grep -qF '{"ticket":"20260101T110000Z-aaaa","type":"iterate","role":"fixer","try":"1-fixer-1","rows":3,"since":"2026-01-01T11:01:00Z","limits":{"silence":600,"startup":300,"limit":7200}}' || fail "the running request: $Q"
printf '%s' "$Q" | grep -qF '{"ticket":"20260101T090000Z-dddd","type":"iterate","role":"builder","try":null,"rows":16,"since":"2026-01-01T09:00:00Z","limits":{"cap":2470}}' || fail "the older request's limits: $Q"
printf '%s' "$Q" | grep -qF '{"ticket":"20260101T110500Z-bbbb","type":"deployed","role":"fixer","try":null,"rows":2,"since":"2026-01-01T11:05:00Z","limits":{"silence":600,"startup":300,"limit":7200},"why":"stack.1: held by pid 1 — repository /w, compose project vid-s1-abc, for 30 s"}' || fail "the waiting request with holders: $Q"
printf '%s' "$Q" | grep -qF '{"ticket":"20260101T110600Z-cccc","type":"iterate","role":"grader","try":null,"rows":1,"since":"2026-01-01T11:06:00Z","limits":{"silence":600,"startup":300,"limit":7200},"why":null}' || fail "the waiting request without holders: $Q"
exit 0
