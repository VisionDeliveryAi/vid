#!/bin/sh
# Purpose: selftest case — a pull request not merged leaves nothing (0.26.10.29.5, DP-1 R2). Pull request 8 is open, 9 was withdrawn
# (closed, not merged) and 10 merged with no decision of ViD's (in merged-prs, not in merges), each with a Decisions section:
# `decisions.sh record` reads none of their descriptions, writes nothing and records no event, as their code never landed through
# a decision. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-unmerged: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
H0=$(git rev-parse HEAD); cp DECISIONS.md "$T/d0"
B='ticket: #3

Decisions:
- notes sort by their last change | why: what users look for'
dpr_pr 8 3 "$B" OPEN; dpr_pr 9 3 "$B" CLOSED; dpr_pr 10 3 "$B" CLOSED; echo MERGED > "$T/gh/prs/10/state"; echo 10 >> .vid/decide/merged-prs
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
for p in 8 9 10; do [ "$(dpr_reads $p)" = 0 ] || fail "pull request $p's description was read"; done
[ "$(git rev-parse HEAD)" = "$H0" ] && cmp -s DECISIONS.md "$T/d0" || fail 'a line was recorded from a pull request ViD never decided merged'
grep -q '^decisions-recorded ' .vid/metrics-events 2>/dev/null && fail 'an event for a pull request ViD never decided merged'
exit 0
