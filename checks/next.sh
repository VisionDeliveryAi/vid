#!/bin/sh
# Purpose: GitHub manual's call, read and judged (GM-1 S3, S4, S7, S8): the mode, the read kept, the pending changes, the
# rows a ticket quotes that differ, the team's changes to a ticket's tests, and the call's lines: the count, the triggers in
# their tiers, the context, the moves and their warnings. Run at the top of ViD's repository. It never calls gh itself and
# writes nothing to GitHub: `read` runs the one read (GM-4 F3) and keeps its output in .vid/round/read; every other subcommand
# only reads ViD's records, the spec in git and that file, and `triggers` writes nothing at all. GM-4 F15: the mode is read by
# devagent-start.sh mode, the one mode command; F4: the questions, the declines and the to-dos are the owner's queue's
# (queue.sh), never kept here
#   read               (GM-4 F3) sh checks/round.sh read and nothing else, the one entry of the one read (github.sh round-read
#                      --bodies in GitHub manual) into .vid/round/read: the round read and the ticket bodies, sub-issues and
#                      assignees, a part GitHub could not give an `unread` line of the read. A read that fails whole leaves
#                      .vid/round/read as it was and exits as round.sh read exits (1), so the call stops. .vid/round/read.prev is the
#                      connect's, never moved here
#   pending            (GM-1 S3) the changes since the applied version (.vid/tw/applied): reset, added and reached as
#                      `inventory.sh impact --base <applied> --tickets --detail` sorts them, its records and a journey's
#                      transitions left out (a transition goes with its row); then retired, an id of the applied commit's
#                      inventory that the working tree's does not hold, a record (a difference with no paying-step:) left out.
#                      INVENTORY.md has no other form of retirement: retiring a row is deleting its line, in a commit of its own
#                      (skills/vid-test-inventory §5); the handed record's `row <id> retired` state is cut (0.26.11.1.2, R5).
#                      Then (IR I6) one `spec` line for each of ARCHITECTURE.md, DECISIONS.md, BASELINE.md and
#                      GRADING-CHECKLIST.md, in that order, changed since the applied commit: <n> is the lines added plus
#                      the lines removed in a line diff of the file at the applied commit (none when it had none) against
#                      the working tree's (as the rows are read), each line first read with its spaces collapsed and
#                      trimmed and blank lines left out, so a change of spaces or blank lines alone lists no file.
#                      GM-3 U1: STAGES.md joins them, last, and PRD.md, first (a requirement reworded with
#                      its fail-if kept sorts no row, yet is a landed change); and before them `pending moved-stage <id>` for each row (kind row)
#                      whose stage column differs between the applied commit's rows table (planner.sh rows in a scratch copy
#                      of the spec there, as arows_ reads it for the retired rows) and the newest one (planner.sh rows
#                      --newest, the working tree's, as the count reads it). impact exits 0 with nothing to print, so any
#                      other exit is a failure: pending prints `unread pending - impact exited <k>[: <its first error line>]`
#                      alone and exits 1, nothing counted
#   differ <n> [<commit>]   each row ticket n's recorded writing (.vid/tw/out/issue-<n>.md, its ## Rows section's `> ` lines,
#                      as writer.sh rowsec writes them) quotes whose text differs from that row's inventory line at the commit,
#                      the working tree by default; a quoted row the inventory there lacks differs too. The inventory line is
#                      first cut as rowsec cuts it (proved-red:, golden:, module:, match:, an evidence: path, a row's test path,
#                      an `owed: prerequisite` note, a rule's or hostility row's one-path field), and a field the writing holds
#                      the field's pointers into ViD's records written "(ViD's records)" as writer.sh A1's unptr writes them
#                      (PTR), and a word lib.sh's PROF blanks read "(a word)", so those alone never read as a difference, and
#                      any other change, a pointer's included, does; spaces are compared collapsed
#   changes            (GM-1 S7) for each published ticket of the read: added, an inventory id (the working tree's or the
#                      applied commit's) in its body that its recorded writing, all its parts, does not name; dropped, when the
#                      body opens `Ticket #<n>, part 1 of <m>, writing <h>.` (ViD's own part 1), an id part 1 of the recorded
#                      writing names that the body no longer does, else (the project's own form) a row of the ticket (the log
#                      line's rows=) the body no longer names. Part 1 is the recorded writing's own `part 1` stretch when it holds
#                      the part lines, else writer.sh parts' first part of it. GM-2 T5, T7: dropped is against every id the kept body
#                      (.vid/tw/body/issue-<n>) ever held, when there is one; a change is not printed when an answer in
#                      .vid/next/team-answers covers it with the same evidence, or a `moved` line of that ticket names the id; an added
#                      id found only in the working tree's inventory is `pending-only`
#   triggers           (GM-1 S8, S4) the call's lines, from the records, .vid/round/read and the pending changes; GM-2 T9, GM-4 F4:
#                      each raised trigger shown or counted by what the last call raised and the owner's answers (queue.sh raise:
#                      .vid/decide/queue/raised and answers), which it reads and never writes
#   own-work           (GM-4 K11, L1) `on` or `off`: the newest `setup-answered key=own-work` line of .vid/plan/setup, the owner's
#                      words of the move own-work on|off; off when none is recorded. /vid next's step 2 writes nothing until on
#   evkeys <file>      (GM-4 F4) for each trigger and quiet line of the call's lines in the file, `<what> TAB <subject> TAB <tier>
#                      TAB <evidence key>`, the key the tiers compare, for queue.sh raise
# Line forms, tab-separated, one record a line (a list comma-separated, `-` when empty):
#   mode, read, pending, differ and changes:
#     pending <reset|added|reached|retired|moved-stage> <id>   (moved-stage, GM-3 U1: a row may also have a line of another kind)
#     spec <file> <n> lines               (IR I6) after the pending lines
#     differ <n> <id>
#     added <n> <id> <step, - or pending-only> <evidence>    dropped <n> <id> <step or -> <evidence>   (GM-2 §5) the evidence: for added,
#                                         the hash of the body lines naming the id; for dropped, the hash of the whole body
#     unread <part> <n or -> <why>        what could not be read, from next-read or here; nothing is counted from it. The rows
#                                         table read through lib.sh's mustread: a failed read stops triggers, exit 1, never an empty list
#   triggers, in this order:
#     unread <part> <n or -> <why>
#     count total <n>, then count <kind> <n> for each kind, in order: to-place added retired restated reset unpublished
#     counted <kind> <id> <evidence>      each test once, under the first kind it matches
#     trigger <critical|important|minor> <what> <subject> <evidence>, critical first, each shown at this call (GM-2 T9): a critical one
#       every call, an important one unless the last call raised it at the same tier and evidence key (GM-4 F4: queue.sh raise), a minor one never; a
#       declined one (the owner's queue's answer) never. The evidence key: a team change's evidence hash; else the hash of the evidence, every count of days left
#       out, and for an inventory id its first line in the working tree. What is one of
#       critical:  reset-taken retired-taken blocked close-twice close-shrink lane-gone apply-owed
#                  (GM-3 U4, U6: apply-owed, a post the newest apply left owed, subject #<n> or <step>, or, GM-4 K13, spec-publish, the
#                  folder's publish it left owed with one repository: see AO below; it never
#                  counts toward planning-analysis, which can post nothing)
#       important: to-place-active added-active stage-to-correct reset-not-taken reached-closed team-added team-dropped
#                  not-taken team-no-lane step-slow
#                  (GM-4 E10, GM M11: step-slow <step>, its published step ticket open and not accepted, out longer than twice the
#                  median time from publish to first acceptance (.vid/decide/accepted-at) of the step tickets accepted, once three
#                  have one; its evidence the ticket, its days out and the median, in whole days)
#       minor:     reached-open added-inactive reset-inactive record
#     quiet <tier> <what> <subject> <evidence> <unchanged|declined|minor>   raised, counted, not shown (GM-2 T9)
#     tiers critical=<n> important=<n> unchanged=<n> minor=<n> declined=<n>   every raised trigger counted once
#     withdrawn <#n> <why>               (GM-3 U2) an ask a landing in GitHub manual withdrew (.vid/next/withdrawn, written by
#                                         land.sh), its issue neither commented on nor closed: listed while the read shows the issue
#                                         open (every one when no read is kept or its round part is unread), for the owner to close
#     context sub <#ticket> <#parent> <#child> <state> <assignees> <title>
#     context own-work off <the move>     (GM-4 K11) while own work is off (next.sh own-work): step 2 writes nothing until the move
#     context ask <#n> <commit12> <the command that decides it>   (GM-4 K11, E1) each published ticket's unanswered `vid: decide`
#                                         ask in the read, /vid:vid-accept-step <n> <commit12>
#     context assigned <#n> <labels> <title>
#     move <kind> <subject> <hash> <what it needs or does>   (GM-2 T10) named by kind and subject: publish <step>, amend #<n> and
#                                         withdraw #<n> (writer.sh due's lines as it gives them), team-change #<n> <id>,
#                                         planning-analysis -, implement-replan -; the hash
#                                         git hash-object of `<kind> TAB <subject> TAB <what>` then its warning lines. GM-3 U6:
#                                         planning-analysis whenever anything is pending or on .vid/tw/to-place, or a critical or
#                                         important trigger is raised and not declined; implement-replan as replan.sh ready gives it
#                                         (`apply analysis`, a fresh proposal; `apply own`, its own, nothing pending adding a test;
#                                         each line carries the proposal's fingerprint, rpfp_, so its hash changes
#                                         with what the apply would do;
#                                         else not listed, and planning-analysis says why), read when anything is pending or
#                                         .vid/next/proposal is kept, never beneath replan.sh (VID_NEXT_NOREADY). GM-4 F9 (I5): a draft
#                                         of the door is the owner's queue's (queue.sh ask draft), never a move here
#                                         GM-4 K4 (GM M16): walk-stage <N>, read-walk <N> and write-summary <N>, while own
#                                         work is on, for each `walk <N>`, `walk-read <N>` and `summary <N>` line of step 2's
#                                         round.sh step (.vid/next/stage-moves), the vid-stage-close skill's
#                                         GM-3 U4: publish <step> also for a step whose tickets are closed when writer.sh due
#                                         owes its follow-up (`new step <S>`: an apply's follow-up left unposted)
#     warning <kind> <subject> <limit|stage-ahead|not-taken|size|withdraw> <the numbers> <the risk>     after its move: a publish's,
#                                         plan.sh warnings' lines (GM-4 K9: a helper that fails, one `unread warnings` line); size, one
#                                         team-added test more than a fifth of the ticket's tests at its last writing (T6); withdraw,
#                                         a dropped test its step's last (T7)
# The count's kinds (first match wins; a test already in a published ticket at its current text is not counted): to-place, on
# .vid/tw/to-place and in no published ticket; added, retired, pending; restated, a row a published ticket quotes whose text
# there differs from the working tree's (differ); reset, pending, in no published ticket; unpublished, in no published ticket
# (its step, or `in no step`). A test is a row of the working tree's rows table (planner.sh rows --newest) of kind row and
# class planned, moved or owed, its handed state not known-limit; a retired row counts only when the applied commit's rows
# table (planner.sh rows in a scratch copy of the spec there) gives it the same; known limits, records and later-phase rows
# are not counted. A stage is active while it has an open published ticket (the read's ticket lines). A ticket's stage, and a
# step's, is the stage most of its rows of class planned, moved or owed are in, the earliest on a tie, as the planner reads
# a step's. Taken: a `vid: claimed` comment on it, an assignee, or any sub-issue. A row's state reads .vid/decide/state then
# the handed record's `row` lines, the newest counting. With exactly one setup lane, a step naming no lane is that lane's.
# GM-3 S2: in GitHub manual a published ticket of kind step or skeleton is of the stage its recorded writing's header names
# (`- stage: <k>`), and the setup's team names and the plan's lanes are read lower-cased, as the planner reads them there.
# The owner items close-twice and close-shrink are close.sh's `twice` and `shrink` lines in each step's newest ask
# (.vid/decide/close/<step>/<k>/items) and each stage's newest candidate (.vid/decide/stage/<N>/<c>/items), unanswered in
# .vid/decide/queue/answers: queue.sh closes, its c_items (GM-4 F10). Every unpublished step of the plan block is publishable: no
# hold for its stage, builds-on, rule A, the graded gate or the open-ticket limit (S4); its warnings (limit, stage-ahead and
# not-taken) are the one helper's, plan.sh warnings (GM-4 K9, J2), printed after its move as the helper gives them, never made here.
# serves: tickets
set -eu
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
TAB=$(printf '\t')
die() { echo "ViD next: $*" >&2; exit 2; }
ref() { echo "ViD next: refused — $*" >&2; exit 1; }
RD=.vid/round/read; LOG=.vid/tw/log; HAND=.vid/tw/handed
TRIM='function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }'
# KEY: an inventory line's id, the first field, or the second on a rule, difference, exception, suppression, hostility or seam
# line (inventory.sh impact's key); REC: a record, a difference with no paying-step:
KEY="$TRIM"' function key(l,   a, k) { split(l, a, "|"); k = tr(a[1]); return (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr(a[2]) : k }
  function isrec(l,   a) { split(l, a, "|"); return tr(a[1]) == "difference" && l !~ /\|[ \t]*paying-step:/ }'

