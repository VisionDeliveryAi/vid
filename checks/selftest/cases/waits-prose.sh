#!/bin/sh
# Purpose: selftest case — the loop guard reads shell syntax only (v0.26.10.4 spec R8, F-38, F-52; §5
# waits-prose). Feeds hooks/waits.sh PreToolUse inputs from vid:builder. Plugin repository only. Allowed: a request
# whose --why says "while", a here-document to a file holding "until" and "went to sleep", a commit message saying
# "until … sleep". Refused, each reason naming `sh checks/test.sh wait`: `while true; do sleep 5; done`, `(while …)`,
# `{ while …; }`, `"$(while …)"`, `sh -c 'while …; sleep 5 …'` and `sh <<EOF` with a loop in its body. Env: CHECKS.
set -eu
H="$CHECKS/../hooks/waits.sh"
[ -f "$H" ] || exit 0
fail() { echo "waits-prose: $*" >&2; exit 1; }
inp() { printf '{"session_id":"s","hook_event_name":"PreToolUse","agent_id":"a1","agent_type":"vid:builder","tool_name":"Bash","tool_input":{"command":"%s","run_in_background":false}}' "$1"; }
deny() { o=$(inp "$1" | sh "$H"); printf '%s' "$o" | grep -q '"permissionDecision":"deny"' || fail "not denied: $1"; printf '%s' "$o" | grep -qF 'sh checks/test.sh wait' || fail "the reason does not name the wait: $1"; }
allow() { o=$(inp "$1" | sh "$H"); [ -z "$o" ] || fail "denied: $1 — $o"; }
Q="'"
allow 'sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why \"the green while the db warms\" -- tests/x'
allow 'cat > notes.md <<EOF\nthe host went to sleep until the morning\nwhile it slept nothing ran\nEOF'
allow "cat > notes.md <<${Q}EOF${Q}\\nuntil it woke\\nEOF\\ngit add notes.md"
allow 'git commit -q -m \"retry until ready, then sleep\"'
deny 'while true; do sleep 5; done'
deny '(while true; do sleep 5; done)'
deny '{ while true; do sleep 5; done; }'
deny 'echo \"$(while true; do sleep 5; done)\"'
deny "sh -c ${Q}while true; do sleep 5; done${Q}"
deny 'sh <<EOF\nwhile true; do sleep 5; done\nEOF'
exit 0
