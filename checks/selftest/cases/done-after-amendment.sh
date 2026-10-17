#!/bin/sh
# Purpose: selftest case — done is never read back (v0.9.7.2 spec 3.6, R9; rehearsal R-5). S1 done and stamped; ROW-002
# is amended: S1 is at once not graded and not done, ROW-002 named, and the stamp stays where it was (one line, not
# rewritten, not removed). A KEPT verdict quoted after the amendment makes it done again, with no second stamp.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "done-after-amendment: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" > /dev/null
sh checks/plan.sh start S1 > /dev/null; close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null; keepall ROW-001 ROW-002 ROW-003 ROW-004
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* done=yes ' "$T/out" || fail 'S1 is not done'
ST=$(grep '^step-done step=S1 ' .vid/metrics-events)
echo b >> app/s1/main.py; commit_all 'amend ROW-002'
printf 'amended row=ROW-002 sha=%s at=%s\n' "$(git rev-parse HEAD)" "$(utcnow)" >> .vid/metrics-events
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* graded=no done=no ' "$T/out" || fail 'the amended row left S1 done'
grep -q '^ungraded step=S1 row=ROW-002' "$T/out" || fail 'ROW-002 is not named'
[ "$(grep '^step-done step=S1 ' .vid/metrics-events)" = "$ST" ] || fail 'the stamp changed'
verdict ROW-002 KEPT
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* done=yes ' "$T/out" || fail 'the fresh KEPT did not make S1 done'
[ "$(grep -c '^step-done step=S1 ' .vid/metrics-events)" -eq 1 ] || fail 'a second stamp was written'
exit 0
