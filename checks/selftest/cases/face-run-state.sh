#!/bin/sh
# Purpose: selftest case — usability (P4): whether the session runs is written by the hooks, one small file a
# session, .vid/face/run.<session id>: `<running|stopped> <since, UTC> <last step, UTC|->`. Convicts unless
# hooks.json runs hooks/face-standing.sh at UserPromptSubmit (5 s), after Bash, Write and Edit (5 s), at Stop (30 s)
# and at StopFailure (10 s, beside stop-failure.sh), and the plugin's one module hands the end of a turn to
# hooks/face/recorder.ts; unless a
# prompt writes running, keeping the last step, and leaves the standing as it was; a step sets the last step, keeps
# a running state's start, turns a stopped (or missing) file to running begun now, and recomputes the standing; Stop
# writes stopped begun now, keeping the last step, and recomputes the standing; StopFailure writes stopped; unless a
# session id that is not a plain id writes nothing; unless where no standing is written nothing is; and unless each
# run of the standing removes .standing.* files older than a minute and run.* files older than seven days, and
# keeps younger ones; and unless a helper's events (an agent_id in the input) never write the session's file (its
# step still recomputes the standing). Gated on the plugin's hooks/.
# Env: CHECKS.
set -eu
H=$CHECKS/../hooks
[ -f "$H/face-standing.sh" ] && [ -f "$H/hooks.json" ] || { echo 'needs the plugin'"'"'s hooks/'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-run-state: $*" >&2; exit 1; }
python3 - "$H/hooks.json" <<'PY' || fail 'hooks.json does not run face-standing.sh at the four events with their limits, or names more than the one module'
import json, sys
d = json.load(open(sys.argv[1])); h = d['hooks']
def ent(ev):
    return [(x.get('matcher', ''), c.get('timeout')) for x in h.get(ev, []) for c in x['hooks'] if 'face-standing.sh' in c.get('command', '')]
ok = ent('UserPromptSubmit') == [('', 5)] and ent('Stop') == [('', 30)] and ent('StopFailure') == [('', 10)]
ok = ok and len(ent('PostToolUse')) == 1 and set(ent('PostToolUse')[0][0].split('|')) >= {'Bash', 'Write', 'Edit'} and ent('PostToolUse')[0][1] == 5
ok = ok and any('stop-failure.sh' in c['command'] for x in h['StopFailure'] for c in x['hooks'])
ok = ok and d.get('modules') == ['./face/register.tsx']
sys.exit(0 if ok else 1)
PY
[ -f "$H/face/recorder.ts" ] || fail 'no hooks/face/recorder.ts'
grep -q "import { recordStop } from './recorder'" "$H/face/register.tsx" || fail "the plugin's one module does not hand the end of a turn to the recorder"
. "$CHECKS/selftest/fixtures/face.sh"
hook() { printf '{"hook_event_name":"%s","session_id":"%s","cwd":"%s"}' "$1" "$2" "$T" | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh" || fail "the hook failed at $1"; }
run() { cat ".vid/face/run.$1"; }
f() { awk -v n="$2" '{ print $n }' ".vid/face/run.$1"; }
utc='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
# no standing: nothing is written
hook UserPromptSubmit S1; [ ! -e .vid/face/run.S1 ] || fail 'a prompt wrote a run file where no standing is'
fc_run write interview lines.interview; [ "$RC" = 0 ] || fail "the interview was refused: $OUT"
# a prompt: running, begun now, no last step yet; the standing left as it was
printf '{"stale":1}\n' > .vid/face/standing.json; cp .vid/face/standing.json S
hook UserPromptSubmit S1
[ "$(f S1 1)" = running ] || fail "a prompt wrote '$(run S1)'"
f S1 2 | grep -Eq "$utc" || fail "a prompt's start is not a UTC time: '$(run S1)'"
[ "$(f S1 3)" = - ] || fail "a first prompt names a last step: '$(run S1)'"
cmp -s S .vid/face/standing.json || fail 'a prompt recomputed the standing'
b1=$(f S1 2); sleep 1
# a step: the last step now, the start kept, the standing recomputed
hook PostToolUse S1
[ "$(f S1 1) $(f S1 2)" = "running $b1" ] || fail "a step while running wrote '$(run S1)', not running since $b1"
f S1 3 | grep -Eq "$utc" || fail "a step left no last step: '$(run S1)'"
grep -q '"stops"' .vid/face/standing.json || fail 'a step did not recompute the standing'
l1=$(f S1 3); sleep 1
# Stop: stopped, begun now, the last step kept, the standing recomputed
printf '{"stale":1}\n' > .vid/face/standing.json
hook Stop S1
[ "$(f S1 1) $(f S1 3)" = "stopped $l1" ] || fail "Stop wrote '$(run S1)', not stopped keeping $l1"
[ "$(f S1 2)" != "$b1" ] || fail 'Stop kept the running start'
grep -q '"stops"' .vid/face/standing.json || fail 'Stop did not recompute the standing'
sleep 1
# a step while stopped: running, begun now
hook PostToolUse S1
[ "$(f S1 1)" = running ] || fail "a step after Stop left '$(run S1)'"
[ "$(f S1 2)" = "$(f S1 3)" ] || fail "a step after Stop did not begin the running state now: '$(run S1)'"
l2=$(f S1 3); sleep 1
# StopFailure: stopped, the last step kept
hook StopFailure S1
[ "$(f S1 1) $(f S1 3)" = "stopped $l2" ] || fail "StopFailure wrote '$(run S1)'"
# a prompt after a stop: running, the last step kept
hook UserPromptSubmit S1
[ "$(f S1 1) $(f S1 3)" = "running $l2" ] || fail "a prompt after a stop wrote '$(run S1)'"
# a helper's events never write the session's file: not its StopFailure, not its step, running or stopped
hookA() { printf '{"hook_event_name":"%s","session_id":"%s","agent_id":"a1","cwd":"%s"}' "$1" "$2" "$T" | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh" || fail "the hook failed at a helper's $1"; }
cp .vid/face/run.S1 R1; hookA StopFailure S1; cmp -s R1 .vid/face/run.S1 || fail "a helper's StopFailure changed the session's file: '$(run S1)'"
sleep 1; hookA PostToolUse S1; cmp -s R1 .vid/face/run.S1 || fail "a helper's step while running changed the session's file: '$(run S1)'"
hook Stop S1; cp .vid/face/run.S1 R2; sleep 1
hookA PostToolUse S1; cmp -s R2 .vid/face/run.S1 || fail "a helper's step after Stop changed the session's file: '$(run S1)'"
printf '{"stale":1}\n' > .vid/face/standing.json; hookA PostToolUse S1; grep -q '"stops"' .vid/face/standing.json || fail "a helper's step did not recompute the standing"
hookA PostToolUse S9; [ ! -e .vid/face/run.S9 ] || fail "a helper's step wrote a file for a session with none: '$(run S9)'"
hook UserPromptSubmit S1
# a step with no file for the session: running
hook PostToolUse S2; [ "$(f S2 1)" = running ] || fail "a step with no file wrote '$(run S2)'"
# an older input with no event name is a step (as before)
printf '{"tool_name":"Bash","session_id":"S3"}' | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh"
[ "$(f S3 1)" = running ] || fail 'an input with no event name was not taken as a step'
# a session id that is not a plain id names no file
hook PostToolUse '../x'; [ ! -e .vid/x ] && [ -z "$(ls .vid/face | grep -v '^run\.S[123]$' | grep '^run\.' || true)" ] || fail "an odd session id wrote a file: $(ls -a .vid/face)"
# the clean-up: old leftovers go, young ones stay
: > .vid/face/.standing.111; touch -t 202001010000 .vid/face/.standing.111
: > .vid/face/.standing.222
: > .vid/face/run.OLD; touch -t 202001010000 .vid/face/run.OLD
hook PostToolUse S1
[ ! -e .vid/face/.standing.111 ] || fail 'a .standing file older than a minute survived'
[ -e .vid/face/.standing.222 ] || fail 'a young .standing file was removed'
[ ! -e .vid/face/run.OLD ] || fail 'a run file older than seven days survived'
[ -e .vid/face/run.S2 ] || fail 'a young run file was removed'
# written whole: the hook renames into the file
grep -q 'mv -f' "$H/face-standing.sh" || fail 'the hook does not rename into the run file'
exit 0
