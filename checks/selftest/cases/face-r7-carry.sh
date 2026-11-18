#!/bin/sh
# Purpose: selftest case — ViD's face R7 (0.26.10.29): each sitting carries the session that wrote it and a format
# number. Convicts unless every sitting written names the session face.sh ran in (CLAUDE_CODE_SESSION_ID) and format
# 2 (usability, P1), and its short phrase for when it is ready (P12); the standing carries format 2 and, while the person's turn, the same session; and unless a write with no
# session to name is refused, nothing written. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-r7-carry: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
for s in interview pause-1 pause-2 pause-3; do
  fc_run write "$s" "lines.$s"; [ "$RC" = 0 ] || fail "$s refused: $OUT"
  [ "$(fc_json "d['session'], d['format']" | tr -d "(),'")" = 'sess-A 2' ] || fail "$s carries $(fc_json "d['session'], d['format']")"
  [ "$(fc_stand "d['format']")" = 2 ] || fail 'the standing carries no format 2'
  case $s in interview) r='Your questions are ready' ;; pause-1) r='Your summary is ready' ;; pause-2) r='The gaps are ready for you' ;; pause-3) r='The final wording is ready' ;; esac
  [ "$(fc_json "d['ready']")" = "$r" ] || fail "$s carries the phrase '$(fc_json "d.get('ready')")', not '$r'"
done
rm -f .vid/face/sitting.json; fc_run write interview lines.interview
[ "$(fc_stand "d['turn'], d['session']" | tr -d "(),'")" = 'person sess-A' ] || fail "the standing does not carry the waiting sitting's session: $(fc_stand "d['turn'], d['session']")"
rm -f .vid/face/sitting.json
set +e; OUT=$(env -u CLAUDE_CODE_SESSION_ID sh "$CHECKS/face.sh" write interview lines.interview 2>&1); RC=$?; set -e
[ "$RC" != 0 ] || fail 'a write with no session was taken'
[ ! -f .vid/face/sitting.json ] || fail 'a write with no session left a sitting'
exit 0
