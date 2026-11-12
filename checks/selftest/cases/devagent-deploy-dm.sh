#!/bin/sh
# Purpose: selftest case — DevAgent's dev manager's side of staging (v0.26.10.26.2 R8), on the fake gh. next gives an issue labelled deploy a line, as it gives a
# run issue: work while it has no vid: reported d1-<k>, wait once it has, work again after a vid: again d1, a ViD comment begun vid: failed at, or a vid: refused d1-<k>
# newer than its newest report, wait while the record's lost d1 <k> came after the k-th again, blocked by its label, nothing once closed. CS, a run issue whose body
# begins close: staging-<N> with its against: line, gets its chunks' lines as any close run. The dev manager's file says who does each: DP the okay, by deploy.sh,
# TM the CS chunks with --against. The row grader's file is as at 00109a8, the second reviewer's as at aa6e610. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-deploy-dm: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_fake; W=$T/work; mkdir -p "$W/tickets"; DM_WORK=$W; export DM_WORK
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/dm-note.txt"
g() { gh "$@" > /dev/null; }
is() { sh "$DM" next > "$T/out" 2>&1 || fail 'next failed'; [ "$(cat "$T/out")" = "$1" ] || { echo "wanted: $1" >&2; fail 'next printed the wrong lines'; }; }
cm() { printf '%s\n' "$2" > "$T/b"; g issue comment "$1" -R owner/code --body-file "$T/b"; }
C=$(printf '%040d' 7)
printf 'okay: staging\ncommit: %s\nseed: synthetic\n\nDeploy this commit to staging.\n' "$C" > "$T/b"
DN=$(gh issue create -R owner/code --title 'Staging okay: stage 1' --body-file "$T/b" --label deploy); DN=${DN##*/}
is "work $DN"
cm "$DN" 'vid: started
by: DP'; is "work $DN"
cm "$DN" 'vid: reported d1-1
by: DP'; is "wait $DN"
cm "$DN" 'vid: failed at migrate: deploy again and report as attempt 2'; is "work $DN"
cm "$DN" 'vid: reported d1-2'; is "wait $DN"
cm "$DN" 'vid: failed'; is "wait $DN"
cm "$DN" 'vid: refused d1-2 — no differs: line'; is "work $DN"
cm "$DN" 'vid: reported d1-3'; is "wait $DN"
cm "$DN" 'vid: refused s1-3'; is "wait $DN"
cm "$DN" 'vid: again d1'; is "work $DN"
echo 'lost d1 1' > "$W/tickets/$DN.txt"; is "wait $DN"
cm "$DN" 'vid: again d1'; is "work $DN"
g issue edit "$DN" -R owner/code --add-label blocked; is "blocked $DN"
g issue close "$DN" -R owner/code; is none
# a grade's refusal still calls for its next attempt, and a deploy's failed at does not reach a grade
printf 'grade: stage-1\ncommit: %s\nrequirements: REQ-1\n' "$C" > "$T/b"; GN=$(gh issue create -R owner/code --title 'Stage grade' --body-file "$T/b" --label grade); GN=${GN##*/}
cm "$GN" 'vid: reported s1-1'; cm "$GN" 'vid: failed at migrate: deploy again and report as attempt 2'; is "wait $GN"
cm "$GN" 'vid: refused — no line for REQ-1'; is "work $GN"; g issue close "$GN" -R owner/code
# CS: a run issue, its chunks as any close run's
printf 'close: staging-1\ncommit: %s\nagainst: http://127.0.0.1:47100\nsignin: admin http://127.0.0.1:47100/_test/signin?role=admin\nengines: alpha beta\n\n- chunk p1c1, alpha: ROW-001 SEAM-001\n- chunk p2c1, beta: ROW-001\n' "$C" > "$T/b"
RN=$(gh issue create -R owner/code --title 'Close run: staging 1' --body-file "$T/b" --label run); RN=${RN##*/}
is "work $RN"; cm "$RN" 'vid: reported p1c1-1'; is "work $RN"; cm "$RN" 'vid: reported p2c1-1'; is "wait $RN"
cm "$RN" 'vid: failed at migrate: deploy again and report as attempt 2'; is "wait $RN"
g issue close "$RN" -R owner/code; is none
# the files
for l in '## A staging okay, D1' '`<prefix>deploy`' 'okay: staging' 'seed: synthetic' 'deploy.sh deploy' 'deploy-<n>' 'vid: reported d1-<k>' 'by: DP' 'vid: again d1' '`vid: failed at`' '`vid: refused d1-<k>`' \
  'lost d1 <k>' '--fail-step' '--product-change' 'deploy.sh stop' 'deploy.sh live' 'close: staging-<N>' 'against:' '--against' '--signin' 'BASE_URL' '**Who does each:**' 'the deployer, DP'; do
  grep -qF -- "$l" "$RT/devagent/agents/dev-manager.md" || fail "the dev manager's file lacks: $l"; done
! git -C "$RT" cat-file -e 00109a8 2> /dev/null || [ "$(git -C "$RT" rev-parse 00109a8:standin/agents/grader.md 2>/dev/null)" = "$(git -C "$RT" hash-object devagent/agents/grader.md)" ] || fail "the row grader's file changed since 00109a8"
! git -C "$RT" cat-file -e aa6e610 2> /dev/null || [ "$(git -C "$RT" rev-parse aa6e610:standin/agents/second-reviewer.md 2>/dev/null)" = "$(git -C "$RT" hash-object devagent/agents/second-reviewer.md)" ] || fail "the second reviewer's file changed since aa6e610"
exit 0
