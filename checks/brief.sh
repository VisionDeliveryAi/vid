#!/bin/sh
# Purpose: ViD court — the brief checker (v0.9.3 spec 3.1, R1, R2). A spawned
# agent reads its brief, a file that QUOTES and never summarises; the
# orchestrating session runs this before every spawn. The file:
#   role: builder|fixer|grader|test-author    slice: <N>
#   quoted-at: <commit sha>
#   receives: <this role's items>    must not receive: <this role's exclusions>
#   [pending-birth: ROW-… …]  [pending-append: REQ-… …]   (test-author only)
#   <the independence paragraph, verbatim, for grader and test-author>
#   ## 1 rows · ## 2 items · ## 3 decisions · ## 4 laws · ## 5 start and
#   receipt · ## 6 test requests · ## 7 attempt record (builder, fixer) ·
#   ## 8 further reading (optional)
# Exits 1 naming the line on: a header field missing or an unknown role; a
# fresh-context role without the independence paragraph; a `ROW-` line not
# byte-identical to the INVENTORY block at `quoted-at`; a PRD item not
# byte-identical to the effective row at `quoted-at` (checks/prd.sh
# --effective; a legacy `### REQ-NNN` block must appear verbatim in the
# effective block); a DECISIONS line not present verbatim at `quoted-at`; a
# law line (section 4) not present verbatim in CLAUDE.md at `quoted-at`; a
# grader brief carrying section 7, a `.vid/verdicts/` path or a `result=`
# token (outside the header's own `must not receive:` field, which names them), an `owed: reverted —` line in any form but the withheld one, or
# lacking the stated read exclusion; a builder or fixer brief missing the
# attempt record of a row that has one (.vid/verdicts/<ROW>.md, every line).
# The test-author exceptions: a row absent at `quoted-at` must match the
# working tree's INVENTORY.md if present there, else be listed
# `pending-birth:`; a PRD item absent or different at `quoted-at` must match
# the working tree's effective set and be listed `pending-append:` (a fix's
# correction lands its append with the fix, after the independent test).
# v0.9.7.0.5 (3.4, R5): in a grader brief (every verb's) a section-3 line
# carrying ` | why:` is refused, and any other must be the rule part of a
# decision line at `quoted-at` — the text before ` | why:`, whole (a line
# without one is all rule): a decision's why can recount an earlier verdict.
# Other roles keep the whole-line check. A test-author's legacy `### REQ-`
# block takes the enriched row's exception: it may match the working
# tree's effective block when its id is listed `pending-append:`.
# `--at <sha>` compares against <sha> instead of `quoted-at` — `--at HEAD` is
# the observer's staleness check. Every run appends `brief-check path=<p>
# result=ok|fail` to .vid/metrics-events; a verdict event names its brief
# (`brief=<path>`) and metrics.sh counts the verdicts whose brief was never
# checked ok. What this proves is stated in CLAUDE.md (3.16): a brief was
# well-formed when checked and a verdict named it — not that the spawn
# carried nothing else.
# v0.9.6 (3.2, 3.6; R2, R6): a builder or fixer brief names its plan step in
# the header (`step: <id>`, beside role and slice). Once the brief's own
# checks pass — and never under --at, the observer's read — it is an
# admission: `sh checks/plan.sh admit --brief <file>` judges the step
# (outside a 0.9.6 develop run it only notes that the rules are off); its
# refusal is this check's refusal, recorded `result=fail`. Test-author and
# grader briefs start no step and are outside the rules.
# v0.9.7.0.2 (3.6, R11): section 6 lists test requests. In any role's
# brief, a line of section 6 naming checks/test.sh other than
# `checks/test.sh request` or `checks/test.sh wait` is refused, naming the
# line (this replaces 0.9.7.0.1's test-author-only role check: a request
# carries its role in --role).
# v0.9.7.0.3 (3.2): `role: test-analyst` — the test analyst's brief
# (skills/vid-test-manager/passes/test-analyst.md). It needs no section 6,
# and a line naming `checks/test.sh request` anywhere in it is refused,
# naming the line: the analyst runs nothing.
# v0.9.7.0.11 (3.7, R7): when the first ticket id the brief names has kept
# timelines (`timeline.<pass>.log` in its folder, at the run's home or
# here), the brief names each one; one it leaves out is refused.
# v0.9.7.0.5 (3.3, 3.4; R3–R6): `write` assembles a grader, fixer or
# test-author brief from the records at HEAD into a new file,
# .vid/briefs/<slice>/<role>-<n>.md, then runs this check on it and prints
# the path and the verdict (a refusal exits 1 and keeps the file). Rows
# come from --rows or a saved claim (`metrics.sh claim … | tee`), whose ids
# alone travel: never a claim line's reason, never a held row. Decisions:
# every line citing a briefed row or an id of its derived-from, whole ids,
# any field (why: included), plus the --decisions ids; a grader gets each
# one's rule, the line up to ' | why:'. A test-author's row born after HEAD
# comes from the working tree, listed pending-birth:, and its new or
# amended item likewise, listed pending-append:. The plugin's texts — the
# role table, the grader's and the test-author's passes — are read under
# $CLAUDE_PLUGIN_ROOT (else this file's ../). Refused before writing: an
# unknown row or decision id, a grader brief without --receipt, a fixer
# brief in a develop run without --step, a CLAUDE.md missing a law section.
# No option adds text. The last header line is the stamp, `written:
# brief.sh write <hash>`, the git hash-object of the file without that
# line; the check refuses a stamped brief whose hash differs ("changed
# after writing"), also under --at. Honest limit: removing or recomputing
# the stamp gets past it; nothing proves a brief was written by the command.
# v0.9.7.0.7 (3.2, R3–R6, R13): `write --role builder` (it requires --step)
# writes the builder's brief: no section 4 (CLAUDE.md is loaded into every
# agent); section 3 by the safe rule — a decision line is kept when it cites
# no ROW-/REQ- id (whole ids), or one of the briefed rows or their
# derived-from ids, and a line kept only for citing no id is dropped when it
# names a screen code (the part before `/` of an INVENTORY row's marker,
# n/a excluded; a whole token) and none of its screen codes is one the
# briefed rows mark; a --decisions id always stays. Then ## 9 test
# locations (per row, every line of its `test` file — the field's first
# token — holding the row's id as ROW-n or ROW_n, a whole id, at quoted-at:
# `ROW-… <path>:<line>[,<line>…]`, `ROW-… owed` for an owed field, `ROW-…
# none`, the writer printing `write: <n> rows without a test location`);
# ## 10 the step (`plan: <hash>`, the plan in force from the latest
# plan-change event, quoted from .vid/plans/<hash>.plan: the step's line and
# its builds-on steps' lines, then the ARCHITECTURE.md module-table rows
# whose Module column is one of the step's modules — `/` and `.` equal, a
# trailing `/` ignored); ## 11 rules (INVENTORY `rule` rows whose origin:
# cites one of section 2's ids, whole); ## 12 notes (--notes, verbatim, the
# run manager's words; a fixer may take it too). A builder's and a fixer's
# header carry `skill: vid-build`. The check, for a builder brief, recomputes
# section 9 at quoted-at and compares it, and refuses a section 10 line found
# in neither the named plan file nor ARCHITECTURE.md at quoted-at, and a
# section 11 line not a `rule` row of INVENTORY.md at quoted-at; section 12
# is not checked. A hand-written builder brief without them passes as before.
# v0.9.7.0.7 (3.3, R7, R12): `return <file>` checks a builder's or fixer's
# hand-back, saved by the run manager as .vid/briefs/<N>/<role>-<n>.return.md:
# the headers `brief:`, `agent:`, `branch:`, `commit:`; the brief exists;
# every row of its section 1 appears once and no other row, as `ROW-… | pass
# | <receipt>` or `ROW-… | not | <receipt or none> | <reason>`; a pass's
# receipt is a valid receipt of the run (a `ledger-run` event names it, the
# file and its .tree are present, no `invalidated` event names it — as
# checks/evidence.sh reads one) that shows the row passing: the row's cases
# in it by evidence.sh's join (`reach`), at least one and every one passed.
# v0.9.7.0.11 (3.1, R1): `reach` is credit-bearing, so a receipt that
# carries its request's frozen rows (`.rows`) shows only those rows passing.
# A refusal names the line and exits 1; it never routes. On ok it records,
# once per brief (a re-check records nothing), `build-cost role= slice=
# step=<id|-> brief= rows= rows-passed= peak= total= before-change=<t|unknown>[
# shell]`: from the agent's own transcript (<the agent-start's transcript=
# without .jsonl>/subagents/agent-<id>.jsonl), per API call (assistant
# entries, one per message id) the context is input_tokens +
# cache_read_input_tokens + cache_creation_input_tokens, `peak` the largest
# and `total` the sum; `before-change` the context of the call that made the
# first product mutation — a Write, Edit or NotebookEdit whose result is no
# error, its path (against the agent's cwd) under one of the step's modules,
# or, when earlier, a shell call naming such a path with a write (`>`, tee,
# sed -i, cp, mv, patch, git apply, or a script fed on stdin or by -c/-e;
# a redirection to /dev/null or to another descriptor is no write),
# which marks the value ` shell`: possible, not proven. v0.9.7.0.9 (3.7,
# R10): a shell call counts only when a path it WRITES is under a module —
# the target of `>`/`>>` (not /dev/null, not a descriptor), each file
# operand of tee, the file operands of sed -i, cp's last operand, every
# operand of mv and of rm; patch and git apply count as before when they
# name a module path, and a script fed on stdin (a here-document) or by
# -c/-e when the script itself names one. The command is split into
# words; nothing parses a programming language. No transcript: every
# token field `unknown`. A transcript line is read as Claude Code writes it,
# one tool call or result per line; nothing parses a programming language.
# v0.9.7.0.9 (3.4, R4): `return`, on ok, prints after its ok line the lines
# of `sh checks/test.sh analyst-due` — each analyst-due with no
# analyst-done — so the run manager, who alone starts the analyst, sees
# them at every builder's and fixer's hand-back.
# v0.9.7.0.10 (3.6, R13): `write … --upgrade`, for a builder or a
# test-author, adds ## 13 harness upgrade — `harness: docker-compose.test.yml
# hash: <cksum at HEAD> rules: none`, the template's path, the newest
# ticket's timeline.log (or none; v0.9.7.0.11: the newest timeline.<pass>.log), the last 20 gated passes' overhead=
# (v0.9.7.0.11 3.4, R4: and the last 20 passes' services.<pass>.txt, newest first, each service's started-at and ready-at; v0.9.8 R17: kept-healthy-at, an older ticket's ready-at read under that name)
# from the run's ledger-run events (report, seconds, overhead), the three
# rules in the template's words, and the harness file at HEAD, whole. It
# is refused when the harness at HEAD is missing or declares `rules:`
# (v0.9.7.0.11 3.2, R2: `rules:` above 1 — a harness at `rules: 1` is
# upgraded to rule 4; the section says `rules: <none|1> target: 2`, quotes
# the template's four rules, and lists the slowest 10 cases of the run's
# .cases, which rule 4's limit is set from). The
# check refuses a section 13 whose hash is not the harness's at quoted-at.
# v0.9.7.0.12 (3.5, R5): a grader's --receipt may name a close batch's
# ticket (checks/test.sh request --batch): the brief lists its constituent
# receipts (its `receipts` — published, retried or adopted), each row's
# per-case status from the constituents that credit the row (evidence.sh
# credit), and the read exclusion 'beyond the receipts named above'; the
# check accepts either exclusion.
# v0.9.7.1 (3.2, R2) — a builder's and a fixer's brief: the header adds `try: <slice>-<role>-<n>` (the
# attempt id; `attempt=` already names the refusal id), `branch: vid/<try>` and `return: <absolute path>` (the
# return file at the run's home); `write` refuses one without `--selection '<selection>'` (the run manager's, in
# the runner's syntax). Section 5 adds the rows' latest results, labelled history — each briefed row's cases, each
# case's newest result by checks/evidence.sh's per-case rule (`rows --history`: invalidation and frozen-row credit
# as there, no staleness), `<row> <case> <status> <receipt> tree=<12>`, a failure's or error's first message line
# and file:line from `evidence.sh red`. Section 6 is the real command: `sh checks/test.sh request --type iterate
# --role <role> --rows <rows> --try <try> --why "<fill in>" -- <selection>` (and `--deployed-selection <…>` when
# given). A builder's section 10 adds the module-table rows of every module the step may call (a row whose
# Dependents column names one of the step's modules, or `all`), after the step's own. The RULE join: a builder's
# rule rows are computed before the decision filter and their RULE ids join it; RULE- counts as an id in the
# safe rule. Size: a section 5 line over 300 characters is cut and ends `… (receipt)`; a section 10 of more than
# 40 module rows keeps 40 and ends `(+N rows: ARCHITECTURE.md)`; nothing is refused for size, and `write`
# records `brief-written path= role= try= bytes=`. The check refuses a section 5 line over 300 characters that
# does not end with the marker, and takes the section 10 marker as its own line.
# v0.9.7.3 (3.2, R2): section 3 by label, never fewer — today's id join and the --decisions ids always stay; a
# decision's label (`| applies-to: <items>`, checks/hooks/pre-commit 4c) adds a match when an item is a briefed row,
# an id of their derived-from, a RULE id of the RULE join, a screen code the briefed rows mark, or a DIF id their
# `divergence:` fields name; the safe rule covers only unlabelled decisions citing no id, and a `scope: project`
# line, a builder's only, under today's screen narrowing. A labelled no-id decision outside the brief is gone.
# v0.9.7.1 (3.4, R4) — returns and continuations. `protected` (below) is the one protected-path set: the commit
# hook's rule 1 directories (tests/invariants/, checks/, design/), every file checks/lawfiles names, PRD.md,
# DEPLOYMENT.md, DESIGN-BRIEF.md and the harness file; DECISIONS.md is not in it.
#   return <file> --agent <id|codex:<try>>   writes the `agent:` line in (the agent writes the file without it);
#     refuses a `commit:` that does not descend from the brief's quoted-at — except a `wrong base` return (every
#     row `not | none | wrong base: …`) — and a `not` reason pointing at a report ("see … report") when no
#     <role>-<n>.report.md is beside the return. A pass whose receipt's tree= differs from the committed tree in a
#     protected path, or whose tree object is missing, is refused (fails closed), for every builder and fixer but
#     a `## 13` harness upgrade (3.9). On ok it records `agent-returned role= n= try=` and prints (3.7, R7): each
#     row's cases at the return's commit from the receipts the return names, the merge probe (`git merge-tree
#     --write-tree <HEAD> <commit>`: clean, conflicts with the paths, or `merge probe: error`; for a wrong base,
#     `wrong base: every row — <git's error> — …` instead), the branch's
#     worktree's uncommitted files, the continuation package of this try, and the `law-needed:` lines verbatim.
#   save <brief> [--worktree <path>]   writes .vid/continuations/<step>/<try>/ atomically: `manifest` (schema,
#     run, step, try, the brief's hash, quoted-at, the worktree's HEAD, the commits it landed past quoted-at, each
#     payload's path, mode and hash), `tracked.patch` (`git diff --binary HEAD`, may be empty) and `new/` (each
#     untracked regular file). Refused, publishing nothing and leaving the worktree as it was: a protected path,
#     a path leaving the worktree, a symlink, any other file type. Records `continuation-saved try= files= bytes=`.
#   restore <brief>   the brief's `## 14 continuation` package onto a clean worktree: the manifest's hash checked,
#     protected paths refused again, any `new/` path present at HEAD or in the worktree refused, then `git apply
#     --check` and `git apply` (all or nothing; an empty patch skips it) and the new files. Refused with git's
#     message, nothing changed. Records `continuation-restored try= from=<try>`.
#   write … --continue <package> [--law <sha>]   checks the package's landed commits and --law are ancestors of
#     HEAD, and adds `## 14 continuation`: the package, its manifest hash, the report path and the law commit.
# v0.9.7.1 (3.8, R8) — the run manager's context: its session is the `session` event whose id= is RUN-STATE's
# `session:`, its transcript's latest call the context. `context` prints `context: <tokens|unknown>`; `write` and
# `return` print `context <n>` above 350000 and record `context-high n=` once per crossing (none since the
# session's latest `session` event). A notice only: nothing is refused or changed.
# v0.9.7.1 (3.11, R11) — cost for every role. `cost <brief> --agent <id>` records `build-cost` for a grader's,
# test-author's or analyst's return, once per brief; every `build-cost` gains tool=, model=, effort= (the
# effective values, from the transcript or Codex's events) and brief-bytes=. At each `return`, once per return
# file, `manager-cost calls= input= since=<the previous manager-cost's at>` from the run manager's transcript. A
# Codex builder's cost is read from .vid/jobs/<try>.events by its own reader.
# v0.9.7.1 (3.12, R12) — `plugins` lists the enabled plugins that are not ViD's, from the host's settings files at
# user, project and local scope (the later scope wins), each with the scope that enables it, then the project
# setting that turns one off and the note that a local setting or the organisation can override it. A notice.
# v0.9.7.2 (3.5, R8) — catch-up grading. `write --role grader --catch-up <step>` takes the rows and the evidence
# itself (no --rows, --claim or --receipt): the step's newest step-closed names the close's evidence — its batch=
# ticket when present (each row joined to the chunks that credit it, as for --receipt <batch>), else its report=;
# the rows are the step's ungraded eligible rows (checks/metrics.sh step-state) that pass on that evidence now —
# passing at HEAD on the receipts published by the close (checks/evidence.sh rows --until) and on every receipt, and
# every one of the row's cases in the close's evidence passed. A stale or amended row is left out, named, for a run, a claim and a
# grade; none left is a refusal.
# v0.9.7.2 (3.11, R15): `return`, on ok, reads the returned step's state (checks/metrics.sh step-state), which
# records `step-rows-passing` the first time the step's rows all pass.
# v0.9.8 (3.3, R5) — the authority bundle. A test-author's and grader's brief adds `## 15 authority`:
# the owner answers the section 2 items' `source:` cites (A-NNN, whole), each as its latest row in a ```vid-prd-answers
# block (AMENDED kept; a test-author's new or changed one from the working tree, listed pending-append:), and the
# design states the rows' markers cite — `<row> <marker> <files under design/ at HEAD holding it, or none>`. With
# sections 2 (the arms) and 3 (the decisions, 0.9.7.3's join) that is the bundle. The check refuses an answer line
# that is not PRD.md's at quoted-at verbatim, and a design line naming a row not briefed, a marker the row does not
# carry, or a file not holding it at quoted-at. `authority --row <ROW-id>` prints one row's bundle at HEAD — `arm`,
# `answer`, `decision` lines with their normative content (an item's statement and fail-if, an answer's A: text, a
# decision's rule with its label stripped, whitespace collapsed), `design` lines, then `digest <cksum>` of the
# normative lines — the join per row: a non-builder's (whole ids; applies-to labels meeting the row, its derived-from
# ids, its screen codes, its DIF ids), never the RULE join or scope: project, which are a builder's.
# v0.9.8 (3.3, R6) — authority changes raise a flag, never a wipe. `authority --changed` prints `authority-changed
# row=<id> since=<commit> what=<ids>` for each row whose bundle — selected by HEAD's records — holds an arm or an
# answer whose normative content changed since the row's baseline, or is new there, or a decision that existed there
# and whose rule changed (a decision added since does not flag). The baseline (amendment 3): the latest of the last
# change to the row's INVENTORY line, the last change to its test file, its kept record (authority-kept sha=) and an
# amendment of the row itself (amended by=obligation). Selecting by HEAD and
# comparing content canonically, a relabel raises nothing. --rows narrows it; --since <commit>, or --base <file> of
# `<row><TAB><commit>` lines, sets the baseline. `authority --kept <ROW-id,…>` records `authority-kept row= sha=<HEAD>`
# — a test-author pass kept the row as it is — which clears its flag until the bundle changes again. Verdicts,
# attempts and holds are untouched; checks/inventory.sh --report lists the flag.
# Usage: sh checks/brief.sh <brief-file> [--at <sha>]
#        sh checks/brief.sh authority --row <ROW-id> [--at <commit>] | --changed [--rows <ROW-id,…>] [--since <commit> | --base <file>] | --kept <ROW-id,…>   (v0.9.8)
#        sh checks/brief.sh return <hand-back file> [--agent <id|codex:<try>>]
#        sh checks/brief.sh write --role grader --slice <N> --catch-up <step>   (v0.9.7.2)
#        sh checks/brief.sh write --role builder|grader|fixer|test-author --slice <N> (--rows <ROW-id,…> | --claim <file>) [--step <id>] [--selection '<selection>' [--deployed-selection '<selection>']] [--receipt <name>] [--decisions <D-id,…>] [--notes <file>] [--upgrade] [--continue <package> [--law <sha>]]
#        sh checks/brief.sh save <brief> [--worktree <path>] | restore <brief> | cost <brief> --agent <id> | context | plugins | protected
set -u
IFS='
'
HDR='Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role — `vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose for a role without one) with no authoring-session and no build-session context. It receives only what this file lists under `receives:` and nothing under `must not receive:`; a re-run is never told the previous verdict; a pass whose prompt carries anything the calling session believes is VOID and is re-spawned. Independence is a mechanism here, not a property.'
EXCL='Do not read under `.vid/` beyond the receipt named above.'
EXCLB='Do not read under `.vid/` beyond the receipts named above.'   # v0.9.7.0.12 (3.5, R5): a close batch's grader
WITHHELD='(detail withheld from graders)'
# --- v0.9.7.0.7 (3.2): the builder's mechanical joins, shared by `write` and the check ---
# whole-id containment: an id never matches inside a longer one (ROW-12 is not ROW-120)
WHOLE='function has(s, id,   p, q, b, a) { q = s; while ((p = index(q, id)) > 0) { b = (p > 1) ? substr(q, p - 1, 1) : ""; a = substr(q, p + length(id), 1); if (b !~ /[A-Za-z0-9_-]/ && a !~ /[A-Za-z0-9_-]/) return 1; q = substr(q, p + 1) } return 0 }'
# ROWLINES: the awk program of section 9's search — the numbers of the lines holding row id `a` as ROW-n or ROW_n, a
# whole id, comma-separated. checks/test.sh's estimate holds the same line (v0.9.7.0.9 3.1); the selftest pins the two.
ROWLINES='BEGIN { b = a; gsub(/-/, "_", b) } function w(s, id,   p, q, o, x, y) { q = s; o = 0; while ((p = index(q, id)) > 0) { x = (o + p > 1) ? substr(s, o + p - 1, 1) : ""; y = substr(s, o + p + length(id), 1); if (x !~ /[A-Za-z0-9]/ && y !~ /[A-Za-z0-9]/) return 1; o += p; q = substr(s, o + 1) } return 0 } w($0, a) || w($0, b) { printf "%s%d", (n++ ? "," : ""), NR }'
# locs <rows file> <commit>: section 9 — one line per row, from its test field's file at <commit>
locs() {
  awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } { t = tr($8); sub(/[ \t].*/, "", t); print tr($1) "\t" t }' "$1" | while IFS='	' read -r _id _t; do
    case "$_t" in owed:*) printf '%s owed\n' "$_id"; continue ;; '') printf '%s none\n' "$_id"; continue ;; esac
    _l=$(git show "$2:$_t" 2>/dev/null | awk -v a="$_id" "$ROWLINES")
    if [ -n "$_l" ]; then printf '%s %s:%s\n' "$_id" "$_t" "$_l"; else printf '%s none\n' "$_id"; fi
  done
}
# planhash: the plan in force — the latest plan-change event's hash, here
# mfiles <ref> <marker>: the files under design/ at <ref> holding the marker — its literal (`P03/form`) or its canvas
# comment (`@screen P03 … state=form`), comma-separated, nothing when none (v0.9.8.1 R19: a per-screen pack's canvas
# carries only the comment)
mfiles() { _mc=${2%%/*}; _ms=${2#*/}
  git grep -l -E -e "$_mc/$_ms" -e "@screen[[:space:]]+$_mc[[:space:]][^>]*state=$_ms([^A-Za-z0-9_-]|\$)" "$1" -- design/ 2>/dev/null | sed "s/^$1://" | paste -sd ',' -; }
