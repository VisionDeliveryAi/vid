#!/bin/sh
# Purpose: selftest case — a first post in GitHub manual sets the parent and the blocked-by links, and a need published later
# links the earlier ticket without touching its body (GM-2 T3, T11; its case manual-form-links). On the form fixture's toy
# (fixtures/form.sh; issue-parent: the epic): S02 posted is a sub-issue of the epic with no blocked-by link (S01, its need,
# has no ticket); S04 posted is a sub-issue of the epic blocked by S02's issue alone: S03, its other need, has no ticket, and
# S05, worked against through fakes, is never linked. The team then edits S04's body on GitHub. S03 posted later, with a
# title in the owner's words; S04's issue gains its blocked-by link to S03's, and S04's body stands byte for byte as the team
# left it; the post's writes are the labels, the issue, its part comments, its parent link and that one blocked-by link.
# S05, the step S04 fakes, posted after S04 with issue-parent: naming no issue: its parent link fails, its
# blocked-by link to S02's issue is still made, the refusal names the failed link (exit 1, the ticket posted and recorded once), and
# S04 is not blocked by S05. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "manual-form-links: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
printf 'issue-parent: %s\n' "$FM_P" >> .vid/tw/settings
I=$FAKEGH/issues
bl() { cat "$I/$1/blocked-by" 2>/dev/null | paste -sd , -; }
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
[ "$(cat "$I/$N2/parent" 2>/dev/null)" = "$FM_P" ] || fail "S02's issue #$N2 is not a sub-issue of the epic #$FM_P"
[ -z "$(bl "$N2")" ] || fail "S02's issue is blocked by $(bl "$N2"), though S01 has no ticket"
grep -q "^owner/code sub-issue $FM_P $N2\$" "$FAKEGH/writes" || fail 'the sub-issue link is not in the write log'
fm_post S04 || { cp "$T/post" "$T/out"; fail 'S04 was not posted in manual'; }; N4=$FM_N
[ "$(cat "$I/$N4/parent" 2>/dev/null)" = "$FM_P" ] || fail "S04's issue #$N4 is not a sub-issue of the epic"
[ "$(bl "$N4")" = "$N2" ] || fail "S04's issue is blocked by '$(bl "$N4")', not by S02's #$N2 alone (S03 has no ticket, S05 is a fake)"
# the team edits S04's body on GitHub
fm_team_edit "$N4" 's/^The toy team.s own checklist line\.$/The toy team'"'"'s own checklist line, edited on GitHub./'
grep -q 'edited on GitHub' "$I/$N4/body" || fail 'the team edit did not take'
cp "$I/$N4/body" "$T/b4"; gh_wclear
fm_post S03 --title 'The mail step, as the owner names it' || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; N3=$FM_N
[ "$(cat "$I/$N3/title")" = 'The mail step, as the owner names it' ] || fail "S03's title is not the one the move gave: $(cat "$I/$N3/title")"
[ "$(bl "$N4")" = "$N2,$N3" ] || fail "S04's issue is blocked by '$(bl "$N4")' once S03 is out, not by #$N2 and #$N3"
cmp -s "$T/b4" "$I/$N4/body" || { diff "$T/b4" "$I/$N4/body" > "$T/out" || :; fail "S04's body changed when S03 was published"; }
[ -z "$(bl "$N3")" ] || fail "S03's issue is blocked by $(bl "$N3"), though S01 has no ticket"
[ "$(cat "$I/$N3/parent" 2>/dev/null)" = "$FM_P" ] || fail "S03's issue is not a sub-issue of the epic"
# the writes of S03's post, and nothing else
M=$(ls "$I/$N3/comments" | grep -c .)
{ printf 'owner/code label create\nowner/code label create\nowner/code issue create\n'; k=0; while [ "$k" -lt "$M" ]; do echo "owner/code comment $N3"; k=$((k + 1)); done
  printf 'owner/code sub-issue %s %s\nowner/code blocked-by %s %s\n' "$FM_P" "$N3" "$N4" "$N3"; } | sort > "$T/want"
sort "$FAKEGH/writes" > "$T/got"; cmp -s "$T/want" "$T/got" || { diff "$T/want" "$T/got" > "$T/out" || :; fail "S03's post wrote other than its issue, its parts, its parent link and S04's blocked-by link"; }
# a link that fails stops no other, and is named: S05 (faked by S04, building on S02) under an issue-parent: that is no issue
grep -v '^issue-parent:' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings; printf 'issue-parent: 999\n' >> .vid/tw/settings
if fm_post S05; then fail "S05's post under no such parent was not refused"; fi
N5=$(sed -n 's/.*ticket #\([0-9]*\) is posted and recorded.*/\1/p' "$T/post" | head -n 1); cp "$T/post" "$T/out"
[ -n "$N5" ] || fail "S05's refusal does not say its ticket is posted and recorded"
grep -q "#$N5 could not be made a sub-issue of #999" "$T/post" || fail "S05's refusal does not name its failed parent link"
[ "$(grep -c "^published $N5 " .vid/tw/log)" = 1 ] || fail "S05's ticket #$N5 is not recorded once"
[ "$(bl "$N5")" = "$N2" ] || fail "S05's issue is blocked by '$(bl "$N5")', not by S02's #$N2: its parent link's failure stopped it"
[ "$(bl "$N4")" = "$N2,$N3" ] || fail "S04's issue is blocked by '$(bl "$N4")' once S05, a fake of it, is out"
! grep -q "^owner/code blocked-by $N4 $N5\$" "$FAKEGH/writes" || fail 'S04 was linked as blocked by S05, a step it fakes'
exit 0
