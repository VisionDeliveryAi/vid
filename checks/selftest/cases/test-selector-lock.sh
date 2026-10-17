#!/bin/sh
# Purpose: selftest case — the ledger wrapper's selector, receipt and lock
# (v0.9.2 spec 3.6, R9; §7.2, §7.3). A toy repository with a compose file;
# VID_COMPOSE points at a recording stub that stands in for the container
# daemon: it records the selector and the mounted context it was handed and
# writes the runner's report unless told to die. Convicts and acquits:
# (1) with a selector the compose command carries it (VID_SELECTOR), the live
# tree is the context and the report is `.live.sel-<hash>`; (2) a full run
# exports HEAD — the context holds the committed file and not a file written
# into the worktree — and the report is `<sha>.full.xml`; (3) a full run on a
# dirty worktree is refused ("commit first") while a scoped run is not;
# (4) a second invocation while the lock is held is refused naming the
# holder's pid; a stale lock is refused, reported as stale, and never
# removed; (5) a killed run leaves no report; (6) an everything-selector
# through the scoped door is still `.live.`. v0.9.3 (3.3, 3.10; the ungated
# set): (7) under a harness contract naming its `completed:` statuses, a
# runner killed by a signal after writing one passed case of a two-case row
# publishes nothing and records `status=`; a runner returning its own
# interrupt status (inside its numeric range, outside `completed:`) after
# writing the same partial report publishes nothing; a runner returning a
# `completed:` status with a complete red report is published; `--role`
# rides the event and an unknown role is refused; a contract without
# `completed:` keeps the 0.9.2 rule and says so. v0.9.6 (3.7; §7 case 13),
# gated — the same toy inside a develop run under a 0.9.6 plan: (8) the
# selector rides and the tested context is a frozen copy under .vid/runs/,
# the receipt <sha>.live.sel-<hash>.run-<id>.xml; (9) a full run tests
# HEAD's tree — the committed file there, a worktree-only file not — kept
# as <sha>.run-<id>.full.xml with <sha>.full.xml its copy; (10) a dirty
# worktree still refuses the full run and not the scoped one; (11) a live
# or stale lock refuses the gated run and is never removed; (12) a killed
# run publishes nothing and records report=none with its run=; no gated
# run ever takes the lock. Env: CHECKS.
set -eu
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'   # v0.9.5 3.11: every event line ends ` at=<UTC>`
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks tests/invariants app .vid
cp "$CHECKS/test.sh" checks/test.sh
printf 'services:\n  product:\n    build:\n      context: ${VID_TEST_CONTEXT:-.}\n  tests:\n    image: runner\n    volumes:\n      - ${VID_TEST_CONTEXT:-.}:/app:ro\n    command: sh -c "run --report /vid-results/pending.xml ${VID_SELECTOR:-}"\n' > docker-compose.test.yml
printf '# Purpose: toy\n' > app/main.py
printf '# ledger REQ-001\n' > tests/invariants/test_req001.py
printf 'scratch.txt\nstub.sh\nstub.log\nout.txt\n' > .gitignore   # the case's own files never dirty the toy tree
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
SHA=$(git rev-parse --short=12 HEAD)
# the stub: records what it was handed; writes the report on "up" unless STUB_MODE=kill
cat > stub.sh <<'STUB'
#!/bin/sh
case "$*" in *' up '*)
  printf 'selector=[%s]\ncontext=[%s]\n' "${VID_SELECTOR:-}" "${VID_TEST_CONTEXT:-}" > "$STUB_LOG"
  [ -f "$VID_TEST_CONTEXT/app/main.py" ] && echo 'context-has-main=yes' >> "$STUB_LOG" || echo 'context-has-main=no' >> "$STUB_LOG"
  [ -f "$VID_TEST_CONTEXT/scratch.txt" ] && echo 'context-has-scratch=yes' >> "$STUB_LOG" || echo 'context-has-scratch=no' >> "$STUB_LOG"
  [ "${STUB_MODE:-}" = kill ] && exit 137
  case "${VID_TEST_CONTEXT:-}" in */ctx) mkdir -p .vid/ledger-results; RD="${VID_TEST_CONTEXT%/ctx}/results"; printf '<report><case name="tests/invariants/test_req001.py::test_req001" status="failed" time="0.1"/></report>\n' > "$RD/pending.xml"; exit 1 ;; esac
  case "${STUB_MODE:-}" in
    partial-signal) printf '<report><case name="tests/invariants/test_req001.py::a[ROW-001]" status="passed" time="0.1"/></report>\n' > .vid/ledger-results/pending.xml; exit 137 ;;
    partial-interrupt) printf '<report><case name="tests/invariants/test_req001.py::a[ROW-001]" status="passed" time="0.1"/></report>\n' > .vid/ledger-results/pending.xml; exit 2 ;;
  esac
  printf '<report><case name="tests/invariants/test_req001.py::test_req001" status="failed" time="0.1"/></report>\n' > .vid/ledger-results/pending.xml
  exit 1 ;;
