#!/bin/sh
# Purpose: selftest case — import checks the scope (v0.26.10.12 spec R5, R9). The planner's toy (fixtures/tickets.sh
# gh_vid) with run-full: in the vid-code block and a merged ticket holding the journey ROW-006, so step A's ticket
# (gh_feature: ROW-001) is stamped with ROW-001 as its row and ROW-006 in its alarm set; its pull request, its block
# carrying the ci-scope: line, is merged. `ticket.sh import <pr>`: a head report without ROW-006's case is refused,
# naming it, nothing published; a report with ROW-006 failing publishes the receipt (its .rows ROW-001 alone), prints
# `sent back:` naming ROW-006 and its route (a fix ticket of the step with the ticket's rows, the alarm set riding its CI
# scope — found by the rehearsal), checks no hand-back and exits 1; a report with both passing is imported and its
# hand-back accepted. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "ci-scope-import: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
awk '/^labels-prefix:/ { print; print "test-framework: the toy runner"; print "test-dir: tests/invariants"; print "run-one: sh tests/run.sh <names>"; print "ci-workflow: CI"; print "report: vid-junit-<run attempt>"; print "run-full: gh workflow run CI --ref main"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
printf '\n## Placement rules\n\n- app/ only.\n\n## Ledger and docs laws\n\n- tests are law.\n\n## Import law\n\n- seams.\n\n## Law-change rule\n\n- standalone.\n' >> CLAUDE.md
printf '# Grading\n\n- reads well\n' > GRADING-CHECKLIST.md
g add -A && g commit -qm 'the test facts'
mkdir -p .vid/briefs/0 .vid/tickets; printf 'role: builder    slice: 0    step: C\n\n## 1 rows\n\nROW-006 | journey | /notes | x\n\n## 2 items\n' > .vid/briefs/0/builder-9.md
printf 'ticket number=90 step=C kind=fix brief=.vid/briefs/0/builder-9.md parts=1 hash=x\n' >> .vid/tickets/map
printf 'ticket issue=90 step=C kind=fix state=merged pr=91 at=2026-10-25T00:00:00Z\n' >> .vid/metrics-events
gh_feature 2>"$T/out" || fail "the feature ticket and its pull request were not made"
grep -qx 'ROW-006 tests/invariants/test_f.py alarm' "$BR" || fail "the ticket's CI scope does not hold ROW-006"
# the block, with its ci-scope: line
awk '{ print } /^ticket: #/ { print "ci-scope: tests/invariants/test_a.py" }' "$T/gh/prs/$P/body" > "$T/b" && cp "$T/b" "$T/gh/prs/$P/body"
gh pr merge "$P" -R owner/code --merge --body 'Stand-in: approver' > /dev/null 2>&1 || fail 'the merge failed'
git -C .vid/code fetch -q
rep() { printf '<testsuites><testsuite name="t">\n'; for c in "$@"; do p=${c%%|*}; c=${c#*|}; printf '  <testcase classname="%s" name="%s" time="0.1"%s\n' "$p" "${c%%=*}" "$( [ "${c#*=}" = failed ] && printf '><failure message="no"/></testcase>' || printf '/>')"; done; printf '</testsuite></testsuites>\n'; }
rep 'tests/invariants/test_a.py|test_1[ROW-001]=passed' > "$T/only.xml"
rep 'tests/invariants/test_a.py|test_1[ROW-001]=passed' 'tests/invariants/test_f.py|test_6[ROW-006]=failed' > "$T/alarm.xml"
rep 'tests/invariants/test_a.py|test_1[ROW-001]=passed' 'tests/invariants/test_f.py|test_6[ROW-006]=passed' > "$T/green.xml"
H12=$(printf '%s' "$HEAD1" | cut -c1-12)
imp() { : > "$T/gh/runs"; gh_ci "$HEAD1" "$1" 1 success CI "$2"; sh checks/github.sh pull > /dev/null 2>&1; sh checks/ticket.sh import "$P" > "$T/out" 2>&1; }
# a scoped row missing: refused, nothing published
N0=$(ls .vid/ledger-results 2>/dev/null | grep -c . || true)
if imp 301 "$T/only.xml"; then fail 'a report without the alarm row was imported'; fi
grep -q 'lacks expected tests: ROW-006 (tests/invariants/test_f.py)' "$T/out" || fail 'the refusal does not name ROW-006'
[ "$(ls .vid/ledger-results 2>/dev/null | grep -c . || true)" = "$N0" ] || fail 'the refused import published something'
# the alarm row failing: published, sent back, no hand-back
if imp 302 "$T/alarm.xml"; then fail 'a red alarm row did not send the ticket back'; fi
R=$H12.ci-302-1.xml; [ -f ".vid/ledger-results/$R" ] || fail 'the red evidence was not published'
[ "$(cat ".vid/ledger-results/$R.rows")" = ROW-001 ] || fail "the receipt's .rows is not the ticket's row alone"
grep -q '^sent back: the alarm set is red in run 302 attempt 1 — ROW-006 (tests/invariants/test_f.py::test_6\[ROW-006\] failed)' "$T/out" || fail 'the send-back does not name ROW-006'
grep -q 'a fix ticket of its step with the ticket'"'"'s rows, these riding its CI scope'"'"'s alarm set' "$T/out" || fail 'the send-back does not name its route (found by the rehearsal: a fix ticket cannot carry another step'"'"'s rows)'
grep -q '^agent-returned ' .vid/metrics-events && fail 'the hand-back was checked for a ticket sent back'
grep -q '^hand-back' "$T/out" && fail 'the import wrote a hand-back'
# both passing: imported, the hand-back accepted
imp 303 "$T/green.xml" || fail 'a green scoped run was refused'
grep -q '^ViD return: ok — .*(1 of 1 rows pass)' "$T/out" || fail 'the hand-back was not accepted'
exit 0
