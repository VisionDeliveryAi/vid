#!/bin/sh
# Purpose: selftest case — stage 0 closes, under the setup hold (v0.26.10.8 spec R2, R3; §5 stage-close-0). A gated toy
# run (fixtures/gated-run.sh) with STAGE-0 accepts `test.sh request --type full --stage 0` (stage=0 in its ticket), and
# refuses --stage 0 without STAGE-0. The toy product (fixtures/stages.sh) cut as STAGE-0 (ROW-001, ROW-002), STAGE-1 and
# STAGE-2, RUN-STATE at `stage: 0`, the setup hold asked at stage 0's start (`hold --after 0 --words "staging setup"`):
# with stage 0's rows passing and KEPT and later stages red, `stage-close --stage 0` is ready on its rows alone, and
# --record writes `stage-closed n=0`, tags vid/stage-0, writes `stage-hold n=0 state=on` and `run: stopped staging
# setup after stage 0`, `stage: 1`; the gate is off. Staging set up (a gate-2 pass), `hold --off --setup` records
# `state=off`; with develop's writes (run: active, its run event, its stage start) the gate is on. With the owner's
# own hold also asked, the setup's release records nothing, the hold stays on and the run line becomes the owner's.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; sleep 1; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stage-close-0: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
CUT0() { st_stages 'STAGE-0 | the skeleton | technical' 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'row: ROW-001 -> STAGE-0' 'row: ROW-002 -> STAGE-0'; }
# the request: --stage 0 accepted with STAGE-0, refused without it
gated_repo "$T/req"; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv; st_cut; g add -A && g commit -qm 'a cut without stage 0'; gate_on
if sh checks/test.sh request --type full --stage 0 --role orchestrator --why 'stage 0 close' > "$T/out" 2>&1; then fail '--stage 0 was accepted without STAGE-0'; fi
grep -q '0 when STAGES.md holds STAGE-0' "$T/out" || fail 'the refusal does not say when 0 is taken'
CUT0; g add -A && g commit -qm 'the cut with stage 0'
sh checks/test.sh request --type full --stage 0 --role orchestrator --why 'stage 0 close' > "$T/out" 2>&1 || fail 'the --stage 0 request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); [ -n "$TK" ] && grep -qx 'stage=0' ".vid/requests/$TK/request" || fail 'the ticket does not carry stage=0'
VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > /dev/null 2>&1 || true
# the close
close_repo() { st_close_repo "$1"; CUT0; g add -A && g commit -qm 'the cut with stage 0'
  sed 's/^stage: 1$/stage: 0/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
  printf 'stage name=develop state=start session=S1 at=2026-10-20T10:00:00Z\n' >> .vid/metrics-events
  st_rcpt ROW-003=failed ROW-004=failed ROW-006=failed; st_keep ROW-001 ROW-002; }
close_repo "$T/r"
sh checks/stages.sh hold --after 0 --words 'staging setup' > "$T/out" 2>&1 || fail 'the setup hold was refused for stage 0'
sh checks/metrics.sh stage-close --stage 0 --record > "$T/out" 2>&1 || fail 'stage-close --stage 0 exited non-zero'
grep -qx 'stage-close 0 ready rows=2 debt=0' "$T/out" || fail 'stage 0 is not ready on its rows alone'
H=$(git rev-parse --short=12 HEAD)
grep -q "^stage-closed n=0 sha=$H ready " .vid/metrics-events || fail 'no stage-closed n=0'
[ "$(git rev-parse --short=12 'vid/stage-0^{commit}' 2>/dev/null)" = "$H" ] || fail 'vid/stage-0 is not at HEAD'
grep -q '^stage-hold n=0 state=on at=' .vid/metrics-events || fail 'the setup hold did not turn on'
grep -qx 'run: stopped staging setup after stage 0' .vid/RUN-STATE.md || fail 'the run line is not the setup stop'
grep -qx 'stage: 1' .vid/RUN-STATE.md || fail 'stage: is not 1'
grep -q '^## stage 0 ' .vid/SLICE-REPORTS.md || fail 'no ## stage 0 section'
if sh checks/plan.sh gate > /dev/null 2>&1; then fail 'the gate is on while the setup holds the stage'; fi
printf 'deploy-gate gate=2 state=start candidate=%s env=staging at=2026-10-20T11:00:00Z\ndeploy-gate gate=2 state=end result=pass at=2026-10-20T11:00:05Z\n' "$H" >> .vid/metrics-events
sh checks/stages.sh hold --off --setup > "$T/out" 2>&1 || fail 'the setup release was refused'
grep -q '^released: staging is set up' "$T/out" && grep -q '^stage-hold n=0 state=off at=' .vid/metrics-events || fail 'the release did not record off'
sed 's/^run:.*/run: active/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
printf 'run state=active at=2026-10-20T11:00:06Z\nstage name=develop state=start session=S1 at=2026-10-20T11:00:07Z\n' >> .vid/metrics-events
sh checks/plan.sh gate > "$T/out" 2>&1 || fail 'the gate is not on after the release'
# the owner's own hold too: the release leaves it on
close_repo "$T/r2"
sh checks/stages.sh hold --after 0 --words 'staging setup' > /dev/null 2>&1
sh checks/stages.sh hold --after 0 --words 'hold after this stage' > /dev/null 2>&1
sh checks/metrics.sh stage-close --stage 0 --record > "$T/out" 2>&1
grep -qx 'run: stopped staging setup after stage 0' .vid/RUN-STATE.md || fail 'with both holds the run line is not the setup stop'
sh checks/stages.sh hold --off --setup > "$T/out" 2>&1 || fail 'the setup release with an owner hold exited non-zero'
grep -q '^held: staging is set up; stage 0 stays held, as the owner asked' "$T/out" || fail 'the reply does not say the stage stays held'
grep -q '^stage-hold n=0 state=off' .vid/metrics-events && fail 'the release ended the owner hold'
grep -qx 'run: stopped owner asked to hold after stage 0' .vid/RUN-STATE.md || fail 'the run line is not the owner hold'
sh checks/stages.sh hold --off > "$T/out" 2>&1 && grep -q '^stage-hold n=0 state=off' .vid/metrics-events || fail "the owner's continue did not end the hold"
exit 0
