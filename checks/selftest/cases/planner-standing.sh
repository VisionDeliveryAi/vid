#!/bin/sh
# Purpose: selftest case — the four standing lines, P5 (v0.26.10.12.2.1 R6). On the planner's
# toy (fixtures/planner-toy.sh) `standing rehearsal` names the gate-1 row ROW-009, `standing fields` and `standing work`
# name ViD's appended census rules RULE-004 and RULE-005, and `standing sign-in` says none: and why: no flag. With the gate-1 row removed
# (pt_nogate1), the line names no planned row and no row is owed to the rehearsal, both flagged, until PL appends the
# rehearsal row ($PT_REH); a missing line, an empty one, an unknown kind, a none: with no why, and a none: for rehearsal while the
# PRD keeps data (REQ-005, a data_entity item) are flagged; with REQ-005 made a later-phase item, the rehearsal's none:
# is not. The page shows every line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-standing: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
fresh; pt_check; grep -q '^standing ' "$T/out" && fail 'the toy with its four standing lines is flagged'
fresh; pt_nogate1; pt_check; pt_has 'standing rehearsal — ROW-009 is no planned row'
pt_has 'standing rehearsal — the product keeps data (REQ-005) and no row is owed to the rehearsal'
pt_after HOS-005 "$PT_REH"; pt_set 'standing rehearsal' 'standing rehearsal | ROW-021'; pt_rs 's/^\(step S04 .*\) RULE-004 /\1 RULE-004 ROW-021 /'
pt_after 'step S05' 'needs ROW-021 | -'; pt_check; [ "$PT_RC" -eq 0 ] || fail 'the plan with ViD'"'"'s rehearsal row is flagged'
pt_set 'standing rehearsal' 'standing rehearsal | ROW-009'; pt_check; pt_has 'form ROW-021 — an origin: plan deploy-paid row no standing line names'
fresh; pt_del 'standing work'; pt_check; pt_has 'standing work — no `standing work` line'
fresh; pt_set 'standing fields' 'standing fields |'; pt_check; pt_has 'standing fields — the line names no planned row'
fresh; pt_set 'standing fields' 'standing fields | ROW-099'; pt_check; pt_has 'standing fields — ROW-099 is no planned row'
fresh; pt_after 'standing work' 'standing money | none: no payments'; pt_check; pt_has 'form "standing money" — no standing kind'
fresh; pt_set 'standing sign-in' 'standing sign-in | none:'; pt_check; pt_has 'standing sign-in — none: says no why'
fresh; pt_set 'standing rehearsal' 'standing rehearsal | none: nothing to move'; pt_check; pt_has 'standing rehearsal — none:, but the product keeps data (REQ-005)'
sed 's/^\(REQ-005 | data_entity .*\)| phase: pilot |/\1| phase: later |/' PRD.md > P.x && mv P.x PRD.md; pt_check; grep -q '^standing rehearsal' "$T/out" && fail 'a later-phase data item asks for a rehearsal row'
fresh; sh "$CHECKS/planner.sh" page > /dev/null 2>&1 || fail 'page failed'
for l in '- **rehearsal:** ROW-009' '- **sign-in:** none: subscribers never sign in' '- **fields:** RULE-004' '- **work:** RULE-005'; do grep -qF -- "$l" .vid/plan/PLAN-PAGE.md || fail "the page lacks: $l"; done
exit 0
