#!/bin/sh
# Purpose: selftest case — the section added, the same head asked again (0.26.10.29.5, DP-1 R8). At a head whose runs accept every
# row, a description with no Decisions section is posted `ticket: not yet` with the line `decisions missing — …`; the dev side adds
# the section, and the next decision at that same head, with no new head and no new report, is `ticket: accepted` without the line,
# and is posted, a second comment on the pull request. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-decide.sh"
fail() { echo "dp-r8-again: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
dpd_body 'ticket: #3'
dpd_dc --post; [ "$RC" = 0 ] || fail "decide exited $RC"; sed -n 2p "$T/out" | grep -qx 'ticket: not yet' && grep -q '^decisions missing — ' "$T/out" || fail 'a description with no section was not answered not yet with the line'
[ "$(ls "$T/gh/prs/4/comments" | wc -l | tr -d ' ')" = 1 ] || fail 'the first decision was not posted'
dpd_body 'ticket: #3

Decisions:
- pages hold 20 items | why: the list fits'
dpd_dc --post; [ "$RC" = 0 ] || fail "the second decide exited $RC"
sed -n 2p "$T/out" | grep -qx 'ticket: accepted' || fail 'the same head, the section added, was not accepted'
grep -q '^decisions missing' "$T/out" && fail 'the second decision still reads decisions missing'
[ "$(ls "$T/gh/prs/4/comments" | wc -l | tr -d ' ')" = 2 ] || fail 'the second decision was not posted'
last=$(ls "$T/gh/prs/4/comments" | sort -n | tail -n 1); sed -n 2p "$T/gh/prs/4/comments/$last" | grep -qx 'ticket: accepted' || fail 'the posted comment is not the accepted decision'
exit 0