# PTR: writer.sh's ptr and unptr (GM-4 F10: writer.sh ptr prints them, never copied), so differ reads a
# quoted field against exactly what the writer wrote for it
PTR=$(sh "$HERE/writer.sh" ptr 2> /dev/null)
[ -n "$PTR" ] || die "writer.sh's ptr and unptr could not be read (writer.sh ptr)"
# invat [<commit>]: the inventory's lines, every ```vid-inventory block, at the commit, else the working tree's
invat() { if [ -n "${1:-}" ]; then git show "$1:INVENTORY.md" 2> /dev/null || return 1; else cat INVENTORY.md 2> /dev/null || true; fi | awk '/^```vid-inventory/ { b = 1; next } b && /^```/ { b = 0; next } b && !/^[ \t]*(#|$|grammar:)/'; }
# keys <file>: `<id><TAB><first field><TAB><record 1|0>`, each id once, its first line
keys() { awk "$KEY"' { k = key($0); if (k == "" || (k in s)) next; s[k] = 1; split($0, a, "|"); print k "\t" tr(a[1]) "\t" isrec($0) }' "$1"; }
needapplied() { A=$(applied); [ -n "$A" ] || ref 'no applied version: .vid/tw/applied names no commit (/vid mode manual records it)'; git rev-parse -q --verify "$A^{commit}" > /dev/null 2>&1 || ref ".vid/tw/applied names $A, no commit of this repository"; }
# pending_: $T/pend (`pending <kind> <id>`), $T/retk (a retired id and its first field), $T/rec (impact's records),
# $T/spec (`spec <file> <n> lines`, IR I6)
pending_() {
  needapplied
  # GM-3 U1: impact exits 0 when it has nothing to print, so every non-zero exit is a failure: the unread line, nothing counted
  _ik=0; sh "$HERE/inventory.sh" impact --base "$A" --tickets --detail > "$T/imp" 2> "$T/impe" || _ik=$?
  if [ "$_ik" -ne 0 ]; then _iw=$(grep -v '^[[:space:]]*$' "$T/impe" | head -n 1 | tr '\t' ' ')
    printf 'unread\tpending\t-\timpact exited %s%s\n' "$_ik" "${_iw:+: $_iw}"; exit 1; fi
  awk -F'\t' -v OFS='\t' '$3 == "transition" || $1 == "record" { next } $1 ~ /^(reset|added|reached)$/ { print "pending", $1, $2 }' "$T/imp" > "$T/pend"
  awk -F'\t' '$1 == "record" { print $2 }' "$T/imp" | sort -u > "$T/rec"
  invat "$A" > "$T/ia" || ref "INVENTORY.md cannot be read at $A"; invat > "$T/iw"; keys "$T/ia" > "$T/ka"; keys "$T/iw" > "$T/kw"
  awk -F'\t' 'FILENAME == ARGV[1] { W[$1] = 1; next } !($1 in W) && $3 == 0 { print $1 "\t" $2 }' "$T/kw" "$T/ka" > "$T/retk"
  awk -F'\t' -v OFS='\t' '{ print "pending", "retired", $1 }' "$T/retk" >> "$T/pend"
  # GM-3 U1: moved-stage, a row (kind row) of both rows tables whose stage differs: the applied commit's (arows_) and the newest's
  arows_ || exit 1; lread "$T/nrows" planner rows --newest || exit 1
  awk -F'\t' -v OFS='\t' 'FILENAME == ARGV[1] { if (!/^#/ && $2 == "row" && !($1 in A)) A[$1] = $5; next } /^#/ || $2 != "row" || (k[$1]++) { next }
    ($1 in A) && A[$1] != $5 { print "pending", "moved-stage", $1 }' "$T/arows" "$T/nrows" >> "$T/pend"
  # IR I6: the law files beyond the rows, each line read with its spaces collapsed and trimmed, blank lines left out; GM-3 U1: STAGES.md
  # too, and PRD.md first, so a requirement reworded with its fail-if kept still shows as pending
  : > "$T/spec"; for f in PRD.md ARCHITECTURE.md DECISIONS.md BASELINE.md GRADING-CHECKLIST.md STAGES.md; do
    { git show "$A:$f" 2> /dev/null || true; } | awk "$SQ" > "$T/sa"; { cat "$f" 2> /dev/null || true; } | awk "$SQ" > "$T/sw"
    n=$({ diff "$T/sa" "$T/sw" || true; } | grep -c '^[<>]' || true)
    [ "$n" -eq 0 ] || printf 'spec\t%s\t%s lines\n' "$f" "$n" >> "$T/spec"; done; }

