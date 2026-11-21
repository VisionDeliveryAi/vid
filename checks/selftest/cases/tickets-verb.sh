#!/bin/sh
# Purpose: selftest case — K1's one path, its script part (GM-4 K1, J1): `github.sh tw-hand publish <step>`, the admission (plan.sh
# start), the write, its check and the post, with the lock, the saved records and the save around it, in each GitHub mode on the fake
# gh. GitHub auto, on TW's toy after the skeleton's round: `tw-hand publish S02` posts S02's ticket and saves it, no words needed;
# `--words` is kept on the log line when given; a step the admission refuses is held (exit 3), its lines printed, nothing posted; a
# closed ticket `tw-hand reopen <n> --words` reopens, with one comment `vid: reopened at the owner's word`, logged; an open one is
# refused; with no words (optional in GitHub auto) it reopens too, logged with none. GitHub manual, on the form fixture's toy: a
# publish with no words is refused (exit 1), nothing posted and no lock taken;
# with the owner's words it posts the skeleton's ticket, the words on its log line, saved to the state repository, the lock it took
# freed; a reopen with no words is refused, through tw-hand and through a direct tw-reopen with the lock held (no words, or
# blank ones: the issue stays closed, no comment, no log line), which reopens it on the owner's words; a closed ticket withdrawn (`tw-hand withdraw <n> --words`, E6) is logged `withdrawn <n>
# decision=closed-outside` with the words and posts nothing. K1's text, F6 and F14's part (the skills' half), where skills/ sits beside
# checks/ (the plugin, not a project's layout, which skips this part alone): vid-tickets is a verb, `/vid:vid-tickets`, its seven
# actions each one entry (admit through `plan.sh admit`, the rest through `github.sh tw-hand`), the words required in GitHub manual;
# its GitHub manual text is in SKILL.md (no manual.md, no "only inside a move"), each GitHub manual line naming its ruling, the
# ticket's form from the setup (`issue-form:`); the run skill's publishing lines (what round.sh next prints, the decisions named, a
# ticket by hand) are in vid-tickets once and gone from the run skill, which names vid-tickets where it runs round.sh next; vid-help
# lists /vid:vid-tickets. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/auto; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "tickets-verb: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
saved() { git --git-dir="$1" show refs/heads/vid-state/records:tw/log 2>/dev/null; }
pub() { sed -n 's/^ViD github: published ticket #\([0-9]*\).*/\1/p' "$T/out"; }
# K1's text, F6, F14's part: the skills, where they sit beside checks/
S=$CHECKS/../skills
if [ -d "$S/vid-tickets" ] && [ -d "$S/vid-run" ]; then
  K=$S/vid-tickets/SKILL.md; R=$S/vid-run/SKILL.md; H=$S/vid-help/SKILL.md
  awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$K" > "$T0/fm"
  ! grep -q '^user-invocable: false' "$T0/fm" && ! grep -qiE '^description: *"?Internal|not a verb' "$T0/fm" || fail 'vid-tickets is not a verb: its description says internal, or not a verb'
  grep -qF '/vid:vid-tickets' "$K" || fail 'vid-tickets does not name its command /vid:vid-tickets'
  while IFS='|' read -r a e; do grep -F "\`$a\`" "$K" | grep -qF "$e" || fail "vid-tickets has no line giving the action $a as $e"; done <<'EOF'
admit <step>|plan.sh admit <step>
publish <step> "<words>"|github.sh tw-hand publish <step>
amend #<n> "<words>"|github.sh tw-hand amend <n>
withdraw #<n> "<words>"|github.sh tw-hand withdraw <n>
reopen #<n> "<words>"|github.sh tw-hand reopen <n>
fix <key> "<words>"|github.sh tw-hand fix <key>
reached "<words>"|github.sh tw-hand reached
EOF
  tr '\n' ' ' < "$K" | tr -s ' ' | grep -qF 'required in GitHub manual' || fail "vid-tickets does not say the owner's words are required in GitHub manual"
  [ ! -e "$S/vid-tickets/manual.md" ] || fail 'vid-tickets still keeps a second layout, manual.md (GM-4 F6)'
  ! grep -qF 'manual.md' "$K" && ! grep -qF 'only inside a move' "$K" || fail 'vid-tickets still sends GitHub manual to manual.md, or runs only inside a move'
  grep -qF 'issue-form:' "$K" || fail "vid-tickets does not take the ticket's form from the setup (issue-form:)"
  awk 'NR == 1 && /^---$/ { f = 1; next } f && /^---$/ { f = 0; next } !f' "$K" | grep 'GitHub manual' | grep -vE 'GM M[0-9]+|GM-[234] [A-Z][0-9]+' > "$T0/gm" || :
  [ ! -s "$T0/gm" ] || fail "a GitHub manual line of vid-tickets names no ruling: $(head -n 1 "$T0/gm")"
  for p in 'Nothing by hand for what it prints beside' '`stop stray: #<n> …`' 'Name one when a decision a ticket needs misses its labels' 'A ticket the owner asks for by hand'; do
    ! grep -qF -- "$p" "$R" || fail "the run skill still holds: $p"; [ "$(grep -cF -- "$p" "$K")" = 1 ] || fail "vid-tickets does not hold once: $p"; done
  grep '^4\. `sh checks/round.sh next`' "$R" | grep -q 'vid-tickets' || fail 'the run skill does not name vid-tickets where it runs round.sh next'
  grep -q '^| \*\*/vid:vid-tickets\*\* |' "$H" || fail 'vid-help does not list /vid:vid-tickets'