esac
exit 0
STUB
chmod +x stub.sh
export VID_COMPOSE="$PWD/stub.sh" STUB_LOG="$PWD/stub.log"
RUNDIR=$(mktemp -d); trap 'rm -rf "$T" "$RUNDIR"' EXIT; export XDG_RUNTIME_DIR="$RUNDIR"   # the host lease (v0.9.3) lives in a private runtime directory, outside the toy tree

# 1. a selector rides through, the live tree is the context, the report is .live.sel-<hash>
sh checks/test.sh -- 'tests/invariants/test_req001.py::test_req001' >out.txt 2>&1 || true
grep -q 'selector=\[tests/invariants/test_req001.py::test_req001\]' stub.log || { echo 'test-selector-lock: the selector did not reach the compose command' >&2; cat stub.log >&2; exit 1; }
grep -q 'context=\[\.\]' stub.log || exit 1
R=$(ls .vid/ledger-results/ | grep -E "^$SHA\.live\.sel-[0-9]+\.xml$" || true)
[ -n "$R" ] || { echo 'test-selector-lock: no .live.sel- report for the scoped run' >&2; ls .vid/ledger-results >&2; exit 1; }
grep -q "ledger-run seconds=[0-9]* kind=scoped report=$R" .vid/metrics-events || exit 1
[ ! -d .vid/ledger.lock ] || exit 1                                          # released on exit
[ ! -f .vid/ledger-results/pending.xml ] || exit 1

# 2. a full run exports HEAD: the committed file is there, a worktree-only file is not; the report is <sha>.full.xml
printf 'written into the worktree while the run executes\n' > scratch.txt   # ignored, so the tree is clean; absent from the export
sh checks/test.sh >out.txt 2>&1 || true
grep -q 'context-has-main=yes' stub.log || { echo 'test-selector-lock: the export lacks the committed file' >&2; exit 1; }
grep -q 'context-has-scratch=no' stub.log || { echo 'test-selector-lock: a worktree-only file reached the export' >&2; exit 1; }
grep -q 'context=\[.*\.vid/export\.' stub.log || exit 1
[ -f ".vid/ledger-results/$SHA.full.xml" ] || { echo 'test-selector-lock: no <sha>.full.xml report' >&2; ls .vid/ledger-results >&2; exit 1; }
grep -q "kind=full report=$SHA.full.xml" .vid/metrics-events || exit 1
[ -z "$(ls -d .vid/export.* 2>/dev/null || true)" ] || { echo 'test-selector-lock: the export was not deleted' >&2; exit 1; }
rm -f scratch.txt

# 3. a dirty worktree refuses the full run and not the scoped one
printf '# Purpose: toy, edited\n' > app/main.py
if sh checks/test.sh >out.txt 2>&1; then exit 1; fi
grep -q 'commit first: a receipt names a tree' out.txt || { cat out.txt >&2; exit 1; }
[ ! -d .vid/ledger.lock ] || exit 1
sh checks/test.sh -- 'tests/invariants' >out.txt 2>&1 || true
grep -q 'context=\[\.\]' stub.log || exit 1
git checkout -q -- app/main.py

