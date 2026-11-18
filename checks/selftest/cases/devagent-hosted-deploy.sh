#!/bin/sh
# Purpose: selftest case — DevAgent's deployer's hosted mode (0.26.11.1.1, R1, R3, R4, R5, R6), on the fixture project with a local bare repository
# as origin and a stand-in host (fixtures/devagent-host.sh, a script that logs its calls and serves the product on 127.0.0.1). With host: in the dev
# setup record: host-login: runs before any step, and its failure refuses with exit 1, naming the log-in, nothing called or pushed; a deploy whose
# record lacks a duty: line of its target is refused, a plant needs none. Staging: checkout, migrate, deploy, the record's seed:, ready (the
# address giving a web answer), no start:, no port of its own (PORT and DATA_DIR empty), no test environment; staging.txt with the address, its
# seam: lines, seed: synthetic and stays: up; duties.txt with the six staging duties; stop --ask leaves it up; live names it. A deploy whose address
# never answers fails ready. Production: backup (nothing to back up on the first), checkout, migrate, deploy, ready; no production-seed:; report.txt
# with production: and, the first time alone, logs: from production-logs:; duties.txt with the seven production duties; the next deploy backs up the
# host's store by backup: (TARGET=production) and is not taken as the first. The rehearsal: no backup yet before production; after, a local copy
# (start: on a port of its own, a test environment) whose dump is taken by backup: with TARGET=production, then the kept step. --seed production:
# refused before production; after, production's dump by backup: loaded by restore: (TARGET=staging) as the step seed, before migrate, the record's
# seed: not run, seed: production in staging.txt. A restore is refused, exit 5, without --lose-writes, naming the recovery point; with it, the
# backup restored and the earlier commit deployed. A rollback deploys the earlier commit; with no earlier commit it is refused and production stays
# up. A failed step reports no duties.txt. stop --target production is refused for a hosted production. Skips where devagent/ is absent (a
# project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
command -v nc > /dev/null 2>&1 && command -v curl > /dev/null 2>&1 || { echo 'devagent-hosted-deploy: no nc or curl, skipped' >&2; exit 0; }
DP=$CHECKS/../devagent/deployer/deploy.sh; FHT=$(cd "$CHECKS/selftest/fixtures" && pwd -P)/devagent-host.sh
T=$(mktemp -d)
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-hosted-deploy: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
FH=$T/host; mkdir -p "$FH"; DEVAGENT_ENVIRONMENTS=$T/envs; export FH DEVAGENT_ENVIRONMENTS
up() { nc -z -w 1 127.0.0.1 "$1" > /dev/null 2>&1; }
free() { p=$1; while up "$p"; do p=$((p + 1)); done; echo "$p"; }
FH_STAGING_PORT=$(free 47910); FH_PRODUCTION_PORT=$(free $((FH_STAGING_PORT + 1))); export FH_STAGING_PORT FH_PRODUCTION_PORT
SA=http://127.0.0.1:$FH_STAGING_PORT; PA=http://127.0.0.1:$FH_PRODUCTION_PORT
sp_project; cd "$T"; W=$T/work; S=$W/dev-setup.txt; O="git -C $T/origin.git"
down() { for a in $(sed 's/-[0-9]*$//' "$W/rehearsal/live" 2>/dev/null); do sh "$DP" stop --setup "$S" --ask "$a" > /dev/null 2>&1 || true; done
  sh "$FHT" down > /dev/null 2>&1 || true; for f in "$T"/listen-*; do [ -f "$f" ] && kill "$(cat "$f")" 2> /dev/null || true; done; }
