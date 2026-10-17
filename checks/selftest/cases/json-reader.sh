#!/bin/sh
# Purpose: selftest case — the hooks' shared JSON reader (v0.9.6.2 spec 3.2;
# §6 case 8). Needs the plugin's hooks/ beside checks/, so in a project
# (init copies checks/ alone) it proves nothing and passes. Convicts unless
# hooks/json.sh exists and hooks/stop-failure.sh sources it (the scanner is
# no longer its own); json_fields gives every top-level key of compact and
# pretty-printed input, never a key nested in an object or written inside a
# string value, with escapes read; jget and jhas answer from its output; and
# input whose brackets do not balance exits non-zero. The death record's
# own cases (death-record.sh) run unchanged on the shared reader. Env: CHECKS.
set -eu
HD="$CHECKS/../hooks"
[ -f "$HD/stop-failure.sh" ] || exit 0
fail() { echo "json-reader: $*" >&2; exit 1; }
[ -f "$HD/json.sh" ] || fail 'no hooks/json.sh'
grep -q 'json\.sh' "$HD/stop-failure.sh" || fail 'stop-failure.sh does not source the shared reader'
grep -q 'RS = "\\001"' "$HD/stop-failure.sh" && fail 'stop-failure.sh still carries its own scanner'
. "$HD/json.sh"
F=$(printf '%s' '{"session_id":"S1","nested":{"agent_id":"inner"},"note":"say \"agent_id\": \"x\"\nok","n":3,"agent_type":"Explore"}' | json_fields) || fail 'compact input did not parse'
[ "$(jget session_id)" = S1 ] || fail 'session_id not read'
[ "$(jget agent_type)" = Explore ] || fail 'a key after a nested object and a number not read'
jhas agent_id && fail 'a nested key or text inside a string was taken for a top-level key'
[ "$(jget note)" = 'say "agent_id": "x" ok' ] || fail "escapes not read: $(jget note)"
jhas n || fail 'a key with a number value is not seen'
F=$(printf '{\n  "session_id": "S2",\n  "cwd": "/a dir/x"\n}\n' | json_fields) || fail 'pretty-printed input did not parse'
[ "$(jget cwd)" = '/a dir/x' ] || fail 'pretty-printed value not read'
printf '%s' '{"session_id":"S1","x":{"y":1}' | json_fields > /dev/null && fail 'unbalanced input parsed'
exit 0
