#!/bin/sh
# Purpose: selftest case — each ticket names its CI scope (v0.26.10.12 spec R2, R9). The planner's toy (fixtures/
# tickets.sh gh_vid) with the skeleton's test facts and run-full: in the vid-code block, and one merged ticket whose
# rows are ROW-006 (a journey) and ROW-004 (a behaviour row). `brief.sh write --ticket` for step A (ROW-001) stamps a
# `### CI scope` in section 16: `selector:` the session's --selection, ROW-001 at its test path as the ticket's row,
# ROW-006 as the alarm set's — not ROW-004 (not a journey, shell or reachability row) and no hostility probe — and its
# return block carries `ci-scope: <the selector>`; the brief passes its check and splits into parts. Without run-full:
# (a skeleton merged before 0.26.10.12, R8) the ticket carries no CI scope and no ci-scope: line. return-check: the
# block's ci-scope: equal to the ticket's selector passes; unequal, absent or doubled is refused, naming it; an older
# ticket (no CI scope) requires none and accepts one. vid-replan §6 names the selection's reach. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "ci-scope-stamp: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
awk '/^labels-prefix:/ { print; print "test-framework: the toy runner"; print "test-dir: tests/invariants"; print "run-one: sh tests/run.sh <names>"; print "ci-workflow: CI"; print "report: vid-junit-<run attempt>"; print "run-full: gh workflow run CI --ref main"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
printf '\n## Placement rules\n\n- app/ only.\n\n## Ledger and docs laws\n\n- tests are law.\n\n## Import law\n\n- seams.\n\n## Law-change rule\n\n- standalone.\n' >> CLAUDE.md
printf '# Grading\n\n- reads well\n' > GRADING-CHECKLIST.md
g add -A && g commit -qm 'the test facts'
# a merged ticket of step C: ROW-006 (journey) and ROW-004 (behaviour)
mkdir -p .vid/briefs/0 .vid/tickets; printf 'role: builder    slice: 0    step: C\n\n## 1 rows\n\nROW-004 | behavior | REQ-004 | x\nROW-006 | journey | /notes | x\n\n## 2 items\n' > .vid/briefs/0/builder-9.md
printf 'ticket number=90 step=C kind=feature brief=.vid/briefs/0/builder-9.md parts=1 hash=x\n' >> .vid/tickets/map
printf 'ticket issue=90 step=C kind=feature state=merged pr=91 at=2026-10-25T00:00:00Z\n' >> .vid/metrics-events
. "$CHECKS/selftest/fixtures/brief-write.sh"; bw_plugin
SEL='tests/invariants/test_a.py tests/invariants/test_f.py'
sh checks/brief.sh write --role builder --slice 1 --step A --rows ROW-001 --selection "$SEL" --ticket > "$T/out" 2>&1 || fail 'the ticket was not written'
BR=$(sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1); [ -f "$BR" ] || fail 'no brief'
sc() { awk '/^## [0-9]/ { on = ($2 == 16); next } on && /^### / { cs = ($0 == "### CI scope"); next } on && cs' "$BR"; }
sc | grep -qx "selector: $SEL" || fail "the CI scope does not give the session's selection as its selector"
sc | grep -qx 'ROW-001 tests/invariants/test_a.py ticket' || fail "the CI scope does not list ROW-001 as the ticket's row"
sc | grep -qx 'ROW-006 tests/invariants/test_f.py alarm' || fail 'the CI scope does not list the built journey ROW-006 in the alarm set'
sc | grep -q 'ROW-004' && fail 'the CI scope lists ROW-004, a behaviour row of the merged ticket'
sc | grep -q 'HOS-' && fail 'the CI scope lists a hostility probe'
[ "$(sc | grep -c '^ROW-')" = 2 ] || fail 'the CI scope does not hold exactly two rows'
awk '/^```vid-return/ { on = 1; next } on && /^```/ { exit } on' "$BR" | grep -qx "ci-scope: $SEL" || fail "the return block template has no ci-scope: line with the selector"
grep -q 'keep the return block'"'"'s$' "$BR" || fail 'the instructions do not tell the dev team to keep the ci-scope: line'
sh checks/brief.sh "$BR" > "$T/out" 2>&1 || fail 'the ticket fails its own check'
sh checks/ticket.sh body "$BR" --out "$T/parts" > "$T/out" 2>&1 || fail 'the ticket does not split into parts'
# without run-full: no CI scope
grep -v '^run-full:' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A && g commit -qm 'an older skeleton'
sh checks/brief.sh write --role builder --slice 1 --step A --rows ROW-001 --selection "$SEL" --ticket > "$T/out" 2>&1 || fail 'the older ticket was not written'
BO=$(sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1)
grep -q '^### CI scope' "$BO" && fail 'a ticket written without run-full: carries a CI scope'
grep -q '^ci-scope:' "$BO" && fail 'a ticket written without run-full: carries a ci-scope: line'
# return-check
blk() { printf 'Sign in.\n\n```vid-return\nticket: #5\n%brows:\n  REQ-001/ROW-001   pass   ci: 201\ndecisions:\n  - none\ndiscovered:\n  - none\nlaw-needed:\n  - none\nquestions:\n  - none\n```\n' "$1"; }
rc() { sh checks/ticket.sh return-check "$@" > "$T/out" 2>&1; }
blk "ci-scope: $SEL\n" > "$T/eq.md"; blk 'ci-scope: tests/invariants/test_a.py\n' > "$T/ne.md"; blk '' > "$T/no.md"; blk "ci-scope: $SEL\nci-scope: $SEL\n" > "$T/two.md"
rc "$T/eq.md" --ticket "$BR" || fail 'a ci-scope: equal to the selector was refused'
if rc "$T/ne.md" --ticket "$BR"; then fail 'an unequal ci-scope: passed'; fi; grep -q 'ci-scope: reads "tests/invariants/test_a.py", not the ticket'"'"'s selector' "$T/out" || fail 'the unequal refusal does not say so'
if rc "$T/no.md" --ticket "$BR"; then fail 'a missing ci-scope: passed'; fi; grep -q 'the block has no ci-scope: line' "$T/out" || fail 'the missing refusal does not say so'
if rc "$T/two.md" --ticket "$BR"; then fail 'two ci-scope: lines passed'; fi; grep -q 'ci-scope: appears 2 times' "$T/out" || fail 'the doubled refusal does not say so'
rc "$T/no.md" --ticket "$BO" || fail 'an older ticket required a ci-scope: line'
rc "$T/eq.md" --ticket "$BO" || fail 'an older ticket refused a ci-scope: line'
rc "$T/eq.md" || fail 'a ci-scope: line was refused without --ticket'
# the skill
R=$(tr '\n' ' ' < "$CHECKS/../skills/vid-replan/SKILL.md" | tr -s ' ')
printf '%s' "$R" | grep -qF 'the selection covers its rows'"'"' tests and the alarm set'"'"'s' || fail 'vid-replan §6 does not name the selection'"'"'s reach'
printf '%s' "$R" | grep -qF '`### CI scope`' || fail 'vid-replan §6 does not name the CI scope'
exit 0
