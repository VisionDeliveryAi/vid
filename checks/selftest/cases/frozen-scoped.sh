#!/bin/sh
# Purpose: selftest case — a gated scoped run tests a frozen copy of the
# working tree (v0.9.6 spec 3.7.1–3.7.4, R7; §7 case 5). A toy develop run
# under a 0.9.6 plan, the compose stub holding the run open: a scoped run
# with an UNSTAGED edit tests a copy holding that edit; an edit made while
# the run is in progress is not in it; the run has its own folder and
# compose project while it runs, and the folder is gone after; the receipt
# is <head>.live.sel-<hash>.run-<id>.xml with <receipt>.tree (tree=, base=,
# frozen-at=, shape=inline) and <receipt>.cases beside it, the tree naming
# the working tree's snapshot (not HEAD's); the `ledger-run` event names
# that receipt with tree= and run=; no lock is taken. v0.26.10.5 (case correction): the event may carry
# ` waited=<s>` between run= and overhead= — a documented field since v0.9.6, written whenever the run waited a whole
# second for its slot; the case refused it, and failed on a clock-second boundary. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "frozen-scoped: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)".*/case \\1 \\2 0.1/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm reader
SHA=$(git rev-parse --short=12 HEAD)
printf 'main v2 unstaged\n' > app/main.py
touch "$T/hold"
( STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" sh checks/test.sh --role builder -- 'tests/x' > "$T/out" 2>&1 ) &
P=$!
waitfor "$T/entered" || fail 'the run never reached its up'
[ "$(nruns)" -eq 1 ] || fail 'no run folder while the run holds'
RF=$(ls -d .vid/runs/*); grep -q "^pid=$P\$" "$RF/holder" 2>/dev/null || grep -q '^pid=' "$RF/holder" || fail 'the run folder has no holder'
grep -q '^project=vid-s1-repo$' "$RF/holder" || fail 'the holder does not name the slot project'
[ ! -d .vid/ledger.lock ] || fail 'a gated run took the lock'
printf 'main v3 during the run\n' > app/main.py
rm -f "$T/hold"; wait "$P" || true
grep -q 'ctx-main=main v2 unstaged' "$STUB_LOG" || fail 'the frozen copy lacks the unstaged edit'
grep -q 'ctx-main=main v3' "$STUB_LOG" && fail 'an edit made during the run reached it'
grep 'up --build' "$STUB_LOG" | grep -q '^repo|vid-s1-repo|.*/\.vid/runs/[^|]*/ctx|' || fail 'the up did not run in the slot project on the frozen copy'
[ "$(nruns)" -eq 0 ] || fail 'the run folder outlived the run'
R=$(kept); [ "$(printf '%s\n' "$R" | grep -c .)" -eq 1 ] || fail "not one kept receipt: $R"
printf '%s\n' "$R" | grep -qE "^$SHA\.live\.sel-[0-9]+\.run-[0-9]{8}T[0-9]{6}Z-[0-9]+\.xml\$" || fail "the receipt's name: $R"
[ -f ".vid/ledger-results/$R.tree" ] && [ -f ".vid/ledger-results/$R.cases" ] || fail 'no .tree or .cases beside the receipt'
TR=$(sed -n 's/^tree=//p' ".vid/ledger-results/$R.tree")
[ -n "$TR" ] && [ "$TR" != "$(git rev-parse 'HEAD^{tree}')" ] || fail 'the tree is HEAD'"'"'s, not the snapshot'
git cat-file -p "$TR:app/main.py" | grep -q 'main v2 unstaged' || fail 'the recorded tree does not hold the tested content'
grep -qx "base=$SHA" ".vid/ledger-results/$R.tree" && grep -qE '^frozen-at=[0-9TZ:-]+$' ".vid/ledger-results/$R.tree" && grep -qx 'shape=inline' ".vid/ledger-results/$R.tree" || fail 'the .tree sidecar lacks base=, frozen-at= or shape='
grep -q '^case tests/invariants/t.py::a\[ROW-001\] passed' ".vid/ledger-results/$R.cases" || fail 'the .cases sidecar lacks the results reader lines'
grep -qE "^ledger-run seconds=[0-9]+ kind=scoped report=$R status=0 role=builder tree=$TR run=[0-9TZ-]+( waited=[0-9]+)? overhead=[0-9]+ at=" .vid/metrics-events || { tail -n 2 .vid/metrics-events >&2; fail 'the event does not name the kept receipt with tree= and run='; }
exit 0
