#!/bin/sh
# Purpose: selftest case — /vid mode manual takes over the published tickets (GM-1 S2, its case mode-switch-take-over). On the
# fake gh, a project with no RUN-STATE and three tickets: #1 published by hand in the project's own form, every part a comment;
# #2 posted by ViD, part 1 its body; #3 amended once, its older writing's comments marked replaced. The switch records each at its
# newest writing (the text joined from GitHub equal to that writing, #2 listed as taken over from its body), records and ratifies
# the plan, records the mode last, and the fake's write log shows writes to state-repo: alone, its lock freed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-switch-take-over: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"
mn_body ROW-003 ROW-004 > "$T/b1"; N1=$(gh_issue 'Skeleton' "$T/b1"); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; GW_KEPT=1; gh_writing "$N1" "$T/t1" comments 2; unset GW_KEPT   # its parts as GitHub may keep them
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step ROW-001 ROW-005 ROW-008 > "$T/t2"; gh_writing "$N2" "$T/t2" body 3
N3=$(gh_issue 'Step S03'); mn_ticket "$N3" S03 step ROW-006 > "$T/t3old"; gh_writing "$N3" "$T/t3old" comments 2; gh_replaced "$N3"
mn_ticket "$N3" S03 step ROW-006 ROW-007 > "$T/t3"; gh_writing "$N3" "$T/t3" comments 2
printf '%s S01\n%s S02\n%s S03\n' "$N1" "$N2" "$N3" > "$T/register"; gh_wclear
# the commit-msg court a project runs (its pre-commit courts need a whole project, which the toy is not) and a
# PLAN.md the owner brought changed, so the switch commits it through that court
mkdir -p "$T/hooks"; cp "$CHECKS/hooks/commit-msg" "$T/hooks/"; git config core.hooksPath "$T/hooks"; printf '\nBrought by the owner to the switch.\n' >> "$T/plan.md"
mn_switch --applied "$AP" --words 'yes, ratify the taken-over plan'
[ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
grep -qx 'mode: GitHub manual, recorded' "$T/mo" || fail 'the switch did not say the mode is recorded'
for k in 1 2 3; do eval "n=\$N$k"; grep -q "^published $n .* taken-over=" .vid/tw/log || fail "#$n has no taken-over published line"
  cmp -s ".vid/tw/out/issue-$n.md" "$T/t$k" || fail "#$n is not recorded at its newest writing"; done
grep -qx "from-body $N2" "$T/mo" || fail "#$N2 is not listed as taken over from its body"
grep -q "^published $N3 .*rows=ROW-006,ROW-007 " .vid/tw/log || fail "#$N3's line is not from its newest writing's header"
cmp -s PLAN.md "$T/plan.md" && [ -z "$(git status --porcelain -- PLAN.md)" ] && git log -1 --format=%s -- PLAN.md | grep -q 'taken over by /vid mode manual' || fail 'the PLAN.md the owner brought is not committed alone through the commit-msg court'
grep -q 'taken-over=body' .vid/tw/log && grep -q 'taken-over=comments' .vid/tw/log || fail 'the two forms are not both recorded'
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the plan is not ratified after the switch'; }
[ "$(sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS")" = manual ] || fail 'github-mode is not manual'
grep -q '^plan-change ' .vid/metrics-events && ls .vid/plans/decisions/*.why > /dev/null 2>&1 || fail 'the plan change is not recorded in .vid/plans/decisions/'
[ -s "$FAKEGH/writes" ] || fail 'the write log is empty: the lock and the records went nowhere'
grep -v '^owner/vid-state ' "$FAKEGH/writes" > "$T/w" && { cat "$T/w" >&2; fail 'a write went to a repository but state-repo:'; }
[ -z "$(mn_lock)" ] || fail 'the lock is held after the switch'
echo 'mode-switch-take-over: ok'
