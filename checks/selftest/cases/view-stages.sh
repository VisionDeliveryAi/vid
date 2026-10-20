#!/bin/sh
# Purpose: selftest case — the stages part (v0.26.10.8 spec R11; §5 view-stages). The viewer fixture with STAGES.md
# (STAGE-0 technical, STAGE-1, STAGE-2) committed at 11:40 and a correction at 11:58. Events: stage 0 closed 11:45 and
# held 11:46; the hold off, a staging check (ahead=3) and a gate-2 pass on the 11:40 commit, stage-deploy by=develop;
# stage 1 closed at the 11:58 commit; a gate-2 fail on it and `stage-deploy n=1 staging=failed … why=`; a deploy log
# whose newest row is the 11:58 commit, committed at 12:10. Now: 0 closed (technical), 1 closed, 2 building; staging
# at the 11:40 commit, stage 0, ahead 3, its base, by develop, the later failure with its candidate and why;
# production at the 11:58 commit, stage 1. A past snapshot (--at 11:47): 0 held, then 1 and 2 not started, staging and
# production null. Without STAGES.md: an empty list, staging and production still read. --check refuses a wrong type
# in stages. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-stages: $*" >&2; exit 1; }
# vstg <snapshot>: the stages part, one value per line
vstg() { vdata "$1" | awk '/^"stages":/ { on = 1 } on { print } on && /^"production":/ { exit }'; }
deplog() { printf '# Deployment\n\n## Deploy log (append-only)\n\n| Version | Date | Commit | Migration | Backup ref | Previous build |\n|---|---|---|---|---|---|\n| 1 | 2026-01-01 | %s | none | - | - |\n' "$1" > DEPLOYMENT.md; }
view_project "$T/repo"
printf '# Stages\n\n```vid-stages\nSTAGE-0 | the skeleton | technical\nSTAGE-1 | the basics | features: FEAT-01\nSTAGE-2 | the rest | features: FEAT-02\nrow: ROW-001 -> STAGE-0\n```\n' > STAGES.md
g add -A; vcommit 11:40 'the cut'; C0=$(git rev-parse --short=12 HEAD)
printf 'a fix\n' >> README.md; g add -A; vcommit 11:58 'a fix'; C1=$(git rev-parse --short=12 HEAD)
vev 11:45 "stage-closed n=0 sha=$C0 ready rows=1 debt=0 stages-blob=x"
vev 11:46 'stage-hold n=0 state=on'
vev 11:50 'stage-hold n=0 state=off'
vev 11:50:30 "deploy-check target=staging sha=$C0 tests=scoped base=abc123def456 ahead=3 rows=0 receipt=- result=ready"
vev 11:51 "deploy-gate gate=2 state=start candidate=$C0 env=staging"
vev 11:52 'deploy-gate gate=2 state=end result=pass'
vev 11:53 'stage-deploy n=0 staging=yes production=no by=develop'
vev 12:00 "stage-closed n=1 sha=$C1 ready rows=2 debt=0 stages-blob=x"
vev 12:05 "deploy-gate gate=2 state=start candidate=$C1 env=staging"
vev 12:06 'deploy-gate gate=2 state=end result=fail'
vev 12:07 'stage-deploy n=1 staging=failed production=no by=develop why="the platform login expired"'
deplog "$C1"; g add -A; vcommit 12:10 'deployed'
vview . --out "$T/out" --at 2026-01-01T11:47:00Z > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
sh "$VIEWER_SH" --check "$T/out/now.html" > "$T/c" 2>&1 || fail "now does not hold the contract: $(cat "$T/c")"
vstg "$T/out/now.html" > "$T/now"
grep -qF '{"n":0,"name":"the skeleton","technical":true,"state":"closed","closedAt":"2026-01-01T11:45:00Z","commit":"'"$C0"'"}' "$T/now" || fail "stage 0 is not closed and technical: $(cat "$T/now")"
grep -qF '{"n":1,"name":"the basics","technical":false,"state":"closed","closedAt":"2026-01-01T12:00:00Z","commit":"'"$C1"'"}' "$T/now" || fail 'stage 1 is not closed'
grep -qF '{"n":2,"name":"the rest","technical":false,"state":"building","closedAt":null,"commit":null}' "$T/now" || fail 'stage 2 is not building'
grep -qF '"staging":{"commit":"'"$C0"'","at":"2026-01-01T11:52:00Z","stage":0,"ahead":3,"base":"abc123def456","by":"develop","lastFailure":{"at":"2026-01-01T12:07:00Z","candidate":"'"$C1"'","why":"the platform login expired"}}' "$T/now" || fail "staging is not read: $(grep staging "$T/now")"
grep -qF '"production":{"commit":"'"$C1"'","at":"2026-01-01","stage":1}' "$T/now" || fail "production is not read: $(grep production "$T/now")"
P=$(ls "$T/out" | grep 'T114700Z-requested.html$') || fail 'no snapshot at 11:47'
vstg "$T/out/$P" > "$T/past"
grep -qF '"n":0,"name":"the skeleton","technical":true,"state":"held"' "$T/past" || fail "the past snapshot does not hold stage 0: $(cat "$T/past")"
grep -qF '"n":1,"name":"the basics","technical":false,"state":"not started"' "$T/past" && grep -qF '"n":2,"name":"the rest","technical":false,"state":"not started"' "$T/past" || fail 'after a held stage the next is not "not started"'
grep -qx '"staging":null,' "$T/past" && grep -qx '"production":null},' "$T/past" || fail 'the past snapshot reads staging or production it did not have'
# --check refuses a wrong type in stages
sed 's/"technical":true/"technical":"yes"/' "$T/out/now.html" > "$T/out/bad.html"
if sh "$VIEWER_SH" --check "$T/out/bad.html" > "$T/c" 2>&1; then fail '--check passed a string technical'; fi
grep -q 'stages' "$T/c" || fail "--check does not name the stages field: $(cat "$T/c")"
# without STAGES.md
view_project "$T/repo2"
vev 11:51 "deploy-gate gate=2 state=start candidate=$(git rev-parse --short=12 HEAD) env=staging"
vev 11:52 'deploy-gate gate=2 state=end result=pass'
deplog "$(git rev-parse --short=12 HEAD)"; g add -A; vcommit 12:10 'deployed'
vview . --out "$T/out2" > "$T/r" 2>&1 || fail "the run without STAGES.md failed: $(cat "$T/r")"
vstg "$T/out2/now.html" > "$T/none"
grep -qx '"stages":{"list":\[\],' "$T/none" || fail "without STAGES.md the list is not empty: $(head -n 1 "$T/none")"
grep -q '^"staging":{"commit":' "$T/none" && grep -q '^"production":{"commit":' "$T/none" || fail 'without STAGES.md staging or production is not read'
exit 0
