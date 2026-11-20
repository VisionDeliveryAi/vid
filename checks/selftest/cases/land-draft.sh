#!/bin/sh
# Purpose: selftest case — a counted change landed during a run (v0.26.10.25.5, R1–R5), checks/land.sh on the writer's toy and the
# fake gh. A draft commits nothing and counts every line by its id (a reset journey with its transitions, a reset hostility row, a
# reset skeleton row, an added row in its step, five reached rows, a record that owes nothing); the Q line asks it; a pause and a
# stop wait for continue; a dry run refused by rule A's ceiling lands nothing; a draft whose base moved is stale; a module-table
# edit lands through the same door with zero rows; the landing's three commits go through the hooks, the plan change is accepted,
# reratify opens the writer's gate, and no stage event comes from the door, so plan.sh start still works. Then R4's records: the
# landed lines, counts, limits, halted, record, state and the handed row line gone, a reset ruling, a fix line not yet published
# without the row and its close's key moved, reached lines keyed by the landing (the same requirement reached twice), and the
# writer: the open ticket amended to drop the reset rows and gaining none, the new rows' ticket owed at once beside it, the skeleton's
# step ticketed for its landed row alone. R5: the closed step reopened and its close ask withdrawn, its issue closed. 0.26.10.29.5
# (DP-1 R7): each landing commit's Decisions: line states what it admits, the draft's why and its count line, a why holding a per cent
# sign, quotes and a backslash kept whole. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "land-draft: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"
# the count before any record: an invariant changed reaches the rows citing it and its protection
sed 's/^INV-001 | invariant | T0 | A job present in both feeds appears once in the listing store./&, under its first source/' PRD.md > "$T/pi.md"
sh "$CHECKS/inventory.sh" impact --tickets --prd "$T/pi.md" > "$T/out" 2>&1 || fail 'the count failed with no records'; grep -qx 'reached ROW-005,ROW-013,HOS-001' "$T/out" || fail 'a changed invariant reached no row'
tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
LS=$CHECKS/land.sh; QS=$CHECKS/queue.sh; TAB=$(printf '\t'); R=owner/code
printf 'none\n' > "$T/rv"   # v0.26.10.26.7 (R5): every draft has its review
ld() { RC=0; if [ "$1" = draft ]; then shift; set -- draft --review "$T/rv" "$@"; fi; sh "$LS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; }
tw_start S02 || fail "S02 was refused: $(cat "$T/start")"; tw_post step S02 || fail "S02's ticket: $(cat "$T/werr")"; N2=$TW_N
# the records a landing clears, and a close of S01 out (its ask) beside S01's closed line
mkdir -p .vid/decide/close/S01/1 .vid/decide/close/S02/1
printf 'ROW-005\theld\tfailing\t4\tabc\t2026-11-09T10:00:00Z\nROW-005-T1\theld\tfailing\t4\tabc\t2026-11-09T10:00:00Z\nHOS-001\taccepted\taccepted\t4\tabc\t2026-11-09T10:00:00Z\nROW-012\tfailing\tfailing\t4\tabc\t2026-11-09T10:00:00Z\n' > .vid/decide/state
printf 'ROW-005 abc\nROW-005-T1 abc\nROW-012 abc\n' > .vid/decide/counts; printf 'ROW-005 4\n' > .vid/decide/limits; printf '4\tROW-005\t\n' > .vid/decide/halted; printf 'ROW-005\nROW-012\n' > .vid/decide/record
FL='fix ROW-005 ROW-012 | ROW-005: the feed read in chromium; ROW-012: the newest first in chromium | close #9 of S02: req-9-p1c1-1'
tw_hand "$FL"; K0=$(printf '%s' "$FL" | cksum | cut -d' ' -f1); printf '%s\tROW-005 ROW-012\n' "$K0" > .vid/decide/close/S02/1/fixes
FH='fix HOS-001 | HOS-001: one listing in chromium | close #8 of S03: req-8-p1c1-1'; tw_hand "$FH"; KH=$(printf '%s' "$FH" | cksum | cut -d' ' -f1); mkdir -p .vid/decide/close/S03/1; printf '%s\tHOS-001\n' "$KH" > .vid/decide/close/S03/1/fixes
I1=$(gh issue create -R $R --title 'Close run: S01' --body b --label run | sed 's/.*\///'); printf 'issue\t%s\ncommit\t0123\nchunk\tp1c1\tchromium\tROW-003 ROW-004\n' "$I1" > .vid/decide/close/S01/1/ask
# the change, in the working tree: REQ-001 amended; ROW-005 (a journey), HOS-001 and ROW-003 (S01's) reset; ROW-021 added in S02; DIF-004 a record
amend() { SK=${1:-yes}; { cat PRD.md; printf '\n### 2026-11-09 (the self-test)\n\n```vid-prd\n'; grep '^REQ-001 |' PRD.md | sed 's/^REQ-001 |/REQ-001 AMENDED |/; s/arrive in one day/arrive in one day, or one is sent before eight/'; printf '```\n'; } > "$T/p" && cp "$T/p" PRD.md
  awk '/^ROW-005 \|/ { sub(/the job stored once/, "the job stored once and dated") } /^ROW-003 \|/ && SK == "yes" { sub(/ shows the saved search/, " shows the saved search at once") } /^hostility \| HOS-001 \|/ { sub(/expect exactly one listing/, "expect one listing, never two") }
    /^ROW-020 \|/ { print; print "ROW-021 | behavior | REQ-001 | (process) | n/a | A job read twice in a day is listed once with its first read time. Fails if a second read moves its time. | REQ-001 | owed: spec-only — ticket"; next }
    /^difference \| DIF-003 \|/ { print; print "difference | DIF-004 | the clock | a fixed clock | the real clock | the digest reads only the date"; next } { print }' SK="$SK" INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md; }
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | sed 's/^\(step S02 .*rows: [^|]*RULE-005\) /\1 ROW-021 /; s/^\(needs ROW-001 .*RULE-005\) /\1 ROW-021 /' > "$T/plan"
grep -q 'RULE-005 ROW-021 |' "$T/plan" || fail "the plan block was not drafted: $(grep 'step S02' "$T/plan")"
amend no; ld draft --why 'REQ-001 amended, and ROW-021 added to S02, in the owner words' --plan "$T/plan"; [ "$RC" = 0 ] || fail "the draft failed ($RC)"   # v0.26.10.26.7 (R4): S01's row apart, so it can land
ok '^draft 1$'; ok '^impact reset=2 added=1 reached=6 records=1$'; ok '^reset ROW-005,HOS-001$'; ok '^added ROW-021$'; ok '^reached ROW-001,ROW-003,ROW-004,ROW-008,ROW-012,RULE-005$'; ok '^record DIF-004$'
ok '^state ROW-005 held$'; ok '^state ROW-003 accepted$'; ok '^words This changes 2 rows, adds 1 in S02, and reaches 6 more: ROW-001, ROW-003, ROW-004, ROW-008, ROW-012, RULE-005. Land it?$'
[ -z "$(git status --porcelain -- PRD.md INVENTORY.md)" ] || fail 'the draft left the working tree changed'; [ "$(git rev-parse HEAD)" = "$(cat .vid/decide/drafts/1/base)" ] || fail 'the draft committed'
grep -q "^reset${TAB}ROW-005-T3${TAB}transition" .vid/decide/drafts/1/sets || fail "a journey's transitions do not follow it"
# asked once; a pause waits for continue, the line staying open
qs ask draft 1; QN=$(sed -n 's/^asked \(Q[0-9]*\) draft 1$/\1/p' "$T/out"); [ -n "$QN" ] || fail 'the draft was not asked'
grep -q "^- $QN · asked .* · gates the spec · draft 1 by SP: REQ-001 amended.*Land it? · answer yes to land it, or no" .vid/RUN-STATE.md || fail "no Q line: $(grep "^- $QN" .vid/RUN-STATE.md)"
sh "$QS" control pause 'hold on' > /dev/null; qs answer "$QN" yes 'Yes, land it'; [ "$RC" = 3 ] || fail "a landing while paused was not refused ($RC)"
grep -q "^- $QN · .*waits for continue" .vid/RUN-STATE.md || fail 'the Q line does not say it waits'; [ ! -f .vid/decide/landed ] || fail 'something landed while paused'
sh "$QS" control continue 'go on' > /dev/null
# rule A's ceiling: S02 at 11 rows, its ceiling 11, so ROW-021 refuses the dry run; nothing is committed
H0=$(git rev-parse HEAD); printf 'unverified-rows=11\n' > .vid/budget; ld 1 --words 'Yes, land it'; [ "$RC" = 1 ] || fail "the dry run over rule A was not refused ($RC)"
ok 'dry run'; [ "$(git rev-parse HEAD)" = "$H0" ] && [ ! -s .vid/decide/landed ] || fail 'a refused dry run landed something'; rm -f .vid/budget
# a module-table edit, drafted on the same base: zero rows, one yes; it lands first, so draft 1 is stale
sed 's/^| web | the pages |/| web | the pages and the operator pages |/' ARCHITECTURE.md > "$T/a"; ! cmp -s "$T/a" ARCHITECTURE.md || fail 'no module-table edit'; cp "$T/a" ARCHITECTURE.md
# 0.26.10.29.5 (DP-1 R7): its why holds a per cent sign, a printf directive, both quotes and a backslash, which the Decisions: line keeps
W2='the module table as the merge of S01 shows it, 100% "as is", the owner'"'"'s %s \n'
ld draft --why "$W2"; ok '^impact reset=0 added=0 reached=0 records=0$'
ld 2 --words 'Yes, the module table'; [ "$RC" = 0 ] || fail "the module-table edit did not land ($RC)"; ok '^landed 2 at '
[ "$(git log -1 --format=%s)" = "Land draft 2, the architecture: $W2" ] || fail "the module-table commit: $(git log -1 --format=%s)"
[ "$(git log -1 --format=%B | grep '^Decisions:')" = "Decisions: admits $W2 (impact reset=0 added=0 reached=0 records=0) — the owner's yes" ] || fail "the landing's Decisions: line: $(git log -1 --format=%B | grep '^Decisions:')"
sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || fail 'the gate is shut after the module-table landing'
ld 1 --words 'Yes, land it'; [ "$RC" = 4 ] || fail "a stale draft was not refused ($RC)"; ok 'stale'
# redrafted on the new HEAD, through the hooks, PLAN.md too (a standing line): S01's ROW-003 is reset, so rule B refuses S02's new row; nothing lands
mkdir -p "$T/hk"; printf '#!/bin/sh\necho "pre-commit $(pwd)" >> "%s/hooks.log"\n[ ! -f "%s/refuse" ] || { echo "a stub hook refuses" >&2; exit 1; }\n' "$T" "$T" > "$T/hk/pre-commit"; chmod +x "$T/hk/pre-commit"
git config core.hooksPath "$T/hk"; H1=$(git rev-parse HEAD)
amend; sed 's/^standing work | RULE-005$/standing work | RULE-005, ROW-021/' PLAN.md > "$T/pl" && cp "$T/pl" PLAN.md
ld draft --why 'REQ-001 amended, and ROW-021 added to S02, in the owner words' --plan "$T/plan"; [ "$RC" = 1 ] || fail "rule B did not refuse the draft ($RC)"   # v0.26.10.26.7 (R4): at draft time
ok 'refused — the draft could not land, so it is not made, and the tree is kept to correct: .*plan change was refused'; ok 'rule B'; [ ! -d .vid/decide/drafts/3 ] || fail 'a draft rule B refuses was made'
[ "$(git rev-parse HEAD)" = "$H1" ] && [ ! -s .vid/decide/landed ] && [ -n "$(git status --porcelain -- PRD.md INVENTORY.md PLAN.md)" ] || fail 'the refused draft did not keep the tree, or landed something'; git checkout -q -- PRD.md INVENTORY.md PLAN.md
# S01's row apart: lands by the queue's yes, in three commits
amend no; sed 's/^standing work | RULE-005$/standing work | RULE-005, ROW-021/' PLAN.md > "$T/pl" && cp "$T/pl" PLAN.md
ld draft --why 'REQ-001 amended, and ROW-021 added to S02, in the owner words' --plan "$T/plan"; ok '^draft 3$'; ok '^impact reset=2 added=1 '
: > "$T/refuse"; : > "$T/hooks.log"; ld 3 --words 'Yes, land it'; [ "$RC" = 1 ] && grep -q 'a stub hook refuses' "$T/out" || fail "a hook's refusal did not refuse the dry run ($RC)"
[ "$(git rev-parse HEAD)" = "$H1" ] && [ ! -s .vid/decide/landed ] && [ -z "$(git status --porcelain -- PRD.md INVENTORY.md PLAN.md)" ] || fail "a hook's refusal landed something"
! grep -qv "pre-commit .*/sc$" "$T/hooks.log" || fail "a real commit was tried: $(cat "$T/hooks.log")"; rm -f "$T/refuse"; : > "$T/hooks.log"
qs ask draft 3; QN=$(sed -n 's/^asked \(Q[0-9]*\) draft 3$/\1/p' "$T/out"); qs answer "$QN" yes 'Yes, land it'; [ "$RC" = 0 ] || fail "draft 3 did not land ($RC)"
ok '^landed 3 at '; L=$(sed -n 's/^landed 3 at \([0-9a-f]*\):.*/\1/p' "$T/out"); ! grep -q "^- $QN " .vid/RUN-STATE.md || fail 'the landed draft stays a Q line'
[ "$(git log --format=%s "$H1..HEAD" | paste -sd '|' -)" = 'Land draft 3, the plan file: REQ-001 amended, and ROW-021 added to S02, in the owner words|Land draft 3, the law: REQ-001 amended, and ROW-021 added to S02, in the owner words|Land draft 3, the PRD: REQ-001 amended, and ROW-021 added to S02, in the owner words' ] || fail "the commits: $(git log --oneline "$H1..HEAD")"
[ "$(grep -c '/sc$' "$T/hooks.log")" = 3 ] && [ "$(grep -vc '/sc$' "$T/hooks.log")" = 3 ] || fail "the hooks did not run on the scratch copy's and the real commits: $(cat "$T/hooks.log")"
# 0.26.10.29.5 (DP-1 R7): each of the landing's commits states what it admits: the draft's why and its count line, the owner's yes
DL3="Decisions: admits REQ-001 amended, and ROW-021 added to S02, in the owner words ($(sed -n 1p .vid/decide/drafts/3/count)) — the owner's yes"
[ "$(git log --format=%B "$H1..HEAD" | grep -c '^Decisions:')" = 3 ] && [ "$(git log --format=%B "$H1..HEAD" | grep '^Decisions:' | sort -u)" = "$DL3" ] || fail "the landing's Decisions: lines: $(git log --format=%B "$H1..HEAD" | grep '^Decisions:')"
! git log --format=%B "$H1..HEAD" | grep -q '^Decisions: none' || fail "a landing's commit says Decisions: none"
[ "$(git rev-parse --short=12 HEAD)" = "$L" ] || fail "the landing names $L, not HEAD"; grep -q 'plan-change what=rows .*why="the owner.s yes to draft 3' .vid/metrics-events || fail 'no plan change'
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'not ratified after the landing'; sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || fail 'the gate is shut after the landing'
grep -q "^ratified hash=.* base=$(printf %.12s "$H1") to=$L words=Yes, land it$" .vid/plan/ratified || fail 'no reratification'
! grep '^stage ' .vid/metrics-events | tail -n 1 | grep -qv 'name=plan' || fail "a stage event came from the door: $(grep '^stage ' .vid/metrics-events | tail -n 1)"
# R4's records
for i in ROW-005 ROW-005-T1 ROW-005-T3 HOS-001 ROW-021; do grep -q "^$i $L " .vid/decide/landed || fail "$i is not landed"; done; ! grep -q '^DIF-004 ' .vid/decide/landed || fail 'a record was landed'
grep -q "${TAB}ROW-005${TAB}reset${TAB}landed at $L" .vid/decide/rulings || fail 'no reset ruling'
! grep -q '^ROW-005' .vid/decide/counts .vid/decide/limits .vid/decide/record .vid/decide/state && ! grep -q "${TAB}ROW-005${TAB}" .vid/decide/halted || fail 'a reset row kept its records'
grep -q '^ROW-012' .vid/decide/counts && grep -q '^ROW-012' .vid/decide/state && grep -q '^row ROW-003 ' .vid/tw/handed || fail "another row's records went"
F2='fix ROW-012 | ROW-012: the newest first in chromium | close #9 of S02: req-9-p1c1-1'; grep -qxF "$F2 | stand-in: the self-test" .vid/tw/handed || fail "the fix line: $(grep '^fix' .vid/tw/handed)"
[ "$(cat .vid/decide/close/S02/1/fixes)" = "$(printf '%s' "$F2" | cksum | cut -d' ' -f1)${TAB}ROW-012" ] || fail "the close's fix key: $(cat .vid/decide/close/S02/1/fixes)"
# a fix line that a landing empties stays in its close's fixes, owing nothing (another step's close is owed again)
! grep -q '^fix HOS-001 ' .vid/tw/handed && [ "$(cat .vid/decide/close/S03/1/fixes)" = "$KH$TAB" ] || fail "the emptied fix line: $(cat .vid/decide/close/S03/1/fixes)"
grep -qx "reached ROW-001 REQ-001 $L | stand-in: SP" .vid/tw/handed && grep -qx "reached ROW-008 REQ-001 $L | stand-in: SP" .vid/tw/handed || fail "no reached lines: $(grep '^reached' .vid/tw/handed)"
# the writer: S02's open ticket drops the reset rows and gains none; the landed rows owe their own ticket at once; the skeleton's step for its row
sh "$CHECKS/github.sh" spec-export > /dev/null 2>&1 || fail 'no export'; sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || fail 'due failed'
ok "^amend $N2$"; ! grep -q '^new step S02$' "$T/out" || fail "the landed rows are owed beside the open ticket #$N2: $(cat "$T/out")"   # 0.26.10.28.10 (R1): they wait for it
sh "$CHECKS/writer.sh" write amend "$N2" > "$T/out" 2>&1 || fail 'the amendment was refused'; M=$(sed -n 1p .vid/tw/out/amend-$N2.meta)
case ",$(printf '%s' "$M" | tr ' ' '\n' | sed -n 's/^rows=//p')," in *,ROW-005,*|*,HOS-001,*|*,ROW-021,*) fail "the open ticket keeps or gains a landed row: $M" ;; esac
tw_post amend "$N2" || fail "the amendment: $(cat "$T/werr")"
# R1: once #N2 is merged the landed rows are owed, on main as it now is, as a follow-up of #N2: its own title, no T5
tw_close "$N2"; sh "$CHECKS/github.sh" tw-sync > /dev/null 2>&1; sh "$CHECKS/writer.sh" due > "$T/out" 2>&1 || fail 'due failed'; ok '^new step S02$'
tw_post step S02 || fail "the landed rows' ticket: $(cat "$T/werr")"
grep -qx -- "- follows: #$N2" "$TW_F" || fail "the landed rows' ticket names no follows: #$N2: $(sed -n '/^## Header/,/^## The step/p' "$TW_F")"
sed -n 1p "$TW_F" | grep -q '^# Follow-up ticket S02: ' || fail "the follow-up's title: $(sed -n 1p "$TW_F")"
grep -q "This step had its grade at its first ticket, #$N2" "$TW_F" || fail "the follow-up does not name the ticket that had the grade: $(grep 'This ticket follows' "$TW_F")"   # the step's grade was at its first ticket
! grep -q '^- T5 ' "$TW_F" && grep -q '^- T4 ' "$TW_F" || fail "the follow-up's asks: $(sed -n '/^## Asks/,$p' "$TW_F")"
N3=$TW_N; sh "$CHECKS/writer.sh" write amend "$N3" > "$T/out" 2>&1 || fail "the follow-up's amendment was refused"; grep -qx -- "- follows: #$N2" ".vid/tw/out/amend-$N3.md" && ! grep -q '^- T5 ' ".vid/tw/out/amend-$N3.md" || fail 'an amended follow-up lost its follows: line, or asks T5'
[ "$(sed -n 's/^- rows: //p' "$TW_F" | head -n 1)" = 'ROW-005, HOS-001, ROW-021' ] || [ "$(sed -n 1p "${TW_F%.md}.meta" | tr ' ' '\n' | sed -n 's/^rows=//p')" = 'HOS-001,ROW-005,ROW-021' ] || [ "$(sed -n 1p "${TW_F%.md}.meta" | tr ' ' '\n' | sed -n 's/^rows=//p')" = 'ROW-005,HOS-001,ROW-021' ] || fail "the new ticket's rows: $(sed -n 1p "${TW_F%.md}.meta")"
grep -q " reached=[^ ]*ROW-004" "${TW_F%.md}.meta" && grep -q " reached=[^ ]*ROW-001" .vid/tw/out/amend-$N2.meta || fail "the reached rows are not carried: $(sed -n 1p "${TW_F%.md}.meta"); $(sed -n 1p .vid/tw/out/amend-$N2.meta)"
# R5: ROW-003, S01's, reset alone: S01 reopened, its ask withdrawn, its issue closed with a comment, its handed row line dropped.
# 0.26.10.29.2 (R9): only a step of a stage with no candidate reopens, so stage 0's candidate is out for this landing
# (land-closed-kept.sh holds the other path)
awk '/^ROW-003 \|/ { sub(/ shows the saved search/, " shows the saved search at once") } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
grep -v '^candidate 0 ' .vid/tw/handed > "$T/hc" && cp "$T/hc" .vid/tw/handed
ld draft --why 'ROW-003 says at once'; ok '^impact reset=1 added=0 '; ld 4 --words 'Yes, S01 too'; [ "$RC" = 0 ] || fail "draft 4 did not land ($RC)"; ok '^reopened S01$'; ok '^withdrawn S01 1$'
tw_hand 'candidate 0'
L5=$(sed -n 's/^landed 4 at \([0-9a-f]*\):.*/\1/p' "$T/out"); ! grep -q '^row ROW-003 ' .vid/tw/handed || fail 'the handed row line stayed'
! grep -q '^closed S01 ' .vid/tw/handed || fail 'S01 stayed closed'; [ -f .vid/decide/close/S01/1/withdrawn ] || fail 'the ask was not withdrawn'
grep -q CLOSED "$T/gh/issues/$I1/state" 2>/dev/null || fail 'the ask issue stayed open'; grep -rq "vid: withdrawn. The landing $L5" "$T/gh/issues/$I1/comments" || fail 'no withdrawal comment'
sh "$CHECKS/close.sh" out > "$T/out" 2>&1; ! grep -q 'S01' "$T/out" || fail 'a withdrawn ask is still out'
sh "$CHECKS/github.sh" spec-export > /dev/null 2>&1; sh "$CHECKS/writer.sh" due > "$T/out" 2>&1; ok '^new step S01$'
tw_post step S01 || fail "the skeleton's step: $(cat "$T/werr" "$T/post")"; [ "$(sed -n 1p "${TW_F%.md}.meta" | tr ' ' '\n' | sed -n 's/^rows=//p')" = ROW-003 ] || fail "the skeleton step's ticket: $(sed -n 1p "${TW_F%.md}.meta")"
sh "$CHECKS/writer.sh" due > "$T/out" 2>&1; ! grep -q '^new step S0[12]$' "$T/out" || fail "the landed rows are owed again: $(cat "$T/out")"
# admission still judges, the gate on with no stage of the door's own: S03 waits for S01, reopened (rule B)
sed 's/^open-tickets: 2$/open-tickets: 9/' .vid/tw/settings > "$T/st" && cp "$T/st" .vid/tw/settings; ! tw_start S03 && grep -q 'S03 builds on S01, which is not closed' "$T/start" || fail "admission did not judge S03 by rule B after S01 reopened: $(cat "$T/start")"
# the same requirement reached again by a second landing: a second line, keyed by its landing
{ cat PRD.md; printf '\n### 2026-11-10 (the self-test)\n\n```vid-prd-answers\nA-201 | human | 2026-11-10 | Q: how early? | A: never before seven | settles: REQ-001\n```\n\n```vid-prd\n'; grep '^REQ-001 AMENDED |' PRD.md | sed 's/before eight/before seven/'; printf '```\n'; } > "$T/p" && cp "$T/p" PRD.md
ld draft --why 'REQ-001 amended again'; ok '^reached ROW-001,ROW-003,ROW-004,ROW-005,ROW-008'; ld 5 --words 'Yes again'; [ "$RC" = 0 ] || fail "draft 5 did not land ($RC)"; L4=$(sed -n 's/^landed 5 at \([0-9a-f]*\):.*/\1/p' "$T/out")
[ "$(grep -c '^reached ROW-001 REQ-001 ' .vid/tw/handed)" = 2 ] && grep -qx "reached ROW-001 REQ-001 $L4 | stand-in: SP" .vid/tw/handed || fail "the second reach: $(grep '^reached ROW-001' .vid/tw/handed)"
git log -1 --format=%B | grep -q '^Answers: .*A-201' || fail "the landing does not cite the answer its PRD adds: $(git log -1 --format=%B)"
# v0.26.10.26.7 (R4): a draft whose added row is in no step is refused at draft time, naming the check; the tree is kept
H5=$(git rev-parse HEAD); awk '/^ROW-020 \|/ { print; print "ROW-022 | behavior | REQ-001 | (process) | n/a | A job is listed with its source. Fails if a listing names no source. | REQ-001 | owed: spec-only — ticket"; next } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
ld draft --why 'ROW-022 added, in no step'; [ "$RC" = 1 ] || fail "a draft whose row is in no step was made ($RC)"; ok 'not made, and the tree is kept to correct: the dry run.s planner.sh check flags the plan'
[ ! -d .vid/decide/drafts/6 ] && grep -q '^ROW-022 ' INVENTORY.md && [ "$(git rev-parse HEAD)" = "$H5" ] || fail 'the refused draft was made, or the tree was put back'; git checkout -q -- INVENTORY.md
# --replaces: draft 6 asked, then redrafted as 7; 6's Q line closes and 7 is asked afresh
sed 's/^| web | the pages and the operator pages |/| web | the pages, the operator pages |/' ARCHITECTURE.md > "$T/a" && cp "$T/a" ARCHITECTURE.md; ld draft --why 'the module table, first'; ok '^draft 6$'
qs ask draft 6; Q6=$(sed -n 's/^asked \(Q[0-9]*\) draft 6$/\1/p' "$T/out"); [ -n "$Q6" ] || fail 'draft 6 was not asked'
sed 's/^| web | the pages and the operator pages |/| web | the pages and the operator screens |/' ARCHITECTURE.md > "$T/a" && cp "$T/a" ARCHITECTURE.md
ld draft --why 'the module table, corrected' --replaces 6; [ "$RC" = 0 ] || fail "the redraft failed ($RC)"; ok '^replaced 6$'; ok '^draft 7$'; [ "$(cat .vid/decide/drafts/6/replaced)" = 7 ] || fail 'draft 6 is not marked replaced by 7'
qs sync; ! grep -q "^- $Q6 " .vid/RUN-STATE.md || fail "the replaced draft's Q line stayed open"
qs ask draft 7; Q7=$(sed -n 's/^asked \(Q[0-9]*\) draft 7$/\1/p' "$T/out"); [ -n "$Q7" ] && [ "$Q7" != "$Q6" ] || fail "draft 7 was not asked afresh ($Q7)"
grep -q "^- $Q7 · .*draft 7 by SP: the module table, corrected" .vid/RUN-STATE.md || fail "no Q line for draft 7"
ld 6 --words 'Yes, the first'; [ "$RC" = 1 ] && ok 'draft 6 was replaced by draft 7' || fail "a replaced draft landed ($RC)"
ld draft --why 'again' --replaces 6 > /dev/null; ld draft --why 'again' --replaces 6; [ "$RC" != 0 ] && ok 'draft 6 is replaced already' || fail 'a replaced draft was replaced again'
# v0.26.10.26.7 (R5 b): no draft without its review's record; one naming no row of the draft, or out of form, refused; kept
awk '/^ROW-005 \|/ { sub(/the job stored once and dated/, "the job stored once and dated, in the owner time zone") } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
RC=0; sh "$LS" draft --why 'no review' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && ok 'refused — no --review' || fail "a draft with no --review was made ($RC)"
printf 'finding ROW-999 | not a row of the draft\n' > "$T/rv2"; RC=0; sh "$LS" draft --review "$T/rv2" --why 'x' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && ok 'names ROW-999, no row of the draft' || fail "a review naming another row was taken ($RC)"
printf 'looks fine\n' > "$T/rv2"; RC=0; sh "$LS" draft --review "$T/rv2" --why 'x' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && ok 'out of form' || fail "a review out of form was taken ($RC)"
[ -n "$(git status --porcelain -- INVENTORY.md)" ] || fail 'a refused review put the tree back'
printf 'finding ROW-005 | the time zone is the owner'"'"'s, not the server'"'"'s\n' > "$T/rv2"; RC=0; sh "$LS" draft --review "$T/rv2" --why 'ROW-005 in the owner time zone' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "a draft with its review was refused ($RC)"
n=$(sed -n 's/^draft \([0-9]*\)$/\1/p' "$T/out"); cmp -s "$T/rv2" ".vid/decide/drafts/$n/review" || fail 'the review is not kept with the draft'
exit 0
