#!/bin/sh
# Purpose: selftest case — the page shows the whole plan, P7 and P13 (v0.26.10.12.2.1 R8;
# v0.26.10.12.2.2 R7: the plan section). On the
# planner's toy (fixtures/planner-toy.sh), `planner.sh page` writes .vid/plan/PLAN-PAGE.md and its HTML, in order: the
# flags ("no review of this plan" before a review, "none" after a clean one; a planted breach and an unanswered
# finding listed there); the plan (each step's name, kind, modules, rows against the ceiling and builds-on, as the
# block has them; the shared: line; the prose below the block as written; the waves and the widest; every recorded
# change, newest first, with its why, trigger, evidence and expectation); the rows ViD added (origin: plan) and the four standing lines; the rows waiting on an open
# question (ROW-018); each stage, stage 0 first, with its card and its steps in order, the skeleton first, every row
# with its id, requirements, promise, fail-if, marks, class and carried fields, each transition under its journey and
# the golden-set row naming its set, printed once under "The golden sets" (v0.26.10.12.3.2, R6), a set cited by two rows
# too, two sets of one name told apart by folder, a missing one said; the grading checklist and the record DIF-003; the later-phase row ROW-020;
# the counts, equal to `planner.sh counts`, Inventory + Seams + ViD's rows = Rows on every line, with a ViD row moved
# too (v0.26.10.12.3.2, R5). No seam shows its module: or match:. An indented stage line is still a stage; with no STAGES.md, one stage shows the PRD's MVP focus.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-page: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
pg() { sh "$CHECKS/planner.sh" page > "$T/out" 2>&1 || fail 'page failed'; PG=.vid/plan/PLAN-PAGE.md; }
flags() { sed -n '/^## Flags$/,/^## /p' "$PG" | grep '^- '; }
fresh; pg
[ -f .vid/pages/PLAN-PAGE.html ] || fail 'no HTML page'
[ "$(grep '^## ' "$PG" | tr '\n' '/')" = '## Flags/## Notes/## The setup/## The plan/## The rows ViD added/## The rows waiting on an open question/## Stage 0 — The walking skeleton/## Stage 1 — The daily digest/## Stage 2 — Synonym-aware search/## The golden sets/## The grading checklist/## The later-phase rows/## Counts/' ] || fail 'the sections are not all there, in order'
[ "$(flags)" = '- no review of this plan' ] || fail 'an unreviewed plan does not say so'
printf 'none\n' > "$T/none"; sh "$CHECKS/planner.sh" review --in "$T/none" > /dev/null; pg
[ "$(flags)" = '- none' ] || fail 'a clean, reviewed plan does not say none'
sec() { awk -v h="## $1" '$0 == h { on = 1; next } on && /^## / { exit } on' "$PG"; }
[ "$(sec 'The rows ViD added' | grep '^| [A-Z]' | grep -v '^| Row ' | cut -d'|' -f2 | tr -d ' ' | tr '\n' ' ')" = 'HOS-005 RULE-004 RULE-005 ' ] || fail "ViD's rows are not shown"
for l in '- **rehearsal:** ROW-009' '- **sign-in:** none: subscribers' '- **fields:** RULE-004' '- **work:** RULE-005'; do sec 'The rows ViD added' | grep -qF -- "$l" || fail "the standing line is not shown: $l"; done
[ "$(sec 'The rows waiting on an open question' | grep '^| [A-Z]' | grep -v '^| Row ' | cut -d'|' -f2 | tr -d ' ')" = ROW-018 ] || fail 'the rows waiting on an open question are not ROW-018'
grep -qF -- '- **Outcome:** one thin journey end to end' "$PG" && grep -qF -- '- **Outcome:** a search also finds jobs' "$PG" || fail "a stage's card is missing"
[ "$(sed -n 's/^### Step \(S[0-9]*\) .*/\1/p' "$PG" | tr '\n' ' ')" = 'S01 S02 S03 S04 S05 ' ] || fail 'the steps are not all there in order'
[ "$(grep -m 1 '^### Step ' "$PG")" = '### Step S01 — save a search and read the first digest (the skeleton)' ] || fail 'the skeleton is not the first step'
sec 'Stage 0 — The walking skeleton' | grep -qF '| ROW-003 | REQ-001 |' || fail 'stage 0 does not hold ROW-003'
# the plan: every step as the block has it, the prose, the width, the recorded change
for l in '| S01 | save a search and read the first digest | skeleton | devagent | web digest | 2 of 60 | 0 | nothing | none |' '| S02 | new jobs only, each listed once | feature | devagent | ingest digest | 11 of 60 | 4 | S01 | none |' \
  '| S03 | the footer, unsubscribe and the mail provider | feature | devagent | web mail | 12 of 60 | 7 | S01 | none |' '| S04 | limits, backups, failures and the data move | feature | devagent | digest ingest | 7 of 60 | 3 | S02, S03 | none |' \
  '| S05 | synonym-aware search | feature | devagent | search | 1 of 60 | 0 | S02 | none |' 'Shared: web.' 'The waves follow builds-on: alone: a dashed link (fakes:) holds no step.' \
  'The longest chain, 3 steps, from last to first: S04, S02, S01.' "Row counts are not effort: a step's rows say what it must prove, not how long it takes." 'S02 and S03 run side by side: the feeds and the mail share no module. S04 builds on S02 for the listings and on S03' \
  '- wave 1: 1 (S01)' '- wave 2: 2 (S02, S03)' '- wave 3: 2 (S04, S05)' '3 waves for 5 steps; the widest wave holds 2.' 'The largest step: S03, 12 rows. The smallest: S05, 1 rows.'; do
  sec 'The plan' | grep -qxF -- "$l" || fail "the plan section lacks: $l"; done