fi
# GitHub auto: TW's toy, the skeleton's round done (#1 posted and closed)
tw_toy "$T/toy"; tw_skel || fail 'the skeleton round failed'
SR=$T/gh/repos/owner%code-spec/remote.git
RC=0; CLAUDE_CODE_SESSION_ID=owner-a sh "$GS" tw-hand publish S02 > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub auto: tw-hand publish S02 exited $RC"
N2=$(pub); [ -n "$N2" ] && grep -q "^published $N2 kind=step step=S02 " .vid/tw/log || fail 'GitHub auto: tw-hand publish S02 posted no S02 ticket'
grep -q "^step-start .*step=S02 " .vid/metrics-events || fail 'GitHub auto: the publish did not admit S02 (no step-start event)'
saved "$SR" | grep -q "^published $N2 kind=step step=S02 " || fail 'GitHub auto: the published ticket is not in the saved records'
! grep -q "^published $N2 .* words=" .vid/tw/log || fail 'GitHub auto: a publish with no words logged words'
RC=0; CLAUDE_CODE_SESSION_ID=owner-a sh "$GS" tw-hand publish S03 --words 'Yes, S03 too' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub auto: tw-hand publish S03 --words exited $RC"
N3=$(pub); [ -n "$N3" ] && grep -q "^published $N3 kind=step step=S03 .* words=\"Yes, S03 too\"\$" .vid/tw/log || fail "GitHub auto: the owner's words are not on S03's log line: $(grep "^published ${N3:-x} " .vid/tw/log)"
# a step the admission refuses (S05, of stage 2): held, its lines printed, nothing posted
I=$(ls "$T/gh/issues" | grep -c .); RC=0; CLAUDE_CODE_SESSION_ID=owner-a sh "$GS" tw-hand publish S05 > "$T/out" 2>&1 || RC=$?
[ "$RC" = 3 ] || fail "GitHub auto: a publish the admission refuses exited $RC, not 3 (held)"
grep -q 'not admitted' "$T/out" && [ "$(ls "$T/gh/issues" | grep -c .)" = "$I" ] && ! grep -q '^published [0-9]* kind=step step=S05 ' .vid/tw/log || fail 'GitHub auto: a held publish posted, or did not say it was held'
# reopen: a closed ticket reopened with its one comment; an open one refused
tw_close "$N2"; RC=0; CLAUDE_CODE_SESSION_ID=owner-a sh "$GS" tw-hand reopen "$N2" --words 'Open it again' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub auto: tw-hand reopen exited $RC"
[ "$(cat "$T/gh/issues/$N2/state")" = OPEN ] || fail "GitHub auto: #$N2 is not open after the reopen"
K=$(ls "$T/gh/issues/$N2/comments" | sort -n | tail -n 1); [ "$(head -n 1 "$T/gh/issues/$N2/comments/$K")" = "vid: reopened at the owner's word" ] || fail "GitHub auto: the reopen's comment is not ViD's one line"
grep -q "^reopened $N2 at=[^ ]* words=\"Open it again\"\$" .vid/tw/log || fail 'GitHub auto: the reopen is not logged with the words'
saved "$SR" | grep -q "^reopened $N2 " || fail 'GitHub auto: the reopen is not in the saved records'
RC=0; CLAUDE_CODE_SESSION_ID=owner-a sh "$GS" tw-hand reopen "$N2" --words 'Again' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail 'GitHub auto: an open ticket was reopened'
# GM-4 K1: the words are optional in GitHub auto: a closed ticket reopened with none goes through, logged with no words
tw_close "$N2"; RC=0; CLAUDE_CODE_SESSION_ID=owner-a sh "$GS" tw-hand reopen "$N2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub auto: a reopen with no words was refused (exit $RC): $(tail -n 1 "$T/out")"
[ "$(cat "$T/gh/issues/$N2/state")" = OPEN ] || fail "GitHub auto: #$N2 is not open after a reopen with no words"
[ "$(grep -c "^reopened $N2 " .vid/tw/log)" = 2 ] && grep "^reopened $N2 " .vid/tw/log | tail -n 1 | grep -q "^reopened $N2 at=[^ ]*\$" || fail "GitHub auto: the reopen with no words is not logged without words: $(grep "^reopened $N2 " .vid/tw/log | tail -n 1)"
sed -n '/^ghc() {/,/^}/p' "$GS" | grep -q "'issue reopen'" || fail 'gh issue reopen is not on the allow-list'

