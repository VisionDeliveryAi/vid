#!/bin/sh
# Purpose: selftest case — adding or removing `rules: by-origin` is a membership change (0.26.10.29.4, phase 4 R2). On
# the toy product (fixtures/stages.sh) committed with its cut: the court parses the line (and refuses `rules: by-hand`
# and the line twice, named); `stages.sh msg` refuses a commit adding the line whose message cites no owner answer, and
# accepts it citing A-002; removing it again with no answer is refused too. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-msg-rules-line: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_files; g add -A; g commit -qm 'the toy and its cut'
printf 'the rules by their origin\n\nDecisions: none\n' > "$T/m0"
printf 'the rules by their origin\n\nStages: A-002 (the owner ratified it)\n' > "$T/m1"
cut() { st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'needs: FEAT-03 needs FEAT-01 — ARCHITECTURE.md module table' "$@"; g add STAGES.md; }
cut 'rules: by-hand'
if sh checks/stages.sh > "$T/out" 2>&1; then fail 'the court passed rules: by-hand'; fi
grep -q "rules: line does not parse (rules: by-origin): 'rules: by-hand'" "$T/out" || fail 'the refusal of rules: by-hand does not say so'
cut 'rules: by-origin' 'rules: by-origin'
if sh checks/stages.sh > "$T/out" 2>&1; then fail 'the court passed the line twice'; fi
grep -q 'rules: by-origin is declared twice' "$T/out" || fail 'the refusal of the line twice does not say so'
cut 'rules: by-origin'
sh checks/stages.sh > "$T/out" 2>&1 || fail 'the court refused rules: by-origin'
if sh checks/stages.sh msg "$T/m0" > "$T/out" 2>&1; then fail 'adding rules: by-origin with no owner answer passed msg'; fi
grep -q 'changes stage membership' "$T/out" || fail 'the refusal does not name a membership change'
sh checks/stages.sh msg "$T/m1" > "$T/out" 2>&1 || fail 'adding rules: by-origin citing A-002 was refused'
g commit -qm 'the rules by origin, A-002'
cut
if sh checks/stages.sh msg "$T/m0" > "$T/out" 2>&1; then fail 'removing rules: by-origin with no owner answer passed msg'; fi
exit 0
