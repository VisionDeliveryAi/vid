#!/bin/sh
# Purpose: selftest case — no screens, no walk (0.26.10.28.6, R1 (a), R-8). On the writer's toy and the fake gh, with no design
# screens, ROW-003's state cell n/a and ROW-005 a behaviour row, so stage 1 holds no screen and no journey. Red-first: once CS has
# passed, no walk is owed; W1 is recorded none, "no walk: this stage has no screens and no journey", once; the CS issue kept open
# for the walk closes; stage 2's candidate gets its staging okay; no brief is written and no walker started; the status line says
# none and why; W1's close condition is met; the summary's facts carry the words, a summary without them is refused, one with them
# closes the stage. Its set-up is stage-walk.sh's, lines 13-52, with no screens and the two rows changed. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-walk-none: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; WS=$CHECKS/walk.sh; RS=$CHECKS/results.sh; R=owner/code; mkdir -p "$T/r" "$T/wk"; COV=''
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; wk() { RC=0; sh "$WS" "$@" > "$T/out" 2>&1 || RC=$?; }
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'   # v0.26.10.26.5 (R5a): stages close in order
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
DU=$(for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done)   # 0.26.11.1.1 (R3): a passed D1's duties, each done
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf '%s\ndecisions: none' "$3")"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"; [ -z "${4:-}" ] || { rr_put "$Q" staging.txt "$(printf '%s\nseed: synthetic\nseam: SEAM-001 real' "$4")"; rr_put "$Q" duties.txt "$DU"; }; send "$Q"; }   # 0.26.11.1.1 (R3, R4, R6): its seed, seam and duty lines
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(echo "$5" | tr ' ' '\n' | sed -n "s/^$r=//p" | tr '+' ' ' | grep . || echo none)"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
qn() { sh "$QS" sync > /dev/null 2>&1; sed -n "s/^- \(Q[0-9]*\) · .*$1.*/\1/p" .vid/RUN-STATE.md | head -n 1; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 skeleton S01 ROW-003,ROW-004 ''; mg 20 2; tk 3 step S02 ROW-001 ''; mg 21 3; tk 4 step S03 ROW-006,SEAM-001,RULE-001 'SEAM-001=seam RULE-001=rule'; mg 22 4; tk 5 step S04 ROW-002 ''; mg 23 5
for r in ROW-003 ROW-004 ROW-001 ROW-006 ROW-002 RULE-001; do tw_hand "row $r accepted"; done; tw_hand 'row SEAM-001 owed'; tw_hand 'closed S01'
sed 's/^\(ROW-003 | [^|]*| [^|]*| [^|]*| \)S01\/saved |/\1n\/a |/; s/^ROW-005 | journey | ingest |/ROW-005 | behavior | REQ-001 |/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
grep -q '^ROW-003 | surface | S01 | anonymous | n/a |' INVENTORY.md && grep -q '^ROW-005 | behavior |' INVENTORY.md || fail 'the inventory was not changed'
sh "$GS" tw-sync > /dev/null 2>&1; [ ! -d design/screens ] || fail 'the toy has screens'
# R4: a row landed before the first candidate: the okay waits for S1 read and its findings ruled
printf 'ROW-006 abcdef123456 2026-11-09T00:00:00Z\n' > .vid/decide/landed
X=$(git --git-dir="$T/code.git" rev-parse main); fetch; cs ask --stage 1; ok '^candidate 1 1$'; N=$(sed -n 's/^asked \([0-9]*\) close stage-1$/\1/p' "$T/out"); K=.vid/decide/stage/1/1
P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/ask); do P="$P $r=pass"; done; rq p1c1-1 "$X" alpha $P; rq p1cx-1 "$X" alpha test_other=pass; fetch
cs decide --stage 1; ok '^stage-c3 1 passed$'; cs owed; no '^okay staging'   # S1 not read yet
G=$(sed -n 's/^issue\t//p' $K/s1ask); Q1=$(sed -n 's/^reqs\t//p' $K/s1ask | cut -d' ' -f1)
{ echo 'by: GR'; echo "commit: $X"; for q in $(sed -n 's/^reqs\t//p' $K/s1ask); do if [ "$q" = "$Q1" ]; then echo "$q partial — the digest omits the address"; else echo "$q pass — read"; fi; done; echo 'finding: rule — every page drops the support address in its footer'; } > "$T/g"
rm -rf "$T/r/grade-$G-1"; mkdir -p "$T/r/grade-$G-1"; cp "$T/g" "$T/r/grade-$G-1/grade.txt"; send "grade-$G-1"; fetch; cs decide --stage 1; ok '^s1 1 read$'; cs owed; no '^okay staging'   # its findings unruled
QA=$(qn "$Q1 partial"); QB=$(qn 'every page drops the support address'); [ -n "$QA" ] && [ -n "$QB" ] || fail "S1's findings reached no Q line: $(grep '^- Q' .vid/RUN-STATE.md)"
sh "$QS" answer "$QA" no 'as built is fine' > "$T/out" 2>&1 || fail 'no was refused'; cs owed; no '^okay staging'
sh "$QS" answer "$QB" row 'make it a rule' > "$T/out" 2>&1 || fail 'row was refused'; ok "^door: /vid fix — a new rule row, its places counted in covers: for stage 1's finding: finding: rule — every page drops"
cs owed; ok '^okay staging 1$'
# D1 and CS green: walk 1 owed
cs okay --stage 1; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
dp "$O" 1 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$X")" "$(printf 'staging: http://127.0.0.1:5001\nsignin: subscriber http://127.0.0.1:5001/signin\ndiffers: none')"; fetch; cs decide --stage 1; ok '^d1 1 passed$'
cs owed; ok '^cs 1$'; no '^walk'; cs ask --cs 1; N=$(sed -n 's/^asked \([0-9]*\) cs stage-1$/\1/p' "$T/out"); P=''; for r in $(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/cs/ask); do P="$P $r=pass"; done
rq p1c1-1 "$X" alpha $P; fetch; cs decide --stage 1; ok '^stage-cs 1 passed$'; CSI=$N
[ "$(cat "$T/gh/issues/$CSI/state")" = OPEN ] || fail "CS's issue closed at its decide, before W1's outcome"
# a fake walker that only says it ran; stage 2's candidate, C3 passed, waits on stage 1's staging
printf '#!/bin/sh\n: > "%s"\n' "$T/ran" > "$T/walker"; chmod +x "$T/walker"; VID_WALKER=$T/walker; export VID_WALKER; VID_WALK_TMP=$T/wk; export VID_WALK_TMP
mkdir -p .vid/decide/stage/2/1; cp $K/ask $K/commit .vid/decide/stage/2/1/; : > .vid/decide/stage/2/1/named; : > .vid/decide/stage/2/1/passed
# red-first: no screens and no journey row: no walk owed, W1 recorded none, CS's issue closed, staging free for stage 2
cs owed; no '^walk'; ok '^okay staging 2$'
[ "$(cat $K/w1/none 2>/dev/null)" = 'no walk: this stage has no screens and no journey' ] || fail "W1's none: $(cat $K/w1/none 2>/dev/null)"
[ "$(cat "$T/gh/issues/$CSI/state")" = CLOSED ] || fail "CS's issue, kept open for a walk not owed, did not close"
[ "$(grep -c '^walk-none stage=1 candidate=1 at=' .vid/metrics-events)" = 1 ] || fail "walk-none events: $(grep -c '^walk-none' .vid/metrics-events)"
cs owed; no '^walk'; [ "$(grep -c '^walk-none stage=1 ' .vid/metrics-events)" = 1 ] || fail 'a second owed recorded none again'   # once
# no walker is started, and none can be
wk brief --stage 1; [ "$RC" != 0 ] || fail 'a brief was written for a walk not owed'; wk start --stage 1; [ "$RC" != 0 ] || fail 'a walker was started for a walk not owed'
[ ! -f "$T/ran" ] || fail 'a walker ran'; [ -z "$(ls $K/w1 | grep -E '^[0-9]+$')" ] || fail "W1 holds a start: $(ls $K/w1)"
wk fin 1; [ "$RC" = 0 ] || fail 'walk.sh fin does not read none as an outcome'
sh "$QS" status > "$T/out" 2>&1; ok ' · W1 none — no walk: this stage has no screens and no journey · '
sh "$CS" conds 1 > "$T/out" 2>&1 || true; no '^4 '   # W1 met
# the close: the summary says why there was no walk; one without the words is refused
cc() { sh "$CS" conds 1 > "$T/out" 2>&1 || true; }
cc; for r in $(sed -n 's/^1 \([^ ]*\) .*/\1/p' "$T/out"); do tw_hand "row $r accepted"; done; cc; for r in $(sed -n 's/^1 \([^ ]*\) .*not paid.*/\1/p' "$T/out"); do tw_hand "row $r paid"; done
KB=$(awk -F'\t' -v q="$QB" '$2 == q { print $1 }' .vid/decide/queue/ids); mkdir -p .vid/decide/drafts/9; echo "$KB" > .vid/decide/drafts/9/for; : > .vid/decide/drafts/9/declined
for q in $(sed -n 's/^- \(Q[0-9]*\) · .*unmatched.*/\1/p' .vid/RUN-STATE.md); do sh "$QS" answer "$q" no 'a harness case' > /dev/null 2>&1 || true; done
cc; [ ! -s "$T/out" ] || fail "conditions left: $(cat "$T/out")"; cs owed; ok '^close-stage 1$'
WORDS='no walk: this stage has no screens and no journey'
cs summary --stage 1; grep -qxF "walk	$WORDS" $K/facts.txt || fail "the facts do not carry why there was no walk: $(grep '^walk' $K/facts.txt)"
W1N=$(awk -F'\t' '$1 == "working" { print $3; exit }' $K/facts.txt); DI=$(awk -F'\t' '$1 == "decided" { print $2 }' $K/facts.txt | paste -sd ',' -)
printf '**Working now:** %s · **Went back:** nothing · **Decided for you:** %s\n' "$W1N" "${DI:-nothing}" > $K/summary.md; cs close-stage --stage 1; ok "^summary-refused 1 the summary does not say the walk's outcome: $WORDS"
printf '**Working now:** %s · **Went back:** nothing · **Decided for you:** %s · %s\n' "$W1N" "${DI:-nothing}" "$WORDS" > $K/summary.md; cs close-stage --stage 1; ok '^stage-closed 1 at [0-9a-f]*$'
[ ! -f "$T/ran" ] || fail 'a walker ran by the close'
exit 0