planhash() { [ -f .vid/metrics-events ] && awk '$1 == "plan-change" { for (i = 2; i <= NF; i++) if (index($i, "hash=") == 1) h = substr($i, 6) } END { print h }' .vid/metrics-events; }
# steplines <plan file> <step>: the step's line, then the lines of the steps in its builds-on:, verbatim
steplines() {
  awk -v st="$2" 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /^[ \t]*step[ \t]/ { n = split($0, f, "|"); id = tr(f[1]); sub(/^step[ \t]+/, "", id); id = tr(id); L[id] = $0
      for (k = 2; k <= n; k++) { x = tr(f[k]); if (x ~ /^builds-on:/) B[id] = tr(substr(x, 11)) } }
    END { if (!(st in L)) exit 1; print L[st]; n = split(B[st], a, /[ ,\t]+/); for (k = 1; k <= n; k++) if (a[k] != "" && a[k] != "-" && (a[k] in L)) print L[a[k]] }' "$1"
}
# archrows <architecture file> <step line>: the module table's header, separator and the rows whose Module column is one of the step's modules
archrows() {
  _m=$(printf '%s\n' "$2" | awk -F'|' '{ for (k = 2; k <= NF; k++) { x = $k; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^modules:/) print substr(x, 9) } }')
  awk -v mods="$_m" 'function nm(s) { gsub(/^[ \t`]+|[ \t`]+$/, "", s); gsub(/\./, "/", s); sub(/\/+$/, "", s); return s }
    BEGIN { n = split(mods, a, /[ ,\t]+/); for (k = 1; k <= n; k++) if (a[k] != "") M[nm(a[k])] = 1 }
    /^[ \t]*\|/ { if (!col) { n = split($0, c, "|"); for (k = 2; k < n; k++) { x = c[k]; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x == "Module") { col = k; hdr = $0; next } } next }
      if ($0 ~ /^[ \t]*\|[ \t:|-]*$/) { sep = $0; next } split($0, c, "|"); if (nm(c[col]) in M) R[++r] = $0; next }
    col && !/^[ \t]*\|/ { col = 0 }
    END { if (r) { print hdr; if (sep != "") print sep; for (k = 1; k <= r; k++) print R[k] } }' "$1"
}
# rulerows <inventory block> <ids file>: the rule rows whose origin: cites one of the ids, whole
rulerows() {
  awk -F'|' -v idf="$2" "$WHOLE"'
    BEGIN { while ((getline l < idf) > 0) if (l != "") I[++ni] = l }
    { k1 = $1; gsub(/^[ \t]+|[ \t]+$/, "", k1); if (k1 != "rule") next
      for (i = 2; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (index(f, "origin:") != 1) continue
        for (k = 1; k <= ni; k++) if (has(f, I[k])) { print; next } } }' "$1"
}
# callrows <architecture file> <step line>: v0.9.7.1 (3.2d, R2) — the module-table rows whose Dependents column names one
# of the step's modules (`/` and `.` equal, a trailing `/` ignored) or `all`: the modules the step may call
callrows() {
  _m=$(printf '%s\n' "$2" | awk -F'|' '{ for (k = 2; k <= NF; k++) { x = $k; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^modules:/) print substr(x, 9) } }')
  awk -v mods="$_m" 'function nm(s) { gsub(/^[ \t`]+|[ \t`]+$/, "", s); gsub(/\./, "/", s); sub(/\/+$/, "", s); return s }
    BEGIN { n = split(mods, a, /[ ,\t]+/); for (k = 1; k <= n; k++) if (a[k] != "") M[nm(a[k])] = 1 }
    /^[ \t]*\|/ { if (!col) { n = split($0, c, "|"); for (k = 2; k < n; k++) { x = c[k]; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x == "Module") col = k; if (x == "Dependents") dcol = k } if (!col || !dcol) col = 0; next }
      if ($0 ~ /^[ \t]*\|[ \t:|-]*$/) next; split($0, c, "|"); n = split(c[dcol], d, /[ ,]+/)
      for (k = 1; k <= n; k++) { x = nm(d[k]); if (x == "all" || (x in M)) { print; next } } next }
    col && !/^[ \t]*\|/ { col = 0; dcol = 0 }' "$1"
}
# --- v0.9.7.1 (3.4, R4): the one protected-path set — save, restore, Codex's profile and the receipt check ---
# protected: one path a line, a directory ending `/` — the commit hook's rule 1 directories, every file checks/lawfiles
# names, PRD.md, DEPLOYMENT.md, DESIGN-BRIEF.md and the harness file. DECISIONS.md is not in it.
protected() {
  printf '%s\n' tests/invariants/ checks/ design/ PRD.md DEPLOYMENT.md DESIGN-BRIEF.md docker-compose.test.yml
  [ -f checks/lawfiles ] && awk '!/^[ \t]*#/ && NF { print $1 }' checks/lawfiles
}
# isprot <path>: the path is in the protected set
isprot() { protected | awk -v p="$1" '{ if ((substr($0, length($0)) == "/" && index(p, $0) == 1) || p == $0) f = 1 } END { exit f ? 0 : 1 }'; }
# --- v0.9.8 (3.3, R5, R6): the authority bundle — a row's effective PRD arms (its derived-from items, amendments
# applied), the owner answers their source: cites, the decisions 0.9.7.3's join gives a non-builder role (whole ids,
# applies-to labels; no RULE join, no scope: project — builders only, as today) and the design states its marker
# cites. Normative content, compared canonically: an item's statement and fail-if, an answer's A: text, a decision's
# rule (the line up to ' | why:', its label fields stripped), whitespace collapsed — a relabel or a metadata edit
# (plain:, covers:, feature:, source:, …) changes none of it. ---
# acanon <PRD file> <DECISIONS file>: `<id>\t<canonical text>`, latest per id (AMENDED stripped); a legacy block-form
# PRD's `### REQ-NNN` blocks whole, the last heading winning
acanon() {
  awk 'function c(s) { gsub(/[ \t]+/, " ", s); gsub(/^ | $/, "", s); return s }
    function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    FNR == 1 { blk = ""; lg = "" }
    FILENAME == ARGV[1] && /^```/ { if (blk == "") { blk = substr($0, 4); sub(/[ \t].*/, "", blk); if (blk == "") blk = "-" } else blk = ""; next }
    FILENAME == ARGV[1] && blk == "vid-prd" && !/^[ \t]*#/ { n = split($0, f, "|"); id = tr(f[1]); sub(/[ \t]+AMENDED$/, "", id); if (id !~ /^[A-Z]+-[0-9A-Za-z_.-]+$/) next
      fi = ""; for (k = 2; k <= n; k++) { x = tr(f[k]); if (index(x, "fail-if:") == 1) fi = x }
      C[id] = c(tr(f[4]) " || " fi); next }
    FILENAME == ARGV[1] && blk == "vid-prd-answers" && !/^[ \t]*#/ { n = split($0, f, "|"); id = tr(f[1]); sub(/[ \t]+AMENDED$/, "", id); if (id !~ /^A-[0-9]+$/) next
      a = ""; for (k = 2; k <= n; k++) { x = tr(f[k]); if (index(x, "A:") == 1) a = x }
      C[id] = c(a); next }
    FILENAME == ARGV[1] && blk == "" && /^#/ { lg = ""; if ($0 ~ /^### REQ-[0-9]+/) { match($0, /REQ-[0-9]+/); lg = substr($0, RSTART, RLENGTH); L[lg] = "" } next }
    FILENAME == ARGV[1] && blk == "" && lg != "" { L[lg] = L[lg] " " $0; next }
    FILENAME == ARGV[2] && /^- \*\*D-[0-9]+\*\*/ { match($0, /D-[0-9]+/); id = substr($0, RSTART, RLENGTH); r = $0; p = index(r, " | why:"); if (p) r = substr(r, 1, p - 1)
      n = split(r, f, / \| /); o = ""; for (k = 1; k <= n; k++) { x = tr(f[k]); if (x ~ /^(applies-to|scope):/) continue; o = o (o == "" ? "" : " | ") x }
      C[id] = c(o); next }
    END { for (k in L) if (!(k in C)) C[k] = c(L[k]); for (k in C) print k "\t" C[k] }' "$1" "$2"
}
# aselect <inventory block> <effective items> <DECISIONS file> <canon> [<rows file>]: `<row>\t<kind>\t<id>` — the row's
# bundle at that commit: kind arm (each derived-from id that is an item of the canon), answer (each A- id an arm's
# source: cites), decision (the join), design (each marker of its marker field). Only the rows of <rows file> when given.
aselect() {
  awk -F'|' -v ef="$2" -v df="$3" -v cf="$4" -v rf="${5:-}" "$WHOLE"'
    function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function label(s,   n, k, f, t, m, a, i2) { split("", AP); nap = 0; n = split(s, t, "|")
      for (k = 2; k <= n; k++) { f = tr(t[k]); if (f ~ /^scope:[ \t]*project$/) return "project"
        if (f ~ /^applies-to:/) { sub(/^applies-to:[ \t]*/, "", f); m = split(f, a, /[ ,]+/); for (i2 = 1; i2 <= m; i2++) if (a[i2] != "") AP[++nap] = a[i2]; return "applies" } }
      return "" }
    BEGIN { if (rf != "") { while ((getline l < rf) > 0) if (l != "") W[l] = 1; want = 1 }
      while ((getline l < cf) > 0) { split(l, ff, "\t"); if (ff[1] !~ /^(A|D)-[0-9]+$/) IT[ff[1]] = 1 }
      while ((getline l < ef) > 0) { n = split(l, ff, "|"); id = tr(ff[1]); if (id == "") continue
        for (k = 2; k <= n; k++) { x = tr(ff[k]); if (index(x, "source:") == 1) { s = x; while (match(s, /A-[0-9]+/)) { SRC[id] = SRC[id] " " substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } } } }
      while ((getline l < df) > 0) if (l ~ /^- \*\*D-[0-9]+\*\*/) { nd++; DL[nd] = l; match(l, /D-[0-9]+/); DI[nd] = substr(l, RSTART, RLENGTH) } }
    { id = tr($1); if (id !~ /^ROW-/) next; if (want && !(id in W)) next
      split("", J); nj = 0; J[++nj] = id; split("", JS); JS[id] = 1
      n = split(tr($7), a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "") { J[++nj] = a[k]; JS[a[k]] = 1
        if (a[k] in IT) { print id "\tarm\t" a[k]; m = split(SRC[a[k]], sv, " "); for (q = 1; q <= m; q++) if (sv[q] != "" && !((id, sv[q]) in SA)) { SA[id, sv[q]] = 1; print id "\tanswer\t" sv[q] } } }
      split("", SC); n = split(tr($5), a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "n/a" && a[k] != "-" && a[k] != "") { print id "\tdesign\t" a[k]; if (index(a[k], "/") > 1) SC[substr(a[k], 1, index(a[k], "/") - 1)] = 1 }
      split("", DF); for (i = 8; i <= NF; i++) { f = tr($i); if (f ~ /^divergence:/) { sub(/^divergence:[ \t]*/, "", f); m = split(f, a, /[ ,]+/); for (k = 1; k <= m; k++) if (a[k] ~ /^DIF-[0-9]+$/) DF[a[k]] = 1 } }
      for (d = 1; d <= nd; d++) { hit = 0; for (k = 1; !hit && k <= nj; k++) if (has(DL[d], J[k])) hit = 1
        if (!hit && label(DL[d]) == "applies") for (k = 1; !hit && k <= nap; k++) if ((AP[k] in JS) || (AP[k] in SC) || (AP[k] in DF)) hit = 1
        if (hit) print id "\tdecision\t" DI[d] } }' "$1"
}
# astate <commit> <dir>: the records at <commit> into <dir> — inv (the INVENTORY block), eff (the effective items),
# dec (DECISIONS lines), canon (acanon); a canon is reused across commits with the same PRD and DECISIONS blobs
astate() {
  mkdir -p "$2"
  git show "$1:INVENTORY.md" 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | sed '1d;$d' > "$2/inv"
  git show "$1:PRD.md" > "$2/prd" 2>/dev/null || : > "$2/prd"
  git show "$1:DECISIONS.md" 2>/dev/null | grep -E '^- \*\*D-[0-9]+\*\*' > "$2/dec" || : > "$2/dec"
  sh checks/prd.sh --effective "$2/prd" > "$2/eff" 2>/dev/null || : > "$2/eff"
  _ck="${ACACHE:-$2}/canon.$(git rev-parse -q --verify "$1:PRD.md" 2>/dev/null || echo none).$(git rev-parse -q --verify "$1:DECISIONS.md" 2>/dev/null || echo none)"
  [ -f "$_ck" ] || acanon "$2/prd" "$2/dec" > "$_ck"
  cp "$_ck" "$2/canon"
}
# adigest <state dir> <row>: the digest of the row's normative bundle (arms, answers, decisions) in that state
adigest() { printf '%s\n' "$2" > "$1/dr"; aselect "$1/inv" "$1/eff" "$1/dec" "$1/canon" "$1/dr" | awk -F'\t' 'FILENAME == ARGV[1] { C[$1] = $2; next } $2 != "design" { print $3 "\t" C[$3] }' "$1/canon" - | sort -u | cksum | cut -d' ' -f1; }
# achanged <row-baseline file: row<TAB>commit> <work dir>: `<row>\t<commit>\t<id>[,<id>…]` for each row whose bundle at
# HEAD (selected by HEAD's records) holds an id whose normative content differs at <commit>: an arm or an answer changed
# or new there, or a decision that existed there with its rule changed (a decision added since does not flag: measured
# on a scratch copy of the evidence run, flagging additions listed 996 of 1,169 rows, these changes 78)
achanged() {
  ACACHE=$2; export ACACHE
  astate HEAD "$2/head"; cut -f1 "$1" | sort -u > "$2/rows"
  aselect "$2/head/inv" "$2/head/eff" "$2/head/dec" "$2/head/canon" "$2/rows" | awk -F'\t' '$2 != "design"' > "$2/sel"
  : > "$2/out"
  for _c in $(cut -f2 "$1" | sort -u); do
    _d=$2/c.$_c; git rev-parse -q --verify "$_c^{commit}" > /dev/null 2>&1 || continue
    astate "$_c" "$_d" > /dev/null 2>&1
    awk -F'\t' -v c="$_c" 'FILENAME == ARGV[1] { if ($2 == c) R[$1] = 1; next } FILENAME == ARGV[2] { N[$1] = $2; next } FILENAME == ARGV[3] { O[$1] = $2; next }
      ($1 in R) && ($3 in N) && ((($3 in O) && O[$3] != N[$3]) || (!($3 in O) && $3 !~ /^D-/)) && !(($1, $3) in S) { S[$1, $3] = 1; W[$1] = W[$1] (W[$1] == "" ? "" : ",") $3 }
      END { for (r in W) print r "\t" c "\t" W[r] }' "$1" "$2/head/canon" "$_d/canon" "$2/sel" >> "$2/out"
  done
  sort "$2/out"
}
# abase: `<row>\t<commit>` — each row's baseline (v0.9.8 amendment 3): the latest of the last commit that changed the
# row's INVENTORY line (git blame at HEAD), the last commit that changed a line of its own test file naming it (ROW-n
# or ROW_n, whole — an edit for another row in a shared file is not this row's), its kept record
# (authority-kept … sha=) and an amendment of the row itself (amended … by=obligation — never one an item's fail-if
# caused, which is the change the flag exists to bring back); latest by HEAD's history, nearest HEAD first. A commit
# the history does not hold is left out.
abase() {
  _ab=$(mktemp -d)
  git rev-list HEAD 2>/dev/null | awk '{ print "O\t" $1 "\t" NR }' > "$_ab/ab.ord"
  git show HEAD:INVENTORY.md 2>/dev/null | awk -F'|' '/^```vid-inventory/ { on = 1; next } on && /^```$/ { on = 0 }
      on && $1 ~ /^[[:space:]]*ROW-/ { id = $1; t = $8; gsub(/^[ \t]+|[ \t]+$/, "", id); gsub(/^[ \t]+|[ \t]+$/, "", t); sub(/[ \t].*/, "", t); print id "\t" NR "\t" t }' > "$_ab/ab.rows"
  git blame --porcelain HEAD -- INVENTORY.md 2>/dev/null | awk '/^[0-9a-f]{40} [0-9]+ [0-9]+/ { print "L\t" $3 "\t" $1 }' > "$_ab/ab.blame"
  : > "$_ab/ab.files"
  for _tf in $(cut -f3 "$_ab/ab.rows" | grep '^tests/' | sort -u); do
    # newest first: the first commit whose changed lines name a row is that row's last change in this file
    git log -p -U0 --format='C %H' HEAD -- "$_tf" 2>/dev/null | awk -v f="$_tf" '/^C [0-9a-f]+$/ { c = $2; next }
      /^(\+\+\+|---) / { next }
      /^[-+]/ { t = $0; while (match(t, /ROW[-_][0-9]+/)) { id = substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH)
          if (t ~ /^[0-9A-Za-z]/) continue; gsub(/_/, "-", id); if (!(id in S)) { S[id] = 1; print "F\t" f "\t" id "\t" c } } }' >> "$_ab/ab.files"
  done
  { [ -f .vid/metrics-events ] && awk 'function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
      ($1 == "authority-kept" || ($1 == "amended" && kv("by") == "obligation")) && kv("row") != "" && kv("sha") != "" { print "E\t" kv("row") "\t" kv("sha") }' .vid/metrics-events; } > "$_ab/ab.ev" || : > "$_ab/ab.ev"
  awk -F'\t' 'FILENAME == ARGV[1] { O[$2] = $3; P[substr($2, 1, 12)] = $3; F[substr($2, 1, 12)] = $2; next }
      FILENAME == ARGV[2] { BL[$2] = $3; next }
      FILENAME == ARGV[3] { TF[$2, $3] = $4; next }
      FILENAME == ARGV[4] { k = substr($3, 1, 12); if ((k in P) && (!($2 in EV) || P[k] < EO[$2])) { EV[$2] = F[k]; EO[$2] = P[k] } next }
      function cand(c) { if (c != "" && (c in O) && (best == "" || O[c] < O[best])) best = c }
      { best = ""; cand(BL[$2]); cand(TF[$3, $1]); if ($1 in EV) cand(EV[$1]); if (best != "") print $1 "\t" best }' \
    "$_ab/ab.ord" "$_ab/ab.blame" "$_ab/ab.files" "$_ab/ab.ev" "$_ab/ab.rows" | sort
  rm -rf "$_ab"
}
# --- v0.9.7.1 (3.8, R8): the run manager's context — its own session, matched by RUN-STATE's session: ---
mgr_session() { sed -n 's/^session:[[:space:]]*//p' .vid/RUN-STATE.md 2>/dev/null | head -n 1 | awk '{ print $1 }'; }
mgr_transcript() {
  _sid=$(mgr_session); [ -n "$_sid" ] && [ -f .vid/metrics-events ] || return 0
  awk -v s="id=$_sid" '$1 == "session" { hit = 0; for (i = 2; i <= NF; i++) if ($i == s) hit = 1; if (!hit) next
      p = index($0, " transcript="); if (!p) next; t = substr($0, p + 12); if (substr(t, 1, 1) == "\"") { t = substr(t, 2); q = index(t, "\""); t = substr(t, 1, q - 1) } else sub(/ .*/, "", t); last = t }
    END { if (last != "" && last != "-") print last }' .vid/metrics-events
}
# usage_ctx: the last assistant entry's context on stdin — input + cache read + cache creation (as `return` counts each call)
USAGECTX='function num(s, k,   p, t) { p = index(s, "\"" k "\":"); if (!p) return 0; t = substr(s, p + length(k) + 3); match(t, /^[0-9]+/); return (RLENGTH > 0) ? substr(t, 1, RLENGTH) + 0 : 0 }
  index($0, "\"role\":\"assistant\"") && (u = index($0, "\"usage\":{")) { s = substr($0, u); c = num(s, "input_tokens") + num(s, "cache_read_input_tokens") + num(s, "cache_creation_input_tokens"); any = 1 }
  END { if (any) print c; else print "unknown" }'
mgr_context() { _t=$(mgr_transcript); if [ -n "$_t" ] && [ -r "$_t" ]; then tail -n 400 "$_t" | awk "$USAGECTX"; else echo unknown; fi; }
# ctx_notice: above 350000, `context <n>` and, once per crossing, `context-high n=` — never a stop
ctx_notice() {
  _c=$(mgr_context); case "$_c" in ''|unknown|*[!0-9]*) return 0 ;; esac
  [ "$_c" -gt 350000 ] || return 0
  echo "context $_c — the run manager's context is above 350000 tokens (a notice; compact when the project's autoCompactWindow is not working)"
  _sid=$(mgr_session)
  awk -v s="id=$_sid" '$1 == "session" { for (i = 2; i <= NF; i++) if ($i == s) h = 0 } $1 == "context-high" { h = 1 } END { exit h ? 0 : 1 }' .vid/metrics-events 2>/dev/null && return 0
  printf 'context-high n=%s at=%s\n' "$_c" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
}
# --- v0.9.7.1 (3.11, R11): the cost readers beside tcost ---
# tmodel <transcript>: `model=<m> effort=<e>` — the last assistant entry's model and the last effort the transcript carries
tmodel() { awk 'index($0, "\"role\":\"assistant\"") && match($0, /"model":"[^"]*"/) { m = substr($0, RSTART + 9, RLENGTH - 10) }
    match($0, /"effort":"[^"]*"/) { e = substr($0, RSTART + 10, RLENGTH - 11) } END { printf "model=%s effort=%s\n", (m == "" ? "unknown" : m), (e == "" ? "unknown" : e) }' "$1"; }
# ccost <codex events file>: `peak=unknown total= before-change=unknown` — Codex's documented JSONL (`codex exec --json`):
# each `turn.completed` carries its turn's usage summed over all its calls (an exec is one turn, measured in rehearsal
# R-6), so no call's context can be read: the total is the input_tokens summed (cached input included), the peak
# unknown. Kept apart from tcost.
ccost() { awk 'function num(s, k,   p, t) { p = index(s, "\"" k "\":"); if (!p) return -1; t = substr(s, p + length(k) + 3); match(t, /^[0-9]+/); return (RLENGTH > 0) ? substr(t, 1, RLENGTH) + 0 : -1 }
    index($0, "\"turn.completed\"") && (u = index($0, "\"usage\":{")) { c = num(substr($0, u), "input_tokens"); if (c < 0) next; tot += c; if (c > peak) peak = c; any = 1 }
    END { if (!any) print "peak=unknown total=unknown before-change=unknown"; else printf "peak=unknown total=%d before-change=unknown\n", tot }' "$1"; }
# cmodel <job record>: the model and effort the job launched with — Codex reports neither in its events
cmodel() { _m=$(sed -n 's/^model=//p' "$1" 2>/dev/null | head -n 1); _e=$(sed -n 's/^effort=//p' "$1" 2>/dev/null | head -n 1); printf 'model=%s effort=%s\n' "${_m:-unknown}" "${_e:-unknown}"; }
# mcost <transcript> <since UTC|empty>: `calls=<n> input=<t>` — the run manager's API calls after <since>, one per message id,
# each call's input + cache read + cache creation
mcost() { awk -v since="$2" 'function num(s, k,   p, t) { p = index(s, "\"" k "\":"); if (!p) return 0; t = substr(s, p + length(k) + 3); match(t, /^[0-9]+/); return (RLENGTH > 0) ? substr(t, 1, RLENGTH) + 0 : 0 }
    index($0, "\"role\":\"assistant\"") && (u = index($0, "\"usage\":{")) { ts = ""; if (match($0, /"timestamp":"[^"]*"/)) ts = substr($0, RSTART + 13, 19) "Z"
      if (since != "" && ts != "" && ts <= since) next
      id = ""; if (match($0, /"id":"msg_[^"]*"/)) id = substr($0, RSTART, RLENGTH); if (id == "") id = "line" NR; if (id in S) next; S[id] = 1
      s = substr($0, u); n++; t += num(s, "input_tokens") + num(s, "cache_read_input_tokens") + num(s, "cache_creation_input_tokens") }
    END { printf "calls=%d input=%d\n", n, t }' "$1"; }
# tcost <agent transcript> <modules>: `peak=<t> total=<t> before-change=<t|unknown>[ shell]` (3.3)
tcost() {
  awk -v mods="$2" '
    function num(s, k,   p, t) { p = index(s, "\"" k "\":"); if (!p) return 0; t = substr(s, p + length(k) + 3); match(t, /^[0-9]+/); return (RLENGTH > 0) ? substr(t, 1, RLENGTH) + 0 : 0 }
    function str(s, k,   p, t, o, c, i) { p = index(s, "\"" k "\":\""); if (!p) return ""; t = substr(s, p + length(k) + 4); o = ""
      for (i = 1; i <= length(t); i++) { c = substr(t, i, 1); if (c == "\\") { i++; c = substr(t, i, 1); if (c == "n" || c == "t") c = " "; o = o c; continue } if (c == "\"") break; o = o c } return o }
    function nm(s) { sub(/\/+$/, "", s); return s }
    function under(p,   k) { for (k = 1; k <= nmod; k++) if (p == M[k] || index(p, M[k] "/") == 1) return 1; return 0 }
    function names(c,   k, p, q, b) { for (k = 1; k <= nmod; k++) { q = c; while ((p = index(q, M[k] "/")) > 0) { b = (p > 1) ? substr(q, p - 1, 1) : ""; if (b !~ /[A-Za-z0-9_.-]/) return 1; q = substr(q, p + 1) } } return 0 }
    # v0.9.7.0.9 (3.7, R10): a shell call is a product change only when a path it WRITES is under a module — words only
    function wpath(p) { if (cwd != "" && index(p, cwd "/") == 1) p = substr(p, length(cwd) + 2); while (substr(p, 1, 2) == "./") p = substr(p, 3); return (p !~ /^\// && under(p)) }
    function segw(cmd, nop, OP, si, sx,   k) {
      if (cmd == "tee" || cmd == "mv" || cmd == "rm") { for (k = 1; k <= nop; k++) if (wpath(OP[k])) return 1; return 0 }
      if (cmd == "sed" && si) { for (k = (sx ? 1 : 2); k <= nop; k++) if (wpath(OP[k])) return 1; return 0 }
      if (cmd == "cp" && nop >= 2) return wpath(OP[nop])
      return 0 }
    # hsplit: the command without its here-document bodies; the bodies, joined, in HB — from the delimiter word after
    # << to its next whole occurrence (the transcript gives the command on one line)
    function hsplit(c,   s, o, dl, p, q, k, hb, ha) { o = ""; HB = ""; s = c
      while (match(s, /<<-?[ ]*/)) { o = o substr(s, 1, RSTART - 1) " "; s = substr(s, RSTART + RLENGTH); q = substr(s, 1, 1); if (q == "\"" || q == "\047") s = substr(s, 2)
        if (!match(s, /^[A-Za-z0-9_]+/)) continue; dl = substr(s, 1, RLENGTH); s = substr(s, RLENGTH + 1); if (substr(s, 1, 1) == "\"" || substr(s, 1, 1) == "\047") s = substr(s, 2)
        p = 0; q = s; while ((k = index(q, dl)) > 0) { hb = substr(q, k - 1, 1); ha = substr(q, k + length(dl), 1); if (hb == " " && ha !~ /[A-Za-z0-9_]/) { p = (length(s) - length(q)) + k; break } q = substr(q, k + 1) }
        if (!p) { HB = HB " " s; s = ""; break } HB = HB " " substr(s, 1, p - 1); s = substr(s, p + length(dl)) }
      return o s }
    # unq: quotes dropped; inside them a blank joins the word (\004) and a shell metacharacter is no metacharacter (\005)
    function unq(c,   o, i, ch, q) { o = ""; q = ""
      for (i = 1; i <= length(c); i++) { ch = substr(c, i, 1)
        if (q != "") { if (ch == q) { q = ""; continue } if (ch == "\\" && q == "\"") { i++; o = o substr(c, i, 1); continue }
          if (ch == " " || ch == "\t") ch = "\004"; else if (index("<>|&;()", ch)) ch = "\005"; o = o ch; continue }
        if (ch == "\"" || ch == "\047") { q = ch; continue } o = o ch }
      return o }
    # scr: the quoted scripts after -c or -e options, joined (an unclosed quote: the rest)
    function scr(c,   s, q, p, o) { o = ""; s = c
      while (match(s, /[ ]-[ce][ ]+["\047]/)) { q = substr(s, RSTART + RLENGTH - 1, 1); s = substr(s, RSTART + RLENGTH); p = index(s, q)
        if (!p) { o = o " " s; break } o = o " " substr(s, 1, p - 1); s = substr(s, p + 1) }
      return o }
    function shw(c,   d, n, w, i, x, cmd, nop, OP, si, sx) {
      # kept: patch and git apply count when the command names a module path; a script fed on stdin (a here-document)
      # or by -c/-e when that script itself names one (a pattern after grep -c, or a scratch script, is no product write)
      if (names(c) && (c ~ /(^|[ ;|&(])patch([ ]|$)/ || c ~ /git[ ]+apply/)) return 1
      d = hsplit(c); if (names(HB) || names(scr(d))) return 1
      d = unq(d); gsub(/[0-9]*>&[0-9-]*/, " ", d); gsub(/&>/, " > ", d); gsub(/>>/, " \002 ", d); gsub(/>/, " > ", d); gsub("\002", ">>", d)
      gsub(/\|\||&&/, " \003 ", d); gsub(/[|&;()]/, " \003 ", d)
      n = split(d, w, /[ \t]+/); cmd = ""; nop = 0; si = 0; sx = 0; split("", OP)
      for (i = 1; i <= n + 1; i++) {
        if (i > n || w[i] == "\003") { if (segw(cmd, nop, OP, si, sx)) return 1; cmd = ""; nop = 0; si = 0; sx = 0; split("", OP); continue }
        x = w[i]; if (x == "") continue
        if (x == ">" || x == ">>") { i++; if (i <= n && w[i] != "\003" && w[i] != "/dev/null" && wpath(w[i])) return 1; continue }
        if (x ~ /^</) { if (x == "<" || x == "<<" || x == "<<-" || x == "<<<") i++; continue }
        if (cmd == "") { if (x ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue; cmd = x; sub(/.*\//, "", cmd); continue }
        if (cmd == "sed" && (x ~ /^-[A-Za-z]*i/ || x ~ /^--in-place/)) { si = 1; continue }
        if (cmd == "sed" && (x == "-e" || x == "-f" || x == "--expression" || x == "--file")) { sx = 1; i++; continue }
        if (x ~ /^-/) continue
        OP[++nop] = x }
      return 0 }
    BEGIN { n = split(mods, a, /[ ,\t]+/); for (k = 1; k <= n; k++) if (a[k] != "" && a[k] != "-") M[++nmod] = nm(a[k]) }
    {
      cwd = str($0, "cwd")
      if (index($0, "\"role\":\"assistant\"") && (u = index($0, "\"usage\":{"))) {
        mp = index($0, "\"message\":{"); mid = (mp ? str(substr($0, mp), "id") : "")
        if (mid == "" ) mid = "line" NR
        if (!(mid in CTX)) { us = substr($0, u); c = num(us, "input_tokens") + num(us, "cache_read_input_tokens") + num(us, "cache_creation_input_tokens"); CTX[mid] = c; tot += c; if (c > peak) peak = c; any = 1 }
        if ((tp = index($0, "\"type\":\"tool_use\",\"id\":\""))) { tu = substr($0, tp); tid = str(tu, "id"); tn = str(tu, "name")
          if (tn == "Write" || tn == "Edit" || tn == "NotebookEdit") { fp = str(tu, "file_path"); if (fp == "") fp = str(tu, "notebook_path")
            if (cwd != "" && index(fp, cwd "/") == 1) fp = substr(fp, length(cwd) + 2)
            if (fp !~ /^\// && under(fp)) { ED[tid] = ++ord; EM[tid] = mid } }
          else if (tn == "Bash") { cm = str(tu, "command"); if (!shell && shw(cm)) { shell = ++ord; SM = mid } } }
      }
      if (index($0, "\"type\":\"tool_result\"") && (tid = str($0, "tool_use_id")) != "" && (tid in ED) && !index($0, "\"is_error\":true")) OK[tid] = 1
    }
    END {
      if (!any) { print "peak=unknown total=unknown before-change=unknown"; exit }
      best = 0; for (t in OK) if (!best || ED[t] < best) { best = ED[t]; bm = EM[t] }
      if (shell && (!best || shell < best)) bc = CTX[SM] " shell"; else if (best) bc = CTX[bm]; else bc = "unknown"
      printf "peak=%d total=%d before-change=%s\n", peak, tot, bc }' "$1"
}
# --- v0.9.7.0.5 (3.3, R3, R4, R6): `write` assembles a grader, fixer or test-author brief from the records ---
if [ "${1:-}" = write ]; then
  shift
  wusage() { echo "ViD brief: usage — sh checks/brief.sh write --role builder|grader|fixer|test-author --slice <N> (--rows <ROW-id,…> | --claim <file> | --catch-up <step>) [--step <id>] [--selection '<selection>' [--deployed-selection '<selection>']] [--receipt <name>] [--decisions <D-id,…>] [--notes <file>] [--upgrade] [--continue <package> [--law <sha>]]" >&2; exit 2; }
  wrefuse() { echo "ViD brief write: refused — $*" >&2; exit 1; }
  WROLE=''; WSLICE=''; WROWS=''; WCLAIM=''; WSTEP=''; WRCPT=''; WDEC=''; WNOTES=''; WUP=no; WSEL=''; WDSEL=''; WCONT=''; WLAW=''; WCU=''
  while [ $# -gt 0 ]; do
    [ "$1" = --upgrade ] && { WUP=yes; shift; continue; }   # v0.9.7.0.10 (R13): a flag, no value
    [ $# -ge 2 ] || wusage
    case "$1" in
      --role) WROLE=$2 ;; --slice) WSLICE=$2 ;; --rows) WROWS=$2 ;; --claim) WCLAIM=$2 ;;
      --step) WSTEP=$2 ;; --receipt) WRCPT=$2 ;; --decisions) WDEC=$2 ;; --notes) WNOTES=$2 ;;
      --selection) WSEL=$2 ;; --deployed-selection) WDSEL=$2 ;; --continue) WCONT=$2 ;; --law) WLAW=$2 ;; --catch-up) WCU=$2 ;; *) wusage ;;
    esac
    shift 2
  done
  case "$WROLE" in builder|grader|fixer|test-author) ;; *) wusage ;; esac
  # v0.9.7.1 (3.2c, R2): a builder's and a fixer's brief carries the real request command — the run manager's selection
  case "$WROLE" in
    builder|fixer) [ -n "$WSEL" ] || wrefuse "a $WROLE brief carries its test request's selection, in the runner's syntax: --selection '<selection>' (ViD never derives one from row ids)"
      case "$WSEL$WDSEL" in *\"*|*\'*) wrefuse 'a selection word holds a quote, which the harness command cannot carry' ;; esac ;;
    *) [ -z "$WSEL$WDSEL$WCONT$WLAW" ] || wrefuse "--selection, --deployed-selection, --continue and --law brief a builder or a fixer, not a $WROLE" ;;
  esac
  [ -z "$WDSEL" ] || [ -n "$WSEL" ] || wusage
  [ -z "$WLAW" ] || [ -n "$WCONT" ] || wrefuse '--law names the law commit a continuation waits for: give --continue <package> with it'
  # v0.9.7.1 (3.9, R9): while builders are paused (Codex ran out), no builder is briefed on either tool — the owner says which
  if [ "$WROLE" = builder ] && [ "$(sed -n 's/^builder-tool=//p' .vid/budget 2>/dev/null | tail -n 1)" = paused ]; then
    wrefuse "builders are paused: Codex ran out of allowance. Ask the owner 'use Claude for builders' or 'wait for Codex' (sh checks/job.sh tool claude|codex --by owner)"
  fi
  [ -n "$WSLICE" ] || wusage
  case "$WSLICE" in */*|.*) wusage ;; esac
  # v0.9.7.2 (3.5, R8): a catch-up grader brief — the rows and the evidence come from the step's close
  if [ -n "$WCU" ]; then
    [ "$WROLE" = grader ] || wrefuse "--catch-up briefs a grader, not a $WROLE"
    [ -z "$WROWS$WCLAIM$WRCPT" ] || wrefuse '--catch-up takes its rows and its evidence from the close: no --rows, --claim or --receipt'
    CUC=$(awk -v st="$WCU" 'function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
      $1 == "step-closed" && kv("step") == st { r = kv("report"); b = kv("batch"); a = kv("at") } END { if (r != "") print r "\t" (b == "" ? "-" : b) "\t" a }' .vid/metrics-events 2>/dev/null)
    [ -n "$CUC" ] || wrefuse "step $WCU was never closed: catch-up grades a closed step from its close's evidence"
    CUR=$(printf '%s\n' "$CUC" | cut -f1); CUB=$(printf '%s\n' "$CUC" | cut -f2); CUA=$(printf '%s\n' "$CUC" | cut -f3)
    if [ "$CUB" != - ]; then WRCPT=$CUB; else WRCPT=$CUR; fi
    sh checks/metrics.sh step-state "$WCU" > "${TMPDIR:-/tmp}/vid-cu.$$" 2>&1 || { cat "${TMPDIR:-/tmp}/vid-cu.$$" >&2; rm -f "${TMPDIR:-/tmp}/vid-cu.$$"; wrefuse "the step's state could not be read (checks/metrics.sh step-state $WCU)"; }
    CUU=$(sed -n 's/^ungraded step=[^ ]* row=\([^ ]*\).*/\1/p' "${TMPDIR:-/tmp}/vid-cu.$$"); rm -f "${TMPDIR:-/tmp}/vid-cu.$$"
    [ -n "$CUU" ] || wrefuse "step $WCU has no ungraded eligible row"
  else
    { [ -n "$WROWS" ] && [ -z "$WCLAIM" ]; } || { [ -z "$WROWS" ] && [ -n "$WCLAIM" ]; } || wusage
  fi
  TAB=$(printf '\t')
  QH=$(git rev-parse HEAD 2>/dev/null) || wrefuse 'no commit at HEAD — a brief quotes the records at HEAD'
  # v0.9.7.1 (3.4c, R4): a continuation — the package's landed commits and the law commit are ancestors of HEAD
  if [ -n "$WCONT" ]; then
    WCONT=${WCONT%/}; [ -f "$WCONT/manifest" ] || wrefuse "no continuation package at $WCONT (its manifest is missing)"
    for _c in $(sed -n 's/^landed=//p' "$WCONT/manifest" | tr ' ' '\n' | grep -v '^$'); do
      git merge-base --is-ancestor "$_c" "$QH" 2>/dev/null || wrefuse "the package's landed commit $_c is not an ancestor of HEAD ($QH): merge it first"
    done
    if [ -n "$WLAW" ]; then git merge-base --is-ancestor "$WLAW" "$QH" 2>/dev/null || wrefuse "the law commit $WLAW is not an ancestor of HEAD ($QH): land it first"; fi
  fi
  # the plugin's own texts: develop's role table, the grader's pass, the test-author's pass
  PR=${CLAUDE_PLUGIN_ROOT:-}
  [ -n "$PR" ] && [ -f "$PR/skills/vid-develop/SKILL.md" ] || PR=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
  DEVSK="$PR/skills/vid-develop/SKILL.md"; GPASS="$PR/skills/vid-verify/passes/grader.md"; TPASS="$PR/skills/vid-test-inventory/passes/test-author.md"
  TSKILL="$PR/skills/vid-test-writing/SKILL.md"   # v0.9.8 (R1): the craft, the boundary rule among it
  [ -f "$DEVSK" ] || wrefuse "the plugin's skills are not found (set CLAUDE_PLUGIN_ROOT): no $DEVSK"
  [ "$WROLE" = grader ] && { [ -f "$GPASS" ] || wrefuse "the grader's pass is not found: $GPASS"; }
  [ "$WROLE" = test-author ] && { [ -f "$TPASS" ] || wrefuse "the test-author's pass is not found: $TPASS"; [ -f "$TSKILL" ] || wrefuse "the test-writing skill is not found: $TSKILL"; }
  # v0.9.7.0.7 (3.2): a builder brief names its step and quotes it from the plan in force; --notes names a file
  if [ "$WROLE" = builder ]; then
    [ -n "$WSTEP" ] || wrefuse 'a builder brief names its plan step (--step)'
    PH=$(planhash); PF=.vid/plans/$PH.plan
    [ -n "$PH" ] && [ -f "$PF" ] || wrefuse "a builder brief quotes its step from the plan in force, and no kept plan is found here (the latest plan-change event's hash: '${PH:-none}', .vid/plans/<hash>.plan)"
    steplines "$PF" "$WSTEP" > /dev/null || wrefuse "step $WSTEP is no step of the plan in force ($PF)"
  fi
  [ -z "$WNOTES" ] || [ -f "$WNOTES" ] || wrefuse "no such notes file: $WNOTES"
  W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
  # v0.9.7.0.10 (3.6, R13): the harness upgrade's section, from the harness at HEAD, the template and the run's records
  if [ "$WUP" = yes ]; then
    case "$WROLE" in builder|test-author) ;; *) wrefuse "--upgrade briefs a builder or a test-author, not a $WROLE" ;; esac
    UTPL="$PR/templates/docker-compose.test.yml"
    [ -f "$UTPL" ] || wrefuse "the template is not found: $UTPL"
    git show HEAD:docker-compose.test.yml > "$W/harness" 2>/dev/null || wrefuse 'no docker-compose.test.yml at HEAD — nothing to upgrade'
    # v0.9.7.0.11 (3.2, R2): due below the current target, rules: 2 — a harness at rules: 1 gains rule 4
    UHR=$(awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ ]/{inx=0} inx && $1=="rules:"{print $2; exit}' "$W/harness")
    case "$UHR" in ''|1) ;; *) wrefuse "the harness at HEAD declares rules: $UHR — nothing to upgrade" ;; esac
    UHH=$(cksum < "$W/harness" | cut -d' ' -f1)
    awk '/^# Four harness rules/ { on = 1 } on && /^#$/ { exit } on { print }' "$UTPL" > "$W/rules3"
    [ -s "$W/rules3" ] || wrefuse "the template carries no harness rules: $UTPL"
    UTL=$(ls -t .vid/requests/*/timeline.log .vid/requests/*/timeline.*.log .vid/requests/*/chunks/*/timeline.*.log 2>/dev/null | head -n 1 || true)
    # v0.9.7.0.11 (3.2, R2): rule 4's limit is set from the project's own case times — the slowest 10 in the run's .cases
    { ls .vid/ledger-results/*.cases 2>/dev/null | grep -v '\.proof\.' | while IFS= read -r _cf; do cat "$_cf"; done | awk '$1 == "case" { print $4 "\t" $2 }' | sort -t "$(printf '\t')" -k1,1 -rn | awk -F'\t' '!s[$2]++' | head -n 10; } > "$W/slow" || : > "$W/slow"
    # v0.9.7.0.11 (3.4, R4): the last 20 passes' container states (services.<pass>.txt), newest first
    # v0.9.8 (R17): kept-healthy-at, an older ticket's ready-at read under that name
    { ls -t .vid/requests/*/services.*.txt .vid/requests/*/chunks/*/services.*.txt 2>/dev/null | head -n 20 | while IFS= read -r _sf; do printf '%s:\n' "${_sf#.vid/requests/}"; sed 's/ ready-at=/ kept-healthy-at=/g; s/^\(# .*\) ready-at /\1 kept-healthy-at /; s/^/    /' "$_sf"; done; } > "$W/svcs" || : > "$W/svcs"
    { [ -f .vid/metrics-events ] && awk 'function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
        $1 == "ledger-run" && kv("run") != "" && kv("overhead") != "" && !index(kv("report"), ".proof.") { print kv("report") " seconds=" kv("seconds") " overhead=" kv("overhead") }' .vid/metrics-events | tail -n 20; } > "$W/ovh" || : > "$W/ovh"
  fi
  git show "HEAD:INVENTORY.md" 2>/dev/null | sed -n '/^```vid-inventory/,/^```$/p' | sed '1d;$d' > "$W/inv.ref"
  [ -f INVENTORY.md ] && sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' > "$W/inv.wt" || : > "$W/inv.wt"
  git show "HEAD:DECISIONS.md" 2>/dev/null | grep -E '^- \*\*D-[0-9]+\*\*' > "$W/dec" || : > "$W/dec"
  git show "HEAD:CLAUDE.md" > "$W/law" 2>/dev/null || : > "$W/law"
  [ -f checks/prd.sh ] || wrefuse 'checks/prd.sh is missing — the effective-set reader'
  git show "HEAD:PRD.md" > "$W/prd.ref" 2>/dev/null || : > "$W/prd.ref"
  sh checks/prd.sh --effective "$W/prd.ref" > "$W/eff.ref" 2>/dev/null || : > "$W/eff.ref"
  if [ -f PRD.md ]; then sh checks/prd.sh --effective PRD.md > "$W/eff.wt" 2>/dev/null || : > "$W/eff.wt"; else : > "$W/eff.wt"; fi
  [ "$WROLE" = grader ] && [ -z "$WRCPT" ] && wrefuse 'a grader brief names its receipt (--receipt)'
  RP=''; RT=''; RB=''; : > "$W/cons"
  # v0.9.7.0.12 (3.5, R5): --receipt <batch ticket> — the close batch's constituent receipts (published, retried or
  # adopted: its `receipts`), each present; the grader reads those and no other, and a row's cases come from the
  # constituents that credit it (checks/evidence.sh credit)
  if [ -n "$WRCPT" ] && [ -f ".vid/requests/$WRCPT/batch" ]; then
    RB=$WRCPT; [ -s ".vid/requests/$RB/receipts" ] || wrefuse "the close batch $RB holds no receipt"
    cut -f2 ".vid/requests/$RB/receipts" | sed 's#.*/#.vid/ledger-results/#' | awk '!s[$0]++' > "$W/cons"
    while IFS= read -r f; do [ -f "$f" ] || wrefuse "the close batch $RB names a receipt that is gone: $f"; done < "$W/cons"
  elif [ -n "$WRCPT" ]; then
    case "$WRCPT" in */*) RP=$WRCPT ;; *) RP=.vid/ledger-results/$WRCPT ;; esac
    [ -f "$RP" ] || wrefuse "no such receipt: $RP"
    case "${RP##*/}" in *.proof.*) wrefuse "$RP is a proof receipt — never an ordinary one: a grader reads the close's evidence (checks/evidence.sh ordinary)" ;; esac   # v0.9.8 (R15)
    case "$RP" in *.close.xml) RT=${RP%.close.xml}.close.deployed.xml ;; *.checkpoint.xml) RT=${RP%.checkpoint.xml}.checkpoint.deployed.xml ;; *.full.xml) RT=${RP%.full.xml}.deployed.xml ;; esac
    [ -n "$RT" ] && [ ! -f "$RT" ] && RT=''
  fi
  # a grader's receipt cases: the receipt's (and its deployed twin's), or each constituent's with the rows it credits
  # (checks/evidence.sh credit; without the reader, its .rows, else every row `*`)
  bcredit() { if [ -f checks/evidence.sh ]; then sh checks/evidence.sh credit "$1" 2>/dev/null < /dev/null || true; elif [ -f "$1.rows" ]; then grep -v '^$' "$1.rows"; else echo '*'; fi; }
  rcases() { if [ -f "$1.cases" ]; then cat "$1.cases"; elif [ -f checks/extractors/results.sh ]; then sh checks/extractors/results.sh "$1" 2>/dev/null; fi | grep -E '^case ' || true; }
  : > "$W/cases"
  if [ "$WROLE" = grader ]; then
    for f in "$RP" $RT; do [ -n "$f" ] && rcases "$f" >> "$W/cases"; done
    _i=0; while IFS= read -r f; do _i=$((_i + 1)); rcases "$f" > "$W/cs.$_i" < /dev/null; bcredit "$f" > "$W/cr.$_i"; done < "$W/cons"
  fi
  # rowcases <rows file>: the cases of each row, as metrics.sh joins them (row_cases: under its test path, naming the row, else one of its derived-from ids)
  rowcases() {
    awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } { t = tr($8); sub(/ .*/, "", t); print tr($1) "\t" t "\t" tr($7) }' "$1" | while IFS=$TAB read -r id p df; do
      [ -n "$p" ] || continue
      if [ -n "$RB" ]; then : > "$W/cases"; _i=0; while IFS= read -r f; do _i=$((_i + 1)); grep -qxF -e "$id" -e '*' "$W/cr.$_i" && cat "$W/cs.$_i" >> "$W/cases"; done < "$W/cons"; fi
      rc=$(awk -v p="$p::" -v id="$id" 'BEGIN { alt = id; gsub(/-/, "_", alt) } index($2, p) == 1 && (index($2, id) || index($2, alt)) { print }' "$W/cases")
      if [ -z "$rc" ]; then
        for q in $(printf '%s\n' "$df" | tr ' ,' '\n\n' | grep -v '^$'); do
          rc=$(awk -v p="$p::" -v id="$q" 'BEGIN { alt = id; gsub(/-/, "_", alt) } index($2, p) == 1 && (index($2, id) || index($2, alt)) { print }' "$W/cases")
          [ -n "$rc" ] && break
        done
      fi
      [ -n "$rc" ] && printf '%s\n' "$rc" | sed "s/^/$id	/"
    done
  }
  # v0.9.7.2 (3.5, R8): catch-up's rows — ungraded, passing at HEAD on the receipts published by the close, and every
  # case in the close's evidence passed; the others are named and left for a run, a claim and a grade
  if [ -n "$WCU" ]; then
    printf '%s\n' "$CUU" | awk 'NF { print $1 "\t-\t" }' > "$W/cumap"
    sh checks/evidence.sh rows --at HEAD --map "$W/cumap" --until "$CUA" > "$W/cust" 2>/dev/null || wrefuse 'checks/evidence.sh could not read the evidence'
    sh checks/evidence.sh rows --at HEAD --map "$W/cumap" > "$W/cunow" 2>/dev/null || wrefuse 'checks/evidence.sh could not read the evidence'
    for id in $CUU; do awk -F'|' -v r="$id" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x) } x == r { print; exit }' "$W/inv.ref"; done > "$W/curows"
    rowcases "$W/curows" > "$W/cuc"
    awk -F'\t' 'FILENAME == ARGV[1] { if ($2 == "pass") P[$1] = 1; next } FILENAME == ARGV[2] { if ($2 != "pass") delete P[$1]; next } { split($2, c, " "); n[$1]++; if (c[3] != "passed") bad[$1] = 1 } END { for (r in P) if (n[r] && !bad[r]) print r }' "$W/cust" "$W/cunow" "$W/cuc" | sort > "$W/cuok"
    CUX=$(printf '%s\n' "$CUU" | grep -vxF -f "$W/cuok" | paste -sd ' ' -)
    [ -s "$W/cuok" ] || wrefuse "no ungraded row of $WCU passes on its close's evidence now ($WRCPT): $CUX — stale or amended since, each goes through a run, a claim and a grade"
    WROWS=$(paste -sd, "$W/cuok")
    [ -z "$CUX" ] || echo "ViD brief write: catch-up leaves out $CUX — not passing on $WCU's close evidence now (stale, amended, red, or not run there): a run, a claim and a grade" >&2
  fi
  # the rows: --rows, or the claim's ids — its claimed and provisional row ids only; a claim line's reason never travels, a held row is never briefed
  : > "$W/prov"
  if [ -n "$WCLAIM" ]; then
    [ -f "$WCLAIM" ] || wrefuse "no such claim file: $WCLAIM"
    sed -n 's/^claim row=\([^ ]*\).*/\1/p' "$WCLAIM" > "$W/ids"
    sed -n 's/^provisional row=\([^ ]*\).*/\1/p' "$WCLAIM" > "$W/prov"
  else
    printf '%s\n' "$WROWS" | tr ', ' '\n\n' | grep -v '^$' > "$W/ids" || : > "$W/ids"
  fi
  awk '!s[$0]++' "$W/ids" > "$W/ids.u" && mv "$W/ids.u" "$W/ids"
  [ -s "$W/ids" ] || wrefuse 'no row to brief'
  rowline() { awk -F'|' -v r="$1" '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id) } id == r { print; exit }' "$2"; }
  PB=''; : > "$W/rows"
  for id in $(cat "$W/ids"); do
    case "$id" in ROW-*) l=$(rowline "$id" "$W/inv.ref") ;; *) l='' ;; esac
    if [ -z "$l" ] && [ "$WROLE" = test-author ] && [ "${id#ROW-}" != "$id" ]; then l=$(rowline "$id" "$W/inv.wt"); [ -n "$l" ] && PB="$PB${PB:+ }$id"; fi
    [ -n "$l" ] || wrefuse "unknown row id: $id — not a row of INVENTORY.md at HEAD (nor, for a test-author, of the working tree's)"
    printf '%s\n' "$l" >> "$W/rows"
  done
  # rehearsal R-2: a row only a deployed run credits (a journey, or a (process) row, when the harness declares
  # deployed-selector:) needs the brief's deployed selection — an inline receipt can never show it passing
  case "$WROLE" in builder|fixer)
    if [ -z "$WDSEL" ] && [ -f docker-compose.test.yml ] && awk '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1=="deployed-selector:" { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); if (v!="") f=1 } END { exit f?0:1 }' docker-compose.test.yml; then
      DEP=$(awk -F'|' '{ for (i = 1; i <= NF; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i) } $2 == "journey" || $4 == "(process)" { print $1 }' "$W/rows" | paste -sd ' ' -)
      [ -z "$DEP" ] || wrefuse "$DEP: only a deployed run credits it (a journey or a (process) row) — name its deployed selection (--deployed-selection)"
    fi ;;
  esac
  # the join ids: the briefed rows and every id in their derived-from
  awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); print id > (D "/rowids"); n = split($7, a, /[ ,]+/); for (i = 1; i <= n; i++) if (a[i] != "") print a[i] > (D "/dfids") }' D="$W" "$W/rows"
  [ -f "$W/dfids" ] || : > "$W/dfids"; sort -u -o "$W/dfids" "$W/dfids"
  cat "$W/rowids" "$W/dfids" | sort -u > "$W/joinids"
  # the named decisions must exist
  : > "$W/named"
  for d in $(printf '%s\n' "$WDEC" | tr ', ' '\n\n' | grep -v '^$' || true); do
    grep -qF -- "- **$d**" "$W/dec" || wrefuse "unknown decision id: $d (not in DECISIONS.md at HEAD)"
    printf '%s\n' "$d" >> "$W/named"
  done
  # the laws: four CLAUDE.md sections, whole, by heading
  : > "$W/laws"
  [ "$WROLE" = builder ] || for h in 'Placement rules' 'Ledger and docs laws' 'Import law' 'Law-change rule'; do
    awk -v h="## $h" 'on && /^## / { exit } !on && (index($0, h) == 1) && (length($0) == length(h) || substr($0, length(h) + 1, 1) ~ /[ (]/) { on = 1 } on { print }' "$W/law" > "$W/one"
    [ -s "$W/one" ] || wrefuse "CLAUDE.md at HEAD has no '## $h' section — a brief quotes the four law sections whole"
    awk '{ L[NR] = $0 } NF { last = NR } END { for (i = 1; i <= last; i++) print L[i] }' "$W/one" >> "$W/laws"; printf '\n' >> "$W/laws"
  done
  if [ "$WROLE" = fixer ] && [ -z "$WSTEP" ] && [ -f checks/plan.sh ]; then
    case "$(sh checks/plan.sh gate 2>/dev/null)" in 'on '*) wrefuse 'a fixer brief in a develop run names its plan step (--step)' ;; esac
  fi
  # section 2: the effective items the rows derive from; a test-author's new or amended working-tree item is quoted from there, pending-append:
  PA=''; : > "$W/items"
  if grep -q '^### REQ-' "$W/eff.ref" "$W/eff.wt" 2>/dev/null; then LEG=yes; else LEG=no; fi
  blk() { awk -v id="$1" '/^### REQ-[0-9]+/ { match($0, /REQ-[0-9]+/); on = (substr($0, RSTART, RLENGTH) == id); if (on) b = "" } on { b = b $0 "\n" } END { printf "%s", b }' "$2" | awk '{ L[NR] = $0 } NF { last = NR } END { for (i = 1; i <= last; i++) print L[i] }'; }
  for id in $(cat "$W/dfids"); do
    if [ "$LEG" = yes ]; then r=$(blk "$id" "$W/eff.ref"); w=$(blk "$id" "$W/eff.wt")
    else r=$(rowline "$id" "$W/eff.ref"); w=$(rowline "$id" "$W/eff.wt"); fi
    if [ "$WROLE" = test-author ] && [ -n "$w" ] && [ "$w" != "$r" ]; then PA="$PA${PA:+ }$id"; r=$w; fi
    [ -n "$r" ] || continue
    printf '%s\n' "$r" >> "$W/items"; [ "$LEG" = yes ] && printf '\n' >> "$W/items"
    printf '%s\n' "$id" >> "$W/itemids"
  done
  [ -f "$W/itemids" ] || : > "$W/itemids"
  # v0.9.8 (3.3, R5): section 15, the authority bundle's rest — sections 2 and 3 already quote the arms and the
  # decisions; here the owner answers the quoted items' source: cites (each answer's latest row, AMENDED kept), and
  # the design states the rows' markers cite (the files under design/ at HEAD holding the marker). A test-author's
  # answer new or changed in the working tree is quoted from there, listed pending-append:.
  : > "$W/s15a"; : > "$W/s15d"
  case "$WROLE" in test-author|grader)
    ansrows() { awk '/^```/ { if (b == "") { b = substr($0, 4); sub(/[ \t].*/, "", b); if (b == "") b = "-" } else b = ""; next }
        b == "vid-prd-answers" && !/^[ \t]*#/ { id = $0; sub(/[ \t]*\|.*/, "", id); sub(/[ \t]+AMENDED$/, "", id); if (id ~ /^A-[0-9]+$/) L[id] = $0 }
        END { for (k in L) print k "\t" L[k] }' "$1"; }
    ansrows "$W/prd.ref" > "$W/ans.ref"; if [ -f PRD.md ]; then ansrows PRD.md > "$W/ans.wt"; else : > "$W/ans.wt"; fi
    awk -F'|' '{ for (i = 2; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (index(f, "source:") == 1) while (match(f, /A-[0-9]+/)) { print substr(f, RSTART, RLENGTH); f = substr(f, RSTART + RLENGTH) } } }' "$W/items" | awk '!s[$0]++' > "$W/aids"
    for _a in $(cat "$W/aids"); do
      _r=$(awk -F'\t' -v a="$_a" '$1 == a { print $2 }' "$W/ans.ref"); _w=$(awk -F'\t' -v a="$_a" '$1 == a { print $2 }' "$W/ans.wt")
      if [ "$WROLE" = test-author ] && [ -n "$_w" ] && [ "$_w" != "$_r" ]; then PA="$PA${PA:+ }$_a"; _r=$_w; fi
      [ -n "$_r" ] && printf '%s\n' "$_r" >> "$W/s15a"
    done
    awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); m = $5; gsub(/^[ \t]+|[ \t]+$/, "", m); n = split(m, a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "" && a[k] != "n/a" && a[k] != "-") print id "\t" a[k] }' "$W/rows" |
      while IFS=$TAB read -r _id _m; do _mf=$(mfiles HEAD "$_m"); printf '%s %s %s\n' "$_id" "$_m" "${_mf:-none}"; done > "$W/s15d"
    # v0.9.8.1 (R19): the component canvases each briefed screen uses, apart from its marker lines — under the
    # per-screen layout the files design/screens/index.json lists for the screen, in a legacy pack the whole
    # components canvas (the files holding a C00 marker)
    : > "$W/s15c"
    _scs=$(awk '{ m = $2; if (index(m, "/") > 1) print substr(m, 1, index(m, "/") - 1) }' "$W/s15d" | grep -vx C00 | sort -u)
    if [ -n "$_scs" ]; then
      _dix=''; [ -f checks/design-join.sh ] && [ -f design/screens/index.json ] && _dix=$(sh checks/design-join.sh --index design/screens 2>/dev/null || true)
      if printf '%s\n' "$_dix" | grep -qx 'layout per-screen'; then
        for _sc in $_scs; do printf 'components %s %s\n' "$_sc" "$(printf '%s\n' "$_dix" | awk -v s="$_sc" '$1 == "component" && $2 == s { sub(/^component [^ ]+ /, ""); print "design/screens/" $0 }' | paste -sd ',' - | sed 's/^$/none/')"; done > "$W/s15c"
      else
        _c00=$(git grep -l -E '@screen[[:space:]]+C00([^A-Za-z0-9_-]|$)' HEAD -- design/ 2>/dev/null | sed 's/^HEAD://' | paste -sd ',' - | sed 's/^$/none/')
        for _sc in $_scs; do printf 'components %s %s\n' "$_sc" "$_c00"; done > "$W/s15c"
      fi
    fi
    # v0.9.8.1 (R19): the rows' own test files (the first token of each INVENTORY test field, present at HEAD) and the
    # declared measure module — never every file under tests/
    awk -F'|' '{ t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t); sub(/[ \t].*/, "", t); if (t != "" && t !~ /^owed:/) print t }' "$W/rows" | awk '!s[$0]++' |
      while IFS= read -r _tf; do git cat-file -e "HEAD:$_tf" 2>/dev/null && printf '%s\n' "$_tf"; done > "$W/s8t" || true
    git ls-tree --name-only HEAD tests/invariants/ 2>/dev/null | grep '^tests/invariants/measure\.' > "$W/s8m" || true ;;
  esac
  # v0.9.7.1 (3.2e, R2): a builder's rule rows come from the item ids before the decision filter, and their RULE ids join it
  : > "$W/rules"
  if [ "$WROLE" = builder ]; then
    rulerows "$W/inv.ref" "$W/itemids" > "$W/rules"
    awk -F'|' '{ x = $2; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^RULE-[0-9]+$/) print x }' "$W/rules" >> "$W/joinids"
  fi
  # section 3: the join (every field, why: included) plus the named ids; a grader gets each one's rule, the line up to ' | why:'
  # v0.9.7.0.7 (3.2, R5): a builder's — the safe rule, narrowed to the step's screens: the screen codes of every row, and of the briefed rows
  awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } tr($1) ~ /^ROW-/ { n = split(tr($5), a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "n/a" && index(a[k], "/") > 1) print substr(a[k], 1, index(a[k], "/") - 1) }' "$W/inv.ref" | sort -u > "$W/scall"
  awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } { n = split(tr($5), a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "n/a" && index(a[k], "/") > 1) print substr(a[k], 1, index(a[k], "/") - 1) }' "$W/rows" | sort -u > "$W/scbrief"
  # v0.9.7.3 (3.2, R2): the DIF ids the briefed rows' divergence: fields name
  awk -F'|' '{ for (i = 8; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (f ~ /^divergence:/) { sub(/^divergence:[ \t]*/, "", f); n = split(f, a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] ~ /^DIF-[0-9]+$/) print a[k] } } }' "$W/rows" | sort -u > "$W/difbrief"
  awk -v jf="$W/joinids" -v nf="$W/named" -v role="$WROLE" -v saf="$W/scall" -v sbf="$W/scbrief" -v dbf="$W/difbrief" "$WHOLE"'
    function anyid(s,   o, q, x, y) { q = s; o = 0; while (match(q, /(ROW|REQ|RULE)-[0-9]+/)) { x = (o + RSTART > 1) ? substr(s, o + RSTART - 1, 1) : ""; y = substr(s, o + RSTART + RLENGTH, 1); if (x !~ /[A-Za-z0-9_-]/ && y !~ /[A-Za-z0-9_-]/) return 1; o += RSTART; q = substr(s, o + 1) } return 0 }
    # label(): the line'"'"'s label (v0.9.7.3 R1) — "project", the applies-to items into AP (count in nap), or ""
    function label(   n, k, f, t, m, a, i2) { split("", AP); nap = 0; n = split($0, t, "|")
      for (k = 2; k <= n; k++) { f = t[k]; gsub(/^[ \t]+|[ \t]+$/, "", f)
        if (f ~ /^scope:[ \t]*project$/) return "project"
        if (f ~ /^applies-to:/) { sub(/^applies-to:[ \t]*/, "", f); m = split(f, a, /[ ,]+/); for (i2 = 1; i2 <= m; i2++) if (a[i2] != "") AP[++nap] = a[i2]; return "applies" } }
      return "" }
    BEGIN { while ((getline l < jf) > 0) { J[++nj] = l; JS[l] = 1 } while ((getline l < nf) > 0) N["**" l "**"] = 1
      while ((getline l < saf) > 0) SA[++ns] = l; while ((getline l < sbf) > 0) SB[l] = 1; while ((getline l < dbf) > 0) DB[l] = 1 }
    { hit = 0; match($0, /\*\*D-[0-9]+\*\*/); if (substr($0, RSTART, RLENGTH) in N) hit = 1
      for (i = 1; !hit && i <= nj; i++) if (has($0, J[i])) hit = 1
      lab = label()
      # a label adds a match: its items meet the briefed rows, their derived-from ids, the RULE join, their screen codes or DIF ids
      for (i = 1; !hit && i <= nap; i++) if ((AP[i] in JS) || (AP[i] in SB) || (AP[i] in DB)) hit = 1
      # the safe rule, a builder'"'"'s: an unlabelled line citing no id, or a scope: project line — narrowed to the step'"'"'s screens
      if (!hit && role == "builder" && (lab == "project" || (lab == "" && !anyid($0)))) { named = 0; mine = 0; for (i = 1; i <= ns; i++) if (has($0, SA[i])) { named = 1; if (SA[i] in SB) mine = 1 } hit = (!named || mine) }
      if (!hit) next
      if (role == "grader") { p = index($0, " | why:"); if (p) { print substr($0, 1, p - 1); next } }
      print }' "$W/dec" > "$W/decs"
  # a grader's extras: owed siblings, flagged tests, the receipt's per-case status
  if [ "$WROLE" = grader ]; then
    awk -F'|' -v rf="$W/rowids" -v df="$W/dfids" "$WHOLE"'
      function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      function owed(  i) { for (i = 2; i <= NF; i++) if (tr($i) ~ /^owed:/) return 1; return 0 }
      function withheld(  i, f, out) { for (i = 1; i <= NF; i++) { f = $i; if (index(tr(f), "owed: reverted —") == 1) { sub(/owed: reverted —.*$/, "owed: reverted — (detail withheld from graders)", f); if (i < NF) f = f " " } out = out (i > 1 ? "|" : "") f } return out }
      BEGIN { while ((getline l < rf) > 0) R[l] = 1; while ((getline l < df) > 0) { D[l] = 1; nd++ } }
      { id = tr($1); hit = 0
        if (id ~ /^ROW-/ && !(id in R) && tr($8) ~ /^owed:/) { n = split(tr($7), a, /[ ,]+/); for (i = 1; i <= n; i++) if (a[i] in D) hit = 1 }
        else if (id == "hostility" && owed()) { for (i = 2; i <= NF; i++) { f = tr($i); if (index(f, "protects:") == 1) { n = split(substr(f, 10), a, /[ ,]+/); for (k = 1; k <= n; k++) if ((a[k] in R) || (a[k] in D)) hit = 1 } } }
        if (hit) print withheld() }' "$W/inv.ref" > "$W/owed"
    awk -F'|' '{ t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t); sub(/ .*/, "", t); if (t ~ /^tests\//) print t }' "$W/rows" | sort -u > "$W/paths"
    : > "$W/flagged"
    if [ -f checks/census.sh ]; then
      VID_COURT_EVENT=off sh checks/census.sh --report 2>/dev/null | grep -E '^(VAC|REND|STR) ' > "$W/census" || : > "$W/census"
      awk -v rf="$W/rowids" -v pf="$W/paths" "$WHOLE"'
        BEGIN { while ((getline l < rf) > 0) R[++nr] = l; while ((getline l < pf) > 0) P[++np] = l }
        { for (i = 1; i <= nr; i++) if (has($0, R[i])) { print; next } for (i = 1; i <= np; i++) if (index($0, P[i])) { print; next } }' "$W/census" > "$W/flagged"
    fi
    # the cases of each briefed row (rowcases, above; a catch-up's were joined already)
    if [ -n "$WCU" ]; then awk -F'\t' 'NR == FNR { R[$1] = 1; next } ($1 in R)' "$W/cuok" "$W/cuc"; else rowcases "$W/rows"; fi | cut -f2- | awk '!s[$0]++' > "$W/rowcases"
    # v0.9.8 (3.4, R4): the fault proof's scope among the briefed rows — protected (checks/inventory.sh protected and the
    # plan's protected: line), journeys, rows repaired after a weak test (a BREACHED class=test verdict on record), and
    # one other row in ten, drawn
    # by the cksum of the row id and this commit (the same draw every time)
    # v0.9.8 (3.5, R9): fresh grading data — the files under tests/ whose Provenance: header says `regression` (a
    # grader's case once used to fix the product) and that serve a briefed row: naming it (ROW-n or ROW_n, whole) or
    # being its golden: fixture
    : > "$W/regr"
    for _rf in $(git grep -l -E '^[^A-Za-z0-9]*Provenance:[[:space:]]*regression' "$QH" -- tests/ 2>/dev/null | sed "s/^$QH://"); do
      git show "$QH:$_rf" > "$W/rgf" 2>/dev/null || continue
      _rr=$(for _id in $(cat "$W/rowids"); do
          if [ -n "$(awk -v a="$_id" "$ROWLINES" "$W/rgf")" ] || awk -F'|' -v r="$_id" -v f="$_rf" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x) } x == r { for (i = 2; i <= NF; i++) { y = $i; gsub(/^[ \t]+|[ \t]+$/, "", y); if (y == "golden: " f) g = 1 } } END { exit g ? 0 : 1 }' "$W/rows"; then printf '%s ' "$_id"; fi
        done | sed 's/ $//')
      [ -n "$_rr" ] && printf '%s — %s\n' "$_rf" "$_rr" >> "$W/regr"
    done
    : > "$W/pscope"; : > "$W/pprot"
    [ -f checks/inventory.sh ] && { sh checks/inventory.sh protected 2>/dev/null | awk '$1 == "protected" && $2 ~ /^ROW-/ { print $2 }' >> "$W/pprot"; } || true
    [ -f checks/plan.sh ] && { sh checks/plan.sh parse 2>/dev/null | awk -F'\t' '$1 == "prot" { print $2 }' >> "$W/pprot"; } || true
    { [ -f .vid/metrics-events ] && awk 'function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
        $1 == "verdict" && kv("result") == "BREACHED" && kv("class") == "test" { print "W\t" kv("row") }' .vid/metrics-events; } > "$W/pev" || : > "$W/pev"
    awk -F'|' '{ id = $1; k = $2; gsub(/^[ \t]+|[ \t]+$/, "", id); gsub(/^[ \t]+|[ \t]+$/, "", k); print id "\t" k }' "$W/rows" | while IFS=$TAB read -r _r _k; do
      if grep -qxF -- "$_r" "$W/pprot"; then echo "$_r protected"
      elif [ "$_k" = journey ]; then echo "$_r journey"
      elif awk -F'\t' -v r="$_r" '$1 == "W" && $2 == r { f = 1 } END { exit f ? 0 : 1 }' "$W/pev"; then echo "$_r repaired"
      elif [ $(( $(printf '%s %s' "$_r" "$QH" | cksum | cut -d' ' -f1) % 10 )) -eq 0 ]; then echo "$_r sample"; fi
    done > "$W/pscope"
  fi
  # section 7: a fixer gets each row's attempt record whole; a test-author each row's latest class=test block; a grader never
  : > "$W/s7"
  if [ "$WROLE" != grader ]; then
    for id in $(cat "$W/rowids"); do
      f=.vid/verdicts/$id.md; [ -f "$f" ] || continue
      if [ "$WROLE" = fixer ] || [ "$WROLE" = builder ]; then cat "$f" >> "$W/s7"; printf '\n' >> "$W/s7"
      else
        awk 'FNR == 1 { hd = 0 } /^## / { hd = 1 } { L[FNR] = $0 } END {
            n = FNR; s = 0; k = 0
            for (i = 1; i <= n; i++) { st = hd ? (L[i] ~ /^## /) : (L[i] != "" && (i == 1 || L[i - 1] == "")); if (st) { k++; B[k] = i } }
            for (j = k; j >= 1; j--) { e = (j < k) ? B[j + 1] - 1 : n; if (!hd) { e = B[j]; while (e < n && L[e + 1] != "") e++ } t = ""; for (i = B[j]; i <= e; i++) t = t L[i] "\n"; if (index(t, "class=test")) { printf "%s", t; exit } } }' "$f" \
          | awk '{ L[NR] = $0 } NF { last = NR } END { for (i = 1; i <= last; i++) print L[i] }' > "$W/one"
        [ -s "$W/one" ] && { cat "$W/one"; printf '\n'; } >> "$W/s7"
      fi
    done
  fi
  # v0.9.8 (3.5, R8; amendment 3): the lessons and the siblings. Section 17 (a test-author's): each entry of
  # .vid/test-lessons.md — `## L-<n> …`, then `helpers:` and `rules:` lines, then bad, why and good — whose rules name a
  # briefed row or an id it derives from, or whose helpers name a briefed row's test file, quoted whole; never the whole
  # file. Section 18 (a test-author's): for each briefed row whose latest verdict is BREACHED class=test — a grader's
  # test-class verdict or a conclusive proof that failed (its verdict carries proof=), repaired in this pass — its
  # siblings: every other row sharing an item it derives from (by=rule <id>) — never a row only because it shares the
  # test file (one file can hold a hundred rows' tests).
  : > "$W/s17"; : > "$W/s18"
  case "$WROLE" in test-author)
    awk -F'|' '{ id = $1; t = $8; d = $7; gsub(/^[ \t]+|[ \t]+$/, "", id); gsub(/^[ \t]+|[ \t]+$/, "", t); sub(/[ \t].*/, "", t)
        print "R\t" id; if (t ~ /^tests\//) print "H\t" t; n = split(d, a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "") print "R\t" a[k] }' "$W/rows" > "$W/lkeys"
    if [ -f .vid/test-lessons.md ]; then
      awk -F'\t' 'FILENAME == ARGV[1] { K[$1, $2] = 1; next }
        function flush(   n, a, k, hit) { if (b == "") return; hit = 0
            n = split(hr, a, /[ ,]+/); for (k = 1; k <= n; k++) if (("H", a[k]) in K) hit = 1
            n = split(rr, a, /[ ,]+/); for (k = 1; k <= n; k++) if (("R", a[k]) in K) hit = 1
            if (hit) { sub(/\n+$/, "\n", b); printf "%s\n", b } b = ""; hr = ""; rr = "" }
        /^## L-[0-9]+/ { flush(); b = $0 "\n"; next }
        b != "" && /^## / { flush(); next }
        b != "" { b = b $0 "\n"; if ($0 ~ /^helpers:/) { hr = $0; sub(/^helpers:[ \t]*/, "", hr) } if ($0 ~ /^rules:/) { rr = $0; sub(/^rules:[ \t]*/, "", rr) } }
        END { flush() }' "$W/lkeys" .vid/test-lessons.md > "$W/s17"
    fi ;;
  esac
  if [ "$WROLE" = test-author ] && [ -f .vid/metrics-events ]; then
    awk '$1 == "verdict" { r = ""; x = ""; c = ""; for (i = 2; i <= NF; i++) { if (index($i, "row=") == 1) r = substr($i, 5); if (index($i, "result=") == 1) x = substr($i, 8); if (index($i, "class=") == 1) c = substr($i, 7) } if (r != "") L[r] = x " " c }
      $1 == "amended" { for (i = 2; i <= NF; i++) if (index($i, "row=") == 1) delete L[substr($i, 5)] }
      END { for (r in L) if (L[r] == "BREACHED test") print r }' .vid/metrics-events | grep -xF -f "$W/rowids" > "$W/weak" || : > "$W/weak"
    if [ -s "$W/weak" ]; then
      awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); if (id !~ /^ROW-/) next; t = $8; gsub(/^[ \t]+|[ \t]+$/, "", t); sub(/[ \t].*/, "", t); d = $7; gsub(/^[ \t]+|[ \t]+$/, "", d); print id "\t" t "\t" d }' "$W/inv.ref" > "$W/allrows"
      for _w in $(cat "$W/weak"); do
        awk -F'\t' -v w="$_w" -v bf="$W/rowids" 'BEGIN { while ((getline l < bf) > 0) B[l] = 1 }
          { T[$1] = $2; D[$1] = $3; O[++n] = $1 }
          END { nd = split(D[w], WD, /[ ,]+/)
            for (i = 1; i <= n; i++) { r = O[i]; if (r == w || (r in B)) continue; why = ""
              if (why == "") { m = split(D[r], RD, /[ ,]+/); for (k = 1; k <= nd && why == ""; k++) for (j = 1; j <= m; j++) if (WD[k] != "" && WD[k] == RD[j]) { why = "by=rule " WD[k]; break } }
              if (why != "") print r " " why " (of " w ")" } }' "$W/allrows" >> "$W/s18"
      done
    fi
  fi
  # v0.9.7.0.7 (3.2): a builder's sections 9–11 — the test locations, the step, the rules
  NONE=0
  if [ "$WROLE" = builder ]; then
    locs "$W/rows" "$QH" > "$W/s9"; NONE=$(grep -c ' none$' "$W/s9")
    steplines "$PF" "$WSTEP" > "$W/steps"
    git show "HEAD:ARCHITECTURE.md" > "$W/arch" 2>/dev/null || : > "$W/arch"
    archrows "$W/arch" "$(sed -n 1p "$W/steps")" > "$W/mods"
    # v0.9.7.1 (3.2d, f): and the rows of every module the step may call, after its own; more than 40 rows keep 40
    callrows "$W/arch" "$(sed -n 1p "$W/steps")" > "$W/calls"
    if [ -s "$W/mods" ] || [ -s "$W/calls" ]; then
      { [ -s "$W/mods" ] && sed -n '1,2p' "$W/mods" || awk -F'|' '{ for (k = 2; k < NF; k++) { x = $k; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x == "Module") { print; getline; print; exit } } }' "$W/arch"; } > "$W/mhead"
      { sed '1,2d' "$W/mods" 2>/dev/null; grep -vxF -f "$W/mods" "$W/calls" 2>/dev/null || cat "$W/calls"; } | awk '!s[$0]++' > "$W/mrows"
      _mn=$(grep -c . "$W/mrows" || true)
      { cat "$W/mhead"; head -n 40 "$W/mrows"; [ "$_mn" -gt 40 ] && printf '(+%d rows: ARCHITECTURE.md)\n' $((_mn - 40)); } > "$W/mods"
    fi
  fi
  # v0.9.7.1 (3.2b, R2): a builder's and a fixer's section 5 history — each row's cases, each case's newest result
  : > "$W/hist"
  if { [ "$WROLE" = builder ] || [ "$WROLE" = fixer ]; }; then
    if [ -f checks/evidence.sh ]; then
      awk '{ print $0 "\t-\t" }' "$W/rowids" > "$W/hmap"
      sh checks/evidence.sh rows --at HEAD --map "$W/hmap" --history > "$W/hraw" 2>/dev/null || : > "$W/hraw"
      awk -F'\t' 'NF >= 5 && ($3 == "failed" || $3 == "error") { print $4 }' "$W/hraw" | sort -u > "$W/hred"
      : > "$W/hmsg"
      while IFS= read -r _r; do
        sh checks/evidence.sh red "$_r" 2>/dev/null < /dev/null | awk -v r="$_r" '/^group / { m = ""; if (match($0, /message="/)) { m = substr($0, RSTART + 9); sub(/"$/, "", m) } next }
          /^    / { c = substr($0, 5); w = ""; p = index(c, " at "); if (p) { w = substr(c, p + 4); c = substr(c, 1, p - 1) } print r "\t" c "\t" m "\t" w }' >> "$W/hmsg"
      done < "$W/hred"
      # a report may name a case by its class (a.b.c::name) where .cases names it by path (a/b/c.ext::name): both are
      # read with the part before `::` stripped of its extension and `/` as `.`
      awk -F'\t' -v mf="$W/hmsg" 'function nk(c,   p, l) { p = index(c, "::"); if (!p) return c; l = substr(c, 1, p - 1); if (index(l, "/")) { sub(/\.[A-Za-z0-9]+$/, "", l); gsub(/\//, ".", l) }; return l substr(c, p) }
        BEGIN { while ((getline l < mf) > 0) { split(l, a, "\t"); M[a[1] "\t" nk(a[2])] = a[3]; X[a[1] "\t" nk(a[2])] = a[4] } }
        NF >= 5 { o = $1 " " $2 " " $3 " " $4 " tree=" substr($5, 1, 12); k = $4 "\t" nk($2)
          if ($3 == "failed" || $3 == "error") { if (M[k] != "") o = o " — " M[k]; if (X[k] != "") o = o " at " X[k] } print o; next }
        $2 == "-" { print $1 " not run"; next }
        { print $1 " " $2 ": " $3 }' "$W/hraw" | awk -v mk='… (receipt)' '{ if (length($0) > 300) $0 = substr($0, 1, 300 - length(mk)) mk; print }' > "$W/hist"
    else echo 'none: checks/evidence.sh is not here' > "$W/hist"; fi
    [ -s "$W/hist" ] || echo none > "$W/hist"
  fi
  # the header: role, slice, step for a builder or fixer, quoted-at, and the role's cells of develop's role table, verbatim
  case "$WROLE" in grader) RC='grader (slice close)' ;; *) RC=$WROLE ;; esac
  CELLS=$(sed -n '/^## Spawned roles/,/^## /p' "$DEVSK" | awk -F'|' -v r="$RC" '{ c = $2; gsub(/^[ \t]+|[ \t]+$/, "", c) } c == r { a = $3; b = $4; gsub(/^[ \t]+|[ \t]+$/, "", a); gsub(/^[ \t]+|[ \t]+$/, "", b); print a "\t" b; exit }')
  [ -n "$CELLS" ] || wrefuse "develop's role table has no row '$RC' ($DEVSK)"
  D=.vid/briefs/$WSLICE; mkdir -p "$D"
  N=$(ls "$D" 2>/dev/null | sed -n "s/^$WROLE-\([0-9][0-9]*\)\.md$/\1/p" | sort -n | tail -n 1); N=$(( ${N:-0} + 1 ))
  OUT=$D/$WROLE-$N.md
  # v0.9.7.1 (3.2a, R2): the attempt id, its branch and the return file's absolute path
  TRY=''; [ "$WROLE" = builder ] || [ "$WROLE" = fixer ] && TRY=$WSLICE-$WROLE-$N
  {
    printf 'role: %s    slice: %s' "$WROLE" "$WSLICE"; { [ "$WROLE" = fixer ] || [ "$WROLE" = builder ]; } && [ -n "$WSTEP" ] && printf '    step: %s' "$WSTEP"; printf '\n'
    printf 'quoted-at: %s\n' "$QH"
    printf 'receives: %s    must not receive: %s\n' "${CELLS%%"$TAB"*}" "${CELLS#*"$TAB"}"
    { [ "$WROLE" = fixer ] || [ "$WROLE" = builder ]; } && printf 'skill: vid-build\n'
    if [ -n "$TRY" ]; then printf 'try: %s\nbranch: vid/%s\nreturn: %s/%s\n' "$TRY" "$TRY" "$(pwd -P)" "$D/$WROLE-$N.return.md"; fi
    [ -n "$PB" ] && printf 'pending-birth: %s\n' "$PB"
    [ -n "$PA" ] && printf 'pending-append: %s\n' "$PA"
  } > "$W/head"
  {
    printf '\n'
    case "$WROLE" in
      test-author) printf '%s\n\n' "$HDR" ;;
      grader)
        cat "$GPASS"; printf '\n'
        if [ -n "$RB" ]; then printf 'receipts: close batch %s — %s\n\n%s\n\n' "$RB" "$(paste -sd '|' "$W/cons" | sed 's/|/ · /g')" "$EXCLB"
        else printf 'receipt: %s%s\n\n%s\n\n' "$RP" "${RT:+ · $RT}" "$EXCL"; fi
        printf '### The claim\n\n'
        if [ -n "$WCLAIM" ]; then printf 'claimed: %s rows — %s\n' "$(grep -c . "$W/ids")" "$(tr '\n' ' ' < "$W/ids" | sed 's/ $//')"
          printf 'provisional: %s\n\n' "$( [ -s "$W/prov" ] && tr '\n' ' ' < "$W/prov" | sed 's/ $//' || echo none)"
        elif [ -n "$WCU" ]; then printf 'catch-up of step %s from its close (%s): %s rows ungraded at the close, passing on its evidence now — %s\n\n' "$WCU" "$WRCPT" "$(grep -c . "$W/ids")" "$(tr '\n' ' ' < "$W/ids" | sed 's/ $//')"
        else printf 'none — the rows were named (--rows)\n\n'; fi
        printf '### Owed siblings\n\n'; [ -s "$W/owed" ] && cat "$W/owed" || echo none; printf '\n'
        printf '### Flagged tests\n\n'; [ -s "$W/flagged" ] && cat "$W/flagged" || echo none; printf '\n'
        printf "### The receipt%s per-case status\n\n" "$([ -n "$RB" ] && echo "s'" || echo "'s")"; [ -s "$W/rowcases" ] && cat "$W/rowcases" || echo none; printf '\n'
        printf '### GRADING-CHECKLIST.md\n\n'; git show "HEAD:GRADING-CHECKLIST.md" 2>/dev/null || echo "absent at $QH"; printf '\n'
        # v0.9.8 (3.5, R9): the regression cases — never grading evidence; fresh cases asked for instead
        printf '### Regression cases\n\n'
        if [ -s "$W/regr" ]; then printf 'These fixtures hold cases a grader found and the product was fixed against (their Provenance: says regression). They stay as regression tests; they are no evidence for your verdict. For the rows each names, grade on fresh cases you construct:\n\n'; cat "$W/regr"
        else echo none; fi
        printf '\n'
        # v0.9.8 (3.4, R4): the rows whose fault the grader names, and where its patches go
        FD=.vid/briefs/$WSLICE/grader-$N.faults
        printf '### Fault proof\n\n'
        if [ -s "$W/pscope" ]; then
          printf 'For each row below, also name its fault: the smallest change to the product, against the commit this brief quotes, that makes exactly that row'"'"'s Fail-if true, written as a patch (git diff, paths from the repository root) at %s/<ROW-id>.patch — the one file you write under .vid/ — and one return line:\n\n    fault: ROW-<id> | target=<case id> | control=<case id> | patch=%s/<ROW-id>.patch\n\ntarget and control as the row'"'"'s test argument names them (its cases: line). You run nothing: the run manager proves it.\n\n' "$FD" "$FD"
          cat "$W/pscope"; mkdir -p "$FD"
        else echo 'none in scope'; fi
        printf '\n' ;;
    esac
    printf '## 1 rows\n\n'; cat "$W/rows"; printf '\n'
    printf '## 2 items\n\n'; cat "$W/items"; printf '\n'
    printf '## 3 decisions\n\n'; cat "$W/decs"; printf '\n'
    [ "$WROLE" = builder ] || { printf '## 4 laws\n\n'; cat "$W/laws"; }
    _rs="${RP:-none named}${RT:+ · $RT}"; [ -n "$RB" ] && _rs="close batch $RB ($(grep -c . "$W/cons") receipts)"
    printf '## 5 start and receipt\n\nstart: %s    receipt: %s\n\n' "$QH" "$_rs"
    [ -n "$TRY" ] && { printf 'history: results on earlier trees; not evidence for this brief; run your rows first\n'; cat "$W/hist"; printf '\n'; }
    printf '## 6 test requests\n\n'
    case "$WROLE" in
      grader) printf 'Graders request nothing.\n\n' ;;
      fixer|builder) printf 'sh checks/test.sh request --type iterate --role %s --rows %s --try %s --why "<fill in>" -- %s%s\nsh checks/test.sh wait <ticket>\n\n' "$WROLE" "$(paste -sd, "$W/rowids")" "$TRY" "$WSEL" "${WDSEL:+ --deployed-selection $WDSEL}" ;;
      test-author) printf 'sh checks/test.sh request --type prove-red --role test-author --rows %s --why "<one line>" -- <selection>\nsh checks/test.sh wait <ticket>\n\n' "$(paste -sd, "$W/rowids")" ;;
    esac
    if [ "$WROLE" = fixer ] || [ "$WROLE" = builder ] || { [ "$WROLE" = test-author ] && [ -s "$W/s7" ]; }; then printf '## 7 attempt record\n\n'; cat "$W/s7"; fi
    printf '## 8 further reading (optional)\n\n'
    for f in CLAUDE.md PRD.md BASELINE.md ARCHITECTURE.md DECISIONS.md INVENTORY.md GRADING-CHECKLIST.md; do git cat-file -e "HEAD:$f" 2>/dev/null && printf '%s\n' "$f"; done
    if [ "$WROLE" = test-author ]; then
      printf '\nthe pass: %s\nthe skill: %s\n\nthe harness:\n' "$TPASS" "$TSKILL"
      git ls-tree --name-only HEAD tests/invariants/ 2>/dev/null | grep '^tests/invariants/harness\.' || echo none
      printf '\nthe files of the rows briefed (v0.9.8.1 R19; a new file is named by the runner'"'"'s convention):\n'; [ -s "$W/s8t" ] && cat "$W/s8t" || echo none
      printf '\nthe measure module:\n'; [ -s "$W/s8m" ] && cat "$W/s8m" || echo none
      printf '\nthe route table (checks/extractors/routes.sh):\n'
      if [ -f checks/extractors/routes.sh ]; then sh checks/extractors/routes.sh 2>/dev/null || true; else echo none; fi
      printf '\n'; awk '/^\*\*The boundary rule \(R6\), verbatim:\*\*/ { on = 1 } on && NF == 0 { exit } on { print }' "$TSKILL"
    fi
    if [ "$WROLE" = grader ]; then   # v0.9.8.1 (R19): the rows' own files only
      printf '\nthe files of the rows briefed:\n'; [ -s "$W/s8t" ] && cat "$W/s8t" || echo none
      printf '\nthe measure module:\n'; [ -s "$W/s8m" ] && cat "$W/s8m" || echo none
    fi
    if [ "$WROLE" = builder ]; then
      printf '\nthe harness:\n'; git ls-tree --name-only HEAD tests/invariants/ 2>/dev/null | grep '^tests/invariants/harness\.' || echo none
      printf '\nthe canvases:\n'; git ls-tree -r --name-only HEAD -- design/screens 2>/dev/null | grep . || echo none
      printf '\n## 9 test locations\n\n'; cat "$W/s9"
      printf '\n## 10 the step\n\nplan: %s\n\n' "$PH"; cat "$W/steps"
      [ -s "$W/mods" ] && { printf '\n'; cat "$W/mods"; }
      printf '\n## 11 rules\n\n'; [ -s "$W/rules" ] && cat "$W/rules"
    fi
    [ -n "$WNOTES" ] && { printf '\n## 12 notes\n\n'; cat "$WNOTES"; }
    # v0.9.7.1 (3.4c, R4): the continuation the successor restores after its checkout
    if [ -n "$WCONT" ]; then
      printf '\n## 14 continuation\n\npackage: %s    manifest: %s\nreport: %s\nlaw: %s\n' "$WCONT" "$(git hash-object "$WCONT/manifest")" "$(sed -n 's/^report=//p' "$WCONT/manifest" | head -n 1)" "${WLAW:-none}"
    fi
    case "$WROLE" in test-author|grader)
      printf '\n## 15 authority\n\nanswers (the items'"'"' source:, followed):\n'; [ -s "$W/s15a" ] && cat "$W/s15a" || echo none
      printf '\ndesign states (the rows'"'"' markers, and the files under design/ holding each):\n'; [ -s "$W/s15d" ] && cat "$W/s15d" || echo none
      [ -s "$W/s15c" ] && { printf '\ncomponent canvases (each screen'"'"'s, apart from its markers):\n'; cat "$W/s15c"; } ;;
    esac
    case "$WROLE" in test-author)
      [ -s "$W/s17" ] && { printf '\n## 17 lessons\n\nthe entries of .vid/test-lessons.md matching these rows'"'"' rules and helpers — earlier weak tests: bad, why, good:\n\n'; cat "$W/s17"; } ;;
    esac
    if [ -s "$W/s18" ]; then printf '\n## 18 siblings\n\na confirmed weak test is repaired with its siblings, in this pass — the rows sharing an item it derives from; check each the same way, and any other test with the same data pattern:\n\n'; cat "$W/s18"; fi
    if [ "$WUP" = yes ]; then
      printf '\n## 13 harness upgrade\n\nharness: docker-compose.test.yml    hash: %s    rules: %s    target: 2\n' "$UHH" "${UHR:-none}"
      printf 'template: %s\ntimeline: %s\n' "$UTPL" "${UTL:-none}"
      printf "\nthe last %s gated passes' overhead, oldest first:\n" "$(grep -c . "$W/ovh" || true)"; [ -s "$W/ovh" ] && cat "$W/ovh" || echo none
      printf "\nthe last %s passes' container states (started-at, kept-healthy-at), newest first:\n" "$(grep -c ':$' "$W/svcs" || true)"; [ -s "$W/svcs" ] && cat "$W/svcs" || echo none
      printf "\nthe slowest %s cases of the run's history, seconds first (rule 4's limit):\n" "$(grep -c . "$W/slow" || true)"; [ -s "$W/slow" ] && cat "$W/slow" || echo none
      printf "\nthe rules, in the template's words:\n"; cat "$W/rules3"
      printf '\nthe harness file at %s, whole:\n\n' "$QH"; sed 's/^/    /' "$W/harness"
    fi
  } > "$W/body"
  HASH=$(cat "$W/head" "$W/body" | git hash-object --stdin)
  { cat "$W/head"; printf 'written: brief.sh write %s\n' "$HASH"; cat "$W/body"; } > "$OUT"
  echo "ViD brief write: $OUT"
  [ "$NONE" -gt 0 ] && echo "write: $NONE rows without a test location"
  # v0.9.7.1 (3.2f, R2): the size, recorded; nothing is refused for it
  sh checks/event.sh "brief-written path=$OUT role=$WROLE try=${TRY:--} bytes=$(wc -c < "$OUT" | tr -d ' ')" >/dev/null 2>&1 || printf 'brief-written path=%s role=%s try=%s bytes=%s at=%s\n' "$OUT" "$WROLE" "${TRY:--}" "$(wc -c < "$OUT" | tr -d ' ')" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
  ctx_notice
  sh "$0" "$OUT"; exit $?
