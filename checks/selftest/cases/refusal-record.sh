#!/bin/sh
# Purpose: selftest case — a refused commit records what was refused and why (v0.9.7.3 spec 3.5, R5). Under the real
# hook with stub courts: a census refusal writes .vid/refusals/<attempt>/ — meta (tree= the index's tree, head=, and
# `court=census rule=RULE-004 subject=site-x` from its machine line) and census.out and .err — and the event
# `court-refused court=census rule=RULE-004 subject=site-x tree=<tree> attempt=<attempt>`; inventory and census
# refusing together give two court lines and two events (inventory's `GAP  ROW-007` as rule gap); a refusal before
# the courts (protected paths) records its own name, rule and subject `-`. Progress lists the refusals by court and
# rule (a row only when there are any). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "refusal-record: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
mkdir -p .vid
printf '#!/bin/sh\n# Purpose: stub census\n: > .ran/census\nif [ -f .fail/census ]; then echo "FAIL  RULE-004  site-x  unguarded"; echo "ViD census: rejected" >&2; exit 1; fi\necho "census ok"\n' > checks/census.sh
printf '#!/bin/sh\n# Purpose: stub inventory\n: > .ran/inventory\nif [ -f .fail/inventory ]; then echo "GAP  ROW-007 cites a missing test"; exit 1; fi\necho "inventory ok"\n' > checks/inventory.sh
g add -A && g commit -qm 'stubs with machine lines'
stage one; : > .fail/census
if sh checks/hooks/pre-commit > .vid/out 2>&1; then fail 'the census refusal passed'; fi
A=$(ls .vid/refusals); [ "$(printf '%s\n' "$A" | grep -c .)" = 1 ] || fail 'not one attempt directory'
R=.vid/refusals/$A; TR=$(git write-tree)
grep -qx "tree=$TR" "$R/meta" || fail 'meta lacks the index tree'
grep -qx "head=$(git rev-parse HEAD)" "$R/meta" || fail 'meta lacks HEAD'
grep -qx 'court=census rule=RULE-004 subject=site-x' "$R/meta" || fail 'meta lacks the court, rule and subject'
grep -q '^FAIL  RULE-004  site-x' "$R/census.out" && grep -q 'ViD census: rejected' "$R/census.err" || fail 'the court output was not kept'
grep -q "^court-refused court=census rule=RULE-004 subject=site-x tree=$TR attempt=$A at=" .vid/metrics-events || fail 'no court-refused event'
: > .fail/inventory
if sh checks/hooks/pre-commit > .vid/out 2>&1; then fail 'the two-court refusal passed'; fi
B=$(ls .vid/refusals | grep -vxF "$A"); [ "$(printf '%s\n' "$B" | grep -c .)" = 1 ] || fail 'the second attempt has no directory of its own'
grep -qx 'court=inventory rule=gap subject=ROW-007' ".vid/refusals/$B/meta" && grep -qx 'court=census rule=RULE-004 subject=site-x' ".vid/refusals/$B/meta" || fail 'meta lacks a line per court'
[ "$(grep -c "^court-refused .* attempt=$B " .vid/metrics-events)" = 2 ] || fail 'not one event per court'
rm -f .fail/*; g reset -q; printf 'x\n' >> checks/lawfiles; g add checks/lawfiles
if sh checks/hooks/pre-commit > .vid/out 2>&1; then fail 'a protected path passed'; fi
grep -q '^court-refused court=protected-paths rule=- subject=- tree=' .vid/metrics-events || fail 'the early refusal has no event'
C=$(ls -t .vid/refusals | head -n 1); grep -qx 'court=protected-paths rule=- subject=-' ".vid/refusals/$C/meta" || fail 'the early refusal has no record'
# progress lists them by court and rule, in a toy develop run carrying these events
EVS=$(grep '^court-refused ' .vid/metrics-events)
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
plan_repo "$T/run"; rows s1 1 2; commit_all rows
plan 'step S1 | name: one | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
sh checks/progress.sh > "$T/.vid/out" 2>&1 || fail 'progress failed'
grep -q '^| Refused commits ' "$T/.vid/out" && fail 'a Refused commits row with no refusal'
printf '%s\n' "$EVS" >> .vid/metrics-events
sh checks/progress.sh > "$T/.vid/out" 2>&1 || fail 'progress failed'
grep -qxF '| Refused commits | 4 — census 2 (RULE-004 2) · inventory 1 (gap 1) · protected-paths 1 (- 1) |' "$T/.vid/out" || fail 'progress does not list the refusals by court and rule'
exit 0
