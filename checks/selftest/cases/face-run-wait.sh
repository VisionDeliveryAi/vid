#!/bin/sh
# Purpose: selftest case — a long call's parts in the panel of a run (FB-3 D2). In a ticket-mode project with all nine stops done,
# the standing carries the parts with `on` and `now`, and the stop with the part it stopped at, beside the backlog; a sitting written
# still clears them. Where hooks/ is beside checks/ and claude is on PATH, the panel's own tests of FB-3 D2 (hooks/face) are run by
# the test kit and pass: the parts drawn with every stop done and the session running, the stop's words with it stopped, and a killed
# call's parts gone. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-run-wait: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
mkdir -p .vid/tw; printf 'repo: owner/code\n' > .vid/tw/settings; printf 'stage-cut n=1 at=2026-11-19T09:00:00Z\n' > .vid/metrics-events
w() { fc_stand "(d['current'], [(p['name'], p['state']) for p in d['wait']['parts']], d['wait']['now'], d['wait']['stop'], d['backlog'])"; }
fc_run wait parts 'Reading GitHub' 'Your list and the plan page'; fc_run wait on 'Your list and the plan page'; fc_run wait now 'writing the page'
E="{'items': [], 'done': [], 'doneCount': 0}"
[ "$(w)" = "(10, [('Reading GitHub', 'done'), ('Your list and the plan page', 'now')], 'writing the page', '', $E)" ] || fail "the running call gives $(w)"
fc_run wait stop 'your words for 2 tests with no step'
[ "$(w)" = "(10, [('Reading GitHub', 'done'), ('Your list and the plan page', 'stopped')], 'your words for 2 tests with no step', 'your words for 2 tests with no step', $E)" ] || fail "the stop gives $(w)"
P=$(cd "$CHECKS/.." && pwd -P); [ -f "$P/hooks/face/register.test.tsx" ] && command -v claude >/dev/null 2>&1 || { echo 'face-run-wait: ok (no panel kit here)'; exit 0; }
set +e; OUT=$(cd "$P" && claude plugin test "$P" 2>&1 < /dev/null); set -e
printf '%s\n' "$OUT" > "$T/out"; ! printf '%s\n' "$OUT" | grep -q '^(fail) FB-3 D2' || fail 'a panel test of FB-3 D2 failed'
printf '%s\n' "$OUT" | grep -qE '^ *[1-9][0-9]* pass$' || fail 'the panel'"'"'s kit ran no test'
[ "$(grep -c "^test('FB-3 D2 " "$P/hooks/face/register.test.tsx")" -ge 4 ] || fail 'the panel has fewer than its four tests of FB-3 D2'
exit 0
