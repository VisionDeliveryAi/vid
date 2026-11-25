#!/bin/sh
# Purpose: selftest case — screens, but no browser: the owner may close without the walk (0.26.10.28.6, R1 (b), R-8). On the writer's
# toy and the fake gh, stage 1 with its screen, CS green and W1 owed. Kept: a walk not done for an unreachable address offers and takes
# only `again`, which behaves as before. A walk read `browser: none` offers "close without the walk"; from RM or a stood-in source,
# or garbled, it is refused and records nothing. Red-first: the owner's answer records the known limit, "walk not done: no browser on
# this machine", with who and when; the CS issue kept open for the walk closes; no walk is owed; stage 2 gets its staging okay; the
# status line, the summary's facts and the completion report carry the words; a summary without them is refused, one with them
# closes the stage. Its set-up is stage-walk.sh's, lines 13-54, 56 and 68-71. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-walk-limit: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; WS=$CHECKS/walk.sh; RS=$CHECKS/results.sh; R=owner/code; mkdir -p "$T/r" "$T/wk"; COV=''
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; wk() { RC=0; sh "$WS" "$@" > "$T/out" 2>&1 || RC=$?; }
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
printf '#!/bin/sh\nprintf 200\n' > "$T/bin/curl"; chmod +x "$T/bin/curl"   # FB-7 C2: the staging's address answers
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
mkdir -p design/screens; echo '<html>the saved search canvas</html>' > 'design/screens/S01 Subscribe.dc.html'; sh "$GS" tw-sync > /dev/null 2>&1
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
rq p1c1-1 "$X" alpha $P; fetch; cs decide --stage 1; ok '^stage-cs 1 passed$'; cs owed; ok '^walk 1$'
CSI=$N; [ "$(cat "$T/gh/issues/$CSI/state")" = OPEN ] || fail "CS's issue closed at green, before the walk"; grep -q "Keep the staging up until this issue closes: ViD's walk of the staging, W1, comes after this run." "$T/gh/issues/$CSI/body" || fail "CS's body has no staging sentence"   # v0.26.10.27.3 (8.1b R4)
mkdir -p .vid/decide/stage/2/1; cp $K/ask $K/commit .vid/decide/stage/2/1/; : > .vid/decide/stage/2/1/named; : > .vid/decide/stage/2/1/passed; cs owed; no '^okay staging'
printf '#!/bin/sh\nprintf "%%s\\n" "$PWD" "$@" > "$WALK_ARGS"\n[ ! -f "$WALK_SRC" ] || cp "$WALK_SRC" walk.txt\nsleep 1\n' > "$T/walker"; WALK_ARGS=$T/args; export WALK_ARGS; chmod +x "$T/walker"; VID_WALKER=$T/walker; export VID_WALKER
w() { NB=$K/w1/$(ls $K/w1 | grep -E '^[0-9]+$' | sort -n | tail -n 1)/brief.md; printf 'by: WA\ncandidate: %s\nbrowser: %s\ngolden path: %s\nscreen S01/saved: %s\nwander: %s\n' "$X" "$1" "$2" "$3" "$4" > "$T/walk.txt"
  awk '/^## The rows/ { on = 1; next } /^## / { on = 0 } on && /^- / { x = substr($0, 3); sub(/:.*/, "", x); print x }' "$NB" | while read -r r; do echo "$r: $2" >> "$T/walk.txt"; done; [ -z "${5:-}" ] || printf '%s\n' "$5" >> "$T/walk.txt"; WALK_SRC=$T/walk.txt; export WALK_SRC; }
waitw() { n=0; while [ "$n" -lt 20 ]; do wk pending; grep -q "^walk-read $1$" "$T/out" && return 0; sleep 1; n=$((n + 1)); done; fail 'the walker never ended'; }
VID_WALK_TMP=$T/wk; export VID_WALK_TMP
# kept: a not-done for another reason (the address does not answer) has `again` alone: close without the walk is refused, for the owner too
wk brief --stage 1 > /dev/null; w chrome 'not done — the address does not answer' 'not done — the address does not answer' 'not done — the address does not answer'
wk start --stage 1; waitw 1; wk read --stage 1; ok '^w1 not-done the address does not answer$'
QU=$(qn 'the walk W1 of stage-1: not done — the address does not answer'); [ -n "$QU" ] || fail "the unreachable not-done reached no Q line: $(grep '^- Q' .vid/RUN-STATE.md)"
! grep -q "^- $QU · .*close without the walk" .vid/RUN-STATE.md || fail 'an unreachable not-done offers close without the walk'
RC=0; sh "$QS" answer "$QU" close without the walk > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail "close without the walk was taken after an unreachable address: $(cat "$T/out")"
[ ! -f $K/w1/limit ] || fail 'a limit was recorded after an unreachable address'
# kept: again behaves as today
sh "$QS" answer "$QU" again 'the address answers now' > "$T/out" 2>&1 || fail 'again was refused'; cs owed; ok '^walk 1$'
# browser: none — the item offers the owner's answer
wk brief --stage 1 > /dev/null; w "$(printf '\tnone')" ' not done — no browser' 'not done — no browser' 'not done — no browser'; wk start --stage 1; waitw 1; wk read --stage 1; ok '^w1 not-done browser: none$'
QW=$(qn 'the walk W1 of stage-1: not done — browser: none'); [ -n "$QW" ] || fail "browser: none reached no Q line: $(grep '^- Q' .vid/RUN-STATE.md)"
grep -q "^- $QW · .*or, yours alone, close without the walk" .vid/RUN-STATE.md || fail "the not-done item does not offer close without the walk: $(grep "^- $QW" .vid/RUN-STATE.md)"
# kept: a delegated or stood-in answer is refused, and records nothing
for by in RM stand-in; do RC=0; sh "$QS" answer "$QW" --by "$by" close without the walk > "$T/out" 2>&1 || RC=$?
  [ "$RC" != 0 ] && grep -q "the owner's answer alone, never $by's" "$T/out" || fail "close without the walk was taken from $by: $(cat "$T/out")"; [ ! -f $K/w1/limit ] || fail "a limit was recorded from $by"; done
