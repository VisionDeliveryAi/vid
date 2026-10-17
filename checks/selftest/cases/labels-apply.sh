#!/bin/sh
# Purpose: selftest case — the labels applied, with no question to the owner (v0.9.7.3 spec 3.3, R3; the owner,
# 2026-10-14). Under the real hooks: `decisions.sh apply` writes each sure label after the line's enforced: field
# (before origin:), in one commit of DECISIONS.md alone that both hooks accept — D-005's enforced: ref names a ledger
# test that does not exist, judged only by the label rule — keeps the record .vid/decision-labels.applied, and records
# `decision-labels applied= widened= changed= skipped=`. With anything else staged it is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/labels.sh"
fail() { echo "labels-apply: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
lb_files; g add -A && g commit -qm toy; lb_hooks
H0=$(git rev-parse HEAD)
lb_prop "D-002 $(lb_hash D-002) | applies-to: RULE-001 | sure" "D-003 $(lb_hash D-003) | scope: project | sure" \
  "D-005 $(lb_hash D-005) | applies-to: ROW-002 | sure" "D-006 $(lb_hash D-006) | applies-to: LOGIN | sure"
printf 'x\n' >> app/x.txt; g add app/x.txt
if sh checks/decisions.sh apply > .vid/out 2>&1; then fail 'apply committed with another file staged'; fi
grep -q 'other changes are staged (app/x.txt)' .vid/out || fail 'the refusal does not name the staged file'
g reset -q app/x.txt; git checkout -q app/x.txt
sh checks/decisions.sh apply > .vid/out 2>&1 || fail 'apply was refused'
[ "$(git rev-list --count "$H0..HEAD")" = 1 ] || fail 'not one commit'
[ "$(git diff --name-only "$H0" HEAD)" = DECISIONS.md ] || fail 'the commit touches more than DECISIONS.md'
grep -qxF -- '- **D-002** sessions last a day | why: load | enforced: convention | applies-to: RULE-001' DECISIONS.md || fail 'D-002 not labelled after enforced:'
grep -qxF -- '- **D-003** one font everywhere | why: brand | enforced: convention | scope: project' DECISIONS.md || fail 'D-003 not labelled'
grep -qxF -- '- **D-005** tokens are eight characters | why: enough | enforced: tests/invariants/test_gone.py | applies-to: ROW-002' DECISIONS.md || fail 'D-005 not labelled'
grep -qxF -- '- **D-006** prices in minor units | why: exactness | enforced: convention | applies-to: LOGIN | origin: proposal' DECISIONS.md || fail 'D-006 not labelled before origin:'
grep -qxF -- '- **D-001** ROW-001 shows one form | why: x | enforced: convention' DECISIONS.md || fail 'D-001, not proposed, was labelled'
git status --porcelain DECISIONS.md | grep -q . && fail 'DECISIONS.md is not committed'
[ "$(grep -c . .vid/decision-labels.applied)" = 4 ] && grep -q "^D-002	applies-to: RULE-001	sure$" .vid/decision-labels.applied || fail 'the record is not one line per label written'
grep -q '^decision-labels applied=4 widened=0 changed=0 skipped=0 at=' .vid/metrics-events || fail 'the event is not recorded with its counts'
exit 0
