#!/bin/sh
# Purpose: selftest case — under breadth first completion needs every hardening step done (v0.9.7.2 spec 3.9, R13).
# The same complete fixture under breadth first: H1 not done prints `hardening not done: H1`, says not complete and
# `--record` leaves the run active; once H1 is closed (and, its rows all deploy-owed, done) the run is complete.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "completion-hardening: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
sed 's#| tests/invariants/test_[a-z0-9]*\.py$#| owed: paid by /vid deploy gate 1 — the deployed shape#' INVENTORY.md > x && mv x INVENTORY.md
printf '#!/bin/sh\n# Purpose: stub coverage court\necho "REQs: 1 cited 1 gaps: 0 open VID-QUESTION markers: 0"\n' > checks/coverage.sh
commit_all 'deploy-owed rows'
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
sh checks/metrics.sh completion > "$T/out" 2>&1
grep -qx 'hardening not done: H1' "$T/out" || fail 'the hardening line is missing'
grep -q '^completion unmet=0 strict-gaps=0$' "$T/out" || fail 'the predicate changed'
grep -q '^not complete — .*hardening not done: H1' "$T/out" || fail 'complete with a hardening step not done'
sh checks/metrics.sh completion --record > /dev/null 2>&1; grep -qx 'run: active' .vid/RUN-STATE.md || fail 'the record completed the run'
printf 'step-closed step=H1 report=x.full.xml at=%s\n' "$(utcnow)" >> .vid/metrics-events
sh checks/metrics.sh completion > "$T/out" 2>&1
grep -q 'hardening not done' "$T/out" && fail 'H1 closed with its rows deploy-owed is still not done'
grep -q '^complete, 12 rows at deploy' "$T/out" || fail 'not complete with every hardening step done'
exit 0
