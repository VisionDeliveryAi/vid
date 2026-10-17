#!/bin/sh
# Purpose: selftest case — a close batch's two phases come from the real sets (v0.9.7.0.12 spec
# 3.1, R1; §6 A). close-rows prints each row with every set it is in and its phase: S2's rows
# (sets 1,4: closing and never run) and an S1 row the rows file names (2,5) are phase 1, the other
# S1 row (2) phase 2. A batch whose phase-1 file holds the phase-2 row is refused at serve, naming
# the row, its phase and sets; one with the phase-1 row in phase 2 the same. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-phases: $*" >&2; cat "$T/out" "$T/req" >&2 2>/dev/null; exit 1; }
batch_repo "$T/repo"
printf 'ROW-001 | the S2 change reads its counter\n' > .vid/close/1.rows
sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1 || fail 'close-rows refused'
grep '^required ' "$T/out" > "$T/req"
cat > "$T/want" <<'W'
required row=ROW-003 sets=1,4 step=S2 phase=1
required row=ROW-004 sets=1,4 step=S2 phase=1
required row=ROW-001 sets=2,5 step=S1 phase=1
required row=ROW-002 sets=2 step=S1 phase=2
W
diff "$T/want" "$T/req" > "$T/out" || fail 'the sets and phases'
# the phase-2 row in phase 1: refused at serve
groups "$T/p1" 3 4 1 2; : > "$T/p2"
batch || fail 'the request was refused before serve'
if bwait; then fail 'a misplaced row ran'; fi
grep -q 'ROW-002 is phase 2 (sets 2) but its group 1.4 is in phase 1' ".vid/requests/$TK/result" || fail "the misplaced phase-2 row is not named: $(cat ".vid/requests/$TK/result")"
# the phase-1 row in phase 2
groups "$T/p1" 3 4; groups "$T/p2" 1 2
batch || fail 'the request was refused before serve'
if bwait; then fail 'a misplaced row ran'; fi
grep -q 'ROW-001 is phase 1 (sets 2,5) but its group 2.1 is in phase 2' ".vid/requests/$TK/result" || fail "the misplaced phase-1 row is not named: $(cat ".vid/requests/$TK/result")"
exit 0
