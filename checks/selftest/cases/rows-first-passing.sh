#!/bin/sh
# Purpose: selftest case — rows first seen passing (v0.9.7.2 spec 3.11, R15). S2's rows passing on two trees record
# nothing; once all four pass on one tree, progress records `step-rows-passing step=S2 tree=<that tree> receipts=<the
# receipts>` once (a second read adds none). A hardening step's rows passing record nothing under breadth first. S1,
# seen passing and then closed, shows the gap labelled "includes regression checks"; S2 open shows its wait.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "rows-first-passing: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
rcpt a1 HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-005=passed ROW-006=passed ROW-009=passed ROW-010=passed ROW-011=passed ROW-012=passed
echo d >> app/s2/main.py; commit_all 'later'
rcpt a2 HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-007=passed ROW-008=passed
sh checks/progress.sh > /dev/null 2>&1
grep -q '^step-rows-passing step=S2 ' .vid/metrics-events && fail 'rows passing on two trees were recorded'
grep -q '^step-rows-passing step=H1 ' .vid/metrics-events && fail 'a hardening step was recorded'
grep -q "^step-rows-passing step=S1 tree=$(git rev-parse --short=12 'HEAD^{tree}') receipts=a2 at=" .vid/metrics-events || fail 'S1 on one tree was not recorded'
rcpt a3 HEAD inline ROW-005=passed ROW-006=passed
sh checks/progress.sh > /dev/null 2>&1; sh checks/progress.sh > "$T/out" 2>&1
[ "$(grep -c '^step-rows-passing step=S2 ' .vid/metrics-events)" -eq 1 ] || fail 'S2 was not recorded exactly once'
grep -q "^step-rows-passing step=S2 tree=$(git rev-parse --short=12 'HEAD^{tree}') receipts=a" .vid/metrics-events || fail "S2's tree"
sh checks/plan.sh start S1 > /dev/null; close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null
sh checks/progress.sh > "$T/out" 2>&1
grep -q '^| Rows passing | closed: S1 [0-9.]* h (includes regression checks) · open: S2 waiting [0-9.]* h |' "$T/out" || fail "the rows-passing line: $(grep '^| Rows passing' "$T/out")"
exit 0
