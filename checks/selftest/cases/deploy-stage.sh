#!/bin/sh
# Purpose: selftest case — deploy ships a closed stage (v0.26.10.5 spec R10–R15; §5 deploy-stage). A toy two-stage
# product (fixtures/stages.sh): before any close, `stages.sh deploy` claims "no stage closed yet" with no candidate;
# stage 1 closed (`stage-closed`, the tag vid/stage-1) and a correction committed after it: refused while a develop
# run is active; paused, the claim reads the record, the candidate is the tag's commit, not HEAD, and the extracted
# tree is the tag's (the correction absent); `since:` names the correction; a deploy log whose production row is a
# newer commit refuses the candidate (v0.26.10.7 R11: production's commit is no ancestor of it). A bare deploy is
# staging's (v0.26.10.7 R1, R2): its output here is unchanged. First deploy (a fake deploy log and events): no production row, no gate-3
# start and --platform none allows gate 1's skip; a production row, a gate-3 start with no row, or a platform
# showing production does not. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "deploy-stage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
st_close_repo "$T/repo"
sh checks/stages.sh deploy --platform none > "$T/out" 2>&1 || fail 'deploy before any close exited non-zero'
grep -qx 'claim: no stage closed yet — preparation may proceed; the gates do not open' "$T/out" && grep -qx 'candidate: none' "$T/out" || fail 'before any close: not "no stage closed yet" with no candidate'
st_rcpt ROW-004=failed; st_keep ROW-001 ROW-002
sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1 || fail 'the close was not recorded'
TAGC=$(git rev-parse --short=12 "vid/stage-1^{commit}")
printf '# Purpose: toy app — REQ-001 REQ-002 REQ-003 REQ-004 REQ-005\n# a correction after the close\n' > app/main.py
g commit -qam 'a correction to stage 1'
# a develop run active: refused, one line
printf 'stage name=develop state=start session=S1 records=25 at=2026-10-20T00:00:00Z\n' >> .vid/metrics-events
if sh checks/stages.sh deploy --platform none > "$T/out" 2>&1; then fail 'deploy ran while a develop run was active'; fi
grep -q '^deploy: refused — a build is running. Say "pause" to the build, deploy, then say "continue"' "$T/out" || fail 'the refusal is not the pause line'
# paused: the claim, the candidate, the tree, since
sed 's/^run:.*/run: stopped owner asked to pause/' .vid/RUN-STATE.md > .vid/rs && mv .vid/rs .vid/RUN-STATE.md
sh checks/stages.sh deploy --platform none --tree "$T/ship" > "$T/out" 2>&1 || fail 'deploy refused while paused'
grep -q '^claim: stage 1 complete (stage-closed n=1 sha=' "$T/out" || fail 'the claim does not read the record'
grep -q "^candidate: stage 1 vid/stage-1 $TAGC " "$T/out" || fail "the candidate is not the tag's commit $TAGC"
[ -f "$T/ship/app/main.py" ] && ! grep -q 'a correction after the close' "$T/ship/app/main.py" || fail "the shipped tree is not the tag's (the working tree's correction is in it)"
grep -q "^since: 1 commits since stage 1's close" "$T/out" && grep -q 'a correction to stage 1' "$T/out" || fail 'the correction since the tag is not named'
grep -q '^first-deploy: yes' "$T/out" || fail 'no production row, no gate-3 start, platform none: not a first deploy'
# a gate-3 start with no log row: an interrupted cutover, not a first deploy
printf 'deploy-gate gate=3 state=start candidate=%s env=production at=2026-10-20T00:00:01Z\n' "$TAGC" >> .vid/metrics-events
sh checks/stages.sh deploy --platform none > "$T/out" 2>&1 || true
grep -q '^first-deploy: no (a gate-3 start was recorded and the deploy log holds no row: an interrupted cutover)' "$T/out" || fail 'a gate-3 start with no row allowed the skip'
sed '/^deploy-gate /d' .vid/metrics-events > .vid/ev && mv .vid/ev .vid/metrics-events
sh checks/stages.sh deploy --platform present > "$T/out" 2>&1 || true
grep -q '^first-deploy: no (the platform shows a production deployment)' "$T/out" || fail 'a platform showing production allowed the skip'
# a production row at the tag: gate 1 applies; a production row newer than the candidate refuses it
printf '# Deployment\n\n## Deploy log (append-only)\n\n| Version | Date | Commit | Migration | Backup ref | Previous build |\n|---|---|---|---|---|---|\n| v0.1 | 2026-10-20 | %s | no | - | - |\n' "$TAGC" > DEPLOYMENT.md
sh checks/stages.sh deploy --platform none > "$T/out" 2>&1 || fail 'a production row at the candidate refused it'
grep -q "^first-deploy: no (the deploy log holds a production row: $TAGC)" "$T/out" || fail 'a production row allowed the skip'
printf '| v0.2 | 2026-10-20 | %s | no | - | - |\n' "$(git rev-parse --short=12 HEAD)" >> DEPLOYMENT.md
if sh checks/stages.sh deploy --platform none > "$T/out" 2>&1; then fail 'a candidate older than production was not refused'; fi
grep -q '^candidate: refused — production runs .*, and the candidate .* does not descend from it; production only moves forward' "$T/out" || fail 'the refusal does not say production only moves forward (v0.26.10.7 R11)'
exit 0
