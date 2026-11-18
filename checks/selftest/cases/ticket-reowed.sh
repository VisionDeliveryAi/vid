#!/bin/sh
# Purpose: selftest case — a ticket closed outside ViD owes its rows again, and its closed step opens again (v0.26.10.27.3, STAGE-8-1B-SPEC.md R2, R3), checks/writer.sh
# through checks/round.sh on the toy and the fake gh. The skeleton, closed outside, is owed `new skeleton`, written and published
# again; a step ticket the round published, closed outside, owes `new step <s>` for its rows (they were sent, so before R2 they
# read as delivered); a step of a closed stage is owed them again too (0.26.10.29.2 R4), the step left closed. S01's close and stage 0's staging are planted handed
# lines, so that the round publishes a step ticket. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "ticket-reowed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
due() { sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || fail "due failed: $(cat "$T/out")"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
tw_hand 'candidate 1'
# the skeleton closed outside: new skeleton, written and published again
rd next; [ "$RC" = 0 ] || fail "next failed: $(cat "$T/out")"; ok '^published 1$'; due; no '^new skeleton'
gh issue close 1 -R $R > /dev/null; rd step; ok '^closed-outside 1 S01$'; due; ok '^new skeleton$'
rd next; ok '^published [0-9]'; N1=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out" | head -n 1); grep -q "^published $N1 kind=skeleton " .vid/tw/log || fail 'no new skeleton published'; due; no '^new skeleton'
# a step ticket the round published (its rows sent), closed outside: its rows owed again
tw_closed S01; tw_hand 'candidate 0'; tw_hand 'staged 0'; tw_hand 'engines alpha'; rd next; N2=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out" | grep -vx "$N1" | head -n 1); [ -n "$N2" ] || fail "no step ticket published: $(cat "$T/out")"
S=$(awk -v n="$N2" '$1 == "published" && $2 == n { for (i = 3; i <= NF; i++) if ($i ~ /^step=/) print substr($i, 6) }' .vid/tw/log); grep -q "^sent [A-Z0-9-]* ticket=$N2 " .vid/tw/log || fail 'its rows were not sent'
# R3: its step closed meanwhile (a plant: the closed line, a green close ask) reopens: the line dropped, the old ask withdrawn, and the
# next step does not close it again; the writer still runs
tw_hand "closed $S"; mkdir -p .vid/decide/close/$S/1; printf 'issue\t90\ncommit\t%s\nasked\t2026-11-10T11:00:00Z\n' "$(git --git-dir="$T/code.git" rev-parse main)" > .vid/decide/close/$S/1/ask; : > .vid/decide/close/$S/1/done
due; no "^new step $S\$"; gh issue close "$N2" -R $R > /dev/null; rd step; ok "^closed-outside $N2 $S\$"; ok "^step-reopened $S #$N2\$"
! grep -q "^closed $S " .vid/tw/handed || fail 'the closed line stayed'; [ -f .vid/decide/close/$S/1/withdrawn ] || fail 'the old ask not withdrawn'; grep -q "^close-reopened step=$S ticket=$N2" .vid/metrics-events || fail 'no close-reopened event'
rd step; no "^closed $S"; no "^step-reopened $S"; ! grep -q "^closed $S " .vid/tw/handed || fail 'closed again at once'; due; ok "^new step $S\$"
# R3 by the state: the step closed later (as a C3 would close it, a plant) while its rows are still owed: reopened again
tw_hand "closed $S | stand-in: C3 #77 at 000000000000"; rd step; ok "^step-reopened $S #$N2\$"; ! grep -q "^closed $S " .vid/tw/handed || fail 'a later close not reopened'
# with no stage candidate (the planted candidate line taken out), the step's close is owed again once its new ticket merges
grep -v '^candidate 1 ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed; rd next; N4=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out" | head -n 1); [ -n "$N4" ] && grep -q "^published $N4 kind=step step=$S " .vid/tw/log || fail "no new ticket for $S: $(cat "$T/out")"
W=$T/w; git clone -q "$T/code.git" "$W" 2>/dev/null; git -C "$W" checkout -q -B tk4 origin/main; git -C "$W" -c user.name=a -c user.email=a@b commit -q --allow-empty -m tk4; git -C "$W" push -q -f origin tk4; H4=$(git -C "$W" rev-parse HEAD)
P4=$(gh pr create -R $R --head tk4 --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$N4")" | sed 's/.*\///'); gh pr ready "$P4" -R $R; gh pr merge "$P4" -R $R --merge --match-head-commit "$H4" --body m > /dev/null; rd step; ok "^merged $P4"
sh "$CHECKS/close.sh" owed > "$T/out" 2>&1; ok "^close $S\$"
# its stage closed: its rows went out again in #N4, which merged, so nothing more is owed
G=$(sed -n 's/^- stage: \([0-9]*\).*/\1/p' ".vid/tw/out/issue-$N2.md" | head -n 1)
[ -n "$G" ] || fail 'no stage on the ticket'; tw_hand "stage-closed $G | stand-in: RM at 000000000000 candidate 1"; due; no "^new step $S\$"
# R3: a ticket of a closed stage's step closed outside: the step stays closed, the owner's line once (a planted ticket)
tw_hand "closed $S"; N3=$(gh issue create -R $R --title "t $S" --body b --label ticket | sed 's/.*\///'); printf 'published %s kind=step step=%s rows=x at=2026-11-10T10:00:00Z\n' "$N3" "$S" >> .vid/tw/log; printf -- '- stage: %s\n' "$G" > ".vid/tw/out/issue-$N3.md"
gh issue close "$N3" -R $R > /dev/null; rd step; ok "^closed-outside $N3 $S\$"; ok "^closed-stage-rows $S $G\$"; no "^step-reopened $S"; grep -q "^closed $S " .vid/tw/handed || fail 'a closed stage step reopened'
rd step; no "^closed-stage-rows $S"
# R2's landing reader (lnew): the skeleton merged (a plant), a landing then adds one of its rows and a correction ticket holds it; closed
# outside, the row is owed again with the stage open; with its stage closed, nothing is owed
r1=$(sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | awk -F' [|] ' '$1 == "step S01" { for (i = 2; i <= NF; i++) if ($i ~ /^rows: /) { sub(/^rows: /, "", $i); split($i, a, " "); print a[1] } }')
printf '9\t%s\t%s\t%s\n' "$N1" "$(git --git-dir="$T/code.git" rev-parse main)" "$(git --git-dir="$T/code.git" rev-parse main)" >> .vid/decide/merges; echo 9 >> .vid/decide/merged-prs; gh issue close "$N1" -R $R > /dev/null
printf 'landed draft=L1 at=2026-11-10T12:00:00Z ids=%s\n' "$r1" >> .vid/tw/log; N5=$(gh issue create -R $R --title "t S01 fix" --body b --label ticket | sed 's/.*\///')
printf 'published %s kind=step step=S01 rows=%s at=2026-11-10T12:30:00Z\n' "$N5" "$r1" >> .vid/tw/log; G0=$(sed -n 's/^- stage: \([0-9]*\).*/\1/p' ".vid/tw/out/issue-$N1.md" | head -n 1); printf -- '- stage: %s\n' "$G0" > ".vid/tw/out/issue-$N5.md"
due; no '^new step S01$'; gh issue close "$N5" -R $R > /dev/null; rd step; ok "^closed-outside $N5 S01\$"; due; ok '^new step S01$'
tw_hand "stage-closed $G0 | stand-in: RM at 000000000000 candidate 1"; due; ok '^new step S01$'   # 0.26.10.29.2 (R4): a closed stage's step too
exit 0
