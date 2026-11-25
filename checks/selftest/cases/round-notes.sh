#!/bin/sh
# Purpose: selftest case — the dev side's plain notes are read (FB-7 B7), checks/round.sh in GitHub auto on the ticket writer's toy and the fake
# gh. A comment begun with a role's two letters and a colon, on an issue or a pull request, ends a wait (`new`) and is printed at the next step,
# `note #<n> <k> <first line>`, once, k the comment's number; a step that prints one is not idle. A step whose save fails prints none, and the next does; one
# made while a step runs is printed, once; a merged pull request's is too. Not printed: ViD's own (`RM:`), a question in
# either form, `DM: left:`, and the dev side's `vid:` words. GitHub manual prints none. vid-run's row names vid-answer, whose row says what to do.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "${T:?}"' EXIT
HOME=$T/home; mkdir -p "$HOME"; export HOME
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-notes: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1: $RC"; }
wt() { VID_WAIT_TICK=1 VID_WAIT_MAX=2 rd wait; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd next; grep -q '^published 1$' "$T/out" || fail 'next'; rd step; wt; grep -qx timeout "$T/out" || fail 'a wait with nothing new did not time out'
say() { printf '%s\nby: x\n\nthe rest\n' "$2" > "$T/c"; gh "$3" comment "$1" -R $R --body-file "$T/c" > /dev/null; }
G=$T/g; git clone -q "$T/code.git" "$G" 2>/dev/null; git -C "$G" checkout -q -b ticket-1; git -C "$G" -c user.name=a -c user.email=a@b commit -q --allow-empty -m t; git -C "$G" push -q origin ticket-1 2>/dev/null
P=$(gh pr create -R $R --head ticket-1 --base main --title t --body "$(printf 'ticket: #1\n\nDecisions: none')" | sed 's/.*\///'); rd step
# a note on the issue wakes the wait, and is printed once
say 1 'vid: claimed' issue; say 1 'DM: this run cannot hold the change; a later build can' issue; wt; grep -qx new "$T/out" || fail 'a note did not end the wait'
rd step; grep -qx 'note #1 2 DM: this run cannot hold the change; a later build can' "$T/out" || fail 'the note is not printed'; ! grep -qx idle "$T/out" || fail 'a step that prints a note says idle'
rd step; ! grep -q '^note ' "$T/out" || fail 'the note is printed twice'; wt; grep -qx timeout "$T/out" || fail 'a note seen ends a wait again'
# another role's, on the pull request; a second on the issue, by its own number
say "$P" 'TM: four cases cannot run on the test site' pr; say 1 'TM: the same' issue; rd step
grep -qx "note #$P 1 TM: four cases cannot run on the test site" "$T/out" && grep -qx 'note #1 3 TM: the same' "$T/out" && [ "$(grep -c '^note ' "$T/out")" = 2 ] || fail 'the notes on the pull request and the issue'
# none of these
for w in 'RM: the answer' 'Question: which words?' 'TA: Question: which words?' 'TA: question on ROW-001' 'DM: left: no account' 'vid: reported p1c1-1' 'vid: again p1c1' 'a plain word' 'DMX: no role'; do say 1 "$w" issue; done
rd step; ! grep -q '^note ' "$T/out" || fail "one of these is printed as a note: $(grep '^note ' "$T/out")"
# a step whose save fails prints none and keeps none as seen; the next prints it, once. One made while a step runs, read by another read, is not lost
mkdir -p "$T/shim"; RG=$(command -v git)
printf '#!/bin/sh\ncase "$*" in *push*vid-state/records*) if [ -f "%s/fs" ]; then echo "fatal: unable to access" >&2; exit 128; fi; while [ -f "%s/hold" ]; do : > "%s/held"; sleep 1; done ;; esac\nexec "%s" "$@"\n' "$T" "$T" "$T" "$RG" > "$T/shim/git"; chmod +x "$T/shim/git"
sh_() { PATH="$T/shim:$PATH" sh "$CHECKS/round.sh" step >> "$T/both" 2>&1; }
: > "$T/both"; : > "$T/fs"; say 1 'DM: the save fails' issue; ! sh_ || fail 'the save did not fail: nothing is proved'; rm -f "$T/fs"; sh_ || fail 'the step after a failed save'; cp "$T/both" "$T/out"; [ "$(grep -c 'DM: the save fails' "$T/both")" = 1 ] || fail "printed $(grep -c 'DM: the save fails' "$T/both" || true) times over a failed save"
: > "$T/both"; : > "$T/hold"; say 1 'TM: before the step' issue; PATH="$T/shim:$PATH" sh "$CHECKS/round.sh" step >> "$T/both" 2>&1 & HP=$!; n=0; while [ ! -f "$T/held" ] && [ "$n" -lt 90 ]; do sleep 1; n=$((n + 1)); done; [ -f "$T/held" ] || { rm -f "$T/hold"; wait "$HP" || true; fail 'the step never reached its save'; }
say 1 'DM: while it runs' issue; sh "$CHECKS/round.sh" read > /dev/null 2>&1 || true; rm -f "$T/hold"; wait "$HP" || fail 'the step that waited failed'; sh_; sh_; cp "$T/both" "$T/out"
for w in 'TM: before the step' 'DM: while it runs'; do [ "$(grep -c "$w" "$T/both")" = 1 ] || fail "printed $(grep -c "$w" "$T/both" || true) times: $w"; done
# on a pull request once it is merged
gh pr merge "$P" -R $R --merge > /dev/null 2>&1 || { echo MERGED > "$T/gh/prs/$P/state"; git -C "$G" push -q origin ticket-1:main 2>/dev/null; git -C "$G" rev-parse ticket-1 > "$T/gh/prs/$P/merge"; git -C "$G" rev-parse ticket-1 > "$T/gh/prs/$P/headoid"; }
[ "$(cat "$T/gh/prs/$P/state")" = MERGED ] || fail 'the pull request is not merged: nothing is proved'; say "$P" 'DM: merged with one row open' pr; sh "$CHECKS/round.sh" step > "$T/out" 2>&1 || true; grep -qx "note #$P 2 DM: merged with one row open" "$T/out" || fail "a merged pull request's note is not printed"
# GitHub manual prints none
say 1 'DM: another' issue; VID_CALLER=mode sh "$CHECKS/round.sh" step > "$T/out" 2>&1 || true; ! grep -q '^note ' "$T/out" || fail 'GitHub manual printed a note'
if [ -d "$CHECKS/../skills/vid-run" ]; then grep -q "^| \`note #<n> <k> <first line>\` (FB-7 B7) | The vid-answer skill's line for it, in /vid run |\$" "$CHECKS/../skills/vid-run/SKILL.md" || fail "vid-run's table has no note row"
  grep -q '^| `note #<n> <k> <first line>` (FB-7 B7) | Read comment `<k>` whole, and say in one line what it says and what you did about it, or that it asks nothing of ViD; when it says an ask cannot be met or takes a claim back, act on that before anything more is asked there |$' "$CHECKS/../skills/vid-answer/SKILL.md" || fail 'vid-answer has no note row'; fi
echo 'round-notes: ok'
