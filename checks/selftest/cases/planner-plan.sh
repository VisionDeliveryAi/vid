#!/bin/sh
# Purpose: selftest case — the plan in develop's form, held to ticket mode, P4, P10 and P12 (v0.26.10.12.2.2
# R1, R3–R5; it replaces planner-steps). On the planner's toy (fixtures/planner-toy.sh: RUN-STATE's
# plan block, ARCHITECTURE.md's five modules) the good plan gives no flag, and nor does one where no step but the
# skeleton builds on anything. R1: an id that is no planned row (in rows: or protected:), a transition, a lane but
# devagent, a module or a shared: token not in ARCHITECTURE.md's table, no shared: line, no name or modules, an
# unknown field, a range of two prefixes, a row in two steps, a builds-on naming no step or a later one; `shared: -`
# passes. R3: a vid-steps block left in PLAN.md, a line of the block that does not parse. R4: no skeleton, two; with a
# STAGE-0 the skeleton holds exactly stage 0's rows (one missing, one more, building on a step, a stage-0 row owed to
# staging, a second step in stage 0); with none, one stage-1 row (two, none, a stage-2 row, a seam); a step across
# stages, or building on a step of a later stage. R5: at a budget of 3, a step over it is flagged `size`, one at it
# (S06, three rows) and the skeleton (ROW-003 and the journey ROW-004, counted once) are not; at 60 none is. A tab
# between ids passes, as plan.sh takes it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-plan: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
st() { pt_set "step $1" "step $1 | name: a step | modules: ${5:-web} | builds-on: $3 | rows: $2 | lane: devagent${4:+ | kind: $4}"; }
rs() { sed "$1" .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x; }
S2='ROW-001 ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 SEAM-002 DIF-002 RULE-005'
clean() { pt_check; [ "$PT_RC" -eq 0 ] || fail "$1 is flagged"; }
fresh; clean 'the good plan'; grep -qx 'planner: clean — 35 rows, 5 steps' "$T/out" || fail 'the clean line is not the toy'"'"'s'
fresh; st S04 'ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004' - '' 'digest ingest'; st S05 ROW-017 - '' search; st S02 "$S2" -; st S03 'ROW-006 ROW-007 ROW-010 ROW-014 ROW-019 RULE-001..RULE-003 HOS-002 HOS-004 SEAM-001 HOS-005' -
clean 'a plan where no step but the skeleton builds on anything'
# R1: the block held to ticket mode
fresh; st S05 'ROW-017 RULE-099' S02 '' search; pt_check; pt_has 'step S05 — RULE-099 is no planned row'
fresh; st S05 'ROW-017 ROW-004-T1' S02 '' search; pt_check; pt_has 'step S05 — ROW-004-T1 is no planned row'
fresh; pt_after 'step S05' 'protected: HOS-001 ROW-005-T2'; pt_check; pt_has 'step protected: — ROW-005-T2 is no planned row'
fresh; pt_after 'step S05' 'protected: HOS-001 HOS-002..HOS-004'; clean 'a protected: line of planned rows and a range'
fresh; rs 's/^\(step S02 .*\)| lane: devagent$/\1| lane: builder/'; pt_check; pt_has 'lane S02 — lane builder is no lane of the setup (devagent)'
fresh; rs 's/^\(step S02 .*\)| lane: devagent$/\1/'; clean 'a step with no lane'
fresh; rs 's/^\(step S02 .*modules: \)ingest digest/\1ingest billing/'; pt_check; pt_has 'module S02 — billing is no module of ARCHITECTURE.md'
fresh; rs 's/^shared: web$/shared: web billing/'; pt_check; pt_has 'module shared — billing is no module of ARCHITECTURE.md'
fresh; rs 's/^shared: web$/shared: -/'; clean 'shared: -'
fresh; rs '/^shared: /d'; pt_check; pt_has 'form shared: — the plan block has no shared: line'
fresh; rs 's/^\(step S02 \)| name: [^|]*/\1/'; pt_check; pt_has 'form S02 — no name:'
fresh; rs 's/^\(step S02 .*\)| modules: [^|]*/\1/'; pt_check; pt_has 'form S02 — no modules:'
fresh; rs 's/^\(step S02 .*\)$/\1 | owner: the team/'; pt_check; pt_has 'form S02 — an unknown field "owner"'
fresh; rs 's/RULE-001\.\.RULE-003/RULE-001..HOS-003/'; pt_check; pt_has 'form S03 — the range RULE-001..HOS-003 is of two prefixes'
fresh; st S03 'ROW-001 ROW-006 ROW-007 ROW-010 ROW-014 ROW-019 RULE-001..RULE-003 HOS-002 HOS-004 SEAM-001 HOS-005' S01 '' 'web mail'; pt_check; pt_has 'step ROW-001 — in two steps, S02 and S03'
fresh; st S02 "$S2" S03 '' 'ingest digest'; pt_check; pt_has 'step S02 — builds on S03, a later step'
fresh; st S05 ROW-017 S09 '' search; pt_check; pt_has 'step S05 — builds on S09, which is no step'
fresh; rs 's/builds-on: S02 S03 | rows: ROW-002 ROW-009/builds-on: S02	S03 | rows: ROW-002	ROW-009/'; grep -q "$(printf 'S02	S03')" .vid/RUN-STATE.md || fail 'the tab was not planted'
clean 'a block with tabs between ids'
# R3: the steps live in RUN-STATE
fresh; printf '\n## Steps\n\n```vid-steps\nstep S01 | name: a | rows: ROW-003 | builds-on: -\n```\n' >> PLAN.md; pt_check; pt_has 'form PLAN.md — a vid-steps block'
fresh; rs 's/^shared: web$/shared: web\nthe skeleton first/'; pt_check; pt_has 'form "the skeleton first" — a line of the plan block that is no step'
# R4: the skeleton and the stages
fresh; rs 's/ | kind: skeleton$//'; pt_check; pt_has 'skeleton - — no step is kind: skeleton'
fresh; rs 's/^\(step S05 .*\)$/\1 | kind: skeleton/'; pt_check; pt_has 'skeleton S05 — a second step of kind: skeleton'
fresh; st S01 ROW-004 - skeleton 'web digest'; st S02 "ROW-003 $S2" S01 '' 'ingest digest'; pt_check; pt_has 'skeleton S01 — lacks ROW-003, a row of stage 0'
fresh; st S01 'ROW-003 ROW-004 ROW-001' - skeleton 'web digest'; st S02 "ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 SEAM-002 DIF-002 RULE-005" S01 '' 'ingest digest'; pt_check
pt_has 'skeleton S01 — holds ROW-001, which is no row of stage 0'
fresh; st S01 'ROW-003 ROW-004' S02 skeleton 'web digest'; pt_check; pt_has 'skeleton S01 — builds on S02; the skeleton builds on nothing'
fresh; pt_set ROW-003 'ROW-003 | surface | S01 | anonymous | S01/saved | The saved state shows on staging. | REQ-001, S01/saved | owed: paid by /vid deploy gate 2 — staging | origin: design'
pt_check; pt_has 'skeleton S01 — its row ROW-003 is deploy-owed or a seam'
fresh; st S01 ROW-004 - skeleton 'web digest'; pt_after 'step S01' 'step S06 | name: the saved page | modules: web | builds-on: S01 | rows: ROW-003 | lane: devagent'; pt_check; pt_has 'skeleton S06 — is in stage 0'
fresh; pt_nostage0; clean 'the toy with no stage 0'
fresh; pt_nostage0; st S01 'ROW-004 ROW-001' - skeleton 'web digest'; st S02 "ROW-003 ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 SEAM-002 DIF-002 RULE-005" S01 '' 'ingest digest'; pt_check; pt_has 'skeleton S01 — holds 2 rows'
fresh; pt_nostage0; st S01 - - skeleton 'web digest'; st S02 "ROW-004 ROW-003 $S2" S01 '' 'ingest digest'; pt_check; pt_has 'skeleton S01 — holds 0 rows'
fresh; pt_nostage0; st S01 ROW-017 - skeleton search; st S05 ROW-004 S02 '' 'web digest'; pt_check; pt_has 'skeleton S01 — its row ROW-017 is in stage 2, not stage 1'
fresh; pt_nostage0; st S01 SEAM-002 - skeleton mail; st S02 "ROW-004 ROW-003 ROW-001 ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 DIF-002 RULE-005" S01 '' 'ingest digest'; pt_check
pt_has 'skeleton S01 — its row SEAM-002 is deploy-owed or a seam'
fresh; st S04 'ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004' 'S02 S03' '' 'digest ingest'; st S05 'ROW-017 ROW-002' S02 '' search; pt_check; pt_has 'step S05 — its rows are in stages 2 and 1'
fresh; pt_del 'step S05'; pt_after 'step S03' 'step S05 | name: synonyms | modules: search | builds-on: S02 | rows: ROW-017 | lane: devagent'; st S04 'ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004' 'S03 S05' '' 'digest ingest'
pt_check; pt_has 'step S04 — builds on S05, a step of a later stage'
# R5: rule A's ceiling
fresh; printf 'unverified-rows=3\n' > .vid/budget; st S04 'ROW-009 HOS-003 DIF-001 RULE-004' 'S02 S03' '' 'digest ingest'
pt_after 'step S04' 'step S06 | name: the cap and the log | modules: digest | builds-on: S02 | rows: ROW-002 ROW-011 ROW-018 | lane: devagent'; pt_check
pt_has 'size S02 — 11 rows, over the ceiling of 3; split it'; pt_has 'size S04 — 4 rows, over the ceiling of 3'
grep -q '^size S06 ' "$T/out" && fail 'a step at the ceiling is flagged'
grep -q '^size S01 ' "$T/out" && fail 'the skeleton, under the ceiling with a journey counted once, is flagged'
grep -q '^size S05 ' "$T/out" && fail 'a step under the ceiling is flagged'
fresh; printf 'unverified-rows=100\n' > .vid/budget; clean 'an unrecorded raise (read as 60)'
exit 0
