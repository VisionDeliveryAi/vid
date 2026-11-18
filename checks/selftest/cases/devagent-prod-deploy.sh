#!/bin/sh
# Purpose: selftest case — DevAgent's deployer's production, D2, and its recovery (v0.26.10.27.1 R8), on the fixture project with a local bare repository as
# origin, a product that listens on 127.0.0.1 and a data store that is one file. deploy.sh deploy --target production: the first deploy's backup step passes with
# nothing to back up, then checkout, migrate, start, seed (production-seed:, SEED=sample, once), ready; report.txt with production: and, the first time alone,
# logs:; it stays up. A later deploy backs up first (the record's backup:, a dump of the live store), then replaces the running instance on the same port, never
# seeds again. A failed step with no --product-change: nothing pushed, the report kept, production down, every other deploy refused; the same command with it
# pushes that report. The plant, --fail-step: the backup taken, nothing deployed, production untouched. rollback: production at the commit it ran before, its
# store as it stood; with none before, recovered none and the store gone. restore: refused, exit 5, while production was written since its start, until
# --lose-writes; then the backup's store at the earlier commit. production names what runs. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
# 0.26.11.1.1 (R1, R3): every restore is refused, exit 5, without --lose-writes, nothing written since included, the recovery point named; with no
# host: in the record, a passed production's duties.txt says each production duty `not needed — a local copy, for a test`, and a failed one has none.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
command -v nc > /dev/null 2>&1 || { echo 'devagent-prod-deploy: no nc, skipped' >&2; exit 0; }
DP=$CHECKS/../devagent/deployer/deploy.sh
T=$(mktemp -d)
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-prod-deploy: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T"; W=$T/work; S=$W/dev-setup.txt; O="git -C $T/origin.git"; W2=$T/work2; mkdir -p "$W2"
down() { for w in "$W" "$W2"; do [ ! -f "$w/production/live" ] || sh "$DP" stop --setup "$w/dev-setup.txt" --target production > /dev/null 2>&1 || true; done
  for f in "$T"/listen-*; do [ -f "$f" ] && kill "$(cat "$f")" 2> /dev/null || true; done; }
