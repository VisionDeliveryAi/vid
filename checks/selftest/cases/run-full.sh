#!/bin/sh
# Purpose: selftest case — `github.sh run-full` (v0.26.10.12 spec R3, R9). The planner's toy (fixtures/tickets.sh gh_vid)
# and the fake gh, the vid-code block holding the test facts. Refused, with no manual start and nothing recorded: a
# vid-code block with no run-full: (naming it); no merged pull request of the stage. With run-full: and a merged
# skeleton pull request (its merge on main), run-full starts `gh workflow run CI … --ref main`, finds the new
# workflow_dispatch run and records `run-full started run=<id> attempt=1 sha=<main's tip, 12>`. A recorded merge the
# run's commit does not descend from (a commit off main) is refused, naming the pull request, and nothing more is
# recorded. `workflow run` is on github.sh's allow-list and in its header. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "run-full: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
awk '/^labels-prefix:/ { print; print "test-framework: the toy runner"; print "test-dir: tests/invariants"; print "run-one: sh tests/run.sh <names>"; print "ci-workflow: CI"; print "report: vid-junit-<run attempt>"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
g add -A && g commit -qm 'the test facts'
nev() { grep -c '^run-full ' .vid/metrics-events || true; }
ndisp() { grep -c '^gh workflow run' "$T/gh/log" 2>/dev/null || true; }
# no run-full: key
if sh checks/github.sh run-full > "$T/out" 2>&1; then fail 'run-full ran without run-full: in the vid-code block'; fi
grep -q 'names no run-full:' "$T/out" || fail 'the refusal does not name run-full:'
[ "$(ndisp)" = 0 ] && [ "$(nev)" = 0 ] || fail 'the refused run-full started or recorded something'
awk '{ print } /^report:/ { print "run-full: gh workflow run CI --ref main" }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A && g commit -qm 'run-full'
# no merged pull request
if sh checks/github.sh run-full > "$T/out" 2>&1; then fail 'run-full ran with nothing merged'; fi
grep -q 'is merged' "$T/out" && [ "$(ndisp)" = 0 ] || fail 'the refusal with nothing merged is wrong'
# a merged skeleton pull request: its merge commit on main
sh checks/ticket.sh skeleton-body --req REQ-001 > /dev/null 2>&1; sh checks/github.sh publish --ticket .vid/tickets/skeleton.md > /dev/null 2>&1 || fail 'the skeleton was not published'
NS=$(awk '$1 == "ticket" && / kind=skeleton / { sub(/number=/, "", $2); print $2 }' .vid/tickets/map)
tk_dev 'Merge pull request #7 from owner/vid-1' app/main.py 'main'; M=$(git -C "$T/dev" rev-parse HEAD)
mkdir -p .vid/tickets/pr-7; printf 'number=7 ticket=%s state=merged draft=false head=%s merge=%s branch=vid/%s\n' "$NS" "$M" "$M" "$NS" > .vid/tickets/pr-7/meta
sh checks/github.sh run-full > "$T/out" 2>&1 || fail 'run-full was refused'
grep -qx 'gh workflow run CI -R owner/code --ref main' "$T/gh/log" || fail 'no manual start of CI on main was made'
R=$(awk '$5 == "workflow_dispatch" { print $1 }' "$T/gh/runs" | tail -n 1); M12=$(printf '%s' "$M" | cut -c1-12)
grep -q "^run-full started run=$R attempt=1 sha=$M12 at=" .vid/metrics-events || fail 'run-full started is not recorded with the run and main'"'"'s tip'
grep -q "pull --commit $M12" "$T/out" || fail 'run-full does not say how to pull the run'
# a recorded merge off main: refused, nothing more recorded
( cd "$T/dev" && git checkout -q -b side && printf 'x\n' > s.txt && git add s.txt && g commit -qm side && git push -q origin side 2>/dev/null && git checkout -q main )
X=$(git -C "$T/dev" rev-parse side); mkdir -p .vid/tickets/pr-8; printf 'number=8 ticket=%s state=merged draft=false head=%s merge=%s branch=vid/%s\n' "$NS" "$X" "$X" "$NS" > .vid/tickets/pr-8/meta
git -C .vid/code fetch -q origin side 2>/dev/null || true
E0=$(nev)
if sh checks/github.sh run-full > "$T/out" 2>&1; then fail 'a run not descending from a merge was recorded'; fi
grep -q 'does not descend from the merge of pull request #8' "$T/out" || fail 'the descent refusal does not name the pull request'
[ "$(nev)" = "$E0" ] || fail 'the refused run-full recorded an event'
# the allow-list and the header
GS=$CHECKS/github.sh
grep -q "'workflow run') ;;" "$GS" || fail 'workflow run is not on the allow-list'
grep -q '^# .*gh workflow run' "$GS" || fail "github.sh's header does not name gh workflow run"
exit 0
