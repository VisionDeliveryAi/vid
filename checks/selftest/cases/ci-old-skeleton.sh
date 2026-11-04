#!/bin/sh
# Purpose: selftest case — a project whose skeleton is already merged (v0.26.10.12 spec R8, R9). The planner's toy
# (fixtures/tickets.sh gh_vid) whose vid-code block holds the five test facts and no run-full:, main's last merge with
# its push run: a ticket written now carries no CI scope; `github.sh run-full` is refused; `import --main` reads main's
# push run and `stage-close --ci` takes its receipt, as 0.26.10.11 did. The offered fix: `skeleton-body --missing "the
# CI runs a ticket's scope on pull requests and every test only on a manual start (R1)"` writes a skeleton fix ticket
# (kind skeleton, the missing line in its section 8) that asks for the new CI and the run-full line, so return-check
# requires `skeleton: run-full:` of its block. vid-replan names the older skeleton, the offer once, and 0.26.10.11's
# close. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "ci-old-skeleton: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"; cp "$CHECKS/metrics.sh" checks/
awk '/^labels-prefix:/ { print; print "test-framework: the toy runner"; print "test-dir: tests/invariants"; print "run-one: sh tests/run.sh <names>"; print "ci-workflow: CI"; print "report: vid-junit-<run attempt>"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
sed -e 's#^\(rule | RULE-001 | .*| \)tests/invariants/test_rule.py$#\1owed: census-armed — no site yet#' \
    -e 's#^\(hostility | HOS-002 | .*| \)tests/invariants/test_hos2.py$#\1owed: guard-first — the password guard#' INVENTORY.md > I.x && mv I.x INVENTORY.md
printf '\n## Placement rules\n\n- app/ only.\n\n## Ledger and docs laws\n\n- tests are law.\n\n## Import law\n\n- seams.\n\n## Law-change rule\n\n- standalone.\n' >> CLAUDE.md
printf '# Grading\n\n- reads well\n' > GRADING-CHECKLIST.md
g add -A && g commit -qm 'the test facts, an older skeleton'
. "$CHECKS/selftest/fixtures/brief-write.sh"; bw_plugin
sh checks/brief.sh write --role builder --slice 1 --step A --rows ROW-001 --selection tests/invariants/test_a.py --ticket > "$T/out" 2>&1 || fail 'the ticket was not written'
BR=$(sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1)
grep -q '^### CI scope' "$BR" && fail 'a ticket under an older skeleton carries a CI scope'
grep -q '^ci-scope:' "$BR" && fail 'a ticket under an older skeleton carries a ci-scope: line'
if sh checks/github.sh run-full > "$T/out" 2>&1; then fail 'run-full ran under an older skeleton'; fi
grep -q 'names no run-full:' "$T/out" || fail 'the run-full refusal does not name run-full:'
# the stage close from main's push run, as 0.26.10.11
tk_dev 'stage 1 merged' tests/invariants/test_a.py "$(cat tests/invariants/test_a.py)" tests/invariants/test_b.py "$(cat tests/invariants/test_b.py)"
C=$(git -C "$T/code.git" rev-parse main); C12=$(printf '%s' "$C" | cut -c1-12)
printf '<testsuites><testsuite name="t">\n  <testcase classname="tests/invariants/test_a.py" name="test_1[ROW-001]" time="0.1"/>\n  <testcase classname="tests/invariants/test_b.py" name="test_2[ROW-002]" time="0.1"/>\n</testsuite></testsuites>\n' > "$T/green.xml"
H=$(git rev-parse HEAD); for r in ROW-001 ROW-002; do printf 'verdict slice=1 row=%s result=KEPT class=product brief=x quoted-at=%s at=2026-10-24T12:00:00Z\n' "$r" "$H" >> .vid/metrics-events; done
git -C .vid/code fetch -q; gh_ci "$C" 400 1 success CI "$T/green.xml"; sh checks/github.sh pull --commit "$C" > /dev/null 2>&1
sh checks/ticket.sh import --main "$C" --stage 1 > "$T/out" 2>&1 || fail "main's push run was refused under an older skeleton"
sh checks/metrics.sh stage-close --stage 1 --ci "$C12.ci-400-1.xml" > "$T/out" 2>&1
grep -q "^stage-close 1 ready .* run=400 commit=$C12$" "$T/out" || fail 'the push run does not close the stage under an older skeleton'
# the offered skeleton fix ticket
MS="the CI runs a ticket's scope on pull requests and every test only on a manual start (R1)"
sh checks/ticket.sh skeleton-body --req REQ-001 --missing "$MS" --out .vid/tickets/skeleton-fix-1.md > "$T/out" 2>&1 || fail 'the skeleton fix ticket was not written'
SF=.vid/tickets/skeleton-fix-1.md
grep -qx 'kind: skeleton' "$SF" && grep -qxF "fix: $MS" "$SF" || fail 'the fix ticket is not a skeleton fix naming what is missing'
sed -n '/^## 8 what is missing/,/^## 9/p' "$SF" | grep -qxF "$MS" || fail 'section 8 does not name what is missing'
grep -q 'runs nothing on a push to main' "$SF" && grep -qx 'skeleton: run-full: <how the full run is started>' "$SF" || fail 'the fix ticket does not ask for the new CI and the run-full line'
printf 'Fix.\n\n```vid-return\nticket: #9\nrows: none\nskeleton: test-framework: t\nskeleton: test-dir: tests/x\nskeleton: run-one: r\nskeleton: ci-workflow: CI\nskeleton: report: vid-junit-<run attempt>\ndecisions:\n  - none\ndiscovered:\n  - none\nlaw-needed:\n  - none\nquestions:\n  - none\n```\n' > "$T/b.md"
if sh checks/ticket.sh return-check "$T/b.md" --ticket "$SF" > "$T/out" 2>&1; then fail "the fix ticket's block passed without run-full"; fi
# the skill — only in the plugin repository (a project has checks/ alone)
[ -f "$CHECKS/../skills/vid-replan/SKILL.md" ] || exit 0
R=$(tr '\n' ' ' < "$CHECKS/../skills/vid-replan/SKILL.md" | tr -s ' ')
printf '%s' "$R" | grep -qF '**An older skeleton (v0.26.10.12 R8).** When the vid-code block holds the test facts but no `run-full:`' || fail 'vid-replan does not name an older skeleton'
printf '%s' "$R" | grep -qF -- "--missing \"$MS\"" || fail 'vid-replan does not offer the skeleton fix ticket with the missing line'
printf '%s' "$R" | grep -qF 'say so once' && printf '%s' "$R" | grep -qF "published at the owner's yes" || fail 'vid-replan does not say it once, published at the owner'"'"'s yes'
printf '%s' "$R" | grep -qF 'ViD behaves as 0.26.10.11: tickets carry no CI scope, import checks every row of the ticket, and the stage close reads main'"'"'s run at the stage'"'"'s last merge' || fail 'vid-replan does not keep 0.26.10.11 until the fix merges'
exit 0
