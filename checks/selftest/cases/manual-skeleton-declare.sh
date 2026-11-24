#!/bin/sh
# Purpose: selftest case — a skeleton accepted in GitHub manual names the engines and the environments from any report at its commit (FB-3
# A1.3), on the manual toy and the fake gh (fixtures/accept.sh): two reports of a team's, `ci-9` by a person with an `engines:` line and
# `ci-10` by another with an `environments:` line, the rows passing; with ViD's own review the skeleton is accepted, the handed record's
# engines line and the budget's stacks and unverified rows hold what they declare. A report at another commit that
# declares others changes nothing. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-skeleton-declare: $*" >&2; cat "$T/out" .vid/tw/handed .vid/budget >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; c12=$(printf %s "$AC_C" | cut -c1-12)
sed 's/^- kind: step$/- kind: skeleton/' ".vid/tw/out/issue-$AC_N.md" > "$T/i" && cat "$T/i" > ".vid/tw/out/issue-$AC_N.md"; sed "s/^published $AC_N kind=step /published $AC_N kind=skeleton /" .vid/tw/log > "$T/l" && cat "$T/l" > .vid/tw/log
! grep -q '^engines ' .vid/tw/handed 2>/dev/null || fail 'the fixture: the engines are named already'
put() { rr_put "$1" results.txt "$(printf 'by: %s\ncommit: %s\n%s' "$2" "$3" "$4")"; rr_put "$1" suite.xml "$(rr_cases ROW-001=pass ROW-012=pass)"; ac_send "$1"; }
put ci-9 'A. Person' "$AC_C" 'engines: alpha beta'; put ci-10 'B. Person' "$AC_C" 'environments: 2'; put ci-8 'A. Person' "$AC_RED" "$(printf 'engines: gamma\nenvironments: 7')"
ac_grade "$AC_C"; ac_ask "$AC_C"; ac_round accept "$AC_N"; [ "$RC" = 0 ] && grep -qx "accepted #$AC_N $c12" "$T/out" || fail "the skeleton was not accepted: exit $RC"
grep -qx 'engines alpha beta | stand-in: results reader' .vid/tw/handed || fail 'the engines a report at the commit declares are not on the handed record'
grep -qx 'stacks=2' .vid/budget && grep -qx 'unverified-rows=120' .vid/budget || fail 'the environments a report at the commit declares are not in the budget'
exit 0
