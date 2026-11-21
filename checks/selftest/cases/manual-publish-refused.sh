#!/bin/sh
# Purpose: selftest case — a publish move refused (GM-2 T4, T10; its case manual-publish-refused). On the form fixture's toy
# (fixtures/form.sh) in GitHub manual, S03's name holds a shape the writer's check refuses (a { } pair). One call names
# `publish S03 "<words>" -- publish S02 "<words>"`: S03 is refused at the ticket path (GM-4 K1: github.sh tw-hand publish, its write
# and check among its steps), the check's words under it, and posts nothing;
# the moves open and end no stage of their own (GM-4 F2, I4: each call runs inside the call's stage, opened and ended as
# vid-connect's start and end open and end it); S02, the next move named, is still done. Then, with no engines line in the handed record,
# `publish S05` refuses at the ticket path, the writer's words on the missing engines under it, and posts nothing (GM-4 K11: the
# move holds no check of its own); a call naming `engines "alpha beta" "<words>" -- publish
# S05 "<words>"` records the handed engines line with the owner as its stand-in, and S05 goes out (S05 builds on S02 alone,
# so its ticket quotes no name of S03's); the first save holding the engines line holds no S05 ticket,
# so the engines move was saved before the publish started. Each call is made as
# /vid next makes it after its read (next.sh read, then next-move.sh call), under this session's lock. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "manual-publish-refused: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
# S03's name, as the owner's plan holds it, with a shape the check refuses
pt_rs 's/name: the footer, unsubscribe and the mail provider/name: the footer {unsubscribe} and the mail provider/'
sh "$CHECKS/plan.sh" change other 'S03 named again' --trigger initial --expect 'the same steps' > "$T/out" 2>&1 || fail 'the rename was not recorded'
tw_ratify 'Yes, publish it' || fail 'the plan was not ratified again'
printf 'stage name=plan state=end session=S1 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
CLAUDE_CODE_SESSION_ID=publish-refused-case; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
# the page in the viewer's folder under a home of the case's own; a ticket the call posts made now on the fake, as GitHub makes it
HOME=$T/home; export HOME; mkdir -p "$HOME"
# each ticket the call posts given its creation time at its post, as GitHub gives it, so the call's own read-back reads it new
FAKEGH_CREATED_NOW=1; export FAKEGH_CREATED_NOW
made() { for n in $(awk '$1 == "published" { print $2 }' .vid/tw/log 2>/dev/null); do [ -f "$FAKEGH/issues/$n/created" ] || gh_attr "$n" created "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; done; }
# each call inside the call's stage, as vid-connect's start opens it and its end ends it (GM-4 F2, I4); the moves open and end none
stg() { printf 'stage name=replan state=%s session=%s%s at=%s\n' "$1" "$CLAUDE_CODE_SESSION_ID" "$2" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; }
call() { stg start ' records=29'; K=$(grep -c '^stage ' .vid/metrics-events)
  sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; made
  [ "$(grep -c '^stage ' .vid/metrics-events)" = "$K" ] || fail 'the moves opened or ended a stage of their own'
  sh "$CHECKS/plan.sh" gate > /dev/null 2>&1 || fail "the gate is off after the moves: they ended the call's stage"
  stg end ''; }
pub() { awk -v s="step=$1" '$1 == "published" { for (i = 3; i <= NF; i++) if ($i == s) print }' .vid/tw/log; }
creates() { grep -c '^owner/code issue create$' "$FAKEGH/writes" || true; }
call; [ "$RC" = 0 ] || fail "the call with no move exited $RC"
gh_wclear
call publish S03 'Yes, publish S03' -- publish S02 'Yes, publish S02'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^refused publish S03 at the ticket path: ' "$T/out" && grep -q '{unsubscribe}' "$T/out" || fail "S03's refusal does not name the ticket path and the check's words"
[ -z "$(pub S03)" ] || fail 'S03 was published though its check refused it'
grep -q '^done publish S02' "$T/out" || fail 'S02, the next move named, was not done after the refusal'
[ -n "$(pub S02)" ] || fail 'S02 was not published'
[ "$(creates)" = 1 ] || { cp "$FAKEGH/writes" "$T/out"; fail "the call made $(creates) issues, not S02's alone"; }
# no engines on record: a step publish refuses, naming the engines move
grep -v '^engines ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed
call; gh_wclear
call publish S05 'Yes, publish S05'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^refused publish S05 at the ticket path: ' "$T/out" && grep -q 'no engines' "$T/out" || fail 'a step publish with no engines on record did not refuse at the ticket path, the writer naming the engines'
[ -z "$(pub S05)" ] && ! grep -qv '^owner/vid-state ' "$FAKEGH/writes" || { cp "$FAKEGH/writes" "$T/out"; fail 'the refused S05 publish posted'; }
call engines 'alpha beta' 'These are the engines we run' -- publish S05 'Yes, publish S05'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^engines alpha beta | stand-in: owner' .vid/tw/handed || { cp .vid/tw/handed "$T/out"; fail 'the engines move did not record the handed engines line with the owner as its stand-in'; }
grep -q '^done publish S05' "$T/out" && [ -n "$(pub S05)" ] || fail 'S05 was not published once the engines were on record'
# each move saved before the next: the first save holding the engines holds no S05 ticket (GM-4 K1: the publish saves through
# tw-hand, then the call saves again, so a publish move makes more than one save)
U=$(gh repo view owner/vid-state --json url --jq .url); git init -q "$T/sr"; git -C "$T/sr" fetch -q "$U" refs/heads/vid-state/records 2>/dev/null || fail 'no records are saved'
E=''; for c in $(git -C "$T/sr" rev-list --reverse FETCH_HEAD); do git -C "$T/sr" show "$c:tw/handed" 2>/dev/null | grep -q '^engines alpha beta | stand-in: owner' && { E=$c; break; }; done
[ -n "$E" ] || fail 'the engines move was never saved'
! git -C "$T/sr" show "$E:tw/log" 2>/dev/null | grep -q '^published .* step=S05 ' || fail "the engines were first saved with S05's ticket: the engines move was not saved before the publish started"
exit 0
