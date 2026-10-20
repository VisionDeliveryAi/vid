#!/bin/sh
# Purpose: selftest case — the staging request (v0.26.10.7 spec R6; §5 staging-request). `request --type staging
# --role orchestrator --rows-file <change set> -- <selection>`: refused with a dirty worktree, as a full run is;
# clean, its receipt is today's scoped receipt named by HEAD, its .rows the change set whole (ROW, census and HOS ids),
# its event `kind=scoped … type=staging`. --deployed-selection is refused while the harness declares no
# deployed-selector: and accepted once it does: the deployed twin is kept beside the receipt. Asked by anyone but
# the orchestrator, it is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "staging-request: $*" >&2; cat "$T"/out* >&2 2>/dev/null; exit 1; }
gated_repo "$T/r"
printf 'ROW-001\nRULE-001\nDIF-002\nHOS-001\n' > "$T/cs"
printf 'main v2, uncommitted\n' > app/main.py
if sh checks/test.sh request --type staging --role orchestrator --rows-file "$T/cs" --why 'staging' -- tests/x > "$T/out" 2>&1; then fail 'a staging request was accepted on a dirty worktree'; fi
grep -q 'uncommitted changes, and a staging runs HEAD' "$T/out" || fail 'the dirty refusal does not say why'
g checkout -q -- app/main.py
if sh checks/test.sh request --type staging --role fixer --try t1 --rows-file "$T/cs" --why 'staging' -- tests/x > "$T/out" 2>&1; then fail 'a fixer asked a staging request'; fi
SHA=$(git rev-parse --short=12 HEAD)
if sh checks/test.sh request --type staging --role orchestrator --rows-file "$T/cs" --why 'staging' -- tests/x --deployed-selection tests/d > "$T/out" 2>&1; then fail 'a deployed selection was accepted with no deployed-selector: declared'; fi
sh checks/test.sh request --type staging --role orchestrator --rows-file "$T/cs" --why 'staging' -- tests/x > "$T/out" 2>&1 || fail 'the staging request was refused'
K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
VID_WAIT_MAX=60 sh checks/test.sh wait "$K" > "$T/out.w" 2>&1 || fail 'the staging request did not run green'
R=$(ls .vid/ledger-results | grep -E "^$SHA\.live\.sel-[0-9]+\.xml\$" || true)
[ -n "$R" ] || fail "no scoped receipt named by HEAD $SHA: $(ls .vid/ledger-results | tr '\n' ' ')"
[ "$(cat ".vid/ledger-results/$R.rows")" = "$(sort -u "$T/cs")" ] || fail "the receipt's .rows is not the change set: $(cat ".vid/ledger-results/$R.rows" 2>/dev/null | tr '\n' ' ')"
grep -q "^ledger-run .* kind=scoped report=$R .* type=staging " .vid/metrics-events || fail 'the event is not kind=scoped with type=staging'
# a harness declaring deployed-selector: — the deployed selection accepted, its twin kept
sed 's/^  completed: \[0, 1\]$/  completed: [0, 1]\n  deployed-selector: sel-declared/' docker-compose.test.yml > dc && mv dc docker-compose.test.yml
grep -q 'deployed-selector: sel-declared' docker-compose.test.yml || fail 'the fixture did not declare deployed-selector:'
g commit -qam 'declare the deployed shape'; SHA=$(git rev-parse --short=12 HEAD)
sh checks/test.sh request --type staging --role orchestrator --rows-file "$T/cs" --why 'staging' -- tests/x --deployed-selection tests/d > "$T/out" 2>&1 || fail 'a deployed selection was refused with deployed-selector: declared'
K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
VID_WAIT_MAX=60 sh checks/test.sh wait "$K" > "$T/out.w" 2>&1 || fail 'the staging request with its deployed pass did not run green'
ls .vid/ledger-results | grep -qE "^$SHA\.live\.deployed\.sel-[0-9]+\.xml\$" || fail "no deployed twin named by HEAD: $(ls .vid/ledger-results | tr '\n' ' ')"
exit 0
