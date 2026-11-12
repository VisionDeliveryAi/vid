#!/bin/sh
# Purpose: selftest case — planner.sh reratify (v0.26.10.25.5, R3), the owner's yes to a counted change landed during a run,
# ratified with no new sitting, on the writer's toy. Refused, each reason named and nothing recorded: a check flag open; a spec file
# the draft did not hold changed between the base and the landing; the spec files at the base not the newest ratified ones (a change
# no one ratified lies before the draft); the landing not HEAD. Accepted: a ratification with its base and landing, and no event
# (land.sh writes the publish-approved event), so planner.sh ratified passes, and with that event the writer's gate opens. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "planner-reratify: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; P=$CHECKS/planner.sh
rr() { RC=0; sh "$P" reratify "$@" > "$T/out" 2>&1 || RC=$?; }; n0() { grep -c . .vid/plan/ratified; }
B=$(git rev-parse HEAD); N=$(n0)
# a change landed: PRD.md and INVENTORY.md, held by the draft; the plan block unchanged
printf '\n### 2026-11-09 (the self-test)\n\n```vid-prd\n%s\n```\n' "$(grep '^REQ-012 |' PRD.md | sed 's/^REQ-012 |/REQ-012 AMENDED |/; s/or mail to it bounces/or mail to it bounces, or it names no person/')" >> PRD.md
g add PRD.md && g commit -qm 'the PRD'; L1=$(git rev-parse HEAD)
rr --words 'Yes' --base "$B" --to "$L1" --held INVENTORY.md; [ "$RC" = 1 ] && grep -q 'PRD.md changed between the base and the landing, and the draft did not hold it' "$T/out" || fail "a file the draft did not hold was not refused ($RC)"
rr --words 'Yes' --base "$B" --to "$B" --held PRD.md; [ "$RC" = 1 ] && grep -q 'is not HEAD' "$T/out" || fail "a landing not HEAD was not refused ($RC)"
# an open flag: a row of a step in no needs line
cp .vid/RUN-STATE.md "$T/rs"; sed 's/^needs ROW-017 | -$//' "$T/rs" > .vid/RUN-STATE.md; rr --words 'Yes' --base "$B" --to "$L1" --held PRD.md
[ "$RC" = 1 ] && grep -q 'a check flag is open' "$T/out" || fail "an open flag was not refused ($RC)"; cp "$T/rs" .vid/RUN-STATE.md
[ "$(n0)" = "$N" ] || fail 'a refused reratify recorded a ratification'
# accepted, the gate open
E0=$(grep -c . .vid/metrics-events); rr --words 'Yes, land it' --base "$B" --to "$L1" --held PRD.md,INVENTORY.md; [ "$RC" = 0 ] || fail "reratify was refused ($RC)"
tail -n 1 .vid/plan/ratified | grep -q "^ratified hash=$(sh "$P" hash) plan=[0-9a-f]* at=[^ ]* base=$(printf %.12s "$B") to=$(printf %.12s "$L1") words=Yes, land it$" || fail "the ratification: $(tail -n 1 .vid/plan/ratified)"
[ "$(grep -c . .vid/metrics-events)" = "$E0" ] || fail 'the planner wrote an event'
sh "$P" ratified > "$T/out" 2>&1 || fail 'not ratified'; printf 'publish-approved words="Yes, land it" at=x\n' >> .vid/metrics-events; sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || fail 'the gate is shut'
# an unseen earlier commit: a spec change no one ratified, then a draft on top of it
printf '\n### 2026-11-10 (the self-test)\n\n```vid-prd\n%s\n```\n' "$(grep '^REQ-012 AMENDED |' PRD.md | sed 's/names no person/names no person by role/')" >> PRD.md; g add PRD.md && g commit -qm 'unseen'; B2=$(git rev-parse HEAD)
printf '\n' >> GRADING-CHECKLIST.md; g add GRADING-CHECKLIST.md && g commit -qm 'the draft'; L2=$(git rev-parse HEAD)
rr --words 'Yes' --base "$B2" --to "$L2" --held GRADING-CHECKLIST.md; [ "$RC" = 1 ] && grep -q 'are not the newest ratified ones' "$T/out" || fail "an unseen earlier commit was not refused ($RC)"
exit 0
