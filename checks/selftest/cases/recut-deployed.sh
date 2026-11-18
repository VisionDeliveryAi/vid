#!/bin/sh
# Purpose: selftest case — a re-cut never changes a stage closed or deployed, nor leaves a stage with no row (0.26.10.29.2, R2),
# checks/land.sh on the writer's toy, its cut giving stage 2 the support address too (REQ-012, its rows in a step S06 of stage 2).
# Stage 1 is deployed first (its candidate's D1 passed) and closed; stage 2 has a candidate whose D1 okay is out. A re-cut moving both
# of stage 2's requirements to a new stage 3 is refused, naming stage 2 left with no row. A re-cut touching stages 2 and 3 (REQ-003
# split to a new stage 3) is drafted while stage 2's D1 has not passed; once it passed, that draft's landing is refused (the D1 passed
# between the ask and the yes) and nothing lands, and the same re-cut drafted again is refused, naming stage 2 deployed, though stage
# 2's deploy wrote no `staged` line (only the first stage's does), the tree kept; so too with a production record covering stage 2 in
# place of its D1. A re-cut touching stage 1 (REQ-006 to stage 2) is refused, naming stage 1 closed. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "recut-deployed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "split: REQ-012 -> STAGE-2" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; g add STAGES.md && g commit -qm 'the cut: the support address in stage 2'
awk '/^step S03 / || /^needs ROW-006 / { gsub(/ ROW-006| ROW-019/, "") } { print }
  /^step S05 / { print "step S06 | name: the support address | modules: web mail | builds-on: S01 | rows: ROW-006 ROW-019 | lane: devagent" } /^needs ROW-017 / { print "needs ROW-006 ROW-019 | -" }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
pt_record; tw_ratify 'Yes, publish it' || fail 'the toy with the support address in stage 2 was not ratified'
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
S=.vid/decide/stage; printf 'none\n' > "$T/rv"
cand() { mkdir -p "$S/$1/$2/d1"; printf 'issue\t%s\ncommit\t0123456789ab\nasked\t2026-11-14T10:00:00Z\n' "$3" > "$S/$1/$2/ask"; : > "$S/$1/$2/named"; : > "$S/$1/$2/passed"
  printf 'issue\t%s\ncommit\t0123456789ab\nasked\t2026-11-14T11:00:00Z\n' "$(($3 + 1))" > "$S/$1/$2/d1/ask"; tw_hand "candidate $1 | stand-in: RM at 0123456789ab candidate $2"; }
