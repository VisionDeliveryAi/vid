#!/bin/sh
# Purpose: selftest case — a re-cut of a stage with a candidate not yet deployed (0.26.10.29.2, R2), checks/land.sh with checks/close.sh
# on the writer's toy and the fake gh. The toy's cut gives stage 2 the support address too (REQ-012, its rows in a step S06 of stage 2);
# stages 0 and 1 closed; S05's and S06's tickets merged, their rows accepted. Stage 2's candidate 1 has its C3 and its S1 out, so no
# candidate is due; a re-cut that changes stage 2 (REQ-003 split to a new stage 3) lands: the candidate, its C3 and its S1 are
# withdrawn, their issues commented and closed, the close no longer out, and a candidate of stage 2 is due again and named, candidate 2.
# Its C3 passed and its D1 okay out, and a candidate 3 named since with its C3 out, a second re-cut changing stage 2 (stage 3 taken
# back) withdraws both candidates, candidate 2's okay and candidate 3's C3; the D1
# report that passes afterwards writes no passed D1 at the withdrawn candidate, so stage 2 is not deployed and a third re-cut is
# drafted. FB-1 C3: the first re-cut's close of the C3 ask fails once (a gh before the fake's), its comment posted: the landing
# prints `ask-open stage-2 <i>`, records `issue <i>` for the S1 ask it closed, and the next `close.sh owed` closes the C3 ask with no
# second comment and comments the closed S1 ask no more. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "recut-candidate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"
# FB-1 C3: `issue close <n>` fails once while $T/failclose names n; every other call is the fake's
mkdir -p "$T/bin0"; printf '#!/bin/sh\nif [ "$1 $2" = "issue close" ] && [ -f %s ] && [ "$3" = "$(cat %s)" ]; then rm -f %s; echo "gh: the close failed" >&2; exit 1; fi\nexec %s "$@"\n' "'$T/failclose'" "'$T/failclose'" "'$T/failclose'" "'$T/bin/gh'" > "$T/bin0/gh"; chmod +x "$T/bin0/gh"; PATH="$T/bin0:$PATH"; export PATH
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "split: REQ-012 -> STAGE-2" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; g add STAGES.md && g commit -qm 'the cut: the support address in stage 2'
awk '/^step S03 / || /^needs ROW-006 / { gsub(/ ROW-006| ROW-019/, "") } { print }
  /^step S05 / { print "step S06 | name: the support address | modules: web mail | builds-on: S01 | rows: ROW-006 ROW-019 | lane: devagent" } /^needs ROW-017 / { print "needs ROW-006 ROW-019 | -" }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
pt_record; tw_ratify 'Yes, publish it' || fail 'the toy with the support address in stage 2 was not ratified'
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; S=.vid/decide/stage; mkdir -p "$T/r" .vid/round .vid/decide .vid/tw/out; printf 'none\n' > "$T/rv"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
iss() { gh issue create -R $R --title "$1" --body b --label "$2" | sed 's/.*\///'; }; st() { cat "$T/gh/issues/$1/state" 2>/dev/null; }
# tk <n> <step> <rows,>: a step ticket published by hand; mg <pr> <n>: merged at a new main commit
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: step\n\n## Rows\n\n' "$1"; for r in $(echo "$3" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done; printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"
  gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null; printf 'published %s kind=step step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
tk 2 S05 ROW-017; mg 20 2; tk 3 S06 ROW-006,ROW-019; mg 21 3; for r in ROW-017 ROW-006 ROW-019; do tw_hand "row $r accepted"; done; sh "$GS" tw-sync > /dev/null 2>&1; X=$MC
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
mkdir -p "$S/1/1/d1"; printf 'issue\t90\ncommit\t%s\nasked\t2026-11-14T10:00:00Z\n' "$X" > "$S/1/1/ask"; : > "$S/1/1/named"; : > "$S/1/1/passed"; : > "$S/1/1/d1/passed"
tw_hand "candidate 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"; tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
# stage 2's candidate 1: its C3 and its S1 out
I1=$(iss 'Close run: stage 2, candidate 1' run); I2=$(iss 'Stage grade: stage 2, candidate 1' grade); mkdir -p "$S/2/1"
printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-15T09:00:00Z\nchunk\tp1c1\tchromium\tROW-017 ROW-006 ROW-019\n' "$I1" "$X" > "$S/2/1/ask"; : > "$S/2/1/named"; printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-15T09:00:00Z\nreqs\tREQ-003 REQ-012\n' "$I2" "$X" > "$S/2/1/s1ask"
tw_hand "candidate 2 | stand-in: RM at $(printf %.12s "$X") candidate 1"; fetch; cs owed; no '^stage 2$'; cs out; ok '^out stage-2$'
recut() { { cat PRD.md; printf '\n### 2026-11-15 (the self-test)\n\n```vid-prd-answers\nA-%s | human | 2026-11-15 | Q: how should the product be delivered — in which stages? | A: %s | settles: contract\n```\n' "$1" "$2"; } > "$T/p" && cp "$T/p" PRD.md
  RC=0; sh "$CHECKS/land.sh" draft --review "$T/rv" --why "/vid stage: $2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the re-cut was not drafted ($RC)"; n=$(sed -n 's/^draft \([0-9]*\)$/\1/p' "$T/out"); [ "${3:-}" = draft ] && return 0
  RC=0; sh "$CHECKS/land.sh" "$n" --words "Yes, $2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the re-cut did not land ($RC)"; }
three() { awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "STAGE-3 | Synonyms, later | features: -"; print "split: REQ-003 -> STAGE-3" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; }
echo "$I1" > "$T/failclose"; three; recut 311 'the synonyms wait for a stage 3'
[ -f "$S/2/1/withdrawn" ] || fail "the re-cut left stage 2's candidate standing"; [ -f "$S/2/1/s1withdrawn" ] || fail "the re-cut left the candidate's S1 standing"
grep -qx "ask-open stage-2 $I1" "$T/out" || fail "the landing does not name the C3 ask #$I1 whose close failed"; [ "$(st "$I1")" != CLOSED ] || fail "the C3 ask #$I1 closed though its close failed"
grep -qx "issue $I2" "$S/2/1/withdrawn" || fail "the landing did not record the S1 ask #$I2 it closed"
ncm() { ls "$T/gh/issues/$1/comments" 2>/dev/null | grep -c . || true; }
fetch; cs owed
for i in $I1 $I2; do [ "$(st "$i")" = CLOSED ] && grep -rq '^vid: withdrawn' "$T/gh/issues/$i/comments" 2>/dev/null || fail "ask #$i was not withdrawn on GitHub"; [ "$(ncm "$i")" = 1 ] || fail "ask #$i holds $(ncm "$i") comments, not one"; done
grep -qx "issue $I1" "$S/2/1/withdrawn" || fail "close.sh owed did not record the C3 ask #$I1 it closed"
cs out; no '^out stage-2$'; cs owed; ok '^stage 2$'
fetch; cs ask --stage 2; [ "$RC" = 0 ] || fail "stage 2's candidate was not named again ($RC)"; ok '^candidate 2 2$'
# candidate 2: C3 passed, its D1 okay out; a second re-cut takes stage 3 back
: > "$S/2/2/passed"; : > "$S/2/2/done"; I4=$(iss 'Deploy to staging: stage 2, candidate 2' deploy); mkdir -p "$S/2/2/d1"; printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-15T10:00:00Z\n' "$I4" "$X" > "$S/2/2/d1/ask"
# and a newer candidate 3 named since, its C3 out: the re-cut withdraws both, the older one's D1 okay with it
I5=$(iss 'Close run: stage 2, candidate 3' run); mkdir -p "$S/2/3"; printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-15T11:00:00Z\nchunk\tp1c1\tchromium\tROW-006\n' "$I5" "$X" > "$S/2/3/ask"; : > "$S/2/3/named"
grep -v -e '^STAGE-3 ' -e '^split: REQ-003 ' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; recut 312 'no stage 3 after all'
[ -f "$S/2/3/withdrawn" ] || fail "the second re-cut left candidate 3, the newest, standing"; [ "$(st "$I5")" = CLOSED ] || fail "candidate 3's C3 #$I5 was not withdrawn on GitHub"
[ -f "$S/2/2/withdrawn" ] || fail "the second re-cut left candidate 2, an older one, standing"; grep -q '^withdrawn' "$S/2/2/d1/closed" 2>/dev/null || fail "the second re-cut left the older candidate's D1 okay standing"
[ "$(st "$I4")" = CLOSED ] && grep -rq '^vid: withdrawn' "$T/gh/issues/$I4/comments" 2>/dev/null || fail "the D1 okay #$I4 was not withdrawn on GitHub"
# the deploy passes after all: no passed D1 at the withdrawn candidate, so stage 2 is not deployed and may be re-cut again
Q=deploy-$I4-1; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$X")"; rr_put "$Q" deploy.xml "$(rr_cases build=pass)"; rr_put "$Q" staging.txt "$(printf 'staging: http://127.0.0.1:5001\ndiffers: none')"; send "$Q"; fetch
cs decide --stage 2; [ ! -f "$S/2/2/d1/passed" ] || fail 'a D1 passed at a withdrawn candidate was read as passed'; no '^d1 2 passed$'
three; recut 313 'the synonyms wait for a stage 3 again' draft
exit 0