fi

# --- v0.9.8 (3.3, R5, R6): the authority bundle — a row's, the flag, the kept record ---
if [ "${1:-}" = authority ]; then
  shift; AM=''; AR=''; AS=''
  ausage() { echo 'ViD authority: usage — sh checks/brief.sh authority --row <ROW-id> [--at <commit>] | --changed [--rows <ROW-id,…>] [--since <commit> | --base <file>] | --kept <ROW-id,…>' >&2; exit 2; }
  AB=''; AAT=HEAD
  while [ $# -gt 0 ]; do case "$1" in --row) AM=row; AR=${2:-}; shift 2 ;; --at) AAT=${2:-}; shift 2 ;; --changed) AM=changed; shift ;; --kept) AM=kept; AR=${2:-}; shift 2 ;; --rows) AR=${2:-}; shift 2 ;; --since) AS=${2:-}; shift 2 ;; --base) AB=${2:-}; shift 2 ;; *) ausage ;; esac; done
  [ -n "$AM" ] || ausage
  git rev-parse -q --verify HEAD > /dev/null 2>&1 || { echo 'ViD authority: no commit at HEAD' >&2; exit 1; }
  W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
  case "$AM" in
    row)
      [ -n "$AR" ] || ausage
      git rev-parse -q --verify "$AAT^{commit}" > /dev/null 2>&1 || { echo "ViD authority: --at $AAT names no commit" >&2; exit 1; }
      ACACHE=$W; astate "$AAT" "$W/h"; printf '%s\n' "$AR" > "$W/r"
      aselect "$W/h/inv" "$W/h/eff" "$W/h/dec" "$W/h/canon" "$W/r" > "$W/sel"
      grep -q "^$AR	" "$W/sel" || awk -F'|' -v r="$AR" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x) } x == r { f = 1 } END { exit f ? 0 : 1 }' "$W/h/inv" || { echo "ViD authority: no row $AR in INVENTORY.md at HEAD" >&2; exit 1; }
      awk -F'\t' 'FILENAME == ARGV[1] { C[$1] = $2; next } $2 != "design" { print $2 " " $3 " " C[$3] }' "$W/h/canon" "$W/sel"
      for m in $(awk -F'\t' '$2 == "design" { print $3 }' "$W/sel"); do
        printf 'design %s %s\n' "$m" "$(git grep -l -F -- "$m" "$AAT" -- design/ 2>/dev/null | sed "s/^$AAT://" | paste -sd ',' - | sed 's/^$/none/')"
      done
      echo "digest $(adigest "$W/h" "$AR")" ;;
    changed)
      if [ -n "$AR" ]; then printf '%s\n' "$AR" | tr ', ' '\n\n' | grep -v '^$' > "$W/want"; fi
      if [ -n "$AB" ]; then [ -f "$AB" ] || ausage; awk -F'\t' 'NF >= 2 && $1 ~ /^ROW-/' "$AB" > "$W/base"   # <row><TAB><commit> per line: each row's own baseline (checks/metrics.sh test-state)
      elif [ -n "$AS" ]; then git rev-parse -q --verify "$AS^{commit}" > /dev/null 2>&1 || { echo "ViD authority: --since $AS names no commit" >&2; exit 1; }
        [ -s "$W/want" ] || ausage; awk -v c="$AS" '{ print $0 "\t" c }' "$W/want" > "$W/base"
      else abase > "$W/base.all"; if [ -s "$W/want" ]; then awk -F'\t' 'NR == FNR { W[$1] = 1; next } ($1 in W)' "$W/want" "$W/base.all" > "$W/base"; else mv "$W/base.all" "$W/base"; fi; fi
      [ -s "$W/base" ] || exit 0
      achanged "$W/base" "$W" | awk -F'\t' '{ printf "authority-changed row=%s since=%s what=%s\n", $1, substr($2, 1, 12), $3 }' ;;
    kept)
      [ -n "$AR" ] || ausage
      H=$(git rev-parse --short=12 HEAD)
      for r in $(printf '%s\n' "$AR" | tr ', ' '\n\n' | grep -v '^$'); do
        case "$r" in ROW-*) ;; *) echo "ViD authority: $r is no row id" >&2; exit 2 ;; esac
        sh checks/event.sh "authority-kept row=$r sha=$H" > /dev/null 2>&1 || printf 'authority-kept row=%s sha=%s at=%s\n' "$r" "$H" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
        echo "ViD authority: $r kept at $H — its authority flag clears until the bundle changes again"
      done ;;
  esac
  exit 0
