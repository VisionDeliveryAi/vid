#!/bin/sh
# Purpose: selftest case — DevAgent's dev manager's side of the rehearsal and production (v0.26.10.27.1 R8), on the fake gh. next reads a deploy-labelled issue's
# body: `okay: rehearsal` is one chunk, rh, worked as a staging okay's d1 (work while it has no vid: reported rh-<k>, again after a vid: again rh, a vid: refused rh-<k>
# or a vid: failed at newer than its newest report, wait after a lost rh <k>); `okay: production` is one chunk, d2, whose next attempt only a vid: again d2 or a
# vid: refused d2-<k> calls for, never a vid: failed at; and a comment begun `Production failed at` or `Production's deploy of` newer than its newest
# vid: recovered calls for work, the recovery, blocked by its label while a question waits. A staging okay is untouched by those. CR and CP, run issues whose bodies
# begin close: rehearsal-<N> and close: production-<N>, get their chunks' lines as any close run. The dev manager's file says who does each: DP the okays and the
# recovery by deploy.sh, TM the CR and CP chunks, CP's sign-ins from the record. The row grader's file is as at 00109a8, the second reviewer's as at aa6e610.
# Skips where devagent/ is absent (a project's layout). Env: CHECKS.
# 0.26.11.1.1 (R2): a hosted okay, the record's host: or a `> platform:` line in its hosting, and every recovery of a hosted production, go to the
# deployer, started by `sh dm.sh start deployer`; with `deploy: local` the dev manager deploys as before, its stand-in seam: lines written first.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-prod-dm: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_fake; W=$T/work; mkdir -p "$W/tickets"; DM_WORK=$W; export DM_WORK
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/dm-note.txt"
g() { gh "$@" > /dev/null; }
is() { sh "$DM" next > "$T/out" 2>&1 || fail 'next failed'; [ "$(cat "$T/out")" = "$1" ] || { echo "wanted: $1" >&2; fail 'next printed the wrong lines'; }; }
cm() { printf '%s\n' "$2" > "$T/b"; g issue comment "$1" -R owner/code --body-file "$T/b"; }
okay() { printf 'okay: %s\ncommit: %s\n\nThe instruction.\n' "$1" "$C" > "$T/b"; n=$(gh issue create -R owner/code --title "Okay: $1" --body-file "$T/b" --label deploy); echo "${n##*/}"; }
C=$(printf '%040d' 7)
# the rehearsal okay: rh, as d1
HN=$(okay rehearsal); is "work $HN"
cm "$HN" 'vid: started
by: DP'; is "work $HN"
cm "$HN" 'vid: reported rh-1
by: DP'; is "wait $HN"
cm "$HN" 'vid: failed at boot: deploy again and report as attempt 2'; is "work $HN"
cm "$HN" 'vid: reported rh-2'; is "wait $HN"
cm "$HN" 'vid: refused rh-2 — a passed rehearsal is not sealed: yes'; is "work $HN"
cm "$HN" 'vid: reported rh-3'; is "wait $HN"
cm "$HN" 'vid: refused d1-3 — not this chunk'; is "wait $HN"
cm "$HN" 'Production failed at boot. Recover as you judge'; is "wait $HN"
cm "$HN" 'vid: again rh'; is "work $HN"
echo 'lost rh 1' > "$W/tickets/$HN.txt"; is "wait $HN"
g issue close "$HN" -R owner/code; is none
# the production okay: d2, and the recovery
PN=$(okay production); is "work $PN"
cm "$PN" 'vid: reported d2-1
by: DP'; is "wait $PN"
cm "$PN" 'vid: failed at migrate: not for a production okay'; is "wait $PN"
cm "$PN" 'Production failed at migrate. Recover as you judge; before a restore that would lose writes, ask here first; comment `vid: recovered <the commit production runs now, or none if no production exists yet> — <what you did>` here.'; is "work $PN"
cm "$PN" 'Question: restore deploy-1-1'"'"'s backup, losing the writes since? — the recovery point and the writes at risk
by: DP'; is "work $PN"
g issue edit "$PN" -R owner/code --add-label blocked; is "blocked $PN"
cm "$PN" 'RM: Question: restore … — yes'; g issue edit "$PN" -R owner/code --remove-label blocked; is "work $PN"
cm "$PN" 'vid: recovered 0000000000000000000000000000000000000006 — restored the backup
by: DP'; is "wait $PN"
cm "$PN" 'vid: refused d2-1 — no production: line'; is "work $PN"
cm "$PN" 'vid: reported d2-2'; is "wait $PN"
cm "$PN" 'vid: again d2'; is "work $PN"
echo 'lost d2 1' > "$W/tickets/$PN.txt"; is "wait $PN"
cm "$PN" "Production's deploy of 000000000007 has not reported: what does production run now?"; is "work $PN"
cm "$PN" 'vid: recovered none — the deploy never ran'; is "wait $PN"
g issue close "$PN" -R owner/code; is none
# a staging okay: RM's production comments do not reach it
SN=$(okay staging); cm "$SN" 'vid: reported d1-1'; cm "$SN" 'Production failed at migrate. Recover as you judge'; is "wait $SN"
cm "$SN" 'vid: failed at migrate: deploy again'; is "work $SN"; g issue close "$SN" -R owner/code
# CR and CP: run issues, their chunks as any close run's
for k in rehearsal production; do printf 'close: %s-1\ncommit: %s\nagainst: http://127.0.0.1:47500\nengines: alpha\n\n- chunk p1c1, alpha: ROW-001\n' "$k" "$C" > "$T/b"
  RN=$(gh issue create -R owner/code --title "Close run: $k 1" --body-file "$T/b" --label run); RN=${RN##*/}
  is "work $RN"; cm "$RN" 'vid: reported p1c1-1'; is "wait $RN"; cm "$RN" 'Production failed at rows ROW-001. Recover as you judge'; is "wait $RN"; g issue close "$RN" -R owner/code; done
is none
# the files
for l in '## A rehearsal okay, RH' 'okay: rehearsal' '--target rehearsal' 'vid: reported rh-<k>' 'vid: again rh' '`vid: refused rh-<k>`' 'lost rh <k>' 'no backup yet' 'sealed-start:' \
  'change-migrates:' 'change-drops:' 'change-rewrites:' 'change-services:' 'deploy.sh stop --setup <record> --ask deploy-<n>' \
  '## A production okay, D2' 'okay: production' '--target production' 'vid: reported d2-<k>' 'vid: again d2' '`vid: refused d2-<k>`' 'lost d2 <k>' 'deploy.sh production' 'production-seed:' \
  '## A recovery' '`Production failed at`' "\`Production's deploy of … has not reported\`" 'deploy.sh rollback' 'deploy.sh restore' '--lose-writes' 'Question:' 'blocked label' \
  'vid: recovered <the commit production runs now, or none> — <what you did>' 'close: rehearsal-<N>' 'close: production-<N>' 'production-signin:' 'ViD never sees them' '--plant-red' \
  'backup:' 'restore:' 'migrate:' '| A recovery |' '| A rehearsal okay, RH |' '| A production okay, D2 |'; do
  grep -qF -- "$l" "$RT/devagent/agents/dev-manager.md" || fail "the dev manager's file lacks: $l"; done
for l in 'sh dm.sh start deployer' '`deploy: local`' 'each recovery'; do
  grep -qF -- "$l" "$RT/devagent/agents/dev-manager.md" || fail "the dev manager's file lacks: $l"; done
! git -C "$RT" cat-file -e 00109a8 2> /dev/null || [ "$(git -C "$RT" rev-parse 00109a8:standin/agents/grader.md 2>/dev/null)" = "$(sed -f "$CHECKS/selftest/fixtures/grader-dp1-r3.sed" "$RT/devagent/agents/grader.md" | git hash-object --stdin)" ] || fail "the row grader's file changed since 00109a8, beyond DP-1 R3's two sentences"
! git -C "$RT" cat-file -e aa6e610 2> /dev/null || [ "$(git -C "$RT" rev-parse aa6e610:standin/agents/second-reviewer.md 2>/dev/null)" = "$(git -C "$RT" hash-object devagent/agents/second-reviewer.md)" ] || fail "the second reviewer's file changed since aa6e610"
exit 0
