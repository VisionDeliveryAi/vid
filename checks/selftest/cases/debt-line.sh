#!/bin/sh
# Purpose: selftest case — the debt line (v0.9.7.2 spec 3.8, R12). Passing rows: ROW-001 KEPT; ROW-002 BREACHED
# product; ROW-003 a journey graded on one transition of two; ROW-004 never graded; ROW-007 KEPT before an amendment,
# passing since; in the hardening step ROW-009 BREACHED test and ROW-010 BREACHED product, deferred. ROW-005 held
# (Q1 names it). Under breadth first the progress table's Debt row reads, each row once — 9 rows: hardening not done
# 4, passing not KEPT 6 (1 never graded, 2 product, 1 test, 1 part-graded, 1 re-grade after amendment), held 1 with
# Q1, deferred open 1 — and the recorded headline ends `· debt 9`; under depth first the line is the 6 alone.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "debt-line: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-009=passed ROW-010=passed
verdict ROW-001 KEPT; verdict ROW-002 BREACHED product; verdict ROW-003 KEPT '' 1/2
verdict ROW-009 BREACHED test; verdict ROW-010 BREACHED product; verdict ROW-007 KEPT
sh checks/metrics.sh defer --kind product --row ROW-010 --why 'edge' --from receipt:r1 > /dev/null || fail 'the deferral was refused'
for n in 1 2; do printf 'verdict slice=1 row=ROW-005 result=BREACHED class=product brief=.vid/briefs/1/grader-h%s.md quoted-at=%s at=%s\n' "$n" "$(git rev-parse HEAD)" "$(utcnow)" >> .vid/metrics-events; done
printf '\n## Open product questions\n\n- Q1 · asked 2026-10-13 · gates ROW-005 · which archive?\n' >> .vid/RUN-STATE.md
echo c >> app/s2/main.py; commit_all 'amend ROW-007'
printf 'amended row=ROW-007 sha=%s at=%s\n' "$(git rev-parse HEAD)" "$(utcnow)" >> .vid/metrics-events
rcpt r2 HEAD inline ROW-007=passed
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep -qxF '| Debt | 9 rows owed — in hardening, not done 4 · passing, not KEPT 6 (never graded 1 · product breach 2 · test or harness breach 1 · journey part-graded 1 · re-grade after amendment 1) · held 1 (with their questions: Q1) · deferred open 1 |' "$T/out" || fail "the debt line: $(grep '^| Debt' "$T/out")"
sh checks/progress.sh --record > "$T/out" 2>&1; grep -q ' · debt 9$' "$T/out" || fail 'the headline does not end with the debt'
sh checks/plan.sh strategy depth-first --by owner --words 'depth' > /dev/null
sh checks/progress.sh > "$T/out" 2>&1
grep -qxF '| Debt | 6 rows owed — passing, not KEPT 6 (never graded 1 · product breach 2 · test or harness breach 1 · journey part-graded 1 · re-grade after amendment 1) |' "$T/out" || fail "the depth-first line: $(grep '^| Debt' "$T/out")"
exit 0
