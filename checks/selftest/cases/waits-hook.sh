#!/bin/sh
# Purpose: selftest case — bounded waits in builder and fixer agents (v0.9.7.1 spec 3.5b, R5). Feeds the plugin's
# hooks/waits.sh PreToolUse inputs. Plugin repository only (a project has no hooks/ of ViD's). Convicts unless it
# denies, for agent_type vid:builder and vid:fixer, a `while … sleep` loop, an `until` loop repeating `git status`,
# a loop repeating checks/test.sh, a `sleep 300`, a `sleep 4m` and a `sleep $X` — each reason naming `sh
# checks/test.sh wait` — and allows: the same loop with run_in_background true, the same loop from the run
# manager (no agent_type) and from another agent type (vid:grader), `sleep 120`, `sleep 200`, a plain `git
# commit`, a `for` loop, and the waits hook is registered on Bash in hooks.json. Env: CHECKS.
set -eu
H="$CHECKS/../hooks/waits.sh"
[ -f "$H" ] || exit 0
fail() { echo "waits-hook: $*" >&2; exit 1; }
inp() { # <agent_type|-> <background true|false> <command>
  _a=''; [ "$1" = - ] || _a="\"agent_id\":\"a1\",\"agent_type\":\"$1\","
  printf '{"session_id":"s","hook_event_name":"PreToolUse",%s"tool_name":"Bash","tool_input":{"command":"%s","run_in_background":%s}}' "$_a" "$3" "$2"; }
deny() { o=$(inp "$1" "$2" "$3" | sh "$H"); printf '%s' "$o" | grep -q '"permissionDecision":"deny"' || fail "not denied ($1, $2): $3"; printf '%s' "$o" | grep -qF 'sh checks/test.sh wait' || fail "the reason does not name the wait: $3"; }
allow() { o=$(inp "$1" "$2" "$3" | sh "$H"); [ -z "$o" ] || fail "denied ($1, $2): $3 — $o"; }
for a in vid:builder vid:fixer; do
  deny $a false 'while kill -0 123; do sleep 5; done'
  deny $a false 'until git status --porcelain | grep -q x; do echo; done'
  deny $a false 'while true; do sh checks/test.sh wait T1; done'
  deny $a false 'sleep 300'
  deny $a false 'sleep 4m'
  deny $a false 'sleep $X'
done
allow vid:builder true 'while kill -0 123; do sleep 5; done'
allow - false 'while kill -0 123; do sleep 5; done'
allow vid:grader false 'while kill -0 123; do sleep 5; done'
allow vid:builder false 'sleep 120'
allow vid:builder false 'sleep 200'
allow vid:builder false 'git commit -q -F msg.txt'
allow vid:builder false 'for f in a b; do echo $f; done'
grep -q 'hooks/waits.sh' "$CHECKS/../hooks/hooks.json" || fail 'the hook is not registered'
awk '/"PreToolUse"/ { p = 1 } p && /"matcher": "Bash"/ { m = 1 } m && /waits\.sh/ { f = 1; exit } END { exit f ? 0 : 1 }' "$CHECKS/../hooks/hooks.json" || fail 'the hook is not on PreToolUse for Bash'
exit 0
