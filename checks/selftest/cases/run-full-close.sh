#!/bin/sh
# Purpose: selftest case — the close reads only a full run ViD started (v0.26.10.12 spec R4, R9; fitted in 0.26.10.28.1,
# the first ticket mode's import and run-full removed: the receipts and the run-full started event are written as they
# wrote them, fixtures/tickets.sh tk_receipt). The stage-close-ci toy (fixtures/tickets.sh gh_vid; ROW-001 and ROW-002
# KEPT, their tests at main's last merge). Before run-full: is in the vid-code block, main's push run's receipt closes
# the stage as 0.26.10.11 did. With run-full: that receipt is refused by `stage-close --ci`, naming the missing run-full
# started event, and so is a pull request's scoped receipt, and nothing is recorded; a receipt of the run a `run-full
# started` event names at that commit closes it. Env: CHECKS.
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
H=$(git rev-parse HEAD)
for r in ROW-001 ROW-002; do printf 'verdict slice=1 row=%s result=KEPT class=product brief=.vid/briefs/1/grader-1.md quoted-at=%s at=2026-10-24T12:00:00Z\n' "$r" "$H" >> .vid/metrics-events; done
git -C .vid/code fetch -q
OK2='case tests/invariants/test_b.py::test_2[ROW-002] passed 0.1'; OK1='case tests/invariants/test_a.py::test_1[ROW-001] passed 0.1'
# main's push run, before run-full: (0.26.10.11's close)
tk_receipt "$C" 400 1 - 1 "$OK1" "$OK2"; R0=$RN
sh checks/metrics.sh stage-close --stage 1 --ci "$R0" > "$T/out" 2>&1; grep -q '^stage-close 1 ready ' "$T/out" || fail 'without run-full: the push run does not close the stage as before'
# a pull request's scoped receipt (pr=12)
tk_receipt "$C" 300 1 12 - "$OK1" "$OK2"; R3=$RN
awk '{ print } /^ci-workflow:/ { print "run-full: gh workflow run CI --ref main" }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md; g add -A && g commit -qm 'run-full'
for r in "$R0" "$R3"; do
  sh checks/metrics.sh stage-close --stage 1 --ci "$r" --record > "$T/out" 2>&1
  grep -q "^metrics stage-close: $r is not from a full run ViD started (no run-full started event names run" "$T/out" || fail "stage-close took $r, which no run-full started event binds"
  grep -q '^stage-closed ' .vid/metrics-events && fail "stage-close recorded a close from $r"
done
# the full run 901 ViD started, as the first mode recorded it
printf 'run-full started run=901 attempt=1 sha=%s at=2026-10-24T12:30:00Z\n' "$C12" >> .vid/metrics-events
tk_receipt "$C" 901 1 - 1 "$OK1" "$OK2"; R=$RN
sh checks/metrics.sh stage-close --stage 1 --ci "$R" > "$T/out" 2>&1
grep -q "^stage-close 1 ready rows=2 debt=2 source=ci run=901 commit=$C12$" "$T/out" || fail 'the full run does not close the stage'
exit 0
