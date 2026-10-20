#!/bin/sh
# Purpose: selftest case — a project without STAGES.md behaves exactly as today (v0.26.10.5 spec §1, §3; §5
# no-stages-unchanged). The toy product (fixtures/stages.sh) with STAGES.md removed, ROW-004 red: the outputs of
# `coverage.sh --strict`, `metrics.sh completion` and plan admission (a gated toy run, fixtures/plan-run.sh, with
# checks/stages.sh present) equal, line for line, what main's 0.26.10.4 readers printed on the same fixture
# (recorded below, the commit and the plan hash normalised); no `refused … by=stage`; `stages.sh deploy` claims "as
# today"; metrics.sh's block lists nothing "since stage". v0.26.10.7 (R2, R12; §5 no-stages-unchanged): the staging
# candidate is HEAD, and `stages.sh hold` refuses with one line, recording nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "no-stages-unchanged: $*" >&2; exit 1; }
cat > "$T/today" <<'GOLD'
--- coverage
receipt: .vid/ledger-results/SHA.full.xml cases=9 passed=8 failed=1 skipped=0 error=0
deployed: none declared (no deployed-selector: in the harness contract)
    GAP  ROW-004 — not green: tests/invariants/test_d.py::t[ROW-004] failed
REQ         cited   test   status
REQ-001     yes     yes    OK
REQ-002     yes     yes    OK
REQ-003     yes     yes    OK
REQ-004     yes     no     ROW-GAP (ROW-004) — counted once per row, above
later (deferred, never a gap): REQ-005 
    inventory: rows=6 routes=0 route-gaps=0 owed=0 (legitimate=0: guard-first=0 census-armed=0 probe-capture=0 golden-set=0 fixture-source=0 prerequisite=0 owner-decision=0 reverted=0; other=0; seam-probes=0) deploy-owed=0 orphans=0 missing-tests=0 hostility=2 tier0=2 hostility-gaps=0

REQs: 4   gaps: 1   open VID-QUESTION markers: 0   deploy-owed: 0   later items: 1   later markers: 0
note: 'cited' = citation present under app-source placement prefixes; the ledger tests are the evidence.
ViD coverage --strict: not done — close every gap and resolve every open question.
exit=1
--- completion
closure contract-ambiguity n=0
closure invalid-test-evidence n=0
closure unfinished-implementation n=2 ROW-004 ROW-005
closure deploy-owed n=0
closure later n=1
completion unmet=2 strict-gaps=1
not complete — unmet 2, strict gaps 1 (the closure above; checks/coverage.sh --strict names every gap)
--- admission
ViD plan: admitted S1 under plan HASH
ViD plan: refused — rule B:
    S2 builds on S1, which is not passing: ROW-001 never run, ROW-002 never run
    Fix S2's prerequisite, or change the plan (sh checks/plan.sh change split "…"): a red row split into its own step that S2 does not build on.
exit=1
1
GOLD
st_close_repo "$T/r"
g rm -q STAGES.md; g commit -qam 'one stage: no STAGES.md'
st_rcpt ROW-004=failed; st_keep ROW-001 ROW-002 ROW-003 ROW-006
H=$(git rev-parse --short=12 HEAD)
{ echo '--- coverage'; sh checks/coverage.sh --strict 2>&1 || echo "exit=$?"
  echo '--- completion'; sh checks/metrics.sh completion 2>&1; } | sed "s/$H/SHA/g" > "$T/got"
sh checks/stages.sh deploy --platform none > "$T/dep" 2>&1 || fail 'stages.sh deploy refused a project without STAGES.md'
# v0.26.10.7 (R2, R12): the claim stays today's; the staging candidate is HEAD; hold refuses with one line
grep -qx 'claim: as today — sh checks/metrics.sh completion' "$T/dep" || fail "deploy's claim is not today's"
grep -q "^candidate: HEAD $H " "$T/dep" || fail "the staging candidate is not HEAD $H"
if sh checks/stages.sh hold --after 1 --words 'hold after this stage' > "$T/hold" 2>&1; then fail 'hold was accepted without STAGES.md'; fi
[ "$(grep -c . "$T/hold")" -eq 1 ] && grep -q '^hold: refused — this project has no STAGES.md' "$T/hold" || fail "hold's refusal is not one line: $(cat "$T/hold")"
grep -q '^stage-hold ' .vid/metrics-events 2>/dev/null && fail 'a refused hold recorded an event'
sh checks/metrics.sh 2>&1 | grep -q '^since stage' && fail 'the metrics block lists commits since a stage'
plan_repo "$T/p" > /dev/null
cp "$CHECKS/stages.sh" checks/
rows s1 1 2; rows s2 3 3; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'in order' > /dev/null 2>&1
P=$(awk '$1 == "plan-change" { for (i = 2; i <= NF; i++) if (index($i, "hash=") == 1) h = substr($i, 6) } END { print h }' .vid/metrics-events)
{ echo '--- admission'; sh checks/plan.sh start S1 2>&1 || echo "exit=$?"; sh checks/plan.sh start S2 2>&1 || echo "exit=$?"; grep -c '^refused ' .vid/metrics-events || true; } | sed "s/$P/HASH/g" >> "$T/got"
grep -q 'by=stage ' .vid/metrics-events && fail 'an admission was refused by=stage without STAGES.md'
if ! diff "$T/today" "$T/got" > "$T/diff"; then cat "$T/diff" >&2; fail "the outputs differ from today's (above: < today, > now)"; fi
exit 0