fi
# v0.9.8.1 (R7, F-1): `brief=` is kept relative to the home, so it holds no space a home's path may; a reader takes
# it up to the next ` key=`, so an older record's absolute path, spaces and all, is read whole, its home prefix
# removed. BKV is that reader; brel <path> prints a path under this home relative to it.
BKV='function bkv(h,   i, s, j) { i = index($0, " brief="); if (!i) return ""; s = substr($0, i + 7); j = match(s, / [a-z][a-z-]*=/); if (j) s = substr(s, 1, j - 1); if (h != "" && index(s, h "/") == 1) s = substr(s, length(h) + 2); return s }'
brel() { case "$1" in ./*) printf '%s\n' "${1#./}" ;; "$PWD"/*) printf '%s\n' "${1#"$PWD"/}" ;; "$(pwd -P)"/*) printf '%s\n' "${1#"$(pwd -P)"/}" ;; *) printf '%s\n' "$1" ;; esac; }
# bcost_seen <brief>: a build-cost for it is recorded (either form)
bcost_seen() { [ -f .vid/metrics-events ] && awk -v b="$1" -v h="$PWD" -v hp="$(pwd -P)" "$BKV"' $1 == "build-cost" { v = bkv(h); if (v == b || bkv(hp) == b) f = 1 } END { exit f ? 0 : 1 }' .vid/metrics-events; }
# --- v0.9.7.1 (3.8, 3.11, 3.12; R8, R11, R12): context, every role's cost, the unrelated plugins ---
if [ "${1:-}" = context ]; then echo "context: $(mgr_context)"; exit 0; fi
if [ "${1:-}" = protected ]; then protected; exit 0; fi   # v0.9.7.1 (3.4, R4): the one set, for checks/job.sh's Codex hook
if [ "${1:-}" = cost ]; then
  # v0.9.8.1 (R15): --tokens <n> --source agent-tool — the caller's own totals (the Agent tool's), recorded as
  # reported when no transcript is found (an agent outside the project's own session), never as unknown
  CB=${2:-}; CA=''; CTK=''; CSRC=''; if [ $# -ge 2 ]; then shift 2; else shift $#; fi
  while [ $# -gt 0 ]; do case "$1" in --agent) CA=${2:-}; shift 2 ;; --tokens) CTK=${2:-}; shift 2 ;; --source) CSRC=${2:-}; shift 2 ;; *) CA=''; break ;; esac; done
  cusage() { echo 'ViD cost: usage — sh checks/brief.sh cost <brief> --agent <id> [--tokens <n> --source agent-tool] (a grader'"'"'s, test-author'"'"'s or analyst'"'"'s return)' >&2; exit 2; }
  [ -n "$CB" ] && [ -f "$CB" ] && [ -n "$CA" ] || cusage
  if [ -n "$CTK$CSRC" ]; then case "$CTK" in ''|*[!0-9]*) cusage ;; esac; [ "$CSRC" = agent-tool ] || cusage; fi
  CR=$(sed -n '1,14s/^role:[[:space:]]*\([a-z-]*\).*/\1/p' "$CB" | head -n 1)
  case "$CR" in grader|test-author|test-analyst) ;; *) echo "ViD cost: a $CR's cost is recorded by sh checks/brief.sh return" >&2; exit 2 ;; esac
  CB=$(brel "$CB")
  if bcost_seen "$CB"; then echo "ViD cost: already recorded for $CB — nothing recorded"; exit 0; fi
  CS=$(sed -n '1,14s/^.*slice:[[:space:]]*\([^ ]*\).*/\1/p' "$CB" | head -n 1)
  CN=$(awk '/^## [0-9]/ { on = ($2 == 1); next } on' "$CB" | grep -c '^ROW-' || true)
  CP=$( [ -f .vid/metrics-events ] && awk -v a="agent=$CA" '$1 == "agent-start" { hit = 0; for (i = 2; i <= NF; i++) if ($i == a) hit = 1; if (!hit) next
      p = index($0, " transcript="); if (!p) next; t = substr($0, p + 12); if (substr(t, 1, 1) == "\"") { t = substr(t, 2); q = index(t, "\""); t = substr(t, 1, q - 1) } else sub(/ .*/, "", t); last = t } END { print last }' .vid/metrics-events)
  CT=''; case "$CP" in ''|-) ;; *) CT="${CP%.jsonl}/subagents/agent-$CA.jsonl" ;; esac
  if [ -n "$CT" ] && [ -r "$CT" ]; then CC=$(tcost "$CT" ''); CE=$(tmodel "$CT")
  elif [ -n "$CTK" ]; then CC="peak=unknown total=$CTK before-change=unknown source=agent-tool"; CE='model=unknown effort=unknown'
  else CC='peak=unknown total=unknown before-change=unknown'; CE='model=unknown effort=unknown'; fi
  sh checks/event.sh "build-cost role=$CR slice=${CS:--} step=- brief=$CB rows=$CN rows-passed=- $CC tool=claude $CE brief-bytes=$(wc -c < "$CB" | tr -d ' ') agent=$CA" >/dev/null   # v0.9.8.1 (R9): agent=
  echo "ViD cost: build-cost role=$CR slice=${CS:--} brief=$CB rows=$CN $CC tool=claude $CE"
  exit 0
