#!/bin/sh
# Purpose: selftest case — progress counts builders apart from the other roles, and by builder tool (v0.9.7.1 spec
# 3.11, 3.9; R11, R9). The plan fixture. build-cost events: two builders and a fixer (Claude), a builder on Codex, two
# graders and a test author. Convicts unless the Builders line counts 4 handed back (three builders and a fixer, never the other roles) and
# their rows; a Graders line says 2 returned with their tokens summed and a Test authors line 1; and the By builder
# tool line gives, per tool, the steps, follow-up briefs, rows passed at hand-back, those whose latest verdict is
# KEPT and BREACHED, law-needed lines, early hand-backs (a `not | none` line while the attempt's ticket still ran)
# and court refusals at commit (.vid/hook-times by worktree); v0.9.7.3: builders 0 (no agent-start here). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-roles: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; cp "$CHECKS/plan.sh" checks/; rows s1 1 4; rows s2 5 8; commit_all rows
plan 'step S1 | name: one | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004 | lane: builder' 'step S2 | name: two | modules: app/s2 | builds-on: - | rows: ROW-005..ROW-008 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two' --trigger initial --expect x > /dev/null
rcpt r1 HEAD inline ROW-001=passed
E=.vid/metrics-events; mkdir -p .vid/briefs/1 .vid/jobs/1-builder-3.wt
bc() { printf 'build-cost role=%s slice=1 step=%s brief=%s rows=%s rows-passed=%s peak=10 total=%s before-change=unknown tool=%s model=m effort=e brief-bytes=9 at=%s\n' "$@" "$(utcnow)" >> $E; }
for n in 1 2 3; do printf 'role: builder    slice: 1    step: S1\ntry: 1-builder-%s\n' $n > .vid/briefs/1/builder-$n.md; done
printf 'brief: x\nROW-001 | pass | r1\nROW-002 | pass | r1\n' > .vid/briefs/1/builder-1.return.md
printf 'brief: x\nROW-003 | not | none | law-needed: a seam row\n' > .vid/briefs/1/builder-2.return.md
printf 'brief: x\nROW-005 | pass | r1\nROW-006 | not | none | still testing\n' > .vid/briefs/1/builder-3.return.md
mkdir -p .vid/requests/T3; printf 'try=1-builder-3\n' > .vid/requests/T3/request; sleep 1; echo 0 > .vid/requests/T3/exit
bc builder S1 .vid/briefs/1/builder-1.md 2 2 100 claude
bc builder S1 .vid/briefs/1/builder-2.md 1 0 200 claude
bc fixer S1 .vid/briefs/1/fixer-1.md 1 1 50 claude
bc builder S2 .vid/briefs/1/builder-3.md 2 1 300 codex
bc grader - .vid/briefs/1/grader-1.md 2 - 1000 claude
bc grader - .vid/briefs/1/grader-2.md 2 - 2000 claude
bc test-author - .vid/briefs/1/test-author-1.md 1 - 500 claude
printf 'verdict slice=1 row=ROW-001 result=KEPT class=product brief=g quoted-at=x at=%s\nverdict slice=1 row=ROW-002 result=BREACHED class=product brief=g quoted-at=x at=%s\nverdict slice=1 row=ROW-005 result=KEPT class=product brief=g quoted-at=x at=%s\n' "$(utcnow)" "$(utcnow)" "$(utcnow)" >> $E
printf 'hook result=refused seconds=1 by=census checkout=1-builder-3.wt at=x\nhook result=refused seconds=1 by=census checkout=agent-abc at=x\nhook result=pass seconds=1 checkout=agent-abc at=x\n' > .vid/hook-times
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep -q '^| Builders | 4 handed back · rows passed 4 of 6 ' "$T/out" || fail "the Builders line does not count builders and fixers only: $(grep '^| Builders' "$T/out")"
grep -qx '| Graders | 2 returned · tokens 3000 (0 unknown) |' "$T/out" || fail 'no Graders line'
grep -qx '| Test authors | 1 returned · tokens 500 (0 unknown) |' "$T/out" || fail 'no Test authors line'
grep -qx '| By builder tool | claude: steps 1 · follow-up briefs 1 · rows passed 2 · kept 1 · breached since 1 · law-needed 1 · early hand-backs 0 · court refusals 1 · builders 0; codex: steps 1 · follow-up briefs 0 · rows passed 1 · kept 1 · breached since 0 · law-needed 0 · early hand-backs 1 · court refusals 1 · builders 0 |' "$T/out" || fail "the by-tool line is not as counted: $(grep '^| By builder tool' "$T/out")"
exit 0