# stage 1 deployed first, then closed; stage 2's candidate, its D1 okay out
cand 1 1 40; : > "$S/1/1/d1/passed"; tw_hand 'stage-closed 1 | stand-in: RM at 0123456789ab candidate 1'; cand 2 1 50
grep -c '^staged ' .vid/tw/handed | grep -qx 1 || fail 'the toy has more than the first stage'"'"'s staged line'
ans() { { cat PRD.md; printf '\n### 2026-11-15 (the self-test)\n\n```vid-prd-answers\nA-%s | human | 2026-11-15 | Q: how should the product be delivered — in which stages? | A: %s | settles: contract\n```\n' "$1" "$2"; } > "$T/p" && cp "$T/p" PRD.md; }
later() { awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "STAGE-3 | Synonyms, later | features: -"; print "split: REQ-003 -> STAGE-3" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; ans 303 'the synonyms wait for a stage 3'; }
ld() { RC=0; sh "$CHECKS/land.sh" draft --review "$T/rv" --why "/vid stage: $1" > "$T/out" 2>&1 || RC=$?; }
# a re-cut that leaves stage 2 with no row: refused, naming it
awk '/^split: REQ-012 -> STAGE-2$/ { next } { print } /^STAGE-2 \| Synonym-aware search/ { print "STAGE-3 | Synonyms and support, later | features: -"; print "split: REQ-003 REQ-012 -> STAGE-3" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md
ans 306 'everything of stage 2 waits for a stage 3'; ld 'everything of stage 2 waits for a stage 3'; [ "$RC" = 1 ] && grep -q 'refused — .*stage 2 with no row' "$T/out" || fail "a re-cut leaving stage 2 with no row was not refused naming it ($RC)"
[ ! -d .vid/decide/drafts/1 ] || fail 'a re-cut leaving a stage with no row was made a draft'; git checkout -q -- STAGES.md PRD.md
# so too when stage 2's remaining rows stay in it by the cut but PLAN.md moves them to stage 3 (moved:): no row of stage 2 in effect
later; ans 307 'the synonyms and the support address wait for a stage 3'; awk '{ print } /^standing work \|/ { print "ROW-006 | moved: STAGE-3 A-307"; print "ROW-019 | moved: STAGE-3 A-307" }' PLAN.md > "$T/pl" && cp "$T/pl" PLAN.md
ld 'the synonyms and the support address wait for a stage 3'; [ "$RC" = 1 ] && grep -q 'refused — .*stage 2 with no row' "$T/out" || fail "a re-cut leaving stage 2 with no row by PLAN.md's moved: lines was not refused naming it ($RC)"
[ ! -d .vid/decide/drafts/1 ] || fail 'a re-cut leaving a stage with no row in effect was made a draft'; git checkout -q -- STAGES.md PRD.md PLAN.md
# stage 2 not yet deployed: the re-cut is drafted
later; ld 'the synonyms wait for a stage 3'; [ "$RC" = 0 ] && grep -qx 'draft 1' "$T/out" || fail "a re-cut of stage 2, not deployed, was refused ($RC)"
# stage 2's D1 passes before the owner's yes: the landing is refused, nothing lands
: > "$S/2/1/d1/passed"; H0=$(git rev-parse HEAD); RC=0; sh "$CHECKS/land.sh" 1 --words 'Yes, a stage 3' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'refused — .*stage 2.*deployed' "$T/out" || fail "a re-cut whose stage deployed before the yes landed, or was not refused naming it ($RC)"; [ "$(git rev-parse HEAD)" = "$H0" ] && [ ! -f .vid/decide/drafts/1/landed ] || fail 'the refused landing landed something'
# deployed, with no staged line: the same re-cut drafted again is refused and the tree kept
later; ld 'the synonyms wait for a stage 3'; [ "$RC" = 1 ] || fail "a re-cut of stage 2, deployed, was drafted ($RC)"
grep -q 'refused — .*stage 2.*deployed' "$T/out" || fail "the refusal does not name stage 2 deployed: $(cat "$T/out")"; [ ! -d .vid/decide/drafts/2 ] || fail 'a refused re-cut was made a draft'
[ -n "$(git status --porcelain -- STAGES.md)" ] || fail 'the refused re-cut did not keep the tree'; git checkout -q -- STAGES.md PRD.md
# a production record covering stage 2 in place of its D1: deployed too
rm -f "$S/2/1/d1/passed"; tw_hand 'production 2 | stand-in: D2 #60 at 0123456789ab'; later; ld 'the synonyms wait for a stage 3'; [ "$RC" = 1 ] && grep -q 'stage 2.*deployed' "$T/out" || fail "a re-cut of stage 2 in production was drafted ($RC)"
git checkout -q -- STAGES.md PRD.md; grep -v '^production 2 ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed
# a re-cut touching stage 1, closed: refused
awk '{ print } /^STAGE-2 \| Synonym-aware search/ { print "split: REQ-006 -> STAGE-2" }' STAGES.md > "$T/s" && cp "$T/s" STAGES.md; ans 304 'the search cap waits for stage 2'
ld 'the search cap waits for stage 2'; [ "$RC" = 1 ] && grep -q 'refused — .*stage 1.*closed' "$T/out" || fail "a re-cut of stage 1, closed, was not refused naming it ($RC)"
exit 0
