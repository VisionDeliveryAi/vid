#!/bin/sh
# Purpose: selftest case — usability (P6): a wait's own parts. Convicts unless `face.sh wait parts <name>…` (two to
# eight, each at most 60 characters) keeps the parts in .vid/face/wait and the standing carries them, each "to come";
# `wait at <n> [<words>]` makes the parts before n done, n now and the rest to come, with the words; `wait done`,
# `write` and `end` clear them; and unless each call it cannot read (at with no parts named, a number out of range or
# not a number, one part or nine, an empty name, a name of 61 characters) is refused and leaves the file byte for
# byte. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-wait-parts: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
w() { fc_stand "([(p['name'], p['state']) for p in d['wait']['parts']], d['wait']['now'])"; }
fc_run wait at 1; [ "$RC" != 0 ] || fail 'at with no parts named was taken'
[ ! -e .vid/face/wait ] || fail 'a refused at wrote a wait'
fc_run wait parts 'Read the PRD' 'Write the plain sentences' 'Check them' 'Show you'; [ "$RC" = 0 ] || fail "four parts were refused: $OUT"
[ -f .vid/face/wait ] || fail 'the parts are not kept in .vid/face/wait'
[ "$(w)" = "([('Read the PRD', 'to come'), ('Write the plain sentences', 'to come'), ('Check them', 'to come'), ('Show you', 'to come')], '')" ] || fail "the standing carries $(w)"
fc_run wait at 2 'Writing the plain sentences for 11 rules'; [ "$RC" = 0 ] || fail "at 2 was refused: $OUT"
[ "$(w)" = "([('Read the PRD', 'done'), ('Write the plain sentences', 'now'), ('Check them', 'to come'), ('Show you', 'to come')], 'Writing the plain sentences for 11 rules')" ] || fail "at 2 gives $(w)"
cp .vid/face/wait W
long=$(printf '%061d' 0); sixty=$(printf '%060d' 0)
for bad in 'at 5' 'at 0' 'at x' 'parts One' 'parts 1 2 3 4 5 6 7 8 9' "parts A ''" "parts A $long" 'frob'; do
  eval "fc_run wait $bad"
  [ "$RC" != 0 ] || fail "wait $bad was taken"
  cmp -s W .vid/face/wait || fail "a refused wait $bad changed the file"
done
fc_run wait parts A "$sixty"; [ "$RC" = 0 ] || fail "a name of 60 characters was refused: $OUT"
fc_run wait parts 'é' "$(printf 'é%.0s' $(seq 1 60))"; [ "$RC" = 0 ] || fail "a name of 60 letters of two bytes each was refused: $OUT"
fc_run wait at 3 'x'; [ "$RC" != 0 ] || fail 'at 3 of two parts was taken'
fc_run wait done; [ "$RC" = 0 ] && [ ! -e .vid/face/wait ] || fail 'wait done left the parts'
[ "$(w)" = "([], '')" ] || fail "after wait done the standing carries $(w)"
# write and end clear them
fc_run wait parts A B; fc_run write interview lines.interview; [ "$RC" = 0 ] || fail "write refused: $OUT"
[ ! -e .vid/face/wait ] && [ "$(w)" = "([], '')" ] || fail 'a sitting written left the parts'
fc_run wait parts A B; fc_run wait at 1; fc_run end interview; [ "$RC" = 0 ] || fail "end refused: $OUT"
[ ! -e .vid/face/wait ] && [ "$(w)" = "([], '')" ] || fail 'a sitting ended left the parts'
exit 0
