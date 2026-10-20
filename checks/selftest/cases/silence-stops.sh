#!/bin/sh
# Purpose: selftest case — silence stops a run (v0.26.10.4 spec R1, R3, R4;
# §5 silence-stops). A gated request whose runner prints three lines and then
# goes silent is stopped once the silence reaches VID_SILENCE_SECONDS (10):
# cap-hit holds reason=silent and the last output time; the result's first
# line says `stopped: no new output for 10 s (last at HH:MM UTC)`; the state
# is `capped`, the event carries `capped=yes stop=silent` and the request's
# silence=, startup=, limit= in place of cap=; the request's line names the
# three limits; the watch file carries the watcher's counts; the timeline is
# kept; no receipt. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "silence-stops: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"
VID_SILENCE_SECONDS=10 STUB_PRINT=3 STUB_HOLD="$T/hold" STUB_LOG_LINES=20 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'prints, then hangs' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
grep -q ' · stops after 10 s with no output, 60 min of start-up, or 24 h$' "$T/out" || fail "the request's line does not name the three limits"
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=".vid/requests/$TK"
grep -qx 'silence=10' "$TD/request" && grep -qx 'startup=3600' "$TD/request" && grep -qx 'limit=86400' "$TD/request" || fail 'the request does not carry silence=, startup=, limit='
grep -q '^cap=' "$TD/request" && fail 'the request still carries cap='
waitfor "$TD/watch" 30 || fail 'the watcher wrote no watch file'
grep -qE '^awake=[0-9]+ silent=[0-9]+ pass=inline phase=startup at=[0-9TZ:-]+$' "$TD/watch" || fail "the watch file is not awake= silent= pass= phase= at=: $(cat "$TD/watch")"
waitfor "$TD/cap-hit" 60 || fail 'the silent run was not stopped'
grep -qx 'reason=silent' "$TD/cap-hit" && grep -qE '^last-output=[0-9-]+T[0-9:]+Z$' "$TD/cap-hit" || fail "cap-hit does not hold reason=silent and the last output time: $(cat "$TD/cap-hit")"
RC=0; VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 130 ] || fail "the stopped run's wait exited $RC, not 130"
head -n 1 "$T/out" | grep -qE '^stopped: no new output for 10 s \(last at [0-9]{2}:[0-9]{2} UTC\)$' || fail "the result's first line does not say why"
grep -q '^status=130 ran-to-end=no capped=yes report=none$' "$T/out" || fail 'the result does not say capped'
grep -q '^retry: ' "$T/out" && fail 'the result still gives a retry figure'
[ "$(cat "$TD/state")" = capped ] || fail 'the final state is not capped'
grep -q "^ledger-run .* report=none status=130 .* request=$TK .* silence=10 startup=3600 limit=86400 .* capped=yes stop=silent " .vid/metrics-events || fail 'the event does not carry the limits and capped=yes stop=silent'
grep "^ledger-run .* request=$TK " .vid/metrics-events | grep -q ' cap=' && fail 'the event still carries cap='
[ -s "$TD/timeline.inline.log.gz" ] && [ -s "$TD/last-lines.inline.log" ] || fail 'the stopped pass kept no timeline'
[ -z "$(kept)" ] || fail 'a stopped run kept a receipt'
exit 0
