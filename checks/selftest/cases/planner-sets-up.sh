#!/bin/sh
# Purpose: selftest case — which step is the first to set up which data store (FB-4 A5, planner.sh), read from
# ARCHITECTURE.md's seam table, on the planner's toy (fixtures/planner-toy.sh). `planner.sh setsup` prints `<step> TAB
# <module> TAB <owned cell>` in the block's order: the first step naming the module, though a later one names it too; a
# module only in `shared:` is the skeleton's; one in neither is `-`; a cell that begins none, or is empty, gives nothing.
# The plan page lists them; nothing is flagged; `--block` reads a candidate. A table without the Owned tables/data column,
# or no ARCHITECTURE.md, gives no list and no error. In GitHub manual the table is the applied commit's, and the re-plan page
# lists the candidate's (fixtures/form.sh). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-sets-up: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
TAB=$(printf '\t'); g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
arch() { printf '# JobDigest — ARCHITECTURE\n\n| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| web | the pages | None of its own | the pages | none |\n| ingest | reading the feeds | listings | the listings | digest |\n| digest | the morning digest | saved searches | the digest run | none |\n| mail | sending mail | none | send | digest |\n| `search` | synonym-aware search | the search index store (a managed engine) | search | digest |\n| audit | the record of sends | | append | none |\n| archive | old digests | the digest archive | keep | none |\n| clock | the schedule | the schedule table | tick | all |\n\n## Data stores\n\n| Store | Kind |\n|---|---|\n| a queue | managed |\n' > ARCHITECTURE.md; }
su() { sh "$CHECKS/planner.sh" setsup "$@" > "$T/out" 2>&1 || fail "setsup failed"; }
pt_toy "$T/p"; arch; pt_rs 's/^shared: web$/shared: web clock/'; pt_record
printf 'S01\tdigest\tsaved searches\nS01\tclock\tthe schedule table\nS02\tingest\tlistings\nS05\tsearch\tthe search index store (a managed engine)\n-\tarchive\tthe digest archive\n' > "$T/want"
su; cmp -s "$T/want" "$T/out" || fail 'the list is not the five lines in the block'"'"'s order'
pt_check; [ "$PT_RC" = 0 ] || fail "the plan is flagged ($PT_RC)"
sh "$CHECKS/planner.sh" page > "$T/out" 2>&1 || fail 'page failed'; P=.vid/plan/PLAN-PAGE.md
awk '/^#/ { on = ($0 ~ /What each step is the first to set up$/) } on && /^- /' "$P" > "$T/out"
printf -- '- **S01**: saved searches (digest)\n- **S01**: the schedule table (clock)\n- **S02**: listings (ingest)\n- **S05**: the search index store (a managed engine) (search)\n- in no step: the digest archive (archive)\n' > "$T/want2"
cmp -s "$T/want2" "$T/out" || fail 'the page does not list them'
# a candidate block: search built first in S02
awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md | sed 's/modules: ingest digest/modules: ingest, search/' > "$T/cand"
su --block "$T/cand"; grep -qx "S02${TAB}search${TAB}the search index store (a managed engine)" "$T/out" && ! grep -q '^S05' "$T/out" || fail 'the candidate is not read'
# an older table: no column, no list; no ARCHITECTURE.md, the same
sed 's/Owned tables\/data/Owned state/' ARCHITECTURE.md > a.x && mv a.x ARCHITECTURE.md; su; [ ! -s "$T/out" ] || fail 'a table without the column gives a list'
sh "$CHECKS/planner.sh" page > "$T/out" 2>&1 || fail 'page failed on an older table'; ! grep -q 'the first to set up' "$P" || fail 'the page holds the list with no column'
mv ARCHITECTURE.md a.x; su; [ ! -s "$T/out" ] || fail 'no ARCHITECTURE.md gives a list'; mv a.x ARCHITECTURE.md
# GitHub manual: the applied commit's table, the working tree's change not read; --at reads another
cd "$T"; pt_toy "$T/m"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'; mkdir -p .vid/tw; git rev-parse HEAD > .vid/tw/applied
printf 'setup-answered key=github-mode value="manual" words="that one" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
arch; g commit -qam 'the stores'; su; grep -qx "S05${TAB}search${TAB}synonyms" "$T/out" || fail 'in manual the applied table is not read'
su --at HEAD --block "$T/cand"; grep -qx "S02${TAB}search${TAB}the search index store (a managed engine)" "$T/out" || fail 'in manual --at is not read'
# the re-plan page: the candidate's list, S03 the first to build search
. "$CHECKS/selftest/fixtures/form.sh"; cd "$T"; fm_toy "$T/toy" || fail 'the toy could not be made'; fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }
awk '{ print } /^ROW-020 / && !d { print "ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if it shows no day. | REQ-001 | owed: spec-only — first stage | origin: REQ-001"; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; g commit -qam 'a row landed'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; C=$T/c1; mkdir -p "$C"; h=$(git rev-parse --short HEAD)
awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md | sed -e 's/^\(step S04 .*rows:\) /\1 ROW-021 /' -e 's/^needs ROW-002 /needs ROW-021 ROW-002 /' -e 's/^\(step S03 .*modules: web mail\) /\1 search /' > "$C/block"
for x in S03 S04; do printf '%s\tscope-change\tcommit:%s\tit is built there\n' "$x" "$h" >> "$C/changes"; done; printf 'none\n' > "$C/review"
sh "$CHECKS/replan.sh" scope > "$T/out" 2>&1 || fail 'scope failed'; awk -F'\t' '$1 == "trigger" { print "trigger\t" $3 " " $4 "\tno plan change helps it" }' "$T/out" > "$C/left"
pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis was refused'
awk '/^## / { f = ($0 == "## What each step is the first to set up") } f && /^- /' .vid/next/proposal/REPLAN-PAGE.md > "$T/out"
printf -- '- **S01**: saved searches (digest)\n- **S02**: listings (ingest)\n- **S03**: synonyms (search)\n' | cmp -s - "$T/out" || fail 'the re-plan page does not list the candidate'"'"'s'
exit 0
