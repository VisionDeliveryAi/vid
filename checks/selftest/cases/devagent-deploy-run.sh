#!/bin/sh
# Purpose: selftest case — DevAgent's deployer and the staging run (v0.26.10.26.2 R8), on the fixture project with a local bare repository as origin and a
# product that listens on 127.0.0.1. deploy.sh deploy: a clean checkout at the okay's commit, the record's start: on a free local port (PORT, BASE_URL, STAGING,
# SEED=synthetic), its seed:, the port answering; pushed alone as deploy-<issue>-<k>/ with report.txt, deploy.xml (a case a step) and staging.txt (the address,
# a signin: line a role of the record, its differs: lines or differs: none), Role: DP, the next free k; the staging kept up after it ends, `live` naming it.
# The labelled plant, --fail-step --product-change: a failed step reported, nothing deployed, the live staging untouched. A real failed step: nothing pushed without
# --product-change, with it outcome: failed <step> and product change:, nothing left up. A new deploy replaces the live staging; stop --ask stops it by its
# recorded groups, refused for another ask. Refused, nothing pushed: a short commit, one not on origin, a malformed ask, a plant with no --product-change or a
# word other than yes or no, another seed. run.sh run --against: the asked rows against that address, the runner given BASE_URL and the signin: lines, nothing
# started, no services read; refused with no product, a line, a rest chunk, a red or head ask, the builder's own run, a non-address, a signin: with no --against.
# Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
command -v nc > /dev/null 2>&1 || { echo 'devagent-deploy-run: no nc, skipped' >&2; exit 0; }
R=$CHECKS/../devagent/test-manager/run.sh; DP=$CHECKS/../devagent/deployer/deploy.sh
T=$(mktemp -d)
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-deploy-run: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T"; W=$T/work; S=$W/dev-setup.txt; O="git -C $T/origin.git"
down() { for w in "$W" "$T/work2"; do a=$(sed 's/-[0-9]*$//' "$w/staging/live" 2>/dev/null) || continue; sh "$DP" stop --setup "$w/dev-setup.txt" --ask "$a" > /dev/null 2>&1 || true; done; }
trap 'down; rm -rf "$T"' EXIT
# the product: a listener on PORT, its pid by RUN_ID; a case that writes what it was given
mkdir -p "$T/dev/tests/cases"; printf '%s\n' 'echo "$BASE_URL|$SIGNIN" > "$SP_T/seen"' 'exit 0' > "$T/dev/tests/cases/ROW-007-staging.sh"
( cd "$T/dev" && git add -A && sp_git commit -qm 'the staging case' && git push -q origin main ); C=$(git -C "$T/dev" rev-parse HEAD)
cat > "$S" <<X
repo: $T/origin.git
engines: alpha beta
environments: 1
case-limit: 3
service-seconds: 1
ready-seconds: 5
start: echo "\$RUN_ID \$STAGING \$SEED" >> "\$SP_T/starts"; [ -z "\${PORT:-}" ] || { nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & echo \$! > "\$SP_T/listen-\$RUN_ID"; }
stop: echo "\$RUN_ID" >> "\$SP_T/stops"
run: sh tests/runner.sh
services: echo "\$RUN_ID" >> "\$SP_T/services"
seed: echo "\$SEED \$BASE_URL" > "\$SP_T/seeded-\$RUN_ID"
signin: admin /_test/signin?role=admin
signin: member /_test/signin?role=member
differs: the /_ops/ door — open — absent
differs: VID_TEST — 1 — unset
X
dp() { RC=0; sh "$DP" "$@" > "$T/out" 2>&1 || RC=$?; }
has() { $O rev-parse -q --verify "refs/heads/vid-results/$1" > /dev/null; }
tree() { $O ls-tree -r --name-only "vid-results/$1" | tr '\n' ' '; }
shw() { $O show "vid-results/$1:$1/$2"; }
up() { nc -z -w 1 127.0.0.1 "$1" > /dev/null 2>&1; }
port() { shw "$1" staging.txt | sed -n 's|^staging: http://127.0.0.1:\([0-9][0-9]*\)$|\1|p'; }
# a deploy: pushed, its three files, the staging up and kept
dp deploy --setup "$S" --ask deploy-5 --commit "$C"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-5-1' "$T/out" || fail "a deploy exited $RC"
[ "$(tree deploy-5-1)" = 'deploy-5-1/deploy.xml deploy-5-1/report.txt deploy-5-1/staging.txt ' ] || fail "the deploy's tree: $(tree deploy-5-1)"
[ "$($O rev-list --count vid-results/deploy-5-1)" = 1 ] && $O log -1 --format=%B vid-results/deploy-5-1 | grep -qx 'Role: DP' || fail 'the deploy is not one commit by DP'
[ "$(shw deploy-5-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$C")" ] || fail "the passed report: $(shw deploy-5-1 report.txt)"
P1=$(port deploy-5-1); [ -n "$P1" ] || fail "no staging: line: $(shw deploy-5-1 staging.txt)"
[ "$(shw deploy-5-1 staging.txt)" = "$(printf 'staging: http://127.0.0.1:%s\nsignin: admin http://127.0.0.1:%s/_test/signin?role=admin\nsignin: member http://127.0.0.1:%s/_test/signin?role=member\ndiffers: the /_ops/ door — open — absent\ndiffers: VID_TEST — 1 — unset' "$P1" "$P1" "$P1")" ] || fail "the staging.txt: $(shw deploy-5-1 staging.txt)"
[ "$(shw deploy-5-1 deploy.xml | sed -n 's/.*<testcase name="\([^"]*\)".*/\1/p' | tr '\n' ' ')" = 'checkout start seed ready ' ] && ! shw deploy-5-1 deploy.xml | grep -q '<failure' || fail "the deploy's steps: $(shw deploy-5-1 deploy.xml)"
up "$P1" || fail 'the staging is not up after the deploy ended'
grep -qx 'deploy-5-1 1 synthetic' "$T/starts" && [ "$(cat "$T/seeded-deploy-5-1")" = "synthetic http://127.0.0.1:$P1" ] || fail "start: or seed: not given the staging's names: $(cat "$T/starts")"
dp live --setup "$S"; grep -qx "live deploy-5-1 http://127.0.0.1:$P1" "$T/out" || fail 'live does not name the staging'
L1=$(cat "$T/listen-deploy-5-1")
# the labelled plant: a failed step reported, nothing deployed, the live staging untouched
dp deploy --setup "$S" --ask deploy-5 --commit "$C" --fail-step migrate --product-change no; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-5-2' "$T/out" || fail "the plant exited $RC"
[ "$(tree deploy-5-2)" = 'deploy-5-2/deploy.xml deploy-5-2/report.txt ' ] || fail "the plant's tree: $(tree deploy-5-2)"
[ "$(shw deploy-5-2 report.txt)" = "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate\nproduct change: no' "$C")" ] || fail "the plant's report: $(shw deploy-5-2 report.txt)"
shw deploy-5-2 deploy.xml | grep -q '<testcase name="migrate"[^>]*><failure message="a labelled plant' || fail "the plant's step: $(shw deploy-5-2 deploy.xml)"
[ "$(wc -l < "$T/starts")" -eq 1 ] && up "$P1" || fail 'the plant deployed, or took the staging down'
dp deploy --setup "$S" --ask deploy-5 --commit "$C" --fail-step boot --product-change yes; shw deploy-5-3 report.txt | grep -qx 'product change: yes' || fail 'a yes plant'
# a new attempt deploys again: the earlier staging stopped, by its groups, with the record's stop:
dp deploy --setup "$S" --ask deploy-5 --commit "$C"; [ "$RC" = 0 ] && has deploy-5-4 || fail "the next attempt exited $RC"
! kill -0 "$L1" 2> /dev/null && grep -qx deploy-5-1 "$T/stops" || fail 'the earlier staging was not stopped'
P4=$(port deploy-5-4); up "$P4" || fail 'the new staging is not up'; L4=$(cat "$T/listen-deploy-5-4")
# a new okay replaces it; stop is by its ask alone
dp deploy --setup "$S" --ask deploy-6 --commit "$C"; [ "$RC" = 0 ] && has deploy-6-1 && ! kill -0 "$L4" 2> /dev/null || fail 'a new okay did not replace the staging'
L6=$(cat "$T/listen-deploy-6-1"); P6=$(port deploy-6-1)
dp stop --setup "$S" --ask deploy-5; [ "$RC" = 1 ] && grep -q 'no live staging of deploy-5' "$T/out" && kill -0 "$L6" || fail "stop took another ask's staging: $RC"
dp stop --setup "$S" --ask deploy-6; [ "$RC" = 0 ] && grep -qx 'stopped deploy-6-1' "$T/out" || fail "stop exited $RC"
! kill -0 "$L6" 2> /dev/null && ! up "$P6" && grep -qx deploy-6-1 "$T/stops" || fail 'stop left the staging up'
dp live --setup "$S"; grep -qx 'live none' "$T/out" || fail 'live names a stopped staging'
# refused, nothing pushed
no() { dp deploy --setup "$S" "$@"; [ "$RC" = 1 ] && ! has deploy-7-1 || fail "a deploy pushed with: $*"; }
no --ask deploy-7 --commit "$(printf %s "$C" | cut -c1-12)"; grep -q 'full id' "$T/out" || fail 'a short commit'
no --ask deploy-7 --commit "$(printf '%040d' 3)"; grep -q 'not on origin' "$T/out" || fail 'a commit not on origin'
no --ask deploy-x --commit "$C"; grep -q 'deploy-<issue>' "$T/out" || fail 'a malformed ask'
no --ask deploy-7 --commit "$C" --fail-step migrate; grep -q 'product-change' "$T/out" || fail 'a plant with no product change'
no --ask deploy-7 --commit "$C" --fail-step migrate --product-change maybe; grep -q 'yes or no' "$T/out" || fail 'a plant with maybe'
no --ask deploy-7 --commit "$C" --seed 'production data'; grep -q 'synthetic' "$T/out" || fail 'another seed'
[ "$(wc -l < "$T/starts")" -eq 3 ] || fail 'a refused deploy started something'
# a real failed step: nothing pushed without a judgement; with one, its step and nothing left up
W2=$T/work2; mkdir -p "$W2"; sed -e 's|^start: .*|start: nc -lk 127.0.0.1 "$PORT" > /dev/null 2>\&1 \& echo $! > "$SP_T/l2"; echo "boom"; exit 3|' "$S" > "$W2/dev-setup.txt"
dp deploy --setup "$W2/dev-setup.txt" --ask deploy-8 --commit "$C"; [ "$RC" = 4 ] && grep -q 'failed start' "$T/out" && ! has deploy-8-1 || fail "a failed start with no judgement: $RC"
! kill -0 "$(cat "$T/l2")" 2> /dev/null || fail 'a failed start left its process up'
dp deploy --setup "$W2/dev-setup.txt" --ask deploy-8 --commit "$C" --product-change yes; [ "$RC" = 0 ] && has deploy-8-1 || fail "a judged failed start: $RC"
[ "$(shw deploy-8-1 report.txt)" = "$(printf 'by: DP\ncommit: %s\noutcome: failed start\nproduct change: yes' "$C")" ] && [ "$(tree deploy-8-1)" = 'deploy-8-1/deploy.xml deploy-8-1/report.txt ' ] || fail "the failed start's report: $(tree deploy-8-1)"
shw deploy-8-1 deploy.xml | grep -q '<testcase name="checkout"' && shw deploy-8-1 deploy.xml | grep -q '<testcase name="start"[^>]*><failure' && ! shw deploy-8-1 deploy.xml | grep -q 'name="ready"' || fail "the failed start's steps: $(shw deploy-8-1 deploy.xml)"
sed 's|^start: .*|start: :|' "$S" > "$W2/dev-setup.txt"; dp deploy --setup "$W2/dev-setup.txt" --ask deploy-9 --commit "$C" --product-change no
[ "$RC" = 0 ] && shw deploy-9-1 report.txt | grep -qx 'outcome: failed ready' || fail "a port that never answered: $RC"
sed '/^signin:/d; /^differs:/d' "$S" > "$W2/dev-setup.txt"; dp deploy --setup "$W2/dev-setup.txt" --ask deploy-10 --commit "$C"; [ "$RC" = 0 ] || fail "a record with no sign-ins: $RC"
[ "$(shw deploy-10-1 staging.txt | sed 1d)" = 'differs: none' ] || fail "no differences, no differs: none: $(shw deploy-10-1 staging.txt)"
dp stop --setup "$W2/dev-setup.txt" --ask deploy-10; [ "$RC" = 0 ] || fail 'the second staging would not stop'
# run.sh --against: the rows against that address, nothing started
: > "$T/services"; n=$(wc -l < "$T/starts"); m=$(wc -l < "$T/stops")
run() { RC=0; sh "$R" run --setup "$S" --commit "$C" "$@" > "$T/out" 2>&1 || RC=$?; }
A='http://127.0.0.1:47555'
run --ask req-12-p1c1 --select ROW-007 --engines alpha --against "$A" --signin "admin $A/_test/signin?role=admin" --signin "member $A/m"; [ "$RC" = 0 ] && has req-12-p1c1-1 || fail "an against run exited $RC"
[ "$(cat "$T/seen")" = "$A|admin $A/_test/signin?role=admin
member $A/m" ] || fail "the runner was not given the address and sign-ins: $(cat "$T/seen")"
[ "$(wc -l < "$T/starts")" -eq "$n" ] && [ "$(wc -l < "$T/stops")" -eq "$m" ] && [ ! -s "$T/services" ] || fail 'an against run started, stopped or read services'
$O show vid-results/req-12-p1c1-1:req-12-p1c1-1/results.txt | head -n 2 | grep -qx "commit: $C" || fail "the against run's report"
run --ask req-12-p2c1 --select ROW-007 --engines beta --against "$A"; [ "$RC" = 0 ] && has req-12-p2c1-1 || fail "an against run with no sign-in: $RC"
bad() { w=$1; shift; run "$@"; [ "$RC" = 1 ] && grep -qF -- "$w" "$T/out" || fail "an against run ran with: $*"; }
bad 'no --no-product' --ask req-13-p1c1 --against "$A" --no-product; bad 'carries no line' --ask req-13-p1c1 --against "$A" --line 'stand-in: m'
bad 'no rest chunk' --ask req-13-p1cx --against "$A" --leave-out none; bad "chunk's alone" --ask red-13 --against "$A" --line 'rows: ROW-001'
bad "chunk's alone" --ask "pr-1-$(printf %s "$C" | cut -c1-12)" --against "$A"; bad 'not an address' --ask req-13-p1c1 --against 'staging'
bad 'with --against alone' --ask req-13-p1c1 --signin "admin $A"; bad '"<role> <address>"' --ask req-13-p1c1 --against "$A" --signin admin
RC=0; sh "$R" run --setup "$S" --here "$T/dev" --against "$A" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "chunk's alone" "$T/out" || fail 'the own run took --against'
! has req-13-p1c1-1 && ! has req-13-p1cx-1 || fail 'a refused against run pushed'
exit 0