fi
if [ "${1:-}" = plugins ]; then
  # each settings file's enabledPlugins entries, `<id> <true|false>`; the later scope wins (user, project, local)
  ep() { [ -f "$1" ] || return 0; tr '\n' ' ' < "$1" | awk '{ p = index($0, "\"enabledPlugins\""); if (!p) exit; s = substr($0, p); b = index(s, "{"); e = index(s, "}"); if (!b || !e) exit; s = substr(s, b + 1, e - b - 1)
      while (match(s, /"[^"]+"[ \t]*:[ \t]*(true|false)/)) { kv = substr(s, RSTART, RLENGTH); k = kv; sub(/^"/, "", k); sub(/".*/, "", k); v = (kv ~ /true$/) ? "true" : "false"; print k " " v; s = substr(s, RSTART + RLENGTH) } }'; }
  : > "${TMPDIR:-/tmp}/vidpl.$$"; trap 'rm -f "${TMPDIR:-/tmp}/vidpl.$$"' EXIT
  for sc in "user:$HOME/.claude/settings.json" "project:.claude/settings.json" "local:.claude/settings.local.json"; do
    ep "${sc#*:}" | awk -v s="${sc%%:*}" '{ print $1 " " $2 " " s }' >> "${TMPDIR:-/tmp}/vidpl.$$"
  done
  awk '{ V[$1] = $2; S[$1] = $3; if (!($1 in O)) O[$1] = ++n; K[O[$1]] = $1 } END { for (i = 1; i <= n; i++) { k = K[i]; split(k, a, "@"); if (V[k] == "true" && a[1] != "vid") print k " (enabled at " S[k] " scope)" } }' "${TMPDIR:-/tmp}/vidpl.$$" > "${TMPDIR:-/tmp}/vidpl.$$.on"
  if [ -s "${TMPDIR:-/tmp}/vidpl.$$.on" ]; then
    echo "plugins: $(grep -c . "${TMPDIR:-/tmp}/vidpl.$$.on") enabled beside ViD — each one's skills reach this session's start:"
    sed 's/^/    /' "${TMPDIR:-/tmp}/vidpl.$$.on"
    printf '  to turn one off for this project only, add to .claude/settings.json: "enabledPlugins": {"<name>@<marketplace>": false} — a local setting (.claude/settings.local.json) or the organisation can override it\n'
  else echo 'plugins: none enabled beside ViD'; fi
  rm -f "${TMPDIR:-/tmp}/vidpl.$$.on"
  exit 0
fi
# --- v0.9.7.1 (3.4b, c; R4): save and restore — a continuation package, never a commit, a stash or an index ---
# bhv <brief> <key>: a header value of a brief (its first 14 lines)
bhv() { sed -n "1,14s/^.*$2:[[:space:]]*//p" "$1" | head -n 1 | sed 's/[[:space:]]\{2,\}[a-z -]*:.*$//;s/[[:space:]]*$//'; }
# homeof <brief path>: the run's home — the folder holding the brief's .vid/briefs/
homeof() { case "$1" in */.vid/briefs/*) printf '%s\n' "${1%%/.vid/briefs/*}" ;; .vid/briefs/*) pwd -P ;; *) pwd -P ;; esac; }
if [ "${1:-}" = save ]; then
  SB=${2:-}; SWT=''
  [ "${3:-}" = --worktree ] && SWT=${4:-}
  [ -n "$SB" ] && [ -f "$SB" ] || { echo "ViD save: usage — sh checks/brief.sh save <brief> [--worktree <path>] (no such brief: '${SB:-}')" >&2; exit 2; }
  srefuse() { echo "ViD save: refused — $* (nothing published; the worktree is as it was)" >&2; exit 1; }
  SH=$(cd "$(homeof "$SB")" && pwd -P); case "$SB" in /*) ;; *) SB=$(pwd -P)/$SB ;; esac
  STRY=$(bhv "$SB" try); SSTEP=$(bhv "$SB" step); SQ=$(bhv "$SB" quoted-at); SROLE=$(bhv "$SB" role)
  [ -n "$STRY" ] || srefuse "the brief has no try: — only a builder's or a fixer's brief is saved"
  [ -n "$SSTEP" ] || SSTEP=-
  SWT=${SWT:-.}; [ -d "$SWT" ] || srefuse "no worktree at $SWT"
  SWT=$(cd "$SWT" && git rev-parse --show-toplevel 2>/dev/null) || srefuse "$SWT is no git worktree"
  SHEAD=$(git -C "$SWT" rev-parse HEAD) || srefuse 'the worktree has no HEAD'
  W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
  # the paths: tracked changes (both sides of a rename) and untracked files outside .vid/
  git -C "$SWT" diff --no-renames --name-only HEAD -- . ':(exclude).vid' > "$W/tracked" || srefuse 'git diff failed'
  git -C "$SWT" ls-files --others --exclude-standard -- . ':(exclude).vid' > "$W/new" || srefuse 'git ls-files failed'
  : > "$W/bad"
  for f in $(cat "$W/tracked" "$W/new"); do
    case "/$f/" in */../*|//*) printf '%s (leaves the worktree)\n' "$f" >> "$W/bad"; continue ;; esac
    (cd "$SH" && isprot "$f") && printf '%s (protected)\n' "$f" >> "$W/bad"
  done
  for f in $(cat "$W/new"); do
    if [ -L "$SWT/$f" ]; then printf '%s (a symlink)\n' "$f" >> "$W/bad"; elif [ ! -f "$SWT/$f" ]; then printf '%s (not a regular file)\n' "$f" >> "$W/bad"; fi
  done
  git -C "$SWT" diff --no-renames --raw HEAD -- . ':(exclude).vid' | awk '$1 ~ /120000/ || $2 ~ /120000/ || $1 ~ /160000/ || $2 ~ /160000/ { sub(/^[^\t]*\t/, ""); print $0 " (a symlink or a submodule)" }' >> "$W/bad"
  [ -s "$W/bad" ] && srefuse "these paths can't travel in a package:
$(sed 's/^/    /' "$W/bad")"
  SD=$SH/.vid/continuations/$SSTEP; mkdir -p "$SD"; ST=$SD/.$STRY.tmp.$$
  rm -rf "$ST"; mkdir -p "$ST/new" || srefuse "can't write under $SD"
  git -C "$SWT" diff --binary --no-renames HEAD -- . ':(exclude).vid' > "$ST/tracked.patch" || { rm -rf "$ST"; srefuse 'git diff --binary failed'; }
  for f in $(cat "$W/new"); do mkdir -p "$ST/new/$(dirname "$f")" && cp -p "$SWT/$f" "$ST/new/$f" || { rm -rf "$ST"; srefuse "can't copy $f"; }; done
  mode() { if [ -x "$1" ]; then echo 755; else echo 644; fi; }
  RPT=$(printf '%s' "$SB" | sed 's/\.md$/.report.md/')
  {
    printf 'schema=1\nrun=%s\nstep=%s\ntry=%s\nrole=%s\nbrief=%s\nbrief-hash=%s\nquoted-at=%s\nhead=%s\nlanded=%s\nreport=%s\n' "$SH" "$SSTEP" "$STRY" "$SROLE" "$SB" "$(git hash-object "$SB")" "$SQ" "$SHEAD" "$(git -C "$SWT" rev-list "$SQ..HEAD" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')" "$RPT"
    printf 'file\ttracked.patch\t644\t%s\n' "$(git hash-object "$ST/tracked.patch")"
    for f in $(cat "$W/new"); do printf 'file\tnew/%s\t%s\t%s\n' "$f" "$(mode "$SWT/$f")" "$(git hash-object "$ST/new/$f")"; done
  } > "$ST/manifest"
  NF_=$(cat "$W/tracked" "$W/new" | grep -c . || true); NB=$(cat "$ST/tracked.patch" $(find "$ST/new" -type f) 2>/dev/null | wc -c | tr -d ' ')
  F=$SD/$STRY
  if [ -d "$F" ]; then mv "$F" "$SD/.$STRY.old.$$" && mv "$ST" "$F" && rm -rf "$SD/.$STRY.old.$$"; else mv "$ST" "$F"; fi || srefuse "can't publish $F"
  (cd "$SH" && sh checks/event.sh "continuation-saved try=$STRY files=$NF_ bytes=$NB" >/dev/null 2>&1) || printf 'continuation-saved try=%s files=%s bytes=%s at=%s\n' "$STRY" "$NF_" "$NB" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$SH/.vid/metrics-events"
  echo "ViD save: ok — .vid/continuations/$SSTEP/$STRY ($NF_ files, $NB bytes; from $SHEAD)"
  exit 0
fi
if [ "${1:-}" = restore ]; then
  RB_=${2:-}
  [ -n "$RB_" ] && [ -f "$RB_" ] || { echo "ViD restore: usage — sh checks/brief.sh restore <brief> (no such brief: '${RB_:-}')" >&2; exit 2; }
  rrefuse() { echo "ViD restore: refused — $* (nothing changed)" >&2; exit 1; }
  RH=$(cd "$(homeof "$RB_")" && pwd -P)
  RS14=$(awk '/^## [0-9]/ { on = ($2 == 14); next } on' "$RB_")
  RPK=$(printf '%s\n' "$RS14" | sed -n 's/^package: \([^ ]*\)    manifest: [0-9a-f]*$/\1/p' | head -n 1)
  RMH=$(printf '%s\n' "$RS14" | sed -n 's/^package: [^ ]*    manifest: \([0-9a-f]*\)$/\1/p' | head -n 1)
  [ -n "$RPK" ] || rrefuse 'the brief names no continuation (## 14 package:)'
  case "$RPK" in /*) ;; *) RPK=$RH/$RPK ;; esac
  [ -f "$RPK/manifest" ] || rrefuse "no package at $RPK"
  [ "$(git hash-object "$RPK/manifest")" = "$RMH" ] || rrefuse "the manifest's hash is not the brief's ($RMH): the package changed after the brief was written"
  [ -z "$(git status --porcelain -- . ':(exclude).vid' 2>/dev/null)" ] || rrefuse 'the worktree is not clean: restore onto your fresh checkout, before any edit'
  W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
  : > "$W/bad"
  awk -F'\t' '$1 == "file" { print $2 "\t" $4 }' "$RPK/manifest" | while IFS='	' read -r f h; do
    [ -f "$RPK/$f" ] || { printf '%s (missing)\n' "$f" >> "$W/bad"; continue; }
    [ "$(git hash-object "$RPK/$f")" = "$h" ] || printf '%s (its hash is not the manifest'"'"'s: corrupted)\n' "$f" >> "$W/bad"
  done
  [ -s "$W/bad" ] && rrefuse "the package's payload does not match its manifest:
$(sed 's/^/    /' "$W/bad")"
  { [ -s "$RPK/tracked.patch" ] && git apply --numstat -z "$RPK/tracked.patch" 2>/dev/null | tr '\0' '\n' | awk -F'\t' 'NF >= 3 { print $3 } NF < 3 && NF > 0 { print }'
    awk -F'\t' '$1 == "file" && index($2, "new/") == 1 { print substr($2, 5) }' "$RPK/manifest"; } | grep -v '^$' | sort -u > "$W/paths" || true
  for f in $(cat "$W/paths"); do
    case "/$f/" in */../*|//*) printf '%s (leaves the worktree)\n' "$f" >> "$W/bad"; continue ;; esac
    (cd "$RH" && isprot "$f") && printf '%s (protected)\n' "$f" >> "$W/bad"
  done
  [ -s "$W/bad" ] && rrefuse "these paths can't be restored:
$(sed 's/^/    /' "$W/bad")"
  awk -F'\t' '$1 == "file" && index($2, "new/") == 1 { print substr($2, 5) }' "$RPK/manifest" | while IFS= read -r f; do
    if git cat-file -e "HEAD:$f" 2>/dev/null || [ -e "$f" ] || [ -L "$f" ]; then printf '%s\n' "$f" >> "$W/bad"; fi
  done
  [ -s "$W/bad" ] && rrefuse "the package's new files already exist here:
$(sed 's/^/    /' "$W/bad")"
  if [ -s "$RPK/tracked.patch" ]; then
    git apply --check --binary "$RPK/tracked.patch" > "$W/err" 2>&1 || rrefuse "the patch no longer applies to this base — reconcile it by reading the package ($RPK):
$(sed 's/^/    /' "$W/err" | head -n 20)"
    git apply --binary "$RPK/tracked.patch" > "$W/err" 2>&1 || rrefuse "git apply failed: $(head -n 5 "$W/err")"
  fi
  awk -F'\t' '$1 == "file" && index($2, "new/") == 1 { print substr($2, 5) "\t" $3 }' "$RPK/manifest" | while IFS='	' read -r f m; do
    mkdir -p "$(dirname "$f")" && cp "$RPK/new/$f" "$f" && chmod "$m" "$f"
  done
  FROM=$(sed -n 's/^try=//p' "$RPK/manifest" | head -n 1); TO=$(bhv "$RB_" try)
  (cd "$RH" && sh checks/event.sh "continuation-restored try=${TO:--} from=${FROM:--}" >/dev/null 2>&1) || printf 'continuation-restored try=%s from=%s at=%s\n' "${TO:--}" "${FROM:--}" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$RH/.vid/metrics-events"
  echo "ViD restore: ok — $(grep -c . "$W/paths" || true) path(s) from $FROM; restored code certifies nothing: run your rows first"
  exit 0
fi
# --- v0.9.7.0.7 (3.3, R7): `return` — a builder's or fixer's hand-back, and its build-cost ---
if [ "${1:-}" = return ]; then
  RF=${2:-}; RAG=''
  [ "${3:-}" = --agent ] && RAG=${4:-}
  [ -n "$RF" ] && [ -f "$RF" ] || { echo "ViD return: usage — sh checks/brief.sh return <hand-back file> [--agent <id|codex:<try>>] (no such file: '${RF:-}')" >&2; exit 2; }
  case "$RF" in *.tmp) echo "ViD return: $RF is a temporary file — the agent renames it into place when it is whole" >&2; exit 2 ;; esac
  W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
  # v0.9.7.1 (3.4a, R4): the agent writes its return without `agent:`; the run manager's --agent writes it in
  if [ -n "$RAG" ]; then
    case "$RAG" in *[!A-Za-z0-9._:-]*) echo "ViD return: --agent takes the host's agent id or codex:<try>, not '$RAG'" >&2; exit 2 ;; esac
    awk -v a="agent: $RAG" 'index($0, "agent:") == 1 { next } { print } index($0, "brief:") == 1 && !d { print a; d = 1 }' "$RF" > "$W/rf"
    grep -qx "agent: $RAG" "$W/rf" || { printf 'agent: %s\n' "$RAG"; cat "$W/rf"; } > "$W/rf2" && [ -f "$W/rf2" ] && mv "$W/rf2" "$W/rf"
    cat "$W/rf" > "$RF.tmp.$$" && mv "$RF.tmp.$$" "$RF"
  fi
  RFAIL=''
  rbad() { RFAIL="$RFAIL$1
"; }
  hv() { awk -v k="$1" 'index($0, k ":") == 1 { v = substr($0, length(k) + 2); gsub(/^[ \t]+|[ \t]+$/, "", v); print v; exit }' "$RF"; }
  RB=$(hv brief); RA=$(hv agent); RBR=$(hv branch); RC=$(hv commit)
  [ -n "$RB" ] || rbad "header: no 'brief:' line"
  [ -n "$RA" ] || rbad "header: no 'agent:' line — the run manager adds the agent id from the Agent tool's result"
  [ -n "$RBR" ] || rbad "header: no 'branch:' line"
  [ -n "$RC" ] || rbad "header: no 'commit:' line"
  # v0.9.8.1 (R16, F-9): a bare brief file name (`brief: builder-7.md`, as a Codex return wrote it) is the run's brief
  # of that name when exactly one .vid/briefs/<N>/ holds it
  case "$RB" in */*|'') ;; *) if [ ! -f "$RB" ]; then _bm=$(ls .vid/briefs/*/"$RB" 2>/dev/null || true)
      if [ "$(printf '%s\n' "$_bm" | grep -c .)" -eq 1 ]; then RB=$_bm
      elif [ -n "$_bm" ]; then rbad "header: brief: $RB names more than one brief of the run ($(printf '%s\n' "$_bm" | paste -sd ',' - | sed 's/,/, /g')) — give its path"; RB=''; fi; fi ;; esac
  if [ -n "$RB" ] && [ ! -f "$RB" ]; then rbad "header: the brief $RB does not exist"; RB=''; fi
  [ -z "$RB" ] || RB=$(brel "$RB")   # v0.9.8.1 (R7): kept relative to the home (the live project's A-272)
  bh() { sed -n "1,12s/^.*$1:[[:space:]]*//p" "$RB" | head -n 1 | sed 's/[[:space:]]\{2,\}[a-z -]*:.*$//;s/[[:space:]]*$//'; }
  if [ -n "$RB" ]; then
    awk '/^## [0-9]/ { on = ($2 == 1); next } on' "$RB" | grep -oE '^ROW-[0-9A-Za-z-]+' > "$W/want" || : > "$W/want"
  else : > "$W/want"; fi
  # the valid receipts of the run, as checks/evidence.sh reads one
  : > "$W/valid"
  if [ -f .vid/metrics-events ]; then
    awk '$1 == "invalidated" { for (i = 2; i <= NF; i++) if (index($i, "report=") == 1) inv[substr($i, 8)] = 1 }
      $1 == "ledger-run" { for (i = 2; i <= NF; i++) if (index($i, "report=") == 1) { r = substr($i, 8); if (r != "" && r != "none" && !index(r, ".proof.")) ok[r] = 1 } }   # v0.9.8 (R15): a proof receipt shows no row passing
      END { for (r in ok) if (!(r in inv)) print r }' .vid/metrics-events > "$W/valid"
  fi
  # the row lines: each row of the brief once, no other; a pass shown passing by its receipt
  awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id) } id ~ /^ROW-/ { print NR "\t" $0 }' "$RF" > "$W/lines"
  NP=0; NROWS=$(grep -c . "$W/want")
  while IFS='	' read -r ln l; do
    id=$(printf '%s\n' "$l" | awk -F'|' '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x); print x }')
    st=$(printf '%s\n' "$l" | awk -F'|' '{ x = $2; gsub(/^[ \t]+|[ \t]+$/, "", x); print x }')
    rc=$(printf '%s\n' "$l" | awk -F'|' '{ x = $3; gsub(/^[ \t]+|[ \t]+$/, "", x); print x }')
    rs=$(printf '%s\n' "$l" | awk -F'|' '{ x = ""; for (i = 4; i <= NF; i++) x = x (i > 4 ? "|" : "") $i; gsub(/^[ \t]+|[ \t]+$/, "", x); print x }')
    if ! grep -qxF -- "$id" "$W/want"; then rbad "line $ln: $id is not a row of the brief ($RB)"; continue; fi
    if grep -qxF -- "$id" "$W/seen" 2>/dev/null; then rbad "line $ln: $id appears twice"; continue; fi
    printf '%s\n' "$id" >> "$W/seen"
    case "$st" in
      pass)
        [ -n "$rc" ] || { rbad "line $ln: $id passes with no receipt"; continue; }
        r=${rc##*/}
        if ! grep -qxF -- "$r" "$W/valid" || [ ! -f ".vid/ledger-results/$r" ] || [ ! -f ".vid/ledger-results/$r.tree" ]; then
          rbad "line $ln: $id — '$rc' is not a valid receipt of this run (published by checks/test.sh, present with its .tree, not invalidated); the receipt field holds one receipt file name; notes go in the report"; continue; fi
        if [ ! -f "$W/cs.$r" ]; then
          { if [ -f ".vid/ledger-results/$r.cases" ]; then cat ".vid/ledger-results/$r.cases"; elif [ -f checks/extractors/results.sh ]; then sh checks/extractors/results.sh ".vid/ledger-results/$r" 2>/dev/null; fi; } | awk '$1 == "case" { print $2 "\t" $3 }' > "$W/cs.$r"
          sh checks/evidence.sh reach "$r" > "$W/reach.$r" 2>/dev/null || : > "$W/reach.$r"
        fi
        awk -F'\t' -v id="$id" 'NR == FNR { S[$1] = $2; next } $2 == id { n++; if (S[$1] != "passed") bad = bad " " $1 " " (S[$1] == "" ? "absent" : S[$1]) } END { if (n == 0) { print "none"; exit } if (bad != "") print "bad" bad }' "$W/cs.$r" "$W/reach.$r" > "$W/v"
        case "$(cat "$W/v")" in
          none) if [ "$(sed -n 's/^shape=//p' ".vid/ledger-results/$r.tree" 2>/dev/null | head -n 1)" != deployed ] && sh checks/evidence.sh reach "$r" --shape deployed --raw 2>/dev/null | awk -F'\t' -v id="$id" '$2 == id { f = 1 } END { exit f ? 0 : 1 }'; then
                  rbad "line $ln: $id — only a deployed run credits it (a journey or a (process) row), and $r is an inline receipt: it does not show the row passing"
                else rbad "line $ln: $id — $r runs none of the row's cases: it does not show the row passing"; fi ;;
          bad*) rbad "line $ln: $id — $r does not show the row passing:$(sed 's/^bad//' "$W/v")" ;;
          *) NP=$((NP + 1)) ;;
        esac ;;
      not) [ -n "$rs" ] || rbad "line $ln: $id is not passing and gives no reason and evidence" ;;
      *) rbad "line $ln: $id — '$st' is neither pass nor not" ;;
    esac
  done < "$W/lines"
  [ -f "$W/seen" ] || : > "$W/seen"
  for id in $(grep -vxF -f "$W/seen" "$W/want" || true); do rbad "the row $id of the brief is missing from the hand-back"; done
  # v0.9.7.1 (3.1, R1): the commit descends from quoted-at — but a `wrong base` return, every row `not | none | wrong base: …`
  WRONGB=no
  if [ -s "$W/lines" ] && ! awk -F'\t' '{ print $2 }' "$W/lines" | awk -F'|' '{ s = $2; r = $3; w = $4; gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", r); gsub(/^[ \t]+/, "", w)
      if (!(s == "not" && r == "none" && index(w, "wrong base:") == 1)) bad = 1 } END { exit bad ? 0 : 1 }'; then WRONGB=yes; fi
  if [ -n "$RB" ] && [ -n "$RC" ] && [ "$WRONGB" = no ]; then
    RQ=$(bh quoted-at)
    if ! git cat-file -e "$RC^{commit}" 2>/dev/null; then rbad "header: commit: $RC is no commit here"
    elif [ -n "$RQ" ] && ! git merge-base --is-ancestor "$RQ" "$RC" 2>/dev/null; then rbad "header: commit: $RC does not descend from the brief's quoted-at ($RQ) — a builder starts on its base (vid-build); a wrong base hands back every row 'not | none | wrong base: <the error>'"; fi
  fi
  # v0.9.7.1 (3.4a, R4): a `not` reason pointing at a report needs the report beside the return
  RPT=$(printf '%s' "$RF" | sed 's/\.return\.md$/.report.md/')
  # v0.9.7.3 (3.9, R9): a report the agent wrote inside its worktree (the checkout of the return's branch, at the same
  # path) is copied to the run's home first
  if [ ! -f "$RPT" ] && [ -n "$RBR" ]; then
    _rr=$RPT; case "$_rr" in "$(pwd -P)"/*) _rr=${_rr#"$(pwd -P)"/} ;; "$PWD"/*) _rr=${_rr#"$PWD"/} ;; esac
    _wtr=$(git worktree list --porcelain 2>/dev/null | awk -v b="refs/heads/$RBR" '$1 == "worktree" { w = substr($0, 10) } $1 == "branch" && $2 == b { print w; exit }')
    if [ -n "$_wtr" ] && [ -f "$_wtr/$_rr" ]; then cp "$_wtr/$_rr" "$RPT.tmp.$$" && mv "$RPT.tmp.$$" "$RPT" && echo "ViD return: the report was in the worktree ($_wtr/$_rr) — copied to $RPT"; fi
  fi
  if [ ! -f "$RPT" ] && awk -F'|' '{ x = tolower($4); if (x ~ /see[ \t]+([^ \t|]+[ \t]+)?report/) f = 1 } END { exit f ? 0 : 1 }' "$RF"; then
    rbad "a not reason points at a report, and there is none: $RPT"
  fi
  # v0.9.7.1 (3.9, R9): a pass's receipt tested the committed protected paths — every builder and fixer, a harness upgrade (## 13) excepted
  if [ -n "$RB" ] && [ -n "$RC" ] && git cat-file -e "$RC^{commit}" 2>/dev/null && ! grep -qE '^## 13([^0-9]|$)' "$RB"; then
    protected > "$W/prot"
    awk -F'\t' '{ print $2 }' "$W/lines" | awk -F'|' '{ s = $2; r = $3; gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", r); if (s == "pass" && r != "") { sub(/.*\//, "", r); print r } }' | sort -u > "$W/prcpt"
    for r in $(cat "$W/prcpt"); do
      [ -f ".vid/ledger-results/$r.tree" ] || continue
      rt=$(sed -n 's/^tree=//p' ".vid/ledger-results/$r.tree" | head -n 1)
      if [ -z "$rt" ] || ! git cat-file -e "$rt^{tree}" 2>/dev/null; then rbad "$r: its tested tree (${rt:-none}) is missing here — the protected paths it ran on can't be checked (fails closed)"; continue; fi
      _pd=$(git diff --name-only "$rt" "$RC" -- $(cat "$W/prot") 2>/dev/null | head -n 5 | paste -sd ',' -)
      [ -z "$_pd" ] || rbad "$r: the tree it tested differs from the commit's in protected paths ($_pd) — a result on changed law, tests or harness is no pass"
    done
  fi
  if [ -n "$RFAIL" ]; then
    echo "ViD return: refused — $RF:" >&2; printf '%s' "$RFAIL" | sed 's/^/    /' >&2; exit 1
  fi
  echo "ViD return: ok — $RF ($NP of $NROWS rows pass)"
  # v0.9.7.1 (3.7, R7): the hand-off in one command — what the run manager acts on, printed; nothing routed
  RTRY=$(bh try)
  # v0.9.7.0.9 (3.4, R4): the analyst-dues still open, for the run manager — it alone starts the analyst; v0.9.7.3
  # (3.9, R9): only this attempt's tickets', when the brief names its try
  if [ -f checks/test.sh ]; then if [ -n "$RTRY" ]; then sh checks/test.sh analyst-due --try "$RTRY" 2>/dev/null; else sh checks/test.sh analyst-due 2>/dev/null; fi; fi
  echo 'results at the return'"'"'s commit, per case (the receipts it names):'
  awk -F'\t' '{ print $2 }' "$W/lines" | awk -F'|' '{ id = $1; r = $3; gsub(/^[ \t]+|[ \t]+$/, "", id); gsub(/^[ \t]+|[ \t]+$/, "", r); if (r != "" && r != "none") { sub(/.*\//, "", r); print id "\t" r } }' | while IFS='	' read -r id r; do
    [ -f ".vid/ledger-results/$r" ] || { echo "    $id: no receipt $r here"; continue; }
    [ -f "$W/reach.$r" ] || sh checks/evidence.sh reach "$r" > "$W/reach.$r" 2>/dev/null < /dev/null || : > "$W/reach.$r"
    [ -f "$W/cs.$r" ] || { if [ -f ".vid/ledger-results/$r.cases" ]; then awk '$1 == "case" { print $2 "\t" $3 }' ".vid/ledger-results/$r.cases"; fi > "$W/cs.$r"; }
    awk -F'\t' -v id="$id" -v r="$r" 'NR == FNR { S[$1] = $2; next } $2 == id { n++; print "    " id " " $1 " " (S[$1] == "" ? "absent" : S[$1]) " (" r ")" } END { if (!n) print "    " id ": no case of the row in " r }' "$W/cs.$r" "$W/reach.$r"
  done
  # rehearsal R-1: a wrong base is said as such — nothing was built, so no merge probe; the run manager writes a new brief
  if [ "$WRONGB" = yes ]; then
    echo "wrong base: every row — $(awk -F'\t' 'NR == 1 { print $2 }' "$W/lines" | sed 's/^[^|]*|[^|]*|[^|]*|[[:space:]]*wrong base:[[:space:]]*//') — nothing was built: write a new brief and spawn again"
  elif [ -n "$RC" ] && git cat-file -e "$RC^{commit}" 2>/dev/null; then
    _mrc=0; git merge-tree --write-tree --name-only HEAD "$RC" > "$W/merge" 2>&1 || _mrc=$?
    case "$_mrc" in
      0) echo "merge probe: clean ($RC onto HEAD)" ;;
      1) echo "merge probe: conflicts ($RC onto HEAD): $(awk 'NR > 1 && NF == 0 { exit } NR > 1 { print }' "$W/merge" | head -n 10 | paste -sd ',' - | sed 's/,/, /g')" ;;
      *) echo 'merge probe: error' ;;
    esac
  else echo 'merge probe: error'; fi
  _wt=$(git worktree list --porcelain 2>/dev/null | awk -v b="refs/heads/$RBR" '/^worktree / { w = substr($0, 10) } $0 == "branch " b { print w; exit }')
  if [ -n "$_wt" ] && [ -d "$_wt" ]; then
    _un=$(git -C "$_wt" status --porcelain 2>/dev/null | grep -v ' \.vid/' | head -n 20)
    if [ -n "$_un" ]; then echo "uncommitted in $_wt:"; printf '%s\n' "$_un" | sed 's/^/    /'; else echo "uncommitted: none ($_wt)"; fi
  else echo "uncommitted: no worktree holds branch $RBR"; fi
  _pk=$(ls -d .vid/continuations/*/"${RTRY:-no-try}" 2>/dev/null | head -n 1)
  [ -n "$_pk" ] && echo "continuation package: $_pk"
  grep -E '^ROW-[^|]*\|[[:space:]]*not[[:space:]]*\|[^|]*\|[[:space:]]*law-needed:' "$RF" || true
  # v0.9.7.1 (3.11, R11): the run manager's own cost since its last, once per return file
  if ! awk -v f="return=$RF" '$1 == "manager-cost" { for (i = 2; i <= NF; i++) if ($i == f) x = 1 } END { exit x ? 0 : 1 }' .vid/metrics-events 2>/dev/null; then
    _mt=$(mgr_transcript); _since=$(awk '$1 == "manager-cost" { for (i = NF; i >= 2; i--) if (index($i, "at=") == 1) { a = substr($i, 4); break } } END { print a }' .vid/metrics-events 2>/dev/null)
    _mc='calls=unknown input=unknown'
    if [ -n "$_mt" ] && [ -r "$_mt" ]; then _mc=$(mcost "$_mt" "$_since"); fi
    sh checks/event.sh "manager-cost $_mc since=${_since:--} return=$RF" >/dev/null 2>&1 || true
  fi
  ctx_notice
  # build-cost, once per brief
  if bcost_seen "$RB"; then
    echo "ViD return: build-cost for $RB is already recorded — nothing recorded"; exit 0
  fi
  ROLE=$(bh role); SLICE=$(bh slice); STEP=$(bh step); [ -n "$STEP" ] || STEP=-
  # the step's modules: the brief's section 10 step line, else the plan in force
  SL=$(awk '/^## [0-9]/ { on = ($2 == 10); next } on && /^[ \t]*step[ \t]/ { print; exit }' "$RB")
  if [ -z "$SL" ] && [ "$STEP" != - ]; then PH=$(planhash); [ -n "$PH" ] && [ -f ".vid/plans/$PH.plan" ] && SL=$(steplines ".vid/plans/$PH.plan" "$STEP" | sed -n 1p); fi
  MODS=$(printf '%s\n' "$SL" | awk -F'|' '{ for (k = 2; k <= NF; k++) { x = $k; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^modules:/) print substr(x, 9) } }')
  # the agent's transcript, from its latest agent-start
  PT=$( [ -f .vid/metrics-events ] && awk -v a="agent=$RA" '$1 == "agent-start" { hit = 0; for (i = 2; i <= NF; i++) if ($i == a) hit = 1; if (!hit) next
      p = index($0, " transcript="); if (!p) next; t = substr($0, p + 12); if (substr(t, 1, 1) == "\"") { t = substr(t, 2); q = index(t, "\""); t = substr(t, 1, q - 1) } else sub(/ .*/, "", t); last = t } END { print last }' .vid/metrics-events)
  TR=''; case "$PT" in ''|-) ;; *) TR="${PT%.jsonl}/subagents/agent-$RA.jsonl" ;; esac
  COST='peak=unknown total=unknown before-change=unknown'
  # v0.9.7.1 (3.9, 3.11; R9, R11): a Codex builder's cost from its own events, by its own reader; the effective model and effort
  case "$RA" in
    codex:*) TOOL=codex; _jt=${RA#codex:}; [ -r ".vid/jobs/$_jt.events" ] && COST=$(ccost ".vid/jobs/$_jt.events"); EFF=$(cmodel ".vid/jobs/$_jt") ;;
    *) TOOL=claude; if [ -n "$TR" ] && [ -r "$TR" ]; then COST=$(tcost "$TR" "$MODS"); EFF=$(tmodel "$TR"); else EFF='model=unknown effort=unknown'; fi ;;
  esac
  _bb=$(wc -c < "$RB" | tr -d ' ')
  _n=$(printf '%s' "$RB" | sed -n 's/.*-\([0-9][0-9]*\)\.md$/\1/p')
  # v0.9.8.1 (R9, F-8): agent= — the agent's latest episode is finished once its return or cost is recorded
  sh checks/event.sh "agent-returned role=$ROLE n=${_n:--} try=${RTRY:--} agent=$RA" >/dev/null 2>&1 || true
  sh checks/event.sh "build-cost role=$ROLE slice=$SLICE step=$STEP brief=$RB rows=$NROWS rows-passed=$NP $COST tool=$TOOL $EFF brief-bytes=$_bb agent=$RA" >/dev/null
  echo "ViD return: build-cost role=$ROLE slice=$SLICE step=$STEP brief=$RB rows=$NROWS rows-passed=$NP $COST tool=$TOOL $EFF brief-bytes=$_bb agent=$RA"
  # v0.9.7.2 (3.11, R15): the step's state read at every hand-back — step-rows-passing recorded the first time its rows all pass
  if [ "$STEP" != - ] && [ -f checks/metrics.sh ]; then sh checks/metrics.sh step-state "$STEP" >/dev/null 2>&1 || true; fi
  exit 0
