#!/bin/sh
# Purpose: selftest case — the skeleton's Part 3 order, by the par (v0.26.10.9 spec R4; §5 skeleton-order). The toy
# spec-only tree (fixtures/spec-only.sh), its spec committed, a develop run at `plan: skeleton` (the gate off): before
# the law commits the par shows spec-only=4; the test-author pass's tests for ROW-001..ROW-003 committed unchanged
# (VID_ROLE=fix, Tests-by:), then one standalone law commit — each row's test field its path, stamped proved-red at
# that commit — and ROW-004, returned `unwritable: missing prerequisite`, as `owed: prerequisite — …`: both pass the
# real hooks, and the par shows spec-only=0, prerequisite=1, materialised=3, holding. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/spec-only.sh"
fail() { echo "skeleton-order: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
so_tree "$T/r"; so_commit 'the spec' > "$T/out" 2>&1 || fail 'the spec commit was refused'
mkdir -p .vid; printf 'run: active\nsession: S1\nplan: skeleton\nstage: 1\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=29 at=2026-10-24T10:00:00Z\nskeleton state=start provenance=spec-only at=2026-10-24T10:00:01Z\n' > .vid/metrics-events
if sh checks/plan.sh gate > "$T/out" 2>&1; then fail 'the gate is on under plan: skeleton'; fi
sh checks/inventory.sh --report > "$T/out" 2>&1 || true
grep -q ' spec-only=4 ' "$T/out" || fail 'before the law commits the par does not show spec-only=4'
grep -q '^par: rows=5 materialised=0 legitimate=4 deploy-owed=1 other=0 — holds' "$T/out" || fail 'the par before is wrong'
# the tests, written by the pass, committed unchanged
mkdir -p tests/invariants
for r in 1 2 3; do printf '# Purpose: ROW-00%s ledger test\ndef test_row_00%s():  # ROW-00%s\n    assert False\n' "$r" "$r" "$r" > "tests/invariants/test_row_00$r.py"; done
g add tests/invariants
VID_ROLE=fix g commit -q -m "$(so_msg 'the skeleton: ledger tests for ROW-001..ROW-003' 'Tests-by: test-author 2026-10-24 skeleton-1')" > "$T/out" 2>&1 || fail "the pass's tests were refused"
TC=$(git rev-parse --short=12 HEAD)
# the law commit: paths, proved-red stamps, the unwritable row as prerequisite
for r in 1 2 3; do so_row "ROW-00$r" "tests/invariants/test_row_00$r.py | proved-red: $TC"; done
so_row ROW-004 'owed: prerequisite — an empty-note fixture the harness lacks; paid at slice 1'
g add INVENTORY.md
VID_ROLE=fix g commit -q -m "$(so_msg 'the skeleton: ROW-001..ROW-003 materialised and proved red, ROW-004 prerequisite')" > "$T/out" 2>&1 || fail 'the law commit was refused'
sh checks/inventory.sh --report > "$T/out" 2>&1 || true
grep -q ' prerequisite=1 spec-only=0 ' "$T/out" || fail 'after the law commits the par does not show spec-only=0 and prerequisite=1'
grep -q '^par: rows=5 materialised=3 legitimate=1 deploy-owed=1 other=0 — holds' "$T/out" || fail 'the par after is wrong'
grep -q '^OWED  ROW-004 (REQ-002) — owed: prerequisite — an empty-note fixture' "$T/out" || fail 'ROW-004 is not owed: prerequisite'
exit 0