trap 'down; rm -rf "$T"' EXIT
C1=$(git -C "$T/dev" rev-parse HEAD); echo two > "$T/dev/two.txt"; ( cd "$T/dev" && git add -A && sp_git commit -qm two && git push -q origin main ); C2=$(git -C "$T/dev" rev-parse HEAD)
cat > "$S" <<X
repo: $T/origin.git
engines: alpha beta
environments: 1
case-limit: 3
ready-seconds: 5
host: fakehost
staging-address: $SA
production-address: $PA
host-login: sh "$FHT" login
deploy: sh "$FHT" deploy
production-logs: the host's log page for production
start: echo "start \$RUN_ID \$TARGET" >> "\$SP_T/starts"; nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & echo \$! > "\$SP_T/listen-\$RUN_ID"
stop: echo "\$RUN_ID" >> "\$SP_T/stops"
run: sh tests/runner.sh
seed: sh "$FHT" seed
production-seed: echo "production-seed \$RUN_ID" >> "\$SP_T/starts"
migrate: sh "$FHT" migrate
backup: sh "$FHT" backup
restore: sh "$FHT" restore
kept: sh "$FHT" kept
signin: admin /_test/signin?role=admin
seam: SEAM-001 real
seam: SEAM-002 stand-in — the payment account is not open yet
duty: log-in — done — the host's tool is logged in
duty: environments — done — staging and production on the host, versions pinned
duty: outside-services — done — each setting set by name
duty: sending-domain — not needed — the product sends no email
duty: deploy-notes — done — DEPLOYMENT.md in the work folder
duty: captures — not needed — no staging run yet
duty: service-switch-on — not needed — no outside service changes
duty: backups — done — daily backups on
duty: point-in-time-recovery — done — seven days
duty: storage-versioning — not needed — no stored files
duty: dns — done — the domain points at production
duty: https — done — the host's certificate
duty: monitoring — not done — the alert address is the owner's to give
X
dp() { RC=0; : > "$FH/calls"; sh "$DP" "$@" > "$T/out" 2>&1 || RC=$?; }
has() { $O rev-parse -q --verify "refs/heads/vid-results/$1" > /dev/null; }
tree() { $O ls-tree -r --name-only "vid-results/$1" | tr '\n' ' '; }
shw() { $O show "vid-results/$1:$1/$2"; }
steps() { shw "$1" deploy.xml | sed -n 's/.*<testcase name="\([^"]*\)".*/\1/p' | tr '\n' ' '; }
calls() { awk '{ print $1 " " $2 }' "$FH/calls" | tr '\n' ','; }
web() { [ "$(curl -s -o /dev/null -m 3 -w '%{http_code}' "$1" 2>/dev/null || true)" != 000 ]; }
slots() { ls "$T/envs" 2>/dev/null | grep '^dp-' | tr '\n' ' ' || true; }
SD="$(printf 'log-in: done — the host'"'"'s tool is logged in\nenvironments: done — staging and production on the host, versions pinned\noutside-services: done — each setting set by name\nsending-domain: not needed — the product sends no email\ndeploy-notes: done — DEPLOYMENT.md in the work folder\ncaptures: not needed — no staging run yet')"
PDU="$(printf 'service-switch-on: not needed — no outside service changes\nbackups: done — daily backups on\npoint-in-time-recovery: done — seven days\nstorage-versioning: not needed — no stored files\ndns: done — the domain points at production\nhttps: done — the host'"'"'s certificate\nmonitoring: not done — the alert address is the owner'"'"'s to give')"
# the log-in first: not logged in, every deploy and recovery refused, exit 1, naming the log-in, nothing else called or pushed
touch "$FH/logged-out"
for a in "deploy --ask deploy-5 --commit $C1" "deploy --target production --ask deploy-20 --commit $C1" "deploy --target rehearsal --ask deploy-30 --commit $C1" "rollback --ask deploy-20" "restore --ask deploy-20 --lose-writes"; do
  # shellcheck disable=SC2086
  dp $a --setup "$S"; [ "$RC" = 1 ] && grep -q 'log-in' "$T/out" && grep -q "owner" "$T/out" && [ "$(calls)" = 'login none,' ] || fail "not logged in, $a: exit $RC, calls $(calls)"; done
