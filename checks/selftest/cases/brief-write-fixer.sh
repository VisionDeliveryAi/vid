#!/bin/sh
# Purpose: selftest case — a fixer brief written in a develop run
# (v0.9.7.0.5 spec 3.3; §6 W-3). The plan fixture (a gated develop run, a
# plan with step S1 holding ROW-001..ROW-002 and S2 holding ROW-003), with
# the four law sections in its CLAUDE.md and an attempt record for ROW-001.
# Convicts unless `sh checks/brief.sh write --role fixer`: refuses a fixer
# brief without --step inside the run, writing nothing; names the step in
# the header; quotes the attempt record whole in section 7; lists the
# role's request form in section 6 with its rows filled in; and runs the
# admission — the step admitted, and a row of another step refused by
# plan.sh admit. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-write-fixer: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 3
printf '\n## Placement rules\n\n- app/ holds the product.\n\n## Ledger and docs laws\n\n- The ledger runs only through requests.\n\n## Import law\n\n- Imports cross declared seams.\n\n## Law-change rule\n\n- A law change is its own commit.\n' >> CLAUDE.md
commit_all rows
plan 'step S1 | name: base | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: builder' 'step S2 | name: next | modules: app/s2 | builds-on: S1 | rows: ROW-003 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'it builds' > /dev/null
mkdir -p .vid/verdicts
printf '# ROW-001 — attempt record\n\n## slice 1 · brief .vid/briefs/1/grader-1.md\n\nBREACHED class=product: the toy accepts an empty name (app/s1/main.py:1)\n' > .vid/verdicts/ROW-001.md
mkdir -p .vid/briefs/1; ls .vid/briefs/1 > "$T/before"
if bw_write --role fixer --slice 1 --rows ROW-001,ROW-002; then fail 'a fixer brief without --step was written in a develop run'; fi
grep -qF 'names its plan step (--step)' "$T/wout" || fail 'the refusal does not name --step'
ls .vid/briefs/1 | cmp -s - "$T/before" || fail 'a refused brief left a file'
bw_write --role fixer --slice 1 --step S1 --rows ROW-001,ROW-002 || fail 'the writer refused a well-formed fixer brief'
F=$(bw_out)
head -n 1 "$F" | grep -qx 'role: fixer    slice: 1    step: S1' || fail 'the header does not name the step'
sed -n '/^## 7/,/^## 8/p' "$F" > "$T/s7"
while IFS= read -r l; do [ -z "$l" ] || grep -qxF -- "$l" "$T/s7" || fail "section 7 does not quote the attempt record whole: $l"; done < .vid/verdicts/ROW-001.md
grep -qx 'sh checks/test.sh request --type iterate --role fixer --rows ROW-001,ROW-002 --try 1-fixer-1 --why "<fill in>" -- tests/invariants' "$F" || fail 'section 6 is not the real request command (v0.9.7.1: --try, the selection)'
grep -qx 'sh checks/test.sh wait <ticket>' "$F" || fail 'section 6 has no wait'
grep -q 'ViD plan: admitted S1' "$T/wout" || fail 'the admission did not run'
# a row of another step: the admission refuses it, keeping the file
bw_write --role fixer --slice 1 --step S1 --rows ROW-001,ROW-003 && fail 'a row of another step was admitted'
grep -qF 'not all rows of step S1' "$T/wout" || fail 'the admission refusal is not shown'
[ -f "$(bw_out)" ] || fail 'a refused brief was not kept'
exit 0
