#!/bin/sh
# Purpose: selftest case — the fast reader is the old reader (v0.9.7.1 spec 3.10, R10). The plan fixture, with
# records covering: a test file amended after a receipt on one row's line (line-level staleness) and on a line no
# row names, an `amended` row, an invalidated receipt, the deployed shape (a journey row read only from a deployed
# receipt), a receipt's frozen rows (.rows credit), a close batch's constituent receipts (kind=close, with .rows),
# and passes on an older commit beside current ones; a closed step and a checkpoint due (two proved environments).
# Convicts unless, at a fixed VID_PROGRESS_AT, `sh checks/progress.sh` prints exactly what checks/progress.sh as at
# 0.9.7.0.12 prints (pinned with its helpers in fixtures/progress-0.9.7.0.12/), and `evidence.sh rows` at HEAD and
# at an earlier commit with --until, `metrics.sh provisional` and `metrics.sh checkpoint` print what the pinned
# ones print. v0.9.7.2: the progress rows it adds are left out of the comparison and its Passing row is read as
# Done. v0.9.8.1 (R8): its stale rows are read back into red, and the Estimate row is left out. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-parity: $*" >&2; exit 1; }
PIN="$CHECKS/selftest/fixtures/progress-0.9.7.0.12"
plan_repo "$T/repo"; cp "$CHECKS/plan.sh" checks/
rows s1 1 6; rows s2 7 9; rows s2 10 10 journey
# the test functions named as the receipts name their cases (test_001 …), so a case's block can be found
for f in tests/invariants/test_s1.py tests/invariants/test_s2.py; do sed -e 's/^def test_\([0-9]\)()/def test_00\1()/' -e 's/^def test_\([0-9][0-9]\)()/def test_0\1()/' "$f" > x && mv x "$f"; done
printf '%s' "$COMPOSEFILE" | awk '{ print } /^x-vid-harness:/ { print "  deployed-selector: tests/invariants/test_s2.py" }' > docker-compose.test.yml
commit_all rows
plan 'step S1 | name: the first step | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-006 | lane: builder' \
  'step S2 | name: the second step | modules: app/s2 | builds-on: S1 | rows: ROW-007..ROW-010 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'they build' > /dev/null
printf 'stacks=2\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
C1=$(git rev-parse HEAD)
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-005=passed ROW-006=passed ROW-007=failed ROW-010=passed
rcpt d1 HEAD deployed ROW-010=passed
# the invalidated receipt
rcpt r2 HEAD inline ROW-003=failed; printf 'invalidated slice=1 report=r2 toy at=%s\n' "$(utcnow)" >> .vid/metrics-events
# frozen rows: a receipt reaching ROW-004 and ROW-005, crediting only ROW-004
rcpt r3 HEAD inline ROW-004=passed ROW-005=failed; printf 'ROW-004\n' > .vid/ledger-results/r3.rows
printf 'step-closed step=S1 report=r1 at=%s\n' "$(utcnow)" >> .vid/metrics-events
# the test file changes: ROW-002's own line, and a line naming no row
sed 's/^\(def test_002(): pass  # ROW-002\)$/\1 and more/' tests/invariants/test_s1.py > x && mv x tests/invariants/test_s1.py
printf '# a shared helper line\n' >> tests/invariants/test_s1.py
commit_all 'test edits'
# an amended row: its results before the amendment's commit do not count
printf 'amended row=ROW-006 sha=%s at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(utcnow)" >> .vid/metrics-events
# a close batch's constituents: two chunk receipts, each with its frozen rows
RCPT_KIND=close rcpt "$(git rev-parse --short=12 HEAD).run-20990101T000000Z-1.close.xml" HEAD inline ROW-007=passed ROW-008=passed
printf 'ROW-007\nROW-008\n' > ".vid/ledger-results/$(git rev-parse --short=12 HEAD).run-20990101T000000Z-1.close.xml.rows"
RCPT_KIND=close rcpt "$(git rev-parse --short=12 HEAD).run-20990101T000000Z-2.close.xml" HEAD inline ROW-009=failed
printf 'ROW-009\n' > ".vid/ledger-results/$(git rev-parse --short=12 HEAD).run-20990101T000000Z-2.close.xml.rows"
printf 'feature\n' > app/s2/main.py; commit_all 'later code'
AT=$(utcnow); MID=$(sed -n 's/^.* at=\([^ ]*\)$/\1/p' .vid/metrics-events | sed -n '8p')
sh checks/plan.sh map --all > "$T/map"
run() { # <old|new> <label> <command…>
  _w=$1; _l=$2; shift 2
  if [ "$_w" = old ]; then for f in progress.sh evidence.sh metrics.sh plan.sh; do cp "$PIN/$f" checks/; done
  else for f in progress.sh evidence.sh metrics.sh plan.sh; do cp "$CHECKS/$f" checks/; done; fi
  VID_PROGRESS_AT=$AT "$@" > "$T/$_w.$_l" 2>&1 || true
}
for w in old new; do
  run $w progress sh checks/progress.sh
  run $w rows sh checks/evidence.sh rows --at HEAD --map "$T/map"
  run $w until sh checks/evidence.sh rows --at "$C1" --map "$T/map" --until "$MID"
  run $w prov sh checks/metrics.sh provisional
  run $w cp sh checks/metrics.sh checkpoint
