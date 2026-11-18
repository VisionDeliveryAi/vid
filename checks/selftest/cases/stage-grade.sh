#!/bin/sh
# Purpose: selftest case — a stage's grade, S1, and R-2 (v0.26.10.26.1 R3, R4, R5), checks/close.sh and results.sh on the writer's
# toy and the fake gh, stage 1. S1 asked on an issue labelled grade, the stage's requirements; a report refused for a requirement
# missing, a fifth word and a wrong commit, each refusal posted; a report read, the newest grade per requirement kept, the issue
# closed; the findings: a non-pass grade, a finding line and an unmatched case of the rest chunk, while a case holding an id is
# credited to none; the status line and the findings count; at a later candidate only the touched requirements, or no S1; S1 lost
# again once, then the owner's, answered again alone. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-grade: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; W=$CHECKS/writer.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"; : > "$T/werr"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings; tw_hand 'engines alpha beta'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'   # v0.26.10.26.5 (R5a): stages close in order
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
# tk <n> <kind> <step> <rows,> <regression rows>: a ticket published by hand; mg <pr> <n>: merged at a new main commit
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; for r in $5; do printf -- '- %s\n' "$r"; done; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1   # issue #1 a placeholder, so tickets begin at 2
tk 2 step S02 ROW-001,ROW-012 ROW-003; mg 20 2; tk 3 step S03 ROW-006 ''; mg 21 3; tk 4 step S04 ROW-002,DIF-001,ROW-013 ''; mg 22 4; tk 5 fix S02 ROW-005 ''; mg 23 5
tk 6 step S05 ROW-012 ''   # a stage 2 ticket still open holds ROW-012: its newest ticket is open
for r in ROW-001 ROW-012 ROW-003 ROW-006 ROW-002 ROW-005; do tw_hand "row $r accepted"; done; tw_hand 'row DIF-001 owed'; tw_hand 'row ROW-013 known-limit'
printf 'ROW-013\tknown limit\tknown limit\t22\tx\tx\nROW-001\taccepted\taccepted\t20\tx\tx\n' >> .vid/decide/state; sed 's/^- DIF-001 marks: none$/- DIF-001 marks: owed-staging/' .vid/tw/out/issue-4.md > "$T/i4" && cat "$T/i4" > .vid/tw/out/issue-4.md; sh "$GS" tw-sync > /dev/null 2>&1
# the candidate: C3 with its rest chunk, and S1 on the stage's every requirement
X=$(git --git-dir="$T/code.git" rev-parse main); fetch; cs ask --stage 1; [ "$RC" = 0 ] || fail "the ask failed ($RC)"; N=$(sed -n 's/^asked \([0-9]*\) close stage-1$/\1/p' "$T/out"); G=$(sed -n 's/^asked \([0-9]*\) grade stage-1$/\1/p' "$T/out")
K=.vid/decide/stage/1/1; [ -n "$G" ] && grep -q grade "$T/gh/issues/$G/labels" || fail 'S1 is not asked on an issue labelled grade'
RQ=$(sh "$CHECKS/stages.sh" scope --upto 1 --reqs | grep '^REQ-' | sort | paste -sd ' ' -); P0=$(sh "$CHECKS/stages.sh" scope --upto 0 --reqs 2>/dev/null | grep '^REQ-' | sort | paste -sd ' ' -)
EXP=$(printf '%s\n' $RQ | grep -vxF -f "$(printf '%s\n' $P0 > "$T/p0"; echo "$T/p0")" | paste -sd ' ' -); [ "$(sed -n 's/^reqs\t//p' $K/s1ask)" = "$EXP" ] || fail "S1's requirements: $(sed -n 's/^reqs\t//p' $K/s1ask), not $EXP"
grep -qx 'grade: stage-1' "$T/gh/issues/$G/body" && grep -qx "commit: $X" "$T/gh/issues/$G/body" && grep -qx "requirements: $EXP" "$T/gh/issues/$G/body" || { head -3 "$T/gh/issues/$G/body" | od -c | head -5; echo "X=$X G=$G"; fail 'the S1 body'; }
sg() { Q=grade-$G-$1; shift; rm -rf "$T/r/$Q"; rr_put "$Q" grade.txt "$(printf '%s\n' "$@")"; send "$Q"; }
ln() { for r in $EXP; do echo "$r ${1:-pass} — read at its rows"; done; }
# refused: a requirement missing, a fifth word, a wrong commit; each posted once
sg 1 'by: GR' "commit: $X" $(ln | sed 1d | tr ' ' '~'); sed -i.b 's/~/ /g' "$T/r/grade-$G-1/grade.txt" 2>/dev/null || true; send "grade-$G-1"; fetch; cs decide --stage 1; ok '^s1-refused 1 1$'
grep -rq '^vid: refused s1-1' "$T/gh/issues/$G/comments" || fail 'the refusal was not posted'; grep -q 'has no grade' $K/s1read || fail "the refusal's why: $(cat $K/s1read)"
F=$(echo $EXP | cut -d' ' -f1); { echo 'by: GR'; echo "commit: $X"; ln | sed "s/^$F pass/$F broken/"; } > "$T/g2"; rm -rf "$T/r/grade-$G-2"; mkdir -p "$T/r/grade-$G-2"; cp "$T/g2" "$T/r/grade-$G-2/grade.txt"; send "grade-$G-2"; fetch; cs decide --stage 1; ok '^s1-refused 1 2$'; grep -q 'no word of the four' $K/s1read || fail 'a fifth word read'
O=$(git --git-dir="$T/code.git" rev-list --max-parents=0 main | head -n 1); { echo 'by: GR'; echo "commit: $O"; ln; } > "$T/g3"; rm -rf "$T/r/grade-$G-3"; mkdir -p "$T/r/grade-$G-3"; cp "$T/g3" "$T/r/grade-$G-3/grade.txt"; send "grade-$G-3"; fetch; cs decide --stage 1; ok '^s1-refused 1 3$'; grep -q 'not the one asked for' $K/s1read || fail 'a wrong commit read'
# read: the grades kept, the newest per requirement; the non-pass grades and the findings recorded; the issue closed
S=$(echo $EXP | cut -d' ' -f2); { echo 'by: GR'; echo "commit: $X"; ln | sed "s/^$S pass/$S facade/"; echo 'finding: bug — the digest repeats a job'; echo 'finding: rule medium — the support address on every footer'; } > "$T/g4"; rm -rf "$T/r/grade-$G-4"; mkdir -p "$T/r/grade-$G-4"; cp "$T/g4" "$T/r/grade-$G-4/grade.txt"; send "grade-$G-4"
# the rest chunk: a case holding no id listed, one holding an id credited to none
rq p1cx-1 "$X" alpha test_harness_boots=pass ROW-001=pass; fetch; cs decide --stage 1; ok '^s1 1 read$'; [ "$(cat "$T/gh/issues/$G/state")" = CLOSED ] || fail 'the S1 issue stayed open'
[ "$(grep -c . .vid/decide/stage/1/s1)" = "$(echo $EXP | wc -w | tr -d ' ')" ] && grep -q "^$S	facade	1$" .vid/decide/stage/1/s1 || fail "the stage's grades: $(cat .vid/decide/stage/1/s1)"
grep -qx "grade $S facade — read at its rows" $K/findings && grep -qx 'finding: rule medium — the support address on every footer' $K/findings && grep -qx 'finding: bug — the digest repeats a job' $K/findings && grep -qx 'unmatched test_harness_boots passed' $K/findings || fail "the findings: $(cat $K/findings)"
! grep -q 'unmatched ROW-001' $K/read || fail 'a case holding an id was listed'
sh "$QS" status > "$T/out" 2>&1; ok "^stage 1: candidate 1 at [0-9a-f]* · C3 out · S1 $(echo $EXP | wc -w | tr -d ' ') of $(echo $EXP | wc -w | tr -d ' ') graded, $(( $(echo $EXP | wc -w) - 1 )) pass · findings 4 · paid [0-9]* of [0-9]* · findings 0 of 4 ruled · the close waits on [0-9, ]* · test site: not known yet$"   # v0.26.10.28.8 (R7): no D1 yet   # v0.26.10.26.4: each a queue item
# a later candidate: only the touched requirements; none when the merge touches none
for c in p1c1 p2c1; do e=alpha; [ $c = p1c1 ] || e=beta; rq "$c-1" "$X" "$e" ROW-001=pass ROW-003=pass ROW-006=pass ROW-002=pass ROW-005=pass; done; fetch; cs decide --stage 1; ok '^stage-c3 1 passed$'
tk 7 fix S03 ROW-006 ''; mg 24 7; fetch; cs owed; ok '^stage 1$'; cs ask --stage 1; ok '^candidate 1 2$'
TR=$(sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' '{ a = $1; gsub(/[ \t]/, "", a) } a == "ROW-006" { n = split($7, t, /[ ,]+/); for (i = 1; i <= n; i++) if (t[i] ~ /^REQ-/) print t[i] }' | grep -xF -f "$(printf '%s\n' $EXP > "$T/e"; echo "$T/e")" | sort | paste -sd ' ' -)
echo "stage-grade: touched $TR" >&2; if [ -n "$TR" ]; then [ "$(sed -n 's/^reqs\t//p' .vid/decide/stage/1/2/s1ask)" = "$TR" ] || fail "S1 at candidate 2: $(sed -n 's/^reqs\t//p' .vid/decide/stage/1/2/s1ask), not $TR"
else [ ! -f .vid/decide/stage/1/2/s1ask ] || fail 'an S1 asked with nothing touched'; fi
# lost: no report past the quiet, again once, then the owner's, answered again
G2=$(sed -n 's/^issue\t//p' .vid/decide/stage/1/2/s1ask 2>/dev/null); if [ -n "$G2" ]; then fetch; cs decide --stage 1; ok '^close-again stage-1 s1$'; fetch; cs decide --stage 1; ok '^close-lost stage-1 s1$'
  sh "$QS" sync > /dev/null 2>&1; grep -q 'the close of stage-1, its grade S1, lost twice · answer again' .vid/RUN-STATE.md || fail 'the lost S1 reached no Q line'
  QN=$(sed -n 's/^- \(Q[0-9]*\) · .*its grade S1, lost twice.*/\1/p' .vid/RUN-STATE.md); RC=0; sh "$QS" answer "$QN" limit 'no' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a limit was taken for S1'
  sh "$QS" answer "$QN" again 'once more' > "$T/out" 2>&1 || fail 'again refused'; fetch; cs decide --stage 1; ok '^close-again stage-1 s1$'
  grep -rlx 'why: once more' "$T"/gh/issues/*/comments/ > /dev/null 2>&1 || fail "the S1 again carries no words"   # 0.26.10.29.1 (R2): an again's words reach the dev side
  # a new candidate while that S1 is out: it is withdrawn, and its requirements join the new S1
  X2=$(sed -n 's/^commit\t//p' .vid/decide/stage/1/2/ask); N=$(sed -n 's/^issue\t//p' .vid/decide/stage/1/2/ask)
  for c in p1c1 p2c1; do e=alpha; [ $c = p1c1 ] || e=beta; rq "$c-1" "$X2" "$e" ROW-001=pass ROW-003=pass ROW-006=pass ROW-002=pass ROW-005=pass; done; rq p1cx-1 "$X2" alpha test_other=pass; fetch; cs decide --stage 1; ok '^stage-c3 1 passed$'
  tk 8 fix S04 ROW-002 ''; mg 25 8; fetch; cs owed; ok '^stage 1$'; cs ask --stage 1; ok '^candidate 1 3$'; [ -f .vid/decide/stage/1/2/s1withdrawn ] || fail "candidate 2's S1 was not withdrawn"
  for r in $TR; do grep -q "^reqs	.*$r" .vid/decide/stage/1/3/s1ask || fail "candidate 2's $r did not join candidate 3's S1: $(grep reqs .vid/decide/stage/1/3/s1ask)"; done; fi
echo "stage-grade: the end"
exit 0
