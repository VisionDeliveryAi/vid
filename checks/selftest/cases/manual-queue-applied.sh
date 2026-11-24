#!/bin/sh
# Purpose: selftest case — the owner's queue reads the spec at the applied commit in GitHub manual (GM-4 E12, GM M3), checks/queue.sh
# on the writer's toy and the fake gh. Stage 1 is planted closed with the owner's production yes open, the grade before the first
# go-live offered on it. In GitHub manual, with a requirement added to the PRD and stage 1 renamed in STAGES.md, both pending (after
# .vid/tw/applied): the offered grade's ask names the applied requirements and not the pending one, and the status line names
# stage 1 as the applied commit does. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "manual-queue-applied: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; QS=$CHECKS/queue.sh; R=owner/code; TAB=$(printf '\t')
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out; tw_hand 'engines alpha'
gh issue create -R $R --title t0 --body b > /dev/null
# stage 1 closed at candidate 1, main's commit; its rehearsal read, the owner's yes asked (close.sh decide --stage writes the item so)
X=$(git --git-dir="$T/code.git" rev-parse main); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs" "$F/rh"
printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"; : > "$F/named"; : > "$F/passed"; : > "$F/d1/passed"; : > "$F/cs/passed"
tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
printf 'production:1:1:1\tRehearsal of stage 1 passed: Deploy to production? yes or no\n' > "$F/yes"
# GitHub manual, the applied commit the toy's; then REQ-099 added and stage 1 renamed, pending
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied
awk '{ print } /^REQ-001 \| / { print "REQ-099 | functional | T1 | A digest names its sender. | fail-if: a digest names no sender | serves: trust | authority: authoritative | source: seed | covers: DIM-notifications | phase: pilot | feature: FEAT-01" }' PRD.md > P.x && mv P.x PRD.md
sed 's/^STAGE-1 | The daily digest |/STAGE-1 | A pending name |/' STAGES.md > S.x && mv S.x STAGES.md
git add PRD.md STAGES.md; git commit -qm 'a requirement and a stage name, not applied'
sh "$CHECKS/prd.sh" --effective 2>/dev/null | grep -q '^REQ-099 ' || fail 'the toy did not take the pending requirement'
# the offered grade: its requirements the applied commit's
sh "$QS" sync > /dev/null 2>&1; QY=$(sed -n 's/^- \(Q[0-9]*\) · .*Rehearsal of stage 1.*/\1/p' .vid/RUN-STATE.md | head -n 1); [ -n "$QY" ] || fail "no production item: $(grep '^- Q' .vid/RUN-STATE.md)"
sh "$QS" answer "$QY" grade 'grade it first — the owner' > "$T/out" 2>&1 || fail "the offered grade was refused: $(cat "$T/out")"
GA=$(sed -n 's/^asked \([0-9]*\) grade before the first go-live$/\1/p' "$T/out"); [ -n "$GA" ] || fail 'no grade ask'
[ "$(grep -cx "review grade-$GA $(printf %.12s "$X")" "$T/out")" = 1 ] || fail "the answer does not print the ask's own review line, once"   # FB-3 A1.6
RQ=$(sed -n 's/^requirements: //p' ".vid/decide/grade/$GA/body"); case " $RQ " in *' REQ-001 '*) ;; *) fail "the ask names no applied requirement: $RQ" ;; esac
case " $RQ " in *' REQ-099 '*) fail "the ask names the pending requirement: $RQ" ;; esac
# the status line: stage 1, the current stage, as applied
if grep -q '^stage:' .vid/RUN-STATE.md; then sed 's/^stage:.*/stage: 1/' .vid/RUN-STATE.md > R.x; else awk '{ print } /^run:/ && !d { print "stage: 1"; d = 1 }' .vid/RUN-STATE.md > R.x; fi; cat R.x > .vid/RUN-STATE.md; rm -f R.x
grep -q '^stage: 1$' .vid/RUN-STATE.md || fail 'the toy'"'"'s run record took no stage line'
VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1 || true
grep -q '^stage: 1 — The daily digest' "$T/out" || fail "the status's stage line: $(grep '^stage:' "$T/out")"
! grep -q 'A pending name' "$T/out" || fail 'the status names the pending stage name'
echo 'manual-queue-applied: ok'
