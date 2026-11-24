#!/bin/sh
# Purpose: selftest case — the switch takes over a project as its tickets were published (GM-3 S2, its case mode-take-over). On
# the fake gh, the toy made like the real project (fixtures/manual.sh mn_takeover): two rows the tickets quote missing from
# INVENTORY.md (one quoted less a field the writer cuts, its copy line holding a tab), no PLAN.md, a published step of stage 2
# by its ticket whose rows are of stage 1 and whose needs line names a step of stage 2, a retired row named by a range in a
# step not published, another step not published holding a retired row alone and built on by another, a team name in
# capitals, a row added after the tickets' commit, and one added and retired since on a side branch merged back. Without
# --from the switch asks for it, naming the two rows; with --from and no --take-over it lists them and asks the owner's yes,
# writing nothing, the panel saying so (FB-3 D2); with the yes, the take-over commit holds the two rows on the tickets' commit (and the copy's PLAN.md), kept
# under refs/vid/applied/1, and is the applied commit, the owner's words with it; HEAD gains the row no commit since has held,
# by a commit of its own, and the copy's PLAN.md; the retired rows are dropped and listed, the range written out less its
# row, the step left with none taken out and its place in another step's builds-on and needs line taken by its own builds-on,
# that step's fakes: losing the step it now builds on, and the page shows them; the step's rows are to place. A rerun with the same flags finds the take-over commit recorded and
# goes on: no second commit, no --take-over asked. The switch completes; the later row and the retirement are still pending;
# and the records restored into an empty folder hold refs/vid/applied/1 (GM M15). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-take-over: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
sw() { MN_RC=0; sh "$CHECKS/mode.sh" manual --register "$T/register" --applied "$MN_H" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
inv() { git show "$1:INVENTORY.md" | grep -c "^$2 " || :; }
# spec() <since>: the commits since that touch INVENTORY.md or PLAN.md (connect's refresh of checks/ may commit, and is no change of the spec)
spec() { git log --format=%H "$1..HEAD" -- INVENTORY.md PLAN.md; }
mn_takeover "$T/p"
# the commit-msg court a project runs, so the switch's commits at HEAD go through it
mkdir -p "$T/hooks"; cp "$CHECKS/hooks/commit-msg" "$T/hooks/"; git config core.hooksPath "$T/hooks"
H0=$(git rev-parse HEAD); TC=$T/copy

# 1. no --from: refused, asking for it, naming the two rows; nothing written
sw
[ "$MN_RC" = 5 ] || fail "the switch with rows the spec lacks and no --from exited $MN_RC, not 5"
grep -q '^need --from — .*ROW-022' "$T/mo" && grep -q '^need --from — .*ROW-023' "$T/mo" || fail 'the need for --from does not name the two rows'
[ -z "$(git for-each-ref refs/vid/)" ] && [ -z "$(spec "$H0")" ] && [ ! -s .vid/tw/applied ] || fail 'the refused switch wrote a commit, a ref or the applied version'

# 2. --from, no --take-over: the rows listed, the owner's yes asked; nothing written
sw --from "$TC"
[ "$MN_RC" = 1 ] && grep -q -- '--take-over' "$T/mo" || fail "the switch with --from and no --take-over exited $MN_RC, not refused asking the owner's yes"
grep -q "^take-over-row ROW-022 #$MN_N2 " "$T/mo" && grep -q "^take-over-row ROW-023 #$MN_N2 " "$T/mo" || fail 'the rows to take over are not listed'
grep -q "^found plan-md PLAN.md — the copy's" "$T/mo" || fail "PLAN.md is not found as the copy's"
grep -q "^found plan .* — .*copy.*RUN-STATE" "$T/mo" || fail "the plan block is not found in the copy's records"
[ -z "$(git for-each-ref refs/vid/)" ] && [ -z "$(spec "$H0")" ] && [ ! -s .vid/tw/applied ] || fail 'the take-over was made with no yes'
grep -qx "stop$(printf '\t')your yes to write 2 rows into the spec" .vid/face/wait || fail "the panel does not say the take-over's yes is needed: $(cat .vid/face/wait 2>/dev/null)"   # FB-3 D2

# 3. the yes: the take-over commit, the rows at HEAD, the copy's PLAN.md; it stops at the rows to place
TW='yes, write ROW-022 and ROW-023 into the spec as the tickets quote them'
sw --from "$TC" --take-over "$TW"
[ "$MN_RC" = 1 ] && grep -q 'rows are to place' "$T/mo" || fail "the switch with the yes exited $MN_RC, not stopped at the rows to place"
A=$(git rev-parse -q --verify refs/vid/applied/1) || fail 'no take-over commit under refs/vid/applied/1'
[ "$(sed -n 1p .vid/tw/applied)" = "$A" ] || fail 'the take-over commit is not the applied commit'
[ "$(git rev-parse "$A^1")" = "$MN_H" ] && [ -z "$(git rev-parse -q --verify "$A^2" || :)" ] || fail "the take-over commit is not made on the tickets' commit alone"
[ "$(git diff --name-only "$MN_H" "$A" | paste -sd ' ' -)" = 'INVENTORY.md PLAN.md' ] || fail "the take-over commit holds more than INVENTORY.md and the copy's PLAN.md: $(git diff --name-only "$MN_H" "$A" | paste -sd ' ' -)"
git diff "$MN_H" "$A" -- INVENTORY.md | grep '^[-+][^-+]' > "$T/d" || :
[ "$(grep -c . "$T/d")" = 2 ] && grep -qxF "+$MN_R22" "$T/d" && grep -qxF "+$MN_R23" "$T/d" || { cat "$T/d" >&2; fail "the take-over commit's inventory is not the tickets' commit's with the two copy lines alone"; }
git show "$A:PLAN.md" | cmp -s - "$TC/PLAN.md" || fail "the take-over commit does not hold the copy's PLAN.md"
git log -1 --format=%B "$A" | grep -qF "Owner: \"$TW\"" || fail "the take-over commit's message does not carry the owner's words"
grep "^mode-take-over commit=$A " .vid/metrics-events | grep -qF "$TW" || fail "no event line records the take-over commit with the owner's words"
[ "$(inv HEAD ROW-022)" = 1 ] && grep -qxF "$MN_R22" INVENTORY.md || fail 'HEAD does not hold ROW-022, the row no commit since has held'
[ "$(inv HEAD ROW-023)" = 0 ] || fail 'ROW-023, added and retired since the tickets were written, is back at HEAD'
grep -q '^held ROW-023 ' "$T/mo" || fail 'ROW-023 is not listed as held since, left retired'
git log --format=%H "$H0..HEAD" -- INVENTORY.md > "$T/ic"; [ "$(grep -c . "$T/ic")" = 1 ] || fail 'the rows are not added at HEAD by one commit'
[ "$(git diff --name-only "$(cat "$T/ic")^" "$(cat "$T/ic")" | paste -sd ' ' -)" = INVENTORY.md ] || fail 'the commit adding the rows at HEAD holds another file'
git show HEAD:PLAN.md | cmp -s - "$TC/PLAN.md" && [ -z "$(git status --porcelain -- PLAN.md INVENTORY.md)" ] || fail "HEAD does not hold the copy's PLAN.md, committed"
grep -qx 'dropped ROW-011 S04' "$T/mo" || fail 'the retired row in a step not published is not listed as dropped'
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md > "$T/blk"; grep -q 'ROW-011' "$T/blk" && fail 'the dropped row is still in the plan block'
# S04's range ROW-009..ROW-011, holding the dropped row, written out less it, in its rows and its needs line
grep -q '^step S04 .*rows: ROW-009 ROW-010 HOS-003 ' "$T/blk" && grep -q '^needs ROW-009 ROW-010 HOS-003 ' "$T/blk" || { cat "$T/blk" >&2; fail "S04's range is not written out less the dropped row"; }
# S07, left with no row, taken out with its needs line; S05 built on it builds on S07's own builds-on, S02, and needs it
grep -qx 'dropped ROW-025 S07' "$T/mo" && grep -qx 'dropped-step S07' "$T/mo" || fail 'the step left with no row is not listed as dropped'
grep -q 'S07\|ROW-025' "$T/blk" && { cat "$T/blk" >&2; fail 'the dropped step or its row is still in the plan block'; }
grep -q '^step S05 .*builds-on: S02 |' "$T/blk" && grep -q '^needs ROW-017 | S02$' "$T/blk" || { cat "$T/blk" >&2; fail "S05 does not build on and need S07's own builds-on in its place"; }
# S05's fakes: S02, the step it now builds on, taken out of it, the field left -
grep -q '^step S05 .*| fakes: -$' "$T/blk" && ! grep -q '^step S05 .*fakes: [^|]*S02' "$T/blk" || { cat "$T/blk" >&2; fail "S05 still fakes S02, which it now builds on"; }
grep -qF -- '- step S07, taken out of the plan' .vid/plan/PLAN-PAGE.md || fail 'the page does not show the dropped step'
grep -q 'ROW-011' .vid/plan/PLAN-PAGE.md || fail 'the page does not show the dropped row'
grep -q '^ *place ROW-002[[:space:]]' "$T/mo" && grep -q '^ *place ROW-018[[:space:]]' "$T/mo" || fail "the published step's rows of another stage are not to place"
HT=$(git rev-parse HEAD)

# 4. a rerun with the same flags, no --take-over: the take-over commit found recorded; no second commit, no yes asked; the page
sw --from "$TC" --to-place 'yes: ROW-002 and ROW-018 go with S06, of stage 2'
[ "$MN_RC" = 1 ] && grep -q 'the page is written' "$T/mo" || fail "the rerun exited $MN_RC, not stopped at the page"
grep -q "^found applied $A — .*take-over" "$T/mo" || fail 'the rerun did not find the take-over commit recorded'
grep -q "^found applied $A — .*the take-over commit made on $MN_H," "$T/mo" || fail "the rerun's found applied line does not name the tickets' commit as the one the take-over commit was made on"
grep -qE -- '--take-over|^take-over-row ' "$T/mo" && fail 'the rerun asked for the take-over again'
[ "$(git for-each-ref refs/vid/applied/ | grep -c .)" = 1 ] && [ -z "$(spec "$HT")" ] || fail 'the rerun made a second take-over commit or a commit at HEAD'
grep -q 'ROW-011' .vid/plan/PLAN-PAGE.md || fail 'the page of the rerun does not show the dropped row'

# 5. the ratification: the switch completes; the later row and the retirement still pending
sw --from "$TC" --to-place 'yes: ROW-002 and ROW-018 go with S06, of stage 2' --words 'yes, ratify the taken-over plan'
[ "$MN_RC" = 0 ] && grep -qx 'mode: GitHub manual, recorded' "$T/mo" || fail "the switch exited $MN_RC, not completed"
[ "$(sed -n 1p .vid/tw/applied)" = "$A" ] && [ "$(git for-each-ref refs/vid/applied/ | grep -c .)" = 1 ] || fail 'the completed switch moved the applied commit or made another'
[ "$(mode_)" = manual ] || fail 'github-mode is not manual'
sh "$CHECKS/next.sh" pending > "$T/pd" 2>&1 || { cat "$T/pd" >&2; fail 'next.sh pending failed'; }
grep -q '^pending	added	ROW-024$' "$T/pd" || { cat "$T/pd" >&2; fail 'ROW-024, added after the tickets were written, is no longer pending'; }
grep -q '^pending	retired	ROW-023$' "$T/pd" || { cat "$T/pd" >&2; fail "ROW-023's retirement is no longer pending"; }
grep -q 'ROW-022' "$T/pd" && { cat "$T/pd" >&2; fail 'ROW-022, taken over, reads as pending'; }
grep -v '^owner/vid-state ' "$FAKEGH/writes" > "$T/w" && { cat "$T/w" >&2; fail 'a write went to a repository but state-repo:'; }
[ -z "$(mn_lock)" ] || fail 'the lock is held after the switch'

# 6. the records restored into an empty folder hold the take-over commit (GM M15)
mkdir "$T/new"; cd "$T/new"; sh "$CHECKS/github.sh" state-restore owner/vid-state > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the records could not be restored into an empty folder'; }
[ "$(git rev-parse -q --verify refs/vid/applied/1)" = "$A" ] && [ "$(sed -n 1p .vid/tw/applied)" = "$A" ] && git cat-file -e "$A^{commit}" || fail 'the new folder does not hold the take-over commit under refs/vid/applied/1'
echo 'mode-take-over: ok'
