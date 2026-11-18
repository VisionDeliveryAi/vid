#!/bin/sh
# Purpose: selftest case — a recording the hooks refuse (0.26.10.29.5, DP-1 R2). Pull request 7 names ticket 4, which the writer's
# log never published, so the pre-commit hook refuses `enforced: ticket 4`: `decisions.sh record` leaves DECISIONS.md and the
# index as HEAD has them, records `decisions-recorded pr=7 n=refused`, and prints `decisions refused pr=7 <the hook's first line>`.
# Run again: the description is not read again and nothing more is recorded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-refused: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
H0=$(git rev-parse HEAD)
sed -e 's/^- number: 3$/- number: 4/' -e 's/^- step: S01$/- step: S02/' .vid/tw/out/issue-3.md > .vid/tw/out/issue-4.md
dpr_pr 7 4 'ticket: #4

Decisions:
- notes sort by their last change | why: what users look for'
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -qx "decisions refused pr=7 ViD pre-commit: rejected — DECISIONS.md cites 'enforced: ticket 4', but the ticket writer's log published no ticket #4." "$T/out" || fail 'no line decisions refused pr=7 with the hook'"'"'s first line'
[ "$(git rev-parse HEAD)" = "$H0" ] || fail 'a refused recording committed'
git diff --quiet HEAD -- DECISIONS.md || fail 'DECISIONS.md is not as HEAD has it'
git diff --cached --quiet || fail 'the index is not as HEAD has it'
grep -q '^decisions-recorded pr=7 n=refused at=' .vid/metrics-events || fail 'no event decisions-recorded pr=7 n=refused'
dpr_rec; [ "$RC" = 0 ] || fail "a second record exited $RC"
[ "$(dpr_reads 7)" = 1 ] || fail 'a refused pull request was tried again'
[ "$(grep -c '^decisions-recorded pr=7 ' .vid/metrics-events)" = 1 ] || fail 'the refusal was recorded again'
grep -q '^decisions refused' "$T/out" && fail 'the refusal was printed again'
exit 0
