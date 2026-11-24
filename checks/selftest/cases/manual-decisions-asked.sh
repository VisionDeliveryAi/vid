#!/bin/sh
# Purpose: selftest case — the Decisions section is asked of a ticket only by its published writing (FB-3 A1.2), on GitHub manual's toy and
# the fake gh (fixtures/accept.sh). A unit merged with no Decisions section under a ticket whose writing never asks for one: accepted,
# the pull request named in its decision. Under a ticket whose writing asks for it: `not yet` as before, naming the pull request, and
# accepted once the description has one. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-decisions-asked: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; sed '/^Decisions: /d' ".vid/tw/out/issue-$AC_N.md" > "$T/i" && cat "$T/i" > ".vid/tw/out/issue-$AC_N.md"
for how in silent asks; do
  [ "$how" = silent ] || { AC_N=$(gh_issue 'Step S03'); { mn_ticket "$AC_N" S03 step ROW-001 ROW-012; printf '\nDecisions: the pull request'"'"'s body holds a section that begins with the line Decisions:.\n\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"; printf 'published %s kind=step step=S03 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$AC_N" >> .vid/tw/log; }
  ac_unit "unit-$how" "$(printf 'ticket: #%s\n\nNo section.\n' "$AC_N")"; m12=$(printf %s "$AC_M" | cut -c1-12); ac_report "run-$how" 'A. Person' "$AC_M" 'u.xml=ROW-001=pass ROW-012=pass'; ac_grade "$AC_M"; ac_ask "$AC_M"; ac_round accept "$AC_N"
  if [ "$how" = silent ]; then grep -qx "accepted #$AC_N $m12" "$T/out" && ac_last | grep -qx "no Decisions section — #$AC_P" || { ac_last >> "$T/out"; fail 'a ticket that never asked for the section was held for it, or not told'; }
  else grep -qx "decided #$AC_N $m12 ticket: not yet" "$T/out" && ac_last | grep -qx "no Decisions section — #$AC_P" || { ac_last >> "$T/out"; fail 'a ticket that asks for the section was accepted without it'; }
    printf 'ticket: #%s\n\nDecisions: none\n' "$AC_N" > "$FAKEGH/prs/$AC_P/body"; ac_ask "$AC_M"; ac_round accept "$AC_N"; grep -qx "accepted #$AC_N $m12" "$T/out" || fail 'the section, added, did not let the ticket be accepted'; fi; done
exit 0
