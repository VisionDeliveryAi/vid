#!/bin/sh
# Purpose: selftest case — one start and end for every caller, in both modes (GM-4 F2, its case connect-shared). Read: no script
# of the connect's lane (plan.sh, land.sh, replan.sh, mode.sh) opens a stage of its own or makes the spec repository itself; no
# script runs the run's start (connect.sh start --run, /vid run's alone); one record of the refresh no. On the GitHub manual toy
# (fixtures/manual.sh): in GitHub manual with no state-repo: line the start refuses, naming the setting, with nothing restored
# or taken (GM M15); with it, connect.sh start makes the spec repository the log does not name, restores, copies the read the
# call before ended with to .vid/round/read.prev, takes the lock, checks access, opens the call's stage once (plan.sh gate on)
# and is ready; its end ends that stage, saves and frees the lock. In GitHub auto the start prints the same steps in the same
# order. The run's start (--run) is refused in GitHub manual before anything else, with nothing refreshed, written or changed in
# the folder, no lock taken and no run stage; a start refused for its mode (outside ticket mode) or at the lock (another
# session's) refreshes nothing and leaves the folder as it was (F2's order: the mode, the spec repository, the restore, the lock,
# then the refresh); in GitHub auto it opens the
# run's stage in place of the call's, writes run: active and the session, and starts the watcher. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "connect-shared: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
C() { RC=0; sh "$CHECKS/connect.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
steps() { sed -n 's/^connect \([a-z-]*\)[: ].*/\1/p; s/^connect: ready$/ready/p' "$T/out" | uniq | grep -vx spec-repo; }   # the spec repository is made once, by the first start
opens() { grep -c '^stage name=replan state=start ' .vid/metrics-events 2>/dev/null || true; }
# read: one opener, one maker of the spec repository, one caller of the run's start, one record of the refresh no
for s in plan land replan mode; do grep -n 'state=start' "$CHECKS/$s.sh" | grep -v '^[0-9]*:[[:space:]]*#' | grep 'stage name=' > "$T/out" && fail "$s.sh opens a stage of its own (above)"; done
grep -n 'spec-setup' "$CHECKS/mode.sh" | grep -v '^[0-9]*:[[:space:]]*#' > "$T/out" && fail 'mode.sh makes the spec repository itself, not through the connect (above)'
grep -n 'connect\.sh"* start[^"]*--run' "$CHECKS"/*.sh | grep -v '^[^:]*:[0-9]*:[[:space:]]*#' > "$T/out" && fail 'a script runs the run'"'"'s start (above)'
grep -ln 'needs the refresh' "$CHECKS"/*.sh | grep -v '/connect\.sh$' > "$T/out" && fail 'a second record of the refresh no (above)'
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
gh repo create owner/vid-state --private > /dev/null
# GM M15: no state-repo: line in GitHub manual, nothing restored or taken
grep -v '^state-repo:' .vid/tw/settings > "$T/s"; cp .vid/tw/settings "$T/s0"; cat "$T/s" > .vid/tw/settings
C start; [ "$RC" = 1 ] || fail "in GitHub manual with no state-repo: the start exited $RC, not 1"
grep -q 'state-repo:' "$T/out" || fail 'the refusal does not name the state-repo: setting'
grep -q '^connect \(records\|lock\):' "$T/out" && fail 'with no state-repo: the start restored or took the lock'
[ -z "$(mn_lock)" ] || fail 'with no state-repo: a lock is held'
cat "$T/s0" > .vid/tw/settings
# GitHub manual: the whole start, then the end
mkdir -p .vid/round; printf 'issue\t9\tthe read the call before ended with\n' > .vid/round/read
K=$(opens); C start; [ "$RC" = 0 ] || fail "in GitHub manual the start exited $RC"
steps > "$T/sm"; grep -qx ready "$T/sm" || fail 'the start did not say ready'
grep -q '^spec-repo owner/code-spec ' .vid/tw/log || fail 'the start did not make the spec repository the log does not name'
cmp -s .vid/round/read .vid/round/read.prev || fail "the read the call before ended with was not copied to .vid/round/read.prev"
[ "$(opens)" = $((K + 1)) ] || fail 'the start did not open the call'"'"'s stage once'
sh "$CHECKS/plan.sh" gate > /dev/null 2>&1 || fail 'after the start the gate is off'
[ -n "$(mn_lock)" ] || fail 'after the start no lock is held'
C end; [ "$RC" = 0 ] || fail "the end exited $RC"
grep -q '^stage name=replan state=end ' .vid/metrics-events || fail 'the end did not end the call'"'"'s stage'
[ -z "$(mn_lock)" ] || fail 'after the end the lock is held'
# --run in GitHub manual: refused, nothing taken
tree() { find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done; git for-each-ref; }
tree > "$T/t0"; C start --run; [ "$RC" = 1 ] || fail "in GitHub manual the run's start exited $RC, not 1"
! grep -q '^connect \(refresh\|records\|spec-repo\|read\|lock\)' "$T/out" || fail "the run's start in GitHub manual went past the mode before refusing"
tree > "$T/t1"; cmp -s "$T/t0" "$T/t1" || { diff "$T/t0" "$T/t1" > "$T/out" || :; fail "the run's start refused in GitHub manual changed the folder (above)"; }
grep -q '/vid next' "$T/out" || fail "the run's start in GitHub manual does not name /vid next"
[ -z "$(mn_lock)" ] || fail "the run's start refused in GitHub manual left a lock held"
grep -q '^stage name=run ' .vid/metrics-events && fail "the run's start refused in GitHub manual opened the run's stage"
# GM-4 F2's order (the mode, the spec repository, the restore, the lock, then the refresh): a start refused at the mode or at the
# lock refreshes nothing and leaves the folder as it was
cp .vid/RUN-STATE.md "$T/rs0"; sed 's/^mode:.*/mode: develop/' "$T/rs0" > .vid/RUN-STATE.md
tree > "$T/t0"; C start; [ "$RC" = 1 ] && grep -q 'not in ticket mode' "$T/out" || fail "a start outside ticket mode was not refused for its mode ($RC)"
! grep -q '^connect refresh' "$T/out" || fail 'a start refused for its mode refreshed checks/ first'
tree > "$T/t1"; cmp -s "$T/t0" "$T/t1" || { diff "$T/t0" "$T/t1" > "$T/out" || :; fail 'a start refused for its mode changed the folder (above)'; }
cat "$T/rs0" > .vid/RUN-STATE.md
CLAUDE_CODE_SESSION_ID=other-session sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'another session could not take the lock'
tree > "$T/t0"; RC=0; CLAUDE_CODE_SESSION_ID=this-session sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q '^connect lock: not taken' "$T/out" || fail "a start under another session's lock was not refused at the lock ($RC)"
! grep -q '^connect refresh' "$T/out" || fail "a start under another session's lock refreshed checks/ first"
tree > "$T/t1"; cmp -s "$T/t0" "$T/t1" || { diff "$T/t0" "$T/t1" > "$T/out" || :; fail "a start under another session's lock changed the folder (above)"; }
CLAUDE_CODE_SESSION_ID=other-session sh "$CHECKS/github.sh" lock-free > "$T/out" 2>&1 || fail 'the other session could not free its lock'
# GitHub auto: the same steps
printf 'setup-answered key=github-mode value="auto" words="DevAgent works them" at=2026-11-03T10:00:00Z\n' >> .vid/plan/setup
C start; [ "$RC" = 0 ] || fail "in GitHub auto the start exited $RC"
steps > "$T/sa"; cmp -s "$T/sm" "$T/sa" || { paste "$T/sm" "$T/sa" >&2; fail 'the start in GitHub auto took other steps than in GitHub manual (manual, then auto, above)'; }
C end; [ "$RC" = 0 ] || fail "in GitHub auto the end exited $RC"
# --run in GitHub auto: the run's stage, the run state, the watcher
K=$(opens); RC=0; VID_OBSERVE_INTERVAL=2 CLAUDE_CODE_SESSION_ID=sess-run sh "$CHECKS/connect.sh" start --run > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "in GitHub auto the run's start exited $RC"
grep -q '^stage name=run state=start session=sess-run ' .vid/metrics-events || fail "the run's start did not open the run's stage"
[ "$(opens)" = "$K" ] || fail "the run's start opened the call's stage too"
grep -qx 'run: active' .vid/RUN-STATE.md && grep -qx 'session: sess-run' .vid/RUN-STATE.md || fail "the run's start did not write run: active and the session"
grep -q 'watcher \(started\|running\)' "$T/out" || fail "the run's start did not start the watcher"
C end; rm -f .vid/observer.pid
echo 'connect-shared: ok'
