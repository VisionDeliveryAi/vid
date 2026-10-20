#!/bin/sh
# Purpose: selftest case — rules 1 and 2 of the home lookup keep precedence
# over discovery (v0.9.7.0.1 spec 3.1, R3; §6 A-4). With a live run in the
# main checkout: a worktree whose own RUN-STATE is stopped stays off (its
# test run takes the lock, ungated); a worktree whose valid .vid/home names
# a stopped run stays off too — the link wins over the live run found
# among the checkouts; an unrelated repository stays off. v0.26.10.3 (R8): both stay off because no live agent of
# the stopped run is bound to their branch; the bound case is gate-stopped-agent's. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "home-precedence: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/main"; gate_on
g worktree add -q "$T/S" -b s 2>/dev/null
g worktree add -q "$T/L" -b l 2>/dev/null
# rule 1: its own stopped run
cd "$T/S"; mkdir -p .vid; gate_on 'stopped owner asked to pause'; SP=$(pwd -P)
if sh checks/plan.sh gate > "$T/out" 2>&1; then fail 'a worktree with its own stopped run found the live one'; fi
grep -q '^off run: stopped' "$T/out" || fail 'the gate does not read its own stopped run'
sh checks/test.sh -- x > "$T/out" 2>&1 || fail 'the ungated run failed'
tail -n 1 .vid/metrics-events | grep -q ' run=' && fail 'the run with its own stopped run was gated'
[ -n "$(ls .vid/ledger-results | grep -E '\.live\.sel-[0-9]+\.xml$')" ] || fail 'no local receipt'
# rule 2: a valid .vid/home to a stopped run
cd "$T/L"; mkdir -p .vid; printf '%s\n' "$SP" > .vid/home
[ "$(sh checks/plan.sh home-of)" = "$SP" ] || fail 'home-of does not follow .vid/home'
if sh checks/plan.sh gate > "$T/out" 2>&1; then fail 'a valid .vid/home lost to discovery'; fi
grep -q '^off run: stopped' "$T/out" || fail 'the gate does not read the linked stopped run'
# an unrelated repository
mkdir -p "$T/other"; cd "$T/other"; git init -q; mkdir checks; cp "$CHECKS/plan.sh" checks/
RC=0; sh checks/plan.sh gate > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] && grep -q '^off no run here' "$T/out" || fail "an unrelated repository is not off (exit $RC)"
RC=0; sh checks/plan.sh home-of > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] || fail "home-of in an unrelated repository exited $RC, not 1"
exit 0
