#!/bin/sh
# Purpose: selftest case — the end grade (v0.26.10.27.4, stage 8.3, R1), checks/close.sh on the writer's toy (stages 0 to 2, stage 2
# final; stage 1 closed, S05 merged) and the fake gh. At the final stage's first candidate, S1 asks every live requirement of every
# stage, not only stage 2's; a `later` requirement is listed deferred, never asked; its body carries the end grade's words. A
# non-final stage's ask (the toy whole, stage 1 of three) has neither. After an add landed since the previous candidate, the set gains
# the add's requirements and those of the rows of every step sharing a module with the add's steps (close.sh's addset). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "end-grade: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
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
for r in ROW-001 ROW-012 ROW-003 ROW-006 ROW-002 ROW-005; do tw_hand "row $r accepted"; done; tw_hand 'row DIF-001 owed'; tw_hand 'row ROW-013 known-limit'; sh "$GS" tw-sync > /dev/null 2>&1
tk 6 step S05 ROW-017 ''; mg 25 6; tw_hand 'row ROW-017 accepted'; tw_hand 'stage-closed 1 | stand-in: RM at 000000000000 candidate 1'; sh "$GS" tw-sync > /dev/null 2>&1
awk '/^REQ-011 \|/ { sub(/phase: pilot/, "phase: later") } { print }' PRD.md > "$T/p" && cp "$T/p" PRD.md; grep -q '^REQ-011 .*phase: later' PRD.md || fail 'REQ-011 not made later'
X=$(git --git-dir="$T/code.git" rev-parse main); fetch; cs ask --stage 2; [ "$RC" = 0 ] || fail "the ask failed ($RC)"; G=$(sed -n 's/^asked \([0-9]*\) grade stage-2$/\1/p' "$T/out"); K=.vid/decide/stage/2/1; N=$(sed -n 's/^asked \([0-9]*\) close stage-2$/\1/p' "$T/out")
LIVE=$(sh "$CHECKS/prd.sh" --effective 2>/dev/null | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); l = 0; for (i = 3; i <= NF; i++) if ($i ~ /phase:[ \t]*later/) l = 1 } k ~ /^REQ-[0-9]/ && !l { print k }' | sort -u | paste -sd ' ' -)
ST1=$(sh "$CHECKS/stages.sh" scope --upto 2 --reqs | grep '^REQ-' | sort -u | grep -vxF -f "$(sh "$CHECKS/stages.sh" scope --upto 1 --reqs | grep '^REQ-' | sort -u > "$T/s0"; echo "$T/s0")" | paste -sd ' ' -)
[ "$(sed -n 's/^reqs\t//p' $K/s1ask)" = "$LIVE" ] || fail "the end grade's requirements: $(sed -n 's/^reqs\t//p' $K/s1ask), not every live one: $LIVE"
[ "$LIVE" != "$ST1" ] || fail 'the toy gives no requirement outside stage 2 itself: nothing is shown'
B=$T/gh/issues/$G/body; grep -qx 'This is the end grade: grade the joins across stages, every journey whole, and each line of the grading checklist.' "$B" || fail 'no end-grade words'
grep '^Deferred, not asked: ' "$B" | grep -q ' REQ-011\( \|$\)' && ! printf ' %s ' "$LIVE" | grep -q ' REQ-011 ' || fail "the later requirement: $(grep Deferred "$B")"
# the add's set, after an add landed since candidate 1's ask: its row's requirements, and the rows of the steps sharing its module
# a later final candidate: S1 read whole, C3 green; an add lands after the first ask, then a fix merges
sg() { Q=grade-$G-$1; shift; rm -rf "$T/r/$Q"; rr_put "$Q" grade.txt "$(printf '%s\n' "$@")"; send "$Q"; }
sg 1 'by: GR' "commit: $X" $(for q in $LIVE; do printf '%s~pass~—~read\n' "$q"; done); sed -i.b 's/~/ /g' "$T/r/grade-$G-1/grade.txt"; send "grade-$G-1"
for c in p1c1 p2c1; do e=alpha; [ $c = p1c1 ] || e=beta; rq "$c-1" "$X" "$e" $(awk -F'\t' -v c=$c '$1 == "chunk" && $2 == c { n = split($4, a, " "); for (i = 1; i <= n; i++) print a[i] "=pass" }' $K/ask); done; rq p1cx-1 "$X" alpha test_other=pass; fetch; cs decide --stage 2; ok '^stage-c3 2 passed$'; ok '^s1 2 read$'
mkdir -p .vid/decide/drafts/1; echo '/vid add: the footer names the support address' > .vid/decide/drafts/1/why; echo abcdef012345 > .vid/decide/drafts/1/landed
printf 'added\tROW-019\trow\n' > .vid/decide/drafts/1/sets; echo 'ROW-019 S03' > .vid/decide/drafts/1/steps; printf 'ROW-019 abcdef012345 2099-01-01T00:00:00Z\n' >> .vid/decide/landed
tk 7 fix S05 ROW-017 ''; mg 26 7; fetch; cs owed; ok '^stage 2$'; cs ask --stage 2; ok '^candidate 2 2$'; A2=$(sed -n 's/^reqs\t//p' .vid/decide/stage/2/2/s1ask)
[ "$(sed -n 's/^commit\t//p' .vid/decide/stage/2/2/s1ask)" = "$(cat .vid/decide/stage/2/2/commit)" ] || fail "candidate 2's end grade is asked at $(sed -n 's/^commit\t//p' .vid/decide/stage/2/2/s1ask), not its commit"
rq1() { sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' -v r="$1" '{ a = $1; gsub(/[ \t]/, "", a) } a == r { n = split($7, t, /[ ,]+/); for (i = 1; i <= n; i++) if (t[i] ~ /^REQ-/) print t[i] }'; }
for q in $(rq1 ROW-019; rq1 ROW-003); do printf ' %s ' "$A2" | grep -q " $q " || ! printf ' %s ' "$LIVE" | grep -q " $q " || fail "candidate 2's end grade lacks $q, of the add's set: $A2"; done
grep -qx 'This is the end grade: grade the joins across stages, every journey whole, and each line of the grading checklist.' "$T/gh/issues/$(sed -n 's/^issue\t//p' .vid/decide/stage/2/2/s1ask)/body" || fail "candidate 2's ask lacks the end grade's words"
# a non-final stage: the toy whole (three stages), stage 1's own requirements and no end-grade words
cd /; T=$T/t2; mkdir -p "$T/r"; tw_toy "$T/toy"; mkdir -p .vid/round .vid/decide .vid/tw/out; printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings; tw_hand 'engines alpha beta'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
sh "$GS" spec-setup > /dev/null 2>&1; gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1; tk 2 step S02 ROW-001,ROW-012 ROW-003; mg 20 2; tk 3 step S03 ROW-006 ''; mg 21 3; tk 4 step S04 ROW-002,DIF-001,ROW-013 ''; mg 22 4
for r in ROW-001 ROW-012 ROW-003 ROW-006 ROW-002; do tw_hand "row $r accepted"; done; tw_hand 'row DIF-001 owed'; tw_hand 'row ROW-013 known-limit'; sh "$GS" tw-sync > /dev/null 2>&1; fetch; cs ask --stage 1
G3=$(sed -n 's/^asked \([0-9]*\) grade stage-1$/\1/p' "$T/out"); [ -n "$G3" ] || fail 'no S1 at a non-final stage'; S1O=$(sh "$CHECKS/stages.sh" scope --upto 1 --reqs | grep '^REQ-' | sort -u | grep -vxF -f "$(sh "$CHECKS/stages.sh" scope --upto 0 --reqs | grep '^REQ-' | sort -u > "$T/s00"; echo "$T/s00")" | paste -sd ' ' -)
[ "$(sed -n 's/^reqs\t//p' .vid/decide/stage/1/1/s1ask)" = "$S1O" ] || fail "a non-final stage's S1: $(sed -n 's/^reqs\t//p' .vid/decide/stage/1/1/s1ask), not $S1O"
! grep -q 'This is the end grade' "$T/gh/issues/$G3/body" || fail 'a non-final stage carries the end grade words'
echo 'end-grade: ok'
