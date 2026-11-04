#!/bin/sh
# Purpose: selftest case — protection rows, P2 (v0.26.10.12.2.1 R3). On the planner's toy
# (fixtures/planner-toy.sh) INV-001 is protected by a hostility row and INV-002 by ViD's appended HOS-005: nothing is flagged.
# `protection <item>` is flagged with HOS-005 deleted or protecting another item, and with HOS-001 deleted — unless another hostility row
# protects INV-001 through a row (ROW-013) or a rule (RULE-001 given origin INV-001); an origin: plan hostility row duplicating one
# is flagged; a T0 requirement (REQ-011 made T0 in PRD.md) is flagged until ViD appends its hostility row.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-protection: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
nop() { grep -q "^protection $1" "$T/out" && fail "$1 is flagged"; return 0; }
P='promise: a promise | fail-if: a fail-if'
fresh; pt_check; grep -q '^protection ' "$T/out" && fail 'an item with a protection row is flagged'
fresh; pt_del HOS-005; pt_check; pt_has 'protection INV-002 — a must-never-happen item with no protection row'; nop INV-001
fresh; pt_set HOS-005 'hostility | HOS-005 | Send an address out | protects: INV-001 | disable: the guard that protects INV-001 | owed: spec-only — ticket | origin: plan INV-002'; pt_check; pt_has 'protection INV-002'
fresh; pt_del HOS-001; pt_check; pt_has 'protection INV-001'
fresh; pt_del HOS-001; pt_set HOS-003 'hostility | HOS-003 | Read one feed twice; expect no new listing | protects: ROW-013 | disable: skip the merge | owed: guard-first — later'; pt_check; nop INV-001
fresh; pt_del HOS-001; pt_set RULE-001 'rule | RULE-001 | Every digest carries the support address | sites: every digest template | 1 | owed: census-armed — later | origin: INV-001'; pt_check; nop INV-001
fresh; pt_after HOS-005 'hostility | HOS-006 | Send the same job twice | protects: INV-001 | disable: the guard that protects INV-001 | owed: spec-only — ticket | origin: plan INV-001'
pt_check; pt_has 'protection HOS-006 — INV-001 already has a protection row, HOS-001'
fresh; sed 's/^REQ-011 | nfr | T2 |/REQ-011 | nfr | T0 |/' PRD.md > P.x && mv P.x PRD.md; pt_check; pt_has 'protection REQ-011'
pt_after HOS-005 'hostility | HOS-006 | Make a digest fail to send and clear the log | protects: REQ-011 | disable: the guard that protects REQ-011 | owed: spec-only — ticket | origin: plan REQ-011'; pt_rs 's/^\(step S04 .*\) RULE-004 /\1 RULE-004 HOS-006 /'
pt_after 'step S05' 'needs HOS-006 | -'; pt_check; grep -q '^protection ' "$T/out" && fail 'REQ-011 with its protection row is still flagged'; [ "$PT_RC" -eq 0 ] || fail 'the plan with HOS-006 is flagged'
exit 0
