#!/bin/sh
# Purpose: selftest case — the stage court (v0.26.10.5 spec R4, R5; §5 stages-court). Under the real pre-commit and
# commit-msg hooks with stub courts (fixtures/stub-courts.sh), the real checks/stages.sh, prd.sh and lawfiles, and the
# toy two-stage product (fixtures/stages.sh). Silent while there never was a STAGES.md (the product commits; the
# court says nothing). Creating STAGES.md with no owner answer in the message is refused by commit-msg (by=stages);
# with `Stages: A-001` it lands. Then each R4 refusal convicts on its own fixture, each by=stages: a pilot feature in
# no stage; in two; a split: naming an unknown id; a split: naming a later item; a ROW spanning stages with no row:
# line; a requirement whose rows all sit in a later stage; a needs: edge to a later stage, directly and only
# transitively; a cycle. commit-msg refuses a membership change and a deletion of STAGES.md with no answer. R5: a
# commit adding a new feature to the PRD may leave it unplaced; the next commit is refused until it is placed.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/r"; cd "$T/r"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-court: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cp "$CHECKS/stages.sh" "$CHECKS/lawfiles" "$CHECKS/event.sh" checks/
# the prd court stays a stub; its --effective reading (what stages.sh calls) is the real one's
cp "$CHECKS/prd.sh" "$T/prd-real.sh"
printf '#!/bin/sh\n# Purpose: stub court prd; the effective reading is the real one\ncase "${1:-}" in --effective|--failifs) exec sh "%s" "$@" ;; esac\n: > .ran/prd\necho "prd ok"\n' "$T/prd-real.sh" > checks/prd.sh
cp "$CHECKS/hooks/commit-msg" checks/hooks/commit-msg
g add -A && g commit -qm 'the real stage court, prd reader and lawfiles' --no-verify
hc() { g -c core.hooksPath=checks/hooks commit -q -F "$1" > "$T/out" 2>&1; }   # a commit through both hooks
printf 'the toy product\n\nDecisions: none — nothing surprising\n' > "$T/m0"
printf 'the cut\n\nDecisions: none — nothing surprising\n' > "$T/m1"
printf 'the cut\n\nStages: A-001 (the owner ratified the cut)\nDecisions: none — nothing surprising\n' > "$T/m2"
# silent while there never was a STAGES.md
st_prd; st_inv; g add -A; g commit -qm 'the toy product' --no-verify
printf 'z\n' >> app/x.txt; g add app/x.txt
hc "$T/m0" || fail 'an ordinary commit was refused with no STAGES.md'
grep -q '^stages' "$T/out" && fail 'the court spoke while there never was a STAGES.md'
# created: an answer is required
st_cut; g add STAGES.md
if hc "$T/m1"; then fail 'STAGES.md was created with no owner answer in the message'; fi
grep -q 'creates STAGES.md and its message cites no owner answer' "$T/out" || fail 'the creation refusal does not say so'
grep -q 'refused phase=commit-msg by=stages ' .vid/metrics-events || fail 'no refused by=stages event from commit-msg'
hc "$T/m2" || fail 'the ratified cut citing A-001 was refused'
# each refusal on its own fixture, through the hook
bad() { # <what> <expected refusal text> — STAGES.md already rewritten
  g add -A
  if sh checks/hooks/pre-commit > "$T/out" 2>&1; then fail "$1: passed"; fi
  grep -qF -- "$2" "$T/out" || fail "$1: the refusal does not say '$2'"
  tail -n 3 .vid/metrics-events | grep -q 'refused phase=pre-commit by=stages ' || fail "$1: not refused by=stages"
  g checkout -q HEAD -- . ; g reset -q
}
B='split: REQ-003 -> STAGE-2'; R='row: ROW-006 -> STAGE-2'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02' 'STAGE-2 | b | features: FEAT-01' "$B" "$R"
bad 'a feature in no stage' 'feature FEAT-03 (pilot) is in no stage'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02 FEAT-03' 'STAGE-2 | b | features: FEAT-03' "$B" "$R"
bad 'a feature in two stages' 'feature FEAT-03 is in two stages: STAGE-1 STAGE-2'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02' 'STAGE-2 | b | features: FEAT-03' 'split: REQ-099 -> STAGE-2' "$R"
bad 'an unknown id' 'split: REQ-099 is no item of the PRD'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02' 'STAGE-2 | b | features: FEAT-03' "$B" 'split: REQ-005 -> STAGE-2' "$R"
bad 'a later item' 'split: REQ-005 is phase: later'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02' 'STAGE-2 | b | features: FEAT-03' "$B"
bad 'a spanning row with no row: line' 'ROW-006 derives from items of stages 1,2 and no row: line places it'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02' 'STAGE-2 | b | features: FEAT-03' "$B" "$R" 'row: ROW-002 -> STAGE-2'
bad 'a requirement proven only later' 'REQ-002 is in stage 1 but every row covering it is in a later stage'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02' 'STAGE-2 | b | features: FEAT-03' "$B" "$R" 'needs: FEAT-01 needs FEAT-03 — a module'
bad 'a needs: edge to a later stage' 'needs: FEAT-01 (STAGE-1) needs, directly or through others, a later stage: FEAT-03 (STAGE-2)'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02' 'STAGE-2 | b | features: FEAT-03' "$B" "$R" 'needs: FEAT-01 needs FEAT-02 — a module' 'needs: FEAT-02 needs FEAT-03 — a seam'
bad 'a needs: edge to a later stage, transitively' 'needs: FEAT-01 (STAGE-1) needs, directly or through others, a later stage: FEAT-03 (STAGE-2)'
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02' 'STAGE-2 | b | features: FEAT-03' "$B" "$R" 'needs: FEAT-01 needs FEAT-02 — a' 'needs: FEAT-02 needs FEAT-01 — b'
bad 'a cycle' 'needs: FEAT-01 is on a cycle of needs: edges'
# commit-msg: a membership change and a deletion, each with no answer
st_stages 'STAGE-1 | a | features: FEAT-01 FEAT-02 FEAT-03'
g add -A
printf 'one stage after all\n\nDecisions: none — nothing surprising\n' > "$T/m3"
if hc "$T/m3"; then fail 'a membership change with no answer landed'; fi
grep -q 'changes stage membership' "$T/out" || fail 'the membership refusal does not say so'
g checkout -q HEAD -- . ; g reset -q
g rm -q STAGES.md
if hc "$T/m3"; then fail 'STAGES.md was deleted with no answer'; fi
grep -q 'deletes STAGES.md and its message cites no owner answer' "$T/out" || fail 'the deletion refusal does not say so'
g reset -q; g checkout -q HEAD -- .
# R5: a new feature may be unplaced at the commit that adds it, never after
awk '/^FEAT-03 /{ print; print "FEAT-04 | G2 | export"; next } /^REQ-005 /{ print; print "REQ-006 | functional | T1 | a person exports notes | fail-if: an export loses a note | serves: export | phase: pilot | feature: FEAT-04"; next } { print }' PRD.md > PRD.x && mv PRD.x PRD.md
g add PRD.md
hc "$T/m0" || fail 'the commit adding FEAT-04 was refused'
printf 'y\n' >> app/x.txt; g add app/x.txt
if sh checks/hooks/pre-commit > "$T/out" 2>&1; then fail 'a commit after FEAT-04 landed unplaced passed'; fi
grep -q 'feature FEAT-04 (pilot) is in no stage' "$T/out" || fail 'the unplaced new feature is not named'
exit 0
