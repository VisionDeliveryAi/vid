#!/bin/sh
# Purpose: selftest case — DevAgent's deployer's rehearsal, RH, and the run script's red plant (v0.26.10.27.1 R8), on the fixture project with a local bare
# repository as origin, a product that listens on 127.0.0.1 and a data store that is one file. deploy.sh deploy --target rehearsal: with no production yet,
# outcome: no backup yet, its change.txt, nothing started; once production runs, a dump of its store taken at the rehearsal's start, restored into the copy's own
# store, migrated there, booted by sealed-start: (sealed: yes) or else start: (sealed: no); report.txt with copy: and a signin: line a role; deploy.xml checkout,
# restore, migrate, boot; change.txt from the record's change- lines; production's store untouched. One rehearsal up at a time; stop --ask destroys it, its store
# and dump. The plant and a real failed step as on staging, change.txt with each. Refused: a change-migrates: other than yes or no, a none beside another line.
# run.sh --plant-red <row> on a chunk against the copy: that row's cases read failed in the pushed report, nothing else, results.txt names the plant; refused for a
# row with no case, a malformed id, a red ask. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
command -v nc > /dev/null 2>&1 || { echo 'devagent-prod-rehearsal: no nc, skipped' >&2; exit 0; }
R=$CHECKS/../devagent/test-manager/run.sh; DP=$CHECKS/../devagent/deployer/deploy.sh
T=$(mktemp -d)
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-prod-rehearsal: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T"; W=$T/work; S=$W/dev-setup.txt; O="git -C $T/origin.git"
down() { for a in $(sed 's/-[0-9]*$//' "$W/rehearsal/live" 2>/dev/null); do sh "$DP" stop --setup "$S" --ask "$a" > /dev/null 2>&1 || true; done
  [ ! -f "$W/production/live" ] || sh "$DP" stop --setup "$S" --target production > /dev/null 2>&1 || true
  for f in "$T"/listen-*; do [ -f "$f" ] && kill "$(cat "$f")" 2> /dev/null || true; done; }
