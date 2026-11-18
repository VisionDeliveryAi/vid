#!/bin/sh
# Purpose: selftest case — `none` is only the line itself (0.26.10.29.5, DP-1 R2, R8). A description whose only Decisions line is
# `Decisions: none of the choices have been documented yet` has no section (`decisions.sh section`, the one reader decide.sh
# uses, prints `missing`), while `Decisions: none` and `Decisions: none — nothing surprising` are none; and a section bullet whose
# words begin with None, `- None of the session tokens are stored | why: prevent replay`, is a decision `decisions.sh record`
# records like any other. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-none-words: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sec() { printf '%s\n' "$1" > "$T/b"; sh checks/decisions.sh section "$T/b"; }
[ "$(sec 'ticket: #3

Decisions: none of the choices have been documented yet')" = missing ] || fail "a Decisions line that only begins with none was read as a section: $(sec 'Decisions: none of the choices have been documented yet')"
[ "$(sec 'Decisions: none')" = none ] || fail 'Decisions: none is not none'
[ "$(sec 'Decisions: none — nothing surprising')" = none ] || fail 'Decisions: none — <words> is not none'
dpr_pr 5 3 'ticket: #3

Decisions:
- None of the session tokens are stored | why: prevent replay'
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -qF -- '- **D-002** None of the session tokens are stored | why: prevent replay | enforced: ticket 3 |' DECISIONS.md || fail 'a bullet beginning with None was not recorded'
grep -q '^decisions-recorded pr=5 n=1 at=' .vid/metrics-events || fail 'no event decisions-recorded pr=5 n=1'
exit 0