[ "$(sec 'The plan' | grep -c '^| S0')" = 5 ] || fail 'the plan section does not hold the five steps'
sec 'The plan' | grep -q '^### The lanes' && fail 'one lane shows a lanes section'
sec 'The setup' | grep -qxF '| devagent | the whole product | core | 1 | devagent |' && sec 'The setup' | grep -qF 'Still to ask at the next /vid:vid-plan: layout, repo, split, team, github-mode, labels-prefix, spec-repo' || fail 'the default setup is not shown'
sec 'The setup' | grep -qxF -- '- **The open-ticket limit:** not set' || fail 'no open-ticket limit is not said'   # v0.26.10.12.3.2 (R4)
sec 'The setup' | grep -qxF -- '- **Who works the tickets:** not asked yet' || fail 'no GitHub mode is not said'   # v0.26.10.28.8 (R3)
sec 'The plan' | grep -q '^- \*\*create\*\* (decision .*): why — the first plan; trigger — initial; evidence — -; expected — the skeleton ticket goes first\.$' || fail 'the recorded create is not shown'
pt_set 'step S05' 'step S05 | name: synonym-aware search, at last | modules: search | builds-on: S02 | rows: ROW-017 | lane: devagent'
sh "$CHECKS/plan.sh" change other 'S05 renamed' --trigger initial --expect 'the same plan' > "$T/out" 2>&1 || fail 'the second change was refused'; pg
[ "$(sec 'The plan' | sed -n 's/^- \*\*\([a-z]*\)\*\* .*/\1/p' | paste -sd ' ' -)" = 'other create' ] || fail 'the changes are not newest first'
sec 'The plan' | grep -q '^- \*\*other\*\* .*why — S05 renamed;' && sec 'The plan' | grep -qF '| S05 | synonym-aware search, at last |' || fail 'the second change is not shown'
# every row, with all its parts, in its stage
sh "$CHECKS/planner.sh" rows | grep -v '^#' > "$T/rows"
awk -F'\t' 'function c(s) { gsub(/\|/, "¦", s); return s == "" ? "—" : s } $2 != "tr" { print $1 "\t" $5 "\t| " $1 " | " c($4) " | " c($8) " | " c($9) " | " c($7) " | " c($10) " | " c($11 ($12 == "-" ? "" : " · golden set: synonyms")) " |" }' "$T/rows" > "$T/want"
while IFS='	' read -r id s l; do
  case "$s" in later) h='The later-phase rows' ;; *) h=$(grep "^## Stage $s — " "$PG" | sed 's/^## //') ;; esac
  case "$id" in DIF-003) h='The grading checklist' ;; esac
  sec "$h" | grep -qxF -- "$l" || fail "$id is not shown whole in its section ($h)"
