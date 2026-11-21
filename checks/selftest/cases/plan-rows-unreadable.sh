#!/bin/sh
# Purpose: selftest case — an unreadable plan stops its readers, never reads as empty (0.26.11.1.2, R6, S2-b2). A copy of checks/
# whose planner.sh fails `rows` while $T/plfail exists, and whose stages.sh fails a `scope` read whose working folder and words match the
# pattern in $T/stfail; every other call goes to the real script. The admission (plan.sh start, the tickets branch) refuses with either
# read failing, naming the command, recorded `refused phase=admission by=stage`, and admits once both read again. On a re-cut toy (stage 2's
# candidate out): close.sh owed, its stage conditions and the end's conditions refuse with the rows failing; the stage conditions refuse
# with the stage's requirements unreadable, never passing "every requirement graded"; end.sh complete, queue.sh status and planner.sh rows
# (its own scope read) refuse too. A re-cut whose draft cut cannot be read is refused, naming the read, and withdraws no candidate. On the
# develop toy (fixtures/stages.sh): metrics.sh stage-close --record with the report's read failing refuses and writes no tag, no event and
# no report; a stage-0 close, whose report asks no read below stage 0, still closes (the control). The text check: no read of either
# command under checks/ turns its failure into an empty list. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "plan-rows-unreadable: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the copy, its two failing doors
C2=$T/checks; mkdir -p "$C2"; for f in "$CHECKS"/*; do [ "${f##*/}" = selftest ] || cp -R "$f" "$C2/"; done
mv "$C2/planner.sh" "$C2/planner.real.sh"; mv "$C2/stages.sh" "$C2/stages.real.sh"
printf '#!/bin/sh\n[ "${1:-}" != rows ] || [ ! -f %s ] || { echo "ViD planner: the model cannot be read (a planted failure)" >&2; exit 2; }\n[ "${1:-}" != rows ] || [ ! -f %s ] || exec cat %s\nexec sh "$(dirname "$0")/planner.real.sh" "$@"\n' "$T/plfail" "$T/plcache" "$T/plcache" > "$C2/planner.sh"
printf '#!/bin/sh\nif [ -f %s ]; then case "$(pwd -P) $*" in $(cat %s)) echo "ViD stages: the cut cannot be read (a planted failure)" >&2; exit 2 ;; esac; fi\nexec sh "$(dirname "$0")/stages.real.sh" "$@"\n' "$T/stfail" "$T/stfail" > "$C2/stages.sh"
rd() { RC=0; "$@" > "$T/out" 2>&1 || RC=$?; }
refused() { [ "$RC" = 1 ] || fail "$1 was not refused, exit 1 (exit $RC)"; grep -qF "$2" "$T/out" || fail "$1's refusal does not say: $2"; }
PLR="refused — the plan's rows cannot be read (checks/planner.sh rows): ViD planner: the model cannot be read (a planted failure)"
SCR="refused — the stage scope cannot be read (checks/stages.sh scope --upto"

# 1. the admission, on the planner toy at stage 0 with its candidate
tw_toy "$T/a"; mkdir -p checks; cp "$C2/stages.sh" "$C2/stages.real.sh" "$CHECKS/prd.sh" checks/; tw_hand 'candidate 0'; tw_hand 'staged 0'
: > "$T/plfail"; rd sh "$C2/plan.sh" start S01; refused 'S01, the rows unreadable' "ViD plan: $PLR"
tail -n 1 .vid/metrics-events | grep -q '^refused phase=admission by=stage .* step=S01 ' || fail 'the refusal with the rows unreadable is not recorded by=stage'
rm -f "$T/plfail"; echo '* scope --upto*' > "$T/stfail"; rd sh "$C2/plan.sh" start S01; refused 'S01, the scope unreadable' "ViD plan: $SCR 1): ViD stages:"
tail -n 1 .vid/metrics-events | grep -q '^refused phase=admission by=stage .* step=S01 ' || fail 'the refusal with the scope unreadable is not recorded by=stage'
rm -f "$T/stfail"; rd sh "$C2/plan.sh" start S01; [ "$RC" = 0 ] && grep -q '^step-start step=S01 ' .vid/metrics-events || fail 'S01 was refused with both reads working'

# 2. the re-cut toy (recut-candidate.sh's): stages 0 and 1 closed, stage 2's candidate 1 with its C3 and S1 out
cd "$T"; rm -rf "$T/gh" "$T/code.git" "$T/dev"; tw_toy "$T/b"
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "split: REQ-012 -> STAGE-2" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; g add STAGES.md && g commit -qm 'the cut: the support address in stage 2'
awk '/^step S03 / || /^needs ROW-006 / { gsub(/ ROW-006| ROW-019/, "") } { print }
  /^step S05 / { print "step S06 | name: the support address | modules: web mail | builds-on: S01 | rows: ROW-006 ROW-019 | lane: devagent" } /^needs ROW-017 / { print "needs ROW-006 ROW-019 | -" }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