# 4. the lock: held by a live pid → refused naming it; stale → refused, reported stale, never removed
mkdir .vid/ledger.lock && printf '%s\n2026-09-21 10:00:00\n%s\n' "$$" "$(date +%s)" > .vid/ledger.lock/holder
if sh checks/test.sh -- x >out.txt 2>&1; then exit 1; fi
grep -q "a ledger run is in progress (pid $$" out.txt || { cat out.txt >&2; exit 1; }
printf '99999999\n2026-09-21 10:00:00\n%s\n' "$(( $(date +%s) - 3600 ))" > .vid/ledger.lock/holder
if sh checks/test.sh -- x >out.txt 2>&1; then exit 1; fi
grep -q 'STALE lock' out.txt || { cat out.txt >&2; exit 1; }
[ -d .vid/ledger.lock ] || { echo 'test-selector-lock: the script removed a stale lock' >&2; exit 1; }
rm -rf .vid/ledger.lock

# 5. a killed run leaves no report and the lock is released
STUB_MODE=kill sh checks/test.sh -- 'tests/invariants' >out.txt 2>&1 && exit 1
grep -q 'no report' out.txt || exit 1
[ ! -f .vid/ledger-results/pending.xml ] || exit 1
[ "$(ls .vid/ledger-results | wc -l | tr -d ' ')" -eq 3 ] || exit 1                 # only the three earlier reports (two scoped, one full)
grep -q 'kind=scoped report=none' .vid/metrics-events || exit 1
[ ! -d .vid/ledger.lock ] || exit 1

# 6. the everything-selector through the scoped door is still .live. (init's red gate)
sh checks/test.sh -- 'tests/invariants' >out.txt 2>&1 || true
ls .vid/ledger-results | grep -qE "^$SHA\.live\.sel-[0-9]+\.xml$" || exit 1
[ "$(ls .vid/ledger-results | grep -c '\.full\.xml$')" -eq 1 ] || exit 1

