#!/bin/sh
# Purpose: selftest case — a newer folder publish closes the older ones (FB-1 B1). On the form fixture's toy (fixtures/form.sh) with
# `layout: one` and `spec-path: upstream/vid`: an export published (#P1, its ticket #I1); the same export again into a changed folder
# reuses its pull request and closes or comments on nothing; a newer export's publish (#P2, #I2) comments on #P1 and #I1, naming
# #P2, closes both and logs `spec-replaced pr=<P1> by=<P2> issue=<I1> at=`; a repeat call posts nothing. A merged earlier pull
# request is left untouched, its ticket too. With the older pull request's comment posted and its close failing once, the call exits
# 5 and the next closes it with no second comment; with the older ticket's close failing once after its pull request closed, the
# call exits 5, logs no `spec-replaced` for it, and the next closes it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-replace: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
# the fake gh, a call failing once while $T/fail-<its two words> exists
mv "$T/bin/gh" "$T/bin/gh-fake"; printf '#!/bin/sh\nf="%s/fail-$1-$2"; if [ -f "$f" ]; then rm -f "$f"; echo "a 502" >&2; exit 1; fi\nexec "%s" "$@"\n' "$T" "$T/bin/gh-fake" > "$T/bin/gh"; chmod +x "$T/bin/gh"
sx() { echo "$1" >> PRD.md; g commit -qam "$1"; git rev-parse HEAD > .vid/tw/applied; sh "$GS" spec-export > "$T/out" 2>&1 || fail "the export after '$1' failed"; }
sp() { RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; }
lastp() { sed -n 's/^spec-published pr=\([0-9]*\) .*/\1/p' .vid/tw/log | tail -n 1; }
tick() { sed -n "s/^spec-ticket pr=$1 issue=\([0-9]*\) .*/\1/p" .vid/tw/log | tail -n 1; }
st() { cat "$FAKEGH/$1/$2/state"; }
nc() { ls "$FAKEGH/$1/$2/comments" 2>/dev/null | grep -c . || true; }
says() { cat "$FAKEGH/$1/$2/comments/"* 2>/dev/null | grep -q -- "$3"; }
repl() { grep -q "^spec-replaced pr=$1 " .vid/tw/log; }
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'
sp; [ "$RC" = 0 ] || fail "the first publish exited $RC"; P1=$(lastp); I1=$(tick "$P1"); [ -n "$P1" ] && [ -n "$I1" ] || fail 'the first publish made no pull request or ticket'
# the same export into a changed folder: its own pull request reused, nothing closed or commented on
grep -v '^spec-path:' .vid/tw/settings > "$T/s"; echo 'spec-path: upstream/vid2' >> "$T/s"; cat "$T/s" > .vid/tw/settings
sp; [ "$RC" = 0 ] || fail "the publish into a changed folder exited $RC"; [ "$(lastp)" = "$P1" ] || fail 'the publish into a changed folder did not reuse its pull request'
[ "$(st prs "$P1")" = OPEN ] && [ "$(st issues "$I1")" = OPEN ] || fail 'a republish of the same export closed its own pull request or ticket'
[ "$(nc prs "$P1")" = 0 ] && [ "$(nc issues "$I1")" = 0 ] && ! repl "$P1" || fail 'a republish of the same export commented on its own pull request or ticket, or logged it replaced'
# a newer export: the older pull request and its ticket told and closed, logged
sx 'A second line for the spec.'; sp; [ "$RC" = 0 ] || fail "the newer publish exited $RC"; P2=$(lastp); I2=$(tick "$P2"); [ "$P2" != "$P1" ] && [ -n "$I2" ] || fail 'the newer export made no pull request of its own'
[ "$(st prs "$P1")" = CLOSED ] || fail "the older pull request #$P1 is still open after a newer folder publish"
[ "$(st issues "$I1")" = CLOSED ] || fail "the older publish ticket #$I1 is still open after a newer folder publish"
says prs "$P1" "^vid: replaced by pull request #$P2" || fail "the older pull request #$P1 was closed with no comment naming #$P2"
says issues "$I1" "^vid: replaced by #$I2: merge pull request #$P2 instead" || fail "the older ticket #$I1 was closed with no comment naming #$I2 and #$P2"
grep -q "^spec-replaced pr=$P1 by=$P2 issue=$I1 at=" .vid/tw/log || fail 'the replacement was not logged as spec-replaced'
gh_wclear; sp; [ "$RC" = 0 ] && [ ! -s "$FAKEGH/writes" ] || { cp "$FAKEGH/writes" "$T/out" 2>/dev/null || true; fail "a repeat call exited $RC or posted again"; }
[ "$(nc prs "$P1")" = 1 ] && [ "$(nc issues "$I1")" = 1 ] || fail 'a repeat call commented again'
# a merged earlier pull request: left untouched, its ticket too
gh pr merge "$P2" -R owner/code --merge > /dev/null || fail "the fake could not merge #$P2"
sx 'A third line for the spec.'; sp; [ "$RC" = 0 ] || fail "the publish after a merged one exited $RC"; P3=$(lastp); I3=$(tick "$P3")
[ "$(st prs "$P2")" = MERGED ] && [ "$(nc prs "$P2")" = 0 ] || fail "the merged pull request #$P2 was commented on or closed"
[ "$(st issues "$I2")" = OPEN ] && [ "$(nc issues "$I2")" = 0 ] || fail "the ticket of the merged pull request #$P2 was commented on or closed"
# the older pull request's comment posted, its close failing once: the call unfinished (5), the next closes it, no second comment
sx 'A fourth line for the spec.'; touch "$T/fail-pr-close"; sp; [ "$RC" = 5 ] || fail "a failed close of the older pull request exited $RC, not 5"
tail -n 1 "$T/out" | grep -q "the older #$P3 or its ticket could not be closed" || fail "the failed close's line does not name #$P3"
P4=$(lastp); I4=$(tick "$P4"); [ "$P4" != "$P3" ] && [ -n "$I4" ] || fail 'the publish whose cleanup failed made no pull request or ticket'
[ "$(st prs "$P3")" = OPEN ] && [ "$(nc prs "$P3")" = 1 ] && ! repl "$P3" || fail "the scene is wrong: #$P3 is not open with its one comment, or was logged replaced"
sp; [ "$RC" = 0 ] || fail "the call after the failed close exited $RC"
[ "$(st prs "$P3")" = CLOSED ] || fail "the next call left #$P3 open"; [ "$(nc prs "$P3")" = 1 ] || fail "the next call posted a second comment on #$P3"
[ "$(st issues "$I3")" = CLOSED ] && [ "$(nc issues "$I3")" = 1 ] && repl "$P3" || fail "#$P3's ticket #$I3 is open or told twice, or the replacement not logged"
# the older ticket's close failing once after its pull request closed: 5, not logged; the next closes it, then logs it
sx 'A fifth line for the spec.'; touch "$T/fail-issue-close"; sp; [ "$RC" = 5 ] || fail "a failed close of the older ticket exited $RC, not 5"
[ "$(st prs "$P4")" = CLOSED ] || fail "#$P4 was not closed"; [ "$(st issues "$I4")" = OPEN ] || fail 'the scene is wrong: the ticket was closed'
! repl "$P4" || fail "spec-replaced was logged for #$P4 before its ticket #$I4 was closed"
sp; [ "$RC" = 0 ] || fail "the call after the failed ticket close exited $RC"
[ "$(st issues "$I4")" = CLOSED ] || fail "the next call left the older ticket #$I4 open"; [ "$(nc issues "$I4")" = 1 ] && [ "$(nc prs "$P4")" = 1 ] || fail 'the next call posted a second comment'
repl "$P4" || fail "the replacement of #$P4 was not logged once its ticket closed"
echo 'spec-publish-replace: ok'
