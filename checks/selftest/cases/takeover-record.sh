#!/bin/sh
# Purpose: selftest case — a takeover is recorded, visible, and ends by the next step (v0.9.7.1 spec 3.9a, R14). The
# plan fixture for progress; the observer fixture for the notice. Convicts unless, with `takeover started
# reason=collision scope=both` recorded and no `takeover ended`, progress prints a Takeover line naming the reason
# and scope; once a step started after it the observer gives one notice that the takeover is still open, and none
# before; and after `takeover ended fix=…` neither the line nor a new notice appears. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "takeover-record: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; cp "$CHECKS/plan.sh" checks/; rows s1 1 2; commit_all rows
plan 'step S1 | name: one | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one' --trigger initial --expect x > /dev/null
sh checks/event.sh 'takeover started reason=collision scope=both' > /dev/null
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep -q '^| Takeover | open — reason=collision scope=both (since ' "$T/out" || fail "no Takeover line: $(grep -c Takeover "$T/out")"
sh checks/event.sh 'takeover ended fix=the ledger home repaired' > /dev/null
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep -q '^| Takeover' "$T/out" && fail 'an ended takeover still shows'
# the observer: told once a step started after an open takeover
mkdir -p "$T/obs"; cd "$T/obs"; CASE=takeover-record
. "$CHECKS/selftest/fixtures/observer-lib.sh"
reset; rs active; sleep 300 & P=$!; trap 'kill $P 2>/dev/null; rm -rf "$T"' EXIT
ev 'takeover started reason=collision scope=tests' "$(ago 30)"
hb "$(ago 5)" 'working'
tick; [ "$(nnote 'took over the builders')" -eq 0 ] || fail 'told before the next step started'
ev 'step-start step=S2 plan=x base=y' "$(ago 10)"
tick; [ "$(nnote 'took over the builders')" -eq 1 ] || fail 'not told at the next step'
tick; [ "$(nnote 'took over the builders')" -eq 1 ] || fail 'told twice'
ev 'takeover ended fix=x' "$(ago 1)"
tick; [ "$(nnote 'took over the builders')" -eq 1 ] || fail 'told again after the end'
exit 0
