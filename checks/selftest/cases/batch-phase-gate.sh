#!/bin/sh
# Purpose: selftest case — the phase gate (v0.9.7.0.12 spec 3.3; R3; §6 B). Phase 2 starts only when every phase-1
# chunk covers its rows' frozen expected cases with no red case. A phase-1 case reported skipped, and (at a new
# tree) a phase-1 group whose words leave out its row's expected case, each end the batch `incomplete phase 1,
# chunks <n>` — exit 1, state done, the chunk's why naming the row not covered — and no phase-2 chunk runs (each
# ends stopped, never left queued).
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-phase-gate: $*" >&2; cat "$T/req" "$T/wait" "$TD/result" >&2 || true; exit 1; }
batch_repo "$T/repo"
groups "$T/p2" 1 2
gate() { # <chunk> <row>: the batch ended incomplete at phase 1 on that chunk, and phase 2 never ran
  _rc=0; bwait || _rc=$?; [ "$_rc" -eq 1 ] || fail "the batch exited $_rc"
  [ "$(cat "$TD/state")" = done ] || fail 'the batch is not done'
  head -n 1 "$TD/result" | grep -qx "incomplete phase 1, chunks $1" || fail "the result does not name chunk $1"
  grep -q "^not covered: $2" "$TD/chunks/$1/why" || fail "chunk $1's why does not name $2: $(cat "$TD/chunks/$1/why" 2>/dev/null)"
  for c in 3 4; do [ ! -f "$TD/chunks/$c/running-at" ] || fail "phase-2 chunk $c ran"; done
  grep -q '^chunk 3 phase=2 not-run$' "$TD/result" || fail 'the result does not show phase 2 not run'
  [ "$(cat "$TD/chunks/3/state")" = stopped ] || fail 'a chunk never run is left queued'
}
# a skipped case
groups "$T/p1" 3 4; printf '%s skipped\n' "$(w 2 3)" > "$T/st"
STUB_STATUSES="$T/st" batch || fail 'the batch was refused'; TD=.vid/requests/$TK
gate 1 ROW-003
# a missing case: ROW-004's group runs ROW-003's case only
unset STUB_STATUSES; printf '# b\n' > app/s3/b.py; commit_all b
printf 'ROW-003 | %s |\nROW-004 | %s |\n' "$(w 2 3)" "$(w 2 3)" > "$T/p1"
batch || fail 'the second batch was refused'; TD=.vid/requests/$TK
gate 2 ROW-004
exit 0