pt_record; tw_ratify 'Yes, publish it' || fail 'the toy was not ratified'
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
R=owner/code; S=.vid/decide/stage; mkdir -p .vid/round .vid/decide .vid/tw/out; printf 'none\n' > "$T/rv"
iss() { gh issue create -R $R --title "$1" --body b --label "$2" | sed 's/.*\///'; }
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: step\n\n## Rows\n\n' "$1"; for r in $(echo "$3" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n' "$r" "$r"; done; printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"
  gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null; printf 'published %s kind=step step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$1" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$MC" "$MC" >> .vid/decide/merges; tw_close "$2"; }
tk 2 S05 ROW-017; mg 20 2; tk 3 S06 ROW-006,ROW-019; mg 21 3; for r in ROW-017 ROW-006 ROW-019; do tw_hand "row $r accepted"; done; sh "$C2/github.sh" tw-sync > /dev/null 2>&1; X=$MC
printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
mkdir -p "$S/1/1/d1"; printf 'issue\t90\ncommit\t%s\nasked\t2026-11-14T10:00:00Z\n' "$X" > "$S/1/1/ask"; : > "$S/1/1/named"; : > "$S/1/1/passed"; : > "$S/1/1/d1/passed"
tw_hand "candidate 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"; tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
I1=$(iss 'Close run: stage 2, candidate 1' run); I2=$(iss 'Stage grade: stage 2, candidate 1' grade); mkdir -p "$S/2/1"
printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-15T09:00:00Z\nchunk\tp1c1\tchromium\tROW-017 ROW-006 ROW-019\n' "$I1" "$X" > "$S/2/1/ask"; : > "$S/2/1/named"; printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-15T09:00:00Z\nreqs\tREQ-003 REQ-012\n' "$I2" "$X" > "$S/2/1/s1ask"
tw_hand "candidate 2 | stand-in: RM at $(printf %.12s "$X") candidate 1"
# the controls: both reads working
rd sh "$C2/close.sh" owed; [ "$RC" = 0 ] || fail "close.sh owed failed with both reads working ($RC)"
rd sh "$C2/close.sh" conds 2; [ "$RC" = 0 ] && grep -q '^3 REQ-[0-9]* not graded' "$T/out" || fail "stage 2's conditions name no ungraded requirement with both reads working"
# the rows unreadable: the close, the stage conditions, the end's conditions, the completion report, the status
: > "$T/plfail"
rd sh "$C2/close.sh" owed; refused 'close.sh owed' "ViD close: $PLR"
rd sh "$C2/close.sh" conds 2; refused "close.sh's stage conditions" "ViD close: $PLR"
rd sh "$C2/close.sh" endconds; refused "close.sh's end conditions" "ViD close: $PLR"
rd sh "$C2/end.sh" complete; refused 'end.sh complete' "ViD end: $PLR"; [ ! -f .vid/decide/completion.md ] || fail 'end.sh wrote a completion report with the rows unreadable'
rd sh "$C2/queue.sh" status; refused 'queue.sh status' "ViD queue: $PLR"
rm -f "$T/plfail"
# the stage's requirements unreadable: never "every requirement graded"; planner.sh's own scope read
sh "$C2/planner.sh" rows > "$T/plc" && mv "$T/plc" "$T/plcache"   # the rows as they read now, so the stage's requirements alone are unreadable
echo '* scope --upto 2 --reqs' > "$T/stfail"; rd sh "$C2/close.sh" conds 2; refused "close.sh's stage conditions, the requirements unreadable" "ViD close: $SCR 2 --reqs): ViD stages:"
! grep -q '^3 ' "$T/out" || fail 'the stage conditions read the requirements as graded'
rm -f "$T/plcache"; echo '* scope --upto*' > "$T/stfail"; rd sh "$C2/planner.sh" rows; refused 'planner.sh rows, its scope unreadable' "$SCR 0 --reqs): ViD stages:"   # the copy's planner, planner.real.sh, names itself so
# a re-cut whose draft cut cannot be read: refused, naming the read, no candidate withdrawn
{ cat PRD.md; printf '\n### 2026-11-15 (the self-test)\n\n```vid-prd-answers\nA-311 | human | 2026-11-15 | Q: how should the product be delivered — in which stages? | A: the synonyms wait for a stage 3 | settles: contract\n```\n'; } > "$T/p" && cp "$T/p" PRD.md
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "STAGE-3 | Synonyms, later | features: -"; print "split: REQ-003 -> STAGE-3" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md
echo '*/cb scope*' > "$T/stfail"; rd sh "$C2/land.sh" draft --review "$T/rv" --why '/vid stage: the synonyms wait for a stage 3'
[ "$RC" != 0 ] || fail 'a re-cut whose draft cut cannot be read was drafted'; grep -qF 'the stage scope cannot be read (checks/stages.sh scope --upto 0 --reqs): ViD stages:' "$T/out" || fail "the re-cut's refusal does not name the read"
[ ! -f "$S/2/1/withdrawn" ] && [ ! -f "$S/1/1/withdrawn" ] || fail 'a re-cut with its cut unreadable withdrew a candidate'
rm -f "$T/stfail"; rd sh "$C2/land.sh" draft --review "$T/rv" --why '/vid stage: the synonyms wait for a stage 3'; [ "$RC" = 0 ] || fail "the re-cut was not drafted with its cut readable ($RC)"

