#!/bin/sh
# Purpose: selftest case — nothing recorded while a draft waits on the owner (0.26.10.29.5, DP-1 R2). With draft 2 made by
# `land.sh draft` and neither landed, declined nor replaced (draft 1 landed), `decisions.sh record` prints
# `decisions wait draft=2`, reads no description, commits nothing and records no event, as a commit would make the draft stale and
# its landing would drop the lines. Once the draft is declined, the next record records the merge's line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-draft-wait: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
H0=$(git rev-parse HEAD)
mkdir -p .vid/decide/drafts/1/files .vid/decide/drafts/2/files; git rev-parse HEAD > .vid/decide/drafts/1/base; echo abcdef012345 > .vid/decide/drafts/1/landed; git rev-parse HEAD > .vid/decide/drafts/2/base; echo '/vid add: a footer' > .vid/decide/drafts/2/why
dpr_pr 5 3 'ticket: #3

Decisions:
- pages hold 20 items | why: the list fits'
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -qx 'decisions wait draft=2' "$T/out" || fail 'no line decisions wait draft=2'
[ "$(git rev-parse HEAD)" = "$H0" ] || fail 'a commit while a draft waits'
grep -q 'D-002' DECISIONS.md && fail 'a line written while a draft waits'
[ "$(dpr_reads 5)" = 0 ] || fail 'the description was read while a draft waits'
grep -q '^decisions-recorded ' .vid/metrics-events 2>/dev/null && fail 'an event while a draft waits'
touch .vid/decide/drafts/2/declined; dpr_rec; [ "$RC" = 0 ] || fail "record after the draft was declined exited $RC"
grep -q '^- \*\*D-002\*\* pages hold 20 items | why: the list fits | enforced: ticket 3 |' DECISIONS.md || fail 'the line was not recorded once the draft was settled'
grep -q '^decisions-recorded pr=5 n=1 at=' .vid/metrics-events || fail 'no event once the draft was settled'
exit 0