done
# v0.9.7.2 (R12, R14, R15): the rows 0.9.7.2 adds are left out, and its "Passing" row read under the old name "Done";
# v0.9.8 (R13): so is its Test state row
sed -e '/^| Test state |/d' -e '/^| Debt |/d' -e '/^| Closed, not graded |/d' -e '/^| Hardening |/d' -e '/^| Builders at once |/d' -e '/^| Rows passing |/d' -e 's/^| Passing |/| Done |/' "$T/new.progress" > "$T/new.p" && mv "$T/new.p" "$T/new.progress"
# v0.9.8.1 (R8): its stale rows, counted apart, are read back into red; and the Estimate row, whose rate now leaves the
# stale rows out, is compared by progress-stale-apart instead
awk '/^\| Left \|/ && match($0, /\([0-9]+ red, [0-9]+ not re-run since a rule or test change, /) {
    m = substr($0, RSTART, RLENGTH); split(m, a, " "); r = substr(a[1], 2) + a[3]; $0 = substr($0, 1, RSTART - 1) "(" r " red, " substr($0, RSTART + RLENGTH) }
  !/^\| Estimate \|/ { print }' "$T/new.progress" > "$T/new.p" && mv "$T/new.p" "$T/new.progress"
grep -v '^| Estimate |' "$T/old.progress" > "$T/old.p" && mv "$T/old.p" "$T/old.progress"
for l in progress rows until prov cp; do
  cmp -s "$T/old.$l" "$T/new.$l" || { diff "$T/old.$l" "$T/new.$l" >&2; fail "the $l output differs from 0.9.7.0.12's"; }
done
# the fixture reaches what it claims to cover
grep -q '^ROW-002	stale\|^ROW-002	never\|^ROW-002	red' "$T/new.rows" || fail "ROW-002's own line changed and it still reads as before: $(grep '^ROW-002' "$T/new.rows")"
grep -q '^ROW-001	pass	passed at' "$T/new.rows" || fail "ROW-001 does not read as a pass on an older commit: $(grep '^ROW-001' "$T/new.rows")"
grep -q '^ROW-003	pass' "$T/new.rows" || fail 'the invalidated receipt still counts'
grep -q '^ROW-005	pass' "$T/new.rows" || fail 'a receipt credited a row outside its frozen rows'
grep -q '^ROW-010	pass' "$T/new.rows" || fail 'the journey row does not read from the deployed receipt'
grep -q '^ROW-009	red' "$T/new.rows" || fail 'the batch constituent does not count'
grep -q '^ROW-006	\(stale\|never\)' "$T/new.rows" || fail 'the amended row kept its earlier result'
grep -q 'checkpoint due' "$T/new.progress" || fail 'no checkpoint due in the table'
exit 0
