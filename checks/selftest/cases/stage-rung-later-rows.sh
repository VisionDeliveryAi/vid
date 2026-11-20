#!/bin/sh
# Purpose: selftest case — the stage sitting shows the rows that cannot be tested yet (0.26.11.1.4, R9). The stage cut's rung
# trial lists, in each rung's scratch copy, its rows provable only at a later stage, read as the planner reads them (subject,
# marker and promise), with a count per stage, answered at the sitting by the cut's row: lines or kept, a step and never a
# refusal; a re-cut's moved rows are the ids whose stage differs between the base and the scratch copy, of every kind,
# protection rows included; and a protection row moves with the row it protects. Skips where skills/ is absent (a
# project's layout). Env: CHECKS.
set -eu
VS=$CHECKS/../skills/vid-stage/SKILL.md; VP=$CHECKS/../skills/vid-plan/SKILL.md
[ -f "$VS" ] && [ -f "$VP" ] || { echo 'needs skills/vid-stage and skills/vid-plan'; exit 77; }
fail() { echo "stage-rung-later-rows: $*" >&2; exit 1; }
# the rung trial's paragraph, joined
T=$(awk '/^\*\*Each rung is tried before it is shown\.\*\*/ { on = 1 } on && /^$/ { exit } on' "$VS" | tr '\n' ' ' | tr -s ' ')
[ -n "$T" ] || fail 'the stage skill has no rung trial'
for w in 'its rows provable only at a later stage' 'Rows provable only at a later stage' 'subject, marker and promise' \
  'a count per stage' 'by the cut'"'"'s existing `row:` lines, or keeps them' 'a step, never a refusal' \
  'the ids whose stage differs between the base and the scratch copy' 'of every kind, protection rows included' \
  'A protection row moves with the row it protects'; do
  printf '%s' "$T" | grep -qF -- "$w" || fail "the rung trial lacks: $w"; done
# the planner's own reading stands, under its heading
grep -qF '**Rows provable only at a later stage**' "$VP" || fail "the planner's reading is gone"
echo 'stage-rung-later-rows: ok'
