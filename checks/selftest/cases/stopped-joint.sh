#!/bin/sh
# Purpose: selftest case — the joint case of 0.26.10.28.6 (its merge point): the dev side's real stopped report, read by ViD's real wait and
# step. On TW's toy and the fake gh, ViD's round waits with nothing new; devagent/dev-manager/dm.sh loops on the same code repository with
# nothing open until its time limit, and pushes its stopped report; ViD's next wait ends `new`, and its step raises
# `flag devagent-stopped stopped-1: <the stop's own words>`, the words dm.sh wrote in its report. Skips where devagent/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
DM=$CHECKS/../devagent/dev-manager/dm.sh; FC_MODEL0=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); export FC_MODEL0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "stopped-joint: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat "$T/work/dm-report.txt" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $* failed ($RC)"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd step; VID_WAIT_TICK=1 VID_WAIT_MAX=2 rd wait; grep -qx timeout "$T/out" || fail 'a wait with nothing new did not time out'
# the dev side, in its own work folder on the same code repository, nothing open, stops at its time limit
W=$T/work; mkdir -p "$W/tickets"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/fc"; printf "{\\"type\\":\\"system\\",\\"subtype\\":\\"init\\",\\"model\\":\\"%%s\\"}\\n" "$FC_MODEL0"\nprintf "{\\"type\\":\\"result\\",\\"subtype\\":\\"success\\",\\"is_error\\":false,\\"num_turns\\":1,\\"result\\":\\"done\\"}\\n"\n' "$T" > "$T/bin/claude"; chmod +x "$T/bin/claude"
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 4\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/note.txt"
( cd "$W" && DM_WORK=$W DM_TICK=1 DM_IDLE=3 DM_IDLE_TICK=2 DM_FIRST=5 sh "$DM" loop "$W/note.txt" ) > "$T/dm.out" 2>&1 || true
git -C "$T/code.git" rev-parse -q --verify refs/heads/vid-results/stopped-1 > /dev/null || { cat "$T/dm.out" >&2; fail 'dm.sh pushed no stopped report'; }
WHY=$(git -C "$T/code.git" show refs/heads/vid-results/stopped-1:stopped-1/results.txt | sed -n 's/^stopped: //p'); [ -n "$WHY" ] || fail 'the stopped report gives no reason'
# ViD's round: the wait ends new, the step flags the stop in dm.sh's own words
VID_WAIT_TICK=1 VID_WAIT_MAX=5 rd wait; grep -qx new "$T/out" || fail "dm.sh's stopped report did not end ViD's wait: $(cat "$T/out")"
rd step; grep -qxF "flag devagent-stopped stopped-1: $WHY" "$T/out" || fail "ViD's step did not flag dm.sh's stop as '$WHY': $(grep flag "$T/out")"
echo 'stopped-joint: ok'
