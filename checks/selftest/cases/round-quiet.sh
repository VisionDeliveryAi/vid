#!/bin/sh
# Purpose: selftest case — ViD says plainly when no dev side answers (v0.26.10.28.3 R2; FB-7 B1), checks/round.sh on the ticket writer's toy and
# the fake gh. A work ticket open and no sign of the dev side for quiet-hours: the step flags devagent-quiet with the items it owes, once. A
# `vid: claimed` comment clears it and, a sign alone, not for good; it is raised again once that is old, with or without the ticket's label, and
# clears at a pull request of the ticket. ViD's own spec pull request, merged by the owner, is no sign. An issue of no ask of ViD's, reported to and never claimed, raises nothing. vid-run's table tells the
# owner in one line. Env: CHECKS.
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
# the last sign older than quiet-hours, the ticket unclaimed: raised, once
OLD=2020-01-01T00:00:00Z; back() { [ -f .vid/round/dev ] || fail 'no record of the dev side'"'"'s last sign, .vid/round/dev'; awk -F'\t' -v OFS='\t' -v u="$OLD" 'NR == 1 { $1 = u } { print }' .vid/round/dev > "$T/dv"; cat "$T/dv" > .vid/round/dev; }
back; rd step; ok "^flag devagent-quiet #1: no sign since $OLD\$"; grep -q 'word=devagent-quiet on=#1' .vid/metrics-events || fail 'no flag event'; rd step; no '^flag devagent-quiet'
# ViD's own spec pull request, opened and merged by the owner (no ticket of its own): no sign of the dev side, so it stays (the toy run)
git clone -q "$T/code.git" "$T/sw" 2>/dev/null; git -C "$T/sw" checkout -q -b vid-spec/x; git -C "$T/sw" -c user.name=a -c user.email=a@b commit -q --allow-empty -m spec; git -C "$T/sw" push -q origin vid-spec/x:vid-spec/x vid-spec/x:main 2>/dev/null
SP=$(gh pr create -R $R --head vid-spec/x --base main --title spec --body 'The spec, as ViD holds it.' | sed 's/.*\///'); git -C "$T/sw" rev-parse HEAD > "$T/gh/prs/$SP/merge"; git -C "$T/sw" rev-parse HEAD > "$T/gh/prs/$SP/headoid"; echo MERGED > "$T/gh/prs/$SP/state"
rd step; grep -q "^merged	$SP	-	" .vid/round/read || fail 'the spec pull request is not in the read as merged: nothing is proved'; ! grep -q 'flag-cleared word=devagent-quiet on=#1' .vid/metrics-events || fail "the merge of ViD's own spec pull request cleared the alarm"
# a claim clears it; old again, raised again, with no label too (FB-3 C3: a ticket on ViD's record counts without it); a pull request naming the ticket clears it
printf 'vid: claimed\nby: DM\n' > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; rd step; no '^flag devagent-quiet'; grep -q 'flag-cleared word=devagent-quiet on=#1' .vid/metrics-events || fail 'a claim did not clear it'
cp "$T/gh/issues/1/labels" "$T/lb"; : > "$T/gh/issues/1/labels"; back; rd step; ok '^flag devagent-quiet #1: '; cp "$T/lb" "$T/gh/issues/1/labels"
W=$T/w; git clone -q "$T/code.git" "$W" 2>/dev/null; git -C "$W" checkout -q -b ticket-1; git -C "$W" -c user.name=a -c user.email=a@b commit -q --allow-empty -m t; git -C "$W" push -q origin ticket-1 2>/dev/null
P=$(gh pr create -R $R --head ticket-1 --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "1")" | sed 's/.*\///'); rd step; no '^flag devagent-quiet'; [ "$(grep -c 'flag-cleared word=devagent-quiet on=#1' .vid/metrics-events)" = 2 ] || fail 'a pull request did not clear it'
# an issue of no ask of ViD's, its chunks reported, never claimed: nothing
echo CLOSED > "$T/gh/prs/$P/state"; tw_close 1; echo 'withdrawn 1 decision=self-test at=2020-01-01T00:00:00Z' >> .vid/tw/log
printf 'close: S01\ncommit: %s\nengines: alpha\n\n- chunk p1c1, alpha: ROW-003\n' "$(git -C "$T/code.git" rev-parse main)" > "$T/b"; C=$(gh issue create -R $R --title 'Close run: S01' --body-file "$T/b" --label run | sed 's/.*\///')
echo "asked $C close step=S01 commit=x at=2020-01-01T00:00:00Z" >> .vid/tw/log; printf 'vid: reported p1c1-1\nby: DM\n' > "$T/c"; gh issue comment "$C" -R $R --body-file "$T/c" > /dev/null
rd step; back; rd step; [ "$RC" = 0 ] || fail "the step with a close issue alone failed: $RC"; no '^flag devagent-quiet'
grep -q '^| `flag devagent-stopped <id>: <why>` (v0.26.10.28.6) | .*`The dev side stopped: <why>\. Start it again with /vid:vid-devagent <job note> in a new conversation in its work folder, or in the background with dm\.sh up <job note>\.`' "$CHECKS/../skills/vid-run/SKILL.md" 2>/dev/null || [ ! -d "$CHECKS/../skills" ] || fail "vid-run's devagent-stopped line does not offer the conversation first"   # 0.26.10.28.8 (R12)
exit 0
