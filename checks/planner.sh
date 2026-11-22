#!/bin/sh
# Purpose: ViD's planner, PL (v0.26.10.12.2.1 R1–R10; v0.26.10.12.2.2
# R1, R3–R5, R7, R8) — the ticket-mode plan read and judged. Every line of the ratified INVENTORY.md's ```vid-inventory
# blocks is a planned row, word for word: its id, requirements, stage (stages.sh scope; a seam is stage 1), marks,
# promise, fail-if and every other field carried by name, but what DevAgent owns (a test path, proved-red:, a golden:
# path as text, a one-path census, a suppression, a class-only exception, a seam's evidence paths, module:, match:).
# ViD's rows are appended to the inventory in the schema's form, `| origin: plan <item>` last. PLAN.md holds the
# owner's class lines and the four `standing` lines. The steps are RUN-STATE's ```vid-plan block under "## The plan",
# in develop's grammar (plan.sh), read by PL's own parser: `step <id> | name: | modules: | builds-on: | rows: | lane: |
# kind: | fakes:`, ranges `<PREFIX>-a..<PREFIX>-b`, one `shared:` and one `protected:` line; the modules are the Module
# column of ARCHITECTURE.md's seam table. Run at the top of ViD's repository. Product text only: no event written, no
# outside service, no code read (the plan-change events and decisions are read, read only). v0.26.10.12.3.1 (R1, R2):
# the setup's teams are .vid/tw/settings' `team: <name> | <area> | strict|core | <people>`
# lines (none: devagent, core, 1); a team of one has the lane <name>, of n the lanes <name>-1 … <name>-n.
#   check [--block <file>] [--ceiling <n>]   one flag line per breach, `<kind> <id> — <why>`, exit 1 on any; clean, one
#             `planner: clean` line (0.26.10.29.2, R1: --block reads that plan block for RUN-STATE's, --ceiling sets rule A's
#             ceiling, as plan.sh change asks for a candidate and the plan it replaces). form,
#             inventory (P1: a PLAN.md line out of form; a class line for no row; a repeated id; an `origin: plan` row
#             of no kind and form ViD adds; inside a repository, INVENTORY.md changed since HEAD outside its origin:
#             plan rows); protection (P2); class, moved, answer (P3: a row in no step but a known limit, a later-phase
#             row or a record; one of those in a step; a bad moved: or A-NNN; a vid-steps block left in PLAN.md); step,
#             module (P10: an id of rows: or protected: no planned row, a transition; a fakes: naming no step, itself or a step it builds on; a modules: or
#             shared: token no Module of ARCHITECTURE.md, `shared: -` apart; no name, modules or rows; an unknown field;
#             a row in two steps; a builds-on: naming no step or a later one); skeleton (P4: exactly one step of kind:
#             skeleton, building on nothing — with a STAGE-0 exactly stage 0's rows left there, else one stage-1 row; no
#             owed- mark, no seam; stage 0 holds no other step; a step in one stage, building only on steps of its own or
#             earlier stages); size (P12: a step over rule A's ceiling, plan.sh's budget read the same way, a journey
#             counted once); standing (P5); unread, golden (P9); setup (a team: line out of form); lane (a lane not the
#             setup's; with more than one lane, a step with none); needs (R10: a row of a step in no `needs <rows> | <steps
#             or ->` line of the block, or in two; a needs id no row of a step; a needed step no step, the row's own or of
#             a later stage; a row whose step reaches a step it needs through no builds-on: chain, "only a dashed link")
#   (R5) the notes, computed beside the flags and shown on the page alone, never in check, ratify or ratified: each
#             stage's steps whose wave is no later than an earlier stage's last; a journey whose step does not reach
#             the home step (the most of its other rows, the earliest on a tie) of one of its items, in its stage or before;
#             v0.26.10.12.3.2: a step with a builds-on: whose every needs line names exactly those steps (R7); a step's rows 10
#             or more places in the block after the last step their needs line names, a `-` line naming the block's first (R8);
#             a step over 40 rows, a journey counted once (R9)
#   rows [--short]   the rows table, tab-separated after a `#` header line: id, kind (row, tr or record), parent,
#             items, stage, class, marks, promise, fail-if, class text, carried (`name: value` joined by ` · `), golden
#             (the set's path, or -); --short cuts each promise to 80 characters. PLAN.md may be absent
#   rows --added   the inventory's `origin: plan` lines, as written (the review's input)
#   rows --newest [--short]   (GM-1 S3) the rows table of the working tree's spec, in every mode
#   teams | steps [--block <file>]   (GM-4 F10) the setup's teams, `<name> TAB <area> TAB <strict|core> TAB <people>`, and the
#                    plan's steps, `<step> TAB <name> TAB <its stage> TAB <rows> …`, as the planner reads them (--block, --at and
#                    --plan-md as check takes them)
# GitHub manual (GM-1 S3, S4; lib.sh's manual): every subcommand but setup and rows --newest reads PRD.md, INVENTORY.md,
#             STAGES.md, GRADING-CHECKLIST.md and ARCHITECTURE.md at .vid/tw/applied's commit and PLAN.md at HEAD, and refuses
#             when that names no commit (reratify refuses outright: the door lands nothing); P1's check of INVENTORY.md against
#             HEAD does not apply. A row in no step is flagged `place <row> — in no step`, a planned row in a step of another
#             stage `place <row> — in step <s> of stage <k>; its own stage is <j>` (a step's own stage: the stage most of its
#             planned rows are in, the earliest on a tie), in place of the class and step flags; a row .vid/tw/to-place lists
#             (`<row> <no-step|other-stage> <at> <the owner's words>`, tab-separated) in that place is no flag, and the page lists
#             it as to place. P4: stage 0 may hold several steps, one the skeleton, building on nothing and in stage 0
#   GM-3 U2, U3: in GitHub manual `check`, `rows` and `hash` take `--at <commit>`, anywhere among their options: the five spec files
#             are read at that commit in place of the applied commit's (the golden sets too); `check` takes `--plan-md <file>` too,
#             read in place of HEAD's PLAN.md. Outside GitHub manual, and with rows --newest, both are refused
#   review --in <file>   records a review pass's output (`finding <row id> | <why>` lines, or `none`) in
#             .vid/plan/review — `review <r> hash=<h> findings=<k> at=<t>`, then `finding <n> review=<r> hash=<h> |
#             <row id> | <why>` each; an empty output, a line out of form or one naming no row ViD added refuses it. low-1 (R5):
#             at most 3 rounds a sitting (rounds()); once they close it records nothing, says why, and exits 0, ratify needs no
#             review at the current hash, the open findings are those at the newest review's hash, and the page notes the close
#             in place of "no review of this plan"
#   page      .vid/plan/PLAN-PAGE.md, rendered (checks/page.sh, .vid/pages/PLAN-PAGE.html), and a `paged spec= plan=`
#             line in .vid/plan/paged: the flags (each check flag, each unanswered finding of a review with the current
#             hash, "no review of this plan" while none has it; or "none"); the notes (R5) and the setup (R4: the
#             answers, each team, its lanes); the plan (P13: each step's name, kind, lane, modules, rows against the
#             ceiling, guards, builds-on and dashed links; with more than one lane, each lane's steps and the links
#             between teams; the longest chain and "Row counts are not effort"; the shared: line; the prose below the block; the waves by
#             the longest builds-on chain; each recorded change, newest first); the rows ViD added and the standing
#             lines; the rows waiting on an open question; each stage, stage 0 first, its card, its steps, every row in
#             full; the golden sets, each once (v0.26.10.12.3.2, R6); the grading checklist and the records; the later-phase
#             rows; the counts
#   counts    per stage `stage <n> inventory= seams= added= rows= planned= moved= owed= limit= record= transitions=
#             steps= requirements= | <name>`, then `later rows=<n>` and `total …`
#   answer <n> keep|fixed --words "<the owner's words>"   `answer <n> keep|fixed hash=<h> at=<t> words=<…>` in .vid/plan/review
#             (low-1, R5: fixed, for a finding the owner had fixed once the rounds closed)
#   ratify --words "<the owner's words>"   `ratified hash=<h> plan=<plan hash> at=<t> words=<verbatim>` in
#             .vid/plan/ratified; refused, each reason named, while a check flag is open, no review has the current
#             hash, a finding of it has no answer, the block is not the newest recorded plan, or the newest page did
#             not show this plan. GM-3 U4: in GitHub manual a size flag is no flag here either, as in ratified (GM M4)
#   reratify --words "<the owner's yes>" --base <b> --to <t> --held <file,…>   (v0.26.10.25.5, R3) a counted change landed
#             during a run, ratified by the owner's yes with no new sitting: a ratification in those words (checks/land.sh records
#             the publish-approved event in the same words, as vid-plan does after ratify); refused while a check flag is open, when the spec files at the base are not the newest ratified ones,
#             when a spec file the draft did not hold changed between them, or when the plan block is not the newest recorded
#   ratified  exit 0 only while the spec files' hash is the ratified one, the block is the newest recorded plan and
#             the check is clean: a recorded plan change keeps the ratification. GM-2 T6, T7: in GitHub manual a size flag is no
#             flag here (the move shows it as a warning), so it never shuts the writer's gate
#   hash      the spec files' hash: PRD.md, INVENTORY.md, STAGES.md, GRADING-CHECKLIST.md, ARCHITECTURE.md, PLAN.md
#   setup <key> <answer> --words "<the owner's words>"   (v0.26.10.26.7, R11) one setup answer: layout, team (one line each),
#             split, repo, spec-repo ("not yet" writes no key), spec-path and spec-stamp (GM-4 K13, J4: with layout one, the
#             code repository's folder the spec is published into, a plain path from its top, read as docs/specs while missing;
#             the stamp, a file inside it named from it, or none, which writes no key; never flagged unanswered) or github-mode (v0.26.10.28.8, R3: auto, ViD's own DevAgent works
#             the tickets; FB-1 C1: team is retired and refused, a team of people taking GitHub manual; GM-1 S1: manual, the owner's team by hand, which, like a change away from
#             manual, only /vid mode's own call sets, VID_CALLER=mode), state-repo (GM-1 S1: owner/name, ViD's own private
#             repository, never repo: or spec-repo:) or slack-channels (names, comma-separated, or none); GM-2 (§5): issue-form (a path in
#             ViD's repository, from its top, no .., never one of the spec export's own files), issue-parent (an issue number, or
#             none) or plan-page (artifact, its link once made, or none); written to .vid/tw/settings, and `setup-answered key=` in
#             .vid/plan/setup, the planner's own record (it writes no event) — until
#             the first ratify, check flags `setup <key>` for each of layout, team, split, repo, spec-repo (GM-4 J5: with
#             layout: one too, ViD's private spec repository being asked in both layouts) and github-mode that no such event covers; in GitHub manual (GM-1 S1) state-repo too, and github-mode
#             not under /vid mode's own mark (GM-2 §5's issue-form, issue-parent and plan-page are asked by /vid mode, not flagged here)
#   prereq    (v0.26.10.12.3.2, R10) what the skeleton ticket quotes, no PLAN.md needed: one line per gap, exit 0; the page's notes repeat each
#   prd-form  (0.26.10.28.1, stage 9 R6, CK-R-006) refuses a PRD.md in the legacy block form (no ```vid-prd block) in one line,
#             exit 1, naming /vid create-prd's import door; silent, exit 0, on an enriched PRD or none
# Usage: sh checks/planner.sh check | prereq | prd-form | rows [--short|--added|--newest] | teams | steps | review --in <file> | page | counts |
#        answer <n> keep --words "<…>" | ratify --words "<…>" | reratify … | ratified | hash
# serves: tickets (0.26.10.28.4, M9)
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
MAN=''; ORIG=''; SNAPC=''; AT=''; PMD=''   # GM-1 S3: set in GitHub manual, read at the applied commit; ORIG the project's top once snap moved in
die() { echo "ViD planner: $*" >&2; exit 2; }
hash() { for f in PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md PLAN.md; do printf '== %s\n' "$f"; if [ -f "$f" ]; then cat "$f"; fi; done | git hash-object --stdin | cut -c1-12; }
RV=.vid/plan/review
# words --words "<…>": OW, the owner's words — one line, not empty
words() { [ "${1:-}" = --words ] && [ -n "${2:-}" ] || die "usage — … --words \"<the owner's words>\""
  case "$2" in *'
'*) die "the owner's words are recorded on one line; these span several" ;; esac; OW=$2; }
block() { sed -n "/^\`\`\`$1[[:space:]]*\$/,/^\`\`\`[[:space:]]*\$/p" "$2" | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true; }
# plan_block (lib.sh): RUN-STATE's plan block (plan.sh's block); prose: the lines below it; phash: the plan's hash, as plan.sh's;
# recorded: the newest plan-change's hash; ceil: rule A's ceiling (plan.sh's budget); mods: ARCHITECTURE.md's modules
PS='/^## The plan/ { s = 1; next } s && /^## / { exit } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/'
prose() { [ -f .vid/RUN-STATE.md ] && awk "$PS"' { b = 0; a = 1; next } a' .vid/RUN-STATE.md; }
phash() { plan_block | { if command -v shasum > /dev/null 2>&1; then shasum -a 256; else sha256sum; fi; } | cut -c1-12; }
recorded() { grep '^plan-change ' .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/^plan-change what=[^ ]* hash=\([0-9a-f]*\) .*/\1/p'; }
ceil() { [ -z "${CEILOV:-}" ] || { echo "$CEILOV"; return 0; }; b=''; s=''; if [ -f .vid/budget ]; then b=$(sed -n 's/^unverified-rows=\([0-9][0-9]*\).*/\1/p' .vid/budget | tail -n 1); s=$(sed -n 's/^stacks=\([0-9][0-9]*\).*/\1/p' .vid/budget | head -n 1); fi; c=$((60 * ${s:-1})); [ -n "$b" ] || b=60
  if [ "$b" -gt "$c" ] && ! grep '^plan-change ' .vid/metrics-events 2>/dev/null | grep ' what=other ' | grep -q "unverified-rows=$b\([^0-9]\|$\)"; then b=$c; fi; echo "$b"; }
mods() { [ -f ARCHITECTURE.md ] && awk -F'|' 'function tr(x) { gsub(/^[ \t`]+|[ \t`]+$/, "", x); return x }
  /^[ \t]*\|/ { if (done) next; if (!col) { for (k = 2; k < NF; k++) if (tr($k) == "Module") col = k; next } if ($0 ~ /^[ \t|:-]+$/) next; v = tr($col); if (v != "") print v; next } col { done = 1 }' ARCHITECTURE.md; }
# gaps (R10): what the skeleton ticket quotes and does not find, read as writer.sh's stack() reads it, one line each
gaps() { awk '/^## Stack[ \t]*$/ { on = 1; next } on && /^## / { exit } on' BASELINE.md > "$T/sk" 2>/dev/null || :; sed -n '/^```vid-hosting[[:space:]]*$/,/^```[[:space:]]*$/p' ARCHITECTURE.md 2>/dev/null | grep -v '^```' > "$T/ho" || :
  grep -q '[^[:space:]]' "$T/sk" || echo "the stack: BASELINE.md's \`## Stack\` section is missing or empty; the skeleton ticket quotes it"
  grep -q '[^[:space:]]' "$T/ho" || echo "the hosting: ARCHITECTURE.md's \`vid-hosting\` block is missing or empty; the skeleton ticket quotes it"; }
# planok: empty when the block is the newest recorded plan, else why not. 0.26.10.29.2 (R1): equal in the admission's canonical
# form counts, through plan.sh canon (shared, not copied), so a block only re-spaced, or a step's rows only re-ordered, stays ratified
planok() { R=$(recorded); if [ -z "$R" ]; then echo 'no plan is recorded (sh checks/plan.sh change create "<why>" --trigger initial --expect "<one line>")'; elif ! plan_block | cmp -s - ".vid/plans/$R.plan" && { [ ! -f ".vid/plans/$R.plan" ] || [ "$(plan_block | sh "$HERE/plan.sh" canon)" != "$(sh "$HERE/plan.sh" canon < ".vid/plans/$R.plan")" ]; }; then echo "the plan block is not the newest recorded plan ($R): record the change with sh checks/plan.sh change"; fi; }

# load [rows]: $T/items (`id kind tier phase stage`), $T/answers, $T/stages (`n<TAB>name`, stage 0 first), $T/stageof
# (`id stage`, every obligation and item stages.sh stages), $T/inv (the inventory's lines), $T/rowsblk, $T/stepsblk
# (RUN-STATE's plan block), $T/mods (ARCHITECTURE.md's modules); with `rows`, PLAN.md may be absent
load() {
  [ -f PRD.md ] || die 'no PRD.md here — run at the top of ViD'"'"'s repository'
  [ -f INVENTORY.md ] || die 'no INVENTORY.md here — the ratified test inventory (/vid init)'
  [ "${1:-}" = rows ] || [ -f PLAN.md ] || die 'no PLAN.md here (templates/PLAN.md)'
  sh "$HERE/prd.sh" PRD.md --effective > "$T/eff" 2>/dev/null || die 'prd.sh --effective failed on PRD.md'
  if [ -f STAGES.md ]; then
    block vid-stages STAGES.md | sed 's/^[[:space:]]*//' | sed -n 's/^STAGE-\([0-9][0-9]*\)[[:space:]]*|[[:space:]]*\([^|]*[^|[:space:]]\)[[:space:]]*|.*/\1	\2/p' | sort -n > "$T/stages"
  else printf '1\tthe product\n' > "$T/stages"; fi
  : > "$T/stageof"
  while IFS='	' read -r k _; do mustread "$T/sq" stages scope --upto "$k" --reqs; sed "s/\$/ $k/" "$T/sq" >> "$T/stageof"; done < "$T/stages"   # R6: never an empty stage
  awk -F'[[:space:]]*[|][[:space:]]*' -v SO="$T/stageof" 'BEGIN { while ((getline l < SO) > 0) { split(l, a, " "); if (!(a[1] in st)) st[a[1]] = a[2] } }
    $1 ~ /^(REQ|INV)-[0-9]+$/ { ph = "pilot"
    for (i = 4; i <= NF; i++) if ($i ~ /^phase: /) { ph = $i; sub(/^phase: /, "", ph) }
    print $1, $2, $3, ph, (ph == "later" ? "later" : ($1 in st ? st[$1] : "?")) }' "$T/eff" > "$T/items"
  awk '/^```vid-prd-answers/ { a = 1; next } /^```/ { a = 0 } a && /^A-[0-9]+[[:space:]]/ { print $1 }' PRD.md > "$T/answers"
  block vid-inventory INVENTORY.md | grep -v '^[[:space:]]*grammar:' > "$T/inv" || true
  : > "$T/rowsblk"; [ ! -f PLAN.md ] || block vid-rows PLAN.md > "$T/rowsblk"
  if [ -n "${BLK:-}" ]; then cat "$BLK"; else plan_block; fi > "$T/stepsblk" || true; mods > "$T/mods" || true; cat .vid/tw/settings > "$T/set" 2>/dev/null || :; touch "$T/stepsblk" "$T/mods" "$T/set"
}

# inventory: $T/irows (id kind parent items marks promise failif carried golden added, tab-separated, in the inventory's
# order, each journey's transitions after it) and $T/iflags (unread) from $T/inv, by §2
inventory() {
  LC_ALL=C awk -v IT="$T/items" -v FL="$T/iflags" -v OUT="$T/irows" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function flag(k, id, why) { print k " " id " — " why > FL }
    function add(c, s) { return c == "" ? s : c " · " s }
    function items(s,   n, a, i, o) { n = split(s, a, /[ ,]+/); o = ""
      for (i = 1; i <= n; i++) if ((a[i] in KD) && index(" " o " ", " " a[i] " ") == 0) o = o (o == "" ? "" : " ") a[i]; return o }
    function path(s) { sub(/[ \t].*/, "", s); return s ~ /\// }
    function keep(id, kd, par, it, mk, p, f, c, g) { O[++N] = id; K[id] = kd; PA[id] = par; I[id] = it; M[id] = mk; P[id] = p; F[id] = f; C[id] = c; G[id] = g
      if (kd != "tr" && V["origin"] ~ /^plan( |$)/) { x = V["origin"]; sub(/^plan[ \t]*/, "", x); AD[id] = (x == "" ? "?" : x) } }
    # a test field: owed: carried (a deploy gate gives its mark); a path dropped; anything else carried
    function testf(t) { if (t == "") return
      if (t ~ /^owed:/) { if (t ~ /^owed:[ \t]*paid by \/vid deploy gate 1/) OM = "owed-rehearsal"; else if (t ~ /^owed:[ \t]*paid by \/vid deploy gate 2/) OM = "owed-staging"; else if (t ~ /^owed:[ \t]*paid by \/vid deploy gate 3/) OM = "owed-production"
        CC = add(CC, "test: " t); return }
      if (!path(t)) CC = add(CC, "test: " t) }
    # a trailing field: `name: value` carried, but proved-red: (dropped) and golden: (its own column)
    function extra(id, x,   k) { if (x == "") return
      if (x ~ /^owed:/) { testf(x); return }
      if (!match(x, /^[a-z][a-z-]*:/)) { if (!path(x)) flag("unread", id, "the field \"" substr(x, 1, 40) "\" has no name"); return }
      k = substr(x, 1, RLENGTH - 1); V[k] = trim(substr(x, RLENGTH + 1))
      if (k == "proved-red") return
      if (k == "golden") { GL = V[k]; return }
      CC = add(CC, k ": " V[k]) }
    # cut: an obligation with a "fails if" sentence gives its promise (before it) and its fail-if (it, to the end)
    function cut(ob,   i, j) { PP = ob; FF = GEN; i = index(tolower(ob), "fails if"); if (!i) return
      for (j = i - 1; j >= 2; j--) if (substr(ob, j - 1, 2) ~ /^[.!?] $/) { PP = substr(ob, 1, j - 1); FF = substr(ob, j + 1); return }
      PP = ""; FF = ob }
    # num: where `k. ` starts in s, from on, after no letter or digit; 0 when it is not there
    function num(s, k, from,   i, p) { while (1) { i = index(substr(s, from), k ". "); if (!i) return 0; p = from + i - 1
        if (p == 1 || substr(s, p - 1, 1) !~ /[A-Za-z0-9]/) return p; from = p + 1 } }
    # unsep: s without the separator it ends with (spaces, ;, , and ·), kept in SEP
    function unsep(s,   e) { SEP = ""; while (s != "") { e = substr(s, length(s))
        if (e == " " || e == ";" || e == ",") { SEP = e SEP; s = substr(s, 1, length(s) - 1); continue }
        if (length(s) >= 2 && substr(s, length(s) - 1) == "·") { SEP = "·" SEP; s = substr(s, 1, length(s) - 2); continue }
        break } return s }
    BEGIN { GEN = "what the promise says is not what is observed"; while ((getline l < IT) > 0) { split(l, a, " "); KD[a[1]] = 1 } }
    { n = split($0, A, /\|/); for (i = 1; i <= n; i++) A[i] = trim(A[i]); c1 = A[1]; CC = ""; GL = "-"; OM = ""; split("", V)
      if (c1 ~ /^(exception|suppression)$/ && $0 ~ /\|[ \t]*origin: plan/) flag("form", A[2], "an origin: plan row of no kind ViD adds (hostility, a deploy-paid ROW, rule)")
      if ((c1 ~ /^ROW-[0-9]+$/ && (c1 in K)) || (c1 ~ /^(hostility|rule|difference|seam)$/ && (A[2] in K)) || (c1 == "exception" && (A[2] in EXS))) { flag("form", (c1 ~ /^ROW-/ ? c1 : A[2]), "the id is used twice"); next }
      if (c1 == "exception") EXS[A[2]] = 1
      if ($0 ~ /\|[ \t]*origin: plan/ && ((c1 ~ /^ROW-[0-9]+$/ && n != 9) || (c1 ~ /^(hostility|rule)$/ && n != 7))) flag("form", (c1 ~ /^ROW-/ ? c1 : A[2]), "an origin: plan row with " n " fields, not its form'"'"'s " (c1 ~ /^ROW-/ ? 9 : 7)) }
    c1 ~ /^ROW-[0-9]+$/ {
      if (n < 8) { flag("unread", c1, "a ROW line with fewer than its eight fields"); next }
      kd = A[2]; if (kd !~ /^(surface|journey|shell|behavior|reachability)$/) { flag("unread", c1, "the kind \"" kd "\" is no kind of the schema"); next }
      CC = "kind: " kd; CC = add(CC, "subject: " A[3]); CC = add(CC, "actor: " A[4]); CC = add(CC, "marker: " A[5]); CC = add(CC, "derived-from: " A[7])
      testf(A[8]); for (i = 9; i <= n; i++) extra(c1, A[i])
      mk = (kd ~ /^(journey|shell|reachability)$/) ? kd : ""; if (OM != "") mk = mk (mk == "" ? "" : " ") OM
      it = items(A[7]); ob = A[6]
      if (kd != "journey") { cut(ob); keep(c1, "row", "", it, mk, PP, FF, CC, GL); next }
      t = index(ob, " transitions:"); r = substr(ob, t + 13); p = t ? num(r, 1, 1) : 0
      if (!p) { flag("unread", c1, "a journey with no `transitions: 1. …`"); next }
      keep(c1, "row", "", it, mk, substr(ob, 1, t - 1), GEN, CC, GL); sep = substr(r, 1, p - 1)
      for (k = 1; p; k++) { s = p + length(k ". "); q = num(r, k + 1, s)
        x = q ? unsep(substr(r, s, q - s)) : substr(r, s)
        keep(c1 "-T" k, "tr", c1, it, "", x, GEN, "separator: \"" sep "\"", "-"); sep = SEP; p = q }
      next }
    c1 == "hostility" { id = A[2]; if (id !~ /^HOS-[0-9]+$/ || n < 4) { flag("unread", (id == "" ? "hostility" : id), "a hostility line out of form"); next }
      for (i = 4; i <= n; i++) extra(id, A[i])
      if (V["protects"] == "") { flag("unread", id, "a hostility row with no protects:"); next }
      PR[id] = V["protects"]; keep(id, "row", "", "", "protection", A[3], "attempting this brings about what " V["protects"] " forbids", CC, "-"); next }
    c1 == "rule" { id = A[2]; m = n; while (m > 3 && (A[m] == "" || (A[m] ~ /^[a-z][a-z-]*:/ && A[m] !~ /^owed:/))) m--
      if (id !~ /^RULE-[0-9]+$/ || m < 6) { flag("unread", (id == "" ? "rule" : id), "a rule line out of form (statement, census, tier, test)"); next }
      split($0, RW, /\|/); cs = RW[4]; for (i = 5; i <= m - 2; i++) cs = cs "|" RW[i]; cs = trim(cs)
      if (!(cs !~ /[ \t]/ && cs ~ /\//)) CC = add(CC, "census: " cs)
      CC = add(CC, "tier: " A[m - 1]); testf(A[m]); for (i = m + 1; i <= n; i++) extra(id, A[i])
      keep(id, "row", "", items(V["origin"]), "rule", A[3], GEN, CC, "-"); next }
    c1 == "difference" { id = A[2]; if (id !~ /^DIF-[0-9]+$/ || n < 6) { flag("unread", (id == "" ? "difference" : id), "a difference line out of form (knob, test value, production value, why safe)"); next }
      CC = "knob: " A[3]; CC = add(CC, "test-value: " A[4]); CC = add(CC, "prod-value: " A[5]); CC = add(CC, "why-safe: " A[6])
      for (i = 7; i <= n; i++) extra(id, A[i])
      if (V["paying-step"] != "") keep(id, "row", "", "", "owed-staging", V["paying-step"], GEN, CC, "-")
      else keep(id, "record", "", "", "", A[6], GEN, CC, "-"); next }
    c1 == "exception" { id = A[2]; if (id !~ /^EXC-[0-9]+$/ || n < 5) { flag("unread", (id == "" ? "exception" : id), "an exception line out of form"); next }
      if (A[4] ~ /^RULE-[0-9]+$/) { EX[++ne] = A[4]; EW[ne] = "except: " A[3] " — " A[5] " (" id ")"; EI[ne] = id }
      next }
    c1 == "suppression" { next }
    c1 == "seam" { id = A[2]; if (id !~ /^SEAM-[0-9]+$/ || n < 4) { flag("unread", (id == "" ? "seam" : id), "a seam line out of form"); next }
      CC = "service: " A[3]; for (i = 5; i <= n; i++) if (A[i] ~ /^(module|match):/ || (A[i] ~ /^evidence:/ && A[i] !~ /^evidence:[ \t]*owed$/)) continue; else extra(id, A[i])
      keep(id, "row", "", "", "seam", A[4], GEN, CC, "-"); next }
    { flag("unread", "\"" substr($0, 1, 40) "\"", "an inventory line of no kind the schema allows") }
    END {
      for (k = 1; k <= ne; k++) if (K[EX[k]] == "row" && M[EX[k]] == "rule") C[EX[k]] = add(C[EX[k]], EW[k]); else flag("unread", EI[k], EX[k] " is no rule of the inventory")
      for (id in PR) { n = split(PR[id], a, /[ ,]+/); it = ""
        for (i = 1; i <= n; i++) { x = a[i]; if (x == "") continue
          if (x in KD) y = x; else if (x in K) y = I[x]; else { flag("unread", id, "protects " x ", no item of PRD.md and no row of the inventory"); continue }
          m = split(y, b, " "); for (j = 1; j <= m; j++) if (index(" " it " ", " " b[j] " ") == 0) it = it (it == "" ? "" : " ") b[j] }
        I[id] = it }
      for (i = 1; i <= N; i++) { id = O[i]; print id "\t" K[id] "\t" PA[id] "\t" I[id] "\t" M[id] "\t" P[id] "\t" F[id] "\t" C[id] "\t" G[id] "\t" AD[id] > OUT } }' "$T/inv"
  touch "$T/iflags" "$T/irows"
}

# model: $T/flags (one line per breach), $T/rows (the rows table, tab-separated: id kind parent items stage class
# marks promise failif classtext carried golden), $T/steps (id name stage rows builds skeleton modules kind lane count,
# tab-separated, the rows expanded), $T/shared (the shared: line)
model() {
  load "${1:-}"; inventory
  # GM-3 S2, under D4 (a step's stage is its own, no ticket held back by stage) and GM M4: in GitHub manual a step with a published ticket (the log's published line, not withdrawn) is of the stage its
  # recorded writing's header names (`- stage: <k>`), its first ticket of kind step or skeleton: $T/pubst, `<step> <k>` a line
  : > "$T/pubst"; if [ -n "$MAN" ] && [ -f .vid/tw/log ]; then
    awk 'function kv(k,   i) { for (i = 3; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
      $1 == "withdrawn" { W[$2] = 1 } $1 == "published" && $2 ~ /^[0-9]+$/ && !($2 in K) { O[++n] = $2; K[$2] = kv("kind"); S[$2] = kv("step") }
      END { for (i = 1; i <= n; i++) if (!(O[i] in W) && K[O[i]] ~ /^(step|skeleton)$/ && S[O[i]] != "") print O[i] " " S[O[i]] }' .vid/tw/log |
    while read -r n s; do [ -f ".vid/tw/out/issue-$n.md" ] || continue
      k=$(awk '/^## / { h = ($0 ~ /^## Header[ \t]*$/); next } h && index($0, "- stage: ") == 1 { v = substr($0, 10); sub(/,.*/, "", v); gsub(/[ \t]/, "", v); print v; exit }' ".vid/tw/out/issue-$n.md")
      case $k in ''|*[!0-9]*) ;; *) echo "$s $k" ;; esac; done > "$T/pubst"; fi
  awk -v MAN="$MAN" -v FL="$T/flags" -v RW="$T/rows" -v SP="$T/steps" -v SH="$T/shared" -v CEIL="$(ceil)" -v TM="$T/teams" -v LN="$T/lanes" -v NO="$T/notes" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function on(l, x,   n, a, i) { n = split(l, a, /[ ,]+/); for (i = 1; i <= n; i++) if (a[i] == x) return 1; return 0 }
    # rch <s> <t>: step s reaches step t through a chain of builds-on: links (R5, R10)
    function rch(s, t,   n, a, i, v) { if ((s, t) in RC) return RC[s, t]; n = split(sb[s], a, /[ ,]+/); v = 0
      for (i = 1; i <= n && !v; i++) if (a[i] == t || ((a[i] in sidx) && sidx[a[i]] < sidx[s] && rch(a[i], t))) v = 1; return RC[s, t] = v }
    # before <k> <b> (GM-1 S3): stage k comes before stage b, a numbered stage before any other
    function before(k, b) { if (k ~ /^[0-9]+$/ && b ~ /^[0-9]+$/) return k + 0 < b + 0; if (k ~ /^[0-9]+$/) return 1; if (b ~ /^[0-9]+$/) return 0; return k < b }
    function same(p, q,   n, a, i) { n = split(p, a, /[ ,]+/); for (i = 1; i <= n; i++) if (a[i] != "" && !on(q, a[i])) return 0
      n = split(q, a, /[ ,]+/); for (i = 1; i <= n; i++) if (a[i] != "" && !on(p, a[i])) return 0; return 1 }
    # R1, R2: the setup, its team: lines and their lanes
    f == 0 { if ($0 !~ /^team:/) next; l = trim(substr($0, 6)); n = split(l, a, "|"); for (i = 1; i <= n; i++) a[i] = trim(a[i]); nm = tolower(a[1])   # GM-3 S2, GM-4 F11: lower-cased, one rule in both modes
      w = (nm == "" ? "no name" : nm !~ /^[a-z][a-z0-9]*$/ ? "the name " nm " is not lower-case letters and digits, starting with a letter" : (nm in tmk) ? "the name " nm " is used twice" : (n != 4 || a[2] == "") ? "not team: <name> | <area> | strict or core | <people>" : a[3] !~ /^(strict|core)$/ ? "\"" a[3] "\" is not strict or core" : a[4] !~ /^[1-9][0-9]*$/ ? "people \"" a[4] "\" is not a whole number of 1 or more" : "")
      if (w != "") { flag("setup", "\"team: " substr(l, 1, 40) "\"", w); next }
      tmk[nm] = 1; nt++; print nm "\t" a[2] "\t" a[3] "\t" a[4] > TM; for (k = 1; k <= a[4]; k++) { x = (a[4] == 1 ? nm : nm "-" k); lane[x] = nm; LO[++nl] = x }; next }
    function flag(k, id, why) { print k " " id " — " why > FL }
    function fields(line, from,   n, i, k) { split("", K); n = split(line, A, /\|/)
      for (i = 1; i <= n; i++) A[i] = trim(A[i])
      for (i = from; i <= n; i++) {
        if (match(A[i], /^[a-z-]+:/)) { k = substr(A[i], 1, RLENGTH - 1); if (k in K) K["?"] = k; K[k] = trim(substr(A[i], RLENGTH + 1)) }
        else if (A[i] != "") K["!" A[i]] = 1 }
      return n }
    function need(id, list,   n, a, i) { n = split(list, a, " "); for (i = 1; i <= n; i++) if (K[a[i]] == "") flag("form", id, "no " a[i] ":") }
    function unknown(id, list,   k, n) { for (k in K) if (k != "?" && index(" " list " ", " " k " ") == 0) { n = k; sub(/^!/, "", n); flag("form", id, "an unknown field \"" n "\"") }
      if ("?" in K) flag("form", id, "the field " K["?"] ": twice") }
    function marks(id, m,   nm, ms, i, x, y, owed, mk) { gsub(/,/, " ", m); nm = split(m, ms, " "); owed = ""; mk = ""
      for (i = 1; i <= nm; i++) { x = ms[i]; if (x == "-") continue
        if (x !~ /^(journey|protection|rule|seam|owed-staging|owed-production|owed-rehearsal|shell|reachability)$/) { flag("mark", id, "an unknown mark \"" x "\""); continue }
        mk = mk (mk == "" ? "" : " ") x; M[id, x] = 1
        y = (x == "seam" ? "owed-staging" : x); if (y ~ /^owed-/ && index(owed, y) == 0) owed = owed " " y }
      if (split(owed, ow, " ") > 1) flag("mark", id, "two owed- marks")
      rmarks[id] = mk; rowed[id] = trim(owed) }
    f == 1 { kind[$1] = $2; tier[$1] = $3; phase[$1] = $4; stage[$1] = $5; next }
    f == 2 { answer[$1] = 1; next }
    f == 3 { split($0, sx, "\t"); nst++; SQ[++nsq] = sx[1]; sname[sx[1]] = sx[2]; if (sx[1] == "0") has0 = 1; next }
    f == 4 { if (!($1 in so)) so[$1] = $2; next }
    f == 5 { split($0, ix, "\t"); id = ix[1]; order[++nr] = id; seen[id] = 1; rkind[id] = ix[2]; rpar[id] = ix[3]; ritem[id] = ix[4]
      marks(id, ix[5]); rp[id] = ix[6]; rf[id] = ix[7]; rc[id] = ix[8]; rg[id] = ix[9]; if (ix[10] != "") ad[id] = ix[10]
      if (ix[2] == "tr") next
      rstage[id] = (id in so) ? so[id] : (id ~ /^SEAM-/ ? 1 : "later"); next }
    f == 6 {
      id = $0; sub(/[ \t]*\|.*/, "", id); sub(/^[ \t]+/, "", id)
      if (id ~ /^standing[ \t]/) { k = id; sub(/^standing[ \t]+/, "", k); v = $0; sub(/^[^|]*\|[ \t]*/, "", v); v = trim(v)
        if (k !~ /^(rehearsal|sign-in|fields|work)$/) { flag("form", "\"standing " k "\"", "no standing kind (rehearsal, sign-in, fields, work)"); next }
        if (k in stl) { flag("form", "standing " k, "the line is written twice"); next }
        stl[k] = (index($0, "|") ? v : ""); next }
      if (id ~ /^(ROW|RULE|HOS|DIF|SEAM)-[0-9]+(-T[0-9]+)?$/) {
        if (!(id in rkind) || rkind[id] == "tr") { flag("class", id, "a class line for no row of the inventory"); next }
        if (id in cl) { flag("form", id, "the id is used twice"); next }
        cl[id] = 1; fields($0, 2); unknown(id, "moved limit")
        if (!("moved" in K) && !("limit" in K)) { flag("form", id, "a class line with no moved: and no limit:"); next }
        if (rkind[id] == "record") { flag("class", id, "a record sits in no stage; it takes no class line"); next }
        if (rstage[id] == "later") { flag("class", id, "a later-phase row; only an amendment brings it into the pilot"); next }
        rlimset[id] = ("limit" in K); rmovset[id] = ("moved" in K); rmoved[id] = K["moved"]; rlimit[id] = K["limit"]; next }
      flag("form", "\"" substr($0, 1, 40) "\"", "a line of the rows block that is no class line or standing line"); next }
    # expand <rows: value> <owner>: its ids, each range <PREFIX>-a..<PREFIX>-b of one prefix written out
    # 0.26.10.29.2 (R1): uniq, the rows of a step each once, as the admission and plan.sh canon read them
    function uniq(v,   n, t, i, r, u) { n = split(v, t, " "); r = ""; for (i = 1; i <= n; i++) if (t[i] != "" && !(t[i] in u)) { u[t[i]] = 1; r = r (r == "" ? "" : " ") t[i] } return r }
    function expand(v, o,   n, t, i, x, a, b, pa, pb, w, lo, hi, k, r) { n = split(v, t, /[ ,]+/); r = ""
      for (i = 1; i <= n; i++) { x = t[i]; if (x == "") continue
        if (x !~ /^[A-Z]+-[0-9]+\.\.[A-Z]+-[0-9]+$/) { r = r (r == "" ? "" : " ") x; continue }
        a = x; sub(/\.\..*/, "", a); b = x; sub(/.*\.\./, "", b); pa = a; sub(/-[0-9]+$/, "", pa); pb = b; sub(/-[0-9]+$/, "", pb)
        lo = a; sub(/^[A-Z]+-/, "", lo); hi = b; sub(/^[A-Z]+-/, "", hi); w = length(lo)
        if (pa != pb || hi + 0 < lo + 0 || hi - lo > 20000) { flag("form", o, "the range " x " is of two prefixes, backwards or too wide"); continue }
        for (k = lo + 0; k <= hi + 0; k++) r = r (r == "" ? "" : " ") sprintf("%s-%0" w "d", pa, k) }
      return r }
    f == 7 { l = trim($0); gsub(/\t/, " ", l); if (l == "" || l ~ /^#/) next
      if (l ~ /^shared:/) { v = trim(substr(l, 8)); nsh++; if (v == "") flag("form", "shared:", "names nothing; it names - or modules of ARCHITECTURE.md"); shv = trim(shv " " v); next }
      if (l ~ /^protected:/) { pv = trim(pv " " expand(substr(l, 11), "protected:")); next }
      if (l ~ /^needs[ \t]/) { v = substr(l, 7); p = index(v, "|"); w = trim(substr(v, p + 1)); if (!p || w == "") { flag("form", "\"" substr(l, 1, 40) "\"", "a needs line is needs <rows> | <steps, or ->"); next }   # R10
        n = split(expand(substr(v, 1, p - 1), "needs"), a, " "); for (j = 1; j <= n; j++) { if (a[j] in nd) flag("needs", a[j], "in two needs lines"); else NDO[++nnd] = a[j]; nd[a[j]] = (w == "-" ? "" : w) } next }
      if (l !~ /^step[ \t]/) { flag("form", "\"" substr(l, 1, 40) "\"", "a line of the plan block that is no step, shared:, protected: or needs line"); next }
      id = l; sub(/^step[ \t]+/, "", id); sub(/[ \t]*\|.*/, "", id); if (id == "" || id ~ /[ \t]/) { flag("form", "\"" substr(l, 1, 40) "\"", "a step line is step <id> | name: … | modules: … | builds-on: … | rows: …"); next }
      fields(l, 2)
      if (id in sseen) { flag("form", id, "the step id is used twice"); next }; sseen[id] = 1; sorder[++ns] = id; sidx[id] = ns
      unknown(id, "name modules builds-on rows lane kind fakes"); need(id, "name modules rows")
      sn[id] = K["name"]; smod[id] = K["modules"]; srows[id] = uniq(expand(K["rows"], id)); sb[id] = (K["builds-on"] == "-" ? "" : K["builds-on"]); slane[id] = K["lane"]; skind[id] = K["kind"]; ssk[id] = (K["kind"] == "skeleton")
      sfk[id] = (K["fakes"] == "-" ? "" : K["fakes"]); if (skind[id] != "" && skind[id] !~ /^(skeleton|hardening)$/) flag("form", id, "kind " skind[id] "; a kind is skeleton, hardening, or absent")
      next }
    f == 8 { mod[$0] = 1; next }
    f == 9 { if (!($1 in PSG)) PSG[$1] = $2; next }
    END {
      for (i = 1; i <= nr; i++) { id = order[i]; if (rkind[id] != "row" || !M[id, "protection"] || rstage[id] == "later") continue
        n = split(ritem[id], a, " "); for (j = 1; j <= n; j++) { x = a[j]; prot[x] = prot[x] (prot[x] == "" ? "" : " ") id } }
      for (it in kind) if (tier[it] == "T0" && phase[it] != "later" && !(it in prot)) flag("protection", it, "a must-never-happen item with no protection row")
      for (i = 1; i <= nr; i++) { id = order[i]; if (!(id in ad) || !M[id, "protection"] || !(ad[id] in prot)) continue; n = split(prot[ad[id]], a, " ")
        for (j = 1; j <= n; j++) if (a[j] != id) { flag("protection", id, ad[id] " already has a protection row, " a[j]); break } }
      for (i = 1; i <= nr; i++) { id = order[i]; if (rkind[id] != "row" || rstage[id] == "later") continue; mv = rmoved[id]; lm = rlimit[id]
        if (lm != "" && mv != "") flag("class", id, "both moved: and limit:; a row has one class")
        if (rlimset[id] && lm == "") flag("form", id, "limit: names no answer")
        if (rmovset[id] && mv == "") flag("form", id, "moved: names no stage and answer")
        if (lm != "") { if (lm !~ /^A-[0-9]+$/) flag("form", id, "limit: is not one A-NNN"); else if (!(lm in answer)) flag("answer", id, lm " is no answer of PRD.md") }
        if (mv != "") { n = split(mv, a, " "); k = a[1]; sub(/^STAGE-/, "", k)
          if (n != 2 || a[1] !~ /^STAGE-[0-9]+$/ || a[2] !~ /^A-[0-9]+$/) { flag("form", id, "moved: is not STAGE-<n> A-NNN"); mv = "" }
          else { if (!(a[2] in answer)) flag("answer", id, a[2] " is no answer of PRD.md")
            if (!(k in sname)) { flag("moved", id, a[1] " is no stage"); mv = "" }
            else if (rstage[id] != "?" && k + 0 <= rstage[id] + 0) { flag("moved", id, a[1] " is not later than its stage " rstage[id]); mv = "" }
            else rstage[id] = k } }
        o = rowed[id]; sub(/^owed-/, "", o)
        if (lm != "") { cls[id] = "limit"; ctext[id] = "known limit (" lm ")" }
        else if (mv != "") { cls[id] = "moved"; ctext[id] = "moved to stage " rstage[id] " by the owner (" a[2] ")" }
        else if (o != "") { cls[id] = "owed"; ctext[id] = "deploy-owed: " o ", in stage " rstage[id] }
        else { cls[id] = "planned"; ctext[id] = "planned to stage " rstage[id] } }
      for (i = 1; i <= nr; i++) { id = order[i]
        if (rkind[id] == "record") { cls[id] = "record"; ctext[id] = "record: deliberately not tested, in no step" }
        else if (rkind[id] == "row" && rstage[id] == "later") { cls[id] = "later"; ctext[id] = "later phase, in no step until an amendment brings it in" } }
      for (i = 1; i <= ns; i++) { s = sorder[i]; n = split(srows[s], a, " ")
        for (j = 1; j <= n; j++) { r = a[j]; if (!(r in rkind) || rkind[r] == "tr") continue
          if (r in instep) flag("step", r, "in two steps, " instep[r] " and " s); else instep[r] = s
          if (cls[r] == "limit") flag("class", r, "a known limit, in step " s)
          if (cls[r] == "record") flag("class", r, "a record, in step " s)
          if (cls[r] == "later") flag("class", r, "a later-phase row, in step " s) } }
      # GM-1 S3 (§5), GM M2 (rows to place, accepted in the owner words): in GitHub manual a row in no step is a row to place, a flag the switch may accept
      for (i = 1; i <= nr; i++) { id = order[i]; if (rkind[id] == "row" && cls[id] ~ /^(planned|moved|owed)$/ && !(id in instep)) { if (MAN) flag("place", id, "in no step"); else flag("class", id, "in no step, and no known limit, later-phase row or record") } }
      for (it in kind) if (kind[it] == "data_entity" && phase[it] != "later") keeps = keeps (keeps == "" ? "" : ", ") it
      for (i = 1; i <= nr; i++) { id = order[i]; if (rkind[id] == "row" && M[id, "owed-rehearsal"] && cls[id] != "later") reh = 1 }
      split("rehearsal sign-in fields work", sk, " ")
      for (j = 1; j <= 4; j++) { k = sk[j]
        if (!(k in stl)) { flag("standing", k, "no `standing " k "` line"); continue }
        v = stl[k]
        if (v ~ /^none:/) { w = v; sub(/^none:[ \t]*/, "", w); if (w == "") flag("standing", k, "none: says no why"); if (k == "rehearsal" && keeps != "") flag("standing", k, "none:, but the product keeps data (" keeps ")"); continue }
        n = split(v, a, /[ ,]+/); c = 0
        for (i = 1; i <= n; i++) { if (a[i] == "") continue; c++; named[a[i]] = 1; if (!(a[i] in rkind) || rkind[a[i]] != "row") flag("standing", k, a[i] " is no planned row") }
        if (!c) flag("standing", k, "the line names no planned row and says no none:") }
      for (i = 1; i <= nr; i++) { id = order[i]; if (!(id in ad)) continue; it = ad[id]
        if (!(it in kind) || phase[it] == "later") flag("form", id, "origin: plan names " it ", no effective pilot REQ- or INV- of PRD.md")
        c = " · " rc[id] " · "
        if (id ~ /^HOS-/) { if (ritem[id] != it || tier[it] != "T0" || index(c, " · protects: " it " · ") == 0) flag("form", id, "an origin: plan hostility row protects its own item, one must-never-happen item, alone")
          if (index(c, " · disable: ") == 0 || index(c, " · disable:  · ") > 0) flag("form", id, "an origin: plan hostility row with no disable:") }
        if (id ~ /^(HOS|RULE)-/ && index(c, " · test: owed: spec-only — ticket · ") == 0) flag("form", id, "an origin: plan row whose test field is not owed: spec-only — ticket")
        if (id ~ /^RULE-/ && index(c, " · census: ") == 0) flag("form", id, "an origin: plan rule with no census of places in words")
        if (id ~ /^ROW-/ && c !~ / · test: owed: paid by \/vid deploy gate [123]/) flag("form", id, "an origin: plan ROW whose test field is not owed: paid by /vid deploy gate N")
        if (id ~ /^HOS-/) ;
        else if (id ~ /^ROW-/) { if (rowed[id] == "") flag("form", id, "an origin: plan ROW is paid at a deploy gate"); else if (!(id in named)) flag("form", id, "an origin: plan deploy-paid row no standing line names") }
        else if (id ~ /^RULE-/) { if (!(id in named)) flag("form", id, "an origin: plan rule no standing line names") }
        else flag("form", id, "an origin: plan row of no kind ViD adds (hostility, a deploy-paid ROW, rule)") }
      if (keeps != "" && !reh) flag("standing", "rehearsal", "the product keeps data (" keeps ") and no row is owed to the rehearsal")
      for (i = 1; i <= nr; i++) { id = order[i]; if (rkind[id] == "row" && cls[id] != "limit" && rstage[id] == "0") s0[id] = 1 }
      for (i = 1; i <= ns; i++) if (ssk[sorder[i]]) { if (skel == "") skel = sorder[i]; else flag("skeleton", sorder[i], "a second step of kind: skeleton; the plan has one") }
      if (!ns) flag("skeleton", "-", "no step: RUN-STATE has no plan block under ## The plan, or it holds no step"); else if (skel == "") flag("skeleton", "-", "no step is kind: skeleton")
      if (!nsh) flag("form", "shared:", "the plan block has no shared: line; it names - or modules of ARCHITECTURE.md"); n = split(shv, a, /[ ,]+/); for (j = 1; j <= n; j++) if (a[j] != "" && !(a[j] == "-" && n == 1) && !(a[j] in mod)) flag("module", "shared", a[j] " is no module of ARCHITECTURE.md")
      n = split(pv, a, " "); for (j = 1; j <= n; j++) if (!(a[j] in rkind) || rkind[a[j]] != "row") flag("step", "protected:", a[j] " is no planned row")
      for (i = 1; i <= ns; i++) { s = sorder[i]; n = split(srows[s], a, " "); sst[s] = "?"; got = ""; c = 0; split("", has)
        m = split(smod[s], mb, /[ ,]+/); for (j = 1; j <= m; j++) if (mb[j] != "" && !(mb[j] in mod)) flag("module", s, mb[j] " is no module of ARCHITECTURE.md")
        for (j = 1; j <= n; j++) { r = a[j]; if (r == "-") continue
          if (!(r in rkind)) { flag("step", s, r " is no planned row"); continue }
          if (rkind[r] == "tr") { flag("step", s, r " is no planned row: a transition; its journey stands for it"); continue }
          c++; last = r; has[r] = 1; if (r ~ /^(HOS|RULE|DIF|SEAM)-/) gd[s]++; if (sst[s] == "?") sst[s] = rstage[r]; if (index(" " got " ", " " rstage[r] " ") == 0) got = got (got == "" ? "" : " and ") rstage[r]
          if (MAN && cls[r] ~ /^(planned|moved|owed)$/) { if (!((s, rstage[r]) in pc)) pst[s] = pst[s] " " rstage[r]; pc[s, rstage[r]]++ } }   # D4, GM M4: the stages of the planned rows of a step, for its own stage
        # GM-1 S3 (§5), D4 and GM M4 (the stage of a step is its own), GM M2 (rows to place): in GitHub manual the own stage of a step is the stage most of its planned rows are in, the earliest on a tie; each
        # planned row of another stage is a row to place, `place <row> — in step <s> of stage <k>; its own stage is <j>`, in place of
        # the step-level "its rows are in stages" flag
        # GM-3 S2: a step with a published ticket is of the stage the header of its ticket names (PSG), its rows of another stage to place
        if (MAN && (pst[s] != "" || (s in PSG))) { m = split(pst[s], qa, " "); bst = ""
          for (j = 1; j <= m; j++) { k = qa[j]; if (bst == "" || pc[s, k] > pc[s, bst] || (pc[s, k] == pc[s, bst] && before(k, bst))) bst = k }
          if (s in PSG) bst = PSG[s]; sst[s] = bst; for (j = 1; j <= n; j++) { r = a[j]; if ((r in rkind) && rkind[r] == "row" && cls[r] ~ /^(planned|moved|owed)$/ && rstage[r] != bst && !(r in placed)) { placed[r] = 1; flag("place", r, "in step " s " of stage " bst "; its own stage is " rstage[r]) } } }
        cnt[s] = c; if (!MAN && got ~ / and /) flag("step", s, "its rows are in stages " got); if (!c && srows[s] != "") flag("step", s, "holds no row")   # D4: in GitHub manual the own stage of the step stands for this flag
        # GM-1 S4, GM M4: in GitHub manual stage 0 may hold several steps, the skeleton one of them
        if (c > CEIL + 0) flag("size", s, c " rows, over the ceiling of " CEIL "; split it"); if (!MAN && !ssk[s] && sst[s] == "0") flag("skeleton", s, "is in stage 0; stage 0 holds the skeleton alone")
        if (s == skel) { if (sb[s] != "") flag("skeleton", s, "builds on " sb[s] "; the skeleton builds on nothing")
          z = 0; if (MAN) for (r in s0) z++   # GM M4: the steps of stage 0
          # GM-1 S4, GM M4: in GitHub manual, with a stage 0, the skeleton is one of its steps; each stage-0 row is in one of them, or a row to place
          # GM-3 S2: a published skeleton ticket is the skeleton of stage 0, so neither this flag nor the no-stage-0 ones below refuse it
          if (MAN && (z || (s in PSG))) { if (sst[s] != "0" && !(s in PSG)) flag("skeleton", s, "is in stage " sst[s] "; with a stage 0 the skeleton is one of stage 0" "\047" "s steps") }
          else { z = 0; for (r in s0) { z++; if (!(r in has)) flag("skeleton", s, "lacks " r ", a row of stage 0") }
          if (z) { for (r in has) if (!(r in s0)) flag("skeleton", s, "holds " r ", which is no row of stage 0") }
          else { if (c != 1) flag("skeleton", s, "holds " c " rows; with no stage 0 the skeleton holds one, the golden path"); if (c == 1 && rstage[last] != "1") flag("skeleton", s, "its row " last " is in stage " rstage[last] ", not stage 1") } }
          for (r in has) if (rowed[r] != "") flag("skeleton", s, "its row " r " is deploy-owed or a seam") } }
      for (i = 1; i <= ns; i++) { s = sorder[i]; n = split(sb[s], a, /[ ,]+/); for (j = 1; j <= n; j++) { b = a[j]; if (b == "") continue
          if (!(b in sidx)) flag("step", s, "builds on " b ", which is no step")
          else if (sidx[b] >= i) flag("step", s, "builds on " b ", a later step")
          else if (sst[b] ~ /^[0-9]+$/ && sst[s] ~ /^[0-9]+$/ && sst[b] + 0 > sst[s] + 0) flag("step", s, "builds on " b ", a step of a later stage") } }
      # R2: each step in a lane of the setup (devagent with no team: line); its dashed links name other steps
      if (!nt) { print "devagent\tthe whole product\tcore\t1" > TM; lane["devagent"] = "devagent"; LO[++nl] = "devagent" }
      for (i = 1; i <= nl; i++) { print LO[i] "\t" lane[LO[i]] > LN; ll = ll (i > 1 ? ", " : "") LO[i] } if (ll == "") ll = "none"
      for (i = 1; i <= ns; i++) { s = sorder[i]; x = slane[s]; slane[s] = x = tolower(x)   # GM-3 S2, GM-4 F11: as the names of the setup, in both modes
        if (x == "" || x == "-") { if (nl > 1) flag("lane", s, "no lane; with " nl " lanes every step names one (" ll ")") } else if (!(x in lane)) flag("lane", s, "lane " x " is no lane of the setup (" ll ")")
        n = split(sfk[s], a, /[ ,]+/); for (j = 1; j <= n; j++) { b = a[j]; if (b == "") continue
          if (!(b in sidx)) flag("step", s, "fakes " b ", which is no step"); else if (b == s) flag("step", s, "fakes itself"); else if (on(sb[s], b)) flag("step", s, "fakes " b ", which it also builds on") } }
      # R10: every row of a step in one needs line; each step it needs a step its own builds on, of its stage or earlier
      for (i = 1; i <= nr; i++) { r = order[i]; if ((r in instep) && !(r in nd)) flag("needs", r, "in step " instep[r] ", and in no needs line") }
      for (i = 1; i <= nnd; i++) { r = NDO[i]; s = ((r in instep) ? instep[r] : ""); rsg = ((s in PSG) ? PSG[s] : rstage[r])   # GM-3 S2: the stage of the ticket of its step
        if (s == "") { flag("needs", r, (!(r in rkind) ? "no row of the inventory" : rkind[r] == "tr" ? "a transition; its journey stands for it" : rkind[r] == "record" ? "a record" : cls[r] == "limit" ? "a known limit" : cls[r] == "later" ? "a later-phase row" : "in no step") "; a needs line names rows of steps"); continue }
        n = split(nd[r], a, /[ ,]+/); for (j = 1; j <= n; j++) { t = a[j]; if (t == "") continue
          if (!(t in sidx)) flag("needs", r, "needs " t ", which is no step"); else if (t == s) flag("needs", r, "needs " t ", its own step")
          else if (sst[t] ~ /^[0-9]+$/ && rsg ~ /^[0-9]+$/ && sst[t] + 0 > rsg + 0) flag("needs", r, "needs " t ", a step of stage " sst[t] ", later than its own stage " rsg ": list it under Provable only at a later stage")
          else if (!rch(s, t)) flag("needs", r, r " in " s " needs " t ", which " s " does not build on" (on(sfk[s], t) ? "; only a dashed link" : "")) } }
      # R5: the notes, beside the flags and never one — steps ahead of the stage order; journeys not built on their home
      for (i = 1; i <= ns; i++) { s = sorder[i]; w = 1; n = split(sb[s], a, /[ ,]+/); for (j = 1; j <= n; j++) if ((a[j] in sidx) && sidx[a[j]] < i && wv[a[j]] >= w) w = wv[a[j]] + 1
        wv[s] = w; if (sst[s] ~ /^[0-9]+$/ && w > LW[sst[s]]) LW[sst[s]] = w }
      for (q = 2; q <= nsq; q++) { k = SQ[q]; mx = 0; for (p = 1; p < q; p++) if (LW[SQ[p]] > mx) mx = LW[SQ[p]]; c = 0; o = ""
        for (i = 1; i <= ns; i++) { s = sorder[i]; if (sst[s] == k && wv[s] <= mx) o = o (c++ ? ", " : "") s " (wave " wv[s] ")" }
        if (c) print "stage " k ": " c (c > 1 ? " steps can start, by their links," : " step can start, by its links,") " before an earlier stage" "\047" "s last step is done: " o "; admission" "\047" "s stage rule holds a step of stage " k " until stage " SQ[q - 1] " has its candidate" > NO }
      for (i = 1; i <= nr; i++) { r = order[i]; if (!(r in instep) || M[r, "journey"]) continue; n = split(ritem[r], a, " "); for (j = 1; j <= n; j++) HC[a[j], instep[r]]++ }
      for (i = 1; i <= nr; i++) { r = order[i]; if (!(r in instep) || !M[r, "journey"]) continue; s = instep[r]; n = split(ritem[r], a, " "); nh = 0; split("", HO); o = ""
        for (j = 1; j <= n; j++) { h = ""; for (p = 1; p <= ns; p++) if (HC[a[j], sorder[p]] > HC[a[j], h] + 0) h = sorder[p]
          if (h == "" || h == s || sst[h] + 0 > sst[s] + 0 || rch(s, h)) continue; if (h in HO) HO[h] = HO[h] ", " a[j]; else { HO[h] = a[j]; HL[++nh] = h } }
        for (j = 1; j <= nh; j++) o = o (j > 1 ? "; " : "") HL[j] " (" HO[HL[j]] (on(sfk[s], HL[j]) ? "; only a dashed link" : "") ")"
        if (nh) print r " in " s " does not build on " o > NO }
      # v0.26.10.12.3.2: per step, needs lines that only repeat its builds-on (R7); rows held 10 or more places late (R8); over 40 rows (R9)
      for (i = 1; i <= ns; i++) { s = sorder[i]; n = split(srows[s], a, " "); c = 0; cp = 0; h = 0; o = ""
        for (j = 1; j <= n; j++) { r = a[j]; if (!(r in nd)) continue; c++; if (same(nd[r], sb[s])) cp++; w = 1; m = split(nd[r], mb, /[ ,]+/)
          for (p = 1; p <= m; p++) if ((mb[p] in sidx) && sidx[mb[p]] > w) w = sidx[mb[p]]; if (i - w >= 10) o = o (h++ ? ", " : "") r }
        x = sb[s]; gsub(/[ ,]+/, ", ", x); if (x != "" && c && cp == c) print s ": every needs line repeats its builds-on (" x "); read its rows one by one" > NO
        if (h) print s ": " h " rows sit 10 or more steps after the last step they need: " o > NO
        if (cnt[s] > 40) print s ": " cnt[s] " rows, over 40; the aim is about 30" > NO }
      for (i = 1; i <= nr; i++) { id = order[i]; t = rkind[id]; if (t == "tr") { pj = rpar[id]; st = rstage[pj]; c = ""; ct = "with its journey" } else { st = rstage[id]; c = cls[id]; ct = ctext[id] }
        print id "\t" t "\t" rpar[id] "\t" ritem[id] "\t" st "\t" c "\t" rmarks[id] "\t" rp[id] "\t" rf[id] "\t" ct "\t" rc[id] "\t" rg[id] > RW }
      for (i = 1; i <= ns; i++) { s = sorder[i]; print s "\t" sn[s] "\t" sst[s] "\t" srows[s] "\t" sb[s] "\t" ssk[s] "\t" smod[s] "\t" skind[s] "\t" slane[s] "\t" cnt[s] "\t" sfk[s] "\t" gd[s] + 0 > SP }; print shv > SH
    }' f=0 "$T/set" f=1 "$T/items" f=2 "$T/answers" f=3 "$T/stages" f=4 "$T/stageof" f=5 "$T/irows" f=6 "$T/rowsblk" f=7 "$T/stepsblk" f=8 "$T/mods" f=9 "$T/pubst"
  touch "$T/flags" "$T/rows" "$T/steps" "$T/shared" "$T/teams" "$T/lanes" "$T/notes"
  cat "$T/iflags" "$T/flags" > "$T/fl0"
  if [ -f PLAN.md ] && grep -q '^```vid-steps' PLAN.md; then echo "form PLAN.md — a vid-steps block; the steps are RUN-STATE's plan block, in develop's form" >> "$T/fl0"; fi
  # in GitHub manual a golden set is read at the applied commit, as the rows that cite it are
  awk -F'\t' '$12 != "-" { print $1 "\t" $12 }' "$T/rows" | while IFS='	' read -r id g; do if [ -n "${ORIG:-}" ]; then [ "$(git -C "$ORIG" cat-file -t "$SNAPC:./$g" 2>/dev/null)" = blob ]; else [ -f "$g" ]; fi || echo "golden $id — its golden set is not in ViD's repository"; done >> "$T/fl0"
  # P1: inside a repository, INVENTORY.md changes since HEAD only in its origin: plan rows
  # GM-1 S3, GM M3 (the spec as the team has it): in GitHub manual the inventory read is the applied commit's, a commit by definition: P1 does not apply
  if [ -z "$MAN" ] && git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    if git show HEAD:./INVENTORY.md > "$T/ih" 2>/dev/null; then
      grep -vE '[|][[:space:]]*origin: plan( |$)' "$T/ih" > "$T/ia" || true; grep -vE '[|][[:space:]]*origin: plan( |$)' INVENTORY.md > "$T/ib" || true
      L=$(diff "$T/ia" "$T/ib" | sed -n 's/^[<>] //p' | head -n 1 | cut -c1-60)
      if [ -n "$L" ] || ! cmp -s "$T/ia" "$T/ib"; then echo "inventory INVENTORY.md — changed since HEAD outside its origin: plan rows (\"$L\")" >> "$T/fl0"; fi
    else echo 'inventory INVENTORY.md — not committed; PL plans only a committed inventory' >> "$T/fl0"; fi
  fi
  # v0.26.10.26.7 (R11, W-13): before the first ratify, each setup key no setup-answered line covers (a written default is no
  # answer); a plan ratified before this release, with no such lines in .vid/plan/setup, is never flagged for them
  # GM-1 S1, GM M15 (ViD's own state repository): in GitHub manual state-repo too; GM M2 (the mode recorded last): under /vid mode's mark github-mode is not asked, as the switch records it last
  if [ ! -s .vid/plan/ratified ]; then KS='layout team split repo spec-repo github-mode'
    if manual; then KS='layout team split repo spec-repo state-repo'; [ "${VID_CALLER:-}" = mode ] || KS="$KS github-mode"; fi   # GM M15, GM M2
    for k in $KS; do grep -q "^setup-answered key=$k " .vid/plan/setup 2>/dev/null && continue   # GM-4 J5: spec-repo in both layouts
      echo "setup $k — no answer of the owner's is recorded: ask it, then sh checks/planner.sh setup $k <the answer> --words \"<their words>\"" >> "$T/fl0"; done; fi
  mv "$T/fl0" "$T/flags"
  # GM-1 S3 (§5), GM M2 (rows to place, in the owner's words): in GitHub manual a row .vid/tw/to-place lists in the place its flag names (no-step, other-stage) is no flag: it
  # goes to $T/toplace, `<row>\t<no-step|other-stage>\t<where>\t<the owner's words>`, for the page
  : > "$T/toplace"
  if [ -n "$MAN" ] && [ -s .vid/tw/to-place ]; then   # GM M2
    awk -v TP="$T/toplace" 'FNR == NR { if (NF < 2) next; w = $0; if (index(w, "\t")) sub(/^[^\t]*\t[^\t]*\t[^\t]*\t?/, "", w); else sub(/^[^ ]+ +[^ ]+ +[^ ]+ */, "", w); K[$1, $2] = 1; W[$1, $2] = w; next }
      $1 == "place" { p = ($0 ~ / — in no step$/) ? "no-step" : "other-stage"; if (($2, p) in K) { x = $0; sub(/^place [^ ]+ — /, "", x); print $2 "\t" p "\t" x "\t" W[$2, p] > TP; next } }
      { print }' .vid/tw/to-place "$T/flags" > "$T/fl1"; mv "$T/fl1" "$T/flags"
  fi
}
# reviewed <hash>: prints yes when a review has that hash, else no; $T/open holds every finding of every review with
# that hash that has no answer, `<n> | <row id> | <why>` each (a later review never closes an earlier finding)
reviewed() {
  : > "$T/open"; [ -f "$RV" ] || { echo no; return 0; }
  awk -v h="hash=$1" -v O="$T/open" '
    $1 == "review" && $3 == h { last = $2 }
    $1 == "finding" && $4 == h { t = $0; sub(/^[^|]*\|[ \t]*/, "", t); ft[$2] = t; no[++n] = $2 }
    $1 == "answer" { ans[$2] = 1 }
    END { for (i = 1; i <= n; i++) { k = no[i]; if (!(k in ans)) print k " | " ft[k] > O }
      print (last == "" ? "no" : "yes") }' "$RV"
}
# rounds (low-1, R5): the rounds of review of this sitting — the review lines after .vid/plan/review's newest `ratified after-review=`
# line (ratify and reratify append it); with none, after the newest review at the newest ratification's hash; with neither, from
# the first. They close after the sitting's 3rd review, or after one that finds no fewer than the one before: then it prints
# `<r> <hash> <why>`, r the review that closed them, else nothing
rounds() { [ -f "$RV" ] || return 0
  RH=$(tail -n 1 .vid/plan/ratified 2>/dev/null | sed -n 's/^ratified hash=\([0-9a-f]*\) .*/\1/p')
  awk -v rh="hash=$RH" '$1 == "ratified" && $2 ~ /^after-review=/ { mk = n + 0; hm = 1 }
    $1 == "review" { n++; r[n] = $2; h[n] = substr($3, 6); k[n] = substr($4, 10) + 0; if ($3 == rh) at = n }
    END { s = hm ? mk : at + 0; for (i = s + 1; i <= n; i++) {
        if (i - s == 3) { print r[i] " " h[i] " it was the 3rd review of this sitting"; exit }
        if (i - s >= 2 && k[i] >= k[i - 1]) { print r[i] " " h[i] " review number " r[i] " found " k[i] ", no fewer than review number " r[i - 1] "\047s " k[i - 1]; exit } } }' "$RV"; }
# openat <hash>: RVD and $T/open as reviewed() gives them for <hash>; once the rounds close (CL, low-1 R5), for NH, the hash of the
# newest review line (in a history the base wrote, that can be a review after the one that closed them)
openat() { CL=$(rounds); NH=''; if [ -n "$CL" ]; then NH=$(sed -n 's/^review [0-9][0-9]* hash=\([0-9a-f]*\) .*/\1/p' "$RV" | tail -n 1); RVD=$(reviewed "$NH"); else RVD=$(reviewed "$1"); fi; }

# counts (R5): every column from the rows table, each row after its move; inventory= is rows less seams and ViD's own
counts() {
  awk -F'\t' -v ST="$T/stages" -v IT="$T/items" -v SP="$T/steps" '
    BEGIN { while ((getline l < ST) > 0) { split(l, a, "\t"); n[++k] = a[1]; nm[a[1]] = a[2] }
      while ((getline l < IT) > 0) { split(l, a, " "); if (a[4] != "later") req[a[5]]++ }
      while ((getline l < SP) > 0) { split(l, a, "\t"); stp[a[3]]++ } }
    $2 != "tr" { s = ($6 == "later" ? "later" : $5); rows[s]++; c[s, $6]++; if ($11 ~ /(^| · )origin: plan( |$)/) pl[s]++; if ($1 ~ /^SEAM-/) sm[s]++ }
    $2 == "tr" { tr[$5]++ }
    function line(h, s, nm) { printf "%s inventory=%d seams=%d added=%d rows=%d planned=%d moved=%d owed=%d limit=%d record=%d transitions=%d steps=%d requirements=%d%s\n", h, rows[s] - sm[s] - pl[s], sm[s], pl[s], rows[s], c[s, "planned"], c[s, "moved"], c[s, "owed"], c[s, "limit"], c[s, "record"], tr[s], stp[s], req[s], nm }
    END { split("planned moved owed limit record", x, " ")
      for (i = 1; i <= k; i++) { s = n[i]; line("stage " s, s, " | " nm[s])
        sm["*"] += sm[s]; pl["*"] += pl[s]; rows["*"] += rows[s]; tr["*"] += tr[s]; stp["*"] += stp[s]; req["*"] += req[s]; for (j = 1; j <= 5; j++) c["*", x[j]] += c[s, x[j]] }
      printf "later rows=%d transitions=%d\n", rows["later"], tr["later"]
      line("total", "*", "") }' "$T/rows"
}
# table <ids>: the rows given, as the page shows them, each journey followed by its transitions, a golden-set row
# naming its set; goldens: each set once (R6), read from ViD's repository, with the rows citing it. GN: a set's short name
GN='function gn(g) { sub(/.*\//, "", g); sub(/\.[^.]*$/, "", g); return g }'
table() {
  awk -F'\t' -v IDS="$1" "$GN"'
    function cell(s) { gsub(/\|/, "¦", s); return s == "" ? "—" : s }
    function car(x,   g) { g = R[x, 12]; return (g == "" || g == "-") ? R[x, 11] : R[x, 11] (R[x, 11] == "" ? "" : " · ") "golden set: " gn(g) }
    BEGIN { n = split(IDS, w, " "); for (i = 1; i <= n; i++) want[w[i]] = i }
    { id[NR] = $1; for (j = 1; j <= 12; j++) R[$1, j] = $j; if ($2 == "tr") kids[$3] = kids[$3] " " $1 }
    function row(x, y) { print "| " x " | " cell(y == "" ? R[x, 4] : R[y, 4] ", a transition of " y) " | " cell(R[x, 8]) " | " cell(R[x, 9]) " | " cell(R[x, 7]) " | " cell(y == "" ? R[x, 10] : "with its journey") " | " cell(y == "" ? car(x) : "—") " |" }
    END { if (!n) { print ""; print "None."; exit }
      print ""; print "| Row | Requirements | Promise | Fail-if | Marks | Class | Carried |"; print "|---|---|---|---|---|---|---|"
      for (i = 1; i <= n; i++) { x = w[i]; if (!((x, 1) in R)) continue; row(x, ""); m = split(kids[x], t, " "); for (j = 1; j <= m; j++) row(t[j], x) } }' "$T/rows"
}
goldens() {
  GP=''; if [ -n "${ORIG:-}" ]; then GP=$T/gold/; awk -F'\t' '$12 != "-" && $12 != "" { print $12 }' "$T/rows" | sort -u | while IFS= read -r g; do mkdir -p "$GP$(dirname "$g")"; git -C "$ORIG" show "$SNAPC:./$g" > "$GP$g" 2>/dev/null || rm -f "$GP$g"; done; fi
  awk -F'\t' -v GP="$GP" "$GN"' $12 != "-" && $12 != "" { g = $12; if (!(g in C)) { O[++n] = g; D[gn(g)]++ } C[g] = C[g] (C[g] == "" ? "" : ", ") $1 }
    END { if (!n) { print ""; print "None." } for (i = 1; i <= n; i++) { g = O[i]; f = g; sub(/\/?[^\/]*$/, "", f); print ""; print "### " gn(g) (D[gn(g)] > 1 ? " (" f ")" : ""); print ""; print "Cited by " C[g] "."; print ""; print "```"
        r = (getline l < (GP g)); if (r < 0) print "(not in ViD'"'"'s repository: flagged)"; while (r > 0) { print l; r = (getline l < (GP g)) } close(GP g); print "```" } }' "$T/rows"
}
# planpage: the page's plan section (R7)
planpage() {
  C=$(ceil); printf '\n## The plan\n\nRUN-STATE'"'"'s plan block, in develop'"'"'s form; its hash `%s`. %s Rule A'"'"'s ceiling: %s rows\na step, a journey counted once. Guards: its hostility, rule, difference and seam rows. Dashed: its fakes:, the steps\nwhose agreed interface it builds against.\n\n| Step | Name | Kind | Lane | Modules | Rows | Guards | Builds on | Dashed |\n|---|---|---|---|---|---|---|---|---|\n' "$(phash)" "$(if [ "$(grep -c '^team:' "$T/set")" -gt "$(grep -c '^setup ' "$T/flags")" ]; then echo 'Each step is built by the team its lane names.'; else echo 'DevAgent builds every step.'; fi)" "$C"
  awk -F'\t' -v c="$C" '{ b = $5; gsub(/ /, ", ", b); d = $11; gsub(/ /, ", ", d); printf "| %s | %s | %s | %s | %s | %s of %s | %s | %s | %s |\n", $1, $2, ($8 == "" ? "feature" : $8), ($9 == "" || $9 == "-" ? "none" : $9), $7, $10 + 0, c, $12 + 0, (b == "" ? "nothing" : b), (d == "" ? "none" : d)
    if (NR == 1 || $10 + 0 > hi) { hi = $10 + 0; h = $1 } if (NR == 1 || $10 + 0 < lo) { lo = $10 + 0; l = $1 } } END { if (NR) printf "\nThe largest step: %s, %d rows. The smallest: %s, %d rows.\n", h, hi, l, lo }' "$T/steps"
  printf '\nShared: %s.\n\n' "$(cat "$T/shared")"; prose
  if [ "$(grep -c . "$T/lanes")" -gt 1 ]; then printf '\n### The lanes\n\nEach lane'"'"'s steps, in block order, with their rows.\n\n'
    awk -F'\t' 'FNR == NR { tm[$1] = $2; lo[++n] = $1; next } { st[$1] = $9; l[$9] = l[$9] (l[$9] == "" ? "" : ", ") $1 " (" ($10 + 0) " rows)"; B[$1] = $5; D[$1] = $11; O[++m] = $1 }
      END { for (i = 1; i <= n; i++) printf "- **%s** (%s): %s\n", lo[i], tm[lo[i]], (l[lo[i]] == "" ? "no step" : l[lo[i]]); printf "\nThe links between steps of different teams:\n\n"
        for (i = 1; i <= m; i++) { s = O[i]; for (k = 1; k <= 2; k++) { q = split(k == 1 ? B[s] : D[s], a, /[ ,]+/); for (j = 1; j <= q; j++) { b = a[j]
          if ((st[s] in tm) && (st[b] in tm) && tm[st[s]] != tm[st[b]]) { c++; printf "- %s (%s) → %s (%s), %s\n", s, tm[st[s]], b, tm[st[b]], (k == 1 ? "solid" : "dashed") } } } }
        if (!c) print "- none" }' "$T/lanes" "$T/steps"; fi
  printf '\n### The width\n\nEach step'"'"'s wave is one more than the deepest step it builds on; the steps of one wave can run side by side.\nThe waves follow builds-on: alone: a dashed link (fakes:) holds no step.\n\n'
  awk -F'\t' '{ w = 1; n = split($5, a, /[ ,]+/); for (i = 1; i <= n; i++) if (a[i] in wv && wv[a[i]] + 1 > w) w = wv[a[i]] + 1; wv[$1] = w; if (w > mx) mx = w; c[w]++; ids[w] = ids[w] (ids[w] == "" ? "" : ", ") $1
      for (i = 1; i <= n; i++) if ((a[i] in wv) && wv[a[i]] == w - 1) { bp[$1] = a[i]; break } if (w > bw) { bw = w; be = $1 } }
    END { for (i = 1; i <= mx; i++) { printf "- wave %d: %d (%s)\n", i, c[i], ids[i]; if (c[i] > wd) wd = c[i] } printf "\n%d waves for %d steps; the widest wave holds %d.\n", mx, NR, wd
      for (x = be; x != ""; x = bp[x]) o = o (o == "" ? "" : ", ") x; if (NR) printf "The longest chain, %d steps, from last to first: %s.\n", bw, o
      print "\nRow counts are not effort: a step'"'"'s rows say what it must prove, not how long it takes." }' "$T/steps"
  printf '\n### The plan'"'"'s changes, newest first\n\n'
  awk 'function kv(e, k) { return match(e, " " k "=[^ ]*") ? substr(e, RSTART + length(k) + 2, RLENGTH - length(k) - 2) : "" }
    $1 == "plan-change" { l[++n] = $0 } END { if (!n) print "None recorded."; for (i = n; i >= 1; i--) { e = l[i]; w = e; sub(/.* why="/, "", w); sub(/" at=.*/, "", w)
      d = kv(e, "decision"); f = ".vid/plans/decisions/" d ".why"; split("", V); while ((getline x < f) > 0) { k = x; sub(/=.*/, "", k); sub(/^[^=]*=/, "", x); if (!(k in V)) V[k] = x } close(f)
      printf "- **%s** (decision %s, plan %s): why — %s; trigger — %s; evidence — %s; expected — %s.\n", kv(e, "what"), d, kv(e, "hash"), w, V["trigger"], V["evidence"], V["expect"] } }' .vid/metrics-events 2>/dev/null || echo 'None recorded.'
}
# setuppage: the page's setup section (R4) — the answers kept in .vid/tw/settings, read as their defaults when missing
sk() { sed -n "s/^$1:[[:space:]]*//p" "$T/set" | head -n 1 | sed 's/[[:space:]]*$//'; }
setuppage() { L=$(sk layout); R=$(sk repo); S=$(sk spec-repo); X=$(sk split); A=$(sk access); O=$(sk open-tickets); W=''
  for k in layout repo split team github-mode labels-prefix; do grep -q "^$k:" "$T/set" || W="$W, $k"; done; grep -q '^spec-repo:' "$T/set" || W="$W, spec-repo"
  if [ -z "$W" ]; then W='Nothing is missing: a later /vid:vid-plan asks nothing.'; else W="Still to ask at the next /vid:vid-plan: ${W#, }; until then each reads as its default."; fi
  case $X in fine) X='finer steps, technical ones allowed (split: fine)' ;; journey) X='steps by journey (split: journey)' ;; *) X='steps by journey (the default)' ;; esac
  printf '\n## The setup\n\nAsked once, at the start of /vid plan, and kept in .vid/tw/settings. %s\n\n' "$W"
  # GM-4 K13, J5: with one repository the team reads the spec in a folder of the code repository, which ViD's own publish
  # (vid-spec-publish) fills by a pull request; ViD's private spec repository keeps its export, as with two
  if [ "$L" = one ]; then printf -- '- **Where the code lives and the specs go:** one repository: the team reads the specs in its folder %s, which ViD'"'"'s own\n  publish, vid-spec-publish, fills from each export by a pull request for the team to merge; %s.\n- **The code repository:** %s\n- **The spec repository (ViD'"'"'s own export):** %s\n' "$(sk spec-path | grep . || echo 'docs/specs (the default)')" "$(if [ -n "$(sk spec-stamp)" ]; then echo "its stamp file, $(sk spec-stamp), names the export there"; else echo 'no stamp file is set'; fi)" "${R:-not set yet}" "${S:-not set yet}"
  else printf -- '- **Where the code lives and the specs go:** separate repositories, the code and ViD'"'"'s private spec repository%s.\n- **The code repository:** %s\n- **The spec repository:** %s\n' "$([ -n "$L" ] || echo ' (the default)')" "${R:-not set yet}" "${S:-not set yet}"; fi
  case $(sk github-mode) in auto) G='ViD'"'"'s own DevAgent, which you start (github-mode: auto)' ;; manual) G='a team of people, by hand, through /vid next (github-mode: manual)' ;; *) G='not asked yet' ;; esac   # v0.26.10.28.8 (R3); GM-1 S1; FB-1 C1: no team
  printf -- '- **Who works the tickets:** %s\n' "$G"
  if manual || [ -n "$(sk state-repo)" ]; then printf -- '- **ViD'"'"'s own state repository:** %s\n- **Slack channels read:** %s\n' "$(sk state-repo | grep . || echo 'not set yet')" "$(sk slack-channels | grep . || echo 'not set yet')"; fi   # GM-1 S1 (§5)   # GM M15
  printf -- '- **The step size:** %s\n- **The open-ticket limit:** %s\n- **Access:** %s\n\n| Team | Area | Strict or core | People | Lanes |\n|---|---|---|---|---|\n' "$X" "${O:-not set}" "${A:-not checked yet}"
  awk -F'\t' 'FNR == NR { L[$2] = L[$2] (L[$2] == "" ? "" : ", ") $1; next } { printf "| %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, L[$1] }' "$T/lanes" "$T/teams"
  grep -q '^team:' "$T/set" || printf '\nNo team is recorded: the default, one team of one person, its lane devagent.\n'; }
# stagepage <n>: stage n's steps and their rows, then its known limits and the rows in no step (flagged)
stagepage() {
  awk -F'\t' '{ b = $5; gsub(/ /, ", ", b); print $1 "\t" $2 "\t" ($3 == "" ? "?" : $3) "\t" ($4 == "" ? "-" : $4) "\t" (b == "" ? "nothing" : b) "\t" ($6 == 1 ? 1 : 0) }' "$T/steps" | while IFS='	' read -r s nm st rws b sk; do
    for r in $rws; do echo "$r"; done >> "$T/placed"
    [ "$st" = "$1" ] || continue
    printf '\n### Step %s — %s%s\n\nBuilds on: %s.\n' "$s" "$nm" "$([ "$sk" = 1 ] && echo ' (the skeleton)' || true)" "$b"
    table "$rws"
  done
  touch "$T/placed"
  L=$(awk -F'\t' -v k="$1" '$2 != "tr" && $5 == k && $6 == "limit" { printf "%s ", $1 }' "$T/rows")
  if [ -n "$L" ]; then printf '\n### Known limits, in no step\n'; table "$L"; fi
  L=$(awk -F'\t' -v k="$1" -v PL="$T/placed" 'BEGIN { while ((getline l < PL) > 0) p[l] = 1 } $2 == "row" && $5 == k && $6 ~ /^(planned|moved|owed)$/ && !($1 in p) { printf "%s ", $1 }' "$T/rows")
  # GM-1 S3: in GitHub manual a row in no step the owner accepted as to place is shown as such, not as flagged
  TP=''; [ ! -s "$T/toplace" ] || TP=$(for r in $L; do awk -F'\t' -v r="$r" '$1 == r && $2 == "no-step" { printf "%s ", r }' "$T/toplace"; done)
  if [ -n "$TP" ]; then L=$(for r in $L; do case " $TP " in (*" $r "*) ;; (*) printf '%s ' "$r" ;; esac; done); printf '\n### Rows to place, in no step\n'; table "$TP"; fi
  if [ -n "$L" ]; then printf '\n### Rows in no step (flagged)\n'; table "$L"; fi
  : > "$T/placed"
}

# snap (GM-1 S3): GitHub manual's reading. A read-only folder in $T, entered: PRD.md, INVENTORY.md, STAGES.md, GRADING-CHECKLIST.md
# and ARCHITECTURE.md as the applied commit (.vid/tw/applied) holds them, PLAN.md as HEAD does (a file a commit lacks, absent),
# and every other entry of the repository's top, .vid/ among them, linked as it stands, so the records the planner writes land
# in the project and the golden sets, BASELINE.md and the scripts it calls read as before; no .git, and git looks no higher,
# so stages.sh reads these files from disk. Refused when .vid/tw/applied names no commit
snap() { C=${AT:-$(applied)}; if [ -z "$C" ] || ! git cat-file -e "$C^{commit}" 2>/dev/null; then
    echo "ViD planner: refused — GitHub manual: .vid/tw/applied names no commit of this repository${C:+ ($C)}; /vid mode manual records the applied version the tickets were written from" >&2; exit 2; fi
  S=$(cd "$T" && pwd -P)/snap; mkdir "$S"
  for e in * .[!.]* ..?*; do [ -e "$e" ] || [ -L "$e" ] || continue
    case $e in .git|PRD.md|INVENTORY.md|STAGES.md|GRADING-CHECKLIST.md|ARCHITECTURE.md|PLAN.md) continue ;; esac; ln -s "$PWD/$e" "$S/$e"; done
  # a system whose ln -s copies (Git Bash without winsymlinks) would leave the planner's records in the copy
  [ ! -d .vid ] || [ -L "$S/.vid" ] || { echo "ViD planner: refused — GitHub manual: this system copied .vid/ where it was to link it, so the planner's records would be lost (on Git Bash: MSYS=winsymlinks:nativestrict)" >&2; exit 2; }
  for f in PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md; do git show "$C:./$f" > "$S/$f" 2>/dev/null || rm -f "$S/$f"; done
  if [ -n "$PMD" ]; then cp "$PMD" "$S/PLAN.md"; else git show "HEAD:./PLAN.md" > "$S/PLAN.md" 2>/dev/null || rm -f "$S/PLAN.md"; fi   # GM-3 U3: --plan-md
  SNAPC=$C
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE; GIT_CEILING_DIRECTORIES=$(dirname "$S"); export GIT_CEILING_DIRECTORIES; ORIG=$PWD; cd "$S"; }
# ab <file>: a file argument as the caller meant it, from the repository's top once snap has moved in
ab() { case $1 in /*) printf '%s\n' "$1" ;; *) printf '%s\n' "${ORIG:-$PWD}/$1" ;; esac; }

CMD=${1:-check}; [ $# -gt 0 ] && shift
# GM-1 S3 (§5), GM M3 (nothing reaches the team before the apply, so the door lands no change): `rows --newest` reads the working tree in every mode; in GitHub manual every other subcommand but setup reads
# the spec at the applied commit (snap), and reratify, the door's landing, is refused there
NEWEST=''; if [ "$CMD" = rows ] && [ "${1:-}" = --newest ]; then NEWEST=1; shift; fi
# GM-3 U2, U3, GM M3 (a candidate read against the applied commit, before the apply): --at <commit> (check, rows, hash, steps) and --plan-md <file> (check, steps), taken out of the arguments wherever they stand
case "$CMD" in check|rows|hash|steps) _n=$#; _i=0; while [ "$_i" -lt "$_n" ]; do _a=$1; shift; _i=$((_i + 1))
    if [ "$_a" = --at ] || { [ "$_a" = --plan-md ] && { [ "$CMD" = check ] || [ "$CMD" = steps ]; }; }; then [ "$_i" -lt "$_n" ] || die "$_a takes a value"; _v=$1; shift; _i=$((_i + 1))
      if [ "$_a" = --at ]; then AT=$(git rev-parse -q --verify "$_v^{commit}" 2>/dev/null) || die "--at $_v names no commit"; else [ -f "$_v" ] || die "--plan-md $_v: no such file"; PMD=$(cd "$(dirname "$_v")" && pwd -P)/$(basename "$_v"); fi
    else set -- "$@" "$_a"; fi; done
  if [ -n "$AT$PMD" ]; then [ -z "$NEWEST" ] || die 'rows --newest reads the working tree: it takes no --at'; manual || die '--at and --plan-md are GitHub manual'"'"'s (GM-3)'; fi ;; esac   # GM M3
if [ "$CMD" != setup ] && [ -z "$NEWEST" ] && manual; then   # GM M3
  [ "$CMD" != reratify ] || { echo "ViD planner: refused — reratify: in GitHub manual the door lands no change, so nothing is re-ratified by a landing" >&2; exit 1; }
  MAN=1; snap; fi
case "$CMD" in
  check)   # 0.26.10.29.2 (R1): --block <file> reads that plan block in place of RUN-STATE's, --ceiling <n> sets rule A's ceiling (empty: as read)
    while [ $# -ge 2 ]; do case $1 in --block) BLK=$(ab "$2"); [ -f "$BLK" ] || die "--block $BLK: no such file" ;; --ceiling) CEILOV=$2; case $CEILOV in *[!0-9]*) die "--ceiling $CEILOV is no number" ;; esac ;; *) die "check: unknown $1" ;; esac; shift 2; done
    [ $# -eq 0 ] || die "check: unknown $1"
    model
    if [ -s "$T/flags" ]; then cat "$T/flags"; exit 1; fi
    echo "planner: clean — $(awk -F'\t' '$2 != "tr"' "$T/rows" | grep -c . || true) rows, $(grep -c . "$T/steps" || true) steps$([ ! -s "$T/toplace" ] || echo "; $(grep -c . "$T/toplace") to place")" ;;
  rows)
    if [ "${1:-}" = --added ]; then [ -f INVENTORY.md ] || die 'no INVENTORY.md here'; block vid-inventory INVENTORY.md | grep -E '[|][[:space:]]*origin: plan( |$)' || true; exit 0; fi
    model rows; printf '# id\tkind\tparent\titems\tstage\tclass\tmarks\tpromise\tfail-if\tclass text\tcarried\tgolden\n'
    if [ "${1:-}" = --short ]; then LC_ALL=C awk -F'\t' -v OFS='\t' '{ p = $8; o = ""; c = 0
        for (i = 1; i <= length(p); i++) { b = substr(p, i, 1); if (b < "\200" || b > "\277") { if (++c > 80) break } o = o b }
        if (c > 80) o = o "…"; $8 = o; print }' "$T/rows"
    else cat "$T/rows"; fi ;;
  # GM-4 F10: the planner's own readings, for a reader that would otherwise write them again (next.sh): the setup's teams,
  # `<name> TAB <area> TAB <strict|core> TAB <people>`, and the plan's steps, `<step> TAB <name> TAB <its stage> TAB <rows> …`
  teams) model; cat "$T/teams" ;;
  steps)   # GM-4 F10: --block <file> reads that plan block in place of RUN-STATE's, as check does (the re-plan's candidate)
    while [ $# -ge 2 ]; do case $1 in --block) BLK=$(ab "$2"); [ -f "$BLK" ] || die "--block $BLK: no such file" ;; *) die "steps: unknown $1" ;; esac; shift 2; done
    [ $# -eq 0 ] || die "steps: unknown $1"; model; cat "$T/steps" ;;
  hash) hash ;;
  prereq) gaps ;;
  prd-form) [ ! -f PRD.md ] || grep -q '^```vid-prd' PRD.md || { echo "ViD plan: refused — PRD.md is in the legacy block form, with no \`\`\`vid-prd block: ticket mode reads only the enriched PRD. Bring it in through /vid create-prd's import door." >&2; exit 1; } ;;
  counts) model; counts ;;
  page)
    model; gaps >> "$T/notes"; H=$(hash); P=.vid/plan/PLAN-PAGE.md; mkdir -p .vid/plan
    openat "$H"; if [ -n "$CL" ]; then CR=${CL%% *}   # low-1 (R5): the rounds closed: no "no review" flag, a note
      echo "the rounds of review are closed after review number $CR (${CL#* * }): PL fixes nothing more on its own; each open finding is the owner's, to keep or to have fixed$([ "$NH" = "$H" ] || echo "; the spec has changed since the newest review, and those changes are not reviewed")" >> "$T/notes"; fi
    NAME=$(sed -n 's/^# \(.*\) — PRD[[:space:]]*$/\1/p' PRD.md | head -n 1); [ -n "$NAME" ] || NAME='The product'
    { sed 's/^/- /' "$T/flags"; sed 's/^\([0-9]*\) | \([^|]*[^| ]\) *| */- finding \1 on \2, not answered: /' "$T/open"
      if [ "$RVD" = no ]; then echo '- no review of this plan'; fi; } > "$T/fl"
    ids() { awk -F'\t' "$1"' { printf "%s ", $1 }' "$T/rows"; }
    {
      printf '# %s — the plan\n\nThe plan for the owner to ratify. Its hash: `%s`.%s\n\n## Flags\n\n' "$NAME" "$H" "$([ -z "$MAN" ] || printf ' GitHub manual: the spec as the applied commit `%.12s` holds it, PLAN.md as HEAD does.' "$(applied)")"   # GM M3
      if [ -s "$T/fl" ]; then cat "$T/fl"; else echo '- none'; fi
      if [ -n "$MAN" ]; then   # GM-1 S3, GM M2: the rows the owner accepted as to place, no flag
        printf '\n## The rows to place\n\nRows the owner accepted as to place (.vid/tw/to-place): each is shown here, and is no flag.\n\n'
        if [ -s "$T/toplace" ]; then awk -F'\t' '{ printf "- %s, %s: to place, in the owner'"'"'s words: %s\n", $1, $3, $4 }' "$T/toplace"; else echo '- none'; fi; fi
      if [ -n "$MAN" ] && [ -s .vid/tw/dropped ]; then   # GM-3 S2, GM M2: the rows the switch took out of steps not published
        printf '\n## The rows taken out of steps not published\n\nAt the switch, each named by a step not yet published and missing from the applied inventory, so taken out of the plan (.vid/tw/dropped).\n\n'
        awk '$1 == "dropped" && !s[$2 " " $3]++ { printf "- %s, out of step %s\n", $2, $3 }
          $1 == "dropped-step" && !s["step " $2]++ { printf "- step %s, taken out of the plan: every row it held was taken out\n", $2 }' .vid/tw/dropped; fi
      printf '\n## Notes\n\nComputed beside the flags; a note never refuses the check or the ratification. For each, the plan is changed or\nthe prose says why it stands.\n\n'
      if [ -s "$T/notes" ]; then sed 's/^/- /' "$T/notes"; else echo '- none'; fi; setuppage
      planpage
      printf '\n## The rows ViD added\n\nAppended to INVENTORY.md with `origin: plan`, each in the schema'"'"'s form for its kind; every other row\nis the ratified inventory'"'"'s, word for word.\n'
      table "$(ids '$11 ~ /(^| · )origin: plan( |$)/')"
      printf '\nThe standing rows:\n\n'
      for k in rehearsal sign-in fields work; do
        v=$(block vid-rows PLAN.md | sed -n "s/^[[:space:]]*standing[[:space:]][[:space:]]*$k[[:space:]]*|[[:space:]]*//p" | head -n 1)
        printf -- '- **%s:** %s\n' "$k" "${v:-(no line: flagged)}"
      done
      printf '\n## The rows waiting on an open question\n\nEach waits for the owner'"'"'s answer before it goes into a ticket.\n'
      table "$(ids 'index($11, "test: owed: owner-decision")')"
      while IFS='	' read -r k nm; do
        printf '\n## Stage %s — %s\n\n' "$k" "$nm"
        if [ -f STAGES.md ]; then awk -v h="## Stage $k — " 'index($0, h) == 1 { on = 1; next } on && /^## / { exit } on' STAGES.md
        else printf "**The PRD's MVP focus** (one stage, so no STAGES.md):\n\n"; awk '/^### MVP focus/ { on = 1; next } on && /^#/ { exit } on' PRD.md; fi
        stagepage "$k"
      done < "$T/stages"
      printf '\n## The golden sets\n\nEach set once, with the rows citing it; each row names its set in its Carried cell.\n'; goldens
      printf '\n## The grading checklist\n\nEvery grade reads every line of it, and the records below.\n\n'
      if [ -f GRADING-CHECKLIST.md ]; then sed '1{/^# /d;}' GRADING-CHECKLIST.md | sed 's/^## /### /'; else echo 'No GRADING-CHECKLIST.md.'; fi
      printf '\n### The records: what is deliberately not tested\n'
      table "$(ids '$6 == "record"')"
      printf '\n## The later-phase rows\n\nIn no step until an amendment brings their items into the pilot.\n'
      table "$(ids '$6 == "later"')"
      printf '\n## Counts\n\nEach row counts in its stage after its move. Inventory rows: the rows of the test inventory that are neither seams\nnor ViD'"'"'s own, so Inventory rows + Seams + ViD'"'"'s rows = Rows.\n\n| Stage | Inventory rows | Seams | ViD'"'"'s rows | Rows | Planned | Moved | Deploy-owed | Known limits | Records | Transitions | Steps | Requirements |\n|---|---|---|---|---|---|---|---|---|---|---|---|---|\n'
      counts | awk '$1 == "later" { v = $2; sub(/^rows=/, "", v); w = $3; sub(/^transitions=/, "", w); print "| Later phase | — | — | — | " v " | — | — | — | — | — | " w " | — | — |"; next }
        { h = ($1 == "total" ? "All" : $2); o = "| " h; for (i = 1; i <= NF; i++) if ($i ~ /=/) { v = $i; sub(/^[a-z]*=/, "", v); o = o " | " v } print o " |" }'
    } > "$T/pg" || exit 1; put "$P" < "$T/pg" || exit 1
    sh "$HERE/page.sh" "$P" && printf 'paged spec=%s plan=%s at=%s\n' "$H" "$(phash)" "$(now)" >> .vid/plan/paged ;;
  review)
    [ "${1:-}" = --in ] && [ -n "${2:-}" ] && RIN=$(ab "$2") && [ -f "$RIN" ] || die 'usage — sh checks/planner.sh review --in <file>'
    CL=$(rounds); if [ -n "$CL" ]; then echo "planner: the rounds of review are closed after review number ${CL%% *} (${CL#* * }); nothing recorded: each open finding is the owner's, to keep (answer <n> keep) or to have fixed (answer <n> fixed)"; exit 0; fi   # low-1 (R5)
    model; H=$(hash); awk -F'\t' '$11 ~ /(^| · )origin: plan( |$)/ { print $1 }' "$T/rows" > "$T/ids"
    awk -v IDS="$T/ids" 'BEGIN { while ((getline l < IDS) > 0) ok[l] = 1 }
      { l = $0; gsub(/^[ \t]+|[ \t]+$/, "", l) }
      l == "" { next }
      l == "none" { said = 1; next }
      l ~ /^finding [^ |]+[ \t]*\|/ { id = l; sub(/^finding /, "", id); sub(/[ \t]*\|.*/, "", id); why = l; sub(/^[^|]*\|[ \t]*/, "", why)
        if (!(id in ok)) { print "ViD planner: line " NR ": " id " is no row ViD added to INVENTORY.md" > "/dev/stderr"; bad = 1 }
        else if (why == "") { print "ViD planner: line " NR ": a finding with no why" > "/dev/stderr"; bad = 1 }
        else print id "\t" why; said = 1; next }
      { print "ViD planner: line " NR " is neither `finding <row id> | <why>` nor none" > "/dev/stderr"; bad = 1 }
      END { if (!said) { print "ViD planner: the output is empty; a pass that finds nothing says none" > "/dev/stderr"; bad = 1 } exit bad }' "$RIN" > "$T/found" || die 'review refused — the output is out of form (above); nothing recorded'
    mkdir -p .vid/plan; touch "$RV"
    r=$(( $(grep -c '^review ' "$RV" || true) + 1 )); n=$(grep -c '^finding ' "$RV" || true); k=$(grep -c . "$T/found" || true)
    printf 'review %s hash=%s findings=%s at=%s\n' "$r" "$H" "$k" "$(now)" >> "$RV"
    awk -F'\t' -v n="$n" -v r="$r" -v h="$H" '{ printf "finding %d review=%s hash=%s | %s | %s\n", n + NR, r, h, $1, $2 }' "$T/found" >> "$RV"
    echo "planner: review $r recorded — $k findings, hash $H" ;;
  answer)
    n=${1:-}; A=${2:-}; case $A in keep|fixed) ;; *) die "usage — sh checks/planner.sh answer <n> keep|fixed --words \"<the owner's words>\"" ;; esac
    shift 2; words "$@"; H=$(hash); openat "$H"
    awk -v n="$n" '$1 == n { f = 1 } END { exit !f }' "$T/open" || die "finding $n is no unanswered finding of this plan's review"
    printf 'answer %s %s hash=%s at=%s words=%s\n' "$n" "$A" "$H" "$(now)" "$OW" >> "$RV"
    if [ "$A" = keep ]; then echo "planner: finding $n kept as written, in the owner's words"; else echo "planner: finding $n answered fixed, in the owner's words"; fi ;;
  ratify)
    words "$@"; model; H=$(hash); openat "$H"   # low-1 (R5): once the rounds close, no review at this hash is needed
    # GM-3 U4 (GM M4): in GitHub manual a size flag is a warning in ratify too, as ratified reads it: the page shows it, and a
    # top-up over rule A's ceiling never refuses the ratification
    if [ -n "$MAN" ]; then grep -v '^size ' "$T/flags" > "$T/flags.g" || :; cat "$T/flags.g" > "$T/flags"; fi
    { sed 's/^/a check flag is open: /' "$T/flags"; if [ "$RVD" = no ]; then echo "no review has this plan's hash ($H)"; fi
      sed 's/^\([0-9]*\) | \([^|]*[^| ]\) *|.*/finding \1 on \2 has no answer/' "$T/open"; planok
      PG=$(tail -n 1 .vid/plan/paged 2>/dev/null | sed -n 's/.* plan=\([0-9a-f]*\) .*/\1/p'); [ "$PG" = "$(phash)" ] || echo "the newest page did not show this plan ($(phash)): sh checks/planner.sh page, for the owner to see"; } > "$T/why"
    if [ -s "$T/why" ]; then sed 's/^/ViD planner: ratify refused — /' "$T/why" >&2; exit 1; fi
    mkdir -p .vid/plan; printf 'ratified hash=%s plan=%s at=%s words=%s\n' "$H" "$(phash)" "$(now)" "$OW" >> .vid/plan/ratified
    printf 'ratified after-review=%s\n' "$(cat "$RV" 2>/dev/null | grep -c '^review ' || :)" >> "$RV"   # low-1 (R5): the sitting's boundary
    echo "planner: ratified, hash $H, in the owner's words" ;;
  setup)   # v0.26.10.26.7 (R11, W-13): one setup answer, as the owner gave it: its key in .vid/tw/settings and setup-answered
    K=${1:-}; V=${2:-}; [ $# -ge 2 ] && shift 2; OW=''; [ "${1:-}" = --words ] && OW=${2:-}
    [ -n "$K" ] && [ -n "$V" ] && [ -n "$OW" ] || die 'usage — sh checks/planner.sh setup <layout|team|split|repo|spec-repo|spec-path|spec-stamp|state-repo|slack-channels|github-mode|issue-form|issue-parent|plan-page> <the answer, or "not yet" for a repository> --words "<the owner'"'"'s words>"'
    case $K in layout|team|split|repo|spec-repo|spec-path|spec-stamp|state-repo|slack-channels|github-mode|issue-form|issue-parent|plan-page) ;; *) die "setup $K: no setup question has that key" ;; esac
    # FB-1 C1: the old team mode is retired
    [ "$K:$V" != github-mode:team ] || die "setup github-mode team: GitHub team is retired: a team of people works the tickets in GitHub manual (/vid mode manual); ViD's own DevAgent, in GitHub auto"
    case "$K:$V" in layout:separate|layout:one|split:journey|split:fine|team:*|repo:*|spec-repo:*|spec-path:*|spec-stamp:*|github-mode:auto|github-mode:manual|state-repo:*|slack-channels:*|issue-form:*|issue-parent:*|plan-page:*) ;; *) die "setup $K: $V is no answer to it" ;; esac
    # GM-1 S1, GM M2: GitHub manual is entered and left only by /vid mode, which marks its own calls (VID_CALLER=mode)
    # GM-4 F13: and /vid mode's switch to auto (VID_CALLER=mode-auto) records github-mode auto last, as the switch to manual does
    if [ "$K" = github-mode ] && case ${VID_CALLER:-} in mode|mode-auto) false ;; *) true ;; esac && { [ "$V" = manual ] || [ "$(ghmode)" = manual ]; }; then
      echo "ViD planner: refused — github-mode $V: GitHub manual is entered and left only through /vid mode, which takes stock first" >&2; exit 1; fi
    # GM-1 S1 (§5): state-repo, ViD's own private repository for the lock and the saved records, owner/name, never the code
    # repository or the spec repository; slack-channels, the channel names comma-separated, or none
    case "$K:$V" in
      state-repo:*) printf %s "$V" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' || die "setup state-repo: $V is not owner/name"
        lo() { printf %s "$1" | tr 'A-Z' 'a-z'; }   # GitHub's names ignore case
        for k in repo spec-repo; do [ "$(lo "$(skey "$k")")" != "$(lo "$V")" ] || die "setup state-repo: $V is the $k:; ViD's own state repository is neither the code repository nor the spec repository"; done ;;
      repo:*|spec-repo:*) [ "$V" = 'not yet' ] || [ "$(skey state-repo | tr 'A-Z' 'a-z')" != "$(printf %s "$V" | tr 'A-Z' 'a-z')" ] || die "setup $K: $V is the state-repo:, ViD's own state repository" ;;
      # GM-4 K13 (J4): with one repository, the folder of the code repository the spec is published into, a plain path from its
      # top; and the stamp, a file inside that folder named from it (STAMP is <spec-path>/STAMP), or none
      spec-path:*|spec-stamp:*) [ "$K:$V" = spec-stamp:none ] || { printf %s "$V" | grep -Eq '^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*$' || die "setup $K: $V is not a plain path (letters, digits, . _ - and /, no leading or trailing /)"
        case /$V/ in */../*|*/./*) die "setup $K: $V is not a plain path (no . or .. in it)" ;; esac; } ;;
      slack-channels:*) [ "$V" = none ] || printf %s "$V" | grep -Eq '^#?[A-Za-z0-9][A-Za-z0-9._-]*(,#?[A-Za-z0-9][A-Za-z0-9._-]*)*$' || die "setup slack-channels: $V is not channel names, comma-separated, or none" ;;
      # GM-2 (§5): the issue form, a file of ViD's repository the export carries beside the spec; the parent issue; the plan page
      issue-form:*) printf %s "$V" | grep -Eq '^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*$' || die "setup issue-form: $V is not a path in ViD's repository (letters, digits, . _ - and /, from its top)"
        case /$V/ in */../*|*/./*) die "setup issue-form: $V is not a plain path (no . or .. in it)" ;; esac
        case $V in PRD.md|DECISIONS.md|BASELINE.md|ARCHITECTURE.md|GRADING-CHECKLIST.md|TEST-DIFFERENCES.md|INVENTORY.md|STAGES.md|PLAN.md|design|design/*) die "setup issue-form: $V is one of the spec's own files; the form is a file of its own" ;; esac ;;
      issue-parent:*) [ "$V" = none ] || printf %s "$V" | grep -Eq '^[1-9][0-9]*$' || die "setup issue-parent: $V is not an issue number, or none" ;;
      plan-page:*) case $V in artifact|none) ;; https://*) printf %s "$V" | grep -Eq '^https://[^[:space:]]+$' || die "setup plan-page: $V is not a link" ;; *) die "setup plan-page: $V is not artifact, a link, or none" ;; esac ;;
    esac
    mkdir -p .vid/tw; touch .vid/tw/settings
    grep -q '^labels-prefix:' .vid/tw/settings || echo 'labels-prefix:' >> .vid/tw/settings   # no question asks it; the writer needs the line (the walk)
    case "$K:$V" in
      repo:'not yet'|spec-repo:'not yet'|spec-stamp:none) grep -v "^$K:" .vid/tw/settings > "$T/st" || true; put .vid/tw/settings < "$T/st" || exit 1 ;;   # a written default goes; no stamp, no key
      team:*) V=$(printf '%s\n' "$V" | awk -F'|' -v OFS='|' '{ $1 = tolower($1) } 1')   # GM-3 S2, GM-4 F11: the name lower-cased, in both modes
        grep -q '^setup-answered key=team ' .vid/plan/setup 2>/dev/null || { grep -v '^team:' .vid/tw/settings > "$T/st" || true; put .vid/tw/settings < "$T/st" || exit 1; }   # the first answer replaces a written default
        grep -qxF "team: $V" .vid/tw/settings || echo "team: $V" >> .vid/tw/settings ;;
      *) grep -v "^$K:" .vid/tw/settings > "$T/st" || true; echo "$K: $V" >> "$T/st" || exit 1; put .vid/tw/settings < "$T/st" || exit 1 ;;
    esac
    mkdir -p .vid/plan; printf 'setup-answered key=%s value="%s" words="%s" at=%s\n' "$K" "$(printf %s "$V" | tr '"' "'")" "$(printf %s "$OW" | tr '"' "'")" "$(now)" >> .vid/plan/setup   # the planner's own record: it writes no event (P8)
    echo "planner: setup $K answered, in the owner's words" ;;
  reratify)   # v0.26.10.25.5 (R3): the owner's yes to a counted change landed during a run, with no new sitting
    OW=''; B=''; TO=''; HELD=''; while [ $# -ge 2 ]; do case $1 in --words) OW=$2 ;; --base) B=$2 ;; --to) TO=$2 ;; --held) HELD=$2 ;; *) die "unknown $1" ;; esac; shift 2; done
    [ -n "$OW" ] && [ -n "$B" ] && [ -n "$TO" ] || die 'usage — sh checks/planner.sh reratify --words "<the owner'"'"'s yes>" --base <the draft'"'"'s base> --to <the landing'"'"'s last commit> --held <file,…>'
    git cat-file -e "$B^{commit}" 2>/dev/null && git cat-file -e "$TO^{commit}" 2>/dev/null || die "--base $B or --to $TO names no commit"
    hashat() { for f in PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md PLAN.md; do printf '== %s\n' "$f"; git show "$1:$f" 2>/dev/null || true; done | git hash-object --stdin | cut -c1-12; }
    model; HB=$(hashat "$B"); H=$(hash)
    { sed 's/^/a check flag is open: /' "$T/flags"
      L=$(tail -n 1 .vid/plan/ratified 2>/dev/null || true); case "$L" in "ratified hash=$HB "*) ;; *) echo "the spec files at the base $(printf %.12s "$B") (hash $HB) are not the newest ratified ones: a change no one ratified lies before the draft" ;; esac
      git merge-base --is-ancestor "$B" "$TO" 2>/dev/null || echo "the base $(printf %.12s "$B") is not an ancestor of $(printf %.12s "$TO")"
      [ "$(git rev-parse HEAD)" = "$(git rev-parse "$TO")" ] || echo "$(printf %.12s "$TO") is not HEAD"
      [ "$(hashat "$TO")" = "$H" ] || echo 'the spec files in the working tree are not those of the landing'
      for f in $(git diff --name-only "$B" "$TO" -- PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md PLAN.md); do case ",$HELD," in *",$f,"*) ;; *) echo "$f changed between the base and the landing, and the draft did not hold it" ;; esac; done
      planok; } > "$T/why"
    if [ -s "$T/why" ]; then sed 's/^/ViD planner: reratify refused — /' "$T/why" >&2; exit 1; fi
    mkdir -p .vid/plan; printf 'ratified hash=%s plan=%s at=%s base=%s to=%s words=%s\n' "$H" "$(phash)" "$(now)" "$(printf %.12s "$B")" "$(printf %.12s "$TO")" "$OW" >> .vid/plan/ratified
    printf 'ratified after-review=%s\n' "$(cat "$RV" 2>/dev/null | grep -c '^review ' || :)" >> "$RV"   # low-1 (R5): the sitting's boundary
    echo "planner: reratified, hash $H, from $(printf %.12s "$B") to $(printf %.12s "$TO"), in the owner's words" ;;
  ratified)
    H=$(hash); L=$(tail -n 1 .vid/plan/ratified 2>/dev/null || true)
    case "$L" in "ratified hash=$H "*) ;; *) echo "planner: not ratified — the newest ratification is not of these spec files (hash $H)" >&2; exit 1 ;; esac
    W=$(planok); [ -z "$W" ] || { echo "planner: not ratified — $W" >&2; exit 1; }
    # GM-2 T6, T7, GM M4 (no ticket held back for rule A's ceiling): in GitHub manual a size flag (rule A's ceiling) is a warning the move shows, never a
    # flag that shuts the gate behind it
    model; if [ -n "$MAN" ]; then grep -v '^size ' "$T/flags" > "$T/flags.g" || :; cat "$T/flags.g" > "$T/flags"; fi
    [ ! -s "$T/flags" ] || { echo "planner: not ratified — planner.sh check flags the plan ($(head -n 1 "$T/flags"))" >&2; exit 1; }
    echo "planner: ratified, hash $H, plan $(phash)" ;;
  *) die "unknown subcommand $CMD — check, prereq, rows, review, page, counts, answer, ratify, reratify, ratified, hash, setup" ;;
esac
