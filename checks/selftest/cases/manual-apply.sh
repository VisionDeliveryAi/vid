#!/bin/sh
# Purpose: selftest case — the apply move on the owner's one yes (GM-3 U4; its case manual-apply). On the form fixture's toy
# (fixtures/form.sh), ROW-022 added and applied first, in no step, on the to-place list in the owner's words, the plan ratified
# again; S02 posted as #N2 and S03 as #N3; the team adds a line of its own to #N2's body. Then, committed as landings leave them:
# ROW-012 reworded (reset, in #N2), ROW-021 added, ROW-019 deleted (retired, in #N3). The candidate tops #N2 up with ROW-021,
# takes the retired ROW-019 out of S03 and places ROW-022 in S04; the analysis writes the proposal. `replan.sh apply --words
# "<words>"` exits 0: .vid/tw/applied is the proposal's target, and .vid/tw/applied.log's newest line names it, set by the apply;
# the plan block is the proposal's, recorded (the newest plan change's hash its block hash) and ratified in the owner's words
# (planner.sh ratified exits 0); ROW-022 is off the to-place list; #N2 is amended, its notice naming ROW-021 added and ROW-012
# restated; #N3 is amended, its notice naming ROW-019 retired, its writing listing ROW-019 marked retired, its log line carrying
# retired=ROW-019; nothing is withdrawn; and every line of #N2's and #N3's bodies outside ViD's own fillings (the form records'
# values, before and after) stands byte for byte, the team's own line among them. S06, holding ROW-018 alone (out
# of S04, recorded), is posted as #N6 (in the form) and ROW-018 retired too; the candidate drops S06: #N6 is amended marking
# ROW-018 retired, never withdrawn, and due then owes its withdrawal, the owner's move for the next call; the
# apply posts none. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-apply: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
# addrow <id> <promise>: a behaviour row of REQ-001 added after ROW-020
addrow() { awk -v l="$1 | behavior | REQ-001 | anonymous | n/a | $2 | REQ-001 | owed: spec-only — first stage | origin: REQ-001" '{ print } /^ROW-020 / && !d { print l; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; }
# ROW-022 applied in no step, on the to-place list in the owner's words
addrow ROW-022 'A saved search shows how many jobs its last digest held. Fails if the count is missing.'
g commit -qam 'ROW-022 landed'; git rev-parse HEAD > .vid/tw/applied
printf 'ROW-022\tno-step\t2026-11-19T10:00:00Z\tleave ROW-022 to place for now\n' > .vid/tw/to-place
tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified again with ROW-022 to place'
# S06, a step of ROW-018 alone, out of S04, recorded
pt_rs 's/^\(step S04 .*rows:.*\) ROW-018 /\1 /'; pt_rs 's/^\(needs .*\) ROW-018 /\1 /'
pt_rs '/^step S05 /{p;s/.*/step S06 | name: the failure log | modules: digest | builds-on: S02 | rows: ROW-018 | lane: devagent/;}'; pt_rs '/^needs ROW-017 /{p;s/.*/needs ROW-018 | -/;}'
sh "$CHECKS/plan.sh" change rows 'S06 holds the failure log' --trigger scope-change --evidence "commit:$(git rev-parse --short HEAD)" --expect 'ROW-018 in a step of its own' > "$T/out" 2>&1 || fail 'S06 could not be recorded'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; N3=$FM_N
fm_post S06 || { cp "$T/post" "$T/out"; fail 'S06 was not posted in manual'; }; N6=$FM_N
printf "The team's own note: the feed is read at six.\n" >> "$FAKEGH/issues/$N2/body"
for n in $N2 $N3; do cp "$FAKEGH/issues/$n/body" "$T/b0.$n"; cp ".vid/tw/form/issue-$n" "$T/f0.$n"; done
# the landed changes: ROW-012 reworded, ROW-021 added, ROW-019 retired
sed 's/at the stated size of 10,000 active jobs/at the stated size of 20,000 active jobs/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
addrow ROW-021 'A saved search shows the day its last digest went out. Fails if a saved search shows no day.'
grep -v -e '^ROW-019 ' -e '^ROW-018 ' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'the landed changes'; HD=$(git rev-parse HEAD)
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
# the candidate and its analysis
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
C=$T/cand; mkdir -p "$C"; printf 'none\n' > "$C/review"
blk | sed -e '/^step S06 /d' -e '/^needs ROW-018 | -$/d' -e 's/^\(step S02 .*rows:\) /\1 ROW-021 /' -e 's/^\(step S03 .*\) ROW-019 /\1 /' -e 's/^\(step S04 .*rows:\) /\1 ROW-022 /' \
  -e 's/^\(needs .*\) ROW-019 /\1 /' -e '/^needs ROW-017 /{p;s/.*/needs ROW-021 | -/;p;s/.*/needs ROW-022 | -/;}' > "$C/block"
S=$(git rev-parse --short HEAD)
{ printf 'S02\tscope-change\tcommit:%s\tROW-021 joins #%s, which builds what it checks\n' "$S" "$N2"
  printf 'S03\tscope-change\tcommit:%s\tthe retired ROW-019 leaves the plan; #%s keeps it listed, marked retired\n' "$S" "$N3"
  printf 'S04\tscope-change\tcommit:%s\tROW-022 is placed in S04\n' "$S"
  printf 'S06\tscope-change\tcommit:%s\tits one test, ROW-018, is retired; #%s keeps it listed, marked retired\n' "$S" "$N6"; } > "$C/changes"
sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis was refused'
# the apply
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply the re-plan' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the apply exited $RC"
[ "$(sed -n 1p .vid/tw/applied)" = "$HD" ] || fail "the applied commit is $(sed -n 1p .vid/tw/applied), not the proposal's target $HD"
tail -n 1 .vid/tw/applied.log | awk -F'\t' -v h="$HD" '$1 == h && $3 == "apply" { f = 1 } END { exit !f }' || { cat .vid/tw/applied.log > "$T/out"; fail "the applied log's newest line does not name $HD, set by the apply"; }
BH=$(sed 's/[[:space:]]*$//' "$C/block" | { if command -v shasum > /dev/null 2>&1; then shasum -a 256; else sha256sum; fi; } | cut -c1-12)
[ "$(grep '^plan-change ' .vid/metrics-events | tail -n 1 | sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p')" = "$BH" ] || fail "the newest plan change is not the proposal's block ($BH)"
blk > "$T/blk"; cmp -s "$C/block" "$T/blk" || { diff "$C/block" "$T/blk" > "$T/out" || :; fail "RUN-STATE's block is not the proposal's"; }
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'the plan is not ratified after the apply'
tail -n 1 .vid/plan/ratified | grep -q 'words=Yes, apply the re-plan$' || { tail -n 1 .vid/plan/ratified > "$T/out"; fail "the newest ratification is not in the owner's words"; }
! grep -q '^ROW-022	' .vid/tw/to-place || { cat .vid/tw/to-place > "$T/out"; fail 'ROW-022 is still on the to-place list'; }
grep -q "^amended $N2 " .vid/tw/log && grep -q "^amended $N3 " .vid/tw/log || fail "#$N2 and #$N3 were not both amended"
am_comment "$N2" 'vid: amended' > "$T/am2"; am_comment "$N3" 'vid: amended' > "$T/am3"; cat "$T/am2" "$T/am3" > "$T/out"
grep -q '^- added: ROW-021 ' "$T/am2" && grep -q '^- restated: ROW-012 ' "$T/am2" || fail "#$N2's notice does not name ROW-021 added and ROW-012 restated"
grep -q '^- retired: ROW-019' "$T/am3" || fail "#$N3's notice does not name ROW-019 retired"
grep -q '^- ROW-019 marks: retired' ".vid/tw/out/issue-$N3.md" || { sed -n '/^## Rows/,/^## Requirements/p' ".vid/tw/out/issue-$N3.md" > "$T/out"; fail "#$N3's writing does not list ROW-019 marked retired"; }
grep "^amended $N3 " .vid/tw/log | tail -n 1 | grep -q ' retired=ROW-019 ' || { grep "^amended $N3 " .vid/tw/log > "$T/out" || :; fail "#$N3's amended line does not carry retired=ROW-019"; }
! grep -q '^withdrawn ' .vid/tw/log || fail 'the apply withdrew a ticket'
grep "^amended $N6 " .vid/tw/log | tail -n 1 | grep -q ' retired=ROW-018 ' || { grep "^amended $N6 " .vid/tw/log > "$T/out" || :; fail "#$N6, left with only retired tests, was not amended marking ROW-018 retired"; }
sh "$CHECKS/writer.sh" due > "$T/due" 2>&1 || { cp "$T/due" "$T/out"; fail 'writer.sh due failed after the apply'; }
# its withdrawal is then the owner's move: due owes it for the next call, and the apply posted none
grep -q "^withdraw $N6 " "$T/due" || { cp "$T/due" "$T/out"; fail "due does not owe #$N6's withdrawal once its retired tests are marked"; }
# the team's lines: every body line outside ViD's fillings, before and after, byte for byte
for n in $N2 $N3; do cut -f2- "$T/f0.$n" ".vid/tw/form/issue-$n" > "$T/fill"
  grep -vxF -f "$T/fill" "$T/b0.$n" > "$T/t0" || :; grep -vxF -f "$T/fill" "$FAKEGH/issues/$n/body" > "$T/t1" || :
  cmp -s "$T/t0" "$T/t1" || { diff "$T/t0" "$T/t1" > "$T/out" || :; fail "a line of #$n's body outside ViD's fillings changed"; }; done
grep -qxF "The team's own note: the feed is read at six." "$FAKEGH/issues/$N2/body" || fail "the team's own line on #$N2 is gone"
exit 0
