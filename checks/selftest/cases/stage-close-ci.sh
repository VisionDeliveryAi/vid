#!/bin/sh
# Purpose: selftest case — a ticket-mode stage closes from main's CI run (v0.26.10.9 spec R18; §5 stage-close-ci). The
# planner's toy (fixtures/tickets.sh gh_vid) holds NO checks/extractors/results.sh, so nothing but the receipt's .cases
# can be read. Stage 1: ROW-001 and ROW-002 KEPT and passing in main's run at the last merge (imported with `ticket.sh
# import --main <sha> --stage 1`), RULE-001 census-armed, HOS-002 guard-first, ROW-007 owed to deploy gate 1, and
# REQ-002 cited nowhere in the code copy: `stage-close --stage 1 --ci <receipt>` is ready; RULE-001, HOS-002 and
# ROW-007 are listed by name as debt; the census and the citation and marker joins are reported "not checked in
# ticket mode", the uncited requirement not refused; --record writes `stage-closed n=1 sha=<the code commit>
# source=ci run=`, no tag, `stage: 2`, the stage report with its debt. With ROW-002 failing in the run, or ViD's copy
# of its test changed at that commit, not ready, naming it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "stage-close-ci: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"; cp "$CHECKS/metrics.sh" checks/
[ ! -e checks/extractors/results.sh ] || fail 'the toy holds a results reader — the case would prove nothing'
sed -e 's#^\(rule | RULE-001 | .*| \)tests/invariants/test_rule.py$#\1owed: census-armed — no site yet#' \
    -e 's#^\(hostility | HOS-002 | .*| \)tests/invariants/test_hos2.py$#\1owed: guard-first — the password guard; paid in the slice that builds it#' INVENTORY.md > I.x
awk '{ print } /^ROW-006 / { print "ROW-007 | behavior | REQ-001 | anonymous | n/a | the sign-in page is served over TLS in production | REQ-001 | owed: paid by /vid deploy gate 1 — production TLS" }' I.x > INVENTORY.md; rm -f I.x
awk '/^labels-prefix:/ { print; print "ci-workflow: CI"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
g add -A && g commit -qm 'ticket-mode rows'
grep -q 'RULE-001 .*owed: census-armed' INVENTORY.md && grep -q 'HOS-002 .*owed: guard-first' INVENTORY.md || fail 'the toy rows were not set'
tk_dev 'stage 1 merged' tests/invariants/test_a.py "$(cat tests/invariants/test_a.py)" tests/invariants/test_b.py "$(cat tests/invariants/test_b.py)" app/login/main.py 'sign in'
C=$(git -C "$T/code.git" rev-parse main); C12=$(printf '%s' "$C" | cut -c1-12)
rep() { printf '<testsuites><testsuite name="t">\n  <testcase classname="tests/invariants/test_a.py" name="test_1[ROW-001]" time="0.1"/>\n  <testcase classname="tests/invariants/test_b.py" name="test_2[ROW-002]" time="0.1"%s\n</testsuite></testsuites>\n' "$1"; }
rep '/>' > "$T/green.xml"; rep '><failure message="lost"/></testcase>' > "$T/red.xml"
H=$(git rev-parse HEAD)
for r in ROW-001 ROW-002; do printf 'verdict slice=1 row=%s result=KEPT class=product brief=.vid/briefs/1/grader-1.md quoted-at=%s at=2026-10-24T12:00:00Z\n' "$r" "$H" >> .vid/metrics-events; done
git -C .vid/code fetch -q
imp() { gh_ci "$C" "$1" 1 success CI "$2"; sh checks/github.sh pull --commit "$C" > /dev/null 2>&1; sh checks/ticket.sh import --main "$C" --stage 1 > "$T/out" 2>&1 || fail "the import of main's run $1 was refused"; }
# ROW-002 failing in the run: not ready
imp 401 "$T/red.xml"
sh checks/metrics.sh stage-close --stage 1 --ci "$C12.ci-401-1.xml" > "$T/out" 2>&1
grep -q '^unmet ROW-002: not green in the CI run' "$T/out" && grep -q '^stage-close 1 unmet=' "$T/out" || fail 'a failing ROW did not hold the close'
# the good run
: > "$T/gh/runs"; imp 400 "$T/green.xml"; R=$C12.ci-400-1.xml
grep -q "^ledger-run type=ci report=$R .* pr=- stage=1 " .vid/metrics-events || fail "main's run was not published for the stage"
# ViD's copy changed at that commit: not ready
printf '# a later correction\n' >> tests/invariants/test_b.py; g commit -qam 'a correction in ViD'"'"'s copy'
sh checks/metrics.sh stage-close --stage 1 --ci "$R" > "$T/out" 2>&1
grep -q "^unmet ROW-002: ViD's copy tests/invariants/test_b.py changed at $C12" "$T/out" || fail 'a changed copy did not hold the close'
g revert --no-edit HEAD > /dev/null 2>&1 || git -c user.email=v@s -c user.name=v revert --no-edit HEAD > /dev/null
sh checks/metrics.sh stage-close --stage 1 --ci "$R" > "$T/out" 2>&1
grep -q "^stage-close 1 ready rows=3 debt=3 source=ci run=400 commit=$C12$" "$T/out" || fail 'the stage is not ready'
grep -q '^debt RULE-001: rule row' "$T/out" && grep -q '^debt HOS-002: hostility probe' "$T/out" && grep -q '^debt ROW-007 gate 1' "$T/out" || fail 'the debt is not listed by name'
grep -qx 'not checked in ticket mode: the census' "$T/out" && grep -qx "not checked in ticket mode: coverage's REQ-citation and design-marker joins" "$T/out" || fail 'what is not checked is not said'
grep -q 'REQ-002' "$T/out" && fail 'the uncited requirement was judged'
sh checks/metrics.sh stage-close --stage 1 --ci "$R" --record > "$T/out" 2>&1
grep -q "^stage-closed n=1 sha=$C12 source=ci run=400 rows=3 debt=3 at=" .vid/metrics-events || fail 'no stage-closed source=ci'
grep -q '^stage-closed .* ready' .vid/metrics-events && fail "the ticket-mode close carries develop's ready token"
git rev-parse -q --verify refs/tags/vid/stage-1 > /dev/null && fail 'a tag was made'
grep -qx 'stage: 2' .vid/RUN-STATE.md || fail 'stage: is not 2'
grep -q '^## stage 1 ' .vid/SLICE-REPORTS.md && grep -q '^  - HOS-002: hostility probe' .vid/SLICE-REPORTS.md || fail 'the stage report lacks its debt'
exit 0
