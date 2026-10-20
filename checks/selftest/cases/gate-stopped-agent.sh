#!/bin/sh
# Purpose: selftest case — a stopped run still owns its live agents (v0.26.10.3 R8, R10; §5 gate-stopped-agent). A run
# at its home with `plan: required`, the develop stage open and `run: stopped owner asked to pause`, and three linked
# checkouts: A (branch vid/t1, a .vid/home marker, its agent a1 live — agent-start and agent-brief naming a brief whose
# branch: is vid/t1), B (branch vid/t2, a .vid/home marker, its agent a2 ended by its build-cost) and C (branch
# worktree-agent-a3, no marker, agent a3 live). Convicts unless: A reads the gate `on <home>`; B reads it off; the home
# reads it off; C reads it on (discovery finds the stopped run's home for a bound checkout); and, once a3 has stopped,
# `test.sh wait` in C — no marker, no gate — still finds a ticket at the home and reports it, adding "the run is stopped";
# a complete run is off in A. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "gate-stopped-agent: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
utcnow() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
mkdir -p "$T/home/checks" && cd "$T/home" && git init -q
cp "$CHECKS/plan.sh" "$CHECKS/testenv.sh" "$CHECKS/test.sh" checks/
printf '.vid/\n' > .gitignore; g add -A; g commit -qm root
H=$(pwd -P)
mkdir -p .vid/briefs/1
printf 'run: stopped owner asked to pause\nsession: S1\nplan: required\n' > .vid/RUN-STATE.md
printf 'role: builder    slice: 1\nquoted-at: x\ntry: 1-builder-1\nbranch: vid/t1\n' > .vid/briefs/1/builder-1.md
{ printf 'stage name=develop state=start session=S1 records=23 at=%s\n' "$(utcnow)"
  printf 'agent-start session=S1 agent=a1 type=vid:builder transcript=- at=%s\n' "$(utcnow)"
  printf 'agent-brief agent=a1 brief=.vid/briefs/1/builder-1.md at=%s\n' "$(utcnow)"
  printf 'agent-start session=S1 agent=a2 type=vid:builder transcript=- at=%s\n' "$(utcnow)"
  printf 'build-cost role=builder agent=a2 brief=.vid/briefs/1/builder-2.md at=%s\n' "$(utcnow)"
  printf 'agent-start session=S1 agent=a3 type=vid:builder transcript=- at=%s\n' "$(utcnow)"; } > .vid/metrics-events
g worktree add -q "$T/A" -b vid/t1 2>/dev/null; g worktree add -q "$T/B" -b vid/t2 2>/dev/null; g worktree add -q "$T/C" -b worktree-agent-a3 2>/dev/null
for w in A B; do mkdir -p "$T/$w/.vid"; printf '%s\n' "$H" > "$T/$w/.vid/home"; done
gate() { (cd "$1" && sh checks/plan.sh gate > "$T/out" 2>&1); }
gate "$T/A" || fail 'the checkout bound to a live agent reads the gate off'
grep -qx "on $H" "$T/out" || fail "A's gate does not name the home: $(cat "$T/out")"
gate "$T/B" && fail 'an old worktree with only .vid/home reads the gate on'
gate "$H" && fail 'the home of a stopped run reads the gate on'
gate "$T/C" || fail 'a markerless checkout bound by its worktree-agent name reads the gate off'
grep -qx "on $H" "$T/out" || fail "C's gate does not name the home: $(cat "$T/out")"
# a ticket at the home, finished; a3 stops; C, with no marker and no gate, still finds it
TK=20261019T120000Z-ab12; mkdir -p ".vid/requests/$TK"
printf 'type=iterate\nestimate=10\nsilence=1200\nstartup=3600\nlimit=86400\ncreated=%s\n' "$(date +%s)" > ".vid/requests/$TK/request"
printf 'status=0 ran-to-end=yes capped=no report=r1\ncases passed=3\n' > ".vid/requests/$TK/result"; echo 0 > ".vid/requests/$TK/exit"; echo done > ".vid/requests/$TK/state"
printf 'agent-stop session=S1 agent=a3 type=vid:builder transcript=- at=%s\n' "$(utcnow)" >> .vid/metrics-events
gate "$T/C" && fail 'C still reads the gate on after its agent stopped'
(cd "$T/C" && VID_WAIT_MAX=5 sh checks/test.sh wait "$TK" > "$T/out" 2>&1) || fail "wait in C did not report the finished ticket: $(cat "$T/out")"
grep -qx 'cases passed=3' "$T/out" || fail 'wait in C did not print the ticket result'
grep -qx 'the run is stopped' "$T/out" || fail 'wait does not say the run is stopped'
sed 's/^run: .*/run: complete/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
gate "$T/A" && fail 'a complete run reads the gate on in a bound checkout'
exit 0