done < "$T/want"
grep -A3 -F '| ROW-004 | REQ-001 REQ-002 REQ-005 |' "$PG" | sed -n 2,4p | cut -d'|' -f2 | tr -d ' ' | tr '\n' ' ' | grep -qx 'ROW-004-T1 ROW-004-T2 ROW-004-T3 ' || fail 'the transitions do not follow their journey'
grep -qF '| ROW-005-T2 | REQ-001 INV-001, a transition of ROW-005 | (process) at the listings ·' "$PG" || fail "a transition's promise is not shown"
sec 'The golden sets' | grep -qxF '### synonyms' && sec 'The golden sets' | grep -qxF 'Cited by ROW-017.' && sec 'The golden sets' | grep -qxF 'electrician | Electrical technician | - | Electronics sales' || fail "the golden set is not shown"
sec 'The grading checklist' | grep -qF -- '- **Digest repeats.** Check that no job reaches' || fail 'the grading checklist is not shown'
grep -qE 'module:|match:|mailer|jobdigest/mail|tests/contract' "$PG" && fail 'a seam shows its code location, pattern or evidence path'
# counts
sh "$CHECKS/planner.sh" counts > "$T/c"
grep -qx 'stage 0 inventory=2 seams=0 added=0 rows=2 planned=2 moved=0 owed=0 limit=0 record=0 transitions=3 steps=1 requirements=0 | The walking skeleton' "$T/c" &&
grep -qx 'stage 1 inventory=26 seams=2 added=3 rows=31 planned=23 moved=0 owed=7 limit=0 record=1 transitions=3 steps=3 requirements=9 | The daily digest' "$T/c" &&
grep -qx 'stage 2 inventory=1 seams=0 added=0 rows=1 planned=1 moved=0 owed=0 limit=0 record=0 transitions=0 steps=1 requirements=1 | Synonym-aware search' "$T/c" &&
grep -qx 'later rows=1 transitions=0' "$T/c" || fail 'counts differs from the files'
sh "$CHECKS/stages.sh" counts | sed -n 's/^stage \([0-9]*\) requirements=[0-9]* rows=\([0-9]*\) .*/\1 \2/p' | tr '\n' ' ' | grep -qx '0 2 1 32 2 1 ' || fail "the toy's stages.sh counts changed"
grep -qx '| 0 | 2 | 0 | 0 | 2 | 2 | 0 | 0 | 0 | 0 | 3 | 1 | 0 |' "$PG" && grep -qx '| 1 | 26 | 2 | 3 | 31 | 23 | 0 | 7 | 0 | 1 | 3 | 3 | 9 |' "$PG" &&
grep -qx '| Later phase | — | — | — | 1 | — | — | — | — | — | 0 | — | — |' "$PG" && grep -qx '| All | 29 | 2 | 3 | 34 | 26 | 0 | 7 | 0 | 1 | 6 | 5 | 10 |' "$PG" || fail 'the page'"'"'s counts differ from counts'
adds() { sh "$CHECKS/planner.sh" counts | awk '/^(stage|total) / { split("", v); for (i = 1; i <= NF; i++) if (split($i, a, "=") == 2) v[a[1]] = a[2]; if (v["inventory"] + v["seams"] + v["added"] != v["rows"]) { print; bad = 1 } } END { exit bad }' > "$T/out" || fail "a line of the counts does not add up: $1"; }
adds 'the toy'
# a planted breach and an unanswered finding are flags, first
pt_del HOS-005; printf 'finding RULE-004 | 1: vague\n' > "$T/hit"; sh "$CHECKS/planner.sh" review --in "$T/hit" > /dev/null; pg
flags | grep -q '^- protection INV-002 — ' || fail 'a check flag is not on the page'
flags | grep -q '^- finding 1 on RULE-004, not answered: 1: vague$' || fail 'an unanswered finding is not on the page'
flags | grep -q '^- none$' && fail 'a flagged page says none'
# v0.26.10.12.3.1 (R4, R9): the setup kept, two teams' lanes and the links between them, R9's prose heading
fresh; mkdir -p .vid/tw; printf 'layout: separate\nrepo: toy/jd\nspec-repo: toy/jd-spec\nlabels-prefix:\nsplit: fine\ngithub-mode: team\nopen-tickets: 4\naccess: 2026-11-03 ok\n' > .vid/tw/settings
pt_teams 'india | stages 0 and 1 | strict | 3' 'usa | the data pipeline | core | 1'; pt_rs 's/lane: devagent/lane: india-2/'; pt_rs 's/^\(step S05 .*\)lane: india-2/\1lane: usa | fakes: S03/'
printf '\nProvable only at a later stage: none in stage 1; none in stage 2.\n' >> .vid/RUN-STATE.md; pg
for l in '- **The spec repository:** toy/jd-spec' '- **Who works the tickets:** an outside team (github-mode: team)' '- **The open-ticket limit:** 4' '- **Access:** 2026-11-03 ok' '- **The step size:** finer steps, technical ones allowed (split: fine)' '| usa | the data pipeline | core | 1 | usa |' \
  'Asked once, at the start of /vid plan, and kept in .vid/tw/settings. Nothing is missing: a later /vid:vid-plan asks nothing.'; do sec 'The setup' | grep -qxF -- "$l" || fail "the setup lacks: $l"; done