# 3. develop's stage close: the report's read failing writes nothing; a stage-0 close still closes
cd "$T"; st_close_repo "$T/r"; mv checks/stages.sh checks/stages.real.sh; cp "$C2/stages.sh" checks/stages.sh; g add -A; g commit -qm 'the stage reader, its door'
st_rcpt; st_keep ROW-001 ROW-002
echo '* scope --upto 2 --reqs' > "$T/stfail"; rd sh checks/metrics.sh stage-close --stage 1 --record; refused 'metrics stage-close, its report unreadable' "metrics stage-close: $SCR 2 --reqs): ViD stages:"
! grep -q '^stage-closed ' .vid/metrics-events && ! git rev-parse -q --verify refs/tags/vid/stage-1 > /dev/null && [ ! -f .vid/SLICE-REPORTS.md ] || fail 'a refused stage close wrote its tag, its event or its report'
rm -f "$T/stfail"; rd sh checks/metrics.sh stage-close --stage 1 --record; [ "$RC" = 0 ] && grep -q '^stage-closed n=1 ' .vid/metrics-events || fail "stage 1 did not close with its reads working ($RC)"
cd "$T"; st_close_repo "$T/r0"; mv checks/stages.sh checks/stages.real.sh; cp "$C2/stages.sh" checks/stages.sh
st_stages 'STAGE-0 | the skeleton | technical' 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'row: ROW-001 -> STAGE-0' 'row: ROW-002 -> STAGE-0'; g add -A; g commit -qm 'the cut with stage 0'
sed 's/^stage: 1$/stage: 0/' .vid/RUN-STATE.md > "$T/rs0" && cat "$T/rs0" > .vid/RUN-STATE.md
st_rcpt ROW-003=failed ROW-004=failed ROW-006=failed; st_keep ROW-001 ROW-002
echo '* scope --upto -*' > "$T/stfail"; rd sh checks/metrics.sh stage-close --stage 0 --record
[ "$RC" = 0 ] && grep -q '^stage-closed n=0 ' .vid/metrics-events && grep -q '^## stage 0 ' .vid/SLICE-REPORTS.md || fail "stage 0 did not close, or its report asked a stage below 0 ($RC)"

# 4. the text check: no read of planner.sh rows or stages.sh scope under checks/ swallows its failure
# each `;`-part of a line that reads either (raw, run by `sh`, or through lib.sh's lread or mustread): no `|| true` or `|| :`, no pipe of its
# output, and a raw read or an lread has a branch for its failure (16 lines at the base: close.sh 4, end, grade, land 2, metrics 3, plan,
# planner, queue, walk 2). A raw read is a command, `sh` running the script: a message that names the command in its words reads nothing
for f in "$CHECKS"/*.sh; do case ${f##*/} in test.sh) continue ;; esac   # test.sh's read sits in an if whose other branch keeps every case
  awk -v F="${f##*/}" '/^[ \t]*#/ { next } { n = split($0, sg, ";"); for (i = 1; i <= n; i++) { s = sg[i]
      raw = (s ~ /(^|[^A-Za-z0-9_])sh ("?[^ ]*\/)?(planner\.sh"? rows|stages\.sh"? scope)( |"|\)|$)/ || s ~ /(^|[^A-Za-z0-9_])sh "\$_pl" rows( |"|\)|$)/); lib = (s ~ /(lread|mustread) [^ ]+ (planner rows|stages scope)/)
      if (!raw && !lib) continue
      if (s ~ /[|][|] *(true|:)/ || s ~ /(rows|scope)[^|]*[^|][|][^|]/ || (raw && s !~ /(rows|scope)[^|&]*([|][|]|&&)/) || (s ~ /lread / && s !~ /[|][|]/)) print F ":" FNR ":" s } }' "$f"; done > "$T/sw"
[ ! -s "$T/sw" ] || { cp "$T/sw" "$T/out"; fail "$(grep -c . "$T/sw") reads swallow a failure"; }
for x in 'close 4' 'end 1' 'grade 1' 'land 2' 'planner 1' 'queue 1' 'walk 2'; do n=$(grep -cE '(lread|mustread) [^ ]+ (planner rows|stages scope)' "$CHECKS/${x% *}.sh" || true)
  [ "$n" = "${x#* }" ] || fail "${x% *}.sh reads the plan's rows or the scope $n times through lib.sh's reader, not ${x#* }"; done
[ "$(grep -c 'cannot be read (checks/' "$CHECKS/plan.sh")" -ge 3 ] && [ "$(grep -c 'scope93 [a-z-]* ' "$CHECKS/metrics.sh")" -ge 3 ] || fail 'plan.sh or metrics.sh lost an inline check'
exit 0
