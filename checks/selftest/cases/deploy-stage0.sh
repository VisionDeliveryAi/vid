#!/bin/sh
# Purpose: selftest case — stage 0 never goes to production (v0.26.10.8 spec R5; §5 deploy-stage0). The toy product
# (fixtures/stages.sh) cut as STAGE-0, STAGE-1 and STAGE-2, stage 0 closed (vid/stage-0) and develop paused: `stages.sh
# deploy --target production` refuses with one line, recording nothing, and so does `candidate --target production`,
# even with a gate-2 pass on stage 0's tag; staging is accepted, its candidate stage 0's tag. Held for the staging
# setup after stage 0, production is refused the same way and staging takes HEAD. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "deploy-stage0: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
L='deploy: refused — Stage 0 is technical and never goes live; production takes stage 1 or later.'
st_close_repo "$T/r"
st_stages 'STAGE-0 | the skeleton | technical' 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'row: ROW-001 -> STAGE-0' 'row: ROW-002 -> STAGE-0'
g add -A && g commit -qm 'the cut with stage 0'
sed 's/^stage: 1$/stage: 0/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
st_rcpt ROW-004=failed; st_keep ROW-001 ROW-002
cp -R . "$T/held"
sh checks/metrics.sh stage-close --stage 0 --record > "$T/out" 2>&1 && grep -q '^recorded: stage-closed n=0' "$T/out" || fail 'stage 0 did not close'
sed 's/^run:.*/run: stopped owner asked to pause/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
TAG0=$(git rev-parse --short=12 'vid/stage-0^{commit}')
printf 'deploy-gate gate=2 state=start candidate=%s env=staging at=2026-10-20T11:00:00Z\ndeploy-gate gate=2 state=end result=pass at=2026-10-20T11:00:05Z\n' "$TAG0" >> .vid/metrics-events
N=$(wc -l < .vid/metrics-events)
if sh checks/stages.sh deploy --target production --platform none > "$T/out" 2>&1; then fail 'production was accepted with stage 0 the newest closed stage'; fi
[ "$(grep -c . "$T/out")" -eq 1 ] && grep -qxF "$L" "$T/out" || fail "the refusal is not the one line: $(cat "$T/out")"
[ "$(wc -l < .vid/metrics-events)" -eq "$N" ] || fail 'the refusal recorded something'
if sh checks/stages.sh candidate --target production > "$T/out" 2>&1; then fail 'the production candidate was given for stage 0'; fi
grep -q '^refused Stage 0 is technical and never goes live' "$T/out" || fail 'candidate --target production does not say why'
sh checks/stages.sh deploy --target staging --platform none > "$T/out" 2>&1 || fail 'staging was refused for stage 0'
grep -q "^candidate: stage 0 vid/stage-0 $TAG0 " "$T/out" || fail "staging's candidate is not stage 0's tag"
# held for the staging setup after stage 0: production refused, staging takes HEAD
cd "$T/held"
sh checks/stages.sh hold --after 0 --words 'staging setup' > /dev/null 2>&1 || fail 'the setup hold was refused'
sh checks/metrics.sh stage-close --stage 0 --record > "$T/out" 2>&1 && grep -qx 'run: stopped staging setup after stage 0' .vid/RUN-STATE.md || fail 'the held close did not stop for the setup'
if sh checks/stages.sh deploy --target production --platform none > "$T/out" 2>&1; then fail 'production was accepted while stage 0 is held'; fi
grep -qxF "$L" "$T/out" || fail 'the held refusal is not the one line'
sh checks/stages.sh candidate --target staging > "$T/out" 2>&1 && grep -qx "candidate $(git rev-parse --short=12 HEAD) head - 0" "$T/out" || fail 'while held for the setup the staging candidate is not HEAD'
exit 0