# GitHub manual: the form fixture's toy, in a folder of its own (its own fake gh and code repository)
T=$T0/man; mkdir -p "$T"; fm_toy "$T/toy" || fail 'the manual toy could not be made'
RC=0; CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" tw-hand publish S01 > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q "owner's words" "$T/out" || fail "GitHub manual: a publish with no words was not refused (exit $RC)"
! grep -qE 'issue create|comment ' "$FAKEGH/writes" 2>/dev/null && [ ! -s "$FAKEGH/locks" ] && ! grep -q '^published ' .vid/tw/log 2>/dev/null || fail 'GitHub manual: a publish refused for its words posted, or took the lock'
RC=0; CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" tw-hand publish S01 --words 'Yes, publish the skeleton' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub manual: tw-hand publish S01 with words exited $RC"
M1=$(pub); [ -n "$M1" ] && grep -q "^published $M1 kind=skeleton step=S01 .* words=\"Yes, publish the skeleton\"\$" .vid/tw/log || fail 'GitHub manual: the skeleton is not published with the words on its log line'
MS=$FAKEGH/repos/owner%vid-state/remote.git; saved "$MS" | grep -q "^published $M1 kind=skeleton " || fail 'GitHub manual: the ticket is not in the saved records of the state repository'
grep -q 'owner/vid-state freed' "$FAKEGH/locks" || fail 'GitHub manual: the lock the call took was not freed'
tw_close "$M1"; RC=0; CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" tw-hand reopen "$M1" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && [ "$(cat "$FAKEGH/issues/$M1/state")" = CLOSED ] || fail "GitHub manual: a reopen with no words went ahead (exit $RC)"
# GM-4 K1 (GM M16): tw-reopen's own guard, called directly with the lock held: no words, or blank ones, refused, nothing posted or
# logged; the owner's words reopen it
CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" lock-take > "$T/out" 2>&1 || fail 'GitHub manual: the lock could not be taken'
nc() { ls "$FAKEGH/issues/$M1/comments" 2>/dev/null | grep -c . || true; }
for w in no blank; do C0=$(nc); RC=0
  if [ "$w" = no ]; then CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" tw-reopen "$M1" > "$T/out" 2>&1 || RC=$?; else CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" tw-reopen --words '  ' "$M1" > "$T/out" 2>&1 || RC=$?; fi
  [ "$RC" = 1 ] && [ "$(cat "$FAKEGH/issues/$M1/state")" = CLOSED ] || fail "GitHub manual: a direct tw-reopen with $w words went ahead (exit $RC)"
  [ "$(nc)" = "$C0" ] && ! grep -q "^reopened $M1 " .vid/tw/log || fail "GitHub manual: a direct tw-reopen with $w words commented or logged"; done
RC=0; CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" tw-reopen --words 'Open the skeleton again' "$M1" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && [ "$(cat "$FAKEGH/issues/$M1/state")" = OPEN ] && grep -q "^reopened $M1 at=[^ ]* words=\"Open the skeleton again\"\$" .vid/tw/log || fail "GitHub manual: a direct tw-reopen with the owner's words did not reopen (exit $RC)"
CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" lock-free > "$T/out" 2>&1 || fail 'GitHub manual: the lock could not be freed'; tw_close "$M1"
gh_wclear; RC=0; CLAUDE_CODE_SESSION_ID=owner-m sh "$GS" tw-hand withdraw "$M1" --words 'Let it go' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "GitHub manual: the withdrawal of a closed ticket exited $RC"
grep -q "^withdrawn $M1 decision=closed-outside at=[^ ]* words=\"Let it go\"\$" .vid/tw/log || fail 'GitHub manual: the closed ticket is not withdrawn closed-outside with the words'
! grep -E "owner/code (comment|issue)" "$FAKEGH/writes" > /dev/null 2>&1 || fail 'GitHub manual: the withdrawal of a closed ticket posted on it'
exit 0
