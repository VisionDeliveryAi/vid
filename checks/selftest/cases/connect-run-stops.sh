#!/bin/sh
# Purpose: selftest case — the run's start keeps a stop the owner made (GM-4 F2; connect.sh start --run's run state). On the
# GitHub auto toy (fixtures/manual.sh): with RUN-STATE's `run: stopped owner asked to pause`, connect.sh start --run leaves that
# line as it was and records no `run state=active`; with `run: stopped owner asked to hold after stage 1` and stage 1's
# stage-closed line in .vid/tw/handed, the same; with that hold and no stage-closed line for its stage (the stage not closed
# yet), the start writes run: active and records `run state=active`. Each start still opens the run's stage. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -f "$T/p/.vid/observer.pid"; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "connect-run-stops: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
actives() { cat .vid/metrics-events 2>/dev/null | grep -c '^run state=active' || true; }
runs() { cat .vid/metrics-events 2>/dev/null | grep -c '^stage name=run state=start ' || true; }
start_run() { RC=0; VID_OBSERVE_INTERVAL=2 CLAUDE_CODE_SESSION_ID=sess-stop sh "$CHECKS/connect.sh" start --run > "$T/out" 2>&1 || RC=$?; }
end_run() { sh "$CHECKS/connect.sh" end > "$T/end" 2>&1 || { cat "$T/end" > "$T/out"; fail 'the end exited non-zero'; }; rm -f .vid/observer.pid; }
mn_project "$T/p"; gh repo create owner/vid-state --private > /dev/null
printf 'setup-answered key=github-mode value="auto" words="DevAgent works them" at=2026-11-03T10:00:00Z\n' >> .vid/plan/setup
check() { # <run line> <stage 1 closed: 1 or empty> <kept: 1 or empty> <what>
  printf 'mode: tickets\nplan: required\n%s\n' "$1" > .vid/RUN-STATE.md
  if [ -n "$2" ]; then printf 'stage-closed 1 | stand-in: RM at %s candidate 1 at=2026-11-03T11:00:00Z\n' "$AP" > .vid/tw/handed; else rm -f .vid/tw/handed; fi
  A=$(actives); S=$(runs); start_run; [ "$RC" = 0 ] || fail "$4: the run's start exited $RC"
  [ "$(runs)" = $((S + 1)) ] || fail "$4: the run's start did not open the run's stage"
  if [ -n "$3" ]; then
    grep -qx "$1" .vid/RUN-STATE.md || fail "$4: the run's start did not keep '$1' (RUN-STATE: $(grep '^run:' .vid/RUN-STATE.md))"
    ! grep -qx 'run: active' .vid/RUN-STATE.md || fail "$4: the run's start wrote run: active"
    [ "$(actives)" = "$A" ] || fail "$4: the run's start recorded run state=active"
  else
    grep -qx 'run: active' .vid/RUN-STATE.md || fail "$4: the run's start did not write run: active (RUN-STATE: $(grep '^run:' .vid/RUN-STATE.md))"
    [ "$(actives)" = $((A + 1)) ] || fail "$4: the run's start did not record run state=active once"
  fi
  end_run; }
check 'run: stopped owner asked to pause' '' 1 'a pause the owner asked for'
check 'run: stopped owner asked to hold after stage 1' 1 1 'a hold after stage 1, stage 1 closed'
check 'run: stopped owner asked to hold after stage 1' '' '' 'a hold after stage 1, stage 1 not closed'
echo 'connect-run-stops: ok'
