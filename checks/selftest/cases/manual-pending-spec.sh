#!/bin/sh
# Purpose: selftest case — an incorporation in GitHub manual shows as pending (IR I6). On the planner's toy in GitHub
# manual, its spec (with a DECISIONS.md) committed and that commit recorded as the applied version, then one commit that
# touches DECISIONS.md and ARCHITECTURE.md alone: D-001 marked replaced by D-002 and D-002 added (3 lines: one removed,
# two added), and a sixth module row (1 line). `next.sh pending` prints both `spec` lines, those counts, and no row line;
# `next.sh triggers` lists the apply move with 0 rows and 2 spec files, its count of tests as before the commit. Both
# again after a later commit of no law file, the applied version unchanged (so the counts are read from the applied
# commit, not the commit before HEAD). Then a change of spaces and blank lines alone, to ARCHITECTURE.md, BASELINE.md and
# GRADING-CHECKLIST.md, in the working tree, changes no count and lists no other file.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "manual-pending-spec: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"
printf '# Decisions\n\nD-001 Every digest goes out at seven in the morning. | scope: project | sure | why: the toy\n' > DECISIONS.md
printf '# Baseline\n\nThe digest runs once a day.\n' > BASELINE.md
printf '# Grading checklist\n\n- A digest names its saved search.\n' > GRADING-CHECKLIST.md
git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw; git rev-parse HEAD > .vid/tw/applied
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed before the incorporation'
grep "^count${TB}" "$T/out" > "$T/count0"; [ -s "$T/count0" ] || fail 'triggers printed no count before the incorporation'
sed 's/^\(D-001 .*\) | why: the toy$/\1 | replaced-by: D-002 | why: the toy/' DECISIONS.md > "$T/d" && cat "$T/d" > DECISIONS.md
printf 'D-002 Every digest goes out at the hour its saved search names. | scope: project | sure | why: records/digest-hour.md@0123456789ab\n' >> DECISIONS.md
printf '| notify | telling a user a digest failed | none | notify | digest |\n' >> ARCHITECTURE.md
grep -q '^D-001 .*| replaced-by: D-002 | why:' DECISIONS.md && grep -q '^D-002 ' DECISIONS.md && grep -q '^| notify ' ARCHITECTURE.md || fail 'the incorporation did not land'
g add DECISIONS.md ARCHITECTURE.md; g commit -qm '/vid incorporate: the digest hour'
[ "$(git diff --name-only HEAD~1 HEAD | sort | tr '\n' ' ')" = 'ARCHITECTURE.md DECISIONS.md ' ] || fail 'the incorporation commit touches more than DECISIONS.md and ARCHITECTURE.md'
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || fail 'next.sh pending failed'
printf 'spec\tARCHITECTURE.md\t1 lines\nspec\tDECISIONS.md\t3 lines\n' > "$T/want"
cmp -s "$T/out" "$T/want" || fail 'pending does not print exactly the two spec lines, ARCHITECTURE.md 1 lines then DECISIONS.md 3 lines, and no row line'
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
grep -q "^move${TB}planning-analysis${TB}-${TB}[0-9a-f]*${TB}proposes how the plan takes in the pending changes, 0 rows, 2 spec files" "$T/out" || fail 'triggers does not list planning-analysis with 0 rows and 2 spec files'
grep "^count${TB}" "$T/out" | cmp -s - "$T/count0" || fail 'the count of tests changed with spec files alone: a spec file counted as a test'
# a later commit of no law file, the applied version unchanged: the counts are still from the applied commit, not HEAD~1
printf 'notes on the toy\n' > NOTES.txt; g add NOTES.txt; g commit -qm 'a note'
[ "$(git rev-parse HEAD~2)" = "$(cat .vid/tw/applied)" ] || fail 'the applied commit is not two commits back'
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || fail 'next.sh pending failed after the later commit'
cmp -s "$T/out" "$T/want" || fail 'after a later commit of no law file, pending does not print the same two spec lines'
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed after the later commit'
grep -q "^move${TB}planning-analysis${TB}-${TB}[0-9a-f]*${TB}proposes how the plan takes in the pending changes, 0 rows, 2 spec files" "$T/out" || fail 'after a later commit of no law file, triggers does not list planning-analysis with 0 rows and 2 spec files'
# spaces and blank lines alone are no change
sed 's/^| notify | telling/|  notify  |   telling/; s/$/  /' ARCHITECTURE.md > "$T/a" && printf '\n\n' >> "$T/a" && cat "$T/a" > ARCHITECTURE.md
printf '\n' >> BASELINE.md; sed 's/^- A digest/-   A digest/' GRADING-CHECKLIST.md > "$T/c" && cat "$T/c" > GRADING-CHECKLIST.md
git diff --quiet -- ARCHITECTURE.md BASELINE.md GRADING-CHECKLIST.md && fail 'the whitespace edits did not land'
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || fail 'next.sh pending failed after the whitespace edits'
cmp -s "$T/out" "$T/want" || fail 'a change of spaces or blank lines alone changed a spec count or listed a file'
exit 0
