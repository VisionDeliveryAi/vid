#!/bin/sh
# Purpose: selftest case — an outside-service row is paid only by a real call (0.26.11.1.1, R4), checks/close.sh, results.sh and
# queue.sh on the writer's toy and the fake gh. A candidate of stage 1 is planted with its C3 passed. An okay with no seam row says
# `outside-service rows: none`; with the toy's two seam rows merged it lists them, `outside-service rows: SEAM-001 SEAM-002`; a passed
# D1 lacking a `seam:` line for a listed row is refused. With SEAM-002 taken off the okay's list (a plant: a row CS asks that the okay
# did not list), SEAM-001 marked real and SEAM-002 a stand-in, CS passing both pays SEAM-001 alone; SEAM-002 is a Q line, `stand-in 1
# SEAM-002 — <why>`, answered limit or again, the owner's alone. Again moves the candidate's d1 and cs to numbered folders, the walk
# and its findings untouched, and the round asks D1 and CS afresh at the same candidate, CS not refused for the earlier ask; SEAM-002
# off the list again and unanswered, it is `stand-in 1 SEAM-002 — not answered`, whose limit pays it as a known limit; that CS closes
# its own issue once read, the walk being over. The again is reached through `out`, and answered while the walk is out it waits for
# the walk's end, staging held, then moves d1 and cs and closes the old CS issue. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-seam-stand-in: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; RS=$CHECKS/results.sh; R=owner/code; TAB=$(printf '\t'); mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
DU=$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done)
# dp <okay> <k> <staging.txt>: a passed D1 report, its duties done
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$X")"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"; rr_put "$Q" staging.txt "$3"; rr_put "$Q" duties.txt "$DU"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(echo "$5" | tr ' ' '\n' | sed -n "s/^$r=//p" | tr '+' ' ' | grep . || echo none)"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
# an okay with no seam row first: stage 1's candidate before the seam ticket merged
tk 2 skeleton S01 ROW-003 ''; mg 20 2; tw_hand 'row ROW-003 accepted'; tw_hand 'closed S01'; sh "$GS" tw-sync > /dev/null 2>&1
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p $K; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit; : > $K/named; : > $K/passed
cs okay --stage 1; O0=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); grep -qx 'outside-service rows: none' "$T/gh/issues/$O0/body" || fail "no seam row: $(head -n 5 "$T/gh/issues/$O0/body")"
rm -rf $K/d1; tw_close "$O0"
# the toy's two seam rows merged, the candidate at that merge
tk 3 step S03 SEAM-001,SEAM-002 'SEAM-001=seam SEAM-002=seam'; mg 21 3; for r in SEAM-001 SEAM-002; do tw_hand "row $r owed"; done; sh "$GS" tw-sync > /dev/null 2>&1
X=$(git --git-dir="$T/code.git" rev-parse main); printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > $K/ask; echo "$X" > $K/commit
cs okay --stage 1; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); B=$T/gh/issues/$O/body
sed -n 4p "$B" | grep -qx 'outside-service rows: SEAM-001 SEAM-002' && sed -n 3p "$B" | grep -qx 'seed: synthetic' || fail "the okay's first lines: $(head -n 5 "$B")"
grep -q 'seam: <row> real' "$B" || fail 'the okay does not ask, for each row, whether its service is real'
# a passed D1 lacking a seam: line for a listed row: refused
dp "$O" 1 "$(printf 'staging: http://127.0.0.1:5001\ndiffers: none\nseed: synthetic\nseam: SEAM-002 real')"; fetch; cs decide --stage 1; ok '^d1-refused 1 1$'
grep -q 'no seam: line for the outside-service row SEAM-001' "$T/gh/issues/$O/comments/1" || fail "the refusal: $(cat "$T/gh/issues/$O/comments/1")"
# SEAM-002 off the okay's list (a plant); SEAM-001 real, SEAM-002 a stand-in
off() { sed 's/^rows\t.*/rows	SEAM-001/' $K/d1/ask > "$T/a" && cat "$T/a" > $K/d1/ask; grep -q "^rows${TAB}SEAM-001\$" $K/d1/ask || fail "the okay's record holds no rows line: $(cat $K/d1/ask)"; }
off; dp "$O" 2 "$(printf 'staging: http://127.0.0.1:5001\ndiffers: none\nseed: synthetic\nseam: SEAM-001 real\nseam: SEAM-002 stand-in — the mail goes to a test inbox')"; fetch; cs decide --stage 1; ok '^d1 1 passed$'
cs owed; ok '^cs 1$'; cs ask --cs 1; N=$(sed -n 's/^asked \([0-9]*\) cs stage-1$/\1/p' "$T/out"); CS1=$N
for r in SEAM-001 SEAM-002; do grep -q -- "^- chunk p1c1, alpha: .*$r" "$T/gh/issues/$N/body" || fail "CS leaves out $r"; done
run() { P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/cs/ask); do P="$P $r=pass"; done; rq p1c1-1 "$X" alpha $P; fetch; cs decide --stage 1; }
run; ok '^paid SEAM-001$'; no '^paid SEAM-002$'; ok '^stand-in 1 SEAM-002 — the mail goes to a test inbox$'; ok '^stage-cs 1 passed$'
grep -q '^row SEAM-001 paid ' .vid/tw/handed && ! grep -q '^row SEAM-002 paid ' .vid/tw/handed || fail "the paid lines: $(grep paid .vid/tw/handed)"
Q2=$(qn 'stand-in 1 SEAM-002 — the mail goes to a test inbox'); [ -n "$Q2" ] || fail "no stand-in Q line: $(grep '^- Q' .vid/RUN-STATE.md)"
grep "^- $Q2 " .vid/RUN-STATE.md | grep -q 'limit' && grep "^- $Q2 " .vid/RUN-STATE.md | grep -q 'again' || fail "the stand-in line's answers: $(grep "^- $Q2 " .vid/RUN-STATE.md)"
# the walk under way, with a finding (plants): it stays as it is
mkdir -p $K/w1/1; printf '1\tW1 finding: bug — the footer is cut\n' > $K/w1/findings; cp $K/w1/findings "$T/wf"; cs out; no '^out stage-1$'
# again: the owner's alone; reached through out; while the walk is out nothing moves and staging stays held (R4)
! sh "$QS" answer "$Q2" --by RM again 'switch it on' > "$T/out" 2>&1 || fail 'RM answered a stand-in line'
! sh "$QS" answer "$Q2" --by delegate again 'switch it on' > "$T/out" 2>&1 || fail 'a delegate answered a stand-in line'
sh "$QS" answer "$Q2" again 'the mail service is on now' > "$T/out" 2>&1 || fail "again was refused: $(cat "$T/out")"
cs out; ok '^out stage-1$'
cs decide --stage 1; no '^staging-again'; [ -d $K/d1 ] && [ -d $K/cs ] || fail 'd1 and cs moved while the walk is out'; cs owed; no '^okay staging 1'
[ "$(cat "$T/gh/issues/$CS1/state")" = OPEN ] || fail "the CS issue closed while the walk is out"
# the walk ends: d1 and cs moved aside, the old CS issue closed, the walk untouched; a new okay and a new CS at the same candidate
# its issue's close failing once (a fake gh that fails one close): nothing moves, and the next round tries again
mv "$T/bin/gh" "$T/bin/gh-fake"; printf '#!/bin/sh\nif [ "$1 $2" = "issue close" ] && [ -f "%s/closefail" ]; then rm -f "%s/closefail"; exit 1; fi\nexec "$(dirname "$0")/gh-fake" "$@"\n' "$T" "$T" > "$T/bin/gh"; chmod +x "$T/bin/gh"; : > "$T/closefail"
: > $K/w1/done; cs decide --stage 1; no '^staging-again 1$'; ok '^staging-again-waits 1: '; [ -d $K/cs ] && [ ! -f $K/cs/issue-closed ] && [ -f $K/cs/stand-in-again ] && [ "$(cat "$T/gh/issues/$CS1/state")" = OPEN ] || fail "a failed close moved cs or recorded its issue closed: $(ls $K $K/cs)"
[ ! -f "$T/closefail" ] || fail 'the fake gh was never asked to close'
cs decide --stage 1; ok '^staging-again 1$'; [ "$(cat "$T/gh/issues/$CS1/state")" = CLOSED ] || fail 'the moved CS issue stayed open'; [ -d $K/d1-1 ] && [ -d $K/cs-1 ] && [ ! -d $K/d1 ] && [ ! -d $K/cs ] || fail "d1 and cs not moved aside: $(ls $K)"
[ -f $K/w1/done ] && cmp -s $K/w1/findings "$T/wf" || fail 'the walk or its findings moved'
cs owed; ok '^okay staging 1$'; no '^walk'; cs okay --stage 1; O2=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); grep -qx "commit: $X" "$T/gh/issues/$O2/body" || fail 'the okay again is not at the same commit'
off; dp "$O2" 1 "$(printf 'staging: http://127.0.0.1:5001\ndiffers: none\nseed: synthetic\nseam: SEAM-001 real')"; fetch; cs decide --stage 1; ok '^d1 1 passed$'
cs owed; ok '^cs 1$'; cs ask --cs 1; [ "$RC" = 0 ] || fail "CS was refused for the earlier ask: $(cat "$T/out")"; N=$(sed -n 's/^asked \([0-9]*\) cs stage-1$/\1/p' "$T/out"); [ -n "$N" ] && [ "$N" != "$CS1" ] || fail 'no new CS issue'
run; ok '^stand-in 1 SEAM-002 — not answered$'; ok '^stage-cs 1 passed$'
[ "$(cat "$T/gh/issues/$N/state")" = CLOSED ] && [ -f $K/cs/issue-closed ] || fail "the new CS issue did not close, the walk being over"
# limit: the owner's alone; it pays SEAM-002 as a known limit
Q3=$(qn 'stand-in 1 SEAM-002 — not answered'); [ -n "$Q3" ] || fail "no not-answered Q line: $(grep '^- Q' .vid/RUN-STATE.md)"
! sh "$QS" answer "$Q3" --by RM limit 'fine' > "$T/out" 2>&1 || fail 'RM answered a stand-in line'
sh "$QS" answer "$Q3" limit 'the mail service has no test account' > "$T/out" 2>&1 || fail "limit was refused: $(cat "$T/out")"
grep -q '^row SEAM-002 paid | stand-in: .*the mail service has no test account' .vid/tw/handed || fail "limit did not pay SEAM-002: $(grep SEAM-002 .vid/tw/handed)"
sh "$QS" sync > /dev/null 2>&1; ! grep -q "^- $Q3 " .vid/RUN-STATE.md || fail 'the answered stand-in line stays'
cs owed; no '^walk'; no '^okay staging 1'
exit 0
