#!/bin/sh
# Purpose: selftest case — PL stays in its lane, P8 (v0.26.10.12.2.1 R7, R9; v0.26.10.12.2.2:
# planner.sh reads the plan-change events, so "writes no event" is an event.sh call or a >> into metrics-events).
# skills/vid-plan/SKILL.md names no `github.sh` but `sh checks/github.sh access`, no `ticket.sh`, `gh`, `.vid/code` or test path,
# and checks/planner.sh calls none of them and writes no event; copies with each planted are convicted. Also the
# review pass's checker (skills/vid-plan/selftest/pass-check.sh) acquits each calibration fixture's expected output
# (the rows ViD appended) and convicts silence, an extra finding and an empty output. The skill parts are skipped where
# skills/ is absent (a project). v0.26.10.12.3.2 (R1): the foreground sentence in the split step, the needs pass and the review. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-scope: $*" >&2; exit 1; }
out() { grep -n -e 'github\.sh' -e 'ticket\.sh' -e '\.vid/code' "$1" || true; grep -nw 'gh' "$1" || true
  grep -nE '(^|[^a-z])tests?/|test_[a-z]|[._]test\.' "$1" || true; }
[ -z "$(out "$CHECKS/planner.sh")" ] || fail 'planner.sh names a GitHub call, a code read or a test path'
wr() { grep -nE 'event\.sh|>>[[:space:]]*"?[^ ]*metrics-events' "$1"; }
wr "$CHECKS/planner.sh" && fail 'planner.sh writes an event'
# 0.26.11.1.3 (GM-1 S3, S4): beside its settings, the applied version (.vid/tw/applied) and the rows to place (.vid/tw/to-place), GitHub manual's
[ "$(grep -o '\.vid/tw/[a-z-]*' "$CHECKS/planner.sh" | sort -u | tr '\n' ' ')" = '.vid/tw/applied .vid/tw/settings .vid/tw/to-place ' ] || fail 'planner.sh reads more of .vid/tw/ than its settings, the applied version and the rows to place'
{ cat "$CHECKS/planner.sh"; echo 'printf x >> .vid/metrics-events'; } > "$T/p.sh"; wr "$T/p.sh" > /dev/null || fail 'a planted write into metrics-events is not convicted'
SK="$CHECKS/../skills/vid-plan"
[ -d "$SK" ] || { echo 'needs skills/vid-plan/'; exit 77; }
grep -q 'sh checks/github\.sh access' "$SK/SKILL.md" || fail 'vid-plan does not run the access check'   # v0.26.10.12.3.1 (R6): its one GitHub read
sed 's|sh checks/github\.sh access||g' "$SK/SKILL.md" > "$T/sk"; out "$T/sk" > "$T/o"; [ ! -s "$T/o" ] || { cat "$T/o" >&2; fail 'vid-plan names a GitHub call, a code read or a test path'; }
for p in 'then gh issue create' 'sh checks/github.sh publish' 'sh checks/ticket.sh body' 'git -C .vid/code fetch' 'a test under tests/acceptance'; do
  { cat "$T/sk"; echo "$p"; } > "$T/s.md"; [ -n "$(out "$T/s.md")" ] || fail "a planted \"$p\" is not convicted"
done
S='Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.'
for h in 'With `split: fine`' "Every row's needs" 'Spawn a fresh agent'; do awk -v RS= -v h="$h" 'index($0, h)' "$SK/SKILL.md" | tr '\n' ' ' | grep -qF "$S" || fail "the foreground sentence is not beside: $h"; done
[ "$(tr '\n' ' ' < "$SK/SKILL.md" | grep -oF "$S" | grep -c .)" = 3 ] || fail 'the foreground sentence is not in exactly three places'
grep -q 'ScheduleWakeup' "$SK/SKILL.md" && fail 'vid-plan names ScheduleWakeup'
C="$SK/selftest"
printf 'none\n' > "$T/none"; printf 'finding ROW-021 | 1: vague\n' > "$T/hit"; printf 'finding ROW-021 | v\nfinding RULE-005 | x\n' > "$T/two"; : > "$T/empty"
pc() { sh "$C/pass-check.sh" "$C/fixtures/$1" "$T/$2" > /dev/null 2>&1; }
pc clean-plan none && pc vague-fail-if hit || fail 'the checker convicts an expected output'
if pc clean-plan hit || pc vague-fail-if none || pc vague-fail-if two || pc clean-plan empty; then fail 'the checker acquits a wrong output'; fi
exit 0
