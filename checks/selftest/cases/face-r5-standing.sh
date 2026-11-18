#!/bin/sh
# Purpose: selftest case — ViD's face R5 (0.26.10.29): a script, with no model, computes the standing from disk: which
# of the nine stops is current and whose turn it is. Convicts unless the current stop follows the marks: the Seed
# alone gives the interview; a pause-N event after the latest create-prd start, or its Ratifications line where no
# event was written, marks that pause done; a pause-1 event of an earlier create-prd run does not; BASELINE.md with
# ARCHITECTURE.md, design/, test-inventory's end and a stage-cut mark stops 6 to 9; and unless the turn is the
# person's exactly while a sitting waits at the current stop: ViD's with none written, with one ended, and with one
# waiting at a stop the marks have passed; and unless a stop's sitting is true exactly where face.sh's table holds a
# sitting for it (usability, P8; 0.26.10.29.6, S1: stops 6 to 9 too). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-r5-standing: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
cur() { fc_run standing; [ "$RC" = 0 ] || fail "standing failed: $OUT"; fc_stand "d['current'], d['turn']" | tr -d "(),'"; }
ev() { printf '%s at=2026-11-12T00:00:0%sZ\n' "$1" "$2" >> .vid/metrics-events; }
[ "$(cur)" = '2 vid' ] || fail "the Seed alone gives '$(cur)', not stop 2, ViD's turn"
# usability (P8): a stop has sittings when the table holds one for it
[ "$(fc_stand "[s['sitting'] for s in d['stops']]")" = '[False, True, True, True, True, True, True, True, True]' ] || fail "the stops' sittings are $(fc_stand "[s['sitting'] for s in d['stops']]")"
ev 'stage name=create-prd state=start session=s records=1' 1
fc_run write interview lines.interview
[ "$(cur)" = '2 person' ] || fail "a waiting interview gives '$(cur)', not 2 person"
fc_run end interview
[ "$(cur)" = '3 vid' ] || fail "an ended interview gives '$(cur)', not 3 vid"
fc_run write pause-1 lines.pause-1
[ "$(cur)" = '3 person' ] || fail "a waiting pause 1 gives '$(cur)'"
ev 'stage name=create-prd state=pause-1 session=s' 2
[ "$(cur)" = '4 vid' ] || fail "pause 1's event gives '$(cur)', not 4 vid (the sitting waits at a passed stop)"
# a later create-prd start: the earlier run's pause-1 no longer counts; the Ratifications line does
ev 'stage name=create-prd state=start session=t records=1' 3
rm -f .vid/face/sitting.json
[ "$(cur)" = '2 vid' ] || fail "an earlier run's pause-1 event still counts: '$(cur)'"
sed 's/^## Ratifications$/## Ratifications\n\n- 2026-11-12 — thesis+contract — abc1234/' PRD.md > X && mv X PRD.md
grep -q ' — thesis+contract — abc1234' PRD.md || fail 'the Ratifications mutation did not apply'
[ "$(cur)" = '4 vid' ] || fail "the thesis+contract line gives '$(cur)', not 4"
printf '%s\n' '- 2026-11-12 — gap answers — abc1235' '- 2026-11-12 — final — abc1236' > R
awk '{ print } /thesis\+contract — abc1234/ { while ((getline l < "R") > 0) print l }' PRD.md > X && mv X PRD.md
[ "$(cur)" = '6 vid' ] || fail "the final line gives '$(cur)', not 6"
: > BASELINE.md; : > ARCHITECTURE.md; [ "$(cur)" = '7 vid' ] || fail "the technical foundation gives '$(cur)', not 7"
ev 'stage name=test-inventory state=end session=s' 4; [ "$(cur)" = '9 vid' ] || fail "the test list's end gives '$(cur)', not 9 (the design, unmarked, done when a later stop is)"
ev 'stage-cut n=2 answer=A-020' 5; [ "$(cur)" = '10 vid' ] || fail "the stage cut gives '$(cur)', not 10 (all nine done)"
fc_stand "[s['state'] for s in d['stops']]" | grep -q "'here'" && fail 'a stop is here when all nine are done'
# next names the stop after the current
rm -f BASELINE.md ARCHITECTURE.md .vid/metrics-events; sed -e '/ — gap answers — /d' -e '/ — final — /d' PRD.md > X && mv X PRD.md
fc_run standing; [ "$(fc_stand "d['current'], d['next']" | tr -d "(),'")" = '4 The final wording' ] || fail "next is not the stop after the current: $(fc_stand "d['next']")"
exit 0
