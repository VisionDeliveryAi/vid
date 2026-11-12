#!/bin/sh
# Purpose: selftest case — the step close (v0.26.10.25.3, R8, R10), checks/close.sh on the toy and the fake gh. A close owed once its step's
# tickets have merged, found again from the records; the ask's rows, chunks by case seconds and phases by engine, an issue labelled run,
# logged, and owed no more; a chunk absent past the quiet asked again once, then lost a second time an item for the owner, answered again;
# a red chunk an item; a row failing in one engine and passing in another writes the split; a green close writes `closed`, closes the
# ask, and the next step may start. v0.26.10.25.5: a withdrawn ask read no more, no close while the writer owes the step a
# ticket, and the whole close asked again after. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "close-step: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
M=$(git --git-dir="$T/code.git" rev-parse main); printf 'close-chunk-minutes: 1\nclose-wait-minutes: 0\n' >> .vid/tw/settings
# S01's one ticket, #1, merged as pull request 2: three rows, one a journey, one deploy-owed, one with the product's processes
printf '# t\n\n## Header\n\n- number: 1\n- kind: skeleton\n\n## Rows\n\n> ROW-003 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-003 marks: none\n> ROW-004 | journey | j | b | n/a | x transitions: 1. a 2. b | REQ-001 | o\n- ROW-004 marks: journey; run with the product'"'"'s processes\n> DIF-001 | difference | a | b | c | d | e\n- DIF-001 marks: owed-staging\n\n## Regression rows\n\n- ROW-001\n' > .vid/tw/out/issue-1.md
printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004,DIF-001 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log; echo 2 > .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" > .vid/decide/merges
printf 'engines alpha beta | stand-in: results reader\n' >> .vid/tw/handed
# owed, and found again from the records alone
cs owed; ok '^close S01$'; cs ask S01; [ "$RC" = 0 ] || fail 'the ask failed'; ok '^asked [0-9]* close S01$'; N=$(sed -n 's/^asked \([0-9]*\) close.*/\1/p' "$T/out")
B=$T/gh/issues/$N/body; grep -q run "$T/gh/issues/$N/labels" || fail 'the ask is not labelled run'; grep -qx 'Close run: S01' "$T/gh/issues/$N/title" 2>/dev/null || grep -q 'Close run:' "$T/gh/issues/$N/title" || fail 'the ask has no title'
grep -qx "commit: $M" "$B" && grep -qx 'engines: alpha beta' "$B" || fail 'the ask names no commit or engines'
grep -qx -- '- chunk p1c1, alpha: ROW-003 ROW-004' "$B" && grep -qx -- '- chunk p1c2, alpha: ROW-001' "$B" && grep -qx -- '- chunk p2c1, beta: ROW-003 ROW-004' "$B" && grep -qx -- '- chunk p2c2, beta: ROW-001' "$B" || fail "the chunks: $(grep chunk "$B")"
grep -qx -- "- with the product's own declared processes: ROW-004" "$B" && ! grep -q DIF-001 "$B" || fail 'the processes line, or a deploy-owed row'
grep -q "^asked $N close step=S01 commit=$M" .vid/tw/log || fail 'the ask is not logged'; cs owed; ! grep -q . "$T/out" || fail 'a close owed twice'; cs out; ok '^out S01$'
# reports: phase 1 green; p2c1 red in beta for ROW-004, so the split; p2c2 absent, past the quiet
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; E=$2; shift 2; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$M")"; rr_put "$Q" cases-$E.xml "$(rr_cases "$@")"; send "$Q"; }
rq p1c1-1 alpha ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass; rq p1c2-1 alpha ROW-001=pass; rq p2c1-1 beta ROW-003=pass ROW-004-T1=fail:broke ROW-004-T2=pass
sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null
cs decide S01; [ "$RC" = 0 ] || fail 'decide failed'; ok '^close-red S01 p2c1'; ok '^split ROW-004$'; ok '^close-again S01 p2c2$'; grep -q '^engine-split ROW-004 | stand-in: alpha' .vid/tw/handed || fail 'the split was not written'
last=$(ls "$T/gh/issues/$N/comments" | sort -n | tail -n 1); head -n 1 "$T/gh/issues/$N/comments/$last" | grep -qx 'vid: again p2c2' || fail 'the lost chunk was not asked again'
grep -q '^red p2c1 beta:ROW-004' .vid/decide/close/S01/1/items || fail 'the red chunk is no item'
# lost a second time: an item, a Q line; the owner's again asks once more
sh "$GS" round-read > .vid/round/read 2>/dev/null; cs decide S01; ok '^close-lost S01 p2c2$'; grep -q '^lost p2c2' .vid/decide/close/S01/1/items || fail 'the twice-lost chunk is no item'
sh "$CHECKS/queue.sh" sync > /dev/null 2>&1; grep -q 'the close of S01, chunk p2c2, lost twice' .vid/RUN-STATE.md || fail 'no Q line for the lost chunk'
QN=$(sed -n 's/^- \(Q[0-9]*\) · .*chunk p2c2, lost twice.*/\1/p' .vid/RUN-STATE.md); sh "$CHECKS/queue.sh" answer "$QN" again 'run it once more' > "$T/out" 2>&1 || fail 'the again answer failed'
sed 's/^close-wait-minutes: 0$/close-wait-minutes: 99/' .vid/tw/settings > "$T/st" && cat "$T/st" > .vid/tw/settings; cs decide S01; ok '^close-again S01 p2c2$'; sed 's/^close-wait-minutes: 99$/close-wait-minutes: 0/' .vid/tw/settings > "$T/st" && cat "$T/st" > .vid/tw/settings   # the owner's again, at once
# lost again after that again: a new item, a new Q line
sh "$GS" round-read > .vid/round/read 2>/dev/null; cs decide S01; ok '^close-lost S01 p2c2$'; sh "$CHECKS/queue.sh" sync > /dev/null 2>&1; [ "$(grep -c 'chunk p2c2, lost twice' .vid/RUN-STATE.md)" = 1 ] || fail 'a chunk lost again after the again reached no Q line'
QN=$(sed -n 's/^- \(Q[0-9]*\) · .*chunk p2c2, lost twice.*/\1/p' .vid/RUN-STATE.md); sh "$CHECKS/queue.sh" answer "$QN" again 'once more' > "$T/out" 2>&1 || fail 'the second again failed'; cs decide S01; ok '^close-again S01 p2c2$'
# the red rows ruled known limits, the lost chunk reported: green, closed, the ask closed, the next step's rule B passes
printf 'ROW-004\tknown limit\tknown limit\t2\t%s\tx\n' "$(printf %.12s "$M")" >> .vid/decide/state; tw_hand 'row ROW-004 known-limit'; rq p2c2-1 beta ROW-001=pass; sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null
cs decide S01; ok '^closed S01$'; grep -q "^closed S01 | stand-in: close #$N at $(printf %.12s "$M")" .vid/tw/handed || fail 'no closed line'; [ "$(cat "$T/gh/issues/$N/state")" = CLOSED ] || fail 'the ask stayed open'
cs out; ! grep -q . "$T/out" || fail 'a closed step is still out'; cs owed; ! grep -q . "$T/out" || fail 'a closed step is owed again'
# v0.26.10.25.5 R5: S01 gains a row at a landing: reopened, its ask withdrawn and read no more; no close while the writer owes S01 a ticket;
# once its new ticket has merged, a close by the first rule, the whole close again
{ grep -v '^closed S01 ' .vid/tw/handed || true; } > "$T/hd"; cat "$T/hd" > .vid/tw/handed; printf 'x 2026-11-09T12:00:00Z\n' > .vid/decide/close/S01/1/withdrawn
printf 'ROW-003 x 2026-11-09T12:00:00Z\n' > .vid/decide/landed; printf 'landed 1 ids=ROW-003 at=2026-11-09T12:00:00Z\n' >> .vid/tw/log; printf 'step-start step=S01 at=2026-11-09T09:00:00Z\n' >> .vid/metrics-events
cs out; ! grep -q S01 "$T/out" || fail 'a withdrawn ask is out'; cs decide S01; ! grep -q . "$T/out" || fail 'a withdrawn ask was decided'
RC=0; sh "$CHECKS/results.sh" close --step S01 > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q withdrawn "$T/out" || fail 'the reader read a withdrawn ask'
sh "$CHECKS/writer.sh" due > "$T/out" 2>&1; ok '^new step S01$'; cs owed; ! grep -q . "$T/out" || fail 'a close was owed while the writer owes S01 its new ticket'
printf 'published 7 kind=step step=S01 rows=ROW-003 at=2026-11-09T13:00:00Z\nsync main=%s open= at=2026-11-09T13:30:00Z\n' "$M" >> .vid/tw/log; echo 8 >> .vid/decide/merged-prs; printf '8\t7\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
sh "$CHECKS/writer.sh" due > "$T/wd" 2>&1 || true; cs owed; grep -q '^close S01$' "$T/out" || fail "no close owed; the writer owes: $(cat "$T/wd")"; cs ask S01; ok '^asked [0-9]* close S01$'; [ -f .vid/decide/close/S01/2/ask ] && grep -q '^asked	' .vid/decide/close/S01/2/ask || fail 'the close again is not ask 2'
exit 0
