#!/bin/sh
# Purpose: selftest case — a screen's rows wait for the stage that builds the screen (0.26.11.1.2, R8). On the toy
# product (fixtures/stages.sh) with four more rows: ROW-007, a state of screen S01 whose only requirement (REQ-002) is
# stage 1, and ROW-008, S01's populated state (REQ-004, stage 2), by their subject; ROW-009, a route whose marker names
# S01; ROW-010, a state of screen S02, which no screen: line names; HOS-003 protecting ROW-007. With no screen: line
# every one reads its requirements' stage (1, 2, 1, 1). With `screen: S01 -> STAGE-2` the court passes, ROW-007,
# ROW-009 and HOS-003 read stage 2 and leave `scope --upto 1`, ROW-010 stays in stage 1; a `row: ROW-007 -> STAGE-1`
# line is refused, `row: ROW-007 -> STAGE-0` in a cut with stage 0 is accepted and read as stage 0; a screen: line to an
# unknown stage, the same screen twice and one that does not parse are refused, each named; a requirement whose every
# row the line moves later trips the existing refusal; adding a screen: line with no owner answer is refused by msg,
# citing A-003 accepted. Where skills/ is beside checks/, vid-stage names the line and what the cut does then. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-screen-line: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_prd; st_inv
add() { awk -v l="$1" '/^```$/ && !d { print l; d = 1 } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md; }
add 'ROW-007 | surface | S01 | anonymous | S01/few | the few-matches state shows its notice | REQ-002 | tests/invariants/test_g.py'
add 'ROW-008 | surface | S01 | member | S01/default | the populated state lists the shared notes | REQ-004 | tests/invariants/test_h.py'
add 'ROW-009 | behavior | /home | anonymous | S01/empty | the empty state offers the first step | REQ-001 | tests/invariants/test_i.py'
add 'ROW-010 | surface | S02 | anonymous | S02/default | the note page renders | REQ-002 | tests/invariants/test_j.py'
add 'hostility | HOS-003 | the few-matches notice for a stranger | protects: ROW-007 | disable: drop the notice | tests/invariants/test_hos3.py'
cp INVENTORY.md "$T/inv0"
so() { sh checks/stages.sh stage-of "$1"; }
want() { _g=$(so "$1"); [ "$_g" = "$2" ] || fail "$1 reads stage $_g, not $2 ($3)"; }
cut() { st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'needs: FEAT-03 needs FEAT-01 — ARCHITECTURE.md module table' "$@"; git add -A; }
court() { sh checks/stages.sh > "$T/out" 2>&1; }
refused() { if court; then fail "the court passed $1"; fi; grep -q "$2" "$T/out" || fail "the refusal of $1 does not say: $2"; }
# no screen: line — as today
cut; court || fail 'the court refused the cut with no screen: line'
want ROW-007 1 'no screen: line'; want ROW-008 2 'no screen: line'; want ROW-009 1 'no screen: line'; want ROW-010 1 'no screen: line'; want HOS-003 1 'no screen: line'
# the screen's stage
cut 'screen: S01 -> STAGE-2'; court || fail 'the court refused screen: S01 -> STAGE-2'
want ROW-007 2 'its subject names S01'; want ROW-008 2 'its subject names S01'; want ROW-009 2 'its marker names S01'
want ROW-010 1 'S02 has no screen: line'; want HOS-003 2 'it protects ROW-007'
sh checks/stages.sh scope --upto 1 > "$T/s1"; for _r in ROW-007 ROW-008 ROW-009 HOS-003; do ! grep -qx "$_r" "$T/s1" || fail "$_r is in scope --upto 1"; done
grep -qx ROW-010 "$T/s1" || fail 'ROW-010 left scope --upto 1'
sh checks/stages.sh scope --upto 2 | grep -qx ROW-007 || fail 'ROW-007 is not in scope --upto 2'
# a row: line placing a screen row earlier: refused; stage 0 kept as written; later accepted
cut 'screen: S01 -> STAGE-2' 'row: ROW-007 -> STAGE-1'
refused 'row: ROW-007 -> STAGE-1' 'row: ROW-007 -> STAGE-1 places a row of screen S01 before STAGE-2'
st_stages 'STAGE-0 | the skeleton | technical' 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' \
  'split: REQ-003 -> STAGE-2' 'row: ROW-006 -> STAGE-2' 'row: ROW-007 -> STAGE-0' 'screen: S01 -> STAGE-2'; git add -A
court || fail 'the court refused row: ROW-007 -> STAGE-0 beside screen: S01 -> STAGE-2'
want ROW-007 0 'a row: line puts it in stage 0'; want ROW-009 2 'its marker names S01'
st_stages 'STAGE-1 | the basics | features: FEAT-01 FEAT-02' 'STAGE-2 | sharing | features: FEAT-03' 'STAGE-3 | later | features: -' \
  'split: REQ-003 -> STAGE-3' 'row: ROW-006 -> STAGE-2' 'row: ROW-007 -> STAGE-3' 'screen: S01 -> STAGE-2'; git add -A
court || fail 'the court refused a row: line placing a screen row after its screen'
want ROW-007 3 'a row: line places it after its screen'
# the line's own refusals
cut 'screen: S01 -> STAGE-4'; refused 'a screen: line to an unknown stage' 'screen: S01 -> STAGE-4, which is no stage'
cut 'screen: S01 -> STAGE-2' 'screen: S01 -> STAGE-1'; refused 'a screen twice' 'screen: S01 is placed twice'
cut 'screen: S01 STAGE-2'; refused 'a screen: line that does not parse' 'screen: line does not parse'
# a requirement whose every row the line moves later: the existing refusal
sed 's#^\(ROW-001 | behavior | REQ-001 | anonymous | \)n/a#\1S01/denied#' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
cut 'screen: S01 -> STAGE-2'; refused 'REQ-001 with every row moved later' 'REQ-001 is in stage 1 but every row covering it is in a later stage'
cp "$T/inv0" INVENTORY.md
# a membership line: a change needs an owner answer
cut; g commit -qm 'the toy and its cut'
printf 'the screen line\n\nDecisions: none\n' > "$T/m0"; printf 'the screen line\n\nStages: A-003 (the owner ratified it)\n' > "$T/m1"
cut 'screen: S01 -> STAGE-2'
if sh checks/stages.sh msg "$T/m0" > "$T/out" 2>&1; then fail 'adding a screen: line with no owner answer passed msg'; fi
grep -q 'changes stage membership' "$T/out" || fail 'the refusal does not name a membership change'
sh checks/stages.sh msg "$T/m1" > "$T/out" 2>&1 || fail 'adding a screen: line citing A-003 was refused'
# vid-stage's words, where the skills are
if [ -f "$CHECKS/../skills/vid-stage/SKILL.md" ]; then
  _s=$(tr '\n' ' ' < "$CHECKS/../skills/vid-stage/SKILL.md" | tr -s ' ')
  case "$_s" in *'screen: <screen id> -> STAGE-<n>'*) ;; *) fail 'vid-stage does not name the screen: line' ;; esac
  printf '%s\n' "$_s" | grep -q 'every row sits in a later stage.\{0,200\}moves that requirement to the screen' || fail 'vid-stage does not say the cut moves a requirement whose every row moves later'
fi
exit 0
