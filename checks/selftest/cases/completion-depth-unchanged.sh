#!/bin/sh
# Purpose: selftest case — completion's predicate is unchanged (v0.9.7.2 spec 3.9, R13). Every row is deploy-owed and
# the coverage court finds no gap: under depth first the run is complete — a kind: hardening step never closed changes
# nothing and no hardening line is printed — and `--record` sets `run: complete`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "completion-depth-unchanged: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
sed 's#| tests/invariants/test_[a-z0-9]*\.py$#| owed: paid by /vid deploy gate 1 — the deployed shape#' INVENTORY.md > x && mv x INVENTORY.md
printf '#!/bin/sh\n# Purpose: stub coverage court\necho "REQs: 1 cited 1 gaps: 0 open VID-QUESTION markers: 0"\n' > checks/coverage.sh
commit_all 'deploy-owed rows'
bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
sh checks/metrics.sh completion > "$T/out" 2>&1
grep -q '^completion unmet=0 strict-gaps=0$' "$T/out" || fail 'the fixture is not complete'
grep -q '^complete, 12 rows at deploy, 0 later' "$T/out" || fail 'not complete under depth first'
grep -q 'hardening not done' "$T/out" && fail 'a hardening line under depth first'
sh checks/metrics.sh completion --record > /dev/null 2>&1; grep -qx 'run: complete' .vid/RUN-STATE.md || fail 'the record did not complete the run'
exit 0
