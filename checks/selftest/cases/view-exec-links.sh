#!/bin/sh
# Purpose: selftest case — an agent's brief only from a record that names both (v0.26.10.6 spec R3). The viewer fixture
# with planted agents: L1 linked by `agent-brief` (its step from its build-cost), L2 by a return file's `agent:` line
# (no build-cost: its step from its brief's `step:` header; its rows from its return's lines), a Codex job by its
# record, L4 whose `agent-brief` says `unavailable`, L5 an unlinked `vid:fixer`, L6 an unlinked `general-purpose`, and
# L7 started a minute after a fixer's brief was written, and L8 named by two return files written in the same second
# (fixer-11 accepted, then fixer-12 a second later). Convicts unless each link, try, role, slice, step and rows is
# as recorded, unless L4, L5, L6 and L7 link no brief (L5's role from its type, L6's none), and unless L8 links the
# newest return — of equal times, the later accepted (fixer-12). Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-links: $*" >&2; exit 1; }
view_project "$T/repo"
mkdir -p .vid/briefs/1 .vid/jobs
printf 'role: fixer    slice: 1    step: S1\n' > .vid/briefs/1/fixer-1.md
printf 'role: fixer    slice: 1    step: S2\n' > .vid/briefs/1/fixer-2.md
printf 'brief: .vid/briefs/1/fixer-2.md\nagent: L2\nROW-004 | pass | r2\nROW-005 | not | none | later\n' > .vid/briefs/1/fixer-2.return.md
printf 'step=S2\ntry=1-builder-20\nbrief=.vid/briefs/1/builder-20.md\nmodel=default\neffort=default\n' > .vid/jobs/1-builder-20
vev 11:00 'agent-start session=S1 agent=L1 type=vid:fixer'; vev 11:00:10 'agent-brief agent=L1 brief=.vid/briefs/1/fixer-1.md'
vev 11:04 'build-cost role=fixer slice=1 step=S1 brief=.vid/briefs/1/fixer-1.md rows=1 rows-passed=1 peak=5 total=9 before-change=unknown'
vev 11:00 'agent-start session=S1 agent=L2 type=vid:fixer'; vev 11:03 'agent-stop session=S1 agent=L2 type=vid:fixer transcript=-'
vev 11:00 'job-start try=1-builder-20 step=S2'
vev 11:00 'agent-start session=S1 agent=L4 type=vid:fixer'; vev 11:00:10 'agent-brief agent=L4 brief=unavailable'
vev 11:00 'agent-start session=S1 agent=L5 type=vid:fixer'
vev 11:00 'agent-start session=S1 agent=L6 type=general-purpose'
vev 11:09 'brief-written path=.vid/briefs/1/fixer-3.md role=fixer try=1-fixer-3 bytes=10'
vev 11:10 'agent-start session=S1 agent=L7 type=vid:fixer'
for n in 11 12; do printf 'brief: .vid/briefs/1/fixer-%s.md\nagent: L8\nROW-004 | pass | r2\n' $n > .vid/briefs/1/fixer-$n.return.md; touch -t 202601011130.00 .vid/briefs/1/fixer-$n.return.md; done
vev 11:00 'agent-start session=S1 agent=L8 type=vid:fixer'; vev 11:30 'agent-stop session=S1 agent=L8 type=vid:fixer transcript=-'
vev 11:31 'agent-returned role=fixer n=11 try=1-fixer-11'; vev 11:31:01 'agent-returned role=fixer n=12 try=1-fixer-12'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
ag() { vel "$N" "{\"id\":\"$1\",\"tool\":"; }
ag L1 | grep -qF '"role":"fixer","try":"1-fixer-1","step":"S1","slice":"1","brief":".vid/briefs/1/fixer-1.md","rows":null' || fail "L1's agent-brief link: $(ag L1)"
ag L1 | grep -qF '"linked":true' || fail "L1 is not linked"
ag L2 | grep -qF '"role":"fixer","try":"1-fixer-2","step":"S2","slice":"1","brief":".vid/briefs/1/fixer-2.md","rows":["ROW-004","ROW-005"]' || fail "L2's return-file link, step from its brief, rows: $(ag L2)"
ag codex:1-builder-20 | grep -qF '"role":"builder","try":"1-builder-20","step":"S2","slice":"1","brief":".vid/briefs/1/builder-20.md"' || fail "the job's link: $(ag codex:1-builder-20)"
for a in L4 L5 L7; do ag $a | grep -qF '"role":"fixer","try":null,"step":null,"slice":null,"brief":null' && ag $a | grep -qF '"linked":false' || fail "$a links a brief: $(ag $a)"; done
ag L6 | grep -qF '"role":null,"try":null' || fail "L6, a general-purpose agent, has a role or try: $(ag L6)"
ag L8 | grep -qF '"try":"1-fixer-12"' || fail "L8 does not link its newest return, the later accepted: $(ag L8)"
exit 0