trap 'down; rm -rf "$T"' EXIT
C=$(git -C "$T/dev" rev-parse HEAD)
cat > "$S" <<X
repo: $T/origin.git
engines: alpha beta
environments: 1
case-limit: 3
ready-seconds: 5
start: echo "\$RUN_ID \$TARGET start" >> "\$SP_T/starts"; nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & echo \$! > "\$SP_T/listen-\$RUN_ID"
sealed-start: echo "\$RUN_ID \$TARGET sealed" >> "\$SP_T/starts"; nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & echo \$! > "\$SP_T/listen-\$RUN_ID"
stop: echo "\$RUN_ID" >> "\$SP_T/stops"
run: sh tests/runner.sh
backup: cp "\$DATA_DIR/data.txt" "\$DUMP"; echo "\$RUN_ID \$DUMP" >> "\$SP_T/dumps"
restore: cp "\$DUMP" "\$DATA_DIR/data.txt"
migrate: echo "migrated by \$RUN_ID" >> "\$DATA_DIR/data.txt"
production-seed: echo "sample: customer-1, colour blue" >> "\$DATA_DIR/data.txt"
signin: admin /_test/signin?role=admin
signin: member /_test/signin?role=member
change-migrates: yes
change-drops: customer.colour
change-rewrites: customer.name, to first and last
change-services: the mail sender, a new sender address
X
dp() { RC=0; sh "$DP" "$@" > "$T/out" 2>&1 || RC=$?; }
has() { $O rev-parse -q --verify "refs/heads/vid-results/$1" > /dev/null; }
tree() { $O ls-tree -r --name-only "vid-results/$1" | tr '\n' ' '; }
shw() { $O show "vid-results/$1:$1/$2"; }
steps() { shw "$1" deploy.xml | sed -n 's/.*<testcase name="\([^"]*\)".*/\1/p' | tr '\n' ' '; }
up() { nc -z -w 1 127.0.0.1 "$1" > /dev/null 2>&1; }
CH="$(printf 'migrates: yes\ndrops: customer.colour\nrewrites: customer.name, to first and last\nservices: the mail sender, a new sender address')"
# no production yet: no backup yet, nothing started
dp deploy --setup "$S" --target rehearsal --ask deploy-30 --commit "$C"; [ "$RC" = 0 ] && has deploy-30-1 || fail "a first rehearsal exited $RC"
[ "$(tree deploy-30-1)" = 'deploy-30-1/change.txt deploy-30-1/deploy.xml deploy-30-1/report.txt ' ] || fail "the first rehearsal's tree: $(tree deploy-30-1)"
[ "$(shw deploy-30-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\noutcome: no backup yet' "$C")" ] && [ "$(shw deploy-30-1 change.txt)" = "$CH" ] || fail "the first rehearsal's report: $(shw deploy-30-1 report.txt)"
shw deploy-30-1 deploy.xml | grep -q '<testcase name="restore"[^>]*><skipped message="no backup yet' && [ ! -s "$T/starts" ] || fail 'no backup yet deployed something'
# production, then a rehearsal of it: a dump at its start, restored, migrated, sealed
dp deploy --setup "$S" --target production --ask deploy-31 --commit "$C"; [ "$RC" = 0 ] || fail "the production deploy: $RC"
PD=$W/production/data/data.txt; BEFORE=$(cat "$PD")
dp deploy --setup "$S" --target rehearsal --ask deploy-32 --commit "$C"; [ "$RC" = 0 ] && has deploy-32-1 || fail "a rehearsal exited $RC"
[ "$(tree deploy-32-1)" = 'deploy-32-1/change.txt deploy-32-1/deploy.xml deploy-32-1/report.txt ' ] || fail "the rehearsal's tree: $(tree deploy-32-1)"
A=$(shw deploy-32-1 report.txt | sed -n 's|^copy: \(http://127.0.0.1:[0-9][0-9]*\)$|\1|p'); [ -n "$A" ] || fail "no copy: line: $(shw deploy-32-1 report.txt)"
[ "$(shw deploy-32-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\noutcome: passed\nsealed: yes\ncopy: %s\nsignin: admin %s/_test/signin?role=admin\nsignin: member %s/_test/signin?role=member' "$C" "$A" "$A" "$A")" ] || fail "the rehearsal's report: $(shw deploy-32-1 report.txt)"
[ "$(steps deploy-32-1)" = 'checkout restore migrate boot ' ] && ! shw deploy-32-1 deploy.xml | grep -q '<failure' && [ "$(shw deploy-32-1 change.txt)" = "$CH" ] || fail "the rehearsal's steps: $(steps deploy-32-1)"
HD=$W/rehearsal/deploy-32-1; [ "$(cat "$HD/data/data.txt")" = "$(printf '%s\nmigrated by deploy-32-1' "$BEFORE")" ] && [ "$(cat "$PD")" = "$BEFORE" ] || fail "the copy's store, or production's: $(cat "$HD/data/data.txt")"
grep -qx "deploy-31-1 $(cd "$W" && pwd -P)/rehearsal/deploy-32-1/dump" "$T/dumps" || fail "the dump was not taken of production for the rehearsal: $(cat "$T/dumps")"
grep -qx 'deploy-32-1 rehearsal sealed' "$T/starts" && up "${A##*:}" || fail 'the copy was not started sealed, or is not up'
dp live --setup "$S"; grep -qx "rehearsal deploy-32-1 $A" "$T/out" || fail "live does not name the rehearsal: $(cat "$T/out")"
L2=$(cat "$T/listen-deploy-32-1")
# with no sealed-start:, sealed: no; and a new rehearsal destroys the one up
grep -v '^sealed-start:' "$S" > "$S.u"; dp deploy --setup "$S.u" --target rehearsal --ask deploy-33 --commit "$C"; [ "$RC" = 0 ] && shw deploy-33-1 report.txt | grep -qx 'sealed: no' || fail "an unsealed copy: $RC"
! kill -0 "$L2" 2> /dev/null && [ ! -d "$HD/data" ] && [ ! -e "$HD/dump" ] && grep -qx deploy-32-1 "$T/stops" || fail 'the earlier rehearsal was not destroyed'
A3=$(shw deploy-33-1 report.txt | sed -n 's|^copy: ||p'); L3=$(cat "$T/listen-deploy-33-1")
dp stop --setup "$S" --ask deploy-32; [ "$RC" = 1 ] && grep -q 'no live staging of deploy-32, nor rehearsal' "$T/out" && kill -0 "$L3" || fail 'stop took another okay'"'"'s rehearsal'
dp stop --setup "$S" --ask deploy-33; [ "$RC" = 0 ] && grep -qx 'destroyed the rehearsal deploy-33-1' "$T/out" && ! kill -0 "$L3" 2> /dev/null && ! up "${A3##*:}" && [ ! -d "$W/rehearsal/deploy-33-1/data" ] || fail "stop did not destroy the rehearsal: $RC"
dp production --setup "$S"; grep -q "^production $C " "$T/out" || fail 'the rehearsal touched production'
# the plant: a failed step reported with its change.txt, nothing restored or deployed
n=$(wc -l < "$T/starts")
dp deploy --setup "$S" --target rehearsal --ask deploy-34 --commit "$C" --fail-step migrate --product-change yes; [ "$RC" = 0 ] && has deploy-34-1 || fail "the plant exited $RC"
[ "$(shw deploy-34-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate\nproduct change: yes' "$C")" ] && [ "$(shw deploy-34-1 change.txt)" = "$CH" ] || fail "the plant's report: $(shw deploy-34-1 report.txt)"
[ "$(wc -l < "$T/starts")" -eq "$n" ] && [ ! -f "$W/rehearsal/live" ] || fail 'the plant deployed'
# a real failed step: nothing pushed without a judgement, the copy destroyed; with one, reported
sed 's|^restore: .*|restore: exit 3|' "$S" > "$S.f"; dp deploy --setup "$S.f" --target rehearsal --ask deploy-35 --commit "$C"; [ "$RC" = 4 ] && grep -q 'failed restore' "$T/out" && ! has deploy-35-1 || fail "a failed restore with no judgement: $RC"
[ ! -d "$W/rehearsal/deploy-35-1/data" ] || fail 'a failed rehearsal left its store'
dp deploy --setup "$S.f" --target rehearsal --ask deploy-35 --commit "$C" --product-change no; [ "$RC" = 0 ] && shw deploy-35-1 report.txt | grep -qx 'outcome: failed restore' && [ "$(shw deploy-35-1 change.txt)" = "$CH" ] || fail "a judged failed restore: $RC"
# change.txt from a record with none, and the refusals
grep -v '^change-' "$S" > "$S.n"; dp deploy --setup "$S.n" --target rehearsal --ask deploy-36 --commit "$C" --fail-step boot --product-change no
[ "$(shw deploy-36-1 change.txt)" = "$(printf 'migrates: no\ndrops: none\nservices: none')" ] || fail "change.txt with no change- lines: $(shw deploy-36-1 change.txt)"
no() { dp deploy --setup "$S.b" --target rehearsal --ask deploy-37 --commit "$C"; [ "$RC" = 1 ] && grep -q "$1" "$T/out" && ! has deploy-37-1 || fail "a rehearsal ran with: $1"; }
sed 's/^change-migrates: .*/change-migrates: maybe/' "$S" > "$S.b"; no 'yes or no'
printf 'change-drops: none\n' >> "$S"; cp "$S" "$S.b"; no 'change-drops: none stands alone'
grep -v '^restore:' "$S.n" > "$S.b"; no 'backup: or restore:'
# run.sh --plant-red: that row's cases read failed, nothing else changed, the plant named
run() { RC=0; sh "$R" run --setup "$S.n" --commit "$C" "$@" > "$T/out" 2>&1 || RC=$?; }
run --ask req-40-p1c1 --select 'ROW-00[14]' --engines alpha --against "$A" --plant-red ROW-001; [ "$RC" = 0 ] && has req-40-p1c1-1 || fail "a planted run exited $RC"
X=$($O show vid-results/req-40-p1c1-1:req-40-p1c1-1/cases-alpha.xml)
printf '%s\n' "$X" | grep -q '<testcase name="ROW-001-home" time="[0-9]*"><failure message="a labelled plant (--plant-red ROW-001): made to read failed">' || fail "the planted case: $X"
printf '%s\n' "$X" | grep -q '<testcase name="ROW-004-after" time="[0-9]*"/>' && [ "$(printf '%s\n' "$X" | grep -c '<failure')" = 1 ] || fail "the plant changed another case: $X"
$O show vid-results/req-40-p1c1-1:req-40-p1c1-1/results.txt | grep -qx 'plant: ROW-001 — a labelled plant, for the test alone: its cases made to read failed, nothing else changed' || fail 'results.txt does not name the plant'
grep -q '^cases: 1 passed, 1 failed' "$T/out" || fail "the run's own count: $(head -n 3 "$T/out")"
run --ask req-40-p1c2 --select 'ROW-004' --engines alpha --against "$A" --plant-red ROW-001; [ "$RC" = 1 ] && grep -q "the plant's row ROW-001 has no case" "$T/out" && ! has req-40-p1c2-1 || fail "a plant on a row with no case: $RC"
bad() { w=$1; shift; run "$@"; [ "$RC" = 1 ] && grep -qF -- "$w" "$T/out" || fail "a plant ran with: $*"; }
bad 'holds a row id' --ask req-40-p1c3 --against "$A" --plant-red row-1
bad "close chunk's alone" --ask red-40 --line 'rows: ROW-001' --plant-red ROW-001
bad "close chunk's alone" --ask req-40-p1cx --leave-out none --plant-red ROW-001
exit 0
