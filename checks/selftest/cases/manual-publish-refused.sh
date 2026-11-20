#!/bin/sh
# Purpose: selftest case — a publish move refused (GM-2 T4, T10; its case manual-publish-refused). On the form fixture's toy
# (fixtures/form.sh) in GitHub manual, S03's name holds a shape the writer's check refuses (a { } pair). One call names
# `publish S03 "<words>" -- publish S02 "<words>"`: S03 is refused at the write and its check, naming it, and posts nothing;
# its own replan stage is ended; S02, the next move named, is still done. Then, with no engines line in the handed record,
# `publish S05` refuses, naming the engines move, and posts nothing; a call naming `engines "alpha beta" "<words>" -- publish
# S05 "<words>"` records the handed engines line with the owner as its stand-in, and S05 goes out (S05 builds on S02 alone,
# so its ticket quotes no name of S03's); the save before the newest holds the engines line and no S05 ticket,
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
made() { for n in $(awk '$1 == "published" { print $2 }' .vid/tw/log 2>/dev/null); do [ -f "$FAKEGH/issues/$n/created" ] || gh_attr "$n" created "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; done; }
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; made; }
pub() { awk -v s="step=$1" '$1 == "published" { for (i = 3; i <= NF; i++) if ($i == s) print }' .vid/tw/log; }
creates() { grep -c '^owner/code issue create$' "$FAKEGH/writes" || true; }
call; [ "$RC" = 0 ] || fail "the call with no move exited $RC"
gh_wclear
call publish S03 'Yes, publish S03' -- publish S02 'Yes, publish S02'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^refused publish S03 at the write and its check: .*{unsubscribe}' "$T/out" || fail "S03's refusal does not name the write's check and its words"
[ -z "$(pub S03)" ] || fail 'S03 was published though its check refused it'
grep -q '^done publish S02' "$T/out" || fail 'S02, the next move named, was not done after the refusal'
[ -n "$(pub S02)" ] || fail 'S02 was not published'
[ "$(creates)" = 1 ] || { cp "$FAKEGH/writes" "$T/out"; fail "the call made $(creates) issues, not S02's alone"; }
S=$(grep -c '^stage name=replan state=start session=publish-refused-case ' .vid/metrics-events || true)
E=$(grep -c '^stage name=replan state=end session=publish-refused-case' .vid/metrics-events || true)
[ "$S" = 2 ] && [ "$E" = 2 ] || fail "the two moves opened $S replan stages and ended $E, the refused one's among them, not 2 and 2"
# no engines on record: a step publish refuses, naming the engines move
grep -v '^engines ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed
call; gh_wclear
call publish S05 'Yes, publish S05'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^refused publish S05 at the engines: .*engines "<primary> <other>' "$T/out" || fail 'a step publish with no engines on record did not refuse naming the engines move'
[ -z "$(pub S05)" ] && ! grep -qv '^owner/vid-state ' "$FAKEGH/writes" || { cp "$FAKEGH/writes" "$T/out"; fail 'the refused S05 publish posted'; }
call engines 'alpha beta' 'These are the engines we run' -- publish S05 'Yes, publish S05'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^engines alpha beta | stand-in: owner' .vid/tw/handed || { cp .vid/tw/handed "$T/out"; fail 'the engines move did not record the handed engines line with the owner as its stand-in'; }
grep -q '^done publish S05' "$T/out" && [ -n "$(pub S05)" ] || fail 'S05 was not published once the engines were on record'
# each move saved before the next: the save before the newest holds the engines and no S05 ticket
U=$(gh repo view owner/vid-state --json url --jq .url); git init -q "$T/sr"; git -C "$T/sr" fetch -q "$U" refs/heads/vid-state/records 2>/dev/null || fail 'no records are saved'
git -C "$T/sr" show FETCH_HEAD~1:tw/handed 2>/dev/null | grep -q '^engines alpha beta | stand-in: owner' || fail 'the engines move was not saved before the publish started'
! git -C "$T/sr" show FETCH_HEAD~1:tw/log 2>/dev/null | grep -q '^published .* step=S05 ' || fail "the save before the publish's own already holds S05's ticket"
exit 0
