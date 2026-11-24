#!/bin/sh
# Purpose: selftest case — the end grade is asked until one is graded (0.26.11.1.2, R10, E-1), checks/close.sh and land.sh on the
# writer's toy and the fake gh (end-grade.sh's records), cut into stages 0 to 3, stage 3 holding nothing yet. Stage 2's candidate 1 asks
# stage 2's own requirements, its s1ask with no `end yes`. A re-cut that drops stage 3 makes stage 2 final and changes none of its members:
# its open candidate is withdrawn, and the next, candidate 2, asks every live requirement, its s1ask carrying `end yes`. Once that end grade is
# done, candidate 3 asks the touched requirements alone, no `end yes`. Stage 3 cut again and stage 2's candidate 3 deployed (its D1 passed), a
# re-cut that makes stage 2 final once more lands, and the deployed candidate stands. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "end-grade-recut: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; TAB=$(printf '\t'); S=.vid/decide/stage; mkdir -p "$T/r"; printf 'none\n' > "$T/rv"
four() { awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "STAGE-3 | Later work | features: FEAT-04" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; }
awk '{ print } /^FEAT-03 \|/ { print "FEAT-04 | G1 | later work" }' PRD.md > "$T/p" && cp "$T/p" PRD.md   # FB-3 C2: a feature with nothing in it yet, so stage 3 holds no row and the stage court takes it
four; g add PRD.md STAGES.md && g commit -qm 'the cut: a stage 3, empty for now'; pt_record; tw_ratify 'Yes, publish it' || fail 'the toy with stage 3 was not ratified'
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings; tw_hand 'engines alpha beta'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; E=$3; shift 3; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" "cases-$E.xml" "$(rr_cases "$@")"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n' "$1" "$2"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
recut() { { cat PRD.md; printf '\n### 2026-11-15 (the self-test)\n\n```vid-prd-answers\nA-%s | human | 2026-11-15 | Q: how should the product be delivered — in which stages? | A: %s | settles: contract\n```\n' "$1" "$2"; } > "$T/p" && cp "$T/p" PRD.md
  RC=0; sh "$CHECKS/land.sh" draft --review "$T/rv" --why "/vid stage: $2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the re-cut was not drafted ($RC)"; n=$(sed -n 's/^draft \([0-9]*\)$/\1/p' "$T/out")
  RC=0; sh "$CHECKS/land.sh" "$n" --words "Yes, $2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the re-cut did not land ($RC)"; }
reqs() { sed -n "s/^reqs$TAB//p" "$S/2/$1/s1ask"; }
# done_ <c>: stage 2's candidate c graded, each requirement it asked passing, and its C3 green, both read
done_() { K=$S/2/$1; G=$(sed -n "s/^issue$TAB//p" $K/s1ask); N=$(sed -n "s/^issue$TAB//p" $K/ask); XC=$(cat $K/commit)
  Q=grade-$G-1; rm -rf "$T/r/$Q"; rr_put "$Q" grade.txt "$(printf 'by: GR\ncommit: %s\n' "$XC"; for q in $(reqs "$1"); do printf '%s pass — read\n' "$q"; done)"; send "$Q"
  for c in p1c1 p2c1; do e=alpha; [ $c = p1c1 ] || e=beta; rq "$c-1" "$XC" "$e" $(awk -F'\t' -v c=$c '$1 == "chunk" && $2 == c { n = split($4, a, " "); for (i = 1; i <= n; i++) print a[i] "=pass" }' $K/ask); done; rq p1cx-1 "$XC" alpha test_other=pass
  fetch; cs decide --stage 2; ok '^s1 2 read$'; [ -f $K/s1done ] || fail "candidate $1's grade is not done"; }
gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
tk 2 step S02 ROW-001,ROW-012 ROW-003; mg 20 2; tk 3 step S03 ROW-006 ''; mg 21 3; tk 4 step S04 ROW-002,DIF-001,ROW-013 ''; mg 22 4; tk 5 fix S02 ROW-005 ''; mg 23 5
for r in ROW-001 ROW-012 ROW-003 ROW-006 ROW-002 ROW-005; do tw_hand "row $r accepted"; done; tw_hand 'row DIF-001 owed'; tw_hand 'row ROW-013 known-limit'; sh "$GS" tw-sync > /dev/null 2>&1
tk 6 step S05 ROW-017 ''; mg 25 6; tw_hand 'row ROW-017 accepted'; tw_hand 'stage-closed 1 | stand-in: RM at 000000000000 candidate 1'; sh "$GS" tw-sync > /dev/null 2>&1
LIVE=$(sh "$CHECKS/prd.sh" --effective 2>/dev/null | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); l = 0; for (i = 3; i <= NF; i++) if ($i ~ /phase:[ \t]*later/) l = 1 } k ~ /^REQ-[0-9]/ && !l { print k }' | sort -u | paste -sd ' ' -)
# stage 2, not final: its own requirements, no end yes
X=$(git --git-dir="$T/code.git" rev-parse main); fetch; cs ask --stage 2; [ "$RC" = 0 ] || fail "stage 2's ask failed ($RC)"; ok '^candidate 2 1$'
[ -n "$(reqs 1)" ] && [ "$(reqs 1)" != "$LIVE" ] || fail "stage 2's first candidate, not final, asks $(reqs 1)"; ! grep -qx "end${TAB}yes" "$S/2/1/s1ask" || fail 'a non-final ask carries end yes'
done_ 1   # its stage grade done: stage 2's own requirements graded once
# the re-cut drops stage 3: stage 2 final, its members unchanged; its open candidate withdrawn
grep -v '^STAGE-3 ' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; recut 311 'stage 3 is not needed'
[ -f "$S/2/1/withdrawn" ] || fail 'a re-cut that made stage 2 final left its open candidate standing'
[ -f "$S/2/1/withdrawn" ] || : > "$S/2/1/withdrawn"   # (the red run goes on)
# candidate 2: the end grade, every live requirement, end yes
fetch; cs owed; ok '^stage 2$'; cs ask --stage 2; ok '^candidate 2 2$'
[ "$(reqs 2)" = "$LIVE" ] || fail "the first candidate since stage 2 became final asks $(reqs 2), not every live requirement: $LIVE"
grep -qx "end${TAB}yes" "$S/2/2/s1ask" || fail "the full end-grade ask's s1ask lacks end yes"
# its end grade done; a fix merges; candidate 3 asks the touched alone
done_ 2
tk 7 fix S05 ROW-017 ''; mg 26 7; fetch; cs owed; ok '^stage 2$'; cs ask --stage 2; ok '^candidate 2 3$'
[ -n "$(reqs 3)" ] && [ "$(reqs 3)" != "$LIVE" ] && ! grep -qx "end${TAB}yes" "$S/2/3/s1ask" || fail "after the end grade was done, candidate 3 asks the full set again: $(reqs 3)"
# stage 3 cut again; candidate 3 deployed; a re-cut makes stage 2 final again: the deployed candidate stands
four; recut 312 'a stage 3 after all'; [ ! -f "$S/2/3/withdrawn" ] || fail 'a re-cut that left stage 2 not final withdrew its candidate'
mkdir -p "$S/2/3/d1"; : > "$S/2/3/d1/passed"
grep -v '^STAGE-3 ' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; recut 313 'no stage 3 again'
[ ! -f "$S/2/3/withdrawn" ] || fail 'a re-cut that made a deployed stage final withdrew its candidate'
exit 0