fi

B=${1:-}
[ -n "$B" ] && [ -f "$B" ] || { echo "ViD brief: usage — sh checks/brief.sh <brief-file> [--at <sha>] (no such file: '${B:-}')" >&2; exit 2; }
AT=''
[ "${2:-}" = --at ] && AT=${3:-}
FAILS=''
bad() { FAILS="$FAILS$1
"; }
hval() { sed -n "1,12s/^.*$1:[[:space:]]*//p" "$B" | head -n 1 | sed 's/[[:space:]]\{2,\}[a-z -]*:.*$//;s/[[:space:]]*$//'; }
ROLE=$(hval role); SLICE=$(hval slice); QAT=$(hval quoted-at)
grep -qE '^receives:' "$B" || bad "header: no 'receives:' line"
grep -qE 'must not receive:' "$B" || bad "header: no 'must not receive:' field"
[ -n "$SLICE" ] || bad "header: no 'slice:' field"
[ -n "$QAT" ] || bad "header: no 'quoted-at:' line"
case "$ROLE" in builder|fixer|grader|test-author|test-analyst) ;; '') bad "header: no 'role:' field" ;; *) bad "header: role '$ROLE' is none of builder, fixer, grader, test-author, test-analyst" ;; esac
REF=${AT:-$QAT}
if [ -n "$REF" ] && ! git cat-file -e "$REF^{commit}" 2>/dev/null; then bad "header: quoted-at '$REF' resolves to no commit"; REF=''; fi
PBIRTH=$(hval pending-birth); PAPPEND=$(hval pending-append)
# v0.9.7.0.5 (3.3, R6): a written brief's stamp — the hash of the file without its `written:` line
if grep -q '^written: brief\.sh write ' "$B"; then
  WH=$(sed -n 's/^written: brief\.sh write \([0-9a-f]*\)[[:space:]]*$/\1/p' "$B" | head -n 1)
  CH=$(awk '!d && /^written: brief\.sh write / { d = 1; next } { print }' "$B" | git hash-object --stdin 2>/dev/null)
  [ -n "$WH" ] && [ "$WH" = "$CH" ] || bad "changed after writing — write it again (sh checks/brief.sh write …): the stamp reads '$WH', the file hashes to '$CH'"
