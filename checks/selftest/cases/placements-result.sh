#!/bin/sh
# Purpose: selftest case — the two readers' outputs joined (FB-4 A1.1). On the planner's toy, its whole plan listed (one part):
# `planner.sh placements result <dir>` is refused (exit 1, the part and the line named, nothing recorded) with no reader's file; with
# counts that do not add up to the part's placements; with a finding out of form or twice; with none and findings; with no refuter's
# file for a part with findings (a refused first reader's refuter file goes with it: no verdict of it may join a new output); with a finding that has no line of the refuter's, or two; with a line for no finding. A part with no
# finding needs no refuter's file. The join: the counts are the outputs', a finding that stands or stands in part keeps its better
# place as the refuter left it and the refuter's why, a refuted one is in no line, the unjudged lines are kept; a `|` inside a quote
# is the quote's, and several rules in one finding are kept as written and shown each by its name. <dir>/reviewed is the block judged. The second round's findings take the first's place; the first's placed line
# and its unjudged lines of tests the second does not list are kept; a finding that names no test and no step is refused, so every one is read again; a third round is not recorded and it says so. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "placements-result: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
TB=$(printf '\t'); D=.vid/plan/placement; pt_toy "$T/toy"
p() { RC=0; sh "$CHECKS/planner.sh" placements "$@" > "$T/out" 2>&1 || RC=$?; }
p write "$D"; [ "$RC" = 0 ] || fail 'write was refused'; N=$(sed -n 's/^listed //p' "$T/out")
F1='finding 1 | ROW-017, RULE-004 | in S05 | rule 2 | wrong | better: S04 | quote: "ROW-017 | behavior" (INVENTORY.md, ROW-017) | harm: nothing there shows it'
F2='finding 2 | S04 | in S04 | rule 7 | doubt | better: S04 without S03 | quote: "builds-on: S02 S03" (the plan, S04) | harm: S04 waits for S03'
F3='finding 3 | ROW-012 | in S02 | rule 1 | doubt | better: S04 | quote: "10,000 active jobs" (INVENTORY.md, ROW-012) | harm: it is shown late'
U='unjudged ROW-018 | the open question is not answered'
good() { printf '%s\n%s\n\n%s\n%s\nplaced right=%s finding=3 unjudged=1\n' "$F1" "$F2" "$F3" "$U" $((N - 4)) > "$D/part-1.reader"
  printf 'stands 1 | better: S03 | "nothing in S05" (the plan, S05)\nrefuted 2 | (b) | a test of S04 needs S03\npartly 3 | better: S04 | the size stands, the place does not\n' > "$D/part-1.refuter"; }