RC=0; sh "$QS" answer "$QW" close the walk > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a garbled close answer was taken'
cs owed; no '^okay staging'   # staging still held for stage 2
# red-first: the owner's close without the walk — the limit recorded in its words, with who and when
sh "$QS" answer "$QW" close without the walk > "$T/out" 2>&1 || fail "the owner's close without the walk was refused: $(cat "$T/out")"
[ "$(sed -n 1p $K/w1/limit)" = 'walk not done: no browser on this machine' ] && sed -n 2p $K/w1/limit | grep -qE '^the owner, [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$' || fail "the limit's record: $(cat $K/w1/limit 2>/dev/null)"
grep -q '^walk-limit stage=1 candidate=1 by=owner at=' .vid/metrics-events || fail "the walk-limit event: $(grep '^walk-limit' .vid/metrics-events)"
WHEN=$(sed -n 2p $K/w1/limit); WORDS="walk not done: no browser on this machine ($WHEN)"
cp $K/w1/limit "$T/l0"; RC=0; sh "$QS" answer "$QW" close without the walk > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q 'has ended already (limit)' "$T/out" && cmp -s $K/w1/limit "$T/l0" || fail "a second close without the walk was taken: $(cat "$T/out")"   # one outcome
[ "$(cat "$T/gh/issues/$CSI/state")" = CLOSED ] || fail "CS's issue, kept open for the walk, did not close"
cs owed; no '^walk'; ok '^okay staging 2$'   # the next stage gets its staging okay
sh "$QS" status > "$T/out" 2>&1; grep -qF " · W1 $WORDS · " "$T/out" || fail "the status line does not show the limit: $(grep '^stage 1:' "$T/out")"
sh "$CS" conds 1 > "$T/out" 2>&1 || true; no '^4 '   # W1 met
# the summary carries the limit's words; one without them is refused
cc() { sh "$CS" conds 1 > "$T/out" 2>&1 || true; }
cc; for r in $(sed -n 's/^1 \([^ ]*\) .*/\1/p' "$T/out"); do tw_hand "row $r accepted"; done; cc; for r in $(sed -n 's/^1 \([^ ]*\) .*not paid.*/\1/p' "$T/out"); do tw_hand "row $r paid"; done
KB=$(awk -F'\t' -v q="$QB" '$2 == q { print $1 }' .vid/decide/queue/ids); mkdir -p .vid/decide/drafts/9; echo "$KB" > .vid/decide/drafts/9/for; : > .vid/decide/drafts/9/declined
for q in $(sed -n 's/^- \(Q[0-9]*\) · .*unmatched.*/\1/p' .vid/RUN-STATE.md); do sh "$QS" answer "$q" no 'a harness case' > /dev/null 2>&1 || true; done
cc; [ ! -s "$T/out" ] || fail "conditions left: $(cat "$T/out")"; cs owed; ok '^close-stage 1$'
cs summary --stage 1; grep -qxF "walk	$WORDS" $K/facts.txt || fail "the facts do not carry the walk's words: $(grep '^walk' $K/facts.txt)"
W1N=$(awk -F'\t' '$1 == "working" { print $3; exit }' $K/facts.txt); DI=$(awk -F'\t' '$1 == "decided" { print $2 }' $K/facts.txt | paste -sd ',' -)
printf '**Working now:** %s · **Went back:** nothing · **Decided for you:** %s\n' "$W1N" "${DI:-nothing}" > $K/summary.md; cs close-stage --stage 1; ok "^summary-refused 1 the summary does not say the walk's outcome: $WORDS"
printf '**Working now:** %s · **Went back:** nothing · **Decided for you:** %s · %s\n' "$W1N" "${DI:-nothing}" "$WORDS" > $K/summary.md; cs close-stage --stage 1; ok '^stage-closed 1 at [0-9a-f]*$'
# the completion report shows it, in the same words
sh "$CHECKS/end.sh" complete > /dev/null 2>&1 || true; grep -qF -- "- stage 1, candidate 1: $WORDS" .vid/decide/completion.md || fail "the completion report does not show the limit: $(grep -n 'walk' .vid/decide/completion.md)"
exit 0
