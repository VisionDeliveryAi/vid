#!/bin/sh
# Purpose: selftest case — `plan.sh admit <step>` (GM-4 K1, J3): whether a step may start, read only, as `plan.sh start` would
# judge it now, then the step's publish warnings (plan.sh warnings, J2). On the ticket writer's toy (fixtures/tw-toy.sh) in a
# planning sitting, GitHub auto: S01, not started, prints `admit S01 ok …`, exit 0, and records nothing (no step-start, no file of
# .vid/ and not git's index changed); once started, `ok` saying it is started. S05, of stage 2 while stage 0 is current, prints
# `admit S05 held …` naming the stage rule, exit 3, and no refusal is recorded. In GitHub manual S05 is `ok` with no hold, its
# warning lines after its line exactly as plan.sh warnings S05 prints them (two open tickets against open-tickets: 2). A step the
# plan lacks is held, exit 3; `admit` with no step is a usage error, exit 2. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "plan-admit-dry: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
A() { RC=0; sh "$CHECKS/plan.sh" admit "$@" > "$T/out" 2> "$T/err" || RC=$?; }
snap() { { find .vid -type f | sort | while read -r f; do cksum "$f"; done; cksum .git/index; } > "$1"; }
ev() { printf '%s at=%s\n' "$1" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; }
starts() { grep -c "^step-start step=$1 " .vid/metrics-events || true; }
refusals() { grep -c '^refused phase=admission ' .vid/metrics-events || true; }
tw_toy "$T/toy"; mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/   # the stage rule reads them at the home
git status --porcelain > /dev/null 2>&1 || :   # the index as git keeps it, before the snapshots
snap "$T/s0"
A S01; [ "$RC" = 0 ] || { cat "$T/err" >&2; fail "admit S01 exited $RC"; }
head -n 1 "$T/out" | grep -q "^admit${TB}S01${TB}ok${TB}." || fail "admit S01 does not open with its ok line: $(head -n 1 "$T/out")"
[ "$(starts S01)" = 0 ] || fail 'admit recorded a step-start'
snap "$T/s1"; cmp -s "$T/s0" "$T/s1" || { diff "$T/s0" "$T/s1" >&2 || :; fail 'admit wrote a file (.vid or the index)'; }
tw_start S01; [ "$(starts S01)" = 1 ] || fail 'the skeleton S01 was not started'
A S01; [ "$RC" = 0 ] && grep -q "^admit${TB}S01${TB}ok${TB}.*already started" "$T/out" || fail "admit on the started S01 is not ok, started ($RC)"
R0=$(refusals); snap "$T/s2"
A S05; [ "$RC" = 3 ] || fail "admit S05, of stage 2, exited $RC, not 3 (held)"
grep -q "^admit${TB}S05${TB}held${TB}.*holds rows outside stages" "$T/out" || fail 'admit S05 is not held by the stage rule'
[ "$(refusals)" = "$R0" ] && [ "$(starts S05)" = 0 ] || fail 'the held admit recorded a refusal or a start'
snap "$T/s3"; cmp -s "$T/s2" "$T/s3" || fail 'the held admit wrote a file'
A S99; [ "$RC" = 3 ] && grep -q "^admit${TB}S99${TB}held${TB}.*no step S99" "$T/out" || fail "a step the plan lacks is not held ($RC)"
A; [ "$RC" = 2 ] || fail "admit with no step was not a usage error ($RC)"
# GitHub manual: no hold, the warnings after the line
git rev-parse HEAD > .vid/tw/applied
printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=github-mode value="manual" words="by hand" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
ev 'stage name=plan state=start session=S2 records=29'
mkdir -p .vid/round; { printf 'published 7 kind=step step=S02 rows=ROW-001 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-01T09:00:00Z\n'
  printf 'published 8 kind=step step=S03 rows=ROW-006 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-01T09:00:00Z\n'; } >> .vid/tw/log
printf 'ticket\t7\tOPEN\tsomeone\t2026-11-01T09:00:00Z\nticket\t8\tOPEN\tsomeone\t2026-11-01T09:00:00Z\n' > .vid/round/read
sh "$CHECKS/plan.sh" warnings S05 > "$T/w" 2>&1 || fail "plan.sh warnings S05 failed: $(cat "$T/w")"
grep -q "^warning${TB}publish${TB}S05${TB}limit${TB}" "$T/w" || fail 'the scene gives S05 no limit warning'
snap "$T/s4"; A S05; [ "$RC" = 0 ] || { cat "$T/err" >&2; fail "in GitHub manual admit S05 exited $RC"; }
head -n 1 "$T/out" | grep -q "^admit${TB}S05${TB}ok${TB}.*no hold" || fail "in GitHub manual admit S05 is not ok with no hold: $(head -n 1 "$T/out")"
sed 1d "$T/out" > "$T/aw"; cmp -s "$T/aw" "$T/w" || { diff "$T/w" "$T/aw" >&2 || :; fail "admit's warnings are not plan.sh warnings', line for line"; }
[ "$(starts S05)" = 0 ] || fail 'admit in GitHub manual recorded a start'
snap "$T/s5"; cmp -s "$T/s4" "$T/s5" || fail 'admit in GitHub manual wrote a file'
echo 'plan-admit-dry: ok'
