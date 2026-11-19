#!/bin/sh
# Purpose: selftest case — admission under ticket mode reads the handed records, never evidence (v0.26.10.9 spec R9,
# R15; re-pointed by v0.26.10.12.3 R6: the old `ticket … state=done` plants are handed closed
# steps and row states). The toy staged product (fixtures/stages.sh) with RUN-STATE `mode: tickets` in a replan
# session, its plan recorded: steps A (ROW-001) → B (ROW-002) in stage 1, C (ROW-004, stage 2) building on A, and
# checks/evidence.sh a stub that fails, leaving a mark, if run. A is admitted; B is refused (by=rule-B) while A is not
# closed and its row is accepted or failing, and admitted after `closed A`. Again with A's row failing, then held:
# B is admitted once A's rows are held, though A is not closed. C, a stage-2 step, is refused in stage 1 (by=stage).
# evidence.sh is never called. 0.26.11.1.2 (R6): planner.sh and lib.sh beside plan.sh, as in a project, since the admission now refuses a
# plan whose rows cannot be read. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "admission-tickets: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
toy() { rm -rf "$1"; mkdir -p "$1/checks" "$1/.vid"; cd "$1"; git init -q
  cp "$CHECKS/plan.sh" "$CHECKS/planner.sh" "$CHECKS/lib.sh" "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
  printf '#!/bin/sh\n# Purpose: a stub that must never run\n: > "%s/evidence-called"\nexit 1\n' "$T" > checks/evidence.sh
  st_files; printf '.vid/\n' > .gitignore; g add -A && g commit -qm root
  printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n\n## The plan\n\n```vid-plan\nstep A | name: sign in | modules: app/login | builds-on: - | rows: ROW-001\nstep B | name: notes | modules: app/notes | builds-on: A | rows: ROW-002\nstep C | name: sharing | modules: app/share | builds-on: A | rows: ROW-004\nshared: -\n```\n' > .vid/RUN-STATE.md
  printf 'stage name=replan state=start session=S1 records=29 at=2026-10-24T10:00:00Z\n' > .vid/metrics-events
  sh checks/plan.sh change create 'the plan' --trigger initial --expect 'A first' > "$T/out" 2>&1 || fail 'the plan was not recorded'
  sh checks/plan.sh start A > "$T/out" 2>&1 || fail 'A, building on nothing, was refused'; }
hd() { mkdir -p .vid/tw; printf '%s | stand-in: the self-test\n' "$1" >> .vid/tw/handed; }
refusedB() { if sh checks/plan.sh start B > "$T/out" 2>&1; then fail "B was admitted $1"; fi
  grep -q 'rule B (tickets)' "$T/out" && grep -q 'builds on A, which is not closed, and its rows ROW-001 are not owed' "$T/out" || fail "the refusal $1 does not name A and its row"
  tail -n 1 .vid/metrics-events | grep -q '^refused phase=admission by=rule-B .* step=B ' || fail "the refusal $1 is not recorded by=rule-B"; }
toy "$T/r1"
refusedB 'with A started only'
hd 'row ROW-001 accepted'; refusedB "with A's row accepted, A not closed"
hd 'closed A'; sh checks/plan.sh start B > "$T/out" 2>&1 || fail "B was refused after A was closed"
grep -q '^step-start step=B ' .vid/metrics-events || fail 'no step-start for B'
toy "$T/r2"
hd 'row ROW-001 accepted'; hd 'row ROW-001 failing'; refusedB "with A's row failing after it was accepted"
hd 'row ROW-001 held'; sh checks/plan.sh start B > "$T/out" 2>&1 || fail "B was refused with A's rows held"
if sh checks/plan.sh start C > "$T/out" 2>&1; then fail 'C, a stage-2 step, was admitted in stage 1'; fi
tail -n 1 .vid/metrics-events | grep -q '^refused phase=admission by=stage .* step=C ' || fail 'C was not refused by=stage'
[ ! -e "$T/evidence-called" ] || fail 'checks/evidence.sh was called under mode: tickets'
exit 0
