#!/bin/sh
# Purpose: selftest case — the walk and the stage's findings (v0.26.10.26.4 R1–R6), checks/walk.sh, close.sh and queue.sh on the
# writer's toy and the fake gh, stage 1. After a landing, the okay waits for S1 read and its findings ruled (R4). Once CS has passed,
# `walk 1` is owed; staging is held for a later stage's okay until W1 is done. The brief, in a folder outside the project: the
# candidate, staging's address and sign-ins, the golden path, the screens with their canvases, the wander, and nothing of
# fail-ifs, results, grades or tickets. The walker is a fake command here (VID_WALKER). The read: a missing line refused, and
# walked again; `browser: none` not done, an item answered again; a second refusal an item; done, with a differs screen and a
# finding to W1's findings. The findings as items: `row` a door line naming a rule row, `no`, `known`, `later 2` asked again at
# stage 2's candidate, `later 5` refused. A newer candidate withdraws an older W1 not done. An accepted rule row among a later
# ticket's regression rows, `covers: 0` failing it there and no `covers:` line evidence missing (R5). The status line. v0.26.10.26.5:
# the close's six conditions, each unmet then all met; the hold mid-stage, at the close, and continue's count; the summary refused three
# ways, then the close's records and `stage: 2`; corrected since the close. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "stage-walk: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; WS=$CHECKS/walk.sh; RS=$CHECKS/results.sh; R=owner/code; mkdir -p "$T/r" "$T/wk"; COV=''
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; wk() { RC=0; sh "$WS" "$@" > "$T/out" 2>&1 || RC=$?; }
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'   # v0.26.10.26.5 (R5a): stages close in order
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
dp() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$3"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"; [ -z "${4:-}" ] || rr_put "$Q" staging.txt "$4"; send "$Q"; }
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
# staging held: stage 2's candidate, C3 passed, waits for stage 1's W1
mkdir -p .vid/decide/stage/2/1; cp $K/ask $K/commit .vid/decide/stage/2/1/; : > .vid/decide/stage/2/1/named; : > .vid/decide/stage/2/1/passed; cs owed; no '^okay staging'
# the brief, outside the project, and nothing of fail-ifs, results or history
mkdir -p .vid/tmp; VID_WALK_TMP=$PWD/.vid/tmp wk brief --stage 1; [ "$RC" != 0 ] && grep -q 'inside the project' "$T/out" || fail 'a brief inside the project was written'
VID_WALK_TMP=$T/wk; export VID_WALK_TMP; wk brief --stage 1; [ "$RC" = 0 ] || fail "the brief failed ($RC)"; B=$(tail -n 1 "$T/out"); case $B in "$(cd "$T/wk" && pwd -P)"/*) ;; *) fail "the brief's folder: $B" ;; esac
grep -qx "candidate: $X" "$B/brief.md" && grep -qx 'staging: http://127.0.0.1:5001' "$B/brief.md" && grep -qx 'signin: subscriber http://127.0.0.1:5001/signin' "$B/brief.md" || fail "the brief's head: $(head -n 5 "$B/brief.md")"
grep -q '^- ROW-003: The S01/saved state' "$B/brief.md" && grep -q '^- ROW-004: The new subscriber' "$B/brief.md" || fail 'the golden path is not in the brief'
grep -qx -- '- screen S01/saved: the canvas S01 Subscribe.dc.html' "$B/brief.md" && [ -f "$B/S01 Subscribe.dc.html" ] || fail 'the screen and its canvas are not in the brief'
grep -q '^## The wander' "$B/brief.md" || fail 'no wander'; [ "$(ls "$B" | sort | tr '\n' ' ')" = 'S01 Subscribe.dc.html brief.md ' ] || fail "the folder holds: $(ls "$B")"
! grep -Eiq 'fail-if|what the promise says|passed|failing|grade|finding|#[0-9]|issue|ticket|checks/|\.vid' "$B/brief.md" || fail "the brief holds: $(grep -Ein 'fail-if|what the promise says|passed|failing|grade|finding|#[0-9]|issue|ticket|checks/|\.vid' "$B/brief.md")"
cs owed; ok '^walk 1$'   # briefed, never started: due again, so a restart loses nothing
sh "$QS" status > "$T/out" 2>&1; ok ' · W1 due · '
# the walker: a fake command that writes the walk.txt the case hands it
printf '#!/bin/sh\nprintf "%%s\\n" "$PWD" "$@" > "$WALK_ARGS"\n[ ! -f "$WALK_SRC" ] || cp "$WALK_SRC" walk.txt\nsleep 1\n' > "$T/walker"; WALK_ARGS=$T/args; export WALK_ARGS; chmod +x "$T/walker"; VID_WALKER=$T/walker; export VID_WALKER
w() { NB=$K/w1/$(ls $K/w1 | grep -E '^[0-9]+$' | sort -n | tail -n 1)/brief.md; printf 'by: WA\ncandidate: %s\nbrowser: %s\ngolden path: %s\nscreen S01/saved: %s\nwander: %s\n' "$X" "$1" "$2" "$3" "$4" > "$T/walk.txt"
  awk '/^## The rows/ { on = 1; next } /^## / { on = 0 } on && /^- / { x = substr($0, 3); sub(/:.*/, "", x); print x }' "$NB" | while read -r r; do echo "$r: $2" >> "$T/walk.txt"; done; [ -z "${5:-}" ] || printf '%s\n' "$5" >> "$T/walk.txt"; WALK_SRC=$T/walk.txt; export WALK_SRC; }
