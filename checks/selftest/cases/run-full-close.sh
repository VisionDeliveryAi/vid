#!/bin/sh
# Purpose: selftest case — the close reads only a full run ViD started (v0.26.10.12 spec R4, R9). The stage-close-ci
# toy (fixtures/tickets.sh gh_vid; ROW-001 and ROW-002 KEPT, their tests at main's last merge). Before run-full: is in
# the vid-code block, `import --main` publishes main's push run as 0.26.10.11 did. With run-full: that receipt is
# refused by `stage-close --ci`, naming the missing run-full started event, and so is a pull request's scoped receipt;
# `import --main` refuses main's push run (no run-full started event names the commit) and publishes nothing. Then
# `github.sh run-full` (the fake gh's manual run 901 of main's tip): pulled while queued, import refuses it as not
# complete; completed with its report, and a later push run of the same commit beside it, import binds to run 901
# alone; stage-close --ci on that receipt is ready. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "run-full-close: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"; cp "$CHECKS/metrics.sh" checks/
sed -e 's#^\(rule | RULE-001 | .*| \)tests/invariants/test_rule.py$#\1owed: census-armed — no site yet#' \
    -e 's#^\(hostility | HOS-002 | .*| \)tests/invariants/test_hos2.py$#\1owed: guard-first — the password guard; paid in the slice that builds it#' INVENTORY.md > I.x && mv I.x INVENTORY.md
awk '/^labels-prefix:/ { print; print "ci-workflow: CI"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
g add -A && g commit -qm 'ticket-mode rows'
tk_dev 'Merge pull request #7' tests/invariants/test_a.py "$(cat tests/invariants/test_a.py)" tests/invariants/test_b.py "$(cat tests/invariants/test_b.py)" app/login/main.py 'sign in'
C=$(git -C "$T/code.git" rev-parse main); C12=$(printf '%s' "$C" | cut -c1-12)
printf '<testsuites><testsuite name="t">\n  <testcase classname="tests/invariants/test_a.py" name="test_1[ROW-001]" time="0.1"/>\n  <testcase classname="tests/invariants/test_b.py" name="test_2[ROW-002]" time="0.1"/>\n</testsuite></testsuites>\n' > "$T/green.xml"
H=$(git rev-parse HEAD)
for r in ROW-001 ROW-002; do printf 'verdict slice=1 row=%s result=KEPT class=product brief=.vid/briefs/1/grader-1.md quoted-at=%s at=2026-10-24T12:00:00Z\n' "$r" "$H" >> .vid/metrics-events; done
git -C .vid/code fetch -q
# main's push run, imported before run-full: (0.26.10.11's close)
gh_ci "$C" 400 1 success CI "$T/green.xml"; sh checks/github.sh pull --commit "$C" > /dev/null 2>&1
sh checks/ticket.sh import --main "$C" --stage 1 > "$T/out" 2>&1 || fail "main's push run was refused without run-full:"
R0=$C12.ci-400-1.xml; [ -f ".vid/ledger-results/$R0" ] || fail 'no receipt of the push run'
sh checks/metrics.sh stage-close --stage 1 --ci "$R0" > "$T/out" 2>&1; grep -q '^stage-close 1 ready ' "$T/out" || fail 'without run-full: the push run does not close the stage as before'
# a pull request's scoped receipt (pr=12)
cp ".vid/ledger-results/$R0" ".vid/ledger-results/$C12.ci-300-1.xml"; cp ".vid/ledger-results/$R0.cases" ".vid/ledger-results/$C12.ci-300-1.xml.cases"; cp ".vid/ledger-results/$R0.rows" ".vid/ledger-results/$C12.ci-300-1.xml.rows"
printf 'ledger-run type=ci report=%s.ci-300-1.xml repo=owner/code workflow=CI run=300 attempt=1 commit=%s pr=12 status=0 at=2026-10-24T12:00:00Z\n' "$C12" "$C12" >> .vid/metrics-events
awk '{ print } /^ci-workflow:/ { print "run-full: gh workflow run CI --ref main" }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A && g commit -qm 'run-full'
for r in "$R0" "$C12.ci-300-1.xml"; do
  sh checks/metrics.sh stage-close --stage 1 --ci "$r" --record > "$T/out" 2>&1
  grep -q "^metrics stage-close: $r is not from a full run ViD started (no run-full started event names run" "$T/out" || fail "stage-close took $r, which no run-full started event binds"
  grep -q '^stage-closed ' .vid/metrics-events && fail "stage-close recorded a close from $r"
done
N0=$(ls .vid/ledger-results | grep -c .)
if sh checks/ticket.sh import --main "$C" --stage 1 > "$T/out" 2>&1; then fail "import --main took main's push run with run-full: in the block"; fi
grep -q 'no full run ViD started tested' "$T/out" && [ "$(ls .vid/ledger-results | grep -c .)" = "$N0" ] || fail 'the refusal of an unbound run is wrong, or it published'
# the full run: queued, then complete, a later push run beside it
mkdir -p .vid/tickets/pr-7; printf 'number=7 ticket=1 state=merged draft=false head=%s merge=%s branch=vid/1\n' "$C" "$C" > .vid/tickets/pr-7/meta
printf 'ticket number=1 step=- kind=skeleton brief=.vid/tickets/skeleton.md parts=1 hash=x\n' >> .vid/tickets/map
sh checks/github.sh run-full > "$T/out" 2>&1 || fail 'run-full was refused'
grep -q "^run-full started run=901 attempt=1 sha=$C12 " .vid/metrics-events || fail 'the full run 901 is not recorded'
sh checks/github.sh pull --commit "$C" > /dev/null 2>&1
if sh checks/ticket.sh import --main "$C" --stage 1 > "$T/out" 2>&1; then fail 'a queued full run was imported'; fi
grep -q 'the full run 901 is not complete (status=queued)' "$T/out" || fail 'the refusal of a queued run does not say so'
sed "s/^901 1 \([0-9a-f]*\) CI workflow_dispatch queued -$/901 1 \1 CI workflow_dispatch completed success/" "$T/gh/runs" > "$T/r" && mv "$T/r" "$T/gh/runs"
mkdir -p "$T/gh/artifacts/901/vid-junit-1"; cp "$T/green.xml" "$T/gh/artifacts/901/vid-junit-1/report.xml"
gh_ci "$C" 950 1 success CI "$T/green.xml"
sh checks/github.sh pull --commit "$C" > /dev/null 2>&1
sh checks/ticket.sh import --main "$C" --stage 1 > "$T/out" 2>&1 || fail 'the completed full run was refused'
R=$C12.ci-901-1.xml; [ -f ".vid/ledger-results/$R" ] || fail 'the full run was not the receipt'
[ -f ".vid/ledger-results/$C12.ci-950-1.xml" ] && fail 'the later push run was read'
sh checks/metrics.sh stage-close --stage 1 --ci "$R" > "$T/out" 2>&1
grep -q "^stage-close 1 ready rows=2 debt=2 source=ci run=901 commit=$C12$" "$T/out" || fail 'the full run does not close the stage'
exit 0
