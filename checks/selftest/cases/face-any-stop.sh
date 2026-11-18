#!/bin/sh
# Purpose: selftest case — usability (P8): a sitting can be written at any stop from 2 to 9, more than one a stop.
# With two rows added to a copy of face.sh's table for stop 6, both of the session's sections only and neither closing
# its stop, convicts unless: the first is written with no PRD.md; the standing says stops 2 to 9 have sittings
# (0.26.10.29.6, S1: the table holds stops 6 to 9's own); while it waits the turn is the person's at stop 6;
# ending it leaves stop 6 the current one; the second
# is written and ended and stop 6 is still current; an unknown sitting is refused naming the table's sittings,
# these two among them; and a PRD sitting still needs PRD.md and still closes its stop. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-any-stop: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
mkdir c; cp -R "$CHECKS/." c/; rm -f c/pages.sh
TAB=$(printf '\t')
awk -v t="$TAB" '/^EOF$/ && !done { print "sitting" t "hints-a" t "6" t "Technical hints, part one" t "Send to ViD" t "-" t "no"
  print "section" t "notes" t "list" t "session" t "Notes" t "ok=Fine,change=Change+" t "-"
  print "sitting" t "hints-b" t "6" t "Technical hints, part two" t "Send to ViD" t "-" t "no"
  print "section" t "more" t "questions" t "session" t "More" t "choose=Choose,own=In my own words+" t "-"; done = 1 } { print }' "$CHECKS/face.sh" > c/face.sh
grep -q "^sitting${TAB}hints-a${TAB}6" c/face.sh || fail 'the table rows were not added to the copy'
fr() { set +e; OUT=$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh "$@" 2>&1); RC=$?; set -e; }
mv PRD.md PRD.away
printf 'section notes\nitem N1 | Runs on one small server\n' > A
fr write hints-a A; [ "$RC" = 0 ] || fail "a stop-6 sitting of the session's sections was refused without PRD.md: $OUT"
[ "$(fc_stand "[s['sitting'] for s in d['stops']]")" = '[False, True, True, True, True, True, True, True, True]' ] || fail "the stops' sittings are $(fc_stand "[s['sitting'] for s in d['stops']]")"
[ "$(fc_stand "d['current'], d['turn'], d['sitting']" | tr -d "(),'")" = '6 person hints-a' ] || fail "a waiting stop-6 sitting gives $(fc_stand "d['current'], d['turn'], d['sitting']")"
fr end hints-a; [ "$RC" = 0 ] || fail "ending hints-a was refused: $OUT"
[ "$(fc_stand "d['current'], d['stops'][5]['state']" | tr -d "(),'")" = '6 here' ] || fail "ending the first sitting moved the map: $(fc_stand "d['current'], d['stops'][5]['state']")"
printf 'section more\nitem M1 | Where does it run?\nchoice | Here\n' > B
fr write hints-b B; [ "$RC" = 0 ] || fail "the second stop-6 sitting was refused: $OUT"
fr end hints-b; [ "$(fc_stand "d['current']")" = 6 ] || fail "ending the second (not closing) sitting moved the map to $(fc_stand "d['current']")"
fr write nonesuch A; [ "$RC" != 0 ] || fail 'an unknown sitting was taken'
printf '%s\n' "$OUT" | grep -q 'hints-a' && printf '%s\n' "$OUT" | grep -q 'pause-3' || fail "the refusal does not name the table's sittings: $OUT"
rm -f .vid/face/sitting.json   # 0.26.10.29.6 (S1): a later stop's sitting on disk would make this stop a passed one
fr write pause-1 lines.pause-1; [ "$RC" != 0 ] || fail 'pause-1 was written with no PRD.md'
mv PRD.away PRD.md
fr write pause-1 lines.pause-1; [ "$RC" = 0 ] || fail "pause-1 was refused: $OUT"
fr end pause-1; [ "$(fc_stand "d['stops'][2]['state']")" = done ] || fail "ending pause-1 did not close stop 3"
exit 0
