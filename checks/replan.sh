#!/bin/sh
# Purpose: GitHub manual's re-plan analysis and its apply (GM-3 U3, U4, U5; GM M10): what the analysis covers, the candidate plan
# checked against the re-plan rules, the proposal and its page, and the apply move on the owner's one yes. Run at the top of ViD's
# repository, in GitHub manual alone (lib.sh manual). All but apply record nothing and post nothing: no event, no plan change,
# nothing under .vid/plan/ or .vid/plans/, no call to GitHub; analyse writes only .vid/next/proposal/ (whole) and its page, .vid/pages/REPLAN-PAGE.html. The rules are read where they stand
# (skills/vid-replan/SKILL.md says where); this script holds the checks.
#   scope [<kind> [<subject>]]… [without #<n> <id> | without <step>]…
#              FB-4 A3, A4: first, before every other read, what the analysis and its apply need, met or missing, one line each, none of
#              which refuses (what refuses, refuses after the list, in its own words): `needs <what> <met|missing> <analysis|apply>
#              <who supplies it: owner, ViD or team> <what stands, or the command>`, what being read (kept, of this call, whole), spec
#              (committed, readable at HEAD, the stage court's own, the applied version named; no export is made or read), records (the
#              writer's at HEAD, next.sh pending, changes and triggers), folder (B1's read kept, the spec the folder holds) and accepted
#              (the tickets closed and not accepted) for the analysis, folder and accepted never ending it; call (the call's stage),
#              engines, settings (writer.sh gate less the ratification, and the issue form at HEAD) and publish (layout: one with
#              spec-publish: hand, the team's, after the apply) for the apply. Then
#              what an analysis with these arguments covers, tab-separated, one line each: `target <HEAD>`, `applied <commit>`;
#              next.sh pending's lines as it prints them (a failure, or an `unread` line, refuses: nothing pending is never read
#              from a failed read); `moved-stage <id> <stage at the applied commit> <stage at HEAD>` for each row whose stage the
#              planner's rows table gives otherwise at HEAD (GM-3 U1's moved-stage, read from the same two tables); `to-place <id>
#              <place> <words>` (.vid/tw/to-place); `team-in #<n> <id> <evidence>`, each team addition next.sh changes lists
#              pending-only (U5) that the analysis takes into ticket n's step, and `team-out #<n> <id>` for one the owner names
#              without; `trigger <tier> <what> <subject> <evidence>` for each trigger covered: by default every critical and
#              important one, and to-place-active and stage-to-correct, not declined (next.sh triggers' trigger and quiet lines), else those of the kinds named (a subject
#              given narrows a kind to it; a kind named that no trigger raises refuses); `ticket #<n> <step> <rows>` for each open
#              published ticket (its newest log line's step= and rows=, not withdrawn, not CLOSED in the call's read). GM M16:
#              an `unread` line of any part but due, in the call's read, next.sh changes or next.sh triggers, refuses,
#              naming it, and no read kept refuses as `unread read`, so an addition a ticket's body holds is never left out unseen. `review
#              needed|none`, needed when `planner.sh rows --added --at HEAD` prints rows. The pending changes and the to-place
#              rows are always covered: the apply makes HEAD the applied version, so each is placed or left either way
#   check <block>   the candidate against the newest spec (HEAD), one line a breach, `<rule> <id> — <why>`, rule-1, rule-2,
#              rule-4 and rule-6; then the warnings, never refusals, `size <#n or step> — <why>` and `builds <row> — <why>`. The
#              candidate's other files are read beside the block, each optional: PLAN.md (else HEAD's), changes, left, taken-out
#              (forms below). rule-1: planner.sh check --block <block> --at HEAD --plan-md <PLAN.md> clean, but for its size
#              flags (warnings, GM M4) and its place flags for a row the to-place list holds in the owner's words (the planner
#              drops those), a row the candidate leaves in no step with why (left's no-step), and a published row a landed
#              re-cut moved, left in its ticket (an other-stage row, left alone; the apply puts it on the list); a place flag of
#              another stage in a step the ratified plan does not hold is a new step in two stages, one line for the step. rule-4:
#              that flag in a step the ratified plan holds, `<row> — in step <s> of stage <k>; HEAD's spec gives it stage <j>`;
#              and a row named taken out that is still in its ticket's step; and a row .vid/tw/to-place holds as
#              other-stage that the candidate moves from its ratified step into another step not of its HEAD stage, though the
#              planner drops its flag. rule-2: each row of an open published ticket is in that ticket's step, unless HEAD's
#              inventory no longer holds it (retired), .vid/next/team-answers holds the owner's yes moving it out (dropped from
#              that ticket, or added to another), recorded after the ticket's newest published or amended line, or a landed re-cut
#              moved its stage and the candidate names it taken out (only the first field of a taken-out line is read) into a step
#              of its HEAD stage, never into no step; a row named taken out that no re-cut moved is a breach too. The top-up of an open
#              ticket (its step's rows the step's open tickets' rows= do not hold, on its newest ticket) is a size warning when
#              `writer.sh topup <added> <tests>` flags it, the one rule (GM-2 T6; its case manual-topup-size); a top-up row sharing no requirement (the rows table's items at
#              HEAD) and no module (a row's module: field; the step's modules: in the ratified block, never the candidate's) with
#              the ticket's rows is a builds warning, the
#              requirements side by side. rule-6: each step the candidate adds, removes or changes from the ratified block
#              (RUN-STATE's, compared field by field, rows and lists sorted and expanded), its shared: or protected: line, and
#              its PLAN.md when it differs from HEAD's, has a line in changes whose triggers are plan.sh change's (TRIGGERS, read
#              from plan.sh), with an evidence reference in a form plan.sh change takes for any trigger but initial and unknown,
#              and an expected effect. Rules 3 and 5 restrict nothing the check can count
#   analyse [--candidate <dir>] [<kind> [<subject>]]… [without #<n> <id> | without <step>]…   scope's reads, then the candidate
#              (the folder, .vid/next/candidate by default; its block required) checked as check checks it, and refused (exit 1,
#              each line named, nothing written) on a breach and on these: a team-in addition not in its ticket's step (U5: in by
#              default, out only by `without`; round 2: one whose ticket is no open published ticket, in no step), a team-out one put there, a `without <step>` naming no new step of the candidate,
#              a no-step row of left placed, a left trigger naming no covered trigger, a review needed and missing, or out of
#              form (`none`, or `finding <row ViD added> | <why>` lines), FB-4 A1: placements listed (planner.sh placements write) and no
#              placement/result in the candidate, two readers' (the vid-placement-review skill; a finding refuses nothing; the apply's own
#              proposal needs none). Refused too while HEAD's spec files differ from the
#              working tree's (the analysis targets HEAD). Then .vid/next/proposal/ written whole, and its page rendered
#              (checks/page.sh) to .vid/pages/REPLAN-PAGE.html
#   hash       the hash the apply recomputes and compares (exit 0, 12 hex): over the applied commit, the newest recorded plan
#              (the newest plan-change's hash=), of .vid/tw/log only its ticket lines (published, amended, withdrawn: exactly that
#              set, so a line of a later kind, phase 4's asked lines among them, never stales a proposal), .vid/tw/to-place,
#              .vid/next/team-answers, and of the call's read
#              (.vid/round/read) only each published ticket's state (its `ticket` line's number and state) and its `body` lines,
#              so the team's other work between the two calls never stales it
#   apply --words "<the owner's words>" [--review <file>]   GM-3 U4, the apply move (U6 wires it as `/vid next implement-replan
#              "<words>"`). First, FB-4 A3, each need of the apply that is missing, a `needs` line as scope prints it, which refuses
#              nothing: a post that cannot be made stays owed. The proposal: .vid/next/proposal/ when the analysis made it (made: analysis) and it is fresh (its hash
#              hash prints now, its target HEAD), else refused, exit 4, "analyse again"; with none, or the apply's own, and nothing
#              pending that adds a test (no added or moved-stage row, no pending-only team addition, no breach of the plan as ratified
#              with its retired rows taken out, a row newly to place among them), the apply's own (made: own, `own` below), kept while
#              fresh; made (or made again) by the apply itself, it is shown, never applied: refused, exit 4, "shown again";
#              anything that adds a test refuses, naming it. The review: the analysis's; for its own, while it is `pending`
#              (planner.sh rows --added --at HEAD prints rows) --review <file> is needed, the fresh agent's review its skill step makes
#              (none, or finding lines); a finding not yet shown refuses this apply, is shown, and is kept in the proposal, so the
#              next apply's words keep it. The review must be the one the page showed (review-hash, kept as the page was written): one
#              changed since refuses (exit 1), shown again, before any finding is kept. Then, before anything is recorded: the check again on its block (a rule- line refuses,
#              exit 1), and steps 1 to 5 on a scratch copy of the repository (land.sh's dry run; a refusal there refuses, exit 1).
#              Then, inside the call's stage (vid-connect's, GM-4 F2; with the gate off the apply is refused), in order: (1) .vid/tw/applied set
#              to the target and a line of .vid/tw/applied.log (`<commit>\t<at>\tapply`; the one in force first, `seed`, when the
#              log is empty), the proposal's PLAN.md committed when it differs from HEAD's; (2) .vid/tw/to-place written whole: a row
#              the block puts in a step of its own stage, or moves, off it (FB-4 A1b), the rest kept with their words, left's no-step and other-stage rows put on in the owner's
#              words; (3) each team-in line recorded in .vid/next/team-answers as a yes in the owner's words; (4) for a landed
#              re-cut (pending's spec STAGES.md) RUN-STATE's stage: moved, STAGES.md read at the target commit; the block written and plan.sh change
#              rows recorded with the changes' triggers, evidence and expected effects (skipped when the block is the newest
#              recorded plan); (5) planner.sh review --in the proposal's review, each new finding answered keep in the owner's
#              words, planner.sh page, planner.sh ratify; 4 and 5 are land.sh's one landing step (`land.sh step`, GM-4 F9). A step
#              that fails rolls 1 to 5 back whole. (6) the posts, each through the one ticket path (GM-4 F5, K1: github.sh
#              tw-hand amend <n>|publish <step> --words "<the words>", its preparation its own: the export at the new applied
#              version, the sync, the round's read, the handovers): each ticket the proposal's amend names that writer.sh due
#              owes, amended with the apply as its cause (--cause); GM-4 K13 (J4): with layout: one, before any post, the
#              export and github.sh spec-publish --words <the apply's words> <that export commit> (FB-1 B6: the words on its line; it
#              does nothing more when its export, folder and stamp
#              are published already), `done spec-publish <12 hex>`; a refused publish or export is `owed spec-publish …`, exit 3, and holds
#              every post below (`owed <kind> <subject>: held, …`);
#              each follow-up the proposal names that due owes (`new step <S>`); each step of its publish; a follow-up due owes that
#              the proposal did not show (its ticket closed since the read) is left owed, named, exit 3, for the next call's publish move. A post that fails stays
#              owed (`owed amend #<n>` or `owed publish <S>`, exit 3), for the next call; steps 1 to 5 stand. The proposal is then
#              kept as .vid/next/applied-proposal
#   ready      for the call's listing (U6): `apply\t<analysis|own|analyse|none>\t<the block hash, the pending lines, why, or ->`
#              (analysis: a fresh analysis to apply; own: the apply's own proposal, nothing pending adding a test; analyse: the
#              analysis is needed first, why; none: nothing pending), with own `own\t<fresh|due|refused>\t<why or ->` (FB-3 C5: its
#              proposal made and fresh; not made, or stale; not to be made, .vid/next/own-refused's reason while what the making read
#              stands), then `review\t<needed|none>`, then, with the apply or its own proposal's making listed, its missing engines and
#              settings `needs` lines (FB-4 A3), said with the move before the owner's yes. Records nothing
#   own        the apply's own proposal written into .vid/next/proposal/ (as analyse writes one, made: own; took: the seconds it
#              took, FB-3 C5); refused when anything pending adds a test, or nothing is pending, or it cannot be made (its first
#              refusal line, kept in .vid/next/own-refused with a hash of what the making read). Records and posts nothing
#   The proposal gains (GM-3 U4) made (`analysis` or `own`), review-hash (git hash-object of review, as the page shows it), followup (`<step>\t<rows,>`: each follow-up of a closed ticket the
#   apply will publish, writer.sh due --why's followup lines at the target), and amend lines of kind reached and quoted (its why
#   lines at the target: a reset row as restated, a reached row, a retired one, a writing whose quoted text changed)
# The candidate's files (the conversation writes them, skills/vid-replan/SKILL.md), tab-separated:
#   block      the plan block, in the plan grammar (planner.sh, plan.sh), as the plan is ratified with the changes made
#   PLAN.md    the PLAN.md the candidate needs, when it differs from HEAD's (standing and class lines; a retired row's lines out)
#   changes    `<subject>\t<trigger>[,<trigger>…]\t<evidence ref>[,<ref>…] or -\t<expected effect>`: subject a step id, shared:,
#              protected: or PLAN.md
#   left       `no-step\t<row>\t<why>` a row left in no step; `trigger\t<what> <subject>\t<why>` a covered trigger left alone
#   taken-out  `<row>` a line: a published row a landed re-cut moved, taken out of its ticket into a step of its new stage
#   review     the fresh agent's review of the rows ViD's planner adds at HEAD (planner.sh review --in's form), or `none`
#   placement/ FB-4 A1: the two readers' folder (planner.sh placements), its result the one the proposal keeps
# The proposal, .vid/next/proposal/ (the apply's input, GM-3 U4), tab-separated, each file present, empty when it has nothing:
#   block, PLAN.md (the candidate's, else HEAD's), review (the candidate's, or `none` when no row is added), changes (the
#   candidate's); target (HEAD, the full commit); hash (as `hash` prints it at the analysis); block-hash (the block's lines, their
#   trailing space trimmed, through SHA-256, 12 hex: the plan's hash once the block is RUN-STATE's); args (`kind\t<kind>\t<subject
#   or ->`, `without\t#<n> <id>`, `without\t<step>`); pending (next.sh pending's lines); triggers (`<tier>\t<what>\t<subject>\t
#   <evidence>`, each covered); amend (`<n>\t<added|restated|retired>\t<row>`: added, the ticket's top-up; restated, next.sh
#   differ <n> <target>; retired, a row of its rows= HEAD's inventory lacks); publish (`<step>` a line: each step the ratified
#   block lacks that holds a pending reset, added, reached or moved-stage row, unless named without); taken-out (`<row>\t<n>\t
#   <step>`); team-in (`<n>\t<row>\t<evidence>`: recorded as a yes by the apply, U5); moves (`<row>\t<from step or ->\t<to step or
#   ->`); warnings (`<kind>\t<subject>\t<why>`: size, builds, and each published step's GM M12 warnings, limit, stage-ahead and
#   not-taken, as next.sh triggers gives them on a scratch copy holding the candidate with HEAD applied); left (`<kind>\t<subject>
#   \t<why>`: no-step, other-stage (a re-cut-moved row left in ticket n, subject `<row> #<n>`), kept (a to-place row the plan still
#   leaves, its words; FB-4 A1b: in no step, or in the step of another stage the ratified plan has it in), trigger, team (`#<n> <id>`, without), step (without)); placements (FB-4 A1: the candidate's placement/result, empty with none); REPLAN-PAGE.md (the page's markdown)
# Exit: scope, hash, ready 0; check 0 clean (warnings printed or not), 1 a breach; analyse and own 0 written, 1 refused (named);
# apply 0 applied and every post out, 3 applied with a post left owed, 1 refused (named, nothing recorded), 4 the proposal stale
# (analyse again); 2 usage, or a read that failed (named).
# Usage: sh checks/replan.sh scope [<args>] | check <block> | analyse [--candidate <dir>] [<args>] | hash | apply --words "<words>" [--review <file>] | ready | own
# serves: tickets
set -eu
LC_ALL=C; export LC_ALL
# GM-3 U6: a next.sh triggers run beneath the re-plan never asks replan.sh ready for implement-replan's line (no loop, no second read)
VID_NEXT_NOREADY=1; export VID_NEXT_NOREADY
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; trap 'exit 1' INT TERM
TAB=$(printf '\t')
die() { echo "ViD replan: $*" >&2; exit 2; }
ref() { echo "ViD replan: refused — $*" >&2; exit 1; }
usage() { die 'usage — sh checks/replan.sh scope [<kind> [<subject>]]… [without #<n> <id> | without <step>]… | check <block> | analyse [--candidate <dir>] [<kind> [<subject>]]… [without …]… | hash | apply --words "<words>" [--review <file>] | ready | own'; }
SPECF='PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md PLAN.md'
# the trigger kinds next.sh triggers raises (its header's list)
KINDS='reset-taken retired-taken blocked close-twice close-shrink lane-gone to-place-active added-active stage-to-correct reset-not-taken reached-closed team-added team-dropped not-taken team-no-lane reached-open added-inactive reset-inactive record'
TRIM='function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }'
KEY="$TRIM"' function key(l,   a, k) { split(l, a, "|"); k = tr(a[1]); return (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr(a[2]) : k }'
sha() { if command -v shasum > /dev/null 2>&1; then shasum -a 256; else sha256sum; fi | cut -c1-12; }

