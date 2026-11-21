#!/bin/sh
# Purpose: selftest case — team changes post through K1's one path (GM-4 F5): checks/team-change.sh's yes amends the tickets the change
# reaches through github.sh tw-hand, never tw-post or tw-close of its own. On the form fixture's toy (fixtures/form.sh), S03 posted
# over its unclosed builds-on and the team adding ROW-002 to its body, the yes to ROW-002 amends S03's ticket as tw-hand does it: the
# lock taken on the state repository and freed (no session held it), the amendment saved to the state repository's records, its line
# holding the words. team-change.sh names no tw-post, tw-close, spec-export or tw-sync call of its own. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "team-change-hand: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^closed S01 ' .vid/tw/handed > "$T/h" && cat "$T/h" > .vid/tw/handed
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted over its unclosed builds-on'; }; N=$FM_N
printf 'Also ROW-002, the team adds it.\n' >> "$FAKEGH/issues/$N/body"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
: > "$FAKEGH/locks"
RC=0; CLAUDE_CODE_SESSION_ID=owner-t sh "$CHECKS/team-change.sh" "$N" ROW-002 yes "Yes, take ROW-002 into #$N" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the yes exited $RC"
grep -q "^amended $N .*added=ROW-002.* words=\"Yes, take ROW-002 into #$N\"" .vid/tw/log || fail 'S03 was not amended with the words'
grep -q '^owner/vid-state taken$' "$FAKEGH/locks" && grep -q '^owner/vid-state freed$' "$FAKEGH/locks" || fail "the amendment did not take and free the lock as tw-hand does: $(cat "$FAKEGH/locks")"
git --git-dir="$FAKEGH/repos/owner%vid-state/remote.git" show refs/heads/vid-state/records:tw/log 2>/dev/null | grep -q "^amended $N .*added=ROW-002" || fail 'the amendment is not in the saved records, as tw-hand saves it'
grep -nE 'github\.sh" (tw-post|tw-close|spec-export|tw-sync)' "$CHECKS/team-change.sh" > "$T/out" && fail 'team-change.sh still posts or prepares on its own, beside tw-hand'
exit 0
