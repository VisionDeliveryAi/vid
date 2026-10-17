#!/bin/sh
# Purpose: selftest case — the selected close (v0.9.6.1 spec 3.1, R1; §6
# case 1). Inside a toy develop run under a 0.9.6 plan whose harness
# declares a deployed selector: `--role close -- <inline selection>
# --deployed-selection <deployed selection>` runs an export of HEAD's tree
# (the .tree names HEAD's tree), each pass with exactly its own selection
# (ViD builds and combines none — the declared deployed selector never
# reaches it), the full run's teardown per pass; it publishes the four
# receipt names — <head>.run-<id>.close.xml, <head>.close.xml,
# <head>.run-<id>.close.deployed.xml, <head>.close.deployed.xml — with
# .tree and .cases beside each kept one, and the events `kind=close` and
# `kind=deployed`, each naming its kept receipt. A dirty worktree is
# refused and publishes nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "close-selected: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-declared
  processes: [worker]
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  worker:
    image: toy:test
    profiles: [deployed]
  tests:
    image: runner
'
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)".*/case \\1 \\2 0.1/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm reader
SHA=$(git rev-parse --short=12 HEAD)
sh checks/test.sh --role close -- sel-inline a b --deployed-selection sel-dep c > "$T/out" 2>&1 || fail 'the selected close failed'
grep 'up --build --exit-code-from tests tests' "$STUB_LOG" | grep -q '^repo|vid-s1-repo|[^|]*/\.vid/runs/[^|]*/ctx|sel-inline a b|' || fail 'the inline pass did not run its own selection on the export'
grep -q '|sel-dep c|.*--profile deployed up --exit-code-from tests tests' "$STUB_LOG" || fail 'the deployed pass did not run its own selection'
grep -q 'sel-declared' "$STUB_LOG" && fail 'the declared deployed selector reached the close — a selection was built by ViD'
grep -q '|sel-inline a b sel-dep c|\|sel-dep c sel-inline' "$STUB_LOG" && fail 'the two selections were combined'
grep -q ' down --remove-orphans --volumes$' "$STUB_LOG" || fail 'the inline pass lost the full run'"'"'s teardown'
grep -q ' --profile deployed down --remove-orphans --volumes$' "$STUB_LOG" || fail 'the deployed pass lost the full run'"'"'s teardown'
R=$(kept | grep '\.close\.xml$' || true); RD=$(kept | grep '\.close\.deployed\.xml$' || true)
printf '%s\n' "$R" | grep -qE "^$SHA\.run-[0-9]{8}T[0-9]{6}Z-[0-9]+\.close\.xml\$" || fail "the inline receipt's name: $R"
printf '%s\n' "$RD" | grep -qE "^$SHA\.run-[0-9]{8}T[0-9]{6}Z-[0-9]+\.close\.deployed\.xml\$" || fail "the deployed receipt's name: $RD"
[ -f ".vid/ledger-results/$SHA.close.xml" ] && cmp -s ".vid/ledger-results/$SHA.close.xml" ".vid/ledger-results/$R" || fail 'no copy <head>.close.xml of the kept receipt'
[ -f ".vid/ledger-results/$SHA.close.deployed.xml" ] && cmp -s ".vid/ledger-results/$SHA.close.deployed.xml" ".vid/ledger-results/$RD" || fail 'no copy <head>.close.deployed.xml'
ls .vid/ledger-results | grep -q '\.full\.xml' && fail 'a selected close wrote a full receipt'
for x in "$R" "$RD"; do [ -f ".vid/ledger-results/$x.tree" ] && [ -f ".vid/ledger-results/$x.cases" ] || fail "no .tree or .cases beside $x"; done
grep -qx "tree=$(git rev-parse 'HEAD^{tree}')" ".vid/ledger-results/$R.tree" || fail 'the close did not test HEAD'"'"'s tree'
grep -qx 'shape=deployed' ".vid/ledger-results/$RD.tree" || fail 'the deployed receipt is not shape=deployed'
grep -qE "^ledger-run seconds=[0-9]+ kind=close report=$R status=0 role=close tree=" .vid/metrics-events || fail 'no kind=close event naming the kept receipt'
grep -qE "^ledger-run seconds=[0-9]+ kind=deployed report=$RD status=0 role=close tree=" .vid/metrics-events || fail 'no kind=deployed event naming the deployed receipt'
[ "$(nruns)" -eq 0 ] || fail 'the run folder outlived the close'
# a dirty worktree is refused
N0=$(ls .vid/ledger-results | wc -l)
printf 'main v2 uncommitted\n' > app/main.py
if sh checks/test.sh --role close -- 'sel-inline' --deployed-selection 'sel-dep' > "$T/out" 2>&1; then fail 'a dirty worktree was closed'; fi
grep -q 'uncommitted changes' "$T/out" || fail 'the refusal does not name the uncommitted change'
[ "$(ls .vid/ledger-results | wc -l)" -eq "$N0" ] || fail 'the refused close published something'
[ "$(nruns)" -eq 0 ] || fail 'the refused close left a run folder'
exit 0
