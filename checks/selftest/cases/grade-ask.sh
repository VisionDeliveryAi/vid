#!/bin/sh
# Purpose: selftest case — the owner's grade asks (v0.26.10.27.2, R1, R2, R4), checks/grade.sh, results.sh, queue.sh on the writer's
# toy and the fake gh. The default scope: at a stage-1 candidate of a three-stage STAGES.md (0 to 2), stages 0 and 1's requirements, stage
# 2's deferred; the ask numbered by its issue, at the candidate's commit, its focus areas first. A `vs` ask and a robustify ask in their
# forms; robustify refused with two areas. The read: refused at the candidate's commit when the ask names another, refused for a `vs`
# line with no second word and with a fifth one, read with each; a finding's severity after its tag. Its findings ranked high, absent,
# facade, medium, partial, low, then none; a passing requirement's vs word a line for RM. A robustify `finding: rule` ruled row reaches
# the door as a rule row. Lost: asked again once, then `grade:<n>:lost` for the owner, out of `out`; again, then no, withdrawn and
# closed. With no candidate, main at the newest sync; vs refused with no copy of the code. The status line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "grade-ask: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; GA=$CHECKS/grade.sh; QS=$CHECKS/queue.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"
ga() { RC=0; sh "$GA" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide/stage/1/1 .vid/tw/out; printf 'close-wait-minutes: 600\n' >> .vid/tw/settings
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null || true; }
rep() { Q=grade-$1-$2; shift 2; rm -rf "$T/r/$Q"; mkdir -p "$T/r/$Q"; printf '%s\n' "$@" > "$T/r/$Q/grade.txt"; send "$Q"; fetch; }
gh issue create -R $R --title t0 --body b > /dev/null
( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m m1 && git push -q origin main ); X=$(git --git-dir="$T/code.git" rev-parse main); O=$(git --git-dir="$T/code.git" rev-list --max-parents=0 main | head -n 1)
printf '20\t2\t%s\t%s\n' "$X" "$X" > .vid/decide/merges; : > .vid/decide/stage/1/1/named; echo "$X" > .vid/decide/stage/1/1/commit; fetch
# the default scope: stages 0 and 1, stage 2's deferred; numbered by its issue; the focus first
EXP=$(sh "$CHECKS/stages.sh" scope --upto 1 --reqs | grep '^REQ-' | sort -u | paste -sd ' ' -); S2=$(sh "$CHECKS/stages.sh" scope --upto 2 --reqs | grep '^REQ-' | sort -u | grep -vxF -f "$(printf '%s\n' $EXP > "$T/e"; echo "$T/e")" | paste -sd ' ' -)
[ -n "$S2" ] || fail 'the toy has no stage 2 requirement'
ga ask --focus 'the digest sent twice'; [ "$RC" = 0 ] || fail "the ask failed ($RC)"; G=$(sed -n 's/^asked \([0-9]*\) grade ask-[0-9]*$/\1/p' "$T/out"); [ -n "$G" ] || fail 'no ask number'
B=$T/gh/issues/$G/body; grep -q grade "$T/gh/issues/$G/labels" || fail 'not on an issue labelled grade'
[ "$(sed -n 1,3p "$B")" = "$(printf 'grade: ask-%s\ncommit: %s\nrequirements: %s' "$G" "$X" "$EXP")" ] || fail "the ask's head: $(sed -n 1,3p "$B")"
grep -qx 'Focus areas, graded first and deepest: the digest sent twice' "$B" || fail 'no focus line'; grep -q "^Deferred, not asked: .*$(echo $S2 | cut -d' ' -f1)" "$B" || fail "stage 2's requirements not deferred"
grep -q 'its severity, high, medium or low, after its tag' "$B" || fail 'the severity is not asked'
# no STAGES.md: every live requirement but a later one (REQ-020, phase: later), deferred
mv STAGES.md "$T/stages"; ga ask; NS=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/out"); mv "$T/stages" STAGES.md; sed -n 3p "$T/gh/issues/$NS/body" | grep -q 'REQ-020' && fail 'a later requirement was asked'
grep -q '^Deferred, not asked: .*REQ-020' "$T/gh/issues/$NS/body" || fail 'the later requirement is not deferred'; sh "$GA" withdraw "$NS" > /dev/null
# a stage-0 candidate alone counts as none: stage 1's requirements, at main's newest merge
mkdir -p .vid/decide/stage/0/1; : > .vid/decide/stage/0/1/named; echo "$O" > .vid/decide/stage/0/1/commit; mv .vid/decide/stage/1/1/named "$T/named"; echo "sync main=$X open=- at=2026-11-10T09:00:00Z" >> .vid/tw/log
ga ask; [ "$RC" = 0 ] || fail "a stage-0 candidate refused the default ask: $(cat "$T/out")"; N0=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/out"); grep -qx "commit: $X" "$T/gh/issues/$N0/body" || fail "a stage-0 candidate's commit was asked"; sh "$GA" withdraw "$N0" > /dev/null; rm -rf .vid/decide/stage/0; mv "$T/named" .vid/decide/stage/1/1/named
# no candidate: main at the newest sync, though the merges record's last line names an older commit; vs refused with no copy of the code
mv .vid/decide/stage/1/1/named "$T/named"; printf '21\t3\t%s\t%s\n' "$O" "$O" >> .vid/decide/merges; echo "sync main=$X open=- at=2026-11-10T10:00:00Z" >> .vid/tw/log
ga ask --reqs "$(echo $EXP | cut -d' ' -f1)"; NC=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/out"); grep -qx "commit: $X" "$T/gh/issues/$NC/body" || fail "no candidate: $(sed -n 2p "$T/gh/issues/$NC/body"), not main's newest merge $X"; sh "$GA" withdraw "$NC" > /dev/null
mv "$T/named" .vid/decide/stage/1/1/named; mv .vid/code "$T/code"; ga ask --reqs "$(echo $EXP | cut -d' ' -f1)" --vs "$O"; mv "$T/code" .vid/code; [ "$RC" != 0 ] || fail 'a vs ask was posted with no copy of the code to find its commit in'
# a vs ask and a robustify ask; robustify needs 3 to 5 areas
F1=$(echo $EXP | cut -d' ' -f1); F2=$(echo $EXP | cut -d' ' -f2); ga ask --reqs "$F1 $F2" --vs "$O"; [ "$RC" = 0 ] || fail 'the vs ask failed'; V=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/out")
grep -qx "vs: $O" "$T/gh/issues/$V/body" && grep -qx "requirements: $F1 $F2" "$T/gh/issues/$V/body" && grep -q ' — vs: <word> — <reason>' "$T/gh/issues/$V/body" || fail 'the vs ask form'
ga ask --robustify 'sending; the feed'; [ "$RC" != 0 ] || fail 'robustify took two areas'
ga ask --robustify 'sending; the feed; unsubscribe'; [ "$RC" = 0 ] || fail 'the robustify ask failed'; RB=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/out")
grep -qx 'requirements: none' "$T/gh/issues/$RB/body" && grep -qx 'robustify: sending; the feed; unsubscribe' "$T/gh/issues/$RB/body" && grep -q 'finding: rule — <the invariant, in plain words>' "$T/gh/issues/$RB/body" && grep -q 'The report holds finding lines alone: no requirement line, and no line for an area as built' "$T/gh/issues/$RB/body" || fail 'the robustify ask form'
ln() { for r in $EXP; do echo "$r pass — read at its rows"; done; }
# the default ask: refused at another commit than the ask's, then read; its findings ranked
rep "$G" 1 'by: GR' "commit: $O" $(ln | tr ' ' '~'); sed -i.b 's/~/ /g' "$T/r/grade-$G-1/grade.txt"; send "grade-$G-1"; fetch; ga step; ok "^grade-ask-refused $G 1$"; grep -q 'not the one asked for' .vid/decide/grade/$G/read || fail "the refusal: $(cat .vid/decide/grade/$G/read)"
grep -rq '^vid: refused s1-1' "$T/gh/issues/$G/comments" || fail 'the refusal was not posted'
F3=$(echo $EXP | cut -d' ' -f3); { echo 'by: GR'; echo "commit: $X"; ln | sed -e "s/^$F1 pass/$F1 partial/" -e "s/^$F2 pass/$F2 absent/" -e "s/^$F3 pass/$F3 facade/"
  printf 'finding: bug low — a low one\nfinding: rule high — a high one\nfinding: bug — one with no severity\nfinding: rule medium — a medium one\n'; } > "$T/g"; rm -rf "$T/r/grade-$G-2"; mkdir -p "$T/r/grade-$G-2"; cp "$T/g" "$T/r/grade-$G-2/grade.txt"; send "grade-$G-2"; fetch