# SQ: a line with its spaces collapsed and trimmed, a blank line left out (IR I6's spec lines)
SQ='{ gsub(/[ \t\r]+/, " "); sub(/^ /, ""); sub(/ $/, "") } $0 != ""'
# section <file> <name>: the lines of a `## <name>` section
section() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
# differ_ <n> [<commit>]: `differ <n> <id>` lines on stdout
differ_() {
  F=.vid/tw/out/issue-$1.md; [ -f "$F" ] || ref "#$1 has no recorded writing ($F)"
  if [ -n "${2:-}" ]; then git rev-parse -q --verify "$2^{commit}" > /dev/null 2>&1 || ref "$2 names no commit"; invat "$2" > "$T/di" || ref "INVENTORY.md cannot be read at $2"; else invat > "$T/di"; fi
  section "$F" Rows | sed -n 's/^> \{0,1\}//p' > "$T/dq"
  awk -v n="$1" -v INV="$T/di" "$KEY$PROF$PTR"'
    function norm(s) { gsub(/[ \t]+/, " ", s); return tr(s) }
    # cut: the line split on |, each field trimmed, less what rowsec leaves out; the fields in C[1..], their count returned
    function cut(l, C, inv,   f, m, i, x, y, k, c) { m = split(l, f, "|"); k = tr(f[1]); c = 0
      for (i = 1; i <= m; i++) { x = tr(f[i]); y = x; sub(/[ \t].*/, "", y)
        if (inv && (x ~ /^(proved-red|golden|module|match):/ || (x ~ /^evidence:/ && x !~ /^evidence:[ \t]*owed$/) || (k ~ /^ROW-/ && i == 8 && x !~ /^owed:/ && y ~ /\//) || x ~ /^owed:[ \t]*prerequisite/ || (k ~ /^(rule|hostility)$/ && i >= 4 && x !~ /[ \t:]/ && x ~ /\//))) continue
        C[++c] = norm(x) }
      while (c > 0 && C[c] == "") c--; return c }
    # same <quoted field> <inventory field>: equal as it stands, or as the writer writes it (unptr), its words blanked or not (profx)
    function same(q, v) { return q == v || q == norm(unptr(v)) || q == norm(unptr(profx(v))) }
    BEGIN { while ((getline l < INV) > 0) { k = key(l); if (k != "" && !(k in L)) L[k] = l } }
    { k = key($0); if (k == "" || (k in seen)) next; seen[k] = 1
      if (!(k in L)) { print "differ\t" n "\t" k; next }
      split("", Q); split("", V); a = cut($0, Q, 0); b = cut(L[k], V, 1); d = (a != b)
      for (i = 1; !d && i <= a; i++) if (!same(Q[i], V[i])) d = 1
      if (d) print "differ\t" n "\t" k }' "$T/dq"; }

# steps_: $T/steps, `<step><TAB><lane><TAB><rows, space-separated>`, the plan block's step lines in order, ranges written out
steps_() { plan_block | awk -F'|' "$RNG$TRIM"' /^[ \t]*step[ \t]/ { id = tr($1); sub(/^step[ \t]+/, "", id); ln = "-"; rw = ""
    for (i = 2; i <= NF; i++) { x = tr($i); if (x ~ /^lane:/) ln = tr(substr(x, 6)); else if (x ~ /^rows:/) rw = substr(x, 6) }
    gsub(/[ \t,]+/, " ", rw); m = split(rw, t, " "); r = ""; for (j = 1; j <= m; j++) if (t[j] != "") r = r " " rng(t[j])
    print id "\t" (ln == "" ? "-" : ln) "\t" substr(r, 2) }' > "$T/steps"; }
# pubs_: $T/pub, `<n><TAB><step><TAB><rows, space-separated>`, each ticket the log publishes and does not withdraw, its newest line
pubs_() { { cat "$LOG" 2> /dev/null || true; } | awk 'function kv(k,   i) { for (i = 3; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    $1 == "withdrawn" { W[$2] = 1 } ($1 == "published" || $1 == "amended") && $2 ~ /^[0-9]+$/ { if (!($2 in S)) O[++n] = $2; S[$2] = kv("step"); r = kv("rows"); gsub(/,/, " ", r); R[$2] = (r == "-" ? "" : r) }
    END { for (i = 1; i <= n; i++) if (!(O[i] in W)) print O[i] "\t" (S[O[i]] == "" ? "-" : S[O[i]]) "\t" R[O[i]] }' > "$T/pub"; }
# ids_: $T/ids, every inventory id of the working tree and, when one is recorded, of the applied commit, and every row id
# ((ROW|RULE|HOS|DIF|SEAM)-<n>, no transition) the log's rows= fields and the recorded writings (.vid/tw/out/issue-*.md) name
# anywhere in their text, so a row no inventory holds any longer is still read in a body, and a requirement or an answer the
# writing quotes is never read as a test
ids_() { invat > "$T/iw"; keys "$T/iw" | cut -f1 > "$T/ids"; A=$(applied); if [ -n "$A" ] && invat "$A" > "$T/ia" 2> /dev/null; then keys "$T/ia" | cut -f1 >> "$T/ids"; fi
  { cut -f3 "$T/pub" | tr ' ' '\n'; for f in .vid/tw/out/issue-*.md; do [ ! -f "$f" ] || cat "$f"; done; } |
    awk '{ m = split($0, w, /[^A-Za-z0-9_-]+/); for (i = 1; i <= m; i++) if (w[i] ~ /^(ROW|RULE|HOS|DIF|SEAM)-[0-9]+$/) print w[i] }' >> "$T/ids"
  for f in .vid/tw/body/issue-*; do [ ! -f "$f" ] || grep -v '^[[:space:]]*$' "$f" >> "$T/ids" || true; done   # GM-2 T5: every id a kept body holds
  sort -u "$T/ids" -o "$T/ids"; }
# named <file>: the inventory ids ($T/ids) the text names, each a whole word (no letter, digit, _ or - beside it), one a line
named() { awk -v IDS="$T/ids" 'BEGIN { while ((getline l < IDS) > 0) I[l] = 1 } { m = split($0, w, /[^A-Za-z0-9_-]+/); for (i = 1; i <= m; i++) if ((w[i] in I) && !(w[i] in s)) { s[w[i]] = 1; print w[i] } }' "$1"; }
# part1 <n> <file>: part 1 of the writing, into $T/p1
part1() { if grep -q "^Ticket #$1, part 1 of [0-9]*, writing " "$2"; then
    awk -v n="$1" 'index($0, "Ticket #" n ", part 1 of ") == 1 { on = 1; next } on && index($0, "Ticket #" n ", part ") == 1 { exit } on' "$2" > "$T/p1"
  else rm -rf "$T/parts"; sh "$HERE/writer.sh" parts "$2" "$1" "$T/parts" > /dev/null 2>&1 && [ -f "$T/parts/part-1.md" ] || return 1; cp "$T/parts/part-1.md" "$T/p1"; fi; }
# changes_: `added|dropped <n> <id> <step or -|pending-only> <evidence hash>` lines and `unread` lines on stdout
changes_() {
  [ -f "$RD" ] || { printf 'unread\tread\t-\tno read kept (.vid/round/read): run next.sh read\n'; return 0; }
  steps_; pubs_; ids_
  awk -F'\t' '{ n = split($3, a, " "); for (i = 1; i <= n; i++) if (!(a[i] in s)) { s[a[i]] = 1; print a[i] "\t" $1 } }' "$T/steps" > "$T/stepof"
  awk -F'\t' '$1 == "unread" && ($2 == "ticket" || $2 == "body") { print $3 }' "$RD" | sort -u > "$T/ubody"
  # GM-2 T5, T7: the answers and ViD's own moves out of a ticket (.vid/next/team-answers); the ids of the applied commit's inventory and
  # of the working tree's, for a pending-only id
  { cat .vid/next/team-answers 2> /dev/null || true; } > "$T/ta"; : > "$T/aids"; AC=$(applied)
  if [ -n "$AC" ] && invat "$AC" > "$T/cia" 2> /dev/null; then keys "$T/cia" | cut -f1 > "$T/aids"; echo "$AC" > "$T/aok"; else rm -f "$T/aok"; fi
  invat > "$T/ciw"; keys "$T/ciw" | cut -f1 > "$T/wids"
  for n in $(awk -F'\t' '$1 == "ticket" { print $2 }' "$RD"); do
    grep -qx "$n" "$T/ubody" && continue
    F=.vid/tw/out/issue-$n.md; [ -f "$F" ] || { printf 'unread\twriting\t%s\tno recorded writing (%s)\n' "$n" "$F"; continue; }
    awk -F'\t' -v n="$n" '$1 == "body" && $2 == n { print substr($0, length($1 $2) + 3) }' "$RD" > "$T/b"
    named "$T/b" | sort > "$T/bn"; named "$F" | sort > "$T/wn"
    comm -23 "$T/bn" "$T/wn" | sed 's/^/added	/' > "$T/ch"
    # dropped (GM-2 T5): against every id the kept body ever held, when there is one; else as phase 1 reads it
    if [ -f ".vid/tw/body/issue-$n" ]; then grep -v '^[[:space:]]*$' ".vid/tw/body/issue-$n" | sort -u > "$T/was"
    elif head -n 1 "$T/b" | grep -q "^Ticket #$n, part 1 of [0-9][0-9]*, writing [0-9a-f]*\.\$"; then
      part1 "$n" "$F" || { printf 'unread\twriting\t%s\tpart 1 of the recorded writing could not be made\n' "$n"; continue; }
      named "$T/p1" | sort > "$T/was"
    else awk -F'\t' -v n="$n" '$1 == n { m = split($3, a, " "); for (i = 1; i <= m; i++) print a[i] }' "$T/pub" | sort -u > "$T/was"; fi
    comm -23 "$T/was" "$T/bn" | sed 's/^/dropped	/' >> "$T/ch"
    # the evidence (GM-2 T7, §5): for an added id the hash of the body lines that name it, for a dropped one the hash of the whole body
    rm -rf "$T/ev"; mkdir -p "$T/ev"
    awk -F'\t' -v B="$T/b" -v D="$T/ev" 'BEGIN { while ((getline l < B) > 0) L[++nl] = l } { k++; f = sprintf("%s/%06d", D, k); printf "" > f
        if ($1 == "added") for (i = 1; i <= nl; i++) { m = split(L[i], w, /[^A-Za-z0-9_-]+/); for (j = 1; j <= m; j++) if (w[j] == $2) { print L[i] > f; break } }
        close(f) }' "$T/ch"
    HB=$(git hash-object "$T/b"); ls "$T/ev" | sed "s#^#$T/ev/#" | git hash-object --stdin-paths > "$T/evh"
    # printed unless an answer covers it with the same evidence, or a move of ViD's took the id out of this ticket (a `moved` line);
    # an added id found only in the working tree's inventory is pending-only
    awk -F'\t' -v n="$n" -v OFS='\t' -v HB="$HB" -v EH="$T/evh" -v AOK="$([ -f "$T/aok" ] && echo 1)" '
      FILENAME == ARGV[1] { S[$1] = $2; next } FILENAME == ARGV[2] { if ($1 == n) { if ($2 == "moved") MV[$3] = 1; else AN[$2, $3, $4] = 1 } next }
      FILENAME == ARGV[3] { AI[$1] = 1; next } FILENAME == ARGV[4] { WI[$1] = 1; next }
      { getline h < EH; e = ($1 == "added") ? h : HB; if (($1, $2, e) in AN || ($2 in MV)) next
        st = ($1 == "added" && AOK && ($2 in WI) && !($2 in AI)) ? "pending-only" : (($2 in S) ? S[$2] : "-"); print $1, n, $2, st, e }' "$T/stepof" "$T/ta" "$T/aids" "$T/wids" "$T/ch"
  done; }

# items_: the open owner items of kind close-twice and close-shrink, `<close-twice|close-shrink><TAB><key>` a line: GM-4 F10, the
# queue's own close items (queue.sh closes, read only), never read again here
items_() { sh "$HERE/queue.sh" closes; }
# arows_: $T/arows, the rows table at the applied commit: planner.sh rows run in a scratch copy of the five spec files there,
# PLAN.md at HEAD and ViD's plan records, the setup's github-mode lines left out so the copy is read as files
arows_() { : > "$T/arows"; A=$(applied); [ -n "$A" ] || return 0; AD=$T/ap; rm -rf "$AD"; mkdir -p "$AD/.vid/plan" "$AD/.vid/tw"
  for f in PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md; do git show "$A:$f" > "$AD/$f" 2> /dev/null || rm -f "$AD/$f"; done
  git show HEAD:PLAN.md > "$AD/PLAN.md" 2> /dev/null || { rm -f "$AD/PLAN.md"; [ ! -f PLAN.md ] || cp PLAN.md "$AD/PLAN.md"; }
  [ ! -f .vid/RUN-STATE.md ] || cp .vid/RUN-STATE.md "$AD/.vid/RUN-STATE.md"; [ ! -f .vid/tw/settings ] || cp .vid/tw/settings "$AD/.vid/tw/settings"
  { grep -v '^setup-answered key=github-mode ' .vid/plan/setup 2> /dev/null || true; } > "$AD/.vid/plan/setup"
  ( cd "$AD" && lread "$T/arows" planner rows ) || return 1; }   # GM-3 U1: a failed read refuses (lread) and returns 1; the caller stops
# teams_: the setup's teams, `<name><TAB><people><TAB><the line>` (GM-4 F10: planner.sh teams, the planner's reading, lower-cased
# in GitHub manual as it reads them there; none, devagent of one)
teams_() { mustread "$T/pteams" planner teams; awk -F'\t' 'NF >= 4 { print $1 "\t" $4 "\tteam: " $1 " | " $2 " | " $3 " | " $4 }' "$T/pteams"; }

# rpfp_ <analysis|own>: GM-3 U6, the fingerprint implement-replan's line carries, so its hash changes with
# what the apply would do: 12 hex of git hash-object over HEAD, replan.sh hash (what a proposal reads: the applied commit, the plan,
# the tickets' log lines, the to-place list, the team's answers, the read's ticket states and bodies), .vid/tw/handed, and for an
# analysis its proposal's files that say what the apply does, and the open-tickets limit and an analysis's
# warnings with their counts of days left out (never its triggers or page). The own
# proposal is made from exactly those reads, so the same reads give the same fingerprint, made yet or not
rpfp_() { { printf '== target\n'; git rev-parse HEAD; printf '== reads\n'; sh "$HERE/replan.sh" hash 2> /dev/null || echo unread
    printf '== handed\n'; cat "$HAND" 2> /dev/null || :
    # the open-tickets limit, a setting outside HEAD that the proposal's limit warnings read (own and analysis alike)
    printf '== limit\n'; grep '^open-tickets:' .vid/tw/settings 2> /dev/null || :
    if [ "$1" = analysis ]; then for _f in made target hash block PLAN.md changes amend publish followup taken-out team-in moves review left args; do
      printf '== %s\n' "$_f"; cat ".vid/next/proposal/$_f" 2> /dev/null || :; done
      # and its warnings, each count of days left out (as ekeys_ leaves them out), so a call later reads the same
      printf '== warnings\n'; sed -E 's/[0-9]+ days?( ago)?//g' .vid/next/proposal/warnings 2> /dev/null || :; fi; } | git hash-object --stdin | cut -c1-12; }

# GM-4 K11 (L1): ownwork_, `on` or `off`, the newest own-work line of the setup
ownwork_() { _o=$(sed -n 's/^setup-answered key=own-work value="\([a-z]*\)".*/\1/p' .vid/plan/setup 2> /dev/null | tail -n 1); [ "$_o" = on ] && echo on || echo off; }
# GM-4 E1: tasks_, each published ticket not withdrawn whose newest `vid: decide <a full commit>` comment no `vid: decision <it>`
# follows, `<n> TAB <commit>`, from the read's issue lines, as round.sh reads them
tasks_() { [ -f "$RD" ] || return 0; awk -F'\t' -v L="$LOG" 'BEGIN { while ((getline l < L) > 0) { split(l, x, " "); if (x[1] == "published") P[x[2]] = 1; else if (x[1] == "withdrawn") delete P[x[2]] } }
  $1 == "issue" && ($2 in P) { n = split($4, c, "\001"); a = ""; for (i = 1; i <= n; i++) { if (c[i] ~ /^vid: decide [0-9a-f]+[ \t]*$/) { y = c[i]; sub(/^vid: decide /, "", y); sub(/[ \t]*$/, "", y); if (length(y) == 40) { a = y; k = i } } }
    if (a == "") next; for (i = k + 1; i <= n; i++) if (c[i] ~ ("^vid: decision " a)) next; print $2 "\t" a }' "$RD"; }
# GM-4 E10 (GM M11): slow_, `SS TAB <step> TAB <evidence>` for each published step ticket open in the read and not accepted (no
# accepted-at line, no merge on record), out longer than twice the median time from publish to first acceptance of the step tickets
# accepted, once three have one
slow_() { [ -f "$RD" ] && [ -f "$LOG" ] && [ -s .vid/decide/accepted-at ] || return 0; _now=$(date -u +%s)
  awk '$1 == "published" && / kind=step / { s = ""; a = ""; for (i = 3; i <= NF; i++) { if ($i ~ /^step=/) s = substr($i, 6); if ($i ~ /^at=/) a = substr($i, 4) } if (!($2 in P)) { P[$2] = 1; print $2 "\t" s "\t" a } } $1 == "withdrawn" { print "w\t" $2 }' "$LOG" > "$T/sl0"
  : > "$T/sl1"; while IFS="$TAB" read -r n s a; do [ "$n" != w ] || continue; grep -qx "w$TAB$n" "$T/sl0" && continue; [ -n "$a" ] || continue
    f=$(awk -v n="$n" '$2 == n { for (i = 4; i <= NF; i++) if ($i ~ /^at=/) { print substr($i, 4); exit } }' .vid/decide/accepted-at)
    if [ -n "$f" ]; then printf 'a\t%s\n' "$(( $(epoch "$f") - $(epoch "$a") ))" >> "$T/sl1"
    elif awk -F'\t' -v n="$n" '$1 == "issue" && $2 == n { f = 1 } END { exit !f }' "$RD" && ! awk -F'\t' -v n="$n" '$2 == n { f = 1 } END { exit !f }' .vid/decide/merges 2> /dev/null; then
      printf 'o\t%s\t%s\t%s\n' "$n" "$s" "$(( _now - $(epoch "$a") ))" >> "$T/sl1"; fi; done < "$T/sl0"
  awk -F'\t' '$1 == "a" { d[++k] = $2 } $1 == "o" { o[++m] = $0 } END { if (k < 3) exit; for (i = 2; i <= k; i++) { x = d[i]; j = i - 1; while (j > 0 && d[j] + 0 > x + 0) { d[j + 1] = d[j]; j-- } d[j + 1] = x }
      md = (k % 2) ? d[(k + 1) / 2] : (d[k / 2] + d[k / 2 + 1]) / 2
      for (i = 1; i <= m; i++) { split(o[i], y, "\t"); if (y[4] + 0 > 2 * md) print "SS\t" y[3] "\t#" y[2] " out " int(y[4] / 86400) " days; the median from publish to first acceptance " int(md / 86400) " days" } }' "$T/sl1"; }
triggers_() {
  : > "$T/f"; : > "$T/pend"; : > "$T/retk"; : > "$T/rec"; : > "$T/spec"
  # GM-3 U1: a failed pending read is pending's own unread line, in its words, and nothing pending is counted from it
  if [ -n "$(applied)" ]; then ( pending_ ) > "$T/pe" 2>&1 || { : > "$T/pend"; : > "$T/retk"; : > "$T/rec"; : > "$T/spec"; rm -f "$T/nrows" "$T/arows"
      _pw=$(sed -n 's/^unread\tpending\t-\t//p' "$T/pe" | head -n 1); [ -n "$_pw" ] || _pw=$(grep -v '^[[:space:]]*$' "$T/pe" | tail -n 1 | sed 's/^ViD next: //')
      printf 'U\tpending\t-\t%s\n' "$_pw" >> "$T/f"; }
  else printf 'U\tpending\t-\tno applied version: .vid/tw/applied names no commit\n' >> "$T/f"; fi
  # the newest rows table pending read, when it did, else read here; a failed read stops the call (mustread)
  if [ -s "$T/nrows" ]; then cp "$T/nrows" "$T/rows"; else mustread "$T/rows" planner rows --newest; fi
  awk -F'\t' -v OFS='\t' '!/^#/ { print "R", $1, $2, $5, $6 }' "$T/rows" >> "$T/f"
  if [ -s "$T/retk" ]; then [ -s "$T/arows" ] || arows_ || exit 1; awk -F'\t' -v OFS='\t' '!/^#/ { print "AR", $1, $2, $6 }' "$T/arows" >> "$T/f"; fi
  { awk -F'\t' '{ print $1 "\t" $2 }' .vid/decide/state 2> /dev/null || true; sed -n 's/^row \([^ ]*\) \([^ |]*\).*/\1	\2/p' "$HAND" 2> /dev/null || true; } | sed 's/^/S	/' >> "$T/f"
  sed 's/^pending/P/' "$T/pend" >> "$T/f"; sed 's/^/C	/' "$T/rec" >> "$T/f"; sed 's/^spec/SP/' "$T/spec" >> "$T/f"
  { awk 'NF >= 2 { print "TP\t" $1 "\t" $2 }' .vid/tw/to-place 2> /dev/null || true; } >> "$T/f"
  steps_; pubs_; sed 's/^/ST	/' "$T/steps" >> "$T/f"; sed 's/^/PUB	/' "$T/pub" >> "$T/f"
  # GM-3 S2: in GitHub manual a published ticket of kind step or skeleton is of the stage its recorded writing's header names
  MN=''; if manual; then MN=1; cut -f1 "$T/pub" | while read -r n; do F=.vid/tw/out/issue-$n.md; [ -f "$F" ] || continue
    awk -v n="$n" '/^## / { h = ($0 ~ /^## Header[ \t]*$/); next } h && index($0, "- kind: ") == 1 { k = substr($0, 9) } h && index($0, "- stage: ") == 1 { v = substr($0, 10); sub(/,.*/, "", v); gsub(/[ \t]/, "", v) }
      END { if (k ~ /^(step|skeleton)[ \t]*$/ && v ~ /^[0-9]+$/) print "HS\t" n "\t" v }' "$F"; done >> "$T/f"; fi
  teams_ | sed 's/^/TEAM	/' >> "$T/f"; items_ | sed 's/^/ITEM	/' >> "$T/f"
  # GM-4 F10: each step's stage as the planner reads it (planner.sh steps), never written again here
  mustread "$T/psteps" planner steps; awk -F'\t' '{ print "PST\t" $1 "\t" $3 }' "$T/psteps" >> "$T/f"
  # GM-4 K9 (J2): the publish warnings are the one helper's, plan.sh warnings, for each step of the plan with no published ticket
  # (each the planner's steps hold); its lines kept as they are, after each step's publish move; a helper that fails is an unread line
  awk -F'\t' -v P="$T/pub" -v S="$T/psteps" 'BEGIN { while ((getline l < P) > 0) { split(l, x, "\t"); D[x[2]] = 1 } while ((getline l < S) > 0) { split(l, x, "\t"); K[x[1]] = 1 } }
    !($1 in D) && ($1 in K) { print $1 }' "$T/steps" > "$T/wst"
  if [ -s "$T/wst" ]; then if sh "$HERE/plan.sh" warnings $(cat "$T/wst") > "$T/pw" 2> "$T/pwe"; then awk '$1 == "warning" { print "PW\t" $0 }' "$T/pw" >> "$T/f"
    else printf 'U\twarnings\t-\tplan.sh warnings failed: %s\n' "$(grep -v '^[[:space:]]*$' "$T/pwe" | tail -n 1 | tr '\t' ' ')" >> "$T/f"; fi; fi
  # GM-3 U2: each ask a landing withdrew in GitHub manual (.vid/next/withdrawn), for the owner to close by hand
  { awk -F'\t' 'NF >= 4 { print "WD\t" $1 "\t" $4 }' .vid/next/withdrawn 2> /dev/null || true; } >> "$T/f"
  # GM-3 U6: implement-replan's state, replan.sh ready's (its rules), read when anything is pending or a proposal is kept, never by a
  # next.sh run beneath replan.sh (VID_NEXT_NOREADY, which replan.sh ready's own reads inherit). GM-4 F9 (I5): the door's drafts are
  # the owner's queue's, never read here
  if manual && [ -z "${VID_NEXT_NOREADY:-}" ] && { [ -s "$T/pend" ] || [ -s "$T/spec" ] || [ -d .vid/next/proposal ]; }; then
    if VID_NEXT_NOREADY=1 sh "$HERE/replan.sh" ready > "$T/rdy" 2> "$T/rdye"; then sed 's/^/RDY	/' "$T/rdy" >> "$T/f"
      # the fingerprint of the proposal implement-replan would apply, carried in its line (rpfp_)
      _k=$(awk -F'\t' '$1 == "apply" { print $2; exit }' "$T/rdy"); case $_k in analysis|own) printf 'RDY\tfp\t%s\n' "$(rpfp_ "$_k")" >> "$T/f" ;; esac
      # GM-4 proof D3: and the analysis's proposal as its page shows it (.vid/next/proposal/hash), so the owner can match the two
      [ "$_k" != analysis ] || printf 'RDY\tph\t%s\n' "$(cat .vid/next/proposal/hash 2> /dev/null)" >> "$T/f"
    else printf 'RDY\tfailed\t%s\n' "$(grep -v '^[[:space:]]*$' "$T/rdye" | tail -n 1 | sed 's/^ViD replan: //' | tr '\t' ' ')" >> "$T/f"; fi; fi
  # GM-4 K11: own work's switch, and each ticket's unanswered ask (round.sh's tasks_ reading); E10: the step tickets out too long
  printf 'OW\t%s\n' "$(ownwork_)" >> "$T/f"; tasks_ | sed 's/^/CA	/' >> "$T/f"; slow_ >> "$T/f"
  # GM-4 K4 (GM M16): while own work is on, step 2's walk, walk-read and summary lines (round.sh step keeps them whole in
  # .vid/next/stage-moves), each with its stage's newest candidate, for the moves walk-stage, read-walk and write-summary
  if manual && [ "$(ownwork_)" = on ]; then awk '$1 ~ /^(walk|walk-read|summary)$/ && $2 ~ /^[0-9]+$/ { print $1 "\t" $2 }' .vid/next/stage-moves 2> /dev/null |
    while IFS="$TAB" read -r _k _n; do _c=''; for _d in $(ls ".vid/decide/stage/$_n" 2> /dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f ".vid/decide/stage/$_n/$_d/ask" ] && _c=$_d; done
      printf 'SM\t%s\t%s\t%s\n' "$_k" "$_n" "${_c:--}"; done >> "$T/f"; fi
  printf 'PX\t%s\nNOW\t%s\n' "$(twkey labels-prefix)" "$(date -u +%s)" >> "$T/f"
  if [ -f "$RD" ]; then
    awk -F'\t' -v OFS='\t' '$1 == "unread" { print "U", $2, $3, substr($0, length($1 $2 $3) + 4) } $1 == "issue" { print "ISS", $2, $3, $4 } $1 == "open" { print "OPR", $2, $10 }
      $1 == "sub" || $1 == "assigned" { print }' "$RD" >> "$T/f"
    awk -F'\t' '$1 == "ticket" { print $2 "\t" $3 "\t" $4 "\t" $5 }' "$RD" | while IFS="$TAB" read -r n s a c; do printf 'TK\t%s\t%s\t%s\t%s\t%s\n' "$n" "$s" "$a" "$c" "$(epoch "$c")"; done >> "$T/f"
    changes_ | awk -F'\t' -v OFS='\t' '$1 == "unread" { print "U", $2, $3, $4; next } { print "CHG", $1, $2, $3, $4, $5 }' >> "$T/f"
    cut -f1 "$T/pub" | while read -r n; do [ -f ".vid/tw/out/issue-$n.md" ] || continue; ( differ_ "$n" ) 2> /dev/null | sed 's/^differ/DIF/' || true; done >> "$T/f"
    # GM-2 T10: the amendments and withdrawals writer.sh due owes, listed as it gives them; a due that fails is an unread line
    # writer.sh's load makes .vid/tw/out, the log and the handed record when one is missing, so due runs only when all three are
    # there: triggers writes nothing
    if [ -s "$T/pub" ] && { [ ! -d .vid/tw/out ] || [ ! -f "$LOG" ] || [ ! -f "$HAND" ]; }; then printf 'U\tdue\t-\twriter.sh due not run: it would make .vid/tw/out, .vid/tw/log or .vid/tw/handed, so no amendment or withdrawal is listed\n' >> "$T/f"
    elif [ -s "$T/pub" ]; then if ( sh "$HERE/writer.sh" due ) > "$T/due" 2> "$T/duee"; then awk '$1 == "amend" || $1 == "withdraw" || ($1 == "new" && $2 == "step") { print "DUE\t" $0 }' "$T/due" >> "$T/f"
      else printf 'U\tdue\t-\twriter.sh due failed: %s\n' "$(grep -v '^[[:space:]]*$' "$T/duee" | tail -n 1 | tr '\t' ' ')" >> "$T/f"; fi; fi
    # GM-3 U4, U6: the posts the newest apply left owed (AO), read from its records, no new one: .vid/tw/applied.log's newest apply
    # line, and the proposal it applied (.vid/next/applied-proposal, its target that line's commit). Owed: a ticket of its amend
    # that writer.sh due still owes an amendment, a follow-up of its followup that due still owes (`new step`), and a step of its
    # publish, each with no amended or published line in .vid/tw/log since that apply's time; GM-4 K13: and the folder's publish the
    # apply left owed (its proposal's spec-publish), with no spec-published line since; FB-1 B6: each line read up to its ` words="`,
    # so the owner's words never change what it reads
    _al=$(awk -F'\t' '$3 == "apply" { l = $1 "\t" $2 } END { print l }' .vid/tw/applied.log 2> /dev/null || true); _ap=.vid/next/applied-proposal
    if [ -n "$_al" ] && [ -f "$_ap/target" ] && [ "$(head -n 1 "$_ap/target")" = "${_al%%"$TAB"*}" ]; then
      { [ ! -f "$T/due" ] || { sed 's/^/A	/' "$_ap/amend"; sed 's/^/F	/' "$_ap/followup"; } 2> /dev/null | awk -F'\t' -v DUE="$T/due" '
          BEGIN { while ((getline l < DUE) > 0) { split(l, d, " "); if (d[1] == "amend") D["a", d[2]] = 1; if (d[1] == "new" && d[2] == "step") D["s", d[3]] = 1 } }
          $1 == "A" && (("a", $2) in D) { print "amend\t#" $2 } $1 == "F" && (("s", $2) in D) { print "publish\t" $2 }'
        grep -v '^[[:space:]]*$' "$_ap/publish" 2> /dev/null | sed 's/^/publish	/'
        [ ! -s "$_ap/spec-publish" ] || printf 'spec-publish\tspec-publish\n'; } | sort -u |
      awk -F'\t' -v L="$LOG" -v AT="${_al#*"$TAB"}" -v A="$(printf %.12s "${_al%%"$TAB"*}")" 'BEGIN { while ((getline l < L) > 0) { p = index(l, " words=\""); if (p) l = substr(l, 1, p - 1); n = split(l, w, " "); t = ""; s = ""
          for (i = 2; i <= n; i++) { if (w[i] ~ /^at=/) t = substr(w[i], 4); if (w[i] ~ /^step=/) s = substr(w[i], 6) } if (t < AT) continue
          if (w[1] == "amended") X["#" w[2]] = 1; if (w[1] == "published" && s != "") X[s] = 1; if (w[1] == "spec-published") X["spec-publish"] = 1 } }
        !($2 in X) { print "AO\t" $1 "\t" $2 "\t" A }' >> "$T/f"; fi
    # FB-1 B5: and in GitHub manual the folder's publish while .vid/tw/spec-owed stands, from that file alone, whatever the apply's
    # records say (a publish failed before any apply, after a switch, too): `owed:<export 12>` in place of the apply
    if [ -n "$MN" ] && [ -f .vid/tw/spec-owed ] && ! grep -q "^AO${TAB}spec-publish${TAB}" "$T/f"; then printf 'AO\tspec-publish\tspec-publish\towed:%s\n' "$(head -n 1 .vid/tw/spec-owed | cut -c1-12)" >> "$T/f"; fi
  else printf 'U\tread\t-\tno read kept (.vid/round/read): run next.sh read\n' >> "$T/f"; fi
  awk -F'\t' -v OFS='\t' -v WR="$HERE/writer.sh" -v MN="$MN" '
    function num(s) { return s ~ /^[0-9]+$/ }
    function add(a, x) { return a == "" ? x : a "," x }
    function trig(t, w, s, e) { TG[t] = TG[t] "trigger\t" t "\t" w "\t" s "\t" e "\n"; if (t != "minor") CI++ }
    $1 == "U" { print "unread", $2, $3, $4; UN[$2, $3] = 1; UP[$2] = 1; next }
    $1 == "R" { if (!($2 in RK)) RO[++nr] = $2; RK[$2] = $3; RG[$2] = $4; RC[$2] = $5; next }
    $1 == "S" { ST[$2] = $3; next }
    $1 == "P" { P[$3, $2] = 1; if (!($3 in PI)) NPI++; PI[$3] = 1; if (!($3 in PO)) { PO[$3] = ++np; PL[np] = $3 } next }
    $1 == "AR" { if (!($2 in ARK)) { ARK[$2] = $3; ARC[$2] = $4 } next }
    $1 == "C" { REC[++nc] = $2; next }
    $1 == "SP" { NSP++; next }
    $1 == "TP" { TP[$2] = $3; ntp++; if (!($2 in PO)) { PO[$2] = ++np; PL[np] = $2 } next }
    $1 == "RDY" { if ($2 == "apply") { RYS = $3; RYW = $4 } else if ($2 == "review") RYV = $3; else if ($2 == "failed") RYF = $3; else if ($2 == "fp") RYP = $3; else if ($2 == "ph") RYH = $3; next }
    $1 == "HS" { HS[$2] = $3; next } $1 == "PST" { PSTG[$2] = $3; next }
    $1 == "ST" { SO[++ns] = $2; SL[$2] = (MN ? tolower($3) : $3); SR[$2] = $4; m = split($4, a, " "); for (i = 1; i <= m; i++) if (!(a[i] in STEP)) STEP[a[i]] = $2; next }
    $1 == "PUB" { TO[++nt] = $2; TS[$2] = $3; TR[$2] = $4; PS[$3] = 1; m = split($4, a, " "); for (i = 1; i <= m; i++) IN[a[i]] = add(IN[a[i]], $2); next }
    $1 == "TEAM" { TM[++nm] = $2; TL[$2] = $4; if ($3 == 1) { LN[$2] = 1; LO1 = $2; nln++ } else for (i = 1; i <= $3; i++) { LN[$2 "-" i] = 1; LO1 = $2 "-" i; nln++ } next }
    $1 == "ITEM" { TG["critical"] = TG["critical"] "trigger\tcritical\t" $2 "\t" $3 "\tthe owner item " $3 " in .vid/decide, unanswered\n"; CI++; next }
    $1 == "PX" { PX = $2; next } $1 == "NOW" { NOW = $2; next }
    $1 == "PW" { PWL[$4] = PWL[$4] substr($0, 4) "\n"; next }
    $1 == "ISS" { IL[$2] = "," $3 ","; IH[$2] = $4; next }
    $1 == "sub" { SUBL[++nsub] = $0; HASSUB[$2] = 1; next }
    $1 == "assigned" { ASL[++nas] = $0; next }
    $1 == "TK" { TKS[$2] = $3; TKA[$2] = $4; TKC[$2] = $5; TKE[$2] = $6; next }
    $1 == "CHG" { CH[++nch] = $2 SUBSEP $3 SUBSEP $4 SUBSEP $5 SUBSEP $6; next }
    $1 == "DUE" { DU[++ndu] = substr($0, 5); next }
    $1 == "AO" { AOO[++nao] = $3; AO[$3] = $4; next }
    $1 == "DIF" { DIF[$3] = add(DIF[$3], $2); next }
    $1 == "WD" { if (!($2 in WDS)) WDO[++nwd] = $2; WDS[$2] = $3; next }
    $1 == "OW" { OWK = $2; next } $1 == "CA" { CAO[++nca] = $2; CAC[$2] = substr($3, 1, 12); next } $1 == "SS" { SSO[++nss] = $2 "\t" $3; next }
    $1 == "SM" { if (!(($2, $3) in SMS)) { SMS[$2, $3] = 1; SMK[++nsm] = $2; SMN[nsm] = $3; SMC[nsm] = $4 } next }
    END {
      # with exactly one lane, a step naming none is that lane'"'"'s, as the planner reads it
      if (nln == 1) for (i = 1; i <= ns; i++) if (SL[SO[i]] == "-" || SL[SO[i]] == "") SL[SO[i]] = LO1
      # the tests: rows of kind row, class planned, moved or owed, not a known limit by its handed state
      for (i = 1; i <= nr; i++) { r = RO[i]; if (RK[r] == "row" && RC[r] ~ /^(planned|moved|owed)$/ && ST[r] != "known-limit") { TEST[r] = 1; U[++nu] = r } }
      # a retired row, when the applied commit'"'"'s rows table gives it kind row and class planned, moved or owed, and it is no known limit
      for (i = 1; i <= np; i++) { r = PL[i]; if (P[r, "retired"] && ARK[r] == "row" && ARC[r] ~ /^(planned|moved|owed)$/ && ST[r] != "known-limit" && !(r in TEST)) { U[++nu] = r; TEST[r] = 1 } }
      # each ticket: its stage, taken, how
      for (i = 1; i <= nt; i++) { n = TO[i]; TST[n] = ((n in HS) ? HS[n] : PSTG[TS[n]])   # GM-3 S2: the ticket'"'"'s header, in GitHub manual; else its step'"'"'s (GM-4 F10)
        h = ""; if (index("\001" IH[n] "\001", "\001vid: claimed")) h = add(h, "a vid: claimed comment"); if (TKA[n] != "" && TKA[n] != "-") h = add(h, "assignee " TKA[n]); if (n in HASSUB) h = add(h, "a sub-issue")
        TK_[n] = h; if (TKS[n] == "OPEN" && num(TST[n])) ACT[TST[n]] = 1 }
      # the count (N8)
      split("to-place added retired restated reset unpublished", KN, " "); for (i = 1; i <= nu; i++) { r = U[i]; it = (r in IN); d = (r in DIF); k = ""; e = ""
        if (!P[r, "retired"] && it && !d) continue
        if ((r in TP) && !it) { k = "to-place"; e = "to-place " TP[r] }
        else if (P[r, "added"]) { k = "added"; e = "pending added" }
        else if (P[r, "retired"]) { k = "retired"; e = "pending retired" (it ? ", in #" IN[r] : "") }
        else if (it && d) { k = "restated"; e = "quoted differently in #" DIF[r] }
        else if (P[r, "reset"]) { k = "reset"; e = "pending reset" }
        else if (!it) { k = "unpublished"; e = (r in STEP) ? "step " STEP[r] : "in no step" }
        if (k == "") continue; CN[k]++; tot++; CL = CL "counted\t" k "\t" r "\t" e "\n" }
      print "count", "total", tot + 0; for (i = 1; i <= 6; i++) print "count", KN[i], CN[KN[i]] + 0; printf "%s", CL
      # the triggers (N15), each id once, its first tier
      for (i = 1; i <= np; i++) { r = PL[i]; it = (r in IN); tk = ""; cl = ""; op = ""; nt_ = ""
        if (it) { m = split(IN[r], a, ","); for (j = 1; j <= m; j++) { if (TK_[a[j]] != "") tk = add(tk, "#" a[j] " (" TK_[a[j]] ")"); else nt_ = add(nt_, "#" a[j]); if (TKS[a[j]] == "CLOSED") cl = add(cl, "#" a[j]); if (TKS[a[j]] == "OPEN") op = add(op, "#" a[j]) } }
        g = RG[r]; ac = num(g) && (g in ACT)
        if (P[r, "reset"] && tk != "") trig("critical", "reset-taken", r, "pending reset; in " tk)
        else if (P[r, "retired"] && tk != "") trig("critical", "retired-taken", r, "pending retired; in " tk)
        else if ((r in TP) && !it && ac) trig("important", "to-place-active", r, "to-place " TP[r] "; stage " g " has an open ticket")
        else if (P[r, "added"] && ac) trig("important", "added-active", r, "pending added; stage " g " has an open ticket")
        else if ((r in TP) && it) trig("important", "stage-to-correct", r, "to-place " TP[r] "; in #" IN[r] ((r in STEP) ? ", step " STEP[r] : "") (num(g) ? " of stage " g : ""))
        else if (P[r, "reset"] && nt_ != "") trig("important", "reset-not-taken", r, "pending reset; in " nt_ ", not taken")
        else if (P[r, "reached"] && cl != "") trig("important", "reached-closed", r, "pending reached; its ticket " cl " is closed")
        else if (P[r, "reached"] && op != "") trig("minor", "reached-open", r, "pending reached; in open " op)
        else if (P[r, "added"] && !ac) trig("minor", "added-inactive", r, "pending added; stage " (g == "" ? "?" : g) " has no open ticket")
        else if (P[r, "reset"] && !it && !ac) trig("minor", "reset-inactive", r, "pending reset; stage " (g == "" ? "?" : g) " has no open ticket") }
      for (i = 1; i <= nc; i++) trig("minor", "record", REC[i], "a record changed since the applied version")
      for (n in IL) if (index(IL[n], "," PX "blocked,")) trig("critical", "blocked", "#" n, "label " PX "blocked")
      # GM-3 U4, U6: a post the newest apply left owed, its cause the apply
      for (i = 1; i <= nao; i++) { x = AOO[i]; if (x == "spec-publish") { trig("critical", "apply-owed", x, (AO[x] ~ /^owed:/ ? "a call to GitHub in the folder publish of export " substr(AO[x], 6) " did not finish, which" : "the apply " AO[x]) " left the spec'"'"'s publish into the code repository'"'"'s folder owed: no ticket quoting it goes out before it; /vid:vid-spec-publish publishes it, and each post publishes it first"); continue }
        trig("critical", "apply-owed", x, "the apply " AO[x] " left it owed: its post did not go out; the " (x ~ /^#/ ? "amend" : "publish") " move posts it") }
      for (i = 1; i <= ns; i++) { s = SO[i]; if (SL[s] != "-" && !(SL[s] in LN)) { g = ""; for (x in LN) g = add(g, x); trig("critical", "lane-gone", s, "lane: " SL[s] "; the setup gives " g) } }
      for (i = 1; i <= nch; i++) { split(CH[i], CC, SUBSEP); trig("important", "team-" CC[1], "#" CC[2] " " CC[3], (CC[4] == "-" ? "in no step" : CC[4] == "pending-only" ? "only in the pending spec" : "step " CC[4]) ", evidence " CC[5]) }
      for (i = 1; i <= nt; i++) { n = TO[i]; if (TKS[n] != "OPEN" || TK_[n] != "" || TKE[n] + 0 == 0 || (("ticket", n) in UN) || (("sub", n) in UN) || ("round" in UP)) continue
        dd = int((NOW - TKE[n]) / 86400); if (NOW - TKE[n] > 7 * 86400) { trig("important", "not-taken", "#" n, "created " TKC[n] ", " dd " days ago; no vid: claimed comment, assignee or sub-issue") } }
      for (i = 1; i <= nss; i++) { split(SSO[i], a, "\t"); trig("important", "step-slow", a[1], a[2]) }   # GM-4 E10
      for (i = 1; i <= nm; i++) { t = TM[i]; u = 0; for (j = 1; j <= ns; j++) { l = SL[SO[j]]; if (l == t || index(l, t "-") == 1 && substr(l, length(t) + 2) ~ /^[0-9]+$/) u = 1 } if (!u) trig("important", "team-no-lane", t, TL[t]) }
      printf "%s%s%s", TG["critical"], TG["important"], TG["minor"]
      # GM-3 U2: each ask a landing withdrew, while the read shows its issue open (a read missing or its round unread: each one)
      for (i = 1; i <= nwd; i++) { n = WDO[i]; if (!("read" in UP) && !("round" in UP) && !(n in IL)) continue; print "withdrawn", "#" n, WDS[n] }
      # the context
      for (i = 1; i <= nsub; i++) { split(SUBL[i], a, "\t"); print "context", "sub", "#" a[2], "#" a[3], "#" a[4], a[5], a[6], a[7] }
      for (i = 1; i <= nas; i++) { split(ASL[i], a, "\t"); print "context", "assigned", "#" a[2], a[3], a[6] }
      # GM-4 K11: own work off, its move listed; each unanswered ticket ask with the command that decides it
      if (MN && OWK != "on") print "context", "own-work", "off", "own-work on \"<your words>\": until you name it, step 2 decides, asks and posts nothing"
      for (i = 1; i <= nca; i++) { n = CAO[i]; print "context", "ask", "#" n, CAC[n], "/vid:vid-accept-step " n " " CAC[n] }
      # the moves, each publish with its warnings (N13), the one helper (GM-4 K9)
      # FB-1 B3: the words asked for on a publish, amend or withdraw move in GitHub manual alone (optional in GitHub auto, K1)
      NW = MN ? "; needs your words" : ""
      # GM-2 T10: each move named by its kind and its subject, `@` its hash until hashmoves; each warning after its move
      for (i = 1; i <= nt; i++) STK[TS[TO[i]]] = add(STK[TS[TO[i]]], "#" TO[i])
      for (i = 1; i <= ns; i++) { s = SO[i]; if (s in PS) continue; r = SR[s]; gsub(/ /, ",", r); print "move", "publish", s, "@", "publishes the ticket of " s ", its tests " (r == "" ? "-" : r) ((s in AO) ? "; owed by the apply " AO[s] ", whose post did not go out" : "") NW
        printf "%s", PWL[s] }   # GM-4 K9 (J2): the lines plan.sh warnings gives
      # the amendments and withdrawals writer.sh due owes, as it gives them (GM-2 T5, T6)
      # an amendment names what it would do, so its hash changes with it: the ticket'"'"'s tests at its last
      # writing and its step'"'"'s tests in the plan now
      for (i = 1; i <= ndu; i++) { split(DU[i], a, " "); if (a[1] != "amend") continue; n = a[2]; o = TR[n]; gsub(/ /, ",", o); w = SR[TS[n]]; gsub(/ /, ",", w)
        print "move", "amend", "#" n, "@", "amends #" n ", its tests " (o == "" ? "-" : o) " at its last writing, step " TS[n] "'"'"'s tests now " (w == "" ? "-" : w) ", as writer.sh due owes it" ((("#" n) in AO) ? "; owed by the apply " AO["#" n] ", whose post did not go out" : "") NW }
      # GM-3 U4: a follow-up writer.sh due owes for a step whose tickets are closed, the reset or reached tests
      # of a closed ticket (a follow-up the apply did not post), listed as the publish move of that step
      for (i = 1; i <= ndu; i++) { split(DU[i], a, " "); if (a[1] == "new" && a[2] == "step" && (a[3] in PS)) print "move", "publish", a[3], "@", "publishes the follow-up of " a[3] ", the reset or reached tests of its closed ticket, as writer.sh due owes it" ((a[3] in AO) ? "; owed by the apply " AO[a[3]] ", whose post did not go out" : "") NW }
      for (i = 1; i <= ndu; i++) { split(DU[i], a, " "); if (a[1] == "withdraw") print "move", "withdraw", "#" a[2], "@", "withdraws #" a[2] ", as writer.sh due owes it (" DU[i] ")" NW }
      # the team'"'"'s changes (GM-2 T7): a pending-only one is the apply move'"'"'s; a yes to an added test of another step'"'"'s published ticket
      # takes it out of that ticket; the size flag (T6) when one test is more than a fifth of the ticket'"'"'s tests at its last writing; a
      # yes to a dropped test that is its step'"'"'s last withdraws the ticket
      for (i = 1; i <= nch; i++) { split(CH[i], CC, SUBSEP); sj = "#" CC[2] " " CC[3]
        if (CC[4] == "pending-only") { print "move", "team-change", sj, "@", CC[1] " " CC[3] " on #" CC[2] ", only in the pending spec, evidence " CC[5] ": a yes comes in through planning-analysis and implement-replan; needs no, and your words"; continue }
        o = (CC[1] == "added" && CC[4] != "-" && CC[4] != TS[CC[2]] && STK[CC[4]] != "") ? ", a yes takes it out of " STK[CC[4]] " (step " CC[4] ")" : ""
        print "move", "team-change", sj, "@", "takes in or declines: " CC[1] " " CC[3] " on #" CC[2] ", " (CC[4] == "-" ? "in no step" : "step " CC[4]) ", evidence " CC[5] o "; needs yes or no, and your words"
        tn = split(TR[CC[2]], a, " "); tf = ""; if (CC[1] == "added") { tc = "sh \"" WR "\" topup 1 " tn; tc | getline tf; close(tc) }   # GM-2 T6: the size flag, one rule in writer.sh topup
        if (tf != "") print "warning", "team-change", sj, "size", "1 test added to the " tn " tests of #" CC[2] " at its last writing, more than a fifth", "a ticket grown past what it was written to build"
        ws = TS[CC[2]]; if (CC[1] == "dropped" && ws != "-" && split(SR[ws], a, " ") == 1 && a[1] == CC[3]) print "warning", "team-change", sj, "withdraw", CC[3] " is the last test of step " ws ": a yes withdraws #" CC[2] ", its test to the to-place list", "a ticket withdrawn" }
      # GM-4 K4 (GM M16): the stage'"'"'s walk and summary, moves the owner names (vid-stage-close)
      for (i = 1; i <= nsm; i++) { n = SMN[i]; c = SMC[i]
        if (SMK[i] == "walk") print "move", "walk-stage", n, "@", "starts stage " n "'"'"'s walk of candidate " c ": its brief, then the walker, a session of its own; no call waits for it; needs your words"
        else if (SMK[i] == "walk-read") print "move", "read-walk", n, "@", "reads the walk of stage " n "'"'"'s candidate " c ", its walker ended; needs your words"
        else print "move", "write-summary", n, "@", "writes the facts of stage " n "'"'"'s summary at candidate " c ", every close condition met, for its summary in plain product words; needs your words" }
      # GM-3 U6: the re-plan'"'"'s moves. planning-analysis with what it would take in (IR I6: the rows and spec files pending, counted
      # apart; the tests to place), tiers_ adding the critical and important triggers not declined and dropping it when it takes in
      # nothing; implement-replan as replan.sh ready gives it. GM-4 K9: both are moves of /vid next, in GitHub manual alone; in GitHub auto
      # the run manager re-plans from the triggers itself (the vid-replan skill, its GitHub auto paragraph)
      pa = (NPI || NSP) ? "the pending changes, " (NPI + 0) " rows, " (NSP + 0) " spec files" : ""; if (ntp) pa = (pa == "" ? "" : pa "; ") ntp " tests to place"
      pnt = (RYS == "analyse") ? "implement-replan needs it first: " RYW : (RYF != "" ? "implement-replan is not listed, replan.sh ready refused: " RYF : "")
      if (MN) print "move", "planning-analysis", "-", "@", pa, pnt
      if (RYS == "analysis") print "move", "implement-replan", "-", "@", "applies the analysis'"'"'s proposal " RYH ", the plan " RYW ", as its page shows (its fingerprint " RYP "); needs your words"
      else if (RYS == "own") print "move", "implement-replan", "-", "@", "applies the pending changes with its own proposal " RYP ", nothing in them adding a test: " RYW (RYV == "needed" ? "; the rows ViD'"'"'s planner adds need a fresh agent'"'"'s review first" : "") "; needs your words"
    }' "$T/f" > "$T/o"
  tiers_ "$T/o" > "$T/o2"; hashmoves "$T/o2"; }
# ekeys_ <file>: for each `<what> TAB <subject> TAB <tier> TAB <evidence>` line, the same with its evidence key in place of the evidence
# (GM-2 T9, §5): a team change's evidence hash exactly (its evidence's `evidence <hash>`); else the hash of the evidence with every
# count of days left out and, when the subject is an id of the working tree's inventory, a newline and its first line there
ekeys_() { invat > "$T/ekw"; rm -rf "$T/ek"; mkdir -p "$T/ek"
  awk -F'\t' -v INV="$T/ekw" -v D="$T/ek" "$KEY"' BEGIN { while ((getline l < INV) > 0) { k = key(l); if (k != "" && !(k in L)) L[k] = l } }
    { n++; f = sprintf("%s/%06d", D, n); e = $4; if ($1 ~ /^team-/) { sub(/.*evidence /, "", e); print "=" e > f } else { gsub(/[0-9]+ days?( ago)?/, "", e); print e > f; if ($2 in L) print L[$2] > f } close(f) }' "$1"
  ls "$T/ek" | sed "s#^#$T/ek/#" > "$T/ekl"; git hash-object --stdin-paths < "$T/ekl" > "$T/ekh"
  awk -F'\t' -v OFS='\t' -v L="$T/ekl" -v H="$T/ekh" '{ getline f < L; getline h < H; c = ""; getline c < f; close(f); if (c ~ /^=/) h = substr(c, 2); print $1, $2, $3, h }' "$1"; }
# tiers_ <file>: the call's lines with each raised trigger shown or counted (GM-2 T9, §5; GM-4 F4, the owner's queue): its key
# `trigger:<what>:<tier>:<evidence key, 12>:<subject>` as queue.sh raise keeps it in .vid/decide/queue/raised. Declined when the
# raised line holds that key and the queue's answers decline it at that raising (`<key>@<since>`); else a critical one shown; an
# important one shown unless the last call raised it with that key, then counted unchanged; a minor one counted. Shown as
# `trigger`, then the counted as `quiet … <unchanged|declined|minor>`, then `tiers`; planning-analysis counts the critical and
# important not declined
tiers_() { awk -F'\t' -v OFS='\t' '$1 == "trigger" { print $3, $4, $2, $5 }' "$1" > "$T/tl"; ekeys_ "$T/tl" > "$T/tk"
  awk -F'\t' -v OFS='\t' -v TK="$T/tk" -v RA=.vid/decide/queue/raised -v QA=.vid/decide/queue/answers '
    BEGIN { while ((getline l < RA) > 0) { split(l, x, "\t"); S[x[1]] = x[2] } while ((getline l < QA) > 0) { split(l, x, "\t"); if (x[3] == "decline") D[x[2]] = 1 } }
    $1 == "trigger" { getline k < TK; split(k, K, "\t"); t = $2; w = $3; s = $4; ky = "trigger:" w ":" t ":" substr(K[4], 1, 12) ":" s
      if ((ky in S) && ((ky "@" S[ky]) in D)) { Q = Q "quiet\t" t "\t" w "\t" s "\t" $5 "\tdeclined\n"; c["declined"]++ }
      else if (t == "critical") { SN = SN $0 "\n"; c["critical"]++; if (w != "apply-owed") ci++ }
      else if (t == "important" && (ky in S)) { Q = Q "quiet\t" t "\t" w "\t" s "\t" $5 "\tunchanged\n"; c["unchanged"]++; ci++ }
      else if (t == "important") { SN = SN $0 "\n"; c["important"]++; ci++ }
      else { Q = Q "quiet\t" t "\t" w "\t" s "\t" $5 "\tminor\n"; c["minor"]++ }
      next }
    $1 ~ /^(withdrawn|context|move|warning)$/ { if (!dn) out()
      # GM-3 U6: planning-analysis, with the critical and important triggers not declined, and only when it takes in something
      if ($1 == "move" && $2 == "planning-analysis") { w = $5; if (ci) w = (w == "" ? "" : w "; ") "the " ci " critical and important triggers not declined"
        if (w != "" || $6 ~ /^implement-replan is not listed/) print "move", "planning-analysis", "-", "@", "proposes how the plan takes in " (w == "" ? "nothing pending or to place" : w) ($6 == "" ? "" : "; " $6) "; records and posts nothing"; next }
      print; next }
    { print }
    function out() { dn = 1; printf "%s%s", SN, Q; print "tiers", "critical=" c["critical"] + 0 " important=" c["important"] + 0 " unchanged=" c["unchanged"] + 0 " minor=" c["minor"] + 0 " declined=" c["declined"] + 0 }
    END { if (!dn) out() }' "$1"; }
# evkeys_ <file>: GM-4 F4, the evidence key of each trigger and quiet line of the call's lines, `<what> TAB <subject> TAB <tier> TAB
# <key>` in their order, for queue.sh raise
evkeys_() { [ -f "$1" ] || die "no lines file $1"; awk -F'\t' -v OFS='\t' '$1 == "trigger" || $1 == "quiet" { print $3, $4, $2, $5 }' "$1" > "$T/el"; ekeys_ "$T/el"; }
# hashmoves <file>: the call's lines, each move's `@` its hash (GM-2 §5): git hash-object of `<kind> TAB <subject> TAB <what>` and a newline,
# then its warning lines as printed, each with its newline
hashmoves() { rm -rf "$T/mh"; mkdir -p "$T/mh"
  awk -F'\t' -v D="$T/mh" '$1 == "move" && $4 == "@" { n++; f = sprintf("%s/%06d", D, n); printf "%s\t%s\t%s\n", $2, $3, $5 > f; close(f); K[$2 SUBSEP $3] = f; next }
    $1 == "warning" && (($2 SUBSEP $3) in K) { f = K[$2 SUBSEP $3]; print >> f; close(f) }' "$1"
  ls "$T/mh" | sed "s#^#$T/mh/#" | git hash-object --stdin-paths > "$T/mhh"
  awk -F'\t' -v OFS='\t' -v H="$T/mhh" '$1 == "move" && $4 == "@" { getline h < H; $4 = h } { print }' "$1"; }

case "${1:-}" in
  # GM-4 F3: the one read, the round read with the ticket bodies, sub-issues and assignees, into the one file
  read) [ $# -eq 1 ] || die 'usage — sh checks/next.sh read'; RC=0; sh "$HERE/round.sh" read || RC=$?; exit "$RC" ;;
  pending) [ $# -eq 1 ] || die 'usage — sh checks/next.sh pending'; pending_; cat "$T/pend" "$T/spec" ;;
  differ) case ${2:-} in ''|*[!0-9]*) die 'usage — sh checks/next.sh differ <n> [<commit>]' ;; esac; [ $# -le 3 ] || die 'usage — sh checks/next.sh differ <n> [<commit>]'; differ_ "$2" "${3:-}" ;;
  changes) [ $# -eq 1 ] || die 'usage — sh checks/next.sh changes'; changes_ ;;
  triggers) [ $# -eq 1 ] || die 'usage — sh checks/next.sh triggers'; triggers_ ;;
  own-work) [ $# -eq 1 ] || die 'usage — sh checks/next.sh own-work'; ownwork_ ;;
  evkeys) [ $# -eq 2 ] || die 'usage — sh checks/next.sh evkeys <lines file>'; evkeys_ "$2" ;;
  *) die 'usage — sh checks/next.sh read | pending | differ <n> [<commit>] | changes | triggers | evkeys <lines file>' ;;
esac
