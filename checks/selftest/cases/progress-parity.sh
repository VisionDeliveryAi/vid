#!/bin/sh
# Purpose: selftest case — the readers on a plan fixture print fixed lines (v0.9.7.1 spec 3.10, R10; fitted in
# 0.26.10.28.3, R5). The plan fixture, with records covering: a test file amended after a receipt on one row's line
# (line-level staleness) and on a line no row names, an `amended` row, an invalidated receipt, the deployed shape (a
# journey row read only from a deployed receipt), a receipt's frozen rows (.rows credit), a close batch's constituent
# receipts (kind=close, with .rows), and passes on an older commit beside current ones; a closed step and a
# checkpoint due (two proved environments). Convicts unless, at a fixed VID_PROGRESS_AT, `sh checks/progress.sh`,
# `evidence.sh rows` at HEAD and at an earlier commit with --until, `metrics.sh provisional` and `metrics.sh
# checkpoint` print exactly the lines a run at 92e0195 printed, written below (the comparison with 0.9.7.0.12's
# pinned readers went in 0.26.10.28.3), and the rows read as the fixture claims. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-parity: $*" >&2; exit 1; }
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
S8=$(sed -n '$s/^.* at=//p' .vid/metrics-events); while [ "$(utcnow)" = "$S8" ]; do sleep 1; done   # the later events fall after the --until cut below, never in its second
# the test file changes: ROW-002's own line, and a line naming no row
sed 's/^\(def test_002(): pass  # ROW-002\)$/\1 and more/' tests/invariants/test_s1.py > x && mv x tests/invariants/test_s1.py
printf '# a shared helper line\n' >> tests/invariants/test_s1.py
commit_all 'test edits'
C2=$(git rev-parse --short=12 HEAD)   # the close receipts are named by this commit
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
for f in progress.sh evidence.sh metrics.sh plan.sh; do cp "$CHECKS/$f" checks/; done
run() { # <label> <command…>
  _l=$1; shift
  VID_PROGRESS_AT=$AT "$@" > "$T/new.$_l" 2>&1 || true
}
run progress sh checks/progress.sh
run rows sh checks/evidence.sh rows --at HEAD --map "$T/map"
run until sh checks/evidence.sh rows --at "$C1" --map "$T/map" --until "$MID"
run prov sh checks/metrics.sh provisional
run cp sh checks/metrics.sh checkpoint
# the expected lines, from a run at 92e0195: the two commits' short names read as C1 and C2, the heading's time as
# AT, and the Estimate row, whose rate follows the clock, left out (progress-stale-apart checks it)
C1S=$(printf '%.12s' "$C1")
norm() { sed -e "s/$C1S/C1/g" -e "s/$C2/C2/g" -e 's/^## [^ ]* — /## AT — /' -e '/^| Estimate |/d' "$1"; }
expected() {
  case $1 in
    progress) cat <<'EXP'
## AT — progress (session)

| | |
|---|---|
| Passing | 0 of 2 steps passing. 7 rows passing (4 provisional: claimed on a selected close, not yet run whole by a checkpoint or the full run) |
| Debt | 7 rows owed — passing, not KEPT 7 (never graded 7 · product breach 0 · test or harness breach 0 · journey part-graded 0 · re-grade after amendment 0) |
| Now | no step in progress |
| Left | 2 steps not started: the first step; the second step. 3 rows not yet passing (1 red, 2 not re-run since a rule or test change, 0 never run) |
| Tests | 0 of 2 environments busy · red by where it stops: setup 0, failed 1 · checkpoint due n=1 built=6 plan=10 |
| Test state | written 10 · passing 7 · proven 0, of 10 rows |
| Builders | none yet · lanes: builder 0 · run manager 0 |
| Builders at once | 0 open · target none · last 6 h average 0.0 |
| Your questions | none open |
| Plan changes since the last update | create — "two steps" |
| Now (the build's own words) | — |
EXP
    ;;
    rows) cat <<'EXP'
ROW-001	pass	passed at C1 (r1)
ROW-002	stale	never run on the current code (last run r1)
ROW-003	pass	passed at C1 (r1)
ROW-004	pass	passed at C1 (r3)
ROW-005	pass	passed at C1 (r1)
ROW-006	stale	never run on the current code (last run r1)
ROW-007	pass	passed at C2 (C2.run-20990101T000000Z-1.close.xml)
ROW-008	pass	passed at C2 (C2.run-20990101T000000Z-1.close.xml)
ROW-009	red	tests/invariants/test_s2.py::test_009[ROW-009] failed (last current run: C2.run-20990101T000000Z-2.close.xml)
ROW-010	pass	passed at C1 (d1)
EXP
    ;;
    until) cat <<'EXP'
ROW-001	pass	r1
ROW-002	pass	r1
ROW-003	pass	r1
ROW-004	pass	r3
ROW-005	pass	r1
ROW-006	stale	never run on the current code (last run r1)
ROW-007	red	tests/invariants/test_s2.py::test_007[ROW-007] failed (last current run: r1)
ROW-008	never	never run
ROW-009	never	never run
ROW-010	pass	d1
EXP
    ;;
    prov) cat <<'EXP'
provisional row=ROW-001
provisional row=ROW-003
provisional row=ROW-004
provisional row=ROW-005
provisional rows=4
EXP
    ;;
    cp) cat <<'EXP'
checkpoint due n=1 built=6 plan=10
EXP
    ;;
  esac
}
for l in progress rows until prov cp; do
  norm "$T/new.$l" > "$T/got.$l"; expected "$l" > "$T/exp.$l"
  cmp -s "$T/exp.$l" "$T/got.$l" || { diff "$T/exp.$l" "$T/got.$l" >&2 || true; fail "the $l output is not the expected lines"; }
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
