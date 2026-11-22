#!/bin/sh
# Purpose: selftest case — a folder publish that fails part way is finished by the next call (GM-4 K13: "a one-repository project
# cannot publish" never holds). On the form fixture's toy (fixtures/form.sh) with `layout: one` and `spec-path: upstream/vid`, after
# the export: the pull request fails once after the branch vid-spec/<12 hex> is made (exit 5, FB-2 B1: a failed call, unfinished,
# .vid/tw/spec-owed holding the export; nothing logged); the call again moves that branch, ViD's own, to its new commit, makes the
# one pull request, the publish ticket and the `spec-published` line. Then, for a new export, the publish ticket fails once after
# the pull request is made: the `spec-published` line is logged all the same (exit 5, the marker holding the new export); the call
# again makes the publish ticket alone (no git data call, no second pull request), logging `spec-ticket pr=<n> issue=<i> at=`; a
# third call posts nothing. A pull request open on the branch is reused, never made twice. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-retry: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
C=$T/code.git
# the fake gh, a call failing once while $T/fail-<its two words> exists
mv "$T/bin/gh" "$T/bin/gh-fake"; printf '#!/bin/sh\nf="%s/fail-$1-$2"; if [ -f "$f" ]; then rm -f "$f"; echo "a 502" >&2; exit 1; fi\nexec "%s" "$@"\n' "$T" "$T/bin/gh-fake" > "$T/bin/gh"; chmod +x "$T/bin/gh"
sp() { RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; }
prs() { ls "$FAKEGH/prs" 2>/dev/null | grep -c . || true; }
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'; E=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log); E12=$(printf %.12s "$E")
# the pull request fails after the branch: nothing logged; the call again finishes it
touch "$T/fail-pr-create"; sp; [ "$RC" = 5 ] || fail "a failed pull request exited $RC, not 5"
[ "$(cat .vid/tw/spec-owed 2>/dev/null)" = "$E12" ] || fail '.vid/tw/spec-owed does not hold the export after the failed pull request'
git --git-dir="$C" rev-parse -q --verify "refs/heads/vid-spec/$E12" > /dev/null || fail 'the branch was not made before the pull request failed: the scene is wrong'
! grep -q '^spec-published ' .vid/tw/log || fail 'a publish with no pull request was logged'
sp; [ "$RC" = 0 ] || fail "the call again, after the failed pull request, exited $RC"
[ "$(prs)" = 1 ] || fail "the call again made $(prs) pull requests, not one"
P=$(sed -n "s/^spec-published pr=\([0-9]*\) export=$E12 .*/\1/p" .vid/tw/log | tail -n 1); [ -n "$P" ] || fail 'the call again logged no spec-published line'
[ "$(cat "$FAKEGH/prs/$P/head")" = "vid-spec/$E12" ] || fail 'the pull request is not the branch'"'"'s'
git --git-dir="$C" cat-file -e "vid-spec/$E12:upstream/vid/PRD.md" || fail 'the branch does not hold the folder'
grep -l "#$P" "$FAKEGH"/issues/*/body > /dev/null 2>&1 || fail 'no publish ticket names the pull request'
# a new export; the publish ticket fails after the pull request: logged, then the ticket alone
echo 'A new line for the spec.' >> PRD.md; g commit -qam 'the spec changed'; git rev-parse HEAD > .vid/tw/applied
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the second export failed'; E2=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log); F12=$(printf %.12s "$E2")
touch "$T/fail-issue-create"; sp; [ "$RC" = 5 ] || fail "a failed publish ticket exited $RC, not 5"
[ "$(cat .vid/tw/spec-owed 2>/dev/null)" = "$F12" ] || fail '.vid/tw/spec-owed does not hold the new export after the failed publish ticket'
P2=$(sed -n "s/^spec-published pr=\([0-9]*\) export=$F12 .*/\1/p" .vid/tw/log | tail -n 1); [ -n "$P2" ] || fail 'the pull request made, its publish not logged before the ticket'
gh_wclear; sp; [ "$RC" = 0 ] || fail "the call again, after the failed ticket, exited $RC"
! grep -q '^owner/code \(git \|pr create\)' "$FAKEGH/writes" || { cp "$FAKEGH/writes" "$T/out"; fail 'the call again made the branch or the pull request again'; }
grep -q "^spec-ticket pr=$P2 issue=[0-9]* at=" .vid/tw/log || fail 'the publish ticket made alone is not logged'
I2=$(sed -n "s/^spec-ticket pr=$P2 issue=\([0-9]*\) .*/\1/p" .vid/tw/log); grep -q "#$P2" "$FAKEGH/issues/$I2/body" || fail 'the publish ticket does not name its pull request'
gh_wclear; sp; [ "$RC" = 0 ] && [ ! -s "$FAKEGH/writes" ] || fail "a third call exited $RC or posted"
# a pull request open on the branch is reused: its export's line gone from the log, the call again makes none
grep -v "^spec-published pr=$P2 \|^spec-ticket pr=$P2 " .vid/tw/log > "$T/lg"; cat "$T/lg" > .vid/tw/log
N0=$(prs); sp; [ "$RC" = 0 ] || fail "the call with its pull request open exited $RC"; [ "$(prs)" = "$N0" ] || fail 'a second pull request was made for an open one'
grep -q "^spec-published pr=$P2 export=$F12 " .vid/tw/log || fail 'the open pull request was not logged as the publish'
exit 0
