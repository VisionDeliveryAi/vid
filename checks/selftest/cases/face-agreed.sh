#!/bin/sh
# Purpose: selftest case — usability (P11): the line of what was agreed at a stop. When a sitting ends, face.sh keeps
# one line in .vid/face/agreed, "<its title>: <n> items, agreed <day> <month>", n the items the sitting file holds,
# the day its end's; the standing carries each stop's `agreed`. Convicts unless: the interview ended gives stop 2
# "The interview: 3 items, agreed <its day>"; stop 1, done with no ended sitting, says "Done"; a stop not done says
# nothing; a later ended sitting of the same stop gives its own line; ending an ended sitting again adds no line;
# and a stop-6 sitting that does not close its stop, ended, leaves stop 6 (not done) with no line; and
# unless the month is in English whatever the locale (the date asked for as LC_ALL=C; the day is the UTC day).
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-agreed: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
ag() { fc_stand "d['stops'][$1 - 1]['agreed']"; }
day() { python3 -c "import json,datetime; e=json.load(open('.vid/face/sitting.json'))['ended']; t=datetime.datetime.strptime(e,'%Y-%m-%dT%H:%M:%SZ'); print(str(t.day) + ' ' + t.strftime('%b'))"; }
fc_run write interview lines.interview; [ "$RC" = 0 ] || fail "the interview was refused: $OUT"
[ "$(ag 2)" = '' ] || fail "a waiting stop says '$(ag 2)'"
fc_run end interview; [ "$RC" = 0 ] || fail "end refused: $OUT"
[ "$(ag 2)" = "The interview: 3 items, agreed $(day)" ] || fail "stop 2 says '$(ag 2)', not 'The interview: 3 items, agreed $(day)'"
[ "$(ag 1)" = 'Done' ] || fail "stop 1, done with no sitting, says '$(ag 1)'"
[ "$(ag 3)" = '' ] && [ "$(ag 9)" = '' ] || fail 'a stop not done has an agreed line'
[ -f .vid/face/agreed ] || fail 'no .vid/face/agreed'
fc_run end interview; [ "$(wc -l < .vid/face/agreed | tr -d ' ')" = 1 ] || fail 'ending an ended sitting again added a line'
fc_run write pause-1 lines.pause-1; fc_run end pause-1
n=$(fc_json "sum(len(x['items']) for x in d['sections'])")
[ "$(ag 3)" = "Agree the summary: $n items, agreed $(day)" ] || fail "stop 3 says '$(ag 3)', not $n items"
[ "$(ag 2)" = "The interview: 3 items, agreed $(day)" ] || fail "stop 2 lost its line: '$(ag 2)'"
# a later sitting of the same stop: its own line
rm -f .vid/face/sitting.json   # 0.26.10.29.6 (S1): a later stop's sitting on disk would make this stop a passed one
grep -v '^item DIM-nfr-privacy' lines.pause-1 > L1; fc_run write pause-1 L1; fc_run end pause-1
[ "$(ag 3)" = "Agree the summary: $((n - 1)) items, agreed $(day)" ] || fail "the later sitting of stop 3 gives '$(ag 3)'"
# a sitting that does not close its stop: no line while the stop is not done
# the month in English whatever the locale: face.sh asks for the date in the C locale
grep -q 'LC_ALL=C date -u' "$CHECKS/face.sh" || fail "face.sh does not ask for the agreed day in the C locale"
rm -f .vid/face/sitting.json   # 0.26.10.29.6 (S1): a later stop's sitting on disk would make this stop a passed one
fc_run write interview lines.interview
set +e; OUT=$(LC_ALL=fr_FR.UTF-8 LC_TIME=fr_FR.UTF-8 LANG=fr_FR.UTF-8 CLAUDE_CODE_SESSION_ID=sess-A sh "$CHECKS/face.sh" end interview 2>&1); set -e
[ "$(ag 2)" = "The interview: 3 items, agreed $(day)" ] || fail "in a French locale stop 2 says '$(ag 2)'"
mkdir c; cp -R "$CHECKS/." c/; rm -f c/pages.sh; TAB=$(printf '\t')
awk -v t="$TAB" '/^EOF$/ && !done { print "sitting" t "hints-a" t "6" t "Technical hints" t "Send to ViD" t "-" t "no" t "Your hints are ready"
  print "section" t "notes" t "list" t "session" t "Notes" t "ok=Fine,change=Change+" t "-"; done = 1 } { print }' "$CHECKS/face.sh" > c/face.sh
printf 'section notes\nitem N1 | One small server\n' > A
set +e; OUT=$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh write hints-a A 2>&1 && CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh end hints-a 2>&1); RC=$?; set -e
[ "$RC" = 0 ] || fail "the stop-6 sitting was refused: $OUT"
[ "$(fc_stand "d['current']")" = 6 ] && [ "$(ag 6)" = '' ] || fail "a stop not done whose sitting ended says '$(ag 6)'"
exit 0
