#!/bin/sh
# Purpose: selftest case — FB-2 A4: DevAgent's side of a take-down okay. dm.sh next gives an issue labelled deploy whose body begins
# `okay: down staging` a line, the chunk dn, worked as D1's: work while it has no `vid: reported dn-<k>`, wait once it has, work again
# after a `vid: refused dn-<k>` or a `vid: again dn` newer than its newest report; dev-manager.md has its paragraph, "A take-down okay".
# deploy.sh stop --target staging --report deploy-<n> --commit <c>, on a live local staging: its process gone, its port silent, the
# report pushed alone on vid-results/deploy-<n>-1 (`outcome: down`, `down: staging <address>`, `decisions: none`), live none.
# --target production on the live local copy: down, the report pushed, its data store kept. A hosted staging with no host-down: in
# the record: `outcome: failed down — the record names no host-down:`, pushed, and the address still answers (fixtures/devagent-host.sh).
# With host-down: in the record: failing, `outcome: failed down — host-down: exited 3` and the site still answers; working, `outcome:
# down`, `down: staging <address>`, the address silent and live none. A hosted production under --report: exit 1, nothing pushed. A
# host-down: that exits 0 while the address still answers: `outcome: failed down — <address> still answers after host-down:`, the
# live record kept.
# A take-down whose report's push fails (the origin refuses it): exit 1, the staging down; run again, that kept report is pushed as it
# was, `outcome: down`, nothing repeated.
# Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
command -v nc > /dev/null 2>&1 && command -v curl > /dev/null 2>&1 || { echo 'devagent-down: no nc or curl, skipped' >&2; exit 0; }
RT=$(cd "$CHECKS/.." && pwd -P); DM=$RT/devagent/dev-manager/dm.sh; DP=$RT/devagent/deployer/deploy.sh; FHT=$(cd "$CHECKS/selftest/fixtures" && pwd -P)/devagent-host.sh
T=$(mktemp -d)
. "$CHECKS/selftest/fixtures/tickets.sh"
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-down: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the dev manager's line
gh_fake; W=$T/work; mkdir -p "$W/tickets"; DM_WORK=$W; export DM_WORK
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/dm-note.txt"
g() { gh "$@" > /dev/null; }
is() { sh "$DM" next > "$T/out" 2>&1 || fail 'next failed'; [ "$(cat "$T/out")" = "$1" ] || { echo "wanted: $1" >&2; fail 'next printed the wrong lines'; }; }
cm() { printf '%s\n' "$2" > "$T/b"; g issue comment "$1" -R owner/code --body-file "$T/b"; }
C=$(printf '%040d' 7)
printf 'okay: down staging\ncommit: %s\naddress: http://127.0.0.1:47100\n\nTake the test site down.\n' "$C" > "$T/b"
DN=$(gh issue create -R owner/code --title 'Take down the test site: stage 1, candidate 1' --body-file "$T/b" --label deploy); DN=${DN##*/}
is "work $DN"
cm "$DN" 'vid: started
by: DP'; is "work $DN"
cm "$DN" 'vid: reported dn-1
by: DP'; is "wait $DN"
cm "$DN" 'vid: refused dn-1'; is "work $DN"
cm "$DN" 'vid: reported dn-2'; is "wait $DN"
cm "$DN" 'vid: again dn'; is "work $DN"
g issue close "$DN" -R owner/code; is none
grep -q '^## A take-down okay' "$RT/devagent/agents/dev-manager.md" || fail 'dev-manager.md has no paragraph for a take-down okay'
grep -qF 'deploy.sh stop --setup <record> --target staging|production --report deploy-<n> --commit <the commit>' "$RT/devagent/agents/dev-manager.md" || fail "dev-manager.md does not give the take-down's command"
# the deployer: a local staging, then the local live copy; its ports from its own bases, so that no deploy of a case running beside it takes
# the port it has just freed
DP_PORT=47700; DP_PRODUCTION_PORT=47800; export DP_PORT DP_PRODUCTION_PORT
sp_project; cd "$T"; S=$W/dev-setup.txt; O="git -C $T/origin.git"; DEVAGENT_ENVIRONMENTS=$T/envs; export DEVAGENT_ENVIRONMENTS
FH=$T/host; mkdir -p "$FH"; export FH
dn() { sh "$DP" stop --setup "$S" --target production > /dev/null 2>&1 || true; for f in "$T"/listen-*; do [ -f "$f" ] && kill "$(cat "$f")" 2> /dev/null || true; done; sh "$FHT" down > /dev/null 2>&1 || true; }
trap 'dn; rm -rf "$T"' EXIT
C1=$(git -C "$T/dev" rev-parse HEAD)
cat > "$S" <<X
repo: $T/origin.git
engines: alpha beta
environments: 2
case-limit: 3
ready-seconds: 5
start: nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & echo \$! > "\$SP_T/listen-\$RUN_ID"
stop: echo "\$RUN_ID" >> "\$SP_T/stops"
run: sh tests/runner.sh
backup: cp "\$DATA_DIR/data.txt" "\$DUMP"
restore: cp "\$DUMP" "\$DATA_DIR/data.txt"
migrate: echo "migrated by \$RUN_ID" >> "\$DATA_DIR/data.txt"
production-seed: echo "sample: customer-1, labelled sample data" >> "\$DATA_DIR/data.txt"
X
dp() { RC=0; sh "$DP" "$@" > "$T/out" 2>&1 || RC=$?; }
up() { nc -z -w 1 127.0.0.1 "$1" > /dev/null 2>&1; }
shw() { $O show "vid-results/$1:$1/$2"; }
tree() { $O ls-tree -r --name-only "vid-results/$1" | tr '\n' ' '; }
dp deploy --setup "$S" --ask deploy-30 --commit "$C1"; [ "$RC" = 0 ] || fail "the staging deploy exited $RC"
P=$(shw deploy-30-1 staging.txt | sed -n 's|^staging: http://127.0.0.1:\([0-9][0-9]*\)$|\1|p'); [ -n "$P" ] && up "$P" || fail 'the staging is not up'
dp stop --setup "$S" --target staging --report deploy-31 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-31-1' "$T/out" || fail "the staging's take-down exited $RC"
[ "$(tree deploy-31-1)" = 'deploy-31-1/report.txt ' ] || fail "the take-down's tree: $(tree deploy-31-1)"
[ "$(shw deploy-31-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: down\ndown: staging http://127.0.0.1:%s' "$C1" "$P")" ] || fail "the staging take-down's report: $(shw deploy-31-1 report.txt)"
! up "$P" || fail 'the staging still answers after its take-down'; dp live --setup "$S"; grep -qx 'live none' "$T/out" || fail "a staging is still live: $(cat "$T/out")"
# FB-2 A4: a take-down done and its report not pushed: the retry pushes that report, outcome: down, and repeats nothing
dp deploy --setup "$S" --ask deploy-32 --commit "$C1"; [ "$RC" = 0 ] || fail "the second staging deploy exited $RC"
P2=$(shw deploy-32-1 staging.txt | sed -n 's|^staging: http://127.0.0.1:\([0-9][0-9]*\)$|\1|p'); [ -n "$P2" ] && up "$P2" || fail 'the second staging is not up'
printf '#!/bin/sh\nwhile read -r o n r; do case $r in refs/heads/vid-results/deploy-33-*) [ ! -f "%s/refuse" ] || exit 1 ;; esac; done\nexit 0\n' "$T" > "$T/origin.git/hooks/pre-receive"; chmod +x "$T/origin.git/hooks/pre-receive"; : > "$T/refuse"
dp stop --setup "$S" --target staging --report deploy-33 --commit "$C1"; [ "$RC" = 1 ] && grep -q 'not pushed: vid-results/deploy-33-1' "$T/out" || fail "the take-down whose push fails exited $RC"
! up "$P2" || fail 'the staging still answers after its take-down whose push failed'; rm -f "$T/refuse"
dp stop --setup "$S" --target staging --report deploy-33 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-33-1' "$T/out" || fail "the take-down's retry exited $RC"
[ "$(shw deploy-33-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: down\ndown: staging http://127.0.0.1:%s' "$C1" "$P2")" ] || fail "the retry did not push the kept report of the take-down: $(shw deploy-33-1 report.txt)"
dp deploy --setup "$S" --target production --ask deploy-40 --commit "$C1"; [ "$RC" = 0 ] || fail "the production deploy exited $RC"
Q=$(shw deploy-40-1 report.txt | sed -n 's|^production: http://127.0.0.1:\([0-9][0-9]*\)$|\1|p'); [ -n "$Q" ] && up "$Q" || fail 'the live copy is not up'
dp stop --setup "$S" --target production --report deploy-41 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-41-1' "$T/out" || fail "the live copy's take-down exited $RC"
shw deploy-41-1 report.txt | grep -qx 'outcome: down' && shw deploy-41-1 report.txt | grep -qx "down: production http://127.0.0.1:$Q" || fail "the live copy's take-down report: $(shw deploy-41-1 report.txt)"
! up "$Q" || fail 'the live copy still answers after its take-down'; [ -s "$W/production/data/data.txt" ] || fail "the live copy's data store is gone"
dp production --setup "$S"; grep -q '^production stopped' "$T/out" || fail "production after its take-down: $(cat "$T/out")"
# a hosted staging, its record naming no host-down:
up() { nc -z -w 1 127.0.0.1 "$1" > /dev/null 2>&1; }; free() { p=$1; while up "$p"; do p=$((p + 1)); done; echo "$p"; }
FH_STAGING_PORT=$(free 47930); FH_PRODUCTION_PORT=$(free $((FH_STAGING_PORT + 1))); export FH_STAGING_PORT FH_PRODUCTION_PORT; SA=http://127.0.0.1:$FH_STAGING_PORT
W3=$T/work3; mkdir -p "$W3"; S3=$W3/dev-setup.txt
{ printf 'repo: %s\nengines: alpha\nready-seconds: 5\nhost: fakehost\nstaging-address: %s\nproduction-address: http://127.0.0.1:%s\nhost-login: sh "%s" login\ndeploy: sh "%s" deploy\n' "$T/origin.git" "$SA" "$FH_PRODUCTION_PORT" "$FHT" "$FHT"
  for d in log-in environments outside-services sending-domain deploy-notes captures; do printf 'duty: %s — not needed — a toy host\n' "$d"; done; } > "$S3"
dp deploy --setup "$S3" --ask deploy-50 --commit "$C1"; [ "$RC" = 0 ] || fail "the hosted staging deploy exited $RC"
web() { [ "$(curl -s -o /dev/null -m 3 -w '%{http_code}' "$1" 2>/dev/null || true)" != 000 ]; }; web "$SA" || fail 'the hosted staging does not answer'
dp stop --setup "$S3" --target staging --report deploy-51 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-51-1' "$T/out" || fail "the hosted take-down with no host-down: exited $RC"
shw deploy-51-1 report.txt | grep -qx 'outcome: failed down — the record names no host-down:' || fail "the hosted take-down's report: $(shw deploy-51-1 report.txt)"
web "$SA" || fail 'the hosted staging stopped with no host-down: in the record'
# FB-2 A4: the record's host-down:, failing (exit 3) and then working; a hosted production is never taken down under --report
printf 'host-down: sh "%s" down\n' "$FHT" >> "$S3"; : > "$FH/fail-down"
dp stop --setup "$S3" --target staging --report deploy-52 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-52-1' "$T/out" || fail "the hosted take-down whose host-down: fails exited $RC"
shw deploy-52-1 report.txt | grep -q '^outcome: failed down — host-down: exited 3' || fail "the failed host-down:'s report: $(shw deploy-52-1 report.txt)"
grep -q '^down staging deploy-52-1 ' "$FH/calls" || fail "host-down: was not run with the staging target: $(cat "$FH/calls")"; web "$SA" || fail 'the hosted staging stopped though its host-down: failed'
rm -f "$FH/fail-down"; dp stop --setup "$S3" --target staging --report deploy-53 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-53-1' "$T/out" || fail "the hosted take-down exited $RC"
shw deploy-53-1 report.txt | grep -qx 'outcome: down' && shw deploy-53-1 report.txt | grep -qx "down: staging $SA" || fail "the hosted take-down's report: $(shw deploy-53-1 report.txt)"
! web "$SA" || fail 'the hosted staging still answers after its take-down'; dp live --setup "$S3"; grep -qx 'live none' "$T/out" || fail "the hosted staging is still live: $(cat "$T/out")"
dp stop --setup "$S3" --target production --report deploy-54 --commit "$C1"; [ "$RC" = 1 ] && grep -q 'a hosted production is not taken down by deploy.sh' "$T/out" || fail "a hosted production's take-down exited $RC: $(cat "$T/out")"
[ -z "$(git ls-remote --heads "$T/origin.git" 'vid-results/deploy-54-*')" ] || fail "a hosted production's take-down pushed a report"
# FB-2 A4: host-down: exits 0 and the address still answers: failed down, the live record kept
dp deploy --setup "$S3" --ask deploy-55 --commit "$C1"; [ "$RC" = 0 ] || fail "the hosted staging's deploy again exited $RC"; web "$SA" || fail 'the hosted staging does not answer again'
grep -v '^host-down:' "$S3" > "$T/s3"; { cat "$T/s3"; echo 'host-down: true'; } > "$S3"
dp stop --setup "$S3" --target staging --report deploy-56 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-56-1' "$T/out" || fail "the take-down whose host-down: stops nothing exited $RC"
shw deploy-56-1 report.txt | grep -qx "outcome: failed down — $SA still answers after host-down:" || fail "the take-down whose host-down: stops nothing: $(shw deploy-56-1 report.txt)"
web "$SA" || fail 'the hosted staging stopped though host-down: stops nothing'; dp live --setup "$S3"; grep -q '^live deploy-55-1 ' "$T/out" || fail "the live record was not kept: $(cat "$T/out")"
exit 0
