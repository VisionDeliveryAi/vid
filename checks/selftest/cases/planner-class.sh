#!/bin/sh
# Purpose: selftest case — every row has one class, P3 (v0.26.10.12.2.1 R4). On the planner's
# toy (fixtures/planner-toy.sh): a row in no step but a known limit, a later-phase row or a record; a known limit in a
# step; a moved: to its own stage, to an earlier one and to a missing one; an unknown A-NNN on moved: and on limit:; a
# row with both; a limit: or a moved: left empty; a class line on a record or a later-phase row — each flagged, by a
# class line, on an inventory row or on one ViD added. Not flagged: a known limit in no step; a row moved to stage 2 sitting in a stage-2 step; a
# stage-0 row moved to stage 1, leaving the skeleton. The page shows each class. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-class: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
cl() { pt_after 'standing work' "$1"; }
S4='step S04 | name: limits | modules: digest ingest | builds-on: S02 S03 | rows: ROW-002 ROW-009 ROW-011 HOS-003 DIF-001 RULE-004 | lane: devagent'
s4() { pt_set 'step S04' "$S4"; pt_rs '/^needs /s/ ROW-018 / /'; }   # ROW-018 out of S04, and out of its needs line (R10)
fresh; pt_check; grep -qE '^(class|moved|answer) ' "$T/out" && fail 'the good plan has a class flag'
fresh; s4; pt_check; pt_has 'class ROW-018 — in no step, and no known limit'
fresh; cl 'ROW-018 | limit: A-005'; pt_check; pt_has 'class ROW-018 — a known limit, in step S04'
fresh; cl 'ROW-018 | limit: A-005'; s4; pt_check; [ "$PT_RC" -eq 0 ] || fail 'a known limit in no step is flagged'
fresh; cl 'ROW-002 | moved: STAGE-1 A-005'; pt_check; pt_has "moved ROW-002 — STAGE-1 is not later than its stage 1"
fresh; cl 'ROW-017 | moved: STAGE-1 A-002'; pt_check; pt_has 'moved ROW-017 — STAGE-1 is not later'
fresh; cl 'ROW-002 | moved: STAGE-3 A-005'; pt_check; pt_has 'moved ROW-002 — STAGE-3 is no stage'
fresh; cl 'ROW-002 | moved: STAGE-2 A-099'; pt_check; pt_has 'answer ROW-002 — A-099 is no answer of PRD.md'
fresh; cl 'ROW-018 | limit: A-099'; s4; pt_check; pt_has 'answer ROW-018 — A-099 is no answer of PRD.md'
fresh; cl 'ROW-018 | moved: STAGE-2 A-005 | limit: A-005'; s4; pt_check; pt_has 'class ROW-018 — both moved: and limit:'
fresh; cl 'ROW-018 | limit:'; s4; pt_check; pt_has 'form ROW-018 — limit: names no answer'
fresh; cl 'ROW-002 | moved:'; pt_check; pt_has 'form ROW-002 — moved: names no stage and answer'
fresh; cl 'RULE-004 | limit: A-005'; pt_check; pt_has 'class RULE-004 — a known limit, in step S04'
fresh; cl 'DIF-003 | limit: A-005'; pt_check; pt_has 'class DIF-003 — a record sits in no stage'
fresh; cl 'ROW-020 | moved: STAGE-2 A-005'; pt_check; pt_has 'class ROW-020 — a later-phase row; only an amendment'
# a row moved to stage 2, in a stage-2 step; a stage-0 row moved to stage 1 leaves the skeleton
fresh; cl 'ROW-002 | moved: STAGE-2 A-005'; pt_set 'step S04' 'step S04 | name: limits | modules: digest ingest | builds-on: S02 S03 | rows: ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004 | lane: devagent'
pt_set 'step S05' 'step S05 | name: synonyms and the cap | modules: search | builds-on: S02 | rows: ROW-017 ROW-002 | lane: devagent'; pt_check; [ "$PT_RC" -eq 0 ] || fail 'a row moved to stage 2, in a stage-2 step, is flagged'
fresh; cl 'ROW-003 | moved: STAGE-1 A-005'; pt_check; pt_has 'skeleton S01 — holds ROW-003, which is no row of stage 0'
pt_set 'step S01' 'step S01 | name: save a search | modules: web digest | builds-on: - | rows: ROW-004 | lane: devagent | kind: skeleton'; pt_set 'step S02' 'step S02 | name: new jobs | modules: ingest digest | builds-on: S01 | rows: ROW-003 ROW-001 ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 SEAM-002 DIF-002 RULE-005 | lane: devagent'
pt_check; [ "$PT_RC" -eq 0 ] || fail 'a stage-0 row moved to stage 1, out of the skeleton, is flagged'
# the page shows each class
fresh; cl 'ROW-018 | limit: A-005'; s4; sh "$CHECKS/planner.sh" page > /dev/null 2>&1 || fail 'page failed'; PG=.vid/plan/PLAN-PAGE.md
for c in 'ROW-018:known limit (A-005)' 'ROW-001:planned to stage 1' 'ROW-009:deploy-owed: rehearsal, in stage 1' 'DIF-003:record: deliberately not tested, in no step' 'ROW-020:later phase, in no step until an amendment brings it in' 'ROW-003:planned to stage 0'; do
  grep -F "| ${c%%:*} | " "$PG" | head -n 1 | grep -qF "| ${c#*:} |" || fail "${c%%:*}'s class is not shown: ${c#*:}"; done
exit 0