refused() { p result "$D"; [ "$RC" = 1 ] && grep -qF "placements result refused — $1" "$T/out" || fail "not refused (exit $RC) naming: $1"; [ ! -e "$D/result" ] && [ ! -e "$D/reviewed" ] || fail "a refused result was recorded ($1)"; }
ed() { sed "$2" "$D/$1" > "$T/x" && cat "$T/x" > "$D/$1"; }
refused 'part-1.reader: there is no such file'
good; ed part-1.reader 's/right=[0-9]*/right=1/'; refused 'part-1.reader line 6: its counts are'
good; ed part-1.reader 's/ | harm: it is shown late//'; refused 'part-1.reader line 4: not finding <n>'
good; ed part-1.reader 's/rule 7/rule 9/'; refused 'part-1.reader line 2: not finding <n>'
good; ed part-1.reader '1s/ROW-017, RULE-004/the footer/'; refused 'part-1.reader line 1: finding 1 names no test and no step of the plan'
good; ed part-1.reader 's/^finding 3/finding 2/'; refused 'part-1.reader line 4: finding 2 twice'
good; ed part-1.reader '1s/^/I looked at each./'; refused 'part-1.reader line 1: a line out of form'
good; { echo none; cat "$D/part-1.reader"; } > "$T/x"; cat "$T/x" > "$D/part-1.reader"; refused 'part-1.reader: none, and findings'
good; ed part-1.reader '/^placed/d'; refused 'part-1.reader: no placed line'
good; rm "$D/part-1.refuter"; refused 'part-1.refuter: there is no such file'
good; ed part-1.refuter 2d; refused 'part-1.refuter: no line of finding 2'
good; printf 'stands 1 | better: S02 | again\n' >> "$D/part-1.refuter"; refused 'part-1.refuter line 4: a second line of finding 1'
good; printf 'stands 4 | better: S02 | another\n' >> "$D/part-1.refuter"; refused 'part-1.refuter line 4: finding 4 is no finding of the first reader'
good; ed part-1.refuter 's/^refuted 2 | (b)/refuted 2 | (d)/'; refused 'part-1.refuter line 2: not refuted <n>'
# several rules in one finding, kept as written; none of nine
good; ed part-1.reader '1s/rule 2/rule 2, 4 and 5/'; p result "$D"; [ "$RC" = 0 ] || fail 'a finding that rests on several rules was refused'
grep -q "^finding${TB}stands${TB}1${TB}ROW-017, RULE-004${TB}S05${TB}2, 4 and 5${TB}" "$D/result" || { cp "$D/result" "$T/out"; fail 'several rules are not kept as written'; }
p show "$D"; grep -qF 'rule 2, 4 and 5: needs; a published ticket; one promise together' "$T/out" || fail 'the page does not name each of several rules'
rm -f "$D/result" "$D/reviewed"; good; ed part-1.reader '1s/rule 2/rule 2 and 9/'; refused 'part-1.reader line 1: not finding <n>'
# a refused first reader takes its second reader's file with it; a refused second reader keeps the first's
[ ! -e "$D/part-1.refuter" ] && [ -f "$D/part-1.reader" ] || fail 'a refused first reader leaves the second reader'"'"'s verdicts on the findings it replaces'
good; ed part-1.refuter 2d; refused 'part-1.refuter: no line of finding 2'; [ -f "$D/part-1.reader" ] || fail 'a refused second reader takes the first'"'"'s file'
# the join
good; p result "$D"; [ "$RC" = 0 ] || fail 'two outputs in form were refused'
R=$D/result; cp "$R" "$T/out"
grep -q "^placed round=1 listed=$N right=$((N - 4)) stands=1 partly=1 refuted=1 unjudged=1 at=20" "$R" || fail 'the counts are not the outputs'"'"
grep -qF "finding${TB}stands${TB}1${TB}ROW-017, RULE-004${TB}S05${TB}2${TB}wrong${TB}S03${TB}\"ROW-017 | behavior\" (INVENTORY.md, ROW-017)${TB}nothing there shows it${TB}\"nothing in S05\" (the plan, S05)" "$R" || fail 'the finding that stands is not kept with the refuter'"'"'s better place and why'
grep -q "^finding${TB}partly${TB}1${TB}ROW-012${TB}S02${TB}1${TB}doubt${TB}S04${TB}" "$R" || fail 'the finding that stands in part is not kept'
[ "$(grep -c '^finding' "$R")" = 2 ] || fail 'a refuted finding is in the result'
grep -q "^unjudged${TB}ROW-018${TB}the open question is not answered\$" "$R" || fail 'an unjudged line is lost'
plan() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
plan | cmp -s - "$D/reviewed" || fail 'reviewed is not the block judged'
# the second round: S05 gains ROW-012, so ROW-012 and the first round's findings' tests are listed
pt_rs 's/^\(step S02 .*\) ROW-012 /\1 /'; pt_rs 's/^\(step S05 .*rows:\) /\1 ROW-012 /'
p write "$D" --again; grep -qx 'listed 3' "$T/out" || { cat "$D/listed" >> "$T/out"; fail 'the second round does not list the three tests'; }
[ ! -e "$D/part-1.reader" ] || fail 'the second round keeps the first'"'"'s outputs'
printf 'finding 1 | ROW-017 | in S05 | rule 2 | wrong | better: S04 | quote: "q" (PRD.md, REQ-003) | harm: still\nplaced right=2 finding=1 unjudged=0\n' > "$D/part-1.reader"; printf 'stands 1 | better: S04 | still\n' > "$D/part-1.refuter"
p result "$D" --again; [ "$RC" = 0 ] || fail 'the second round was refused'
cp "$R" "$T/out"; grep -q '^placed round=1 ' "$R" && grep -q '^placed round=2 listed=3 right=2 stands=1 partly=0 refuted=0 unjudged=0 ' "$R" || fail 'a round'"'"'s placed line is lost'
[ "$(grep -c '^finding' "$R")" = 1 ] && grep -q "^finding${TB}stands${TB}2${TB}ROW-017${TB}" "$R" || fail 'the second round'"'"'s findings do not take the first'"'"'s place'
grep -q "^unjudged${TB}ROW-018${TB}" "$R" || fail 'the first round'"'"'s unjudged line, of a test the second does not list, is lost'
plan | cmp -s - "$D/reviewed" || fail 'reviewed is not the block the second round judged'
# a finding on a step alone, corrected by folding the step into another: its tests are read again where they stand now, and it goes
p write "$D" --all; good; ed part-1.reader '1s/ROW-017, RULE-004/S05/'; p result "$D"; [ "$RC" = 0 ] || fail 'the first round of a finding on a step alone was refused'
R5=$(sed -n 's/^step S05 .*| rows: \([^|]*[^| ]\) *|.*/\1/p' .vid/RUN-STATE.md | head -n 1); pt_rs '/^step S05 /d'; pt_rs "s/^\(step S04 .*rows:\) /\1 $R5 /"
p write "$D" --again; L=$(sed -n 's/^listed //p' "$T/out"); [ "${L:-0}" -gt 0 ] || fail 'the folded step'"'"'s tests are not listed'
printf 'none\nplaced right=%s finding=0 unjudged=0\n' "$L" > "$D/part-1.reader"; p result "$D" --again; [ "$RC" = 0 ] || fail 'the second round of it was refused'
cp "$R" "$T/out"; ! grep -q '^finding' "$R" || fail 'a finding corrected by taking its step away stays'
grep -q '^placed round=2 ' "$R" || fail 'the second round is not recorded'
# a third round is not recorded
cp "$R" "$T/r2"
for a in "write $D --again" "result $D --again"; do p $a; [ "$RC" = 0 ] && grep -q 'a third round of one review is not recorded' "$T/out" || fail "the third round ($a) exited $RC, or does not say it is not recorded"; done
cmp -s "$R" "$T/r2" || fail 'a third round was recorded'
# a part with no finding needs no refuter's file
p write "$D" --all; printf 'none\nplaced right=%s finding=0 unjudged=0\n' "$N" > "$D/part-1.reader"; p result "$D"; [ "$RC" = 0 ] && grep -q "^placed round=1 listed=$N right=$N stands=0 " "$R" || fail 'a part with no finding needs a refuter'
exit 0
