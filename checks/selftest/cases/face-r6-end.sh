#!/bin/sh
# Purpose: selftest case — ViD's face R6 (0.26.10.29): when a sitting ends its file says so; a pause ends at its commit
# (face.sh end pause-N, the skill's instruction after it), the interview when ViD takes its answers. Convicts unless
# end turns the sitting's state to ended with its time, takes the turn from the person, and the ended sitting is no
# longer the one the standing names; unless ending a sitting that is not the one written (0.26.10.29.6, S1) says so,
# exits 0 and keeps the file byte for byte;
# and unless ending twice keeps the first end's time; and unless the fixture's writes and ends make no pages (usability,
# P9: they are face-pages-index's). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-r6-end: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
for s in interview pause-1 pause-2 pause-3; do
  fc_run write "$s" "lines.$s"; [ "$RC" = 0 ] || fail "$s refused: $OUT"
  [ "$(fc_json "d['state']")" = waiting ] || fail "$s is not written waiting"
  o=interview; [ "$s" = interview ] && o=pause-1
  cp .vid/face/sitting.json before; fc_run end "$o"; [ "$RC" = 0 ] || fail "ending $o while $s is written did not exit 0: $OUT"
  printf '%s\n' "$OUT" | grep -q 'not written' || fail "ending $o while $s is written does not say so: $OUT"
  cmp -s before .vid/face/sitting.json || fail "an end of a sitting not written changed the sitting"
  fc_run end "$s"; [ "$RC" = 0 ] || fail "end $s refused: $OUT"
  [ "$(fc_json "d['state']")" = ended ] || fail "$s is not ended after end"
  t=$(fc_json "d['ended']"); [ -n "$t" ] || fail "$s ended with no time"
  [ "$(fc_stand "d['turn'], d['sitting']" | tr -d "(),'")" = 'vid ' ] || fail "after $s ended the standing still offers it: $(fc_stand "d['turn'], d['sitting']")"
  sleep 1; fc_run end "$s"; [ "$(fc_json "d['ended']")" = "$t" ] || fail "a second end moved $s's end time"
done
# usability (P9): the fixture's face.sh has no pages script beside it, so a case that does not test the pages makes none
[ ! -d .vid/pages ] || fail 'the fixture made pages: a case that does not test them pays for them'
exit 0
