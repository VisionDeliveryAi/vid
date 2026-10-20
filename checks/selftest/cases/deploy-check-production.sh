#!/bin/sh
# Purpose: selftest case — the production check (v0.26.10.7 spec R2, R8, R11; §5 deploy-check-production). The toy
# product (fixtures/stages.sh) without STAGES.md, its last full pass a staging record of B1. Unmet with no gate-2 pass,
# and with one for an older tree (a re-based contract test since); a later commit touching only DEPLOYMENT.md or
# tests/probes/captured/ keeps the gate-2 pass. Unmet with no full run, a failing case, coverage not clean, or a stale
# verdict: ROW-002, its test changed after its verdict, is asked again (`regrade ROW-002`), and so is a verdict quoted
# on another line; graded after its last change, it is not. A row born owed to gate 1 is listed (`owed ROW-008 gate 1`),
# not unmet, and never asked for a verdict, nor is a paid deploy-owed row. Refused while develop runs, and when the
# candidate does not descend from production's commit. `--record` writes the production record. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "deploy-check-production: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
dc() { sh checks/metrics.sh deploy-check --target production "$@" > "$T/out" 2>&1; }
gate2() { _c=$(git rev-parse --short=12 "${1:-HEAD}"); printf 'deploy-gate gate=2 state=start candidate=%s env=staging at=2026-10-20T10:00:00Z\ndeploy-gate gate=2 state=end result=pass at=2026-10-20T10:00:01Z\n' "$_c" >> .vid/metrics-events; }
keep() { _q=$(git rev-parse --short=12 "${2:-HEAD}"); printf 'verdict slice=1 row=%s result=KEPT class=product brief=b%s quoted-at=%s at=2026-10-20T00:00:00Z\n' "$1" "$_q" "$_q" >> .vid/metrics-events; }
born() { awk -v l="$1" '/^```$/ && !d { print l; d = 1 } { print }' INVENTORY.md > inv && mv inv INVENTORY.md; }
st_close_repo "$T/repo"
g rm -q STAGES.md; g commit -qam 'one stage: no STAGES.md'
st_rcpt; st_keep ROW-001 ROW-002 ROW-003 ROW-004 ROW-006
sh checks/metrics.sh deploy-check --target staging --record > "$T/out" 2>&1; grep -q '^deploy-check staging ready' "$T/out" || fail 'the first staging check is not ready'
B1=$(git rev-parse --short=12 HEAD)
dc; grep -q '^unmet .*no gate-2 pass is recorded' "$T/out" || fail 'no gate-2 pass is not unmet'
gate2
dc; grep -qx 'deploy-check production ready' "$T/out" || fail 'the gate-2 pass on the last full pass is not ready'
# the deploy's own records keep the gate-2 pass
mkdir -p tests/probes/captured; printf '{}\n' > tests/probes/captured/mail.json
printf '# Deployment\n\n## Deploy log (append-only)\n\n| Version | Date | Commit | Migration | Backup ref | Previous build |\n|---|---|---|---|---|---|\n' > DEPLOYMENT.md
g add -A; g commit -qm 'the deploy records'
sh checks/stages.sh candidate --target production > "$T/out" 2>&1 && grep -q "^candidate $B1 head " "$T/out" || fail 'a commit of DEPLOYMENT.md and a capture did not keep the gate-2 pass'
dc; grep -q '^unmet no full run current for HEAD' "$T/out" || fail 'no full run of HEAD is not unmet'
st_rcpt; dc; grep -qx 'deploy-check production ready' "$T/out" || fail 'not ready with the full run of HEAD'
# a re-based contract test: the gate-2 pass is for an older tree
printf '# re-based on the capture\n' >> tests/invariants/test_b.py; g commit -qam 'ROW-002 re-based'
dc; grep -q "^unmet .*the commit staging runs ($B1) is not HEAD's tree" "$T/out" || fail 'a gate-2 pass for an older tree is not unmet'
gate2; st_rcpt
dc; grep -qx 'regrade ROW-002' "$T/out" || fail 'a verdict older than its row'"'"'s change is not asked again'
grep -qx 'regrade ROW-001' "$T/out" && fail 'a row outside the change set was asked again'
g checkout -q -b side; printf 'x\n' > side.txt; g add side.txt; g commit -qm side; SIDE=$(git rev-parse --short=12 HEAD); g checkout -q -
keep ROW-002 "$SIDE"; dc; grep -qx 'regrade ROW-002' "$T/out" || fail 'a verdict quoted on another line counted'
keep ROW-002; dc; grep -qx 'deploy-check production ready' "$T/out" || fail 'a row graded after its last change was asked again'
st_rcpt ROW-003=failed; dc; grep -q '^unmet the full run .* has 1 failing case' "$T/out" || fail 'a failing case is not unmet'
st_rcpt; printf 'verdict slice=1 row=ROW-003 result=BREACHED class=product brief=bx quoted-at=%s at=2026-10-20T00:00:01Z\n' "$(git rev-parse --short=12 HEAD)" >> .vid/metrics-events
dc; grep -q '^unmet coverage: not clean' "$T/out" || fail 'coverage not clean is not unmet'
keep ROW-003
# rows owed to a deploy gate: listed, never asked for a verdict
born 'ROW-008 | behavior | REQ-001 | anonymous | n/a | the backup restores | REQ-001 | owed: paid by /vid deploy gate 1 — a restored backup'
born 'ROW-009 | behavior | REQ-002 | anonymous | n/a | one real mail | REQ-002 | owed: paid by /vid deploy gate 2 — one real mail | paid-at: gate-2 2026-10-20 v0.1'
g commit -qam 'two rows owed to the deploy'; gate2; st_rcpt
dc; grep -qx 'owed ROW-008 gate 1' "$T/out" || fail 'the gate-1-owed row is not listed'
grep -q '^regrade ROW-00[89]' "$T/out" && fail 'a deploy-owed row was asked for a verdict'
grep -q 'owed ROW-009' "$T/out" && fail 'a paid deploy-owed row is listed'
grep -qx 'deploy-check production ready' "$T/out" || fail 'the deploy-owed rows made it unmet'
# refused while develop runs, without STAGES.md too
printf 'run: active\nsession: S1\nplan: required\n' > .vid/rs0; cp .vid/RUN-STATE.md .vid/rs.keep; cp .vid/rs0 .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=27 at=2026-10-20T11:00:00Z\n' >> .vid/metrics-events
dc; grep -q '^unmet .*a build is running' "$T/out" || fail 'production was not refused while develop runs'
printf 'stage name=develop state=end session=S1 at=2026-10-20T11:00:01Z\n' >> .vid/metrics-events; cp .vid/rs.keep .vid/RUN-STATE.md
# production on another line: the candidate does not descend from it
printf '| v0.1 | 2026-10-20 | %s | no | - | - |\n' "$SIDE" >> DEPLOYMENT.md; g commit -qam 'production runs the side line'; gate2; st_rcpt
dc; grep -q '^unmet .*production runs .* does not descend from it' "$T/out" || fail 'a candidate not descending from production was not refused'
printf '| v0.2 | 2026-10-20 | %s | no | - | - |\n' "$B1" >> DEPLOYMENT.md; g commit -qam 'production runs B1'; gate2; st_rcpt
dc --record; grep -qx 'deploy-check production ready' "$T/out" || fail 'not ready once production is an ancestor'
grep -q "^deploy-check target=production sha=$(git rev-parse --short=12 HEAD) tests=full base=$B1 regraded=1 result=ready at=" .vid/metrics-events || fail 'the production record is not written'
sh checks/metrics.sh deploy-check > "$T/out" 2>&1; grep -qx "base: $(git rev-parse --short=12 HEAD) (deploy-check target=production)" "$T/out" || fail 'the production record is not the new last full pass'
exit 0