ga step; ok "^grade-ask $G read 2: "; [ "$(cat "$T/gh/issues/$G/state")" = CLOSED ] || fail 'the read ask stayed open'
sh "$QS" sync > /dev/null 2>&1; awk '/^- Q[0-9]+ .* grade ask #'"$G"'/' .vid/RUN-STATE.md | sed 's/.*grade ask #[0-9]*[^:]*: //' > "$T/q"
for w in 'a high one' "$F2 absent" "$F3 facade" 'a medium one' "$F1 partial" 'a low one' 'one with no severity'; do grep -n -- "$w" "$T/q" | head -n 1 | cut -d: -f1; done | paste -sd ' ' - > "$T/o"
[ "$(cat "$T/o")" = '1 2 3 4 5 6 7' ] || { cat "$T/q" >&2; fail "not ranked: $(cat "$T/o")"; }
sh "$QS" status > "$T/out" 2>&1; ok '^grade asks: 2 out · 7 findings to rule$'
# the vs ask: no second word, a fifth one, then read; a pass's vs word a line for RM
rep "$V" 1 'by: GR' "commit: $X" "$F1~pass~—~fine" "$F2~pass~—~fine~—~vs:~partial~—~half"; sed -i.b 's/~/ /g' "$T/r/grade-$V-1/grade.txt"; send "grade-$V-1"; fetch; ga step; ok "^grade-ask-refused $V 1$"; grep -q "$F1 has no vs: word" .vid/decide/grade/$V/read || fail "no vs word: $(cat .vid/decide/grade/$V/read)"
printf 'by: GR\ncommit: %s\n%s pass — fine — vs: broken — odd\n%s pass — fine — vs: partial — half\n' "$X" "$F1" "$F2" > "$T/g"; rm -rf "$T/r/grade-$V-2"; mkdir -p "$T/r/grade-$V-2"; cp "$T/g" "$T/r/grade-$V-2/grade.txt"; send "grade-$V-2"; fetch; ga step
ok "^grade-ask-refused $V 2$"; grep -q "$F1 has no vs: word of the four: broken" .vid/decide/grade/$V/read || fail "a fifth word: $(cat .vid/decide/grade/$V/read)"
printf 'by: GR\ncommit: %s\n%s partial —  — vs: absent — none then\n%s pass — fine — vs: partial — half\n' "$X" "$F1" "$F2" > "$T/g"; rm -rf "$T/r/grade-$V-3"; mkdir -p "$T/r/grade-$V-3"; cp "$T/g" "$T/r/grade-$V-3/grade.txt"; send "grade-$V-3"; fetch; ga step
ok "^grade-ask-refused $V 3$"; grep -q "$F1 has no reason" .vid/decide/grade/$V/read || fail "an empty first reason: $(cat .vid/decide/grade/$V/read)"
printf 'by: GR\ncommit: %s\n%s partial — half — vs: absent — none then\n%s pass — fine — vs: partial — half\n' "$X" "$F1" "$F2" > "$T/g"; rm -rf "$T/r/grade-$V-4"; mkdir -p "$T/r/grade-$V-4"; cp "$T/g" "$T/r/grade-$V-4/grade.txt"; send "grade-$V-4"; fetch; ga step
ok "^grade-ask $V read 4: "; ok "^vs $V $F2 partial — half$"; sh "$QS" sync > /dev/null 2>&1; grep -q "grade ask #$V: $F1 partial — half · vs $O: absent — none then · rule it" .vid/RUN-STATE.md || fail "the vs word is not in its item"
! grep -q "grade ask #$V: $F2" .vid/RUN-STATE.md || fail 'a vs comparison made an item'
a=$(grep -n "grade ask #$V: $F1 partial" .vid/RUN-STATE.md | cut -d: -f1); b=$(grep -n "grade ask #$G's finding: bug low" .vid/RUN-STATE.md | cut -d: -f1); [ "$a" -lt "$b" ] || fail "not ranked across the asks: #$V's partial at $a, #$G's low at $b"
# robustify: its rule line ruled row reaches the door as a rule row
rep "$RB" 1 'by: GR' "commit: $X" 'finding: rule — every send names its tenant, in the sender and the digest'; ga step; ok "^grade-ask $RB read 1: 0 graded"
sh "$QS" sync > /dev/null 2>&1; QR=$(sed -n "s/^- \(Q[0-9]*\) · .*grade ask #$RB's finding: rule — every send.*/\1/p" .vid/RUN-STATE.md); [ -n "$QR" ] || fail 'the robustify rule reached no Q line'
RC=0; sh "$QS" answer "$QR" later 2 'later' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'later was taken for a grade finding'
sh "$QS" answer "$QR" row 'make it a rule' > "$T/out" 2>&1 || fail 'row refused'; ok "^door: /vid fix — a new rule row, its places counted in covers:, armed in every later ticket, for grade ask #$RB's line: finding: rule — every send names its tenant"
grep -qx "grade:$RB:1" .vid/decide/queue/doors || fail 'the door does not wait on its draft'
# lost: again once, then the owner's; again; then no, withdrawn
sed 's/^close-wait-minutes: 600$/close-wait-minutes: 0/' .vid/tw/settings > "$T/st" && cat "$T/st" > .vid/tw/settings
ga ask --reqs "$F1"; L=$(sed -n 's/^asked \([0-9]*\) .*/\1/p' "$T/out"); fetch; ga step; ok "^grade-again $L$"; grep -rq '^vid: again s1' "$T/gh/issues/$L/comments" || fail 'again not posted'
ga step; ok "^grade-lost $L$"; sh "$GA" out | grep -qx "$L" && fail 'a lost ask is still out'; sh "$GA" out | grep -qx "$V" && fail 'a read ask is still out'
sh "$QS" sync > /dev/null 2>&1; QL=$(sed -n "s/^- \(Q[0-9]*\) · .*grade ask #$L could not be read.*/\1/p" .vid/RUN-STATE.md); [ -n "$QL" ] || fail 'the lost ask reached no Q line'
sh "$QS" answer "$QL" again 'once more' > "$T/out" 2>&1 || fail 'again refused'; ga step; ok "^grade-again $L$"; ga step; ok "^grade-lost $L$"; sh "$QS" sync > /dev/null 2>&1; grep -q "grade ask #$L could not be read" .vid/RUN-STATE.md || fail 'lost again reached no Q line'
sh "$QS" answer "$QL" no 'leave it' > "$T/out" 2>&1 || fail 'no refused'; [ -f .vid/decide/grade/$L/withdrawn ] && [ "$(cat "$T/gh/issues/$L/state")" = CLOSED ] || fail 'not withdrawn'; grep -rq '^vid: withdrawn' "$T/gh/issues/$L/comments" || fail 'no withdrawn comment'
sh "$QS" sync > /dev/null 2>&1; ! grep -q "grade ask #$L could not be read" .vid/RUN-STATE.md || fail 'the withdrawn ask kept its Q line'
sh "$QS" status > "$T/out" 2>&1; ok '^grade asks: 0 out · '
exit 0