fi

# the independence paragraph, whitespace-normalised, for fresh-context roles
case "$ROLE" in grader|test-author)
  PARAS=$(awk 'NF==0 { if (p!="") print p; p=""; next } { p = (p=="" ? $0 : p " " $0) } END { if (p!="") print p }' "$B" | tr -s ' ')
  printf '%s\n' "$PARAS" | grep -qxF "$HDR" || bad "$ROLE brief: the independence paragraph is missing or not verbatim (checks/selftest/cases/passes.sh HEADER)" ;;
esac

sect() { awk -v n="$1" '/^## [0-9]/ { on = ($2 == n) ; next } on' "$B"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
at() { # $1=path → the file at REF (empty when absent)
  [ -n "$REF" ] && git show "$REF:$1" 2>/dev/null || true
}
at INVENTORY.md | sed -n '/^```vid-inventory/,/^```$/p' | sed '1d;$d' > "$T/inv.ref"
[ -f INVENTORY.md ] && sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' > "$T/inv.wt" || : > "$T/inv.wt"
at PRD.md > "$T/prd.ref"; [ -f PRD.md ] && cp PRD.md "$T/prd.wt" || : > "$T/prd.wt"
PRDSH=checks/prd.sh
if [ -f "$PRDSH" ]; then
  sh "$PRDSH" --effective "$T/prd.ref" > "$T/eff.ref" 2>/dev/null || : > "$T/eff.ref"
  sh "$PRDSH" --effective "$T/prd.wt" > "$T/eff.wt" 2>/dev/null || : > "$T/eff.wt"
else
  : > "$T/eff.ref"; : > "$T/eff.wt"; bad "checks/prd.sh is missing — the effective-set reader the item comparison needs"
fi
at DECISIONS.md > "$T/dec.ref"
at CLAUDE.md > "$T/law.ref"
inlist() { printf ' %s ' "$2" | tr ',' ' ' | grep -qF " $1 "; }

# 1. rows, byte-identical
for l in $(sect 1 | grep -E '^ROW-[0-9A-Za-z-]+[[:space:]]*\|' || true); do
  id=$(printf '%s\n' "$l" | sed 's/[[:space:]]*|.*//')
  if grep -qxF -- "$l" "$T/inv.ref"; then continue; fi
  if grep -qE "^[[:space:]]*$id[[:space:]]*\|" "$T/inv.ref"; then bad "row $id: not byte-identical to the INVENTORY block at ${REF:-?} — a brief quotes, it never summarises: $l"; continue; fi
  if [ "$ROLE" = test-author ]; then
    if grep -qxF -- "$l" "$T/inv.wt"; then continue; fi
    if inlist "$id" "$PBIRTH" && ! grep -qE "^[[:space:]]*$id[[:space:]]*\|" "$T/inv.wt"; then continue; fi
    bad "row $id: absent at ${REF:-?}, not in the working tree's INVENTORY.md, and not listed pending-birth:"
  else
    bad "row $id: absent from the INVENTORY block at ${REF:-?}"
  fi
done
# 2. items: enriched rows byte-identical to the effective set; legacy blocks verbatim
for l in $(sect 2 | grep -E '^REQ-[0-9]+[[:space:]]*\|' || true); do
  id=$(printf '%s\n' "$l" | sed 's/[[:space:]]*|.*//')
  grep -qxF -- "$l" "$T/eff.ref" && continue
  if [ "$ROLE" = test-author ] && grep -qxF -- "$l" "$T/eff.wt" && inlist "$id" "$PAPPEND"; then continue; fi
  if [ "$ROLE" = test-author ] && grep -qxF -- "$l" "$T/eff.wt"; then bad "item $id: differs from or is absent at ${REF:-?} and matches only the working tree — list it pending-append:"; continue; fi
  bad "item $id: not byte-identical to the effective row at ${REF:-?} (checks/prd.sh --effective) — a paraphrased Fail-if is a summary: $l"
done
sect 2 > "$T/s2"
awk -v ref="$T/eff.ref" '
  BEGIN { while ((getline l < ref) > 0) all = all l "\n" }
  function flush() { if (b != "" && index(all, b) == 0) print h; b = ""; h = "" }
  /^### REQ-[0-9]+/ { flush(); h = $0; b = $0 "\n"; next }
  h != "" && NF == 0 { flush(); next }
  h != "" { b = b $0 "\n" }
  END { flush() }' "$T/s2" > "$T/badblocks"
# v0.9.7.0.5 (3.4): a test-author's legacy block may come from the working tree's effective set, listed pending-append:
if [ "$ROLE" = test-author ] && [ -s "$T/badblocks" ]; then
  awk -v ref="$T/eff.wt" '
    BEGIN { while ((getline l < ref) > 0) all = all l "\n" }
    function flush() { if (b != "" && index(all, b) == 0) print h; b = ""; h = "" }
    /^### REQ-[0-9]+/ { flush(); h = $0; b = $0 "\n"; next }
    h != "" && NF == 0 { flush(); next }
    h != "" { b = b $0 "\n" }
    END { flush() }' "$T/s2" > "$T/badwt"
fi
for h in $(cat "$T/badblocks"); do
  if [ "$ROLE" = test-author ] && ! grep -qxF -- "$h" "$T/badwt"; then
    id=$(printf '%s\n' "$h" | sed 's/^### \(REQ-[0-9]*\).*/\1/')
    inlist "$id" "$PAPPEND" && continue
    bad "item block '$h': differs from or is absent at ${REF:-?} and matches only the working tree — list it pending-append:"; continue
  fi
  bad "item block '$h': not verbatim in the effective block at ${REF:-?}"
done
# 3. decisions, verbatim; a grader gets each decision's rule — the line up to ' | why:', matched whole (v0.9.7.0.5 3.4, R5)
awk '/^- \*\*D-/ { i = index($0, " | why:"); print (i ? substr($0, 1, i - 1) : $0) }' "$T/dec.ref" > "$T/rules.ref"
for l in $(sect 3 | grep -E '^- \*\*D-' || true); do
  if [ "$ROLE" = grader ]; then
    case "$l" in *' | why:'*) bad "decision: a grader gets a decision's rule, never its why: quote the line up to ' | why:': $l"; continue ;; esac
    grep -qxF -- "$l" "$T/rules.ref" || bad "decision: not the rule part of a decision line in DECISIONS.md at ${REF:-?} — quote the line up to ' | why:', whole: $l"
  else
    grep -qxF -- "$l" "$T/dec.ref" || bad "decision: not present verbatim in DECISIONS.md at ${REF:-?}: $l"
  fi
