#!/bin/sh
# Purpose: selftest case — a hand-back and its acceptance (v0.26.10.6 spec R4). The viewer fixture with four planted
# hand-backs, each linked to its agent by `agent-brief`: accepted by `agent-returned try=`, accepted by `build-cost
# brief=` alone, with no acceptance recorded, and one whose "not" line's reason holds a `|`, with a report beside it.
# Convicts unless each hand-back's file, accepted, refusedAt (always null) and lines are as written, the report is
# seen, and the hand-back with no acceptance is listed in rework.noAcceptance. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-handbacks: $*" >&2; exit 1; }
view_project "$T/repo"
mkdir -p .vid/briefs/2
for n in 1 2 3 4; do printf 'role: fixer    slice: 2    step: S2\n' > .vid/briefs/2/fixer-$n.md
  vev 11:00 "agent-start session=S1 agent=K$n type=vid:fixer"; vev 11:00:10 "agent-brief agent=K$n brief=.vid/briefs/2/fixer-$n.md"; vev 11:05 "agent-stop session=S1 agent=K$n type=vid:fixer transcript=-"; done
printf 'brief: .vid/briefs/2/fixer-1.md\nROW-004 | pass | r2\n' > .vid/briefs/2/fixer-1.return.md; vev 11:06 'agent-returned role=fixer n=1 try=2-fixer-1'
printf 'brief: .vid/briefs/2/fixer-2.md\nROW-005 | pass | r2\n' > .vid/briefs/2/fixer-2.return.md; vev 11:06 'build-cost role=fixer slice=2 step=S2 brief=.vid/briefs/2/fixer-2.md rows=1 rows-passed=1 peak=5 total=9 before-change=unknown'
printf 'brief: .vid/briefs/2/fixer-3.md\nROW-005 | pass | r2\n' > .vid/briefs/2/fixer-3.return.md
printf 'brief: .vid/briefs/2/fixer-4.md\nROW-004 | pass | r2\nROW-005 | not | none | the price a | b split\n' > .vid/briefs/2/fixer-4.return.md; vev 11:07 'agent-returned role=fixer n=4 try=2-fixer-4'
printf '# report\n' > .vid/briefs/2/fixer-4.report.md
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
ag() { vel "$N" "{\"id\":\"$1\",\"tool\":"; }
ag K1 | grep -qF '"handBack":{"file":".vid/briefs/2/fixer-1.return.md","accepted":true,"refusedAt":null,"lines":[{"row":"ROW-004","result":"pass","receipt":"r2","reason":null}],"report":false}' || fail "K1's hand-back: $(ag K1)"
ag K2 | grep -qF '"handBack":{"file":".vid/briefs/2/fixer-2.return.md","accepted":true,' || fail "K2, accepted by build-cost alone: $(ag K2)"
ag K3 | grep -qF '"handBack":{"file":".vid/briefs/2/fixer-3.return.md","accepted":false,"refusedAt":null,' || fail "K3, no acceptance recorded: $(ag K3)"
ag K4 | grep -qF '{"row":"ROW-005","result":"not","receipt":null,"reason":"the price a | b split"}],"report":true}' || fail "K4's not line or report: $(ag K4)"
vel "$N" '"noAcceptance":[' | grep -qF '"noAcceptance":[{"try":"2-fixer-3","file":".vid/briefs/2/fixer-3.return.md","refusedAt":null}]' || fail "noAcceptance: $(vel "$N" '"noAcceptance":[')"
exit 0
