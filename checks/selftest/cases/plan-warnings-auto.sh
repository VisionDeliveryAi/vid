#!/bin/sh
# Purpose: selftest case — the publish warnings in GitHub auto, from the round's own read (GM-4 K9: plan.sh warnings and admit in
# both modes). On the ticket writer's toy (fixtures/tw-toy.sh) in GitHub auto, open-tickets: 1: the skeleton's ticket published and
# closed, S02's (stage 1) published and open; `round.sh read`, GitHub auto's read (no --bodies, so no ticket lines). Then
# `plan.sh warnings S05` (stage 2) prints the limit warning (1 open ticket, 2 with it, over 1) and stage-ahead (stage 2, ahead of
# stage 1, the lowest active stage), and `plan.sh admit S05` prints the same lines after its admit line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "plan-warnings-auto: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
tw_toy "$T/toy"; sed 's/^open-tickets: .*/open-tickets: 1/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
tw_skel || { cat "$T/sk" > "$T/out"; fail 'the skeleton round failed'; }; tw_close 1
tw_start S02 || { cp "$T/start" "$T/out"; fail 'S02 was not admitted'; }; tw_post step S02 || { cp "$T/werr" "$T/out"; fail "S02's ticket was not posted"; }
sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the round read failed'
! grep -q "^ticket${TB}" .vid/round/read || fail "GitHub auto's read holds ticket lines: the scene is wrong"
RC=0; sh "$CHECKS/plan.sh" warnings S05 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "plan.sh warnings S05 exited $RC"
grep -q "^warning${TB}publish${TB}S05${TB}limit${TB}1 open tickets, 2 with this one, over open-tickets: 1${TB}" "$T/out" || fail 'in GitHub auto S05 is not warned past the open-ticket limit'
grep -q "^warning${TB}publish${TB}S05${TB}stage-ahead${TB}stage 2, ahead of stage 1, the lowest active stage, whose [0-9]* tests are not yet accepted${TB}" "$T/out" || fail 'in GitHub auto S05 is not warned for its stage'
cp "$T/out" "$T/w"; RC=0; sh "$CHECKS/plan.sh" admit S05 > "$T/out" 2>&1 || RC=$?
grep "^warning${TB}" "$T/out" > "$T/aw" || :; cmp -s "$T/w" "$T/aw" || fail "plan.sh admit S05 does not print the same warnings (exit $RC)"
exit 0
