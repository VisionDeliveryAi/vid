#!/bin/sh
# Purpose: selftest case — an answer under the owner's delegation recorded as such (v0.26.10.28.8),
# checks/queue.sh on TW's toy. `answer Q<n> --by delegate` (the setup hold's continue) records who=delegate, an event by=delegate and
# the hold's own line by the delegate, and the status lists it among
# the delegated answers, marked as given under the owner's delegation; the owner's own answer (no --by) records owner and is not
# listed; an answerer that is none of owner, RM and delegate is refused; the production yes is refused to the delegate, nothing
# recorded; the delegation path passes --by delegate (vid-answer's, since GM-4 K6). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "queue-delegate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; QS=$CHECKS/queue.sh; TAB=$(printf '\t'); mkdir -p .vid/round .vid/decide
qa() { RC=0; sh "$QS" answer "$@" > "$T/out" 2>&1 || RC=$?; }
# the owner's production item, stage 1 closed and its yes asked (planted as stage-production.sh plants it)
X=$(git --git-dir="$T/code.git" rev-parse main); C12=$(printf %.12s "$X"); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs"
printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"; : > "$F/named"; : > "$F/passed"
tw_hand "stage-closed 1 | stand-in: RM at $C12 candidate 1"; printf 'production:1:1:7\tRehearsal of %s: migrates no. Deploy to production? yes or no\n' "$C12" > "$F/yes"
tw_hand 'candidate 1'; sh "$QS" sync > /dev/null 2>&1; sh "$QS" keys > "$T/keys" 2>&1 || true   # the setup hold's Q line, staging not passed yet
QC=$(awk -F'\t' '$1 == "hold:1" { print $2 }' "$T/keys"); QP=$(awk -F'\t' '$1 ~ /^production:1:1:/ { print $2 }' "$T/keys")
[ -n "$QC" ] && [ -n "$QP" ] || fail "no Q lines for the setup hold and the production yes: $(cat "$T/keys")"
# an unknown answerer: refused, nothing recorded
qa "$QC" --by someone continue 'not mine to say'; [ "$RC" != 0 ] || fail 'an answer --by someone was taken'; [ ! -s .vid/decide/queue/answers ] || fail 'a refused answer was recorded'
# the production yes: the owner's alone, refused to the delegate
qa "$QP" --by delegate yes 'go live, as you said I may'; [ "$RC" != 0 ] || fail 'the delegate gave the production yes'
! grep -q 'production:1:1:' .vid/decide/queue/answers 2>/dev/null || fail 'the refused production yes was recorded'
# a delegated answer: who=delegate, its event, listed apart in the status
qa "$QC" --by delegate continue 'the owner said: build on without me'; [ "$RC" = 0 ] || fail "the delegated answer was refused ($RC)"
awk -F'\t' '$2 == "hold:1" && $5 == "delegate" { f = 1 } END { exit !f }' .vid/decide/queue/answers || fail "the delegated answer's who: $(cut -f2,5 .vid/decide/queue/answers)"
grep -q '^queue-answered what=hold by=delegate' .vid/metrics-events || fail 'no queue-answered event by=delegate'
grep -q '^setup-hold off | stand-in: delegate the owner said: build on without me$' .vid/tw/handed && grep -q '^setup-hold state=off by=delegate' .vid/metrics-events || fail "the hold's line is not the delegate's: $(grep '^setup-hold' .vid/tw/handed)"
VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1 || true
grep -qx 'delegated answers since the last update:' "$T/out" && grep -qx '  hold:1 — the owner said: build on without me · answered for you, under your delegation' "$T/out" || fail 'the status does not list the delegated answer apart'
! grep -q '^  control:hold — ' "$T/out" || fail 'one delegated continue is listed twice'   # hold_off's own record is not listed again
# the hold again, the run paused; a delegated continue with no words ends the pause, recorded as the delegate's, listed as such
{ grep -v '^setup-hold off' .vid/tw/handed || true; } > "$T/h"; cat "$T/h" > .vid/tw/handed; sed 's/^run:.*/run: stopped owner asked to pause/' .vid/RUN-STATE.md > "$T/rs"; cat "$T/rs" > .vid/RUN-STATE.md
qa "$QC" --by delegate continue; [ "$RC" = 0 ] || fail "the delegated continue ending a pause was refused ($RC)"
awk -F'\t' '$2 == "control:continue" && $5 == "delegate" { f = 1 } END { exit !f }' .vid/decide/queue/answers && grep -q '^run state=active by=delegate' .vid/metrics-events || fail "the pause's end is not the delegate's: $(grep 'control:continue' .vid/decide/queue/answers | cut -f2,5)"
VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1 || true; grep -qx '  control:continue — (no words) · answered for you, under your delegation' "$T/out" || fail "a delegated answer with no words: $(grep '^  control' "$T/out")"
# the owner's own answer: who=owner, not listed as delegated
tw_hand "stage-closed 2 | stand-in: RM at $C12 candidate 1"; G=.vid/decide/stage/2/1; mkdir -p "$G"; cp "$F/ask" "$F/commit" "$F/named" "$F/passed" "$G/"
printf 'production:2:1:8\tRehearsal of %s: migrates no. Deploy to production? yes or no\n' "$C12" > "$G/yes"; sh "$QS" sync > /dev/null 2>&1; sh "$QS" keys > "$T/keys" 2>&1 || true
QN=$(awk -F'\t' '$1 ~ /^production:2:1:/ { print $2 }' "$T/keys"); [ -n "$QN" ] || fail "no Q line for stage 2's production yes: $(cat "$T/keys")"
qa "$QN" no 'not yet, I say'; [ "$RC" = 0 ] || fail "the owner's own no was refused ($RC)"
awk -F'\t' '$2 ~ /^production:2:1:/ && $5 == "owner" { f = 1 } END { exit !f }' .vid/decide/queue/answers || fail "the owner's answer is not recorded as the owner's"
VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1 || true; ! grep -q 'not yet, I say' "$T/out" || fail "the owner's own answer is listed as delegated"
# the owner's own control command, with a BY in the environment, is still the owner's
sh "$QS" control pause 'a break' > /dev/null 2>&1; BY=delegate sh "$QS" control continue 'back, the owner' > /dev/null 2>&1 || fail 'the control continue was refused'
awk -F'\t' '$4 == "back, the owner" { w = $5 } END { exit w != "owner" }' .vid/decide/queue/answers || fail "an exported BY was recorded as who said continue: $(grep 'back, the owner' .vid/decide/queue/answers | cut -f5)"
# vid-answer (GM-4 K6 moves the run skill's delegation there): the delegation path passes --by delegate
S=$CHECKS/../skills/vid-answer/SKILL.md
[ ! -d "$CHECKS/../skills/vid-run" ] || grep -q 'in their place.*queue.sh answer Q<n> --by delegate' "$S" || fail 'vid-answer gives no --by delegate for an answer under delegation'
echo 'queue-delegate: ok'