waitw() { n=0; while [ "$n" -lt 20 ]; do wk pending; grep -q "^walk-read $1$" "$T/out" && return 0; sleep 1; n=$((n + 1)); done; fail 'the walker never ended'; }
# a missing line: refused, and due once more
w 'chrome' done matches 'differs — the button is gone'; wk start --stage 1; ok '^started [0-9]*$'; cs owed; no '^walk'; cs out; ok '^out stage-1$'; waitw 1
grep -qx "$B" "$T/args" && grep -qx 'claude-opus-5-5' "$T/args" && grep -q "^You are ViD's walker" "$T/args" && grep -qx 'Write' "$T/args" || fail "the walker's start: $(head -c 400 "$T/args")"
! grep -qx 'Edit' "$T/args" || fail 'the walker may edit'   # its folder, its model, its role, Bash Read Write alone
wk read --stage 1; ok '^w1 refused wander reads neither done nor not done$'; grep -q '^- ROW-005: ' "$B/brief.md" || fail 'a stage 1 screen row is not in the brief'; cs owed; ok '^walk 1$'; [ -f "$K/w1/1/walk.txt" ] || fail 'walk.txt not copied back'
# browser: none: not done, an item answered again; a promise in fail-if form kept from the walker
sed 's/^\(ROW-003 | [^|]*| [^|]*| [^|]*| [^|]*| \)[^|]*|/\1never: the saved search is shown without its address |/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
wk brief --stage 1 > /dev/null; grep -q '^- ROW-003: (walk it as a user would' $K/w1/2/brief.md && ! grep -q 'never:' $K/w1/2/brief.md || fail "a fail-if form reached the brief: $(grep '^- ROW-003' $K/w1/2/brief.md)"; git checkout -q -- INVENTORY.md
cp .vid/RUN-STATE.md "$T/rs0"; sed 's/^\(step S01 .*\)rows: ROW-003 ROW-004 /\1rows: ROW-003..ROW-004 /' "$T/rs0" > .vid/RUN-STATE.md; grep -q 'rows: ROW-003..ROW-004 ' .vid/RUN-STATE.md || fail 'no range planted'
wk brief --stage 1 > /dev/null; grep -q '^- ROW-004: The new subscriber' $K/w1/3/brief.md || fail "a golden range lost its rows: $(sed -n '/golden path/,/^## The [rs]/p' $K/w1/3/brief.md)"; cp "$T/rs0" .vid/RUN-STATE.md   # the plan's range expanded
rm -rf $K/w1/3; w "$(printf '\tnone')" ' not done — no browser' 'not done — no browser' 'not done — no browser'; wk start --stage 1; waitw 1; wk read --stage 1; ok '^w1 not-done browser: none$'; cs owed; no '^walk'; no '^okay staging'
QW=$(qn 'the walk W1 of stage-1: not done — browser: none'); [ -n "$QW" ] || fail "not done reached no Q line: $(grep '^- Q' .vid/RUN-STATE.md)"; sh "$QS" answer "$QW" again 'a browser is here now' > "$T/out" 2>&1 || fail 'again was refused'; cs owed; ok '^walk 1$'
sh "$QS" status > "$T/out" 2>&1; ok ' · W1 due · '
# no walk.txt at all: the first refusal since the owner's again, due once more; an empty browser: line the second, the owner's
wk brief --stage 1 > /dev/null; WALK_SRC=$T/no-walk-at-all; wk start --stage 1; waitw 1; wk read --stage 1; ok '^w1 refused no walk.txt$'; cs owed; ok '^walk 1$'
wk brief --stage 1 > /dev/null; w '' done matches done; wk start --stage 1; waitw 1; wk read --stage 1; ok '^w1 refused no browser: line'; cs owed; no '^walk'
sh "$QS" status > "$T/out" 2>&1; ok ' · W1 refused · '
QR=$(qn 'its return refused twice'); [ -n "$QR" ] || fail 'the second refusal reached no Q line'; sh "$QS" answer "$QR" again 'once more' > "$T/out" 2>&1 || fail 'again was refused'; cs owed; ok '^walk 1$'
# done: a differs screen and a finding to W1's findings; staging free for stage 2
wk brief --stage 1 > /dev/null; w 'chrome --headless' done 'differs — the address line is missing' done 'finding: bug — saving twice makes two searches'; wk start --stage 1; waitw 1; wk read --stage 1; ok '^w1 done$'; ok "^cs-closed #$CSI\$"; [ "$(cat "$T/gh/issues/$CSI/state")" = CLOSED ] || fail "CS's issue open after W1 done"
grep -qx '5	W1 screen S01/saved: differs — the address line is missing' $K/w1/findings && grep -qx '5	W1 finding: bug — saving twice makes two searches' $K/w1/findings || fail "W1's findings: $(cat $K/w1/findings)"
: > .vid/decide/stage/2/1/s1ask   # stage 2's S1 asked, unread: a landing of stage 1's rows does not hold stage 2's okay (R4)
cs owed; no '^walk'; ok '^okay staging 2$'
# W1's findings as items: known; later 5 refused; later 2 asked again at stage 2's candidate
QD=$(qn 'the address line is missing'); QF=$(qn 'saving twice makes two searches'); [ -n "$QD" ] && [ -n "$QF" ] || fail "W1's findings reached no Q line"
sh "$QS" recommend "$QD" known 'seen before' > /dev/null 2>&1 || fail 'recommend was refused for a stage finding'; sh "$QS" sync > /dev/null 2>&1; grep -q "^- $QD · .*recommended: known — seen before" .vid/RUN-STATE.md || fail 'the recommendation is not shown'
sh "$QS" answer "$QD" known 'we know' > "$T/out" 2>&1 || fail 'known was refused'; ! sh "$QS" answer "$QF" later 5 'much later' > "$T/out" 2>&1 || fail 'later 5 was taken'
sh "$QS" answer "$QF" later 2 'next stage' > "$T/out" 2>&1 || fail 'later 2 was refused'; Q2=$(qn "stage 2's finding (moved from stage 1"); [ -n "$Q2" ] || fail 'the moved finding is not asked at stage 2'
QU=$(qn 'unmatched test_other passed'); [ -n "$QU" ] || fail 'the unmatched case reached no Q line'; sh "$QS" answer "$QU" no 'a harness case' > "$T/out" 2>&1 || fail 'no was refused'
sh "$QS" status > "$T/out" 2>&1; ok '^stage 1: candidate 1 at [0-9a-f]* · C3 green · .* · D1 passed · CS green · paid [0-9]* of [0-9]* · W1 done · findings 5 of 5 ruled · the close waits on [0-9, ]* · test site: http://127.0.0.1:5001, taken down after its run$'   # v0.26.10.28.8 (R7): the walk ended, CS's issue closed
# a newer candidate withdraws an older W1 not done: stage 2's candidate 1, its walk out
mkdir -p .vid/decide/stage/2/1/cs .vid/decide/stage/2/1/w1/1; : > .vid/decide/stage/2/1/cs/passed; CS2=$(gh issue create -R $R --title cs2 --body b --label run | sed 's/.*\///'); printf 'issue\t%s\n' "$CS2" > .vid/decide/stage/2/1/cs/ask; echo "$T/wk" > .vid/decide/stage/2/1/w1/1/folder
printf '1\tW1 finding: bug — the home page errors before any sign-in\n' > .vid/decide/stage/2/1/w1/findings   # read before the withdrawal
mkdir -p .vid/decide/stage/2/2; cp $K/ask .vid/decide/stage/2/2/; wk withdraw --stage 2 --below 2; ok '^walk-withdrawn 2 1$'; [ -f .vid/decide/stage/2/1/w1/withdrawn ] || fail 'no withdrawn'; ok "^cs-closed #$CS2\$"; [ "$(cat "$T/gh/issues/$CS2/state")" = CLOSED ] || fail "the old green CS's issue open after its walk's withdrawal"
[ -n "$(qn 'the home page errors before any sign-in')" ] || fail 'a withdrawn walk lost a finding already read'
grep -q 'sh "$HERE/walk.sh" withdraw --stage "$N" --below "$c"' "$CS" || fail 'naming a candidate does not withdraw the older W1'
# R5: an accepted rule row among a later ticket's regression rows; covers 0 fails it, none is evidence missing
rm -rf design; printf 'step-start step=S05 at=2026-11-09T09:00:00Z\n' >> .vid/metrics-events; sh "$GS" spec-export > /dev/null 2>&1; F=$(sh "$CHECKS/writer.sh" write step S05 2> "$T/out") || fail 'S05 was refused'
awk '/^## Regression rows/ { on = 1; next } /^## / { on = 0 } on' "$F" | grep -qx -- '- RULE-001' || fail "RULE-001 is no regression row of S05: $(awk '/^## Regression rows/,0' "$F" | head -n 12)"
I=$(( $(ls "$T/gh/issues" | sort -n | tail -n 1) + 1 )); gh issue create -R $R --title "t$I" --body b --label ticket > /dev/null; cp "$F" ".vid/tw/out/issue-$I.md"
printf 'published %s kind=step step=S05 rows=ROW-017 at=2026-11-09T12:00:00Z\n' "$I" >> .vid/tw/log
( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m head && git push -q origin HEAD:refs/heads/s05 ); H=$(git --git-dir="$T/code.git" rev-parse s05); H12=$(printf %.12s "$H")
hr() { Q=pr-90-$H12-$1; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nenvironments: 1%s' "$H" "${2:+
$2}")"; rr_put "$Q" cases-alpha.xml "$(rr_cases test_ROW_017_a=pass test_RULE_001_every_footer=pass)"; send "$Q"; }
hr 1 'covers: RULE-001 0'; fetch; sh "$RS" read --ticket "$I" --pr 90 --head "$H" > "$T/out" 2>&1 || true; grep -q "^RULE-001	.*covers 0" "$T/out" || fail "covers 0 did not fail RULE-001: $(grep RULE-001 "$T/out")"
hr 2 ''; fetch; sh "$RS" read --ticket "$I" --pr 90 --head "$H" > "$T/out" 2>&1 || true; grep -q "^RULE-001	.*no covers: line" "$T/out" || fail "no covers: line is not evidence missing: $(grep RULE-001 "$T/out")"
# --- v0.26.10.26.5 (R1–R6): the close of stage 1, its six conditions one at a time, the summary's three refusals, the hold ---
git checkout -q -- INVENTORY.md 2>/dev/null || true; rm -f .vid/tw/out/step-S05.md
cc() { sh "$CS" conds 1 > "$T/out" 2>&1 || true; }
cc; ok '^1 '; ok '^5 a finding without the owner'"'"'s ruling: '   # rows not yet decided; QB's row with no draft landed or declined
for r in $(sed -n 's/^1 \([^ ]*\) .*/\1/p' "$T/out"); do tw_hand "row $r accepted"; done; cc; ok '^1 [A-Z0-9-]* accepted, not paid at staging$'   # a staging-owed row accepted is not paid
for r in $(sed -n 's/^1 \([^ ]*\) .*not paid.*/\1/p' "$T/out"); do tw_hand "row $r paid"; done; cc; no '^1 '
KB=$(awk -F'\t' -v q="$QB" '$2 == q { print $1 }' .vid/decide/queue/ids); mkdir -p .vid/decide/drafts/9; echo "$KB" > .vid/decide/drafts/9/for; : > .vid/decide/drafts/9/declined; cc; no '^5 '
mv $K/w1/done $K/w1/done.x; cc; ok '^4 W1 not done$'; mv $K/w1/done.x $K/w1/done
mv $K/cs/passed $K/cs/passed.x; cc; ok '^2 CS not passed$'; mv $K/cs/passed.x $K/cs/passed
cp .vid/decide/stage/1/s1 "$T/s1"; printf '%s\tpass\t9\n' "$Q1" >> .vid/decide/stage/1/s1; cc; ok "^3 $Q1 graded before a merge that touched it\$"; cp "$T/s1" .vid/decide/stage/1/s1
mkdir -p .vid/decide/drafts/8; : > .vid/decide/drafts/8/asked; printf 'added\tROW-099\trow\n' > .vid/decide/drafts/8/sets; printf 'step S02 | name: x | rows: ROW-001 ROW-099 | lane: devagent\n' > .vid/decide/drafts/8/plan
cc; ok '^6 an item for the owner: draft:8'; : > .vid/decide/drafts/8/declined   # a waiting draft that adds a row to the stage's step
C3I=$(sed -n 's/^issue\t//p' $K/ask | head -n 1); printf '%s:9\t%s\tQuestion: which default?\tasked\n' "$C3I" "$C3I" >> .vid/decide/queue/questions; cc; ok "^6 an item for the owner: question:$C3I:9"   # a question on the candidate's own C3
grep -v "^$C3I:9	" .vid/decide/queue/questions > "$T/qq" || true; cat "$T/qq" > .vid/decide/queue/questions
echo 'lost d1 #9' >> $K/d1/items; cc; ok '^6 an item for the owner: close:stage-1/1/d1:lost:d1'; grep -v '^lost d1 #9$' $K/d1/items > "$T/i" || true; cat "$T/i" > $K/d1/items
cc; [ ! -s "$T/out" ] || fail "conditions left: $(cat "$T/out")"; cs owed; ok '^close-stage 1$'
# the hold, mid-stage: stage 2 admitted no further
mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/; tw_hand 'closed S02'; sed 's/^stage: 0$/stage: 1/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md; sh "$QS" control hold 'hold after this stage — the owner' > "$T/out" 2>&1 || fail 'the hold was refused'; ok '^held after stage 1$'; grep -qx 'held-after: 1' .vid/RUN-STATE.md || fail 'no held-after line'
grep -q '^stage-hold n=1 state=asked' .vid/metrics-events || fail 'no stage-hold asked'; grep -v 'step=S05' .vid/metrics-events > "$T/m"; cat "$T/m" > .vid/metrics-events; ! sh "$CHECKS/plan.sh" start S05 > "$T/out" 2>&1 || fail 'S05 was admitted under the hold'
sh "$QS" status > "$T/out" 2>&1; ok '^stage 1: .* · held after 1 · test site: http://127.0.0.1:5001, taken down after its run$'   # v0.26.10.28.8 (R7)
# the summary: facts, then refused three ways, then the close
mkdir -p .vid/decide/close/S02/1 .vid/decide/close/S02/2; printf 'ROW-001\tgreen\n' > .vid/decide/close/S02/1/result; printf 'ROW-001\tred\n' > .vid/decide/close/S02/2/result   # a regression at S02's second close
printf '2026-11-10T00:00:01Z\tquestion:9:1\t-\tthe default stands\tRM\tdelegated\n' >> .vid/decide/queue/answers
cs summary --stage 1; cs summary --stage 1; ok '^facts 1 '; grep -q '^went-back	ROW-001	' $K/facts.txt && grep -q '^decided	question:9:1	' $K/facts.txt && grep -q "^working	" $K/facts.txt || fail "the facts: $(cat $K/facts.txt)"   # computed twice: a regression is the candidate's until an earlier close named it
NM=$(awk -F'\t' '$1 == "went-back" && $2 == "ROW-001" { print $3 }' $K/facts.txt); DI=$(awk -F'\t' '$1 == "decided" && $2 ~ /^D-/ { print $2 }' $K/facts.txt | paste -sd ',' -); W1N=$(awk -F'\t' '$1 == "working" { print $3; exit }' $K/facts.txt)
cs close-stage --stage 1; ok '^summary-refused 1 no summary'
printf '**Working now:** %s · **Went back:** nothing · **Decided for you:** question:9:1, the default stood; %s\n' "$W1N" "$DI" > $K/summary.md; cs close-stage --stage 1; ok "^summary-refused 1 the summary's went back misses: "; [ ! -f $K/summary.md ] || fail 'the refused summary was left'
printf '**Working now:** %s · **Went back:** %s · **Decided for you:** the default stood; %s\n' "$W1N" "$NM" "$DI" > $K/summary.md; cs close-stage --stage 1; ok '^summary-refused 1 the summary misses the decision question:9:1'
printf '**Working now:** %s · **Went back:** %s · **Decided for you:** question:9:12, the default stood; %s\n' "$W1N" "$NM" "$DI" > $K/summary.md; cs close-stage --stage 1; ok '^summary-refused 1 the summary misses the decision question:9:1$'   # an id whole, not inside another
printf '**Working now:** %s · **Went back:** %s · **Decided for you:** question:9:1, the default stood; %s\n' "$W1N" "$NM" "$DI" > $K/summary.md; cs close-stage --stage 1; ok '^stage-closed 1 at [0-9a-f]*$'; ok '^held after stage 1: the run stops$'
grep -q "^stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1" .vid/tw/handed && grep -q "^stage-closed n=1 sha=$(printf %.12s "$X") ready rows=[0-9]* debt=[0-9]*" .vid/metrics-events || fail 'the close records'
grep -qx 'stage: 2' .vid/RUN-STATE.md && grep -qx 'run: stopped owner asked to hold after stage 1' .vid/RUN-STATE.md && grep -q '^stage-hold n=1 state=on' .vid/metrics-events || fail "stage: or run: $(grep -E '^(stage|run):' .vid/RUN-STATE.md)"
grep -q '^## The deploy debt' $K/report.md && grep -q '^## The findings and their rulings' $K/report.md || fail 'no report'; cs owed; no '^close-stage'
! sh "$CHECKS/plan.sh" start S05 > "$T/out" 2>&1 || fail 'S05 was admitted under the hold after the close'
sh "$QS" status > "$T/out" 2>&1; ok '^stage 1: .* · closed at [0-9a-f]* · held after 1 · test site: http://127.0.0.1:5001, taken down after its run$'   # v0.26.10.28.8 (R7)
# continue after the close: the hold ends, with its count
sh "$QS" control continue 'go on — the owner' > "$T/out" 2>&1; ok '^hold after stage 1: off · staging runs [0-9]* merges past'; ok '^run: active$'; ! grep -q '^held-after:' .vid/RUN-STATE.md || fail 'the hold stands'
grep -q '^stage-hold n=1 state=off' .vid/metrics-events || fail 'no stage-hold off'
# R4: stage 1's candidate named, stage 2 holding no step of the plan: plan-stage 2; nothing once it holds one
sh "$CS" nextplan > "$T/out" 2>&1; [ ! -s "$T/out" ] || fail "nextplan with S05 planned: $(cat "$T/out")"; cp .vid/RUN-STATE.md "$T/rs1"; sed '/^step S05 /d' "$T/rs1" > .vid/RUN-STATE.md
sh "$CS" nextplan > "$T/out" 2>&1; ok '^2$'; cp "$T/rs1" .vid/RUN-STATE.md; grep -q 'PS=$(plan_stage); \[ -z "$PS" \] || echo "plan-stage $PS"' "$CHECKS/round.sh" || fail 'the round prints no plan-stage'
# corrected since its close: a merge touching stage 1's rows after it
I7=$(( $(ls "$T/gh/issues" | sort -n | tail -n 1) + 1 )); tk "$I7" fix S02 ROW-001 ''; mg 40 "$I7"; sh "$QS" status > "$T/out" 2>&1; ok '^stage 1: .* · closed at [0-9a-f]* · corrected since its close at [0-9a-f]*'
exit 0
