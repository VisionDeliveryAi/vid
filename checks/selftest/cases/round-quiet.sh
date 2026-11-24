#!/bin/sh
# Purpose: selftest case — ViD says plainly when no dev side answers (v0.26.10.28.3 R2), checks/round.sh on the ticket writer's toy and the fake gh. A work
# ticket open, none claimed and the newest published line older than quiet-hours: the step flags devagent-quiet with the open count, once. It clears once the
# ticket's issue holds a `vid: claimed` comment, is raised again when that comment is gone, and clears once a pull request names the ticket. A close issue
# alone, reported to and never claimed, raises nothing. vid-run's table tells the owner in one line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-quiet: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd next; [ "$RC" = 0 ] || fail "next failed: $RC"; ok '^published 1$'
# published within quiet-hours: nothing
rd step; [ "$RC" = 0 ] || fail "the step failed: $RC"; no '^flag devagent-quiet'
# the newest publication older than quiet-hours, the ticket unclaimed: raised, once
sed -i.b 's/^\(published .*\) at=.*/\1 at=2020-01-01T00:00:00Z/' .vid/tw/log; rm -f .vid/tw/log.b
rd step; ok '^flag devagent-quiet 1$'; grep -q 'word=devagent-quiet on=1' .vid/metrics-events || fail 'no flag event'; rd step; no '^flag devagent-quiet'
# a claim clears it; the claim gone, raised again; a pull request naming the ticket clears it
printf 'vid: claimed\nby: DM\n' > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; rd step; no '^flag devagent-quiet'; grep -q 'flag-cleared word=devagent-quiet on=1' .vid/metrics-events || fail 'a claim did not clear it'
rm "$T/gh/issues/1/comments/$(ls "$T/gh/issues/1/comments" | sort -n | tail -n 1)"; cp "$T/gh/issues/1/labels" "$T/lb"; : > "$T/gh/issues/1/labels"; rd step; ok '^flag devagent-quiet 1$'; cp "$T/lb" "$T/gh/issues/1/labels"   # FB-3 C3: a ticket on ViD's record counts without its label
W=$T/w; git clone -q "$T/code.git" "$W" 2>/dev/null; git -C "$W" checkout -q -b ticket-1; git -C "$W" -c user.name=a -c user.email=a@b commit -q --allow-empty -m t; git -C "$W" push -q origin ticket-1 2>/dev/null
P=$(gh pr create -R $R --head ticket-1 --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "1")" | sed 's/.*\///'); rd step; no '^flag devagent-quiet'; [ "$(grep -c 'flag-cleared word=devagent-quiet on=1' .vid/metrics-events)" = 2 ] || fail 'a pull request did not clear it'
# a close issue alone, its chunks reported, never claimed: nothing
echo CLOSED > "$T/gh/prs/$P/state"; tw_close 1; echo 'withdrawn 1 decision=self-test at=2020-01-01T00:00:00Z' >> .vid/tw/log
printf 'close: S01\ncommit: %s\nengines: alpha\n\n- chunk p1c1, alpha: ROW-003\n' "$(git -C "$T/code.git" rev-parse main)" > "$T/b"; C=$(gh issue create -R $R --title 'Close run: S01' --body-file "$T/b" --label run | sed 's/.*\///')
echo "asked $C close step=S01 commit=x at=2020-01-01T00:00:00Z" >> .vid/tw/log; printf 'vid: reported p1c1-1\nby: DM\n' > "$T/c"; gh issue comment "$C" -R $R --body-file "$T/c" > /dev/null
rd step; [ "$RC" = 0 ] || fail "the step with a close issue alone failed: $RC"; no '^flag devagent-quiet'
grep -q '^| `flag devagent-quiet <n>` (v0.26.10.28.3) | .*`No dev side has answered for <h> hours: <n> tickets open, none claimed\. Start it with /vid:vid-devagent <job note> in a new conversation in its work folder, or in the background with dm\.sh up <job note>, or check that it runs\.`' "$CHECKS/../skills/vid-run/SKILL.md" 2>/dev/null || [ ! -d "$CHECKS/../skills" ] || fail "vid-run's table has no devagent-quiet line offering the conversation first"   # 0.26.10.28.8 (R12)
grep -q '^| `flag devagent-stopped <id>: <why>` (v0.26.10.28.6) | .*`The dev side stopped: <why>\. Start it again with /vid:vid-devagent <job note> in a new conversation in its work folder, or in the background with dm\.sh up <job note>\.`' "$CHECKS/../skills/vid-run/SKILL.md" 2>/dev/null || [ ! -d "$CHECKS/../skills" ] || fail "vid-run's devagent-stopped line does not offer the conversation first"   # 0.26.10.28.8 (R12)
exit 0