# hash_: the apply's hash (GM-3 U3)
hash_() { { printf '== applied\n'; applied; printf '== plan\n'; grep '^plan-change ' .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/^plan-change what=[^ ]* hash=\([0-9a-f]*\) .*/\1/p'
    printf '== log\n'; awk '$1 == "published" || $1 == "amended" || $1 == "withdrawn"' .vid/tw/log 2>/dev/null || :; printf '== to-place\n'; cat .vid/tw/to-place 2>/dev/null || :
    printf '== team-answers\n'; cat .vid/next/team-answers 2>/dev/null || :
    printf '== read\n'; awk -F'\t' '$1 == "ticket" { print "ticket\t" $2 "\t" $3 } $1 == "body"' .vid/round/read 2>/dev/null || :; } | git hash-object --stdin | cut -c1-12; }

# BP: a plan block parsed, one line a step, `<id>\t<rows>\t<its fields, each trimmed, lists expanded and sorted, sorted by
# name>\t<modules>`, and `<shared:|protected:>\t\t<its value, sorted>\t`; needs lines are the rows' and are not compared
BP="$RNG$TRIM"'
  function ex(v,   m, a, j, o) { gsub(/[\t,]/, " ", v); m = split(v, a, " "); o = ""; for (j = 1; j <= m; j++) if (a[j] != "" && a[j] != "-") o = o " " rng(a[j]); return substr(o, 2) }
  function srt(v,   m, a, i, j, x, o) { m = split(v, a, " "); for (i = 2; i <= m; i++) { x = a[i]; for (j = i - 1; j >= 1 && a[j] > x; j--) a[j + 1] = a[j]; a[j + 1] = x }
    o = ""; for (i = 1; i <= m; i++) o = o (o == "" ? "" : " ") a[i]; return o }
  { l = tr($0) }
  l ~ /^step[ \t]/ { m = split(l, f, "|"); id = tr(f[1]); sub(/^step[ \t]+/, "", id); rows = ""; mods = ""; nk = 0; split("", K)
    for (j = 2; j <= m; j++) { x = tr(f[j]); k = x; sub(/:.*/, "", k); v = x; sub(/^[^:]*:/, "", v); v = tr(v)
      if (k == "rows") { rows = srt(ex(v)); v = rows } else if (k == "builds-on" || k == "fakes" || k == "modules") { v = srt(ex(v)); if (k == "modules") mods = v }
      K[++nk] = k ": " v }
    for (i = 2; i <= nk; i++) { x = K[i]; for (j = i - 1; j >= 1 && K[j] > x; j--) K[j + 1] = K[j]; K[j + 1] = x }
    o = ""; for (i = 1; i <= nk; i++) o = o " | " K[i]; print id "\t" rows "\t" substr(o, 4) "\t" mods; next }
  l ~ /^(shared|protected):/ { k = l; sub(/:.*/, "", k); v = l; sub(/^[^:]*:/, "", v); print k ":\t\t" srt(ex(v)) "\t" }'

