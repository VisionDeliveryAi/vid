#!/bin/sh
# Purpose: selftest case — the pending changes, read truly (GM-3 U1). On the planner's toy in GitHub manual, its spec committed
# and that commit recorded as the applied version: with nothing pending, `inventory.sh impact --tickets --detail` exits 0 and
# prints nothing, and `next.sh pending` prints nothing. With ROW-001's obligation restated in the working tree and impact made to
# fail with no output (a copy of checks/ whose inventory.sh exits 5 on impact), `next.sh pending` prints exactly
# `unread pending - impact exited 5` and exits non-zero, and `next.sh triggers` prints the same line, counts no reset test (the
# real checks/ count ROW-001 as reset) and goes on with its count and tiers lines, exit 0. Then a re-cut committed that moves
# ROW-019 alone to stage 2: `next.sh pending` prints exactly `pending moved-stage ROW-019` and `spec STAGES.md 1 lines`.
# then REQ-001's statement reworded, its fail-if kept, committed: `pending` prints `spec PRD.md 2 lines` too,
# first of the spec lines, and nothing else new. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "manual-pending-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw; git rev-parse HEAD > .vid/tw/applied
# nothing pending: impact exits 0 with nothing to print, and pending prints nothing
RC=0; sh "$CHECKS/inventory.sh" impact --base HEAD --tickets --detail > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "impact --tickets --detail exited $RC with nothing to print and nothing failed"
[ ! -s "$T/out" ] || fail 'impact --tickets --detail printed something with nothing changed'
RC=0; sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && [ ! -s "$T/out" ] || fail "with nothing pending, next.sh pending exited $RC or printed something"
# a pending reset, read by the real checks/: counted as reset
sed 's/^\(ROW-001 .*\)holding only jobs it has not sent before\./\1holding only jobs it has not sent before, newest first./' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
grep -q 'newest first' INVENTORY.md || fail 'the restatement did not land'
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed with the real checks/'
grep -qx "count${TB}reset${TB}1" "$T/out" || fail 'the real checks/ do not count ROW-001 as reset'
# impact made to fail with no output: a copy of checks/ whose inventory.sh exits 5 on impact
cp -R "$CHECKS" "$T/ck"; printf '#!/bin/sh\n[ "${1:-}" != impact ] || exit 5\nexec sh "%s/inventory.sh" "$@"\n' "$CHECKS" > "$T/ck/inventory.sh"
RC=0; sh "$T/ck/next.sh" pending > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] || fail 'a failed impact read as nothing pending: next.sh pending exited 0'
printf 'unread\tpending\t-\timpact exited 5\n' | cmp -s - "$T/out" || fail 'a failed impact does not print exactly the unread line, impact exited 5'
RC=0; sh "$T/ck/next.sh" triggers > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "triggers stopped on a failed impact ($RC): it prints the unread line and goes on"
grep -qx "unread${TB}pending${TB}-${TB}impact exited 5" "$T/out" || fail 'triggers does not print the unread line in the same words'
grep -qx "count${TB}reset${TB}0" "$T/out" || fail 'triggers counted a pending reset from a failed impact'
grep -q "^count${TB}total${TB}" "$T/out" && grep -q "^tiers${TB}" "$T/out" || fail 'triggers did not go on with its count and tiers lines'
git checkout -q -- INVENTORY.md
# a re-cut that moves ROW-019 alone to stage 2, committed: STAGES.md and the moved row show as pending
awk '{ print } /^row: ROW-004 -> STAGE-0$/ { print "row: ROW-019 -> STAGE-2" }' STAGES.md > "$T/s" && cat "$T/s" > STAGES.md
grep -qx 'row: ROW-019 -> STAGE-2' STAGES.md || fail 'the re-cut did not land'
g add STAGES.md; g commit -qm 'the re-cut: the footer waits for stage 2'
RC=0; sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "next.sh pending failed after the re-cut ($RC)"
printf 'pending\tmoved-stage\tROW-019\nspec\tSTAGES.md\t1 lines\n' | cmp -s - "$T/out" || fail 'a landed re-cut does not show as pending: exactly pending moved-stage ROW-019, then spec STAGES.md 1 lines'
# a PRD-only change, a requirement reworded with its fail-if kept, shows as pending
sed 's/^\(REQ-001 | functional | T1 | A subscriber receives one digest per saved search\) per day,/\1 each day,/' PRD.md > "$T/p" && cat "$T/p" > PRD.md
grep -q '^REQ-001 | functional | T1 | A subscriber receives one digest per saved search each day,' PRD.md || fail 'the PRD rewording did not land'
g add PRD.md; g commit -qm 'REQ-001 reworded, its fail-if kept'
RC=0; sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "next.sh pending failed after the PRD rewording ($RC)"
printf 'pending\tmoved-stage\tROW-019\nspec\tPRD.md\t2 lines\nspec\tSTAGES.md\t1 lines\n' | cmp -s - "$T/out" || fail 'a PRD-only change does not show as pending: exactly spec PRD.md 2 lines, first of the spec lines'
exit 0
