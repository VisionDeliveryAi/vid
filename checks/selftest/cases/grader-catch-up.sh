#!/bin/sh
# Purpose: selftest case — catch-up grading (v0.9.7.2 spec 3.5, R8). `brief.sh write --role grader --catch-up <step>`
# takes its rows and evidence from the step's close. S1, closed by a report: the brief names that receipt and briefs
# only its ungraded eligible rows passing on it now — not ROW-001 (graded), not ROW-003 (amended since: stale, named
# as left out), not ROW-004 (red on a later run). S2, closed by a batch: the brief names the batch's receipts and
# each row's cases from the chunks that credit it; ROW-008, which no chunk credits, is left out. Refused: a step never
# closed, --catch-up with --rows, and a step whose ungraded rows all fail the rule. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "grader-catch-up: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin
bf_repo "$T/repo"
printf '# CLAUDE.md\n\n## Placement rules\n\nx\n\n## Ledger and docs laws\n\nx\n\n## Import law\n\nx\n\n## Law-change rule\n\nx\n' > CLAUDE.md; commit_all laws
bf_on > /dev/null; bf_plan "$S1L" "$S2L" > /dev/null
cu() { sh checks/brief.sh write --role grader --slice 1 --catch-up "$1" > "$T/out" 2>&1; }
if cu S1; then fail 'a step never closed was caught up'; fi
grep -q 'never closed' "$T/out" || fail 'the refusal does not say never closed'
sh checks/plan.sh start S1 > /dev/null
close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null || fail 'S1 did not close'
R1=$(sed -n 's/^step-closed step=S1 report=\([^ ]*\) .*/\1/p' .vid/metrics-events | tail -n 1)
keepall ROW-001
echo a >> app/s1/main.py; commit_all 'amend ROW-003'
printf 'amended row=ROW-003 sha=%s at=%s\n' "$(git rev-parse HEAD)" "$(utcnow)" >> .vid/metrics-events
rcpt later HEAD inline ROW-004=failed
if sh checks/brief.sh write --role grader --slice 1 --catch-up S1 --rows ROW-002 > "$T/out" 2>&1; then fail '--catch-up was taken with --rows'; fi
cu S1 || fail 'the catch-up was refused'
B=$(sed -n 's/^ViD brief write: wrote \([^ ]*\).*/\1/p;s/^\(\.vid\/briefs\/[^ ]*\.md\).*/\1/p' "$T/out" | head -n 1); [ -n "$B" ] || B=$(ls .vid/briefs/1/grader-*.md | tail -n 1)
grep -q 'left out ROW-003 ROW-004\|leaves out ROW-003 ROW-004' "$T/out" || fail 'the rows left out are not named'
grep -qx "receipt: .vid/ledger-results/$R1" "$B" || fail "the brief does not name the close's receipt"
sed -n '/^## 1 rows/,/^## 2/p' "$B" | grep -o '^ROW-[0-9]*' | tr '\n' ' ' | grep -qx 'ROW-002 ' || fail "the brief's rows are not ROW-002 alone: $(sed -n '/^## 1 rows/,/^## 2/p' "$B" | grep -o '^ROW-[0-9]*' | tr '\n' ' ')"
grep -q '^catch-up of step S1 from its close' "$B" || fail 'the brief does not say it is a catch-up'
# a batch close: two chunks, each crediting its rows through .rows; ROW-008 credited by none
verdict ROW-002 KEPT; verdict ROW-003 KEPT; verdict ROW-004 KEPT
rcpt fixed HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed
sh checks/plan.sh start S2 > /dev/null || fail 'S2 was refused'
rcpt c1 HEAD inline ROW-005=passed ROW-006=passed; printf 'ROW-005\nROW-006\n' > .vid/ledger-results/c1.rows
rcpt c2 HEAD inline ROW-007=passed ROW-008=passed; printf 'ROW-007\n' > .vid/ledger-results/c2.rows
mkdir -p .vid/requests/B1/frozen; printf 'tree=x\nsteps=S2\n' > .vid/requests/B1/batch
printf '1\t%s\n2\t%s\n' "$(pwd -P)/.vid/ledger-results/c1" "$(pwd -P)/.vid/ledger-results/c2" > .vid/requests/B1/receipts
for r in 5 6 7 8; do printf 'ROW-00%s\t1\tS2\t1\tinline\n' "$r"; done > .vid/requests/B1/frozen/required
printf 'step-closed step=S2 report=c2 batch=B1 at=%s\n' "$(utcnow)" >> .vid/metrics-events
cu S2 || fail 'the batch catch-up was refused'
B=$(ls -t .vid/briefs/1/grader-*.md | head -n 1)
grep -q '^receipts: close batch B1 — ' "$B" || fail "the brief does not name the batch's receipts"
sed -n '/^## 1 rows/,/^## 2/p' "$B" | grep -o '^ROW-[0-9]*' | tr '\n' ' ' | grep -qx 'ROW-005 ROW-006 ROW-007 ' || fail "the batch brief's rows are not 5–7"
grep -q 'leaves out ROW-008' "$T/out" || fail 'ROW-008 (credited by no chunk) is not named as left out'
grep -q 'test_007\[ROW-007\] passed' "$B" || fail "ROW-007's case from its chunk is not in the brief"
keepall ROW-005 ROW-006 ROW-007
if cu S2; then fail 'a step whose only ungraded row passes nowhere was caught up'; fi
grep -q 'ROW-008' "$T/out" || fail 'the refusal does not name ROW-008'
exit 0
