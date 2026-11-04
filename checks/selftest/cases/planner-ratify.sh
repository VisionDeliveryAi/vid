#!/bin/sh
# Purpose: selftest case — nothing is ratified with a flag open, P6 (v0.26.10.12.2.1 R8;
# v0.26.10.12.2.2 R8: the first plan ratified, and kept through recorded changes). On
# the planner's toy (fixtures/planner-toy.sh) `planner.sh ratify` is refused, naming the reason and recording nothing:
# with no review; with a check flag open (INV-002's appended protection row HOS-005 deleted); with a stale review (PLAN.md changed
# after it); with a finding unanswered — also after a later review of the same plan finds nothing, the page still
# showing it — until `answer <n> keep` records the owner's words. A review naming an inventory row is refused whole. A
# ratification records the owner's words verbatim with the spec files' hash and the plan's; `ratified` exits 0 until
# an unrecorded edit of the block, or PLAN.md, STAGES.md, INVENTORY.md, GRADING-CHECKLIST.md or ARCHITECTURE.md
# changes. It holds after a recorded split; it ends after a recorded drop that leaves a row in no step. ratify is
# refused for a plan the page has not shown, a recorded change among them. Words on two lines, and an answer to no
# open finding, are refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-ratify: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
pl() { sh "$CHECKS/planner.sh" "$@" > "$T/out" 2>&1; }
refused() { if pl ratify --words 'yes'; then fail "ratify recorded: $1"; fi; grep -qF "ratify refused — $1" "$T/out" || fail "the refusal does not name: $1"
  [ ! -s .vid/plan/ratified ] || fail "a refused ratify wrote .vid/plan/ratified ($1)"; }
printf 'none\n' > "$T/none"; printf 'finding RULE-004 | 1: vague\n' > "$T/hit"; printf 'finding ROW-002 | 1: vague\n' > "$T/inv"
fresh; refused "no review has this plan's hash"
fresh; pt_del HOS-005; pl review --in "$T/none"; refused 'a check flag is open: protection INV-002'
fresh; pl review --in "$T/none"; printf '\n' >> PLAN.md; refused "no review has this plan's hash"
fresh; if pl review --in "$T/inv"; then fail 'a finding on an inventory row was recorded'; fi; grep -qF 'ROW-002 is no row ViD added' "$T/out" || fail 'the refusal does not name the row'
fresh; pl review --in "$T/hit"; refused 'finding 1 on RULE-004 has no answer'
pl review --in "$T/none"; refused 'finding 1 on RULE-004 has no answer'
sh "$CHECKS/planner.sh" page > /dev/null 2>&1; grep -q '^- finding 1 on RULE-004, not answered: ' .vid/plan/PLAN-PAGE.md || fail 'a later clean review took the finding off the page'
if pl answer 2 keep --words 'keep it'; then fail 'an answer to no open finding was recorded'; fi
pl answer 1 keep --words 'keep it as written' || fail 'the answer was refused'
grep -q '^answer 1 keep hash=.* words=keep it as written$' .vid/plan/review || fail "the answer does not carry the owner's words"
if pl ratify --words 'line one
line two'; then fail 'words on two lines were recorded'; fi
if pl ratified; then fail 'ratified before any ratification'; fi
W='Yes — ratify it "as it is", $HOME and 100% \n too'
rm -f .vid/plan/paged; refused 'the newest page did not show this plan'; pl page
pl ratify --words "$W" || fail 'a clean, reviewed, answered plan was refused'
H=$(sh "$CHECKS/planner.sh" hash); P=$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events)
L=$(cat .vid/plan/ratified); [ "${L#ratified hash=$H plan=$P at=}" != "$L" ] || fail 'the ratification lacks the spec files'"'"' hash or the plan'"'"'s'
[ "${L#* words=}" = "$W" ] || fail "the recorded words differ from the owner's: ${L#* words=}"
pl ratified || fail 'ratified does not exit 0 on the ratified plan'
pt_set 'step S05' 'step S05 | name: synonym search | modules: search | builds-on: S02 | rows: ROW-017 | lane: devagent'
if pl ratified; then fail 'ratified exits 0 after an unrecorded edit of the block'; fi
grep -q 'not the newest recorded plan' "$T/out" || fail 'the unrecorded edit is not named'
go() { fresh; pl review --in "$T/none"; pl page; pl ratify --words 'yes' || fail 'the toy was refused'; }
for f in PLAN.md STAGES.md INVENTORY.md GRADING-CHECKLIST.md ARCHITECTURE.md; do go; printf '\n' >> "$f"
  if pl ratified; then fail "ratified exits 0 after $f changed"; fi; done
# a recorded split keeps it, and needs no new ratification; a recorded drop that leaves a row in no step ends it
ch() { sh "$CHECKS/plan.sh" change "$@" > "$T/out" 2>&1 || fail "plan.sh change $1 was refused"; }
go; pt_set 'step S04' 'step S04 | name: limits and backups | modules: digest ingest | builds-on: S02 S03 | rows: ROW-002 ROW-009 ROW-011 HOS-003 | lane: devagent'
pt_after 'step S04' 'step S06 | name: failures and the data move | modules: digest | builds-on: S02 | rows: ROW-018 DIF-001 RULE-004 | lane: devagent'
ch split 'S04 in two' --trigger discovered-dependency --evidence step:S04 --expect 'two smaller tickets'
pl ratified || fail 'ratified ends after a recorded split'
pt_set 'step S05' 'step S05 | name: synonym search | modules: search | builds-on: S02 | rows: ROW-017 | lane: devagent'
ch other 'S05 renamed; earlier hash=deadbeef was unclear' --trigger discovered-dependency --evidence step:S05 --expect 'the same rows'
pl ratified || fail "ratified reads a hash= inside the why: $(cat "$T/out")"
if pl ratify --words 'again'; then fail 'ratify passed a recorded change the page has not shown'; fi
grep -qF 'the newest page did not show this plan' "$T/out" || fail 'the unshown change is not named'
go; pt_del 'step S05'; ch drop 'S05 out' --trigger scope-change --evidence step:S04 --expect 'one step fewer'
if pl ratified; then fail 'ratified holds after a recorded drop that leaves ROW-017 in no step'; fi
grep -q 'check flags the plan' "$T/out" || fail 'the drop is not named as a check flag'
exit 0