done
# 4. laws, quoted line for line from CLAUDE.md
for l in $(sect 4 | grep -v '^[[:space:]]*$' || true); do
  grep -qxF -- "$l" "$T/law.ref" || bad "law: not a line of CLAUDE.md at ${REF:-?} — quote the law, never restate it: $l"
done
# the grader's withholding (GRADING.md's shared rule)
if [ "$ROLE" = grader ]; then
  grep -qE '^## 7([^0-9]|$)' "$B" && bad 'grader brief: carries item 7, the attempt record — a grader never sees prior verdicts, counterexamples or fixes'
  grep -n '\.vid/verdicts/' "$B" | grep -v 'must not receive:' | head -n 1 | while IFS= read -r x; do echo "grader brief: names a .vid/verdicts/ path (line ${x%%:*})"; done >> "$T/g"
  grep -n 'result=' "$B" | grep -v 'must not receive:' | head -n 1 | while IFS= read -r x; do echo "grader brief: carries a result= token (line ${x%%:*}) — a prior verdict"; done >> "$T/g"
  grep -n 'owed: reverted —' "$B" | grep -vF "$WITHHELD" | head -n 1 | while IFS= read -r x; do echo "grader brief: a legacy reversion reason travels (line ${x%%:*}) — only 'owed: reverted — $WITHHELD'"; done >> "$T/g"
  [ -f "$T/g" ] && for x in $(cat "$T/g"); do bad "$x"; done
  grep -qF -- "$EXCL" "$B" || grep -qF -- "$EXCLB" "$B" || bad "grader brief: no stated read exclusion — '$EXCL' (a close batch's: '$EXCLB')"
fi
# v0.9.7.0.2 (3.6, R11): section 6 asks the test manager — requests and waits only, in every role
for l in $(sect 6 | grep 'checks/test\.sh' || true); do
  printf '%s\n' "$l" | sed -E 's#checks/test\.sh[[:space:]]+(request|wait)([[:space:]]|$)##g' | grep -q 'checks/test\.sh' \
    && bad "section 6 runs checks/test.sh directly — nobody runs the test runner directly: make a request (sh checks/test.sh request …, then sh checks/test.sh wait <ticket>): $l"
done
# v0.9.7.0.3 (3.2): the test analyst runs nothing — no test request anywhere in its brief
if [ "$ROLE" = test-analyst ]; then
  for l in $(grep -n 'checks/test\.sh[[:space:]][[:space:]]*request' "$B" || true); do
    bad "test-analyst brief: carries a test request (line ${l%%:*}) — the analyst reads and reports, it requests and runs no test: ${l#*:}"
  done
  # v0.9.7.0.11 (3.7, R7): it names each timeline the ticket it reads kept (timeline.<pass>.log), at the run's home or here
  # v0.9.7.0.12 (3.2, R2): a close batch's chunk is `<ticket>/<n>`, its folder <ticket>/chunks/<n>
  _atk=$(grep -oE '[0-9]{8}T[0-9]{6}Z-[0-9a-f]{4}(/[0-9]+(-retry)?)?' "$B" | head -n 1 | sed 's#/#/chunks/#' || true)
  if [ -n "$_atk" ]; then
    _ah=.; _ag=$(sh checks/plan.sh gate 2>/dev/null || true); case "$_ag" in 'on '*) _ah=${_ag#on } ;; esac
    for _tl in "$_ah/.vid/requests/$_atk"/timeline.*.log ".vid/requests/$_atk"/timeline.*.log; do
      [ -f "$_tl" ] || continue
      grep -qF "${_tl##*/}" "$B" || bad "test-analyst brief: does not name ${_tl##*/}, which ticket $(printf '%s' "$_atk" | sed 's#/chunks/#/#') kept — the analyst receives each pass's timeline"
    done
  fi
fi
# v0.9.7.0.7 (3.2): a builder's sections 9–11, when present, against their sources at quoted-at (12 is the run manager's words)
if [ "$ROLE" = builder ] && [ -n "$REF" ]; then
  if grep -qE '^## 9([^0-9]|$)' "$B"; then
    sect 1 | grep -E '^ROW-' > "$T/b.rows" || : > "$T/b.rows"
    locs "$T/b.rows" "$REF" > "$T/b.s9"; sect 9 | grep -v '^[[:space:]]*$' > "$T/b.got" || : > "$T/b.got"
    cmp -s "$T/b.s9" "$T/b.got" || bad "section 9: the test locations differ from the ledger at $REF — recomputed: $(diff "$T/b.s9" "$T/b.got" | grep '^[<>]' | head -n 1)"
  fi
  if grep -qE '^## 10([^0-9]|$)' "$B"; then
    BPH=$(sect 10 | sed -n 's/^plan:[[:space:]]*\([0-9a-f]*\)[[:space:]]*$/\1/p' | head -n 1)
    if [ -z "$BPH" ] || [ ! -f ".vid/plans/$BPH.plan" ]; then bad "section 10: names no kept plan (plan: '${BPH:-}', .vid/plans/<hash>.plan)"
    else
      at ARCHITECTURE.md > "$T/arch.ref"
      for l in $(sect 10 | grep -v '^[[:space:]]*$' | grep -v '^plan:' || true); do
        printf '%s\n' "$l" | grep -qE '^\(\+[0-9]+ rows: ARCHITECTURE\.md\)$' && continue   # v0.9.7.1 (3.2f): the truncation marker
        grep -qxF -- "$l" ".vid/plans/$BPH.plan" || grep -qxF -- "$l" "$T/arch.ref" || bad "section 10: neither a line of .vid/plans/$BPH.plan nor of ARCHITECTURE.md at $REF: $l"
      done
    fi
  fi
  for l in $(sect 11 | grep -v '^[[:space:]]*$' || true); do
    case "$l" in rule*) grep -qxF -- "$l" "$T/inv.ref" && continue ;; esac
    bad "section 11: not a rule row of INVENTORY.md at $REF, verbatim: $l"
  done
fi
# v0.9.7.1 (3.2f, R2): a section 5 line over 300 characters ends with the generated marker
case "$ROLE" in builder|fixer)
  sect 5 | awk -v mk='… (receipt)' 'length($0) > 300 && substr($0, length($0) - length(mk) + 1) != mk { print NR }' > "$T/long"
  for x in $(cat "$T/long"); do bad "section 5: a line over 300 characters does not end with the marker '… (receipt)' (its line $x)"; done ;;
esac
# v0.9.7.1 (3.4c, R4): a continuation names a package whose manifest still hashes as briefed
if grep -qE '^## 14([^0-9]|$)' "$B"; then
  _pk=$(sect 14 | sed -n 's/^package: \([^ ]*\)    manifest: \([0-9a-f]*\)$/\1/p' | head -n 1); _mh=$(sect 14 | sed -n 's/^package: [^ ]*    manifest: \([0-9a-f]*\)$/\1/p' | head -n 1)
  if [ -z "$_pk" ] || [ ! -f "$_pk/manifest" ]; then bad "section 14: names no continuation package with a manifest (package: '${_pk:-}')"
  elif [ "$(git hash-object "$_pk/manifest")" != "$_mh" ]; then bad "section 14: the package's manifest $_pk/manifest no longer hashes to $_mh — it changed after the brief was written"; fi
fi
# v0.9.7.0.10 (3.6, R13): a harness-upgrade section names the harness it changes, as it was at quoted-at
if grep -qE '^## 13([^0-9]|$)' "$B" && [ -n "$REF" ]; then
  BHH=$(sect 13 | sed -n 's/^harness: docker-compose\.test\.yml[[:space:]]*hash: \([0-9][0-9]*\).*/\1/p' | head -n 1)
  [ -n "$BHH" ] && [ "$BHH" = "$(at docker-compose.test.yml | cksum | cut -d' ' -f1)" ] || bad "section 13: the harness hash '${BHH:-}' is not docker-compose.test.yml's at $REF — an upgrade is briefed on the harness it changes"
fi
# v0.9.8 (3.3, R5): section 15 — each answer line an answer row of PRD.md at quoted-at, verbatim (a test-author's may
# be the working tree's, listed pending-append:); each design line a row of section 1, a marker of its marker field,
# and files present at quoted-at holding that marker
if grep -qE '^## 15([^0-9]|$)' "$B"; then
  for l in $(sect 15 | grep -E '^A-[0-9]+' || true); do
    id=$(printf '%s\n' "$l" | sed 's/[[:space:]]*|.*//; s/[[:space:]]*AMENDED$//')
    grep -qxF -- "$l" "$T/prd.ref" && continue
    if [ "$ROLE" = test-author ] && grep -qxF -- "$l" "$T/prd.wt" && inlist "$id" "$PAPPEND"; then continue; fi
    bad "section 15: answer $id is not an answer row of PRD.md at ${REF:-?}, verbatim: $l"
  done
  for l in $(sect 15 | grep -E '^components ' || true); do   # v0.9.8.1 (R19): apart from the markers; each file present
    _fl=${l#components }; _fl=${_fl#* }; [ "$_fl" = none ] && continue
    for _f in $(printf '%s\n' "$_fl" | tr ',' '\n'); do [ -n "$REF" ] && git cat-file -e "$REF:$_f" 2>/dev/null || bad "section 15: the component canvas $_f is not present at ${REF:-?}: $l"; done
  done
  for l in $(sect 15 | grep -E '^ROW-' || true); do
    id=${l%% *}; _rest=${l#* }; _m=${_rest%% *}; _fl=${_rest#* }
    _rl=$(sect 1 | grep -E "^[[:space:]]*$id[[:space:]]*\|" | head -n 1)
    [ -n "$_rl" ] || { bad "section 15: $id is no row of section 1: $l"; continue; }
    printf '%s\n' "$_rl" | awk -F'|' -v m="$_m" '{ x = $5; gsub(/^[ \t]+|[ \t]+$/, "", x); n = split(x, a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] == m) f = 1 } END { exit f ? 0 : 1 }' || { bad "section 15: $_m is not a marker of $id: $l"; continue; }
    [ "$_fl" = none ] && continue
    for _f in $(printf '%s\n' "$_fl" | tr ',' '\n'); do
      [ -n "$REF" ] && mfiles "$REF" "$_m" | tr ',' '\n' | grep -qxF -- "$_f" || bad "section 15: $_f does not hold $_m at ${REF:-?}: $l"
    done
  done
fi
# v0.9.8 (3.5, R8): section 17 quotes whole entries of .vid/test-lessons.md; section 18 names rows of INVENTORY.md
if grep -qE '^## 17([^0-9]|$)' "$B"; then
  if [ -f .vid/test-lessons.md ]; then
    sect 17 | awk -v lf=.vid/test-lessons.md 'BEGIN { while ((getline l < lf) > 0) all = all l "\n" }
      function flush() { if (b != "" && index(all, b) == 0) print h; b = "" }
      /^## L-[0-9]+/ { flush(); h = $0; b = $0 "\n"; next } b != "" && NF == 0 { next } b != "" { b = b $0 "\n" } END { flush() }' > "$T/badl"
    for x in $(cat "$T/badl"); do bad "section 17: the lesson '$x' is not .vid/test-lessons.md's, whole"; done
  else bad 'section 17: quotes lessons, and there is no .vid/test-lessons.md'; fi
fi
for l in $(sect 18 | grep -E '^ROW-' || true); do
  grep -qE "^[[:space:]]*${l%% *}[[:space:]]*\|" "$T/inv.ref" || bad "section 18: ${l%% *} is no row of INVENTORY.md at ${REF:-?}"
done
# the attempt record travels to builders and fixers
case "$ROLE" in builder|fixer)
  S7=$(sect 7)
  for l in $(sect 1 | grep -E '^ROW-' || true); do
    id=$(printf '%s\n' "$l" | sed 's/[[:space:]]*|.*//')
    [ -f ".vid/verdicts/$id.md" ] || continue
    [ -n "$S7" ] || { bad "$ROLE brief: $id has an attempt record (.vid/verdicts/$id.md) and the brief has no item 7 — the history travels with the row"; continue; }
    for rl in $(grep -v '^[[:space:]]*$' ".vid/verdicts/$id.md"); do
      printf '%s\n' "$S7" | grep -qxF -- "$rl" || { bad "$ROLE brief: item 7 does not quote .vid/verdicts/$id.md whole (missing: $rl)"; break; }
    done
  done ;;
esac

# v0.9.6: the admission, only for a brief whose own checks passed
ADMITTED=''
if [ -z "$FAILS" ] && [ -z "$AT" ] && [ -f checks/plan.sh ]; then
  case "$ROLE" in builder|fixer)
    if ADMITTED=$(sh checks/plan.sh admit --brief "$B" 2>&1); then :; else for x in $ADMITTED; do bad "$x"; done; ADMITTED=''; fi ;;
  esac
fi

mkdir -p .vid
if [ -n "$FAILS" ]; then
  printf 'brief-check path=%s result=fail at=%s\n' "$B" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
  echo "ViD brief: rejected — $B:" >&2
  printf '%s' "$FAILS" | sed 's/^/    /' >&2
  exit 1
fi
printf 'brief-check path=%s result=ok at=%s\n' "$B" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
echo "ViD brief: ok — $B (role $ROLE, quoted at ${REF})"
[ -n "$ADMITTED" ] && printf '%s\n' "$ADMITTED"
exit 0
