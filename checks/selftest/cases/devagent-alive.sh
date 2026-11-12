#!/bin/sh
# Purpose: selftest case — one command says whether the dev side is alive (0.26.10.28.8, R5): dm.sh list. In a work folder whose loop and
# whose dev manager live, each a process this case starts and stamps as up and start do, list names the loop's pid and its minutes, and the
# dev manager, beside what it showed before; with the loop gone it says `loop: not running`, and a dead dev manager is not named alive.
# Nothing is started or written by list. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
RT=$(cd "$CHECKS/.." && pwd -P); [ -d "$RT/devagent" ] || { echo 'needs devagent/'; exit 77; }
DM=$RT/devagent/dev-manager/dm.sh; RUN=$RT/devagent/test-manager/run.sh
T=$(mktemp -d); P1=''; P2=''; trap '[ -z "$P1" ] || kill "$P1" 2>/dev/null || true; [ -z "$P2" ] || kill "$P2" 2>/dev/null || true; rm -rf "$T"' EXIT
fail() { echo "devagent-alive: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
W=$T/work; mkdir -p "$W/agents/dev-manager-1"; DM_WORK=$W; export DM_WORK
DM_WORK=$W sh "$DM" list > "$T/out" 2>&1 || fail 'list failed'; grep -qx 'loop: not running' "$T/out" && grep -qx none "$T/out" || fail 'an empty work folder is not said as no loop, nothing'
# a live loop, recorded as up records it, and a live dev manager, recorded as start records it
sleep 120 & P1=$!; { echo "$P1"; sh "$RUN" stamp "$P1"; } > "$W/dm-loop.pid"; echo $(($(date +%s) - 180)) > "$W/dm-loop.start"
sleep 120 & P2=$!; A=$W/agents/dev-manager-1; echo "$P2" > "$A/pid"; sh "$RUN" stamp "$P2" > "$A/lstart"; echo $(($(date +%s) - 60)) > "$A/start"; : > "$A/log"; echo DM > "$A/role"; echo - > "$A/ticket"
( cd "$W" && find . -type f | LC_ALL=C sort | xargs cksum ) > "$T/before"
sh "$DM" list > "$T/out" 2>&1 || fail 'list failed with a live loop'
grep -qx "loop: alive, pid $P1, for 3 min" "$T/out" || fail "the live loop is not named with its pid and minutes"
grep -qx 'dev manager: dev-manager-1, alive, for 1 min' "$T/out" || fail 'the live dev manager is not named'
( cd "$W" && find . -type f | LC_ALL=C sort | xargs cksum ) > "$T/after"; cmp -s "$T/before" "$T/after" || fail 'list wrote in the work folder'
# the loop gone, the dev manager gone
kill "$P1"; wait "$P1" 2>/dev/null || true; P1=''; kill "$P2"; wait "$P2" 2>/dev/null || true; P2=''
sh "$DM" list > "$T/out" 2>&1 || fail 'list failed with the loop gone'; grep -qx 'loop: not running' "$T/out" || fail 'a gone loop is not said as not running'
! grep -q '^dev manager: ' "$T/out" || fail 'a dead dev manager is named alive'
echo 'devagent-alive: ok'
