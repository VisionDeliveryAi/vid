#!/bin/sh
# Purpose: selftest case — a merge that states no decisions, and one whose description has no section (0.26.10.29.5, DP-1 R2).
# `decisions.sh record` writes nothing for pull request 5, whose description says `Decisions: none`, and records
# `decisions-recorded pr=5 n=none`; nothing for pull request 6, whose description has no Decisions section, nor an empty
# `Decisions:` line with no `- ` line under it, and records `decisions-recorded pr=6 n=missing`. No commit. Run again: neither
# description is read again and no event is added (n=missing is never tried again). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-none-missing: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
H0=$(git rev-parse HEAD); cp DECISIONS.md "$T/d0"
dpr_pr 5 3 'ticket: #3

Decisions: none'
dpr_pr 6 3 'ticket: #3

Decisions:

The rest of the description.'
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -q '^decisions-recorded pr=5 n=none at=' .vid/metrics-events || fail 'no event decisions-recorded pr=5 n=none'
grep -q '^decisions-recorded pr=6 n=missing at=' .vid/metrics-events || fail 'no event decisions-recorded pr=6 n=missing'
[ "$(git rev-parse HEAD)" = "$H0" ] || fail 'a commit with nothing to record'
cmp -s DECISIONS.md "$T/d0" || fail 'DECISIONS.md changed'
dpr_rec; [ "$RC" = 0 ] || fail "a second record exited $RC"
[ "$(dpr_reads 5)" = 1 ] && [ "$(dpr_reads 6)" = 1 ] || fail "a description was read again: pr 5 $(dpr_reads 5), pr 6 $(dpr_reads 6)"
[ "$(grep -c '^decisions-recorded ' .vid/metrics-events)" = 2 ] || fail 'an event was added again'
exit 0