# 7. v0.9.3: publish only on a completed: status; status= and role= on the event
grep -q 'declares no completed: statuses' out.txt || { echo 'test-selector-lock: a contract without completed: did not say so' >&2; exit 1; }
printf 'x-vid-harness:\n  product: product\n  completed: [0, 1]   # all passed, some failed\n' | cat - docker-compose.test.yml > c && mv c docker-compose.test.yml
git add docker-compose.test.yml && git -c user.email=vid@selftest -c user.name=vid commit -qm 'the completed statuses'
SHA=$(git rev-parse --short=12 HEAD)
rm -f .vid/ledger-results/*
STUB_MODE=partial-signal sh checks/test.sh --role close >out.txt 2>&1 && exit 1
grep -q 'outside the harness contract.s completed: \[0 1\]' out.txt || { echo 'test-selector-lock: a signal death after a partial report did not say why' >&2; cat out.txt >&2; exit 1; }
[ -z "$(ls .vid/ledger-results)" ] || { echo 'test-selector-lock: a partial report was published after a signal death' >&2; exit 1; }
tail -n 1 .vid/metrics-events | grep -qE "kind=full report=none status=137 role=close form=legacy $ATRE\$" || { tail -n 1 .vid/metrics-events >&2; exit 1; }
STUB_MODE=partial-interrupt sh checks/test.sh --role builder -- x >out.txt 2>&1 && exit 1
[ -z "$(ls .vid/ledger-results)" ] || { echo "test-selector-lock: a partial report was published after the runner's own interrupt status" >&2; exit 1; }
tail -n 1 .vid/metrics-events | grep -qE "kind=scoped report=none status=2 role=builder form=legacy $ATRE\$" || exit 1
sh checks/test.sh --role close >out.txt 2>&1 && exit 1                       # a complete red report, a completed: status (1)
[ -f ".vid/ledger-results/$SHA.full.xml" ] || { echo 'test-selector-lock: a complete red report was not published' >&2; cat out.txt >&2; exit 1; }
tail -n 1 .vid/metrics-events | grep -qE "kind=full report=$SHA.full.xml status=1 role=close form=legacy $ATRE\$" || exit 1
if sh checks/test.sh --role reviewer >out.txt 2>&1; then exit 1; fi
grep -q 'usage' out.txt || exit 1

# v0.9.6, gated
cp "$CHECKS/plan.sh" checks/plan.sh
git add checks/plan.sh && git -c user.email=vid@selftest -c user.name=vid commit -qm 'the plan script'
SHA=$(git rev-parse --short=12 HEAD)
printf 'run: active\nsession: S\nplan: required\n' > .vid/RUN-STATE.md
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
printf 'stage name=develop state=start session=S records=2 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
rm -f .vid/ledger-results/*
# 8. the selector rides; the context is a frozen copy; the receipt is kept by run
sh checks/test.sh --role builder -- 'tests/invariants/test_req001.py::test_req001' >out.txt 2>&1 || true
grep -q 'selector=\[tests/invariants/test_req001.py::test_req001\]' stub.log || exit 1
grep -q 'context=\[.*/\.vid/runs/[0-9TZ]*-[0-9]*/ctx\]' stub.log || { echo 'test-selector-lock: the gated scoped run did not test a frozen copy' >&2; cat stub.log >&2; exit 1; }
ls .vid/ledger-results | grep -qE "^$SHA\.live\.sel-[0-9]+\.run-[0-9TZ]+-[0-9]+\.xml\$" || { ls .vid/ledger-results >&2; exit 1; }
# 9. a full run tests HEAD's tree, kept by run, the commit-named file its copy
printf 'written into the worktree while the run executes\n' > scratch.txt
sh checks/test.sh --role close >out.txt 2>&1 || true
grep -q 'context-has-main=yes' stub.log && grep -q 'context-has-scratch=no' stub.log || { echo 'test-selector-lock: the gated full run did not test HEAD' >&2; exit 1; }
KF=$(ls .vid/ledger-results | grep -E "^$SHA\.run-[0-9TZ]+-[0-9]+\.full\.xml\$" || true)
[ -n "$KF" ] && cmp -s ".vid/ledger-results/$KF" ".vid/ledger-results/$SHA.full.xml" || { echo 'test-selector-lock: no kept full receipt with its copy' >&2; ls .vid/ledger-results >&2; exit 1; }
grep "^ledger-run " .vid/metrics-events | tail -n 1 | grep -qE "kind=full report=$KF status=1 role=close tree=[0-9a-f]+ run=[0-9TZ]+-[0-9]+ overhead=[0-9]+ $ATRE\$" || { tail -n 1 .vid/metrics-events >&2; exit 1; }
rm -f scratch.txt
# 10. dirty: the full run refused, the scoped not
printf '# Purpose: toy, edited\n' > app/main.py
if sh checks/test.sh --role close >out.txt 2>&1; then exit 1; fi
grep -q 'commit first: a receipt names a tree' out.txt || exit 1
sh checks/test.sh --role builder -- 'tests/invariants' >out.txt 2>&1 || true
grep -q 'context=\[.*/ctx\]' stub.log || exit 1
git checkout -q -- app/main.py
# 11. a lock, live or stale, refuses the gated run and is never removed
mkdir .vid/ledger.lock && printf '%s\n2026-09-21 10:00:00\n%s\n' "$$" "$(date +%s)" > .vid/ledger.lock/holder
if sh checks/test.sh --role builder -- x >out.txt 2>&1; then exit 1; fi
grep -q "a ledger run is in progress (pid $$" out.txt || exit 1
printf '99999999\n2026-09-21 10:00:00\n%s\n' "$(( $(date +%s) - 3600 ))" > .vid/ledger.lock/holder
if sh checks/test.sh --role builder -- x >out.txt 2>&1; then exit 1; fi
grep -q 'STALE lock' out.txt && [ -d .vid/ledger.lock ] || exit 1
rm -rf .vid/ledger.lock
# 12. a killed run publishes nothing; no gated run took the lock
N=$(ls .vid/ledger-results | wc -l | tr -d ' ')
STUB_MODE=kill sh checks/test.sh --role builder -- 'tests/invariants' >out.txt 2>&1 && exit 1
[ "$(ls .vid/ledger-results | wc -l | tr -d ' ')" -eq "$N" ] || exit 1
grep "^ledger-run " .vid/metrics-events | tail -n 1 | grep -qE "kind=scoped report=none status=137 role=builder tree=[0-9a-f]+ run=[0-9TZ]+-[0-9]+ $ATRE\$" || { tail -n 1 .vid/metrics-events >&2; exit 1; }
[ ! -d .vid/ledger.lock ] && [ -z "$(ls .vid/runs 2>/dev/null)" ] || exit 1
exit 0