trap 'down; rm -rf "$T"' EXIT
C1=$(git -C "$T/dev" rev-parse HEAD); echo two > "$T/dev/two.txt"; ( cd "$T/dev" && git add -A && sp_git commit -qm two && git push -q origin main ); C2=$(git -C "$T/dev" rev-parse HEAD)
cat > "$S" <<X
repo: $T/origin.git
engines: alpha beta
environments: 1
case-limit: 3
ready-seconds: 5
start: echo "\$RUN_ID \$TARGET \$SEED \$DATA_DIR" >> "\$SP_T/starts"; nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & echo \$! > "\$SP_T/listen-\$RUN_ID"
stop: echo "\$RUN_ID" >> "\$SP_T/stops"
run: sh tests/runner.sh
backup: cp "\$DATA_DIR/data.txt" "\$DUMP"
restore: cp "\$DUMP" "\$DATA_DIR/data.txt"
migrate: echo "migrated by \$RUN_ID" >> "\$DATA_DIR/data.txt"
production-seed: echo "sample: customer-1, labelled sample data, \$SEED" >> "\$DATA_DIR/data.txt"
signin: admin /_test/signin?role=admin
X
dp() { RC=0; sh "$DP" "$@" > "$T/out" 2>&1 || RC=$?; }
has() { $O rev-parse -q --verify "refs/heads/vid-results/$1" > /dev/null; }
tree() { $O ls-tree -r --name-only "vid-results/$1" | tr '\n' ' '; }
shw() { $O show "vid-results/$1:$1/$2"; }
steps() { shw "$1" deploy.xml | sed -n 's/.*<testcase name="\([^"]*\)".*/\1/p' | tr '\n' ' '; }
up() { nc -z -w 1 127.0.0.1 "$1" > /dev/null 2>&1; }
DATA=$W/production/data/data.txt
# at <commit>: production runs that commit where `deploy.sh production` says, and that port answers; P is then that port. A replacement or a
# recovery keeps production's port while it is free, and may take the next one when another holds it
at() { dp production --setup "$S"; P=$(sed -n "s|^production $1 http://127.0.0.1:\([0-9][0-9]*\)\$|\1|p" "$T/out"); [ -n "$P" ] && up "$P"; }
# refused before anything: no production-seed: on a first deploy, no backup: or restore:, a bad target, --lose-writes on a deploy
sed '/^production-seed:/d' "$S" > "$W2/dev-setup.txt"; dp deploy --setup "$W2/dev-setup.txt" --target production --ask deploy-20 --commit "$C1"
[ "$RC" = 1 ] && grep -q 'production-seed:' "$T/out" && ! has deploy-20-1 || fail "a first production deploy with no production-seed: $RC"
sed '/^restore:/d' "$S" > "$W2/dev-setup.txt"; dp deploy --setup "$W2/dev-setup.txt" --target production --ask deploy-20 --commit "$C1"; [ "$RC" = 1 ] && grep -q 'backup: or restore:' "$T/out" || fail 'a production with no restore:'
dp deploy --setup "$S" --target cloud --ask deploy-20 --commit "$C1"; [ "$RC" = 1 ] && grep -q 'staging, rehearsal or production' "$T/out" || fail 'a target other than the three'
dp deploy --setup "$S" --target production --ask deploy-20 --commit "$C1" --lose-writes; [ "$RC" = 1 ] && grep -q "restore's alone" "$T/out" || fail '--lose-writes on a deploy'
dp production --setup "$S"; grep -qx 'production none' "$T/out" || fail "production before any: $(cat "$T/out")"
# the first deploy: nothing to back up, seeded once, logs:
dp deploy --setup "$S" --target production --ask deploy-20 --commit "$C1"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-20-1' "$T/out" || fail "the first production deploy exited $RC"
[ "$(tree deploy-20-1)" = 'deploy-20-1/deploy.xml deploy-20-1/duties.txt deploy-20-1/report.txt ' ] || fail "the first deploy's tree: $(tree deploy-20-1)"
[ "$(shw deploy-20-1 duties.txt)" = "$(for d in service-switch-on backups point-in-time-recovery storage-versioning dns https monitoring; do echo "$d: not needed — a local copy, for a test"; done)" ] || fail "a local production's duties.txt: $(shw deploy-20-1 duties.txt)"
[ "$($O rev-list --count vid-results/deploy-20-1)" = 1 ] && $O log -1 --format=%B vid-results/deploy-20-1 | grep -qx 'Role: DP' || fail 'the deploy is not one commit by DP'
P=$(shw deploy-20-1 report.txt | sed -n 's|^production: http://127.0.0.1:\([0-9][0-9]*\)$|\1|p'); [ -n "$P" ] || fail "no production: line: $(shw deploy-20-1 report.txt)"
[ "$(shw deploy-20-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: passed\nproduction: http://127.0.0.1:%s\nlogs: %s' "$C1" "$P" "$(cd "$W" && pwd -P)/production/production.log")" ] || fail "the first report: $(shw deploy-20-1 report.txt)"
[ "$(steps deploy-20-1)" = 'backup checkout migrate start seed ready ' ] && ! shw deploy-20-1 deploy.xml | grep -q '<failure' || fail "the first deploy's steps: $(steps deploy-20-1)"
shw deploy-20-1 deploy.xml | grep -q '<testcase name="backup"[^>]*><system-out>nothing to back up</system-out>' || fail "the first backup step: $(shw deploy-20-1 deploy.xml)"
up "$P" && grep -qx "deploy-20-1 production sample $(cd "$W" && pwd -P)/production/data" "$T/starts" || fail "the production is not up, or start: saw the wrong names: $(cat "$T/starts")"
[ "$(cat "$DATA")" = "$(printf 'migrated by deploy-20-1\nsample: customer-1, labelled sample data, sample')" ] || fail "the store after the first deploy: $(cat "$DATA")"
dp production --setup "$S"; grep -qx "production $C1 http://127.0.0.1:$P" "$T/out" || fail "production does not name it: $(cat "$T/out")"
dp live --setup "$S"; grep -qx 'live none' "$T/out" || fail 'live names production as a staging'
dp restore --setup "$S" --ask deploy-20; [ "$RC" = 1 ] && grep -q 'nothing to restore' "$T/out" || fail 'a restore of a first deploy, which took no backup'
L1=$(cat "$T/listen-deploy-20-1")
# a second deploy: backed up first, the running one replaced on the same port while it is free, no second seed, no logs:
dp deploy --setup "$S" --target production --ask deploy-21 --commit "$C2"; [ "$RC" = 0 ] && has deploy-21-1 || fail "the second deploy exited $RC"
[ "$(steps deploy-21-1)" = 'backup checkout migrate start ready ' ] || fail "the second deploy's steps: $(steps deploy-21-1)"
B=$W/production/backups/deploy-21-1.dump; [ "$(cat "$B")" = "$(printf 'migrated by deploy-20-1\nsample: customer-1, labelled sample data, sample')" ] || fail "the backup is not the store before it: $(cat "$B" 2>&1)"
! kill -0 "$L1" 2> /dev/null && grep -qx deploy-20-1 "$T/stops" && at "$C2" || fail "the earlier production was not replaced, or the new one is not up: $(cat "$T/out")"
[ "$(shw deploy-21-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: passed\nproduction: http://127.0.0.1:%s' "$C2" "$P")" ] || fail "the second report: $(shw deploy-21-1 report.txt)"
[ "$(grep -c '^sample:' "$DATA")" = 1 ] && grep -qx 'migrated by deploy-21-1' "$DATA" || fail "the second deploy seeded again, or did not migrate: $(cat "$DATA")"
# a write since its start: a restore is refused, exit 5, the recovery point and the writes at risk named; a rollback keeps the store
echo 'written: order 7' >> "$DATA"
dp restore --setup "$S" --ask deploy-21; [ "$RC" = 5 ] && grep -q 'would lose the writes' "$T/out" && grep -q 'recovery point' "$T/out" && grep -q 'writes at risk' "$T/out" && grep -qx 'written: order 7' "$DATA" || fail "a restore that loses writes went ahead: $RC"
dp rollback --setup "$S" --ask deploy-21; [ "$RC" = 0 ] && grep -q "^recovered $C1 — production rolled back" "$T/out" || fail "a rollback: $RC"
at "$C1" && grep -qx 'written: order 7' "$DATA" && grep -qx 'migrated by deploy-21-1' "$DATA" || fail "after the rollback: $(cat "$T/out"); $(cat "$DATA")"
# nothing written since the rollback's start: a restore still asks first, a rollback in between hiding no write; then --lose-writes
dp restore --setup "$S" --ask deploy-21; [ "$RC" = 5 ] && grep -q 'lose-writes' "$T/out" && grep -qx 'written: order 7' "$DATA" || fail "a restore after a rollback went ahead with no word: $RC"
dp restore --setup "$S" --ask deploy-21 --lose-writes; [ "$RC" = 0 ] && grep -q "^recovered $C1 — production's store restored from" "$T/out" || fail "a restore with the owner's yes: $RC"
[ "$(cat "$DATA")" = "$(cat "$B")" ] && at "$C1" || fail "the restored store, or production after the restore: $(cat "$DATA"); $(cat "$T/out")"
echo 'written: order 8' >> "$DATA"; dp restore --setup "$S" --ask deploy-21; [ "$RC" = 5 ] || fail "a second write: $RC"
dp restore --setup "$S" --ask deploy-21 --lose-writes; [ "$RC" = 0 ] && [ "$(cat "$DATA")" = "$(cat "$B")" ] || fail "a second restore with the owner's yes: $RC"
# the plant: the backup taken, nothing deployed, production untouched
LP=$(cat "$W/production/live"); LL=$(cat "$T/listen-$LP"); n=$(wc -l < "$T/starts")
dp deploy --setup "$S" --target production --ask deploy-22 --commit "$C2" --fail-step start --product-change no; [ "$RC" = 0 ] && has deploy-22-1 || fail "the plant exited $RC"
[ "$(shw deploy-22-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: failed start\nproduct change: no' "$C2")" ] || fail "the plant's report: $(shw deploy-22-1 report.txt)"
[ "$(steps deploy-22-1)" = 'backup start ' ] && shw deploy-22-1 deploy.xml | grep -q '<testcase name="start"[^>]*><failure message="a labelled plant' && [ -f "$W/production/backups/deploy-22-1.dump" ] || fail "the plant's steps: $(shw deploy-22-1 deploy.xml)"
[ "$(wc -l < "$T/starts")" -eq "$n" ] && kill -0 "$LL" && [ "$(cat "$W/production/live")" = "$LP" ] || fail 'the plant deployed, or touched production'
dp deploy --setup "$S" --target production --ask deploy-22 --commit "$C2" --fail-step backup --product-change yes; [ "$(steps deploy-22-2)" = 'backup ' ] && [ ! -f "$W/production/backups/deploy-22-2.dump" ] || fail 'a plant at the backup'
# a real failed step: nothing pushed without a judgement, production down, every other deploy refused; then its report pushed, and a rollback
sed 's|^migrate: .*|migrate: echo "half a migration" >> "$DATA_DIR/data.txt"; exit 3|' "$S" > "$S.f" && mv "$S.f" "$S"
dp deploy --setup "$S" --target production --ask deploy-23 --commit "$C2"; [ "$RC" = 4 ] && grep -q 'failed migrate, nothing pushed: production is down' "$T/out" && ! has deploy-23-1 || fail "a failed migrate with no judgement: $RC"
dp production --setup "$S"; grep -q '^production down — deploy-23-1 failed' "$T/out" && ! kill -0 "$LL" 2> /dev/null || fail "production after the failed migrate: $(cat "$T/out")"
dp deploy --setup "$S" --target production --ask deploy-24 --commit "$C2" --product-change no; [ "$RC" = 1 ] && grep -q 'deploy-23-1 waits for its judgement' "$T/out" && ! has deploy-24-1 || fail 'another deploy went while one waits for its judgement'
dp rollback --setup "$S" --ask deploy-23; [ "$RC" = 1 ] && grep -q 'not pushed yet' "$T/out" || fail 'a recovery before the failed report is pushed'
dp deploy --setup "$S" --target production --ask deploy-23 --commit "$C2" --product-change yes; [ "$RC" = 0 ] && has deploy-23-1 || fail "the judged failed migrate: $RC"
[ "$(shw deploy-23-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\ndecisions: none\noutcome: failed migrate\nproduct change: yes' "$C2")" ] && [ "$(steps deploy-23-1)" = 'backup checkout migrate ' ] || fail "the failed migrate's report: $(shw deploy-23-1 report.txt); $(steps deploy-23-1)"
[ "$(tree deploy-23-1)" = 'deploy-23-1/deploy.xml deploy-23-1/report.txt ' ] || fail "a failed production carries more than its report: $(tree deploy-23-1)"
dp deploy --setup "$S" --target production --ask deploy-24 --commit "$C2"; [ "$RC" = 1 ] && grep -q 'production is down since deploy-23-1' "$T/out" || fail 'a deploy while production is down'
# production's port taken by another while production is down (as by a case running beside this one): the rollback comes up on the next free one
nc -lk 127.0.0.1 "$P" > /dev/null 2>&1 & OC=$!; echo "$OC" > "$T/listen-occupier"; sleep 1
dp rollback --setup "$S" --ask deploy-23; [ "$RC" = 0 ] && grep -q "^recovered $C1 — " "$T/out" || fail "the rollback after a failed migrate: $RC"
at "$C1" || fail "production after the rollback: $(cat "$T/out")"; kill "$OC" 2> /dev/null || true; wait "$OC" 2> /dev/null || true
LR=$(cat "$W/production/live"); dp stop --setup "$S" --target production; [ "$RC" = 0 ] && ! kill -0 "$(cat "$T/listen-$LR")" 2> /dev/null && [ -f "$DATA" ] || fail "stop --target production: $RC"
dp production --setup "$S"; grep -q '^production stopped' "$T/out" || fail "production once stopped: $(cat "$T/out")"
dp deploy --setup "$S" --target production --ask deploy-24 --commit "$C2"; [ "$RC" = 1 ] && grep -q 'stopped' "$T/out" || fail 'a deploy onto a stopped production'
# a first deploy failed and rolled back: recovered none, the store gone
sed -e '/^migrate:/d' -e 's|^start: .*|start: nc -lk 127.0.0.1 "$PORT" > /dev/null 2>\&1 \& echo $! > "$SP_T/listen-w2"; exit 3|' "$S" > "$W2/dev-setup.txt"
dp deploy --setup "$W2/dev-setup.txt" --target production --ask deploy-25 --commit "$C1" --product-change no; [ "$RC" = 0 ] && shw deploy-25-1 report.txt | grep -qx 'outcome: failed start' || fail "a failed first start: $RC"
! kill -0 "$(cat "$T/listen-w2")" 2> /dev/null || fail 'a failed start left its process up'
dp rollback --setup "$W2/dev-setup.txt" --ask deploy-25; [ "$RC" = 0 ] && grep -q '^recovered none — ' "$T/out" && [ ! -d "$W2/production/data" ] || fail "a first deploy rolled back: $RC"
dp production --setup "$W2/dev-setup.txt"; grep -qx 'production none' "$T/out" || fail "production after recovered none: $(cat "$T/out")"
dp rollback --setup "$S" --ask deploy-99; [ "$RC" = 1 ] && grep -q 'no production deploy of deploy-99' "$T/out" || fail 'a rollback of no deploy'
exit 0
