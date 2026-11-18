#!/bin/sh
# Purpose: selftest case — a dev-side line that names a ledger path (0.26.10.29.5, DP-1 R2). In ticket mode a line marked
# `origin: dev-side` is enforced by its ticket ref, so the pre-commit hook's ledger-path test (check 4b) does not read the dev
# side's words, where a path names the dev side's own tests: `decisions.sh record` records a line naming
# tests/invariants/test_tokens.py, a file ViD's repository does not hold. The skip is that narrow: in ticket mode the hook still
# refuses a line of ViD's own that names a ledger test that does not exist. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-ledger-path: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
H0=$(git rev-parse HEAD)
dpr_pr 5 3 'ticket: #3

Decisions:
- tokens are checked in one place, tests/invariants/test_tokens.py | why: one place to change'
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -qF -- '- **D-002** tokens are checked in one place, tests/invariants/test_tokens.py | why: one place to change | enforced: ticket 3 |' DECISIONS.md || fail 'the dev-side line naming a ledger path was not recorded'
[ "$(git rev-list --count "$H0..HEAD")" = 1 ] || fail 'the line was not committed'
grep -q '^decisions-recorded pr=5 n=1 at=' .vid/metrics-events || fail 'no event decisions-recorded pr=5 n=1'
printf -- '- **D-009** the audit keeps a year | why: law | enforced: tests/invariants/test_audit.py | scope: project\n' >> DECISIONS.md; g add DECISIONS.md
sh checks/hooks/pre-commit > "$T/out" 2>&1 && fail "in ticket mode the hook passed a ViD line naming a ledger test that does not exist"
grep -q "cites 'tests/invariants/test_audit.py' as enforcement" "$T/out" || fail 'the refusal is not the ledger-path test'
exit 0
