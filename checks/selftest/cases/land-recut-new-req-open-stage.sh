#!/bin/sh
# Purpose: selftest case — a ticket re-cut that adds a requirement to a closed stage's feature and splits it to an open
# stage changes the open stage alone (0.26.10.29.4, phase 4 R5): checks/land.sh reads the base cut over the base's
# PRD.md and INVENTORY.md and the draft cut over the draft's. On the writer's toy, stage 1 (FEAT-01, FEAT-03) closed and
# stage 2 (FEAT-02) open, a draft adding REQ-013 to FEAT-01 with `split: REQ-013 -> STAGE-2`, its row ROW-021 in the
# stage-2 step S05, and the owner's answer, is drafted (draft 1); a re-cut moving stage 1's existing REQ-006 to stage 2
# is still refused, naming stage 1 closed, and is made no draft. On the record too: a re-cut adding a census rule row
# RULE-006 with no row: line (no rules: line in the cut, so stage 1) is refused as a change to closed stage 1, and with
# `row: RULE-006 -> STAGE-2` it is drafted; an ordinary draft (not a re-cut) adding the same row in a stage-1 step is drafted, since
# land.sh reads the cuts only for a re-cut. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "land-recut-new-req-open-stage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
tw_hand 'stage-closed 1 | stand-in: RM at 0123456789ab candidate 1'
printf 'none\n' > "$T/rv"
ans() { { cat PRD.md; printf '\n### 2026-11-15 (the self-test)\n\n```vid-prd-answers\nA-%s | human | 2026-11-15 | Q: how should the product be delivered — in which stages? | A: %s | settles: contract\n```\n' "$1" "$2"; } > "$T/p" && cp "$T/p" PRD.md; }
ld() { RC=0; sh "$CHECKS/land.sh" draft --review "$T/rv" --why "/vid stage: $1" ${2:+--plan "$2"} > "$T/out" 2>&1 || RC=$?; }
# the new requirement, in stage 1's feature, split to stage 2, with its row in S05
awk '{ print } /^REQ-012 \|/ { print "REQ-013 | functional | T2 | A subscriber can rename a saved search. | fail-if: a renamed search loses its words or its address | serves: a subscriber keeps searches tidy | authority: authoritative | source: A-310 | phase: pilot | feature: FEAT-01" }' PRD.md > "$T/p" && cp "$T/p" PRD.md
grep -q '^REQ-013 ' PRD.md || fail 'the fixture did not take REQ-013'
ans 310 'renaming a search waits for stage 2'
awk '{ print } /^ROW-020 \|/ { print "ROW-021 | behavior | REQ-013 | anonymous | n/a | A renamed saved search keeps its words and its address. Fails if a renamed search loses either. | REQ-013 | owed: spec-only — ticket | origin: REQ-013" }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "split: REQ-013 -> STAGE-2" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | awk '/^step S05 / { sub(/rows: ROW-017 /, "rows: ROW-017 ROW-021 ") } /^needs ROW-017 / { sub(/ROW-017 /, "ROW-017 ROW-021 ") } { print }' > "$T/plan"
grep -q '^step S05 .*rows: ROW-017 ROW-021 |' "$T/plan" || fail "the plan was not drafted: $(grep 'step S05' "$T/plan")"
ld 'renaming a search waits for stage 2' "$T/plan"
[ "$RC" = 0 ] && grep -qx 'draft 1' "$T/out" || fail "a re-cut adding a requirement to a closed stage's feature and splitting it to an open stage was not drafted ($RC)"
# a move of a closed stage's existing requirement: still refused
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "split: REQ-006 -> STAGE-2" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; ans 311 'the search cap waits for stage 2'
ld 'the search cap waits for stage 2'
[ "$RC" = 1 ] && grep -q 'refused — .*stage 1.*closed' "$T/out" || fail "a re-cut moving closed stage 1's REQ-006 was not refused naming it ($RC)"
[ ! -d .vid/decide/drafts/2 ] || fail 'the refused re-cut was made a draft'
git checkout -q -- STAGES.md PRD.md
# a new census rule row: stage 1 with no row: line, so a re-cut adding it changes closed stage 1
rule() { awk '{ print } /^rule \| RULE-005 / { print "rule | RULE-006 | Every renamed search keeps its address | sites: every rename of a saved search | 1 | owed: spec-only — ticket | origin: REQ-012" }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
  sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | awk '/^step S05 / { sub(/rows: ROW-017 /, "rows: ROW-017 RULE-006 ") } /^needs ROW-017 / { sub(/ROW-017 /, "ROW-017 RULE-006 ") } { print }' > "$T/plan2"; }
rule; ans 312 'the rename rule is checked from stage 2'; ld 'the rename rule is checked from stage 2' "$T/plan2"
[ "$RC" = 1 ] && grep -q 'refused — .*stage 1.*closed' "$T/out" || fail "a re-cut adding an unplaced rule row (stage 1, closed) was not refused naming stage 1 ($RC)"
grep -q 'row: <id> -> STAGE-<k>' "$T/out" && grep -q 'rules: by-origin' "$T/out" || fail 'the refusal of a re-cut that changes a closed stage does not name the way out for a new rule row (a row: line to an open stage, or rules: by-origin)'
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "row: RULE-006 -> STAGE-2" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md
ld 'the rename rule is checked from stage 2' "$T/plan2"
[ "$RC" = 0 ] && grep -qx 'draft 2' "$T/out" || fail "a re-cut adding a rule row placed in open stage 2 by a row: line was not drafted ($RC)"
# an ordinary draft adding the row (no re-cut), in stage-1 step S03: the cuts are not read, so it is drafted
rule; sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | awk '/^step S03 / { sub(/rows: ROW-006 /, "rows: ROW-006 RULE-006 ") } /^needs ROW-006 / { sub(/ROW-006 /, "ROW-006 RULE-006 ") } { print }' > "$T/plan3"
grep -q '^step S03 .*rows: ROW-006 RULE-006 ' "$T/plan3" || fail "the stage-1 plan was not drafted: $(grep 'step S03' "$T/plan3")"
RC=0; sh "$CHECKS/land.sh" draft --review "$T/rv" --why 'the rename rule' --plan "$T/plan3" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && grep -qx 'draft 3' "$T/out" || fail "an ordinary draft adding a rule row was not drafted ($RC)"
exit 0