# tickets_ <out>: each open published ticket, `<n>\t<step>\t<rows, space-separated>\t<its at=>`: its newest published or amended log line,
# not withdrawn, not CLOSED in the call's read
tickets_() { awk -v RD=.vid/round/read 'BEGIN { while ((getline l < RD) > 0) { split(l, a, "\t"); if (a[1] == "ticket" && a[3] == "CLOSED") C[a[2]] = 1 } }
    $1 == "withdrawn" { W[$2] = 1 } ($1 == "published" || $1 == "amended") { L[$2] = $0 }
    END { for (n in L) if (!(n in W) && !(n in C)) { s = ""; r = ""; t = ""; m = split(L[n], f, " "); for (j = 3; j <= m; j++) { if (f[j] ~ /^step=/) s = substr(f[j], 6); if (f[j] ~ /^rows=/) r = substr(f[j], 6); if (f[j] ~ /^at=/ && t == "") t = substr(f[j], 4) }
      gsub(/,/, " ", r); print n "\t" s "\t" r "\t" t } }' .vid/tw/log 2>/dev/null | sort -n > "$1"; }

# reads_: the reads every subcommand but hash shares, into $T: rh, ra (the rows tables at HEAD and at the applied commit), md
# (`<id>\t<module>` at HEAD), tk (tickets_), rb (the ratified block), rs (it parsed), hpm (HEAD's PLAN.md)
reads_() {
  manual || ref 'the re-plan runs in GitHub manual alone'
  A=$(applied); [ -n "$A" ] && git rev-parse -q --verify "$A^{commit}" > /dev/null 2>&1 || ref 'no applied version: .vid/tw/applied names no commit of this repository (/vid mode manual records it)'
  HD=$(git rev-parse -q --verify HEAD^{commit} 2>/dev/null) || ref 'this repository has no commit'
  lread "$T/rh" planner rows --at HEAD || exit 2; lread "$T/ra" planner rows || exit 2
  git show HEAD:INVENTORY.md 2>/dev/null | awk "$KEY"' /^```vid-inventory/ { b = 1; next } b && /^```/ { b = 0; next }
    b { k = key($0); n = split($0, a, "|"); for (j = 1; j <= n; j++) { x = tr(a[j]); if (x ~ /^module:/) { sub(/^module:[ \t]*/, "", x); if (k != "" && x != "") print k "\t" x } } }' > "$T/md" || :
  tickets_ "$T/tk"; plan_block > "$T/rb"; awk "$BP" "$T/rb" > "$T/rs"
  git show HEAD:PLAN.md > "$T/hpm" 2>/dev/null || : > "$T/hpm"
}

# judge <block>: the check's lines into $T/jo (breaches first: rule-1, rule-2, rule-4, rule-6; then size and builds), and into $T/side
# what analyse reads: `moved\t<row>\t<from>\t<to>`, `no-step\t<row>`, `other-stage\t<row>\t<n>\t<stage>`, `topup\t<n>\t<row>\t<step>`;
# $T/cs the candidate parsed, $T/cpm its PLAN.md. Needs reads_
judge() {
  B=$1; D=$(dirname "$B"); [ -f "$B" ] || die "no candidate block at $B"
  awk "$BP" "$B" > "$T/cs"
  if [ -f "$D/PLAN.md" ]; then cp "$D/PLAN.md" "$T/cpm"; else cp "$T/hpm" "$T/cpm"; fi
  PMD=''; cmp -s "$T/cpm" "$T/hpm" || PMD=1
  RC=0; sh "$HERE/planner.sh" check --block "$B" --at HEAD --plan-md "$T/cpm" > "$T/pk" 2> "$T/pke" || RC=$?
  [ "$RC" -le 1 ] || { sed 's/^/    /' "$T/pke" "$T/pk" >&2; die 'planner.sh check could not read the candidate'; }
  # GM-4 F10: each candidate step's stage is the planner's (planner.sh steps), never worked out here again
  sh "$HERE/planner.sh" steps --block "$B" --at HEAD --plan-md "$T/cpm" > "$T/pst" 2> "$T/pke" || { sed 's/^/    /' "$T/pke" >&2; die "planner.sh steps could not read the candidate's steps"; }
  for f in changes left taken-out; do if [ -f "$D/$f" ]; then tr -d '\r' < "$D/$f" > "$T/c-$f"; else : > "$T/c-$f"; fi; done
  awk -F'\t' '$5 == "yes"' .vid/next/team-answers > "$T/ta" 2>/dev/null || : > "$T/ta"
  TRIGS=$(sed -n "s/^TRIGGERS='\(.*\)'\$/\1/p" "$HERE/plan.sh" | head -n 1); [ -n "$TRIGS" ] || die "plan.sh's triggers could not be read"
  awk -F'\t' -v PK="$T/pk" -v CS="$T/cs" -v RSF="$T/rs" -v TK="$T/tk" -v RH="$T/rh" -v RA="$T/ra" -v MD="$T/md" -v TA="$T/ta" \
    -v LF="$T/c-left" -v TO="$T/c-taken-out" -v CH="$T/c-changes" -v PMD="$PMD" -v TRIGS="$TRIGS" -v SIDE="$T/side" -v TP=.vid/tw/to-place -v PST="$T/pst" '
    function has(l, x,   m, a, j) { m = split(l, a, " "); for (j = 1; j <= m; j++) if (a[j] == x) return 1; return 0 }
    function cnt(l,   a) { return split(l, a, " ") }
    function br(rule, id, why) { B[rule] = B[rule] rule " " id " \342\200\224 " why "\n" }
    function wn(kind, id, why) { WN = WN kind " " id " \342\200\224 " why "\n" }
    function rd(f, k,   l, n, a) { n = 0; while ((getline l < f) > 0) { L[k, ++n] = l } N[k] = n; close(f) }
    BEGIN {
      # pst: each candidate step'"'"'s own stage, the planner'"'"'s (planner.sh steps)
      rd(PST, "pst"); for (i = 1; i <= N["pst"]; i++) { split(L["pst", i], a, "\t"); pst[a[1]] = a[3] }
      rd(CS, "cs"); for (i = 1; i <= N["cs"]; i++) { split(L["cs", i], a, "\t"); s = a[1]; if (s ~ /:$/) { cx[s] = a[3]; continue } CO[++nc] = s; cst[s] = 1; crow[s] = a[2]; cnm[s] = a[3]; cmo[s] = a[4]; m = split(a[2], r, " "); for (j = 1; j <= m; j++) cin[r[j]] = s }
      rd(RSF, "rs"); for (i = 1; i <= N["rs"]; i++) { split(L["rs", i], a, "\t"); s = a[1]; if (s ~ /:$/) { rx[s] = a[3]; continue } RO[++nr] = s; rst[s] = 1; rnm[s] = a[3]; rmo[s] = a[4]; m = split(a[2], r, " "); for (j = 1; j <= m; j++) rin[r[j]] = s }
      rd(TK, "tk"); for (i = 1; i <= N["tk"]; i++) { split(L["tk", i], a, "\t"); n = a[1]; TO_[++nt] = n; tst[n] = a[2]; trw[n] = a[3]; tat[n] = a[4]; if (!(a[2] in stk) || n + 0 > stk[a[2]] + 0) stk[a[2]] = n; ur[a[2]] = ur[a[2]] " " a[3]
        m = split(a[3], r, " "); for (j = 1; j <= m; j++) tko[r[j], a[2]] = n }
      rd(RH, "rh"); for (i = 1; i <= N["rh"]; i++) { if (L["rh", i] ~ /^#/) continue; split(L["rh", i], a, "\t"); hk[a[1]] = a[2]; hit[a[1]] = a[4]; hst[a[1]] = a[5] }
      rd(RA, "ra"); for (i = 1; i <= N["ra"]; i++) { if (L["ra", i] ~ /^#/) continue; split(L["ra", i], a, "\t"); ast[a[1]] = a[5]; AO[++na] = a[1] }
      for (i = 1; i <= na; i++) { x = AO[i]; if (x !~ /^SEAM-/ && (x in hst) && hk[x] == "row" && hst[x] ~ /^[0-9]+$/ && ast[x] ~ /^[0-9]+$/ && hst[x] != ast[x]) { mv[x] = 1; print "moved\t" x "\t" ast[x] "\t" hst[x] > SIDE } }
      rd(MD, "md"); for (i = 1; i <= N["md"]; i++) { split(L["md", i], a, "\t"); mod[a[1]] = a[2] }
      rd(TA, "ta"); for (i = 1; i <= N["ta"]; i++) { split(L["ta", i], a, "\t"); YN[i] = a[1]; YK[i] = a[2]; YI[i] = a[3]; YT[i] = a[6] }
      rd(LF, "lf"); for (i = 1; i <= N["lf"]; i++) { split(L["lf", i], a, "\t"); if (a[1] == "no-step") lft[a[2]] = 1 }
      rd(TO, "to"); for (i = 1; i <= N["to"]; i++) { x = L["to", i]; split(x, q_, "\t"); x = q_[1]; gsub(/[ \t]/, "", x); if (x != "") out[x] = 1 }
      rd(TP, "tp"); for (i = 1; i <= N["tp"]; i++) { split(L["tp", i], a, "\t"); if (a[2] == "other-stage") tpo[a[1]] = 1 }
      rd(CH, "ch"); for (i = 1; i <= N["ch"]; i++) { x = L["ch", i]; if (x ~ /^[ \t]*$/) continue; n = split(x, a, "\t"); s = a[1]; gsub(/[ \t]/, "", s); chl[s] = 1; ctr[s] = (n >= 2 ? a[2] : ""); cev[s] = (n >= 3 ? a[3] : ""); cex[s] = (n >= 4 ? a[4] : "") }
      # rule 1 and rule 4, from the planner flags
      rd(PK, "pk"); for (i = 1; i <= N["pk"]; i++) { f = L["pk", i]; if (f ~ /^planner: clean/ || f ~ /^[ \t]*$/) continue
        k = f; sub(/ .*/, "", k); id = f; sub(/^[^ ]+ /, "", id); sub(/ .*/, "", id); why = f; p = index(why, " \342\200\224 "); why = (p ? substr(why, p + 5) : why)
        if (k == "size") { wn("size", id, why); continue }
        if (k == "place" && why == "in no step") { if (id in lft) { print "no-step\t" id > SIDE; continue } br("rule-1", id, "in no step, and the candidate neither places it nor leaves it alone with why (left: no-step)"); continue }
        if (k == "place" && match(why, /^in step [^ ]+ of stage [^;]+; its own stage is .+$/)) { s = why; sub(/^in step /, "", s); sub(/ .*/, "", s); ks = why; sub(/^in step [^ ]+ of stage /, "", ks); sub(/;.*/, "", ks); js = why; sub(/.*its own stage is /, "", js)
          n = tko[id, s]; if (n != "" && (id in mv) && !(id in out)) { print "other-stage\t" id "\t" n "\t" js > SIDE; continue }
          if (!(s in rst)) { if (!(s in two)) { two[s] = ks; TW[++ntw] = s } if (!has(two[s], js)) two[s] = two[s] " " js; continue }
          br("rule-4", id, "in step " s " of stage " ks "; HEAD" "\047" "s spec gives it stage " js "; a stage changes only by a landed re-cut"); continue }
        br("rule-1", id, k ": " why) }
      # FB-4 A2: a seam is skipped here and above, its stage being its step'"'"'s. A row the to-place list holds as other-stage, moved from its ratified step into another of another stage
      for (x in tpo) if (x !~ /^SEAM-/ && cin[x] != "" && cin[x] != rin[x] && hst[x] ~ /^[0-9]+$/ && pst[cin[x]] != hst[x]) br("rule-4", x, "in step " cin[x] " of stage " pst[cin[x]] "; HEAD" "\047" "s spec gives it stage " hst[x] "; the to-place list accepted it in step " (rin[x] == "" ? "none" : rin[x]) ", not here")
      for (i = 1; i <= ntw; i++) { s = TW[i]; x = two[s]; gsub(/ /, " and ", x); br("rule-1", s, "a new step whose rows are in stages " x "; every step is in one stage") }
      # rule 2, and each ticket'"'"'s top-up
      for (i = 1; i <= nt; i++) { n = TO_[i]; s = tst[n]; m = split(trw[n], r, " ")
        for (j = 1; j <= m; j++) { x = r[j]; if (cin[x] == s) continue; if (!(x in hk)) continue
          # a yes moving it out counts only when recorded after the ticket'"'"'s newest writing
          ok = 0; for (e = 1; e <= N["ta"]; e++) if (YI[e] == x && YT[e] > tat[n] && ((YK[e] == "dropped" && YN[e] == n) || (YK[e] == "added" && YN[e] != n))) ok = 1; if (ok) continue
          # a re-cut row taken out only into a step of its new stage, HEAD'"'"'s
          if ((x in mv) && (x in out) && cin[x] != "" && pst[cin[x]] == hst[x]) continue
          br("rule-2", x, "in #" n " (step " s "); the candidate puts it " (cin[x] == "" ? "in no step" : "in step " cin[x]) ": a published ticket is only topped up, and nothing is taken from it without the owner" "\047" "s words") } }
      for (x in out) { n = ""; for (i = 1; i <= nt; i++) if (has(trw[TO_[i]], x)) { n = TO_[i]; s = tst[n] }
        if (!(x in mv)) br("rule-2", x, "named taken out, but no landed re-cut moved its stage")
        else if (n != "" && cin[x] == s) br("rule-4", x, "named taken out, yet still in step " s " of #" n) }
      for (s in stk) { if (!(s in cst)) continue; n = stk[s]; add = ""; k = 0; m = split(crow[s], r, " ")
        for (j = 1; j <= m; j++) { x = r[j]; if (has(ur[s], x) || hk[x] != "row") continue; add = add " " x; k++; print "topup\t" n "\t" x "\t" s > SIDE }
        if (!k) continue; t = cnt(trw[n])
        print "size\t" n "\t" k "\t" t "\t" s > SIDE
        rq = ""; md = " " rmo[s] " "; q = split(trw[n], tr_, " "); for (j = 1; j <= q; j++) { y = tr_[j]; if (!(y in hit)) continue; z = split(hit[y], ia, " "); for (e = 1; e <= z; e++) if (!has(rq, ia[e])) rq = rq " " ia[e]; if (mod[y] != "") md = md mod[y] " " }
        z = split(add, ad, " "); for (e = 1; e <= z; e++) { x = ad[e]; sh = 0; w = split(hit[x], ia, " "); for (j = 1; j <= w; j++) if (has(rq, ia[j])) sh = 1; if (mod[x] != "" && index(md, " " mod[x] " ")) sh = 1
          if (!sh) { a1 = hit[x]; gsub(/ /, ", ", a1); if (a1 == "") a1 = "none"; a2 = substr(rq, 2); gsub(/ /, ", ", a2); if (a2 == "") a2 = "none"; wn("builds", x, "a top-up to #" n " (step " s ") sharing no requirement and no module with its rows: its requirements " a1 "; the ticket" "\047" "s " a2) } } }
      # rule 6: each change with its trigger, evidence and expected effect
      for (i = 1; i <= nc; i++) { s = CO[i]; if (!(s in rst) || rnm[s] != cnm[s]) CHG[++ng] = s }
      for (i = 1; i <= nr; i++) { s = RO[i]; if (!(s in cst)) CHG[++ng] = s }
      for (s in cx) if (cx[s] != rx[s]) CHG[++ng] = s; for (s in rx) if (!(s in cx)) CHG[++ng] = s
      if (PMD) CHG[++ng] = "PLAN.md"
      nt2 = split(TRIGS, TG, " "); for (j = 1; j <= nt2; j++) TV[TG[j]] = 1
      for (i = 1; i <= ng; i++) { s = CHG[i]; if (s in seen6) continue; seen6[s] = 1
        if (!(s in chl)) { br("rule-6", s, "the candidate changes it, and no change line gives its trigger, evidence and expected effect"); continue }
        t = ctr[s]; gsub(/[ \t]/, "", t); if (t == "") { br("rule-6", s, "the change has no trigger (triggers: " TRIGS ")"); continue }
        m = split(t, a, ","); need = 0; bad = ""; for (j = 1; j <= m; j++) { if (!(a[j] in TV)) bad = a[j]; if (a[j] != "initial" && a[j] != "unknown") need = 1 }
        if (bad != "") { br("rule-6", s, "\047" bad "\047 is no trigger (triggers: " TRIGS ")"); continue }
        v = cev[s]; gsub(/[ \t]/, "", v); if (v == "-") v = ""
        if (need && v == "") { br("rule-6", s, "the trigger " t " needs an evidence reference (receipt:, question:Q, agent:, refusal:, step:, commit:, ticket:)"); continue }
        m = split(v, a, ","); bad = ""; for (j = 1; j <= m; j++) if (a[j] !~ /^(receipt|question|agent|refusal|step|commit|ticket):[^ ]+$/) bad = a[j]
        if (bad != "") { br("rule-6", s, "\047" bad "\047 is no evidence reference in the forms plan.sh change takes"); continue }
        e = cex[s]; gsub(/^[ \t]+|[ \t]+$/, "", e); if (e == "") br("rule-6", s, "the change has no expected effect") }
      printf "%s%s%s%s%s", B["rule-1"], B["rule-2"], B["rule-4"], B["rule-6"], WN }' < /dev/null > "$T/jo"
  touch "$T/side"
  # each top-up's size flag is writer.sh topup's, the one rule (GM-2 T6); this script only words it
  awk -F'\t' '$1 == "size" { print $2 "\t" $3 "\t" $4 "\t" $5 }' "$T/side" | while IFS="$TAB" read -r n k t s; do
    f=$(sh "$HERE/writer.sh" topup "$k" "$t") || exit 2; [ -n "$f" ] || continue
    case $f in *'more than 5'*) w='over 5' ;; *) w='over a fifth of its tests' ;; esac
    echo "size #$n — a top-up of $k tests to a ticket of $t (step $s): $w; shown to the owner, never refused"; done > "$T/sz" || die 'writer.sh topup could not read a top-up'
  cat "$T/sz" >> "$T/jo"
}

# parseargs <args>: $T/kinds (`<kind>\t<subject or empty>`), $T/wo (`team\t#<n> <id>` or `step\t<step>`), CAND
iskind() { case " $KINDS " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
parseargs() { : > "$T/kinds"; : > "$T/wo"; CAND=.vid/next/candidate
  while [ $# -gt 0 ]; do case $1 in
    --candidate) [ $# -ge 2 ] || usage; CAND=$2; shift 2 ;;
    without) [ $# -ge 2 ] || usage; case $2 in
        '#'*) [ $# -ge 3 ] || usage; case ${2#'#'} in ''|*[!0-9]*) die "without $2: not #<ticket number>" ;; esac; printf 'team\t%s %s\n' "$2" "$3" >> "$T/wo"; shift 3 ;;
        *) printf 'step\t%s\n' "$2" >> "$T/wo"; shift 2 ;; esac ;;
    *) iskind "$1" || die "'$1' is no trigger kind (kinds: $KINDS), nor without"
      if [ $# -ge 2 ] && [ "$2" != without ] && [ "$2" != --candidate ] && ! iskind "$2"; then printf '%s\t%s\n' "$1" "$2" >> "$T/kinds"; shift 2; else printf '%s\t\n' "$1" >> "$T/kinds"; shift; fi ;;
  esac; done; }

# nx_ <file> <next.sh command>: next.sh's output in $T/<file>, read once a run (FB-4 A3: the list of needs and scope_ read the same one)
nx_() { [ -f "$T/$1.rc" ] || { _nr=0; sh "$HERE/next.sh" "$2" > "$T/$1" 2> "$T/$1.e" || _nr=$?; echo "$_nr" > "$T/$1.rc"; }; [ "$(cat "$T/$1.rc")" = 0 ]; }
# needs_ [apply]: FB-4 A3, A4, what an analysis and an apply need (scope's header), or the apply's alone; nd_ <what> <analysis|apply>
# <who> <what is missing, empty when met> [<words when met>]: one line of it
nd_() { printf 'needs\t%s\t%s\t%s\t%s\t%s\n' "$1" "$(if [ -n "$4" ]; then echo missing; else echo met; fi)" "$2" "$3" "$(printf '%s' "${4:-$5}" | tr '\t\n' '  ')"; }
last_() { grep -v '^[[:space:]]*$' "$1" | tail -n 1 | sed 's/^ViD [a-z]*: //; s/^refused — //'; }
join_() { grep . | paste -sd ';' - | sed 's/;/; /g'; }
needs_() { _nh=$(git rev-parse -q --verify HEAD^{commit} 2>/dev/null) || _nh=''; _na=$(applied) || _na=''; git rev-parse -q --verify "${_na:-none}^{commit}" > /dev/null 2>&1 || _na=''; _rd=.vid/round/read; [ -f "$_rd" ] || _rd=/dev/null
  if [ "${1:-}" != apply ]; then
    # read: kept, of this call (connect.sh keeps the read before it as read.prev at the call's start, so a read of this call is newer), whole
    if [ "$_rd" = /dev/null ]; then _w='no read kept'; elif [ -n "$(find .vid/round/read.prev -newer "$_rd" 2>/dev/null)" ]; then _w="the call before's"
    else _w=$(awk -F'\t' '$1 == "unread" && $2 != "due" { printf "%sunread %s %s: %s", (n++ ? "; " : ""), $2, $3, $4 }' "$_rd"); fi
    nd_ read analysis ViD "${_w:+$_w — /vid:vid-read reads GitHub now}" 'GitHub, read in this call'
    # spec: the applied version, the spec files committed, and what the planner cannot read at HEAD, the stage court's refusals among it
    { [ -n "$_na" ] || echo 'no applied version, .vid/tw/applied names no commit of this repository — /vid:vid-mode manual records it'
      _sd=$(specdiff_); [ -z "$_sd" ] || echo "not committed: $(echo $_sd) — commit them"
      _r=0; sh "$HERE/planner.sh" check --at HEAD > "$T/nck" 2> "$T/nce" || _r=$?; awk '$1 == "stages" || $1 == "unread" { print $0 " — a commit of the spec corrects it" }' "$T/nck"; [ "$_r" -le 1 ] || echo "planner.sh check cannot read HEAD: $(last_ "$T/nce")"; } > "$T/nw"
    nd_ spec analysis owner "$(join_ < "$T/nw")" "read at HEAD $(printf %.12s "$_nh"), the team has $(printf %.12s "$_na"); no export is read"
    # records: the writer's own at HEAD, then every part next.sh cannot read that the call's read does not say itself
    { VID_WRITER_AT=${_nh:-HEAD} sh "$HERE/writer.sh" pending > /dev/null 2> "$T/nre" || { last_ "$T/nre" | grep . || echo 'the records cannot be read at HEAD (writer.sh pending)'; }
      [ -z "$_na" ] || for _k in pend:pending chg:changes tg:triggers; do nx_ "${_k%:*}" "${_k#*:}" || grep -q '^unread' "$T/${_k%:*}" || echo "next.sh ${_k#*:}: $(last_ "$T/${_k%:*}.e")"; done
      cat "$T/pend" "$T/chg" "$T/tg" 2>/dev/null | awk -F'\t' -v R="$_rd" 'BEGIN { while ((getline l < R) > 0) { split(l, a, "\t"); if (a[1] == "unread") K[a[2], a[3]] = 1 } }
        $1 == "unread" && $2 != "due" && $2 != "read" && !(($2, $3) in K) { K[$2, $3] = 1; print "unread " $2 " " $3 ": " $4 (($2 == "writing") ? " — /vid:vid-mode manual takes stock again" : "") }'; } > "$T/nw"
    nd_ records analysis ViD "$(join_ < "$T/nw")" 'the records read whole'
    # folder (FB-4 B1, lib.sh foldersay): met while it holds the applied version's spec; else missing, in the words of the call's own context
    # line, and no line while that one is quiet
    if [ -f .vid/round/folder ] && command -v foldersay > /dev/null 2>&1; then _f=$(foldersay 2>/dev/null) || _f=''; _w=$(sed -n "s/^context${TAB}folder$TAB//p" "$T/tg" 2>/dev/null | head -n 1)
      case $_f in '') ;; "holds$TAB"*) nd_ folder analysis owner '' "${_f#*"$TAB"}" ;; *) [ -z "$_w" ] || nd_ folder analysis owner "$_w" ;; esac; fi
    # accepted: a published ticket closed on GitHub and not accepted (next.sh's `context closed`, its command the one that records it)
    _w=$(awk -v M=.vid/decide/merges -v RD="$_rd" 'BEGIN { while ((getline l < M) > 0) { split(l, a, "\t"); if (a[4] != "") A[a[2]] = 1 } while ((getline l < RD) > 0) { split(l, a, "\t"); if (a[1] == "ticket" && a[3] == "CLOSED") C[a[2]] = 1 } }
      $1 == "withdrawn" { W[$2] = 1 } $1 == "published" { P[$2] = 1 } END { for (n in P) if ((n in C) && !(n in W) && !(n in A)) print n }' .vid/tw/log 2>/dev/null | sort -n | sed 's/^/#/' | paste -sd ',' - | sed 's/,/, /g')
    nd_ accepted analysis owner "${_w:+$_w closed and not accepted — /vid:vid-accept-step <n> <commit> accepted \"<words>\" records each; the analysis goes on}" 'every closed ticket is accepted'
  fi
  _w=$(sh "$HERE/plan.sh" gate 2>/dev/null) && _w='' || _w="${_w:-off} — the vid-connect skill's start opens it; a plan that changes needs it"; nd_ call apply ViD "$_w" "the call's stage is on"
  _w=''; ! engnone || _w=$ENGASK; nd_ engines apply owner "$_w" 'named'
  # settings: GIT_OPTIONAL_LOCKS=0, so the gate's git status writes no index: ready runs on a read's path
  _w=$(skey issue-form); { GIT_OPTIONAL_LOCKS=0 sh "$HERE/writer.sh" gate 2>&1 | sed -n 's/^writer: gate — //p' | grep -v '^the plan is not ratified' || :
    [ -z "$_w" ] || [ "$(git cat-file -t "HEAD:$_w" 2>/dev/null)" = blob ] || echo "issue-form: $_w is no file committed at HEAD — commit it, or sh checks/planner.sh setup issue-form <path> --words \"<words>\""; } |
    sed -e 's|^the settings name no \([a-z-]*\): .*|& — sh checks/planner.sh setup \1 <owner>/<name> --words "<words>"|' -e 's|^spec-repo: .*|& — sh checks/planner.sh setup spec-repo <owner>/<name> --words "<words>"|' \
      -e 's|^the settings have no labels-prefix: .*|& — any answer sh checks/planner.sh setup records writes it|' -e 's|^open-tickets: .*|& — correct the line of .vid/tw/settings|' -e 's|has an uncommitted change$|& — commit it|' > "$T/nw"
  nd_ settings apply owner "$(join_ < "$T/nw")" 'whole'
  if [ "$(skey layout)" = one ] && [ "$(skey spec-publish)" = hand ]; then nd_ publish apply team "after the apply: its posts wait until the team has published the new export into the folder"; fi; }

# scope_: the analysis's reads (reads_ first): $T/pend, $T/tin (`<n>\t<id>\t<evidence>`), $T/tout (`<n>\t<id>`), $T/trg (covered,
# `<tier>\t<what>\t<subject>\t<evidence>`), $T/tp, REV (needed or none), $T/added
# specdiff_: each spec file whose working-tree bytes differ from HEAD's (a tracked file gone counts), compared byte for byte, so
# a read writes nothing: git diff would write a refreshed .git/index, and next.sh triggers, which reads replan.sh ready, changes no file
specdiff_() { for _f in $SPECF; do if git cat-file -e "HEAD:$_f" 2>/dev/null; then [ -f "$_f" ] && git show "HEAD:$_f" | cmp -s - "$_f" || echo "$_f"
    elif [ -n "$(git ls-files -- "$_f")" ]; then echo "$_f"; fi; done; }
scope_() {
  _sd=$(specdiff_); [ -z "$_sd" ] || ref "the spec files in the working tree differ from HEAD's ($(echo $_sd)): the analysis reads HEAD; land them first"
  nx_ pend pending || { sed 's/^/    /' "$T/pend.e" >&2; ref 'the pending changes could not be read (next.sh pending): nothing is analysed from a failed read'; }
  ! grep -q '^unread' "$T/pend" || { sed 's/^/    /' "$T/pend" >&2; ref 'the pending changes could not be read (an unread line): nothing is analysed from a failed read'; }
  nx_ chg changes || { sed 's/^/    /' "$T/chg.e" >&2; ref "the team's changes could not be read (next.sh changes)"; }
  nx_ tg triggers || { sed 's/^/    /' "$T/tg.e" >&2; ref "the call's triggers could not be read (next.sh triggers)"; }
  # GM M16: a partial read never reads as nothing: any unread part but due refuses, named
  # no read kept is a read unread, named `unread read`
  { if [ -f .vid/round/read ]; then cat .vid/round/read; else printf 'unread\tread\t-\tno read kept (.vid/round/read)\n'; fi; cat "$T/chg" "$T/tg"; } |
    awk -F'\t' '$1 == "unread" && $2 != "due" { print $2 " " $3 ": " $4; exit }' > "$T/unrd"
  [ ! -s "$T/unrd" ] || ref "the call's read is incomplete, unread $(head -n 1 "$T/unrd"): nothing is analysed from a partial read; call /vid next again"
  awk -F'\t' -v OFS='\t' 'FILENAME == ARGV[1] { if ($1 == "team") { split($2, a, " "); W[substr(a[1], 2), a[2]] = 1 } next }
    $1 == "added" && $4 == "pending-only" { if (($2, $3) in W) { print $2, $3 > "/dev/stderr" } else print $2, $3, $5 }' "$T/wo" "$T/chg" > "$T/tin" 2> "$T/tout"
  awk -F'\t' 'FILENAME == ARGV[1] { O[$1, $2] = 1; next } $1 == "team" { split($2, a, " "); n = substr(a[1], 2); if (!((n, a[2]) in O)) print "#" n " " a[2] }' "$T/tout" "$T/wo" > "$T/wbad"
  [ ! -s "$T/wbad" ] || ref "without $(head -n 1 "$T/wbad"): no test the team added to that ticket is in the pending spec alone"
  awk -F'\t' -v OFS='\t' -v K="$T/kinds" 'BEGIN { while ((getline l < K) > 0) { split(l, a, "\t"); nk++; KW[nk] = a[1]; KS[nk] = a[2] } }
    $1 == "trigger" || $1 == "quiet" { t = $2; w = $3; s = $4; ev = $5
      if (!nk) { if ((t == "critical" || t == "important" || w ~ /^(to-place-active|stage-to-correct)$/) && !($1 == "quiet" && $6 == "declined")) print t, w, s, ev; next }
      for (i = 1; i <= nk; i++) if (KW[i] == w && (KS[i] == "" || KS[i] == s)) { print t, w, s, ev; HIT[i] = 1; break } }
    END { for (i = 1; i <= nk; i++) if (!(i in HIT)) print "unraised\t" KW[i] (KS[i] == "" ? "" : " " KS[i]) > "/dev/stderr" }' "$T/tg" > "$T/trg" 2> "$T/unr"
  [ ! -s "$T/unr" ] || ref "no trigger is raised now of $(cut -f2 "$T/unr" | tr '\n' ',' | sed 's/,$//; s/,/, /g'): the analysis covers only what the call raises"
  { cat .vid/tw/to-place 2>/dev/null || :; } > "$T/tp"
  lread "$T/added" planner rows --added --at HEAD || exit 2; if grep -q '[^[:space:]]' "$T/added"; then REV=needed; else REV=none; fi
}

# ---- GM-3 U4: the apply move ----
one() { printf '%s' "$1" | tr '\t\n\r' '   ' | tr '"' "'" | sed 's/^ *//; s/ *$//'; }
# owned_ <out>: what the apply owes at the target, from the writer read there (VID_WRITER_AT=HEAD; GM-4 F7: due's own reasons,
# writer.sh due --why): `amend\t<n>\t<kind>\t<row or ->` (kind reset, reached, retired or writing: its `why` lines) for each open
# ticket, and `followup\t<step>\t<rows,>`; the tickets the call's read shows closed read as closed (VID_WRITER_CLOSED), since no
# sync is taken before the apply's own; needs reads_
owned_() { : > "$1"; VID_WRITER_CLOSED=$(awk -F'\t' '$1 == "ticket" && $3 == "CLOSED" { print $2 }' .vid/round/read 2>/dev/null | paste -sd ' ' -); export VID_WRITER_CLOSED
  VID_WRITER_AT=$HD sh "$HERE/writer.sh" due --why > "$T/wy" 2> "$T/e" || { sed 's/^/    /' "$T/e" >&2; die "what the apply owes could not be read (writer.sh due --why)"; }
  while IFS="$TAB" read -r n _s _r _a; do awk -v n="$n" -v OFS='\t' '$1 == "why" && $2 == n { print "amend", n, $3, $4 }' "$T/wy" >> "$1"; done < "$T/tk"
  awk -v OFS='\t' '$1 == "followup" { print "followup", $2, $3 }' "$T/wy" >> "$1"; }
# ownblock_ <out>: the plan as ratified ($T/rb) with the retired rows taken out (rows HEAD's rows table lacks), from rows:, needs and
# protected:; $T/oret the retired rows, $T/ochg each step changed; a step left with no row refuses (exit 1: it needs the analysis)
ownblock_() { grep -v '^#' "$T/rh" | cut -f1 > "$T/hid"; : > "$T/oret"; : > "$T/ochg"
  awk -v H="$T/hid" -v RT="$T/oret" -v CG="$T/ochg" 'BEGIN { while ((getline l < H) > 0) I[l] = 1 }
    function kp(t) { return (t ~ /\.\./ || (t in I)) }
    /^[ \t]*step[ \t]/ { n = split($0, f, "|"); id = f[1]; sub(/^[ \t]*step[ \t]+/, "", id); gsub(/[ \t]+$/, "", id); c = 0
      for (i = 2; i <= n; i++) if (f[i] ~ /^[ \t]*rows:/) { m = split(f[i], t, /[ \t,]+/); v = " rows:"; k = 0
        for (j = 1; j <= m; j++) { if (t[j] == "" || t[j] == "rows:") continue; if (kp(t[j])) { v = v " " t[j]; k++ } else { print t[j] > RT; c = 1 } }
        f[i] = v (i < n ? " " : "") ; if (!k) { print "empty " id > CG; exit 1 } }
      if (c) { print id > CG; o = f[1]; for (i = 2; i <= n; i++) o = o "|" f[i]; print o } else print; next }
    /^[ \t]*needs[ \t]/ { p = index($0, "|"); m = split(substr($0, 1, p - 1), t, /[ \t,]+/); v = ""; c = 0; for (j = 1; j <= m; j++) { if (t[j] == "" || t[j] == "needs") continue; if (kp(t[j])) v = v " " t[j]; else c = 1 }
      if (!c) print; else if (v != "") print "needs" v " |" substr($0, p + 1); next }
    /^[ \t]*protected:/ { v = $0; sub(/^[ \t]*protected:[ \t]*/, "", v); m = split(v, t, /[ \t,]+/); o = ""; for (j = 1; j <= m; j++) if (t[j] != "" && kp(t[j])) o = o " " t[j]; if (o != "") print "protected:" o; next }
    { print }' "$T/rb" > "$1" || return 1; sort -u "$T/oret" -o "$T/oret"; }
# adds_: why the apply needs the analysis, one line each in $T/adds (empty: nothing pending adds a test): an added row, a row a re-cut
# moved, a pending-only team addition, a row newly to place or another breach of the plan as ratified with its retired rows taken out
adds_() { : > "$T/adds"
  awk -F'\t' '$1 == "pending" && ($2 == "added" || $2 == "moved-stage") { print $2 " " $3 }' "$T/pend" >> "$T/adds"
  awk -F'\t' '{ print "team #" $1 " " $2 }' "$T/tin" >> "$T/adds"
  mkdir -p "$T/oc"; if ownblock_ "$T/oc/block"; then ( judge "$T/oc/block" ) > /dev/null 2> "$T/oje" || { sed 's/^ViD replan: //' "$T/oje" | tail -n 1; echo 'the plan as ratified could not be checked at HEAD'; } >> "$T/adds"
    grep '^rule-[124] ' "$T/jo" >> "$T/adds" 2>/dev/null || :   # rule 6 is the change lines own_ writes
  else echo "a step of the plan would hold no row once its retired rows leave: $(sed -n 's/^empty //p' "$T/ochg")" >> "$T/adds"; fi; }
# fresh_: 0 when .vid/next/proposal is fresh: its hash the one hash_ prints now, its target HEAD
fresh_() { [ -f .vid/next/proposal/hash ] && [ "$(cat .vid/next/proposal/hash)" = "$(hash_)" ] && [ "$(cat .vid/next/proposal/target 2>/dev/null)" = "$HD" ]; }
made_() { if [ -f .vid/next/proposal/made ]; then cat .vid/next/proposal/made; elif [ -d .vid/next/proposal ]; then echo analysis; else echo none; fi; }
# ownkey_ (FB-3 C5): what a refused making of the own proposal read that a refusal can come from: HEAD, the applied commit, the plan,
# the tickets' log lines and exports, the handed record, the settings and setup, the to-place list, the team's answers, the recorded
# writings, the tickets GitHub shows closed, ViD's copy of the spec repository and the scripts themselves; never a ticket's body, which the team edits
ownkey_() { { echo "$HD"; applied; grep '^plan-change ' .vid/metrics-events 2>/dev/null | tail -n 1; awk '$1 ~ /^(published|amended|withdrawn|export)$/' .vid/tw/log 2>/dev/null || :
    cat .vid/tw/handed .vid/tw/settings .vid/plan/setup .vid/tw/to-place .vid/next/team-answers 2>/dev/null || :
    for _f in .vid/tw/out/issue-*.md "$HERE/replan.sh" "$HERE/writer.sh" "$HERE/next.sh" "$HERE/planner.sh"; do [ ! -f "$_f" ] || git hash-object "$_f"; done
    awk -F'\t' '$1 == "ticket" && $3 == "CLOSED" { print $2 }' .vid/round/read 2>/dev/null || :; git --git-dir=.vid/spec.git for-each-ref --format='%(objectname) %(refname)' 2>/dev/null || :; } | git hash-object --stdin; }
# own_: the apply's own proposal (GM-3 U4, no analysis): the plan as ratified, the retired rows taken out, each changed step's change,
# written through analyse itself, so it has every file of the proposal's form; made own; its review `pending` while one is needed
own_() { [ -s "$T/oc/block" ] || ownblock_ "$T/oc/block" || ref 'a step would hold no row once its retired rows leave: the plan needs the analysis'
  S12=$(printf %.12s "$HD"); : > "$T/oc/changes"; for s in $(grep -v '^empty ' "$T/ochg"); do printf '%s\tscope-change\tcommit:%s\tthe retired tests %s leave the plan; each ticket keeps them listed, marked retired\n' "$s" "$S12" "$(paste -sd ' ' "$T/oret")" >> "$T/oc/changes"; done
  printf 'none\n' > "$T/oc/review"; S0=$(date -u +%s); VID_REPLAN_OWN=1 sh "$0" analyse --candidate "$T/oc" > "$T/oa" 2>&1 || { sed 's/^/    /' "$T/oa" >&2; _w=$(grep -v '^[[:space:]]*$' "$T/oa" | head -n 1 | sed 's/^[[:space:]]*//' | tr '\t' ' ')
    # FB-3 C5 (e): kept, with what it read, so the call leaves the move out while the same reason stands
    [ -z "$_w" ] || { mkdir -p .vid/next; printf '%s\t%s\n' "$(ownkey_)" "$_w" | put .vid/next/own-refused || :; }
    ref "the apply's own proposal could not be made: ${_w:-it was stopped}"; }
  rm -f .vid/next/own-refused; echo "$(( $(date -u +%s) - S0 ))" > .vid/next/proposal/took   # FB-3 C5 (g): the seconds it took
  printf 'own\n' > .vid/next/proposal/made; [ "$REV" != needed ] || { printf 'pending\n' > .vid/next/proposal/review; git hash-object .vid/next/proposal/review > .vid/next/proposal/review-hash; }; }
# rpage_: the page's review section written again from the proposal's review, the page rendered, and the review's hash kept as shown
rpage_() { _p=.vid/next/proposal; awk '/^## The review of the tests ViD adds/ { exit } { print }' "$_p/REPLAN-PAGE.md" > "$T/rp" || return 0
  { cat "$T/rp"; printf '## The review of the tests ViD adds\n\n'
    if grep -qx none "$_p/review"; then printf 'None to show.\n'; elif grep -qx pending "$_p/review"; then printf 'A fresh agent reviews them before the apply.\n'; else sed 's/^finding /- /' "$_p/review"; printf '\nYour words to the apply answer each finding shown here as kept.\n'; fi; } > "$_p/REPLAN-PAGE.md"
  sh "$HERE/page.sh" "$_p/REPLAN-PAGE.md" --out .vid/pages/REPLAN-PAGE.html > /dev/null 2>&1 || :; git hash-object "$_p/review" > "$_p/review-hash"; }
# rcheck <file>: a review's form, `none` alone or `finding <row ViD added> | <why>` lines (planner.sh review --in's)
rcheck() { awk -v AD="$T/added" "$KEY"' BEGIN { while ((getline l < AD) > 0) { k = key(l); if (k != "") A[k] = 1 } } /^[ \t]*$/ { next } { n++ } /^[ \t]*none[ \t]*$/ { z++; next }
    /^finding [^ |]+ *\|/ { x = $2; if (!(x in A)) { print x " is no row ViD added"; exit } next } { print "a line out of form: " substr($0, 1, 60); exit } END { if (!n) print "it is empty"; else if (z && n > 1) print "none with findings" }' "$1"; }

# keptin_ <a block parsed by BP> (FB-4 A1b): each row of the to-place list that block leaves in the step the ratified plan ($T/rs) has it
# in, a step of another stage ($T/pst the block's steps' stages, the planner's; $T/rh the rows' at HEAD); needs judge of that block
keptin_() { awk -F'\t' -v CS="$1" -v RSF="$T/rs" -v PST="$T/pst" -v RH="$T/rh" '
  BEGIN { while ((getline l < CS) > 0) { split(l, a, "\t"); if (a[1] ~ /:$/) continue; m = split(a[2], r, " "); for (j = 1; j <= m; j++) c[r[j]] = a[1] }
    while ((getline l < RSF) > 0) { split(l, a, "\t"); if (a[1] ~ /:$/) continue; m = split(a[2], r, " "); for (j = 1; j <= m; j++) o[r[j]] = a[1] }
    while ((getline l < PST) > 0) { split(l, a, "\t"); st[a[1]] = a[3] } while ((getline l < RH) > 0) { split(l, a, "\t"); sg[a[1]] = a[5] } }
  NF && ($1 in c) && c[$1] == o[$1] && st[c[$1]] != sg[$1] { print $1 }' .vid/tw/to-place 2>/dev/null || :; }

# steps15: the apply's steps 1 to 5, in the repository at the working directory (ViD's, or the dry run's scratch copy), the proposal
# at .vid/next/proposal; WD the owner's words (one line), TGT the target. Prints a line each thing recorded; 1 on the first refusal
steps15() { P=.vid/next/proposal; N0=$(now)
  # 1. the applied commit, logged; the proposal's PLAN.md committed when it differs from HEAD's
  A0=$(applied); mkdir -p .vid/tw; touch .vid/tw/applied.log
  [ -s .vid/tw/applied.log ] || [ -z "$A0" ] || [ "$A0" = "$TGT" ] || printf '%s\t%s\tseed\n' "$A0" "$N0" >> .vid/tw/applied.log
  printf '%s\n' "$TGT" | put .vid/tw/applied || { echo 'the applied commit could not be written' >&2; return 1; }
  printf '%s\t%s\tapply\n' "$TGT" "$N0" >> .vid/tw/applied.log; echo "applied $(printf %.12s "$TGT")"
  if ! git show HEAD:PLAN.md 2>/dev/null | cmp -s - "$P/PLAN.md"; then cp "$P/PLAN.md" PLAN.md && git add PLAN.md && git commit -q -m 'PLAN.md: the re-plan applied on the owner'"'"'s yes' -m "REQs: none
Decisions: none — PLAN.md as the re-plan's proposal holds it, applied on the owner's yes (checks/replan.sh apply)
Seams: none
Owner: \"$WD\"" -- PLAN.md > "$T/cm" 2>&1 || { sed 's/^/    /' "$T/cm" >&2; echo 'PLAN.md could not be committed' >&2; return 1; }; echo "plan-md $(git rev-parse --short=12 HEAD)"; fi
  # 2. the to-place list, written whole: each row the block puts in a step of its own stage, or moves, off it (FB-4 A1b: the stages are
  # the apply's check's, $T/pst and $T/rh; the plan as ratified, $T/rs), each other kept with its words, the rows the proposal
  # leaves in no step (no-step) and the re-cut rows it leaves in their tickets (other-stage) put on it in the owner's words
  awk "$BP" "$P/block" | awk -F'\t' '$1 !~ /:$/ { n = split($2, r, " "); for (i = 1; i <= n; i++) print r[i] }' | sort -u > "$T/inb"
  awk "$BP" "$P/block" > "$T/bps"; keptin_ "$T/bps" > "$T/kin"
  # a row the proposal leaves otherwise than its line says (moved out of its step into none) takes a new line
  awk -F'\t' -v B="$T/inb" -v K="$T/kin" -v L="$P/left" 'BEGIN { while ((getline l < B) > 0) I[l] = 1; while ((getline l < K) > 0) delete I[l]
      while ((getline l < L) > 0) { split(l, a, "\t"); if (a[1] ~ /^(no-step|other-stage)$/) { sub(/ .*/, "", a[2]); N[a[2]] = a[1] } } }
    NF && !($1 in I) && (!($1 in N) || N[$1] == $2)' .vid/tw/to-place > "$T/tpk" 2>/dev/null || :
  { cat "$T/tpk"
    awk -F'\t' -v OFS='\t' -v t="$N0" -v w="$WD" -v B="$T/inb" -v TP="$T/tpk" 'BEGIN { while ((getline l < B) > 0) I[l] = 1; while ((getline l < TP) > 0) { split(l, a, "\t"); H[a[1]] = 1 } }
      $1 == "no-step" && !($2 in I) && !($2 in H) { print $2, "no-step", t, w; H[$2] = 1 }
      $1 == "other-stage" { r = $2; sub(/ .*/, "", r); if (!(r in H)) { print r, "other-stage", t, w; H[r] = 1 } }' "$P/left"; } > "$T/tpn"
  awk -F'\t' 'FILENAME == ARGV[1] { N[$1] = 1; next } NF && !($1 in N) { print "off-to-place " $1 }' "$T/tpn" .vid/tw/to-place 2>/dev/null || :
  awk -F'\t' 'FILENAME == ARGV[1] { O[$1] = 1; next } !($1 in O) { print "to-place " $1 " " $2 }' .vid/tw/to-place "$T/tpn" 2>/dev/null || awk -F'\t' '{ print "to-place " $1 " " $2 }' "$T/tpn"
  put .vid/tw/to-place < "$T/tpn" || { echo 'the to-place list could not be written' >&2; return 1; }
  # 3. each pending-only team addition the proposal takes in: the owner's yes, in the apply's words (U5)
  if [ -s "$P/team-in" ]; then mkdir -p .vid/next; awk -F'\t' -v OFS='\t' -v t="$N0" -v w="$WD" 'NF { print $1, "added", $2, $3, "yes", t, w }' "$P/team-in" >> .vid/next/team-answers || return 1
    awk -F'\t' 'NF { print "team-in #" $1 " " $2 }' "$P/team-in"; fi
  # 4 and 5. GM-4 F9: land.sh's one landing step, as a landing in GitHub auto makes it: a landed re-cut's stage: moved (STAGES.md read
  # at the target), the block and its plan change with the proposal's triggers, evidence and expected effects (none when the block
  # is the newest recorded plan), the review recorded, each finding the page showed kept in the owner's words, the planner's page and
  # the ratification
  TG=$( { cut -f2 "$P/changes" 2>/dev/null || :; } | tr ',' '\n' | grep . | awk '!s[$0]++' | paste -sd , -); EV=$( { cut -f3 "$P/changes" 2>/dev/null || :; } | tr ',' '\n' | grep -v '^-*$' | awk '!s[$0]++' | paste -sd , -)
  EX=$( { cut -f4 "$P/changes" 2>/dev/null || :; } | grep . | paste -sd ';' - | sed 's/;/; /g'); [ -n "$TG" ] || { TG=scope-change; EV=commit:$(printf %.12s "$TGT"); }; [ -n "$EX" ] || EX='the plan as the re-plan proposal holds it'
  if [ -n "$EV" ]; then set -- --evidence "$EV"; else set --; fi
  ! grep -q "^spec${TAB}STAGES.md${TAB}" "$P/pending" || set -- "$@" --stages "$TGT"
  if sh "$HERE/land.sh" step --block "$P/block" --if-new --why "the re-plan applied on the owner's yes: $WD" --trigger "$TG" "$@" --expect "$EX" --review "$P/review" --words "$WD" 2> "$T/lse"; then sed 's/^ViD land: //' "$T/lse" >&2
  else sed 's/^ViD land: //' "$T/lse" >&2; return 1; fi; }

# apply_ --words "<words>" [--review <file>]
apply_() { WD=''; RVF=''; while [ $# -gt 0 ]; do case $1 in --words) [ $# -ge 2 ] || usage; WD=$(one "$2"); shift 2 ;; --review) [ $# -ge 2 ] || usage; RVF=$2; shift 2 ;; *) usage ;; esac; done
  [ -n "$WD" ] || ref "no words: the apply is done only on the owner's yes, --words \"<their words>\""
  [ -z "$RVF" ] || [ -f "$RVF" ] || die "--review $RVF: no file there"
  ! manual || needs_ apply | awk -F'\t' '$3 == "missing"'   # FB-4 A3: what its posts need and lack, first; none refuses
  reads_; P=.vid/next/proposal; M=$(made_)
  # which proposal: a fresh analysis; else, with nothing pending that adds a test, the apply's own (kept while fresh, so a review shown stays)
  if [ "$M" = analysis ]; then fresh_ || { echo "ViD replan: refused — the proposal is stale: HEAD or what it reads changed since the analysis ($(printf %.12s "$(cat "$P/target" 2>/dev/null)") then, $(printf %.12s "$HD") now): analyse again, /vid next planning-analysis" >&2; exit 4; }
  else scope_; adds_; [ ! -s "$T/adds" ] || { sed 's/^/    /' "$T/adds" >&2; ref "something pending adds a test (above): the apply needs a fresh analysis first, /vid next planning-analysis"; }
    [ -s "$T/pend" ] || ref 'nothing is pending: the applied version is the newest spec, and there is nothing to apply'
    # the apply's own proposal is never applied unseen: made (or made again) here, it is shown, and refused
    if [ "$M" != own ] || ! fresh_; then own_; echo "ViD replan: refused — the apply's own proposal is made and its page written (.vid/pages/REPLAN-PAGE.html, the plan block $(cat "$P/block-hash")): shown again; your next implement-replan words apply it" >&2; exit 4; fi; fi
  # the review: the analysis's; or, for the apply's own proposal, the fresh agent's the apply's skill step made (--review), when
  # planner.sh rows --added --at <target> prints rows. A finding the owner has not seen refuses this apply and is shown
  if grep -qx pending "$P/review"; then [ -n "$RVF" ] || ref "the rows ViD's planner adds at the target need a fresh agent's review first (planner.sh rows --added --at HEAD): its output, --review <file>"
    lread "$T/added" planner rows --added --at HEAD || exit 2; b=$(rcheck "$RVF"); [ -z "$b" ] || ref "--review $RVF: $b"
    tr -d '\r' < "$RVF" > "$P/review"; rpage_
    if grep -q '^finding ' "$P/review"; then grep '^finding ' "$P/review" | sed 's/^finding /    /' >&2
      ref "the review found what you have not seen yet (above): your next implement-replan words keep each as written, or run the analysis again"; fi
  elif [ -n "$RVF" ]; then echo "ViD replan: the proposal's own review stands; --review $RVF is not read"; fi
  # the review recorded is the one the page showed (its hash kept as the page was written); one changed since
  # refuses this apply and is shown again, before any finding is kept
  if [ "$(git hash-object "$P/review")" != "$(cat "$P/review-hash" 2>/dev/null)" ]; then { echo '    the review now:'; sed 's/^/    /' "$P/review"; } >&2; rpage_
    ref "the proposal's review changed since its page showed it (above): shown again; your next implement-replan words keep each finding as written, or run the analysis again"; fi
  # checked whole before anything is recorded: the check again, then steps 1 to 5 on a scratch copy (land.sh's dry run)
  judge "$P/block"; if grep -q '^rule-' "$T/jo"; then grep '^rule-' "$T/jo" >&2; ref "the proposal breaks $(grep -c '^rule-' "$T/jo") re-plan rule(s) (above): nothing applied"; fi
  TGT=$(cat "$P/target"); SC=$T/sc; git clone -q -c core.longpaths=true --no-hardlinks . "$SC" 2> "$T/e" || ref "no scratch copy for the dry run: $(tail -n 1 "$T/e")"
  BR=$(git symbolic-ref -q --short HEAD || true); if [ -n "$BR" ]; then git -C "$SC" checkout -q -B "$BR" HEAD 2>/dev/null; fi
  for k in core.hooksPath user.name user.email; do v=$(git config --get "$k" || true); [ -z "$v" ] || git -C "$SC" config "$k" "$v"; done
  [ ! -d checks ] || cp -R checks "$SC/"
  mkdir -p "$SC/.vid"; for e in .vid/* .vid/.[!.]*; do [ -e "$e" ] || continue; case ${e#.vid/} in code|spec.git|results|*.lock|*.lock.steal) continue ;; esac; cp -R "$e" "$SC/.vid/"; done
  rm -rf "$SC/.vid/next"/.proposal.*
  ( cd "$SC" && steps15 ) > "$T/dry" 2> "$T/drye" || { sed 's/^/    /' "$T/drye" >&2; ref "the dry run of the apply's steps 1 to 5 refused: $(grep -v '^ ' "$T/drye" | tail -n 1): nothing applied"; }
  # the apply: steps 1 to 5 (rolled back whole if one fails), then the posts, inside the call's stage (GM-4 F2: none of its own)
  for f in .vid/tw/applied .vid/tw/applied.log .vid/tw/to-place .vid/next/team-answers .vid/RUN-STATE.md .vid/metrics-events; do if [ -f "$f" ]; then cp "$f" "$T/bk.$(echo "$f" | tr / _)"; fi; done
  mkdir -p .vid/plan .vid/plans; cp -R .vid/plan "$T/bk-plan"; cp -R .vid/plans "$T/bk-plans"; H0=$(git rev-parse HEAD)
  if ! steps15 > "$T/real" 2> "$T/reale"; then sed 's/^/    /' "$T/reale" >&2
    for f in .vid/tw/applied .vid/tw/applied.log .vid/tw/to-place .vid/next/team-answers .vid/RUN-STATE.md .vid/metrics-events; do b=$T/bk.$(echo "$f" | tr / _); if [ -f "$b" ]; then put "$f" < "$b"; else rm -f "$f"; fi; done
    rm -rf .vid/plan .vid/plans; cp -R "$T/bk-plan" .vid/plan; cp -R "$T/bk-plans" .vid/plans
    [ "$(git rev-parse HEAD)" = "$H0" ] || { git reset -q --soft "$H0"; git reset -q -- PLAN.md; git checkout -q "$H0" -- PLAN.md 2>/dev/null || :; }
    die "the apply's steps refused after its dry run passed: rolled back, nothing applied"; fi
  cat "$T/real"
  # 6. the posts, each through the one ticket path (GM-4 F5, K1: github.sh tw-hand, which makes its own preparation, the export, the
  # sync, the read and the handovers, under the call's lock, and prints a publish's warnings), each on the owner's words; in order, each open ticket
  # owed amended, the apply its cause, each follow-up of a closed ticket's reset or reached rows, then each new step the proposal
  # publishes; a post tw-hand refuses or holds stays owed
  RCP=0; CA="the re-plan applied on the owner's yes, the plan $(cat "$P/block-hash")"
  sh "$HERE/github.sh" tw-sync > "$T/sy" 2>&1 || :; sh "$HERE/writer.sh" due > "$T/due" 2> "$T/e" || : > "$T/due"
  # GM-4 K13 (J4): with one repository (layout: one) the spec goes first into the code repository's folder: the export at the new
  # applied version, then github.sh spec-publish of that export commit (nothing more when it is published there already); a
  # publish refused, or an export failed, holds every post (owed, exit 3), since each would quote a spec the folder lacks
  SPH=''; if [ "$(skey layout)" = one ]; then
    if sh "$HERE/github.sh" spec-export > "$T/sx" 2>&1; then SX=$(awk '$1 == "export" { x = $2 } END { print x }' .vid/tw/log 2> /dev/null)
      # GM-4 K13: spec-publish alone judges what is published (its export, folder and stamp), so the apply keeps no check of its own
      if [ -z "$SX" ]; then SPH='the export made no export line'
      # FB-1 B6: the apply's words recorded on the spec-published line
      elif sh "$HERE/github.sh" spec-publish --words "$WD" "$SX" > "$T/sp" 2>&1; then echo "done spec-publish $(printf %.12s "$SX")"; grep -v '^[[:space:]]*$' "$T/sp" | sed 's/^/    /'
      else SPH="spec-publish $(printf %.12s "$SX"): $(grep -v '^[[:space:]]*$' "$T/sp" | tail -n 1)"; fi
    else SPH="the export: $(grep -v '^[[:space:]]*$' "$T/sx" | tail -n 1)"; fi
    [ -z "$SPH" ] || { RCP=3; echo "owed $SPH"; case $SPH in spec-publish*) ;; *) echo 'owed spec-publish: the export did not go out' ;; esac
      printf '%s\n' "$SPH" > "$P/spec-publish"; }; fi   # GM-4 K13: kept with the proposal applied, so the next call shows the owed publish
  post() { if [ -n "$SPH" ]; then RCP=3; echo "owed $1 $2: held, the spec not in the code repository's folder yet ($SPH)"; return 0; fi
    _pk=$1; _ps=$2; shift 2; _pr=0; sh "$HERE/github.sh" tw-hand "$_pk" "${_ps#\#}" --words "$WD" "$@" > "$T/po" 2>&1 || _pr=$?
    if [ "$_pr" = 0 ]; then echo "done $_pk $_ps"; else RCP=3; echo "owed $_pk $_ps: $(grep -v '^[[:space:]]*$' "$T/po" | tail -n 1)"; fi
    grep -v '^[[:space:]]*$' "$T/po" | sed 's/^/    /'; }
  for n in $(cut -f1 "$P/amend" | sort -un); do if grep -qx "amend $n" "$T/due"; then post amend "#$n" --cause "$CA"; else echo "amend #$n: not owed now"; fi; done
  awk -F'\t' '$1 == "amend" { print $2 }' "$T/due" | sort -un | while read -r n; do grep -q "^$n$TAB" "$P/amend" || echo "left owed amend #$n: the proposal did not show it"; done
  while IFS="$TAB" read -r s _r; do [ -n "$s" ] || continue; if grep -qx "new step $s" "$T/due"; then post publish "$s"; else echo "follow-up $s: not owed now"; fi; done < "$P/followup"
  while IFS= read -r s; do [ -n "$s" ] || continue; post publish "$s"; done < "$P/publish"
  # each follow-up due owes after the sync that the proposal did not show (its ticket closed meanwhile) is left
  # owed, named, for the next call's publish move
  for s in $(sed -n 's/^new step //p' "$T/due"); do grep -q "^published [0-9]* .*step=$s " .vid/tw/log || continue; ! grep -q "^$s$TAB" "$P/followup" || continue; grep -qx "$s" "$P/publish" && continue
    RCP=3; echo "owed publish $s: a follow-up the proposal did not show (its ticket closed since the read); the next call lists it"; done
  rm -rf .vid/next/applied-proposal; mv "$P" .vid/next/applied-proposal
  echo "ViD replan: applied — the applied version $(printf %.12s "$TGT"), the plan $(cat .vid/next/applied-proposal/block-hash) ratified in the owner's words"
  exit "$RCP"; }

# ready: for the call's listing (U6), one line `apply <analysis|own|analyse|none>\t<why or the block hash or ->`, then `review <needed|none>`
ready_() { reads_
  if [ "$(made_)" = analysis ] && fresh_; then printf 'apply\tanalysis\t%s\n' "$(cat .vid/next/proposal/block-hash)"
  elif [ "$(made_)" = analysis ]; then printf 'apply\tanalyse\tthe proposal is stale: HEAD or what it reads changed since the analysis\n'
  else scope_; adds_; if [ -s "$T/adds" ]; then printf 'apply\tanalyse\t%s\n' "$(paste -sd ';' "$T/adds" | sed 's/;/; /g')"
    elif [ ! -s "$T/pend" ]; then printf 'apply\tnone\t-\n'; else printf 'apply\town\t%s\n' "$(cut -f2,3 "$T/pend" | tr '\t' ' ' | paste -sd ',' - | sed 's/,/, /g')"
      # FB-3 C5 (e, g): its own proposal fresh, due, or not to be made for a reason that stands
      if [ "$(made_)" = own ] && fresh_; then printf 'own\tfresh\t-\n'
      elif [ -s .vid/next/own-refused ] && [ "$(cut -f1 .vid/next/own-refused)" = "$(ownkey_)" ]; then printf 'own\trefused\t%s\n' "$(cut -f2- .vid/next/own-refused)"
      else printf 'own\tdue\t-\n'; fi; fi; fi
  lread "$T/added" planner rows --added --at HEAD || exit 2; if grep -q '[^[:space:]]' "$T/added"; then echo 'review	needed'; else echo 'review	none'; fi; }

sub=${1:-}; [ $# -gt 0 ] && shift || usage
case $sub in
  hash) [ $# -eq 0 ] || usage; manual || ref 'the re-plan runs in GitHub manual alone'; hash_; exit 0 ;;

  check) [ $# -eq 1 ] || usage; reads_; judge "$1"; cat "$T/jo"; ! grep -q '^rule-' "$T/jo" || exit 1; exit 0 ;;

  scope) parseargs "$@"; [ "$CAND" = .vid/next/candidate ] || usage; ! manual || needs_; reads_; scope_   # FB-4 A3: the list first, whatever refuses after it
    printf 'target\t%s\napplied\t%s\n' "$HD" "$A"; cat "$T/pend"
    judge "$T/rb" > /dev/null 2>&1 || :; awk -F'\t' -v OFS='\t' '$1 == "moved" { print "moved-stage", $2, $3, $4 }' "$T/side"
    awk -F'\t' -v OFS='\t' 'NF { print "to-place", $1, $2, $4 }' "$T/tp"
    awk -F'\t' -v OFS='\t' '{ print "team-in", "#" $1, $2, $3 }' "$T/tin"; awk -F'\t' -v OFS='\t' '{ print "team-out", "#" $1, $2 }' "$T/tout"
    awk -F'\t' -v OFS='\t' '{ print "trigger", $1, $2, $3, $4 }' "$T/trg"
    awk -F'\t' -v OFS='\t' '{ r = $3; gsub(/ /, ",", r); print "ticket", "#" $1, $2, (r == "" ? "-" : r) }' "$T/tk"
    printf 'review\t%s\n' "$REV"; exit 0 ;;

  analyse) ;;
  apply) parseargs; apply_ "$@" ;;
  # FB-4 A3: with implement-replan listed, what its posts need and lack
  ready) [ $# -eq 0 ] || usage; parseargs; ready_ > "$T/rdo"; cat "$T/rdo"; ! grep -q "^apply${TAB}\(analysis\|own\)$TAB" "$T/rdo" || grep -q "^own${TAB}refused" "$T/rdo" || needs_ apply | awk -F'\t' '$3 == "missing" && $2 ~ /^(engines|settings)$/'; exit 0 ;;
  own) [ $# -eq 0 ] || usage; parseargs; reads_; scope_; adds_; [ ! -s "$T/adds" ] || { sed 's/^/    /' "$T/adds" >&2; ref 'something pending adds a test (above): the apply needs the analysis'; }
    [ -s "$T/pend" ] || ref 'nothing is pending'; own_; echo "ViD replan: the apply's own proposal is in .vid/next/proposal/ — the plan block $(cat .vid/next/proposal/block-hash); nothing recorded or posted"; exit 0 ;;
  *) usage ;;
esac

# analyse
parseargs "$@"; reads_; scope_
C=$CAND; [ -f "$C/block" ] || ref "no candidate: $C/block is missing (the conversation writes the candidate there, skills/vid-replan/SKILL.md)"
judge "$C/block"; : > "$T/bad"
# U5: a pending-only team addition in its ticket's step by default, out only by `without`
awk -F'\t' -v CS="$T/cs" -v TK="$T/tk" -v TIN="$T/tin" -v TOUT="$T/tout" -v WO="$T/wo" -v RSF="$T/rs" -v LF="$T/c-left" -v TRG="$T/trg" -v REV="$REV" -v RF="$C/review" -v AD="$T/added" "$KEY"'
  BEGIN { while ((getline l < CS) > 0) { split(l, a, "\t"); if (a[1] ~ /:$/) continue; cst[a[1]] = 1; m = split(a[2], r, " "); for (j = 1; j <= m; j++) cin[r[j]] = a[1] }
    while ((getline l < RSF) > 0) { split(l, a, "\t"); rst[a[1]] = 1 }
    while ((getline l < TK) > 0) { split(l, a, "\t"); tst[a[1]] = a[2] }
    # an addition whose ticket maps to no open step is placed in some step, or named without
    while ((getline l < TIN) > 0) { split(l, a, "\t"); s = tst[a[1]]; if (s == "") { if (cin[a[2]] == "") print "team #" a[1] " " a[2] " \342\200\224 the team added it to #" a[1] ", which is no open published ticket: the candidate places it in a step, or the owner names it left out: planning-analysis \342\200\246 without #" a[1] " " a[2]; continue } if (cin[a[2]] != s) print "team #" a[1] " " a[2] " \342\200\224 the team added it to #" a[1] "; the analysis takes it into its step " s " unless the owner names it left out: planning-analysis \342\200\246 without #" a[1] " " a[2] }
    while ((getline l < TOUT) > 0) { split(l, a, "\t"); s = tst[a[1]]; if (s != "" && cin[a[2]] == s) print "team #" a[1] " " a[2] " \342\200\224 named without, yet the candidate puts it in step " s " of #" a[1] }
    while ((getline l < WO) > 0) { split(l, a, "\t"); if (a[1] == "step" && (!(a[2] in cst) || (a[2] in rst))) print "step " a[2] " \342\200\224 without " a[2] " names no new step of the candidate" }
    while ((getline l < TRG) > 0) { split(l, a, "\t"); cov[a[2] " " a[3]] = 1 }
    while ((getline l < LF) > 0) { split(l, a, "\t"); if (a[1] == "no-step" && cin[a[2]] != "") print "left " a[2] " \342\200\224 left alone in no step, yet the candidate puts it in step " cin[a[2]]
      else if (a[1] == "trigger" && !(a[2] in cov)) print "left " a[2] " \342\200\224 names no trigger this analysis covers"
      else if (a[1] != "no-step" && a[1] != "trigger" && l !~ /^[ \t]*$/) print "left " a[1] " \342\200\224 a line of left is no-step or trigger" }
    # the review of the rows ViD adds at HEAD: needed, it is there and in form
    while ((getline l < AD) > 0) { k = key(l); if (k != "") ADD[k] = 1 }
    if (REV == "needed") { n = 0; bad = ""; none = 0
      while ((getline l < RF) > 0) { if (l ~ /^[ \t]*$/) continue; n++; if (l ~ /^[ \t]*none[ \t]*$/) { none = 1; continue }
        if (l !~ /^finding [^ |]+ *\|/) { bad = "a line out of form, " substr(l, 1, 60); continue } x = l; sub(/^finding /, "", x); sub(/ *\|.*/, "", x); if (!(x in ADD)) bad = x " is no row ViD added" }
      if (!n) print "review \342\200\224 the rows ViD" "\047" "s planner adds at HEAD (planner.sh rows --added --at HEAD) need a fresh agent" "\047" "s review: its output, or none, in the candidate" "\047" "s review"
      else if (bad != "") print "review \342\200\224 " bad
      else if (none && n > 1) print "review \342\200\224 none and findings both" } }' < /dev/null > "$T/bad"
# FB-4 A1: the candidate's placements, two readers' (the vid-placement-review skill); the apply's own proposal places no test
PLN=0; if [ -z "${VID_REPLAN_OWN:-}" ] && [ ! -f "$C/placement/result" ]; then
  PLN=$(sh "$HERE/planner.sh" placements write "$T/plc" --block "$C/block" --at HEAD --plan-md "$T/cpm" 2> "$T/e" | sed -n 's/^listed //p'); [ -n "$PLN" ] || { sed 's/^/    /' "$T/e" >&2; die "planner.sh placements could not list the candidate's placements"; }
  [ "$PLN" = 0 ] || echo "placements — $PLN to read (planner.sh placements write), and no $C/placement/result: the vid-placement-review skill's two readers" >> "$T/bad"; fi
if grep -q '^rule-' "$T/jo" || [ -s "$T/bad" ]; then grep '^rule-' "$T/jo" >&2 || :; cat "$T/bad" >&2
  ref "the candidate breaks $(grep -c '^rule-' "$T/jo" || :) re-plan rule(s) and $(grep -c . "$T/bad" || :) of the analysis's — nothing written"; fi

# the proposal, built beside its place, then put in whole
mkdir -p .vid/next .vid/pages; PD=.vid/next/.proposal.$$; rm -rf "$PD"; mkdir "$PD"
trap 'rm -rf "$T" "$PD"' EXIT   # FB-3 C5 (e): a read that dies half way leaves no folder (once put in place, it is there no more)
fail_() { rm -rf "$PD"; ref "$1"; }
cp "$C/block" "$PD/block"; cp "$T/cpm" "$PD/PLAN.md"; cp "$T/c-changes" "$PD/changes"
if [ "$REV" = needed ]; then tr -d '\r' < "$C/review" > "$PD/review"; else printf 'none\n' > "$PD/review"; fi
if [ -z "${VID_REPLAN_OWN:-}" ] && [ -f "$C/placement/result" ]; then cp "$C/placement/result" "$PD/placements"; else : > "$PD/placements"; fi   # FB-4 A1
printf '%s\n' "$HD" > "$PD/target"; hash_ > "$PD/hash"; sed 's/[[:space:]]*$//' "$C/block" | sha > "$PD/block-hash"
{ awk -F'\t' -v OFS='\t' '{ print "kind", $1, ($2 == "" ? "-" : $2) }' "$T/kinds"; awk -F'\t' -v OFS='\t' '{ print "without", $2 }' "$T/wo"; } > "$PD/args"
cp "$T/pend" "$PD/pending"; cp "$T/trg" "$PD/triggers"
# amend: each open ticket's top-up, restated and retired rows
: > "$PD/amend"; while IFS="$TAB" read -r n s rows _at; do
  awk -F'\t' -v n="$n" -v OFS='\t' '$1 == "topup" && $2 == n { print n, "added", $3 }' "$T/side" >> "$PD/amend"
  sh "$HERE/next.sh" differ "$n" "$HD" > "$T/df" 2> "$T/e" || { sed 's/^/    /' "$T/e" >&2; fail_ "what #$n quotes could not be compared with HEAD (next.sh differ $n)"; }
  for r in $rows; do if ! awk -F'\t' -v r="$r" '$1 == r { f = 1 } END { exit !f }' "$T/rh"; then printf '%s\tretired\t%s\n' "$n" "$r" >> "$T/ret"; fi; done
  awk -F'\t' -v n="$n" -v OFS='\t' -v RT="$T/ret" 'BEGIN { while ((getline l < RT) > 0) { split(l, a, "\t"); if (a[1] == n) R[a[3]] = 1 } } $1 == "differ" && $2 == n && !($3 in R) { print n, "restated", $3 }' "$T/df" >> "$PD/amend"
  [ ! -f "$T/ret" ] || { awk -F'\t' -v n="$n" '$1 == n' "$T/ret" >> "$PD/amend"; rm -f "$T/ret"; }
done < "$T/tk"
# GM-3 U4: what the apply owes at the target beyond the top-ups and quotes (writer.sh due --why): a reset row as restated, a
# reached row, a retired one, a writing whose quoted text changed (quoted -); and each follow-up of a closed ticket, in followup
owned_ "$T/ow"
awk -F'\t' -v OFS='\t' -v AM="$PD/amend" 'BEGIN { while ((getline l < AM) > 0) { split(l, a, "\t"); H[a[1], a[3]] = 1 } }
  $1 == "amend" { k = ($3 == "reset") ? "restated" : ($3 == "writing") ? "quoted" : $3; if (k == "quoted" || !(($2, $4) in H)) { print $2, k, $4; H[$2, $4] = 1 } }' "$T/ow" >> "$PD/amend"
awk -F'\t' -v OFS='\t' '$1 == "followup" { print $2, $3 }' "$T/ow" > "$PD/followup"; printf 'analysis\n' > "$PD/made"; git hash-object "$PD/review" > "$PD/review-hash"   # the review as the page shows it
# publish: each new step holding a pending change, unless named without
awk -F'\t' -v CS="$T/cs" -v RSF="$T/rs" -v WO="$T/wo" -v SD="$T/side" 'BEGIN { while ((getline l < RSF) > 0) { split(l, a, "\t"); rst[a[1]] = 1 }
    while ((getline l < WO) > 0) { split(l, a, "\t"); if (a[1] == "step") w[a[2]] = 1 }
    while ((getline l < SD) > 0) { split(l, a, "\t"); if (a[1] == "moved") P[a[2]] = 1 } }
  $1 == "pending" && $2 ~ /^(reset|added|reached|moved-stage)$/ { P[$3] = 1 }
  END { while ((getline l < CS) > 0) { split(l, a, "\t"); s = a[1]; if (s ~ /:$/ || (s in rst) || (s in w)) continue; m = split(a[2], r, " "); for (j = 1; j <= m; j++) if (r[j] in P) { print s; break } } }' "$T/pend" > "$PD/publish"
awk -F'\t' -v OFS='\t' -v TK="$T/tk" 'BEGIN { while ((getline l < TK) > 0) { split(l, a, "\t"); m = split(a[3], r, " "); for (j = 1; j <= m; j++) n[r[j]] = a[1] } }
  NF && $0 !~ /^[ \t]*$/ { x = $1; gsub(/[ \t]/, "", x); if (x != "") print x, n[x], "" }' "$T/c-taken-out" > "$T/to1"
awk -F'\t' -v OFS='\t' -v CS="$T/cs" 'BEGIN { while ((getline l < CS) > 0) { split(l, a, "\t"); m = split(a[2], r, " "); for (j = 1; j <= m; j++) s[r[j]] = a[1] } } { print $1, $2, s[$1] }' "$T/to1" > "$PD/taken-out"
cp "$T/tin" "$PD/team-in"
awk -F'\t' -v OFS='\t' -v RS_="$T/rs" 'BEGIN { while ((getline l < RS_) > 0) { split(l, a, "\t"); if (a[1] ~ /:$/) continue; m = split(a[2], r, " "); for (j = 1; j <= m; j++) f[r[j]] = a[1] } }
  $1 !~ /:$/ { m = split($2, r, " "); for (j = 1; j <= m; j++) { x = r[j]; t[x] = $1; if (f[x] != $1) print x, ((x in f) ? f[x] : "-"), $1 } }
  END { for (x in f) if (!(x in t)) print x, f[x], "-" }' "$T/cs" | sort > "$PD/moves"
# warnings: the check's, then each published step's GM M12 warnings on a scratch copy: the candidate's block in RUN-STATE, HEAD applied
awk '/^(size|builds) / { k = $1; id = $2; w = $0; p = index(w, " \342\200\224 "); print k "\t" id "\t" substr(w, p + 5) }' "$T/jo" > "$PD/warnings"
if [ -s "$PD/publish" ]; then
  SC=$T/sc; git clone -q -c core.longpaths=true --no-hardlinks . "$SC" 2> "$T/e" || fail_ "no scratch copy for the new steps' warnings: $(tail -n 1 "$T/e")"
  mkdir -p "$SC/.vid"; for e in .vid/* .vid/.[!.]*; do [ -e "$e" ] || continue; case ${e#.vid/} in code|spec.git|results|*.lock|*.lock.steal|.proposal.*) continue ;; esac; cp -R "$e" "$SC/.vid/"; done
  rm -rf "$SC/.vid/next/proposal" "$SC/.vid/next/candidate" "$SC/.vid/next"/.proposal.*; printf '%s\n' "$HD" > "$SC/.vid/tw/applied"; cp "$T/cpm" "$SC/PLAN.md"
  awk -v NB="$C/block" 'BEGIN { while ((getline l < NB) > 0) K[++k] = l } /^## The plan/ { s = 1 } s && !d && /^```vid-plan[ \t]*$/ { print; for (i = 1; i <= k; i++) print K[i]; b = 1; d = 1; next } b && /^```[ \t]*$/ { b = 0 } !b { print }' .vid/RUN-STATE.md > "$SC/.vid/RUN-STATE.md"
  ( cd "$SC" && sh "$HERE/next.sh" triggers ) > "$T/m12" 2> "$T/e" || { sed 's/^/    /' "$T/e" >&2; fail_ "the new steps' warnings could not be read (next.sh triggers on a scratch copy holding the candidate)"; }
  awk -F'\t' -v OFS='\t' -v PB="$PD/publish" 'BEGIN { while ((getline l < PB) > 0) P[l] = 1 } $1 == "warning" && $2 == "publish" && ($3 in P) { print $4, $3, $5 "; " $6 }' "$T/m12" >> "$PD/warnings"
fi
# left: the rows left in no step, the re-cut rows left in their tickets, the to-place rows kept, the triggers, the team's, the steps
{ awk -F'\t' -v OFS='\t' -v LF="$T/c-left" 'BEGIN { while ((getline l < LF) > 0) { split(l, a, "\t"); if (a[1] == "no-step") W[a[2]] = a[3] } } $1 == "no-step" { print "no-step", $2, W[$2] }' "$T/side"
  awk -F'\t' -v OFS='\t' '$1 == "other-stage" { print "other-stage", $2 " #" $3, "a landed re-cut moved it to stage " $4 "; it stays in #" $3 ", where it was published, on the to-place list" }' "$T/side"
  keptin_ "$T/cs" > "$T/kin"   # FB-4 A1b: a test left in another stage's step is said too
  awk -F'\t' -v OFS='\t' -v CS="$T/cs" -v K="$T/kin" 'BEGIN { while ((getline l < CS) > 0) { split(l, a, "\t"); m = split(a[2], r, " "); for (j = 1; j <= m; j++) c[r[j]] = a[1] } while ((getline l < K) > 0) k[l] = 1 }
    NF && (!($1 in c) || ($1 in k)) { print "kept", $1, "on the to-place list (" $2 "): " $4 (($1 in k) ? " (still in step " c[$1] ", of another stage)" : "") }' "$T/tp"
  awk -F'\t' -v OFS='\t' '$1 == "trigger" { print "trigger", $2, $3 }' "$T/c-left"
  awk -F'\t' -v OFS='\t' '{ print "team", "#" $1 " " $2, "left out in the owner" "\047" "s words: without #" $1 " " $2 }' "$T/tout"
  awk -F'\t' -v OFS='\t' '$1 == "step" { print "step", $2, "not published by the apply, in the owner" "\047" "s words: without " $2 }' "$T/wo"; } > "$PD/left"

# FB-4 A5: which step is the first to set up which data store, the planner's own list for the candidate
sh "$HERE/planner.sh" setsup --block "$C/block" --at HEAD > "$T/su" 2> "$T/e" || { sed 's/^/    /' "$T/e" >&2; fail_ "what each step is the first to set up could not be read (planner.sh setsup)"; }
# the page, in plain words
BH=$(cat "$PD/block-hash"); PH=$(cat "$PD/hash")
{ printf '# The re-plan proposal\n\n'
  printf 'How the plan would take in what is waiting. Nothing is recorded or posted: your words to `implement-replan` do it, as shown here, and nothing else.\n\n'
  printf -- '- **The plan block:** %s (its hash; the apply'"'"'s page shows it too)\n- **The proposal:** %s (if anything it reads changes before the apply, analyse again)\n' "$BH" "$PH"
  printf -- '- **The spec the team would get:** %s; **the team has now:** %s\n\n' "$(printf %.12s "$HD")" "$(printf %.12s "$A")"
  printf '## Each ticket'"'"'s top-ups\n\n'
  # FB-3 E3: each added test's promise, the inventory's own words at the target ($T/rh), a line each after its ticket's or its step's line
  if [ -s "$PD/amend" ]; then awk -F'\t' -v TK="$T/tk" -v RH="$T/rh" 'BEGIN { while ((getline l < TK) > 0) { split(l, a, "\t"); st[a[1]] = a[2]; t[a[1]] = a[3] } while ((getline l < RH) > 0) { split(l, a, "\t"); PR[a[1]] = (a[8] != "" ? a[8] : a[9]) } }
      { k = $1; O[k] = 1; if ($2 == "added") { A[k] = A[k] ", " $3; WD[k] = WD[k] "\t  - " $3 ": " PR[$3] } else if ($2 == "restated") R[k] = R[k] ", " $3; else if ($2 == "reached") H[k] = H[k] ", " $3; else if ($2 == "quoted") Q[k] = 1; else X[k] = X[k] ", " $3 }
      END { for (k in O) { l = "- **#" k "** (step " st[k] "):"; if (A[k] != "") l = l " adds " substr(A[k], 3) ";"; if (R[k] != "") l = l " restates " substr(R[k], 3) ";"; if (H[k] != "") l = l " reaches " substr(H[k], 3) " (a requirement they check changed);"; if (Q[k]) l = l " its quoted text changes;"; if (X[k] != "") l = l " marks retired " substr(X[k], 3) ";"
        sub(/;$/, ".", l); m = split(t[k], r, " "); nx = split(substr(X[k], 3), xr, ", "); if (m && nx == m) l = l " Only retired tests are left in it: it stays; withdrawing it is the withdraw move, in your words."; print l WD[k] } }' "$PD/amend" | sort | tr '\t' '\n'
  else printf 'No published ticket changes.\n'; fi
  [ ! -s "$PD/followup" ] || { printf '\n## Follow-ups of closed tickets\n\nA reset or reached test of a closed ticket goes out in a follow-up ticket of its step holding exactly those tests; the apply publishes it.\n\n'
    awk -F'\t' '{ r = $2; gsub(/,/, ", ", r); print "- **" $1 "**: " r }' "$PD/followup"; }
  printf '\n## New or split steps\n\n'
  awk -F'\t' -v RS_="$T/rs" -v PB="$PD/publish" -v W="$PD/warnings" -v WO="$T/wo" -v RH="$T/rh" -v PE="$T/pend" -v AM="$PD/amend" '
    function words(all,   i) { for (i = 1; i <= m; i++) if (all || ((w[i] in AD) && !(w[i] in TU))) print "  - " w[i] ": " PR[w[i]] }
    BEGIN { while ((getline l < RH) > 0) { split(l, a, "\t"); PR[a[1]] = (a[8] != "" ? a[8] : a[9]) }
      while ((getline l < PE) > 0) { split(l, a, "\t"); if (a[1] == "pending" && a[2] == "added") AD[a[3]] = 1 } while ((getline l < AM) > 0) { split(l, a, "\t"); if (a[2] == "added") TU[a[3]] = 1 }
      while ((getline l < RS_) > 0) { split(l, a, "\t"); rn[a[1]] = a[3]; RO[++nr] = a[1] }
      while ((getline l < PB) > 0) P[l] = 1; while ((getline l < W) > 0) { split(l, a, "\t"); WW[a[2]] = WW[a[2]] " " a[1] ": " a[3] "." }
      while ((getline l < WO) > 0) { split(l, a, "\t"); if (a[1] == "step") X[a[2]] = 1 } }
    $1 !~ /:$/ { C[$1] = 1; r = $2; m = split(r, w, " "); gsub(/ /, ", ", r); if (!($1 in rn)) { print "- **" $1 "** (new" (($1 in P) ? "; the apply publishes it" : (($1 in X) ? "; not published by the apply: you left it out" : "; published later, by its publish move")) "): its tests " r "." (WW[$1] != "" ? " Warnings:" WW[$1] : ""); words(1); n++ }
      else if (rn[$1] != $3) { print "- **" $1 "** (changed): its tests " r "."; words(0); n++ } }
    END { for (i = 1; i <= nr; i++) if (!(RO[i] in C) && RO[i] !~ /:$/) { print "- **" RO[i] "** (no longer in the plan)"; n++ } if (!n) print "No step is new, split or changed." }' "$T/cs"
  printf '\n## What moves\n\n'
  if [ -s "$PD/moves" ]; then awk -F'\t' '{ if ($2 == "-") print "- " $1 ": into " $3 " (new to the plan)"; else if ($3 == "-") print "- " $1 ": out of " $2 ", into no step"; else print "- " $1 ": from " $2 " to " $3 }' "$PD/moves"; else printf 'No test moves.\n'; fi
  [ ! -s "$PD/taken-out" ] || awk -F'\t' '{ print "- " $1 ": taken out of #" $2 " into " $3 ", its new stage after the landed re-cut; your words to the apply are your words for it" }' "$PD/taken-out"
  [ ! -s "$T/su" ] || { printf '\n## What each step is the first to set up\n\nFrom the owned data of ARCHITECTURE.md'"'"'s seam table and the steps'"'"' modules, as the plan would be.\n\n'
    awk -F'\t' '{ printf "- %s: %s (%s)\n", ($1 == "-" ? "in no step" : "**" $1 "**"), $3, $2 }' "$T/su"; }
  printf '\n## Where the tests go: what two readers found\n\n'   # FB-4 A1, as the plan page shows it
  if [ -s "$PD/placements" ]; then sh "$HERE/planner.sh" placements show "$C/placement" --block "$C/block" --at HEAD --plan-md "$T/cpm" 2> "$T/e" || fail_ "the two readers' result could not be shown: $(tail -n 1 "$T/e")"; printf '\nYour words to the apply answer each finding shown here.\n'
  elif [ -n "${VID_REPLAN_OWN:-}" ]; then echo '- not reviewed: this proposal places no test'; else echo '- not reviewed: no placement to read'; fi
  printf '\n## The warnings\n\nEach is shown, never a refusal: your words to the apply are your words past them.\n\n'
  if [ -s "$PD/warnings" ]; then awk -F'\t' '{ print "- **" $1 "** " $2 ": " $3 }' "$PD/warnings"; else printf 'None.\n'; fi
  printf '\n## What it leaves alone, and why\n\n'
  if [ -s "$PD/left" ]; then awk -F'\t' '{ k = $1; s = $2; if (k == "no-step") k = "in no step"; else if (k == "other-stage") k = "left in its ticket"; else if (k == "kept") k = "to place"; else if (k == "team") k = "the team" "\047" "s addition"; else if (k == "step") k = "the new step"; print "- " k " " s ": " $3 }' "$PD/left"; else printf 'Nothing.\n'; fi
  printf '\n## The triggers it covers\n\n'
  if [ -s "$PD/triggers" ]; then awk -F'\t' -v LF="$PD/left" 'BEGIN { while ((getline l < LF) > 0) { split(l, a, "\t"); if (a[1] == "trigger") W[a[2]] = a[3]; if (a[1] == "kept") K["to-place-active " a[2]] = K["stage-to-correct " a[2]] = 1 } }
      { k = $2 " " $3; print "- " $1 ", " k " (" $4 "): " ((k in W) ? "left alone: " W[k] : (k in K) ? "left as it is" : "taken in by the changes below") }' "$PD/triggers"; else printf 'None.\n'; fi
  [ ! -s "$PD/team-in" ] || { printf '\n## The team'"'"'s additions it takes in\n\n'; awk -F'\t' '{ print "- " $2 " in #" $1 ", as the team added it: the apply records your yes to it" }' "$PD/team-in"; }
  printf '\n## The changes\n\n'
  if [ -s "$PD/changes" ]; then printf '| What | Trigger | Evidence | Expected effect |\n|---|---|---|---|\n'; awk -F'\t' '{ for (i = 1; i <= 4; i++) gsub(/\|/, "/", $i); print "| " $1 " | " $2 " | " $3 " | " $4 " |" }' "$PD/changes"; else printf 'No plan change.\n'; fi
  printf '\n## What is pending\n\n'
  if [ -s "$PD/pending" ]; then awk -F'\t' '$1 == "pending" { print "- " $2 ": " $3 } $1 == "spec" { print "- " $2 " changed (" $3 " lines)" } $1 != "pending" && $1 != "spec" { print "- " $0 }' "$PD/pending"; else printf 'Nothing.\n'; fi
  printf '\n## The review of the tests ViD adds\n\n'
  if grep -qx none "$PD/review"; then printf 'None to show.\n'; else sed 's/^finding /- /' "$PD/review"; printf '\nYour words to the apply answer each finding shown here as kept.\n'; fi
} > "$PD/REPLAN-PAGE.md"
rm -rf .vid/next/proposal; mv "$PD" .vid/next/proposal
sh "$HERE/page.sh" .vid/next/proposal/REPLAN-PAGE.md --out .vid/pages/REPLAN-PAGE.html > "$T/pg" 2>&1 || { sed 's/^/    /' "$T/pg" >&2; rm -rf .vid/next/proposal; ref 'the page could not be written — no proposal kept'; }
echo "ViD replan: the proposal is in .vid/next/proposal/ — the plan block $BH, the proposal $PH; nothing recorded or posted"
echo "page .vid/pages/REPLAN-PAGE.html"
