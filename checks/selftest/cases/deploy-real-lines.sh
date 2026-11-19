#!/bin/sh
# Purpose: selftest case — DevAgent's deployer carries the real checks' answers (0.26.11.1.3, R3), devagent/deployer/deploy.sh on the fixture
# project with a local bare repository as origin and a product that listens on 127.0.0.1. The dev setup record holds `real:` lines for
# this okay, for another okay and for an okay whose number begins the same, one of this okay's twice: the passed staging's staging.txt
# holds this okay's lines alone, each key once, its newest line; a record with no real: line gives a staging.txt with none. The
# deployer's role file says how the lines are written, before the deploy on the people's machine, and on a hosted staging after a first
# deploy, then deployed again as the okay's next attempt. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
command -v nc > /dev/null 2>&1 || { echo 'deploy-real-lines: no nc, skipped' >&2; exit 0; }
DP=$CHECKS/../devagent/deployer/deploy.sh; DPM=$CHECKS/../devagent/agents/deployer.md
T=$(mktemp -d)
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "deploy-real-lines: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T"; W=$T/work; S=$W/dev-setup.txt; O="git -C $T/origin.git"
down() { a=$(sed 's/-[0-9]*$//' "$W/staging/live" 2>/dev/null) || return 0; sh "$DP" stop --setup "$S" --ask "$a" > /dev/null 2>&1 || true; }
trap 'down; rm -rf "$T"' EXIT
C=$(git -C "$T/dev" rev-parse HEAD)
cat > "$S" <<X
repo: $T/origin.git
engines: alpha beta
environments: 1
case-limit: 3
service-seconds: 1
ready-seconds: 5
start: [ -z "\${PORT:-}" ] || { nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & echo \$! > "\$SP_T/listen-\$RUN_ID"; }
run: sh tests/runner.sh
seam: SEAM-001 stand-in — a local copy
real: #5-1 not done — no phone to hand yet
real: #4-1 done — an answer to another okay
real: #55-1 done — an answer to an okay whose number begins the same
real: #5-2 done — the mail read in the real inbox
real: #5-1 done — the journey run on a phone, signed in for real
X
dp() { RC=0; sh "$DP" "$@" > "$T/out" 2>&1 || RC=$?; }
shw() { $O show "vid-results/$1:$1/$2"; }
dp deploy --setup "$S" --ask deploy-5 --commit "$C"; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/deploy-5-1' "$T/out" || fail "the deploy exited $RC"
shw deploy-5-1 staging.txt > "$T/st"; grep '^real:' "$T/st" > "$T/rl" || true
[ "$(cat "$T/rl")" = "$(printf 'real: #5-1 done — the journey run on a phone, signed in for real\nreal: #5-2 done — the mail read in the real inbox')" ] || { cp "$T/st" "$T/out"; fail "staging.txt's real: lines are not this okay's, each its newest"; }
# a record with no real: line: none in staging.txt, the rest as it was
grep -v '^real:' "$S" > "$T/s2"; cp "$T/s2" "$S"; dp deploy --setup "$S" --ask deploy-5 --commit "$C"; [ "$RC" = 0 ] || fail "the second deploy exited $RC"
shw deploy-5-2 staging.txt > "$T/st2"; ! grep -q '^real:' "$T/st2" || { cp "$T/st2" "$T/out"; fail 'a record with no real: line gave one'; }
grep -v '^real:' "$T/st" | sed 's|127.0.0.1:[0-9]*|PORT|' > "$T/a"; sed 's|127.0.0.1:[0-9]*|PORT|' "$T/st2" > "$T/b"; cmp -s "$T/a" "$T/b" || { diff "$T/a" "$T/b" > "$T/out" || true; fail 'the real: lines moved the rest of staging.txt'; }
# the role file says how
j() { tr -s '[:space:]' ' ' < "$1"; }
j "$DPM" | grep -qF 'real: #<issue>-<n> done — <what was run, where>' && j "$DPM" | grep -qF 'real: #<issue>-<n> not done — <why>' || fail "the deployer's role file does not name the real: lines"
j "$DPM" | grep -qF "the okay's next attempt" || fail "the deployer's role file does not say a hosted staging is deployed again as the okay's next attempt"
exit 0
