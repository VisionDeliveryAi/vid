#!/bin/sh
# Purpose: selftest case — the spec where the team reads it, one repository (GM-4 K13, J4): `github.sh spec-publish` on the fake gh.
# GitHub manual (the form fixture's toy) with layout: one, spec-path: upstream/vid and spec-stamp: STAMP, after the export: the call
# makes, through the git data API alone, a branch whose commit changes nothing outside upstream/vid/ against main, holds there each
# file of the export as it is and STAMP naming the export commit, then a pull request of that branch and a publish ticket naming it;
# logged `spec-published pr=<n> export=<12 hex> path=upstream/vid stamp=STAMP at=<time> words="<the words>"` (GM-4 K13: the publish names its folder and stamp;
# FB-1 B6: the owner's words given with --words, last on the line); called again for the same export, nothing more is posted. A
# ticket written while the round's read shows that pull request open names it, asks for it to be merged first, and quotes the folder.
# A stamp or folder outside upstream/vid is refused and nothing is posted. GitHub auto with layout: separate (TW's toy): spec-publish
# is refused, nothing posted, and a ticket quotes the spec repository as today. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/man; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-one: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
fm_toy "$T/toy" || fail 'the manual toy could not be made'
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\nspec-stamp: STAMP\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
C=$T/code.git; M0=$(git --git-dir="$C" rev-parse main)
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'; E=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log); [ -n "$E" ] || fail 'no export'
SG=.vid/spec.git; E=$(git --git-dir="$SG" rev-parse "$E^{commit}")
# a stamp, then a folder, that leave the folder: refused, nothing posted
for k in 'spec-stamp: ../STAMP' 'spec-path: upstream/../vid'; do cp .vid/tw/settings "$T/s0"; kk=${k%%:*}; grep -v "^$kk:" "$T/s0" > "$T/s"; echo "$k" >> "$T/s"; cat "$T/s" > .vid/tw/settings
  gh_wclear; RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; cat "$T/s0" > .vid/tw/settings
  [ "$RC" = 1 ] && [ ! -s "$FAKEGH/writes" ] || fail "$k: not refused, or something was posted (exit $RC)"; done
! grep -q '^spec-published ' .vid/tw/log || fail 'a refused publish was logged'
# the publish
gh_wclear; RC=0; sh "$GS" spec-publish --words 'Yes, publish the spec' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "spec-publish exited $RC"
L=$(grep '^spec-published ' .vid/tw/log | tail -n 1); P=$(printf '%s\n' "$L" | sed -n 's/^spec-published pr=\([0-9]*\) .*/\1/p')
printf '%s\n' "$L" | grep -qE "^spec-published pr=$P export=$(printf %.12s "$E") path=upstream/vid stamp=STAMP at=[^ ]+ words=\"Yes, publish the spec\"\$" || fail "the log line is not J4's, the owner's words last: $L"
B=$(cat "$FAKEGH/prs/$P/head" 2>/dev/null); [ -n "$B" ] || fail 'no pull request made'; [ "$(cat "$FAKEGH/prs/$P/base")" = main ] || fail 'the pull request is not on main'
BC=$(git --git-dir="$C" rev-parse "refs/heads/$B") || fail "no branch $B on the code repository"
[ "$(git --git-dir="$C" rev-parse main)" = "$M0" ] || fail 'main moved: ViD merged or pushed to main'
[ "$(git --git-dir="$C" rev-parse "$BC^")" = "$M0" ] || fail "the branch's commit is not on main"
git --git-dir="$C" diff --name-only "$M0" "$BC" > "$T/ch"; [ -s "$T/ch" ] || fail 'the branch changes nothing'
grep -v '^upstream/vid/' "$T/ch" > "$T/out" && fail 'the branch changes files outside upstream/vid/'
[ "$(git --git-dir="$C" show "$BC:upstream/vid/STAMP")" = "$E" ] || fail 'STAMP does not name the export commit'
for f in $(git --git-dir="$SG" ls-tree -r --name-only "$E"); do [ "$(git --git-dir="$C" rev-parse "$BC:upstream/vid/$f")" = "$(git --git-dir="$SG" rev-parse "$E:$f")" ] || fail "upstream/vid/$f is not the export's $f"; done
[ "$(git --git-dir="$C" ls-tree -r --name-only "$BC" -- upstream/vid | grep -c .)" = $(( $(git --git-dir="$SG" ls-tree -r --name-only "$E" | grep -c .) + 1 )) ] || fail 'the folder holds more or less than the export and its stamp'
grep -q '^owner/code git ref refs/heads/' "$FAKEGH/writes" && ! grep -q '^owner/code push ' "$FAKEGH/writes" || fail 'the branch was not made through the git data API, or something was pushed'
I=$(grep -l "#$P" "$FAKEGH"/issues/*/body 2>/dev/null | head -n 1); [ -n "$I" ] || fail 'no publish ticket names the pull request'
# the same export again: nothing more
gh_wclear; sh "$GS" spec-publish > "$T/out" 2>&1 || fail 'a second call for the same export failed'; [ ! -s "$FAKEGH/writes" ] || fail 'a second call for the same export posted again'
# a ticket written while the pull request is open names it and quotes the folder
sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the read failed'; grep -q "^open	$P	" .vid/round/read || fail 'the read does not show the pull request open'
sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1 && sh "$CHECKS/plan.sh" start S01 > "$T/out" 2>&1 || fail 'S01 could not be admitted'
F=$(sh "$CHECKS/writer.sh" write skeleton 2> "$T/out") || fail 'the skeleton ticket could not be written'
grep -q "pull request #$P" "$F" && grep -q 'merge' "$F" || fail 'the ticket does not name the open folder pull request, or ask for it to be merged first'
grep -q '^The spec, in the folder https://github.com/owner/code/tree/main/upstream/vid of the code repository' "$F" || fail 'the ticket does not quote the folder'
sh "$CHECKS/writer.sh" check "$F" > "$T/out" 2>&1 || fail 'the ticket naming the folder fails the check'

# GitHub auto, layout: separate
T=$T0/auto; mkdir -p "$T"; tw_toy "$T/toy"; tw_skel || fail 'the skeleton round failed'
gh_wclear; RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && [ ! -s "$FAKEGH/writes" ] || fail "layout: separate: spec-publish was not refused, or posted (exit $RC)"
tw_start S02 || fail 'S02 was not admitted'; F=$(sh "$CHECKS/writer.sh" write step S02 2> "$T/out") || fail "S02's ticket could not be written"
grep -q '^The spec repository, https://github.com/owner/code-spec, at the export ' "$F" || fail 'layout: separate: the ticket does not quote the spec repository'
exit 0
