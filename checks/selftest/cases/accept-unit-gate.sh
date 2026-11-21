#!/bin/sh
# Purpose: selftest case — a direct acceptance reads the units merged since the last call (GM-4 E4, E13): on GitHub manual's toy and the
# fake gh (fixtures/accept.sh), a unit merged under the step ticket with no Decisions section, and no round.sh step since: round.sh
# accept at the merge's commit records the merge in .vid/decide/unit-merges and answers `not yet`, naming the pull request, so the
# Decisions-section gate is never skipped. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "accept-unit-gate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
ac_unit unit-1 "$(printf 'ticket: #%s\n\nNo section.\n' "$AC_N")"; UP=$AC_P; ac_good "$AC_M"; ac_ask "$AC_M"
ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept exited $RC"
cut -f1 .vid/decide/unit-merges 2>/dev/null | grep -qx "$UP" || fail 'the direct acceptance did not record the unit merged since the last call'
ac_last | grep -qx 'ticket: not yet' && ac_last | grep -qx "no Decisions section — #$UP" || { ac_last > "$T/out"; fail 'the unit with no Decisions section did not hold the ticket'; }
! grep -q '^step-' .vid/decide/merges 2>/dev/null || fail 'the ticket was accepted past the gate'
exit 0
