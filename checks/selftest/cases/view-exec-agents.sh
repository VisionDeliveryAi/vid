#!/bin/sh
# Purpose: selftest case — every Claude agent, with its runs (v0.26.10.6 spec R1, R9). The viewer fixture with planted
# agent records: R resumed (three runs, 480 s), N started twice and stopped once (the first run's end not recorded,
# its seconds null), X stopped with no start, H ended by `agent-returned agent=` (linked by agent-brief, accepted:
# returned), C ended by `build-cost agent=`, O open (working), D's one run stopped twice, U linked to a hand-back with
# no acceptance (unaccepted), and a brief written a minute before O starts, which must not link to it. Convicts unless
# each agent's runs, ends, seconds and state are as recorded, and unless the Delivery page's agents now names O with
# no hand-back (none paired by time). Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-agents: $*" >&2; exit 1; }
view_project "$T/repo"
vev 11:00 'agent-start session=S1 agent=R type=vid:fixer'; vev 11:05 'agent-stop session=S1 agent=R type=vid:fixer transcript=-'
vev 11:06 'agent-start session=S1 agent=R type=vid:fixer'; vev 11:08 'agent-stop session=S1 agent=R type=vid:fixer transcript=-'
vev 11:09 'agent-start session=S1 agent=R type=vid:fixer'; vev 11:10 'agent-stop session=S1 agent=R type=vid:fixer transcript=-'
vev 11:00 'agent-start session=S1 agent=N type=general-purpose'; vev 11:02 'agent-start session=S1 agent=N type=general-purpose'; vev 11:03 'agent-stop session=S1 agent=N type=general-purpose transcript=-'
vev 11:04 'agent-stop session=S1 agent=X type=general-purpose transcript=-'
mkdir -p .vid/briefs/1
printf 'role: builder    slice: 1    step: S2\n' > .vid/briefs/1/builder-2.md; printf 'role: builder    slice: 1    step: S2\n' > .vid/briefs/1/builder-3.md
printf 'brief: .vid/briefs/1/builder-2.md\nROW-004 | pass | r2\n' > .vid/briefs/1/builder-2.return.md
printf 'brief: .vid/briefs/1/builder-3.md\nROW-005 | not | none | not built\n' > .vid/briefs/1/builder-3.return.md
vev 11:00 'agent-start session=S1 agent=H type=vid:builder'; vev 11:00:30 'agent-brief agent=H brief=.vid/briefs/1/builder-2.md'
vev 11:05 'agent-returned role=builder n=2 try=1-builder-2 agent=H'
vev 11:00 'agent-start session=S1 agent=C type=vid:grader'; vev 11:06 'build-cost role=grader slice=1 step=- brief=.vid/briefs/1/grader-1.md rows=1 rows-passed=- peak=5 total=9 before-change=unknown agent=C'
vev 11:00 'agent-start session=S1 agent=D type=vid:grader'; vev 11:01 'agent-stop session=S1 agent=D type=vid:grader transcript=-'; vev 11:01:30 'agent-stop session=S1 agent=D type=vid:grader transcript=-'
vev 11:00 'agent-start session=S1 agent=U type=vid:builder'; vev 11:00:30 'agent-brief agent=U brief=.vid/briefs/1/builder-3.md'; vev 11:02 'agent-stop session=S1 agent=U type=vid:builder transcript=-'
vev 11:19 'brief-written path=.vid/briefs/1/builder-9.md role=builder try=1-builder-9 bytes=10'
vev 11:20 'agent-start session=S1 agent=O type=vid:builder'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
ag() { vel "$N" "{\"id\":\"$1\",\"tool\":\"claude\""; }
ag R | grep -qF '"runs":[{"started":"2026-01-01T11:00:00Z","ended":"2026-01-01T11:05:00Z","endedBy":"stop"},{"started":"2026-01-01T11:06:00Z","ended":"2026-01-01T11:08:00Z","endedBy":"stop"},{"started":"2026-01-01T11:09:00Z","ended":"2026-01-01T11:10:00Z","endedBy":"stop"}],"seconds":480,"state":"ended"' || fail "R's three runs are not as recorded: $(ag R)"
ag R | grep -qF '"session":"S1","type":"vid:fixer","started":"2026-01-01T11:00:00Z","role":"fixer"' || fail "R's session, type, start or role: $(ag R)"
ag N | grep -qF '"runs":[{"started":"2026-01-01T11:00:00Z","ended":null,"endedBy":null},{"started":"2026-01-01T11:02:00Z","ended":"2026-01-01T11:03:00Z","endedBy":"stop"}],"seconds":null,"state":"ended"' || fail "N's first run is not 'end not recorded': $(ag N)"
ag N | grep -qF '"role":null' || fail "an unlinked general-purpose agent has a role: $(ag N)"
ag X | grep -qF '"started":null' && ag X | grep -qF '"runs":[{"started":null,"ended":"2026-01-01T11:04:00Z","endedBy":"stop"}],"seconds":null' || fail "X's stop with no start: $(ag X)"
ag H | grep -qF '"runs":[{"started":"2026-01-01T11:00:00Z","ended":"2026-01-01T11:05:00Z","endedBy":"hand-back"}]' || fail "H's run is not ended by its hand-back: $(ag H)"
ag H | grep -qF '"state":"returned"' || fail "H is not returned: $(ag H)"
ag C | grep -qF '"endedBy":"cost"}]' || fail "C's run is not ended by its cost: $(ag C)"
ag O | grep -qF '"runs":[{"started":"2026-01-01T11:20:00Z","ended":null,"endedBy":null}]' && ag O | grep -qF '"state":"working"' || fail "O is not working: $(ag O)"
ag O | grep -qE '"seconds":[0-9]+,' || fail "O's open run has no seconds to the snapshot's time: $(ag O)"
ag O | grep -qF '"linked":false' || fail "O was linked to a brief by time: $(ag O)"
[ "$(ag D | grep -o '"endedBy"' | wc -l | tr -d ' ')" = 1 ] || fail "D's stop written twice made two runs: $(ag D)"
ag U | grep -qF '"state":"unaccepted"' || fail "U, handed back with no acceptance recorded, is not unaccepted: $(ag U)"
# R9: agents now — O with no hand-back paired by time; R, H, U not open
vdata "$N" | grep -qF '{"name":"builder O (since 2026-01-01T11:20:00Z)","handBack":""}' || fail "agents now does not name O alone, unpaired: $(vdata "$N" | grep -o '"agentsOpen":\[[^]]*\]')"
vdata "$N" | grep -o '"agentsOpen":\[[^]]*\]' | grep -qF 'builder-9' && fail 'agents now paired a brief by time'
vdata "$N" | grep -o '"agentsOpen":\[[^]]*\]' | grep -qE '"(fixer|builder) (R|H|U) ' && fail 'agents now names an agent whose run ended'
exit 0
