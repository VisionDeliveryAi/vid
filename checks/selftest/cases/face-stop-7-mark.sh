#!/bin/sh
# Purpose: selftest case — usability 3 (0.26.10.29.6, S1): stop 7 is done when the design is ratified, and a stop the
# map has passed gets no sitting. Convicts unless: a design/ folder with no design event keeps today's mark (stop 7
# done); after the design verb's start event stop 7 is not done although design/ is there, a design sitting is
# written and waits there, and ending it leaves stop 7 current; the verb's end event marks stop 7 done; then a write
# of a design sitting writes nothing, leaves the sitting on disk byte for byte, says in one line that the stop is
# passed and exits 0, and an end of a sitting not written says so in one line, changes nothing and exits 0; a new
# start reopens stop 7; and after init's end a write of the test list's sitting leaves the waiting design sitting
# as it was and exits 0, and its end leaves it, the agreed lines and the map as they were. Before all that, the map
# counts the sitting on disk: with the interview ended and pause 1 waiting, a write of the interview writes nothing
# and leaves pause 1 waiting at stop 3, while a write of pause 1 again (the map's own stop) is taken. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-stop-7-mark: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
ev() { printf '%s at=2026-11-16T10:%02d:00Z\n' "$1" "$2" >> .vid/metrics-events; }
st7() { fc_run standing; fc_stand "d['current'], d['stops'][6]['state']" | tr -d "(),'"; }
# the sitting on disk counts: an earlier stop's sitting never replaces a waiting one
fc_run write interview lines.interview; fc_run end interview
fc_run write pause-1 lines.pause-1; [ "$RC" = 0 ] || fail "pause-1 refused: $OUT"
cp .vid/face/sitting.json p1
fc_run write interview lines.interview; [ "$RC" = 0 ] || fail "a write of the interview at a passed stop did not exit 0: $OUT"
cmp -s p1 .vid/face/sitting.json || fail 'a write of the interview replaced the waiting pause-1 sitting'
[ "$(fc_stand "d['current'], d['sitting']" | tr -d "(),'")" = '3 pause-1' ] || fail "after the refused interview the map is $(fc_stand "d['current'], d['sitting']")"
fc_run write pause-1 lines.pause-1; [ "$RC" = 0 ] && [ "$(fc_json "d['sitting'], d['state']" | tr -d "(),'")" = 'pause-1 waiting' ] || fail "a re-write at the map's own stop was not taken: $OUT"
mkdir design
[ "$(st7 | cut -d' ' -f2)" = done ] || fail "design/ with no design event: stop 7 is $(st7)"
ev 'stage name=design state=start session=sess-A records=1' 1
[ "$(st7 | cut -d' ' -f2)" = todo ] || fail "after the design verb's start stop 7 is $(st7), not to come"
printf 'section brief-only\nitem S-04 | The empty inbox screen\nrecommend | Draw it\nempty design-only | none\nempty unknown | none\n' > G
fc_run write design-gaps G; [ "$RC" = 0 ] || fail "design-gaps refused: $OUT"
[ "$(fc_stand "d['current'], d['turn'], d['sitting']" | tr -d "(),'")" = '7 person design-gaps' ] || fail "the design sitting does not wait at stop 7: $(fc_stand "d['current'], d['turn'], d['sitting']")"
fc_run end design-gaps; [ "$RC" = 0 ] || fail "end design-gaps refused: $OUT"
[ "$(st7)" = '7 here' ] || fail "ending design-gaps moved stop 7: $(st7)"
ev 'stage name=design state=end session=sess-A' 2
[ "$(st7)" = '8 done' ] || fail "after the design verb's end stop 7 is $(st7)"
cp .vid/face/sitting.json before
printf 'section lines\nitem L1 | Spacing\nrecommend | Design wins\n' > D
fc_run write design-lines D; [ "$RC" = 0 ] || fail "a write at a passed stop did not exit 0: $OUT"
cmp -s before .vid/face/sitting.json || fail 'a write at a passed stop changed the sitting on disk'
[ "$(printf '%s\n' "$OUT" | grep -c 'passed')" = 1 ] || fail "a write at a passed stop does not say so in one line: $OUT"
fc_run end design-lines; [ "$RC" = 0 ] || fail "an end of a sitting not written did not exit 0: $OUT"
cmp -s before .vid/face/sitting.json || fail 'an end of a sitting not written changed the sitting'
[ "$(printf '%s\n' "$OUT" | grep -c 'not written')" = 1 ] || fail "an end of a sitting not written does not say so in one line: $OUT"
# a new round of the design reopens stop 7
ev 'stage name=design state=start session=sess-A records=1' 3
[ "$(st7 | cut -d' ' -f2)" != done ] || fail 'a new start of the design verb did not reopen stop 7'
fc_run write design-lines D; [ "$RC" = 0 ] || fail "design-lines refused once stop 7 reopened: $OUT"
cp .vid/face/sitting.json waiting
# after init's end every stop is passed: nothing is written, the waiting sitting stays
ev 'stage name=init state=end session=sess-A' 4
printf 'section counted\nitem rows | Tests\nvalue | 3\nempty look | none\nempty kinds | none\nempty alone | none\n' > X
fc_run write tests X; [ "$RC" = 0 ] || fail "a write after init's end did not exit 0: $OUT"
cmp -s waiting .vid/face/sitting.json || fail "a write after init's end replaced the waiting sitting"
fc_run end tests; [ "$RC" = 0 ] || fail "an end of the test list's sitting, not written, did not exit 0: $OUT"
cmp -s waiting .vid/face/sitting.json || fail 'an end of a sitting not written changed the waiting one'
cp .vid/face/agreed agreed.before
fc_run end design-lines; [ "$RC" = 0 ] || fail "an end at a passed stop did not exit 0: $OUT"
cmp -s waiting .vid/face/sitting.json || fail 'an end at a passed stop ended the old sitting'
cmp -s agreed.before .vid/face/agreed || fail 'an end at a passed stop added an agreed line'
exit 0
