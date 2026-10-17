#!/bin/sh
# Purpose: selftest case — outside the gate the close is 0.9.6's (v0.9.6.1
# spec 3.1, R7; §6 case 3). In a repository with no develop run, `--role
# close -- <selection>` is a scoped run: the lock taken, the live tree
# mounted, the receipt <head>.live.sel-<hash>.xml, the event kind=scoped
# role=close; `--role close` with no selection is the whole-ledger run,
# <head>.full.xml on an export; --deployed-selection is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "close-gate-off: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"
SHA=$(git rev-parse --short=12 HEAD)
sh checks/test.sh --role close -- 'sel-inline' > "$T/out" 2>&1 || fail 'the ungated close failed'
grep -q '^repo||\.|sel-inline|-f docker-compose.test.yml up ' "$STUB_LOG" || fail 'the ungated close did not mount the live tree as a scoped run'
ls .vid/ledger-results | grep -qE "^$SHA\.live\.sel-[0-9]+\.xml\$" || fail "the receipt is not 0.9.6's scoped name: $(ls .vid/ledger-results)"
ls .vid/ledger-results | grep -q 'close' && fail 'an ungated run wrote a close receipt'
grep -qE '^ledger-run seconds=[0-9]+ kind=scoped report=[^ ]+ status=0 role=close form=legacy at=' .vid/metrics-events || fail 'the event is not 0.9.6'"'"'s scoped line'
[ ! -d .vid/runs ] || [ -z "$(ls .vid/runs)" ] || fail 'an ungated run made a run folder'
sh checks/test.sh --role close > "$T/out" 2>&1 || fail 'the ungated whole-ledger close failed'
[ -f ".vid/ledger-results/$SHA.full.xml" ] || fail 'the ungated whole-ledger close is not <head>.full.xml'
grep -qE "^ledger-run seconds=[0-9]+ kind=full report=$SHA.full.xml status=0 role=close form=legacy at=" .vid/metrics-events || fail 'the whole-ledger event is not 0.9.6'"'"'s'
N0=$(ls .vid/ledger-results | wc -l)
if sh checks/test.sh --role close -- 'sel-inline' --deployed-selection 'sel-dep' > "$T/out" 2>&1; then fail '--deployed-selection was taken outside the gate'; fi
grep -q 'belongs to a selected close' "$T/out" || fail 'the refusal does not say why'
[ "$(ls .vid/ledger-results | wc -l)" -eq "$N0" ] || fail 'the refused run published something'
[ ! -d .vid/ledger.lock ] || fail 'the refused run kept the lock'
exit 0
