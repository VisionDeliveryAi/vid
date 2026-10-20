#!/bin/sh
# Purpose: selftest case — the stage court with stage 0 (v0.26.10.8 spec R2; §5 stages-court-stage0). Under the real
# pre-commit and commit-msg hooks with stub courts (fixtures/stub-courts.sh), the real checks/stages.sh, prd.sh and
# lawfiles, and the toy product (fixtures/stages.sh). Creating STAGES.md with `STAGE-0 | the skeleton | technical`, fed
# by row: lines, and stages 1 and 2, lands in the commit that creates it (citing an answer). Then each refusal
# convicts on its own fixture, by=stages: `technical` on STAGE-1; STAGE-0 without it; a feature in STAGE-0; a split:
# to STAGE-0; a STAGE-0 no row: line places a row in; STAGE-0 removed from the existing STAGES.md; and, from a cut
# without it, STAGE-0 added to an existing STAGES.md. commit-msg refuses a change to the STAGE-0 line with no answer.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/r"; cd "$T/r"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-court-stage0: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cp "$CHECKS/stages.sh" "$CHECKS/lawfiles" "$CHECKS/event.sh" checks/
cp "$CHECKS/prd.sh" "$T/prd-real.sh"
printf '#!/bin/sh\n# Purpose: stub court prd; the effective reading is the real one\ncase "${1:-}" in --effective|--failifs) exec sh "%s" "$@" ;; esac\n: > .ran/prd\necho "prd ok"\n' "$T/prd-real.sh" > checks/prd.sh
cp "$CHECKS/hooks/commit-msg" checks/hooks/commit-msg
g add -A && g commit -qm 'the real stage court, prd reader and lawfiles' --no-verify
hc() { g -c core.hooksPath=checks/hooks commit -q -F "$1" > "$T/out" 2>&1; }
printf 'the change\n\nDecisions: none — nothing surprising\n' > "$T/m0"
printf 'the cut\n\nStages: A-001 (the owner ratified the cut, stage 0 included)\nDecisions: none — nothing surprising\n' > "$T/m1"
st_prd; st_inv; g add -A; g commit -qm 'the toy product' --no-verify
Z='STAGE-0 | the skeleton | technical'; S1='STAGE-1 | the basics | features: FEAT-01 FEAT-02'; S2='STAGE-2 | sharing | features: FEAT-03'
B='split: REQ-003 -> STAGE-2'; R='row: ROW-006 -> STAGE-2'; R0='row: ROW-001 -> STAGE-0'; R0b='row: ROW-002 -> STAGE-0'
# accepted in the commit creating STAGES.md
st_stages "$Z" "$S1" "$S2" "$B" "$R" "$R0" "$R0b"; g add STAGES.md
hc "$T/m1" || fail 'the cut with STAGE-0 fed by row: lines was refused'
# each refusal on its own fixture, through the hook
bad() { # <what> <expected refusal text> — STAGES.md already rewritten
  g add -A
  if sh checks/hooks/pre-commit > "$T/out" 2>&1; then fail "$1: passed"; fi
  grep -qF -- "$2" "$T/out" || fail "$1: the refusal does not say '$2'"
  tail -n 3 .vid/metrics-events | grep -q 'refused phase=pre-commit by=stages ' || fail "$1: not refused by=stages"
  g checkout -q HEAD -- . ; g reset -q
}
st_stages "$Z" 'STAGE-1 | the basics | technical | features: FEAT-01 FEAT-02' "$S2" "$B" "$R" "$R0" "$R0b"
bad 'technical on STAGE-1' 'STAGE-1 is marked technical: only STAGE-0'
st_stages 'STAGE-0 | the skeleton' "$S1" "$S2" "$B" "$R" "$R0" "$R0b"
bad 'STAGE-0 without technical' 'STAGE-0 is not marked technical'
st_stages 'STAGE-0 | the skeleton | technical | features: FEAT-01' 'STAGE-1 | the basics | features: FEAT-02' "$S2" "$B" "$R" "$R0" "$R0b"
bad 'a feature in STAGE-0' 'STAGE-0 lists features (FEAT-01): stage 0 holds rows only'
st_stages "$Z" "$S1" "$S2" "$B" "$R" "$R0" "$R0b" 'split: REQ-002 -> STAGE-0'
bad 'a split: to STAGE-0' 'split: REQ-002 -> STAGE-0: stage 0 holds rows only'
st_stages "$Z" "$S1" "$S2" "$B" "$R"
bad 'a STAGE-0 with no row: line' 'STAGE-0 holds no row: no row: line places a row in it'
st_stages "$S1" "$S2" "$B" "$R"
bad 'STAGE-0 removed from STAGES.md' 'STAGE-0 is removed from STAGES.md'
# commit-msg: the STAGE-0 line is membership — its change needs an answer
st_stages 'STAGE-0 | the thin journey | technical' "$S1" "$S2" "$B" "$R" "$R0" "$R0b"; g add -A
if hc "$T/m0"; then fail 'a change to the STAGE-0 line landed with no answer'; fi
grep -q 'changes stage membership' "$T/out" || fail 'the membership refusal does not say so'
g checkout -q HEAD -- . ; g reset -q
# from a cut without stage 0: adding it later is refused
g rm -q STAGES.md; g commit -qm 'no cut' --no-verify
st_stages "$S1" "$S2" "$B" "$R"; g add STAGES.md; hc "$T/m1" || fail 'the cut without STAGE-0 was refused'
st_stages "$Z" "$S1" "$S2" "$B" "$R" "$R0" "$R0b"
bad 'STAGE-0 added to an existing STAGES.md' 'STAGE-0 is added to an existing STAGES.md'
exit 0