! has deploy-5-1 && ! has deploy-20-1 && ! has deploy-30-1 || fail 'a refused log-in pushed'; rm -f "$FH/logged-out"
# a duty: line missing refuses a deploy before anything; a plant needs none
grep -v '^duty: captures' "$S" > "$W/nd.txt"; dp deploy --setup "$W/nd.txt" --ask deploy-5 --commit "$C1"; [ "$RC" = 1 ] && grep -q 'captures' "$T/out" && ! has deploy-5-1 && [ "$(calls)" = '' ] || fail "a staging with no captures duty line: $RC, calls $(calls)"
grep -v '^duty: monitoring' "$S" > "$W/nd.txt"; dp deploy --setup "$W/nd.txt" --target production --ask deploy-20 --commit "$C1"; [ "$RC" = 1 ] && grep -q 'monitoring' "$T/out" || fail "a production with no monitoring duty line: $RC"
grep -v '^duty:' "$S" > "$W/nd.txt"; dp deploy --setup "$W/nd.txt" --ask deploy-4 --commit "$C1" --fail-step migrate --product-change no; [ "$RC" = 0 ] && has deploy-4-1 || fail "a plant with no duty: lines: $RC"
[ "$(tree deploy-4-1)" = 'deploy-4-1/deploy.xml deploy-4-1/report.txt ' ] || fail "a plant's tree: $(tree deploy-4-1)"
# hosted staging: its steps, the host called, nothing local started, no port, no test environment
dp deploy --setup "$S" --ask deploy-5 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-5-1' "$T/out" || fail "a hosted staging exited $RC"
[ "$(tree deploy-5-1)" = 'deploy-5-1/deploy.xml deploy-5-1/duties.txt deploy-5-1/report.txt deploy-5-1/staging.txt ' ] || fail "the staging's tree: $(tree deploy-5-1)"
[ "$(steps deploy-5-1)" = 'checkout migrate deploy seed ready ' ] && ! shw deploy-5-1 deploy.xml | grep -q '<failure' || fail "the staging's steps: $(steps deploy-5-1)"
[ "$(calls)" = 'login none,migrate staging,deploy staging,seed staging,' ] || fail "the staging's calls: $(calls)"
[ "$(grep -c 'port=none data=none base='"$SA"' ' "$FH/calls")" = 3 ] && grep -q "^deploy staging deploy-5-1 $C1 " "$FH/calls" && grep -q '^seed staging .* seed=synthetic$' "$FH/calls" || fail "the host was not given the staging's names: $(cat "$FH/calls")"
[ ! -s "$T/starts" ] && [ -z "$(slots)" ] || fail "a hosted staging ran start: or took a test environment: $(cat "$T/starts" 2>/dev/null) $(slots)"
[ "$(shw deploy-5-1 staging.txt)" = "$(printf 'staging: %s\nsignin: admin %s/_test/signin?role=admin\ndiffers: none\nseam: SEAM-001 real\nseam: SEAM-002 stand-in — the payment account is not open yet\nseed: synthetic\nstays: up' "$SA" "$SA")" ] || fail "the staging.txt: $(shw deploy-5-1 staging.txt)"
[ "$(shw deploy-5-1 duties.txt)" = "$SD" ] || fail "the staging's duties.txt: $(shw deploy-5-1 duties.txt)"
[ "$(shw deploy-5-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: passed' "$C1")" ] || fail "the staging's report: $(shw deploy-5-1 report.txt)"
web "$SA" || fail 'the hosted staging does not answer'
dp live --setup "$S"; grep -qx "live deploy-5-1 $SA" "$T/out" || fail "live does not name the hosted staging: $(cat "$T/out")"
dp stop --setup "$S" --ask deploy-5; [ "$RC" = 0 ] && grep -q 'stays up' "$T/out" && web "$SA" && [ ! -s "$T/stops" ] || fail "stop --ask took a hosted staging down: $RC"
dp live --setup "$S"; grep -qx "live deploy-5-1 $SA" "$T/out" || fail 'the hosted staging is no longer live after stop --ask'
# a staging whose address never answers fails ready
touch "$FH/no-serve"; dp deploy --setup "$S" --ask deploy-6 --commit "$C1" --product-change no; [ "$RC" = 0 ] && shw deploy-6-1 report.txt | grep -qx 'outcome: failed ready' || fail "a staging that never answered: $RC"
[ "$(tree deploy-6-1)" = 'deploy-6-1/deploy.xml deploy-6-1/report.txt ' ] || fail "a failed staging carries more than its report: $(tree deploy-6-1)"; rm -f "$FH/no-serve"
# a failed step: nothing pushed without a judgement, no duties.txt with one
touch "$FH/fail-deploy"; dp deploy --setup "$S" --ask deploy-6 --commit "$C1"; [ "$RC" = 4 ] && grep -q 'failed deploy' "$T/out" && ! has deploy-6-2 || fail "a failed hosted deploy with no judgement: $RC"
dp deploy --setup "$S" --ask deploy-6 --commit "$C1" --product-change yes; [ "$RC" = 0 ] && shw deploy-6-2 report.txt | grep -qx 'outcome: failed deploy' && [ "$(tree deploy-6-2)" = 'deploy-6-2/deploy.xml deploy-6-2/report.txt ' ] || fail "a judged failed hosted deploy: $RC"
rm -f "$FH/fail-deploy"
# a failed first hosted production marks no production down, nothing having run before it: the next attempt runs as the first
touch "$FH/fail-deploy"; dp deploy --setup "$S" --target production --ask deploy-20 --commit "$C1" --product-change no; [ "$RC" = 0 ] && shw deploy-20-1 report.txt | grep -qx 'outcome: failed deploy' || fail "a failed first hosted production: $RC"
rm -f "$FH/fail-deploy"; dp production --setup "$S"; grep -qx 'production none' "$T/out" || fail "after a failed first hosted production: $(cat "$T/out")"
# no production yet: --seed production refused, the rehearsal no backup yet
dp deploy --setup "$S" --ask deploy-7 --commit "$C1" --seed production; [ "$RC" = 1 ] && grep -q 'no production' "$T/out" && ! has deploy-7-1 || fail "--seed production before production: $RC"
dp deploy --setup "$S" --target rehearsal --ask deploy-30 --commit "$C1"; [ "$RC" = 0 ] && shw deploy-30-1 report.txt | grep -qx 'outcome: no backup yet' || fail "a hosted rehearsal before production: $RC"
# the first hosted production: nothing to back up, no production-seed:, production: and logs:
dp deploy --setup "$S" --target production --ask deploy-20 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-20-2' "$T/out" || fail "the first hosted production exited $RC"
[ "$(tree deploy-20-2)" = 'deploy-20-2/deploy.xml deploy-20-2/duties.txt deploy-20-2/report.txt ' ] || fail "the production's tree: $(tree deploy-20-2)"
[ "$(steps deploy-20-2)" = 'backup checkout migrate deploy ready ' ] && shw deploy-20-2 deploy.xml | grep -q '<testcase name="backup"[^>]*><system-out>nothing to back up</system-out>' || fail "the first production's steps: $(steps deploy-20-2)"
[ "$(calls)" = 'login none,migrate production,deploy production,' ] && [ "$(grep -c "port=none data=none base=$PA " "$FH/calls")" = 2 ] || fail "the first production's calls: $(cat "$FH/calls")"
[ ! -s "$T/starts" ] && [ -z "$(slots)" ] || fail "a hosted production ran start: or production-seed:, or took a test environment: $(cat "$T/starts" 2>/dev/null) $(slots)"
[ "$(shw deploy-20-2 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: passed\nproduction: %s\nlogs: the host'"'"'s log page for production' "$C1" "$PA")" ] || fail "the first production's report: $(shw deploy-20-2 report.txt)"
[ "$(shw deploy-20-2 duties.txt)" = "$PDU" ] || fail "the production's duties.txt: $(shw deploy-20-2 duties.txt)"
web "$PA" || fail 'the hosted production does not answer'
dp production --setup "$S"; grep -qx "production $C1 $PA" "$T/out" || fail "production does not name the hosted one: $(cat "$T/out")"
# the next: backed up from the host first, not the first
echo 'record: order 1' >> "$FH/production.data"; H1=$(cat "$FH/production.data")
dp deploy --setup "$S" --target production --ask deploy-21 --commit "$C2"; [ "$RC" = 0 ] && has deploy-21-1 || fail "the second hosted production exited $RC"
[ "$(steps deploy-21-1)" = 'backup checkout migrate deploy ready ' ] && [ "$(calls)" = 'login none,backup production,migrate production,deploy production,' ] || fail "the second production: $(steps deploy-21-1); $(calls)"
B=$W/production/backups/deploy-21-1.dump; [ "$(cat "$B")" = "$H1" ] || fail "the backup is not the host's store: $(cat "$B" 2>&1)"
[ "$(shw deploy-21-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: passed\nproduction: %s' "$C2" "$PA")" ] || fail "the second production's report: $(shw deploy-21-1 report.txt)"
# the rehearsal: a local copy, its dump by backup: against the hosted production, then kept
dp deploy --setup "$S" --target rehearsal --ask deploy-31 --commit "$C2"; [ "$RC" = 0 ] && shw deploy-31-1 report.txt | grep -qx 'outcome: passed' || fail "a hosted rehearsal: $RC"
[ "$(steps deploy-31-1)" = 'checkout restore migrate kept boot ' ] && shw deploy-31-1 report.txt | grep -qx 'kept: records — 1 rows' || fail "the rehearsal's steps or kept: $(steps deploy-31-1); $(shw deploy-31-1 report.txt)"
grep -q '^backup production .* port=none data=none base='"$PA"' ' "$FH/calls" && grep -q "^restore rehearsal .* data=$(cd "$W" && pwd -P)/rehearsal/deploy-31-1/data " "$FH/calls" || fail "the rehearsal's dump was not taken from the hosted production: $(cat "$FH/calls")"
grep -q '^start deploy-31-1 rehearsal$' "$T/starts" && [ "$(slots)" = "$(ls "$T/envs" | grep '^dp-.*\.rehearsal$') " ] || fail "the rehearsal is not a local copy in a test environment: $(cat "$T/starts"); $(slots)"
dp stop --setup "$S" --ask deploy-31; [ "$RC" = 0 ] && grep -q 'destroyed the rehearsal' "$T/out" && grep -qx deploy-31-1 "$T/stops" || fail "the rehearsal would not go: $RC"; : > "$T/stops"
# production data on staging: the dump of production, loaded into staging before the migration, the record's seed: not run
dp deploy --setup "$S" --ask deploy-7 --commit "$C2" --seed production; [ "$RC" = 0 ] && has deploy-7-1 || fail "a staging on production data: $RC"
[ "$(steps deploy-7-1)" = 'checkout seed migrate deploy ready ' ] && [ "$(calls)" = 'login none,backup production,restore staging,migrate staging,deploy staging,' ] || fail "the production-data staging: $(steps deploy-7-1); $(calls)"
[ "$(cat "$FH/staging.data")" = "$(printf '%s\nmigrated deploy-21-1\nmigrated deploy-7-1' "$H1")" ] || fail "staging's store is not production's, then migrated: $(cat "$FH/staging.data")"
shw deploy-7-1 staging.txt | grep -qx 'seed: production' && ! shw deploy-7-1 staging.txt | grep -qx 'seed: synthetic' || fail "staging.txt's seed: $(shw deploy-7-1 staging.txt)"
# a restore always asks: refused, exit 5, the recovery point named; with --lose-writes, the backup and the earlier commit
echo 'record: order 2' >> "$FH/production.data"
dp restore --setup "$S" --ask deploy-21; [ "$RC" = 5 ] && grep -q 'lose-writes' "$T/out" && grep -q 'recovery point' "$T/out" && [ "$(calls)" = 'login none,' ] && grep -qx 'record: order 2' "$FH/production.data" || fail "a restore without --lose-writes: $RC, $(calls)"
dp restore --setup "$S" --ask deploy-21 --lose-writes; [ "$RC" = 0 ] && grep -q "^recovered $C1 — " "$T/out" && [ "$(cat "$FH/production.data")" = "$H1" ] || fail "a restore with the owner's yes: $RC, $(cat "$FH/production.data")"
[ "$(calls)" = 'login none,restore production,deploy production,' ] && grep -q "^deploy production deploy-21-r1 $C1 port=none data=none" "$FH/calls" && [ ! -s "$T/stops" ] && [ -z "$(slots)" ] || fail "the restore's calls: $(cat "$FH/calls"); $(slots)"
dp production --setup "$S"; grep -qx "production $C1 $PA" "$T/out" && web "$PA" || fail "production after the restore: $(cat "$T/out")"
# a rollback deploys the earlier commit; with none before, it is refused and production stays up
dp rollback --setup "$S" --ask deploy-21; [ "$RC" = 0 ] && grep -q "^recovered $C1 — production rolled back" "$T/out" && [ "$(calls)" = 'login none,deploy production,' ] || fail "a hosted rollback: $RC, $(calls)"
dp rollback --setup "$S" --ask deploy-20; [ "$RC" = 1 ] && grep -q 'owner' "$T/out" && [ "$(calls)" = 'login none,' ] && web "$PA" || fail "a hosted rollback with nothing before it: $RC, $(calls)"
dp production --setup "$S"; grep -qx "production $C1 $PA" "$T/out" || fail "production after a refused rollback: $(cat "$T/out")"
dp stop --setup "$S" --target production; [ "$RC" = 1 ] && web "$PA" || fail "stop --target production took a hosted production down: $RC"
echo 'devagent-hosted-deploy: ok'
