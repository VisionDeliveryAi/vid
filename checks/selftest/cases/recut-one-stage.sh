#!/bin/sh
# Purpose: selftest case — a re-cut back to one stage, and a re-cut after it, in ticket mode (0.26.10.29.2, R2), checks/land.sh on the
# writer's toy (stage 0 not yet closed, RUN-STATE at `stage: 0`). The verb deletes STAGES.md in the working tree and adds the owner's
# answer row; the draft carries the deletion and puts the tree back; the landing deletes STAGES.md in its law commit, which cites the
# answer (commit-msg: checks/stages.sh msg refuses a deletion citing none), re-ratifies with STAGES.md held, so the writer's gate stays
# open, records the stage-cut event of one stage, and moves RUN-STATE's stage: to 1, the one stage. A second re-cut into stages 1 and 2
# (no stage 0) keeps stage: at 1, so admission refuses a step holding a stage-2 row. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "recut-one-stage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/   # admission's stage scope reads the project's checks/
grep -qx 'stage: 0' .vid/RUN-STATE.md || fail 'the toy is not at stage 0 (the case is wrong)'
ans() { { cat PRD.md; printf '\n### 2026-11-15 (the self-test)\n\n```vid-prd-answers\nA-%s | human | 2026-11-15 | Q: how should the product be delivered — in which stages? | A: %s | settles: contract\n```\n' "$1" "$2"; } > "$T/p" && cp "$T/p" PRD.md; }
printf 'none\n' > "$T/rv"; H0=$(git rev-parse HEAD)
# the re-cut to one stage: STAGES.md deleted, the owner's answer row
rm STAGES.md; ans 302 'one stage'
# the plan as it will stand: with no stage 0 the skeleton holds one row, ROW-004, and ROW-003 joins S02 (as pt_nostage0 cuts it)
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | sed -e 's/^\(step S01 .*\)rows: ROW-003 ROW-004 /\1rows: ROW-004 /' -e 's/^\(step S02 .*rows:\) /\1 ROW-003 /' -e 's/^needs ROW-003 ROW-004 /needs ROW-004 /' -e 's/^needs ROW-001 /needs ROW-003 ROW-001 /' > "$T/plan"
RC=0; sh "$CHECKS/land.sh" draft --review "$T/rv" --why '/vid stage: one stage, in the owner words' --plan "$T/plan" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && grep -qx 'draft 1' "$T/out" || fail "the re-cut to one stage was not drafted ($RC): $(cat "$T/out")"
[ -f STAGES.md ] && [ -z "$(git status --porcelain -- STAGES.md PRD.md)" ] && [ "$(git rev-parse HEAD)" = "$H0" ] || fail 'the draft did not put the tree back'
mkdir -p "$T/hk"; printf '#!/bin/sh\nexec sh "%s/stages.sh" msg "$1"\n' "$CHECKS" > "$T/hk/commit-msg"; chmod +x "$T/hk/commit-msg"; git config core.hooksPath "$T/hk"
RC=0; sh "$CHECKS/land.sh" 1 --words 'Yes, one stage' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the re-cut to one stage did not land ($RC)"
[ ! -f STAGES.md ] || fail 'a landed re-cut to one stage leaves STAGES.md in the working tree'; ! git cat-file -e HEAD:STAGES.md 2>/dev/null || fail 'a landed re-cut to one stage leaves STAGES.md in HEAD'
git log -1 --format=%B --diff-filter=D -- STAGES.md | grep -qx 'Answers: A-302' || fail "the deletion cites no answer: $(git log -1 --format=%B --diff-filter=D -- STAGES.md)"
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'not ratified after the re-cut to one stage'; sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || fail "the writer's gate is shut after the re-cut to one stage"
grep -q '^stage-cut n=1 answer=A-302 at=' .vid/metrics-events || fail "no stage-cut event of one stage: $(grep '^stage-cut' .vid/metrics-events)"
grep -qx 'stage: 1' .vid/RUN-STATE.md || fail "the re-cut to one stage left RUN-STATE at $(grep '^stage:' .vid/RUN-STATE.md)"
# a second re-cut, into stages 1 and 2 with no stage 0: stage: stays 1, so a step holding stage 2's ROW-017 is refused
printf '# JobDigest — STAGES\n\n## The cut\n\n```vid-stages\nSTAGE-1 | The daily digest | features: FEAT-01 FEAT-03\nSTAGE-2 | Synonym-aware search | features: FEAT-02\n```\n' > STAGES.md; ans 305 'two stages after all'
RC=0; sh "$CHECKS/land.sh" draft --review "$T/rv" --why '/vid stage: two stages, in the owner words' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the second re-cut was not drafted ($RC)"
RC=0; sh "$CHECKS/land.sh" 2 --words 'Yes, two stages' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the second re-cut did not land ($RC)"
grep -qx 'stage: 1' .vid/RUN-STATE.md || fail "the second re-cut left RUN-STATE at $(grep '^stage:' .vid/RUN-STATE.md)"
tw_hand 'closed S02'; ! tw_start S05 || fail 'a step holding a stage-2 row was admitted at stage 1'; grep -q 'outside stages 1 to 1' "$T/start" || fail "S05 was not refused for its stage: $(cat "$T/start")"
exit 0
