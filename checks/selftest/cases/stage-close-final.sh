#!/bin/sh
# Purpose: selftest case — the final stage closes like the others (v0.26.10.8 spec R2, R9; §5 stage-close-final). The
# toy product (fixtures/stages.sh) cut as STAGE-0 (ROW-001, ROW-002), STAGE-1 and STAGE-2 — three lines, final stage 2.
# Stage 1's ready close is no final close: `stage: 2`, its section names stage 2 next. Stage 2's ready close records
# `stage-closed n=2`, tags vid/stage-2, writes its section with no next stage and leaves `stage: 2` (no next stage set);
# completion is left to `completion --record`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stage-close-final: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
st_close_repo "$T/r"
st_stages 'STAGE-0 | the skeleton | technical' 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'row: ROW-001 -> STAGE-0' 'row: ROW-002 -> STAGE-0'
g add -A && g commit -qm 'the cut with stage 0'
st_rcpt ROW-004=failed; st_keep ROW-001 ROW-002
sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1 || fail 'stage 1 close exited non-zero'
grep -q '^recorded: stage-closed n=1 .* stage: 2$' "$T/out" || fail 'stage 1 was not recorded with stage: 2 next'
grep -qx 'stage: 2' .vid/RUN-STATE.md || fail 'stage: is not 2 after stage 1'
grep -q -- '^- next: stage 2, sharing' .vid/SLICE-REPORTS.md || fail "stage 1's section does not name stage 2 next"
st_rcpt; st_keep ROW-003 ROW-004 ROW-006
H=$(git rev-parse --short=12 HEAD)
sh checks/metrics.sh stage-close --stage 2 --record > "$T/out" 2>&1 || fail 'stage 2 close exited non-zero'
grep -q '^stage-close 2 ready' "$T/out" || fail 'stage 2 is not ready'
grep -q "^stage-closed n=2 sha=$H ready " .vid/metrics-events || fail 'the final stage recorded no stage-closed n=2'
[ "$(git rev-parse --short=12 'vid/stage-2^{commit}' 2>/dev/null)" = "$H" ] || fail 'vid/stage-2 is not at HEAD'
grep -q '^recorded: .*no next stage — the final stage' "$T/out" || fail 'the record does not say there is no next stage'
grep -qx 'stage: 2' .vid/RUN-STATE.md || fail 'the final close set a next stage'
grep -q -- '^- next: none — stage 2 is the final stage' .vid/SLICE-REPORTS.md || fail "the final section names a next stage"
grep -q 'stage: 3' "$T/out" .vid/RUN-STATE.md && fail 'a stage 3 was set'
grep -q '^completion ' .vid/metrics-events && fail 'the close recorded completion itself'
exit 0