for l in '- **india-2** (india): S01 (2 rows), S02 (11 rows), S03 (12 rows), S04 (7 rows)' '- **india-1** (india): no step' '- **usa** (usa): S05 (1 rows)' '- S05 (usa) → S02 (india), solid' '- S05 (usa) → S03 (india), dashed' \
  '| S05 | synonym-aware search | feature | usa | search | 1 of 60 | 0 | S02 | S03 |' 'Provable only at a later stage: none in stage 1; none in stage 2.'; do sec 'The plan' | grep -qxF -- "$l" || fail "the plan lacks: $l"; done
# an indented stage line (stages.sh takes it) is still a stage
fresh; sed 's/^STAGE-2 |/ STAGE-2 |/' STAGES.md > S.x && mv S.x STAGES.md; sh "$CHECKS/stages.sh" check > /dev/null 2>&1 || fail 'stages.sh refuses the indented stage line'
pg; grep -qx '## Stage 2 — Synonym-aware search' "$PG" && grep -q '^### Step S05 ' "$PG" && grep -qF '| ROW-017 | REQ-003 |' "$PG" || fail 'an indented stage line drops stage 2 off the page'
# one stage: the PRD's MVP focus stands in for the card
fresh; rm STAGES.md; pg
grep -qx '## Stage 1 — the product' "$PG" && grep -qF -- '- G1: A subscriber receives a daily digest' "$PG" || fail "one stage does not show the PRD's MVP focus"
grep -qE '^## Stage [02]' "$PG" && fail 'one stage shows another'
# one set cited by two rows: printed once, each row naming it; two sets of one name, by folder; a missing set; a ViD row moved
fresh; pl2() { sed "s|^\(ROW-012 .*\)\$|\1 \| golden: $1|" INVENTORY.md > I.x && cat I.x > INVENTORY.md; rm I.x; pg; }
pl2 tests/invariants/golden/synonyms.golden; [ "$(grep -c '^electrician ' "$PG")" = 1 ] && [ "$(grep -c '^### synonyms$' "$PG")" = 1 ] && sec 'The golden sets' | grep -qxF 'Cited by ROW-012, ROW-017.' || fail 'a set cited by two rows is not printed once'; [ "$(grep -c '^| ROW-01[27] | .* · golden set: synonyms |$' "$PG")" = 2 ] || fail 'a row citing the set does not name it'
fresh; pl2 elsewhere/synonyms.txt; sec 'The golden sets' | grep -qxF '### synonyms (elsewhere)' && sec 'The golden sets' | grep -qxF '### synonyms (tests/invariants/golden)' && sec 'The golden sets' | grep -qxF "(not in ViD's repository: flagged)" || fail 'two sets of one name are not told apart, or the missing one not said'; flags | grep -q '^- golden ROW-012 — ' || fail 'a missing set is not flagged'
fresh; pt_after 'standing work' 'RULE-004 | moved: STAGE-2 A-005'; adds 'a ViD row moved'; sh "$CHECKS/planner.sh" counts > "$T/c"; grep -q '^stage 1 inventory=26 seams=2 added=2 rows=30 ' "$T/c" && grep -q '^stage 2 inventory=1 seams=0 added=1 rows=2 ' "$T/c" || fail "a ViD row's move is not followed"
exit 0
