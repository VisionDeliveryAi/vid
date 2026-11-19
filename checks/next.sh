#!/bin/sh
# Purpose: GitHub manual's call, read and judged (GM-1 S3, S4, S7, S8): the mode, the read kept, the pending changes, the
# rows a ticket quotes that differ, the team's changes to a ticket's tests, and the call's lines: the count, the triggers in
# their tiers, the questions, the context, the moves and their warnings. Run at the top of ViD's repository. It never calls gh
# itself and writes nothing to GitHub: `read` runs github.sh next-read and keeps its output in .vid/next/read; every other
# subcommand only reads ViD's records, the spec in git and that file, and `triggers` writes nothing at all.
#   mode               `mode: GitHub manual`, exit 0, in GitHub manual (lib.sh ghmode); else one line naming the verb that fits,
#                      exit 1: /vid run in GitHub auto or team; in ticket mode with no GitHub mode answered, /vid plan (its setup
#                      asks it); outside ticket mode, /vid develop when RUN-STATE runs a build, /vid plan when there is none
#   read               sh checks/github.sh next-read into .vid/next/read (lib.sh put); a read that exits non-zero is still kept,
#                      with an `unread round - next-read exited <k>` line, and the call exits 1
#   pending            (GM-1 S3) the changes since the applied version (.vid/tw/applied): reset, added and reached as
#                      `inventory.sh impact --base <applied> --tickets --detail` sorts them, its records and a journey's
#                      transitions left out (a transition goes with its row); then retired, an id of the applied commit's
#                      inventory that the working tree's does not hold, a record (a difference with no paying-step:) left out.
#                      INVENTORY.md has no other form of retirement: retiring a row is deleting its line, in a commit of its own
#                      (skills/vid-test-inventory §5); the handed record's `row <id> retired` state is cut (0.26.11.1.2, R5)
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
#                      the part lines, else writer.sh parts' first part of it
#   triggers           (GM-1 S8, S4) the call's lines, from the records, .vid/next/read and the pending changes
# Line forms, tab-separated, one record a line (a list comma-separated, `-` when empty):
#   mode, read, pending, differ and changes:
#     pending <reset|added|reached|retired> <id>
#     differ <n> <id>
#     added <n> <id> <step or ->          dropped <n> <id> <step or ->
#     unread <part> <n or -> <why>        what could not be read, from next-read or here; nothing is counted from it. The rows
#                                         table read through lib.sh's mustread: a failed read stops triggers, exit 1, never an empty list
#   triggers, in this order:
#     unread <part> <n or -> <why>
#     count total <n>, then count <kind> <n> for each kind, in order: to-place added retired restated reset unpublished
#     counted <kind> <id> <evidence>      each test once, under the first kind it matches
#     trigger <critical|important|minor> <what> <subject> <evidence>, critical first; what is one of
#       critical:  reset-taken retired-taken blocked close-twice close-shrink lane-gone
#       important: to-place-active added-active stage-to-correct reset-not-taken reached-closed team-added team-dropped
#                  not-taken team-no-lane
#       minor:     reached-open added-inactive reset-inactive record
#     question <#n> <the comment's first line>
#     context sub <#ticket> <#parent> <#child> <state> <assignees> <title>
#     context assigned <#n> <labels> <title>
#     move <k> <publish|team-change|analyse|apply|answer> <subject> listed; done from phase <2|3>
#     warning <k> <step> <limit|stage-ahead|not-taken> <the numbers> <the risk>     after its publish move
# The count's kinds (first match wins; a test already in a published ticket at its current text is not counted): to-place, on
# .vid/tw/to-place and in no published ticket; added, retired, pending; restated, a row a published ticket quotes whose text
# there differs from the working tree's (differ); reset, pending, in no published ticket; unpublished, in no published ticket
# (its step, or `in no step`). A test is a row of the working tree's rows table (planner.sh rows --newest) of kind row and
# class planned, moved or owed, its handed state not known-limit; a retired row counts only when the applied commit's rows
# table (planner.sh rows in a scratch copy of the spec there) gives it the same; known limits, records and later-phase rows
# are not counted. A stage is active while it has an open published ticket (the read's ticket lines). A ticket's stage, and a
# step's, is the stage most of its rows of class planned, moved or owed are in, the earliest on a tie, as the planner reads
# a step's. Taken: a `vid: claimed` comment on it, an assignee, or any sub-issue. A row's state reads .vid/decide/state then
# the handed record's `row` lines, the newest counting; for the stage-ahead warning, accepted is accepted, accepted by
# ruling, owed or paid (held is not). With exactly one setup lane, a step naming no lane is that lane's.
# The owner items close-twice and close-shrink are close.sh's `twice` and `shrink` lines in each step's newest ask
# (.vid/decide/close/<step>/<k>/items) and each stage's newest candidate (.vid/decide/stage/<N>/<c>/items), unanswered in
# .vid/decide/queue/answers, as queue.sh's c_items reads them. Every unpublished step of the plan block is publishable: no
# hold for its stage, builds-on, rule A, the graded gate or the open-ticket limit (S4); its warnings are the open tickets
# against open-tickets:, its stage against the lowest active stage, and the tickets not taken 7 days after their creation.
# serves: tickets
set -eu
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
TAB=$(printf '\t')
die() { echo "ViD next: $*" >&2; exit 2; }
ref() { echo "ViD next: refused — $*" >&2; exit 1; }
RD=.vid/next/read; LOG=.vid/tw/log; HAND=.vid/tw/handed
TRIM='function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }'
# KEY: an inventory line's id, the first field, or the second on a rule, difference, exception, suppression, hostility or seam
# line (inventory.sh impact's key); REC: a record, a difference with no paying-step:
KEY="$TRIM"' function key(l,   a, k) { split(l, a, "|"); k = tr(a[1]); return (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr(a[2]) : k }
  function isrec(l,   a) { split(l, a, "|"); return tr(a[1]) == "difference" && l !~ /\|[ \t]*paying-step:/ }'

# PTR: writer.sh A1's ptr and unptr, word for word (a .vid/ path, a checks/<…> path, a claude.ai artifact link, "artifact <id>"
# written "(ViD's records)"), so differ reads a quoted field against exactly what the writer wrote for it
PTR='function ptr(l,   n, w, i, a, x) { if (match(l, /(https?:\/\/)?claude\.ai\/[^ \t)]*artifact\/[A-Za-z0-9_-]+/) || match(l, /[^ \t"(),;]*\.vid\/[^ \t"(),;]*/)) return substr(l, RSTART, RLENGTH)
    if (match(l, /(^|[^A-Za-z0-9_.\/-])(\.\/)?checks\/[A-Za-z0-9_.-]+(\/|\.[a-z])[A-Za-z0-9_.\/-]*/)) { x = substr(l, RSTART, RLENGTH); sub(/^[^A-Za-z0-9_.\/-]/, "", x); sub(/\.$/, "", x); return x }
    n = split(l, w, /[ \t]+/); for (i = 1; i < n; i++) { a = w[i]; sub(/^[^A-Za-z]+/, "", a); sub(/[^A-Za-z]+$/, "", a); x = w[i + 1]; sub(/^[^A-Za-z0-9_-]+/, "", x); sub(/[^A-Za-z0-9_-]+$/, "", x)
      if (tolower(a) ~ /^artifacts?$/ && x ~ /^[A-Za-z0-9_-]+$/ && x ~ /[0-9]/ && length(x) >= 16 && match(l, a "[^A-Za-z0-9_ \t-]*[ \t]+[^A-Za-z0-9_ \t-]*" x)) return substr(l, RSTART, RLENGTH) } return "" }
  function unptr(l,   p, i) { while ((p = ptr(l)) != "") { i = index(l, p); l = substr(l, 1, i - 1) "(ViD\047s records)" substr(l, i + length(p)) } return l }'
# invat [<commit>]: the inventory's lines, every ```vid-inventory block, at the commit, else the working tree's
invat() { if [ -n "${1:-}" ]; then git show "$1:INVENTORY.md" 2> /dev/null || return 1; else cat INVENTORY.md 2> /dev/null || true; fi | awk '/^```vid-inventory/ { b = 1; next } b && /^```/ { b = 0; next } b && !/^[ \t]*(#|$|grammar:)/'; }
# keys <file>: `<id><TAB><first field><TAB><record 1|0>`, each id once, its first line
keys() { awk "$KEY"' { k = key($0); if (k == "" || (k in s)) next; s[k] = 1; split($0, a, "|"); print k "\t" tr(a[1]) "\t" isrec($0) }' "$1"; }
needapplied() { A=$(applied); [ -n "$A" ] || ref 'no applied version: .vid/tw/applied names no commit (/vid mode manual records it)'; git rev-parse -q --verify "$A^{commit}" > /dev/null 2>&1 || ref ".vid/tw/applied names $A, no commit of this repository"; }
# pending_: $T/pend (`pending <kind> <id>`), $T/retk (a retired id and its first field), $T/rec (impact's records)
pending_() {
  needapplied
  # impact --detail with nothing to print exits 1 with no output (its grep -v under set -e): read as nothing pending
  if ! sh "$HERE/inventory.sh" impact --base "$A" --tickets --detail > "$T/imp" 2> "$T/impe"; then
    [ ! -s "$T/imp" ] && [ ! -s "$T/impe" ] || { sed 's/^/  /' "$T/impe" >&2; ref "inventory.sh impact --base $A failed: $(grep -v "^[[:space:]]*$" "$T/impe" | head -n 1)"; }; fi
  awk -F'\t' -v OFS='\t' '$3 == "transition" || $1 == "record" { next } $1 ~ /^(reset|added|reached)$/ { print "pending", $1, $2 }' "$T/imp" > "$T/pend"
  awk -F'\t' '$1 == "record" { print $2 }' "$T/imp" | sort -u > "$T/rec"
  invat "$A" > "$T/ia" || ref "INVENTORY.md cannot be read at $A"; invat > "$T/iw"; keys "$T/ia" > "$T/ka"; keys "$T/iw" > "$T/kw"
  awk -F'\t' 'FILENAME == ARGV[1] { W[$1] = 1; next } !($1 in W) && $3 == 0 { print $1 "\t" $2 }' "$T/kw" "$T/ka" > "$T/retk"
  awk -F'\t' -v OFS='\t' '{ print "pending", "retired", $1 }' "$T/retk" >> "$T/pend"; }

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
  sort -u "$T/ids" -o "$T/ids"; }
# named <file>: the inventory ids ($T/ids) the text names, each a whole word (no letter, digit, _ or - beside it), one a line
named() { awk -v IDS="$T/ids" 'BEGIN { while ((getline l < IDS) > 0) I[l] = 1 } { m = split($0, w, /[^A-Za-z0-9_-]+/); for (i = 1; i <= m; i++) if ((w[i] in I) && !(w[i] in s)) { s[w[i]] = 1; print w[i] } }' "$1"; }
# part1 <n> <file>: part 1 of the writing, into $T/p1
part1() { if grep -q "^Ticket #$1, part 1 of [0-9]*, writing " "$2"; then
    awk -v n="$1" 'index($0, "Ticket #" n ", part 1 of ") == 1 { on = 1; next } on && index($0, "Ticket #" n ", part ") == 1 { exit } on' "$2" > "$T/p1"
  else rm -rf "$T/parts"; sh "$HERE/writer.sh" parts "$2" "$1" "$T/parts" > /dev/null 2>&1 && [ -f "$T/parts/part-1.md" ] || return 1; cp "$T/parts/part-1.md" "$T/p1"; fi; }
# changes_: `added|dropped <n> <id> <step or ->` lines and `unread` lines on stdout
changes_() {
  [ -f "$RD" ] || { printf 'unread\tread\t-\tno read kept (.vid/next/read): run next.sh read\n'; return 0; }
  steps_; pubs_; ids_
  awk -F'\t' '{ n = split($3, a, " "); for (i = 1; i <= n; i++) if (!(a[i] in s)) { s[a[i]] = 1; print a[i] "\t" $1 } }' "$T/steps" > "$T/stepof"
  awk -F'\t' '$1 == "unread" && ($2 == "ticket" || $2 == "body") { print $3 }' "$RD" | sort -u > "$T/ubody"
  for n in $(awk -F'\t' '$1 == "ticket" { print $2 }' "$RD"); do
    grep -qx "$n" "$T/ubody" && continue
    F=.vid/tw/out/issue-$n.md; [ -f "$F" ] || { printf 'unread\twriting\t%s\tno recorded writing (%s)\n' "$n" "$F"; continue; }
    awk -F'\t' -v n="$n" '$1 == "body" && $2 == n { print substr($0, length($1 $2) + 3) }' "$RD" > "$T/b"
    named "$T/b" | sort > "$T/bn"; named "$F" | sort > "$T/wn"
    comm -23 "$T/bn" "$T/wn" | sed 's/^/added	/' > "$T/ch"
    if head -n 1 "$T/b" | grep -q "^Ticket #$n, part 1 of [0-9][0-9]*, writing [0-9a-f]*\.\$"; then
      part1 "$n" "$F" || { printf 'unread\twriting\t%s\tpart 1 of the recorded writing could not be made\n' "$n"; continue; }
      named "$T/p1" | sort > "$T/was"
    else awk -F'\t' -v n="$n" '$1 == n { m = split($3, a, " "); for (i = 1; i <= m; i++) print a[i] }' "$T/pub" | sort -u > "$T/was"; fi
    comm -23 "$T/was" "$T/bn" | sed 's/^/dropped	/' >> "$T/ch"
    awk -F'\t' -v n="$n" -v OFS='\t' 'FILENAME == ARGV[1] { S[$1] = $2; next } { print $1, n, $2, (($2 in S) ? S[$2] : "-") }' "$T/stepof" "$T/ch"
  done; }

# items_: the open owner items of kind close-twice and close-shrink, `<close-twice|close-shrink><TAB><key>` a line
items_() { D=.vid/decide; { for x in $(ls "$D/close" 2> /dev/null); do k=''; for d in $(ls "$D/close/$x" 2> /dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$D/close/$x/$d/ask" ] && k=$d; done
    [ -n "$k" ] && [ ! -f "$D/close/$x/$k/withdrawn" ] || continue; grep -Eq "^closed $x( |\$)" "$HAND" 2> /dev/null && continue; echo "$x/$k $D/close/$x/$k/items"; done
  for x in $(ls "$D/stage" 2> /dev/null); do k=''; for d in $(ls "$D/stage/$x" 2> /dev/null | grep -E '^[0-9]+$' | sort -n); do [ -f "$D/stage/$x/$d/ask" ] && k=$d; done
    [ -n "$k" ] && [ ! -f "$D/stage/$x/$k/withdrawn" ] && echo "stage-$x/$k $D/stage/$x/$k/items"; done; } | while read -r sk f; do [ -f "$f" ] || continue
    awk -v sk="$sk" -v A="$D/queue/answers" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); Q[x[2]] = 1 } }
      ($1 == "twice" || $1 == "shrink") { k = "close:" sk ":" $1 ":" $2; if (!(k in Q)) print "close-" $1 "\t" k }' "$f"; done; }
# arows_: $T/arows, the rows table at the applied commit: planner.sh rows run in a scratch copy of the five spec files there,
# PLAN.md at HEAD and ViD's plan records, the setup's github-mode lines left out so the copy is read as files
arows_() { : > "$T/arows"; A=$(applied); [ -n "$A" ] || return 0; AD=$T/ap; rm -rf "$AD"; mkdir -p "$AD/.vid/plan" "$AD/.vid/tw"
  for f in PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md; do git show "$A:$f" > "$AD/$f" 2> /dev/null || rm -f "$AD/$f"; done
  git show HEAD:PLAN.md > "$AD/PLAN.md" 2> /dev/null || { rm -f "$AD/PLAN.md"; [ ! -f PLAN.md ] || cp PLAN.md "$AD/PLAN.md"; }
  [ ! -f .vid/RUN-STATE.md ] || cp .vid/RUN-STATE.md "$AD/.vid/RUN-STATE.md"; [ ! -f .vid/tw/settings ] || cp .vid/tw/settings "$AD/.vid/tw/settings"
  { grep -v '^setup-answered key=github-mode ' .vid/plan/setup 2> /dev/null || true; } > "$AD/.vid/plan/setup"
  ( cd "$AD" && mustread "$T/arows" planner rows ); }
# teams_: the setup's teams, `<name><TAB><people><TAB><the line>`; none, devagent of one (planner.sh's reading)
teams_() { awk -F'|' "$TRIM"' /^team:/ { l = tr(substr($0, 6)); n = split(l, a, "|"); for (i = 1; i <= n; i++) a[i] = tr(a[i]); if (n == 4 && a[1] ~ /^[a-z][a-z0-9]*$/ && a[4] ~ /^[1-9][0-9]*$/ && !(a[1] in s)) { s[a[1]] = 1; print a[1] "\t" a[4] "\t" $0; k++ } }
    END { if (!k) print "devagent\t1\t(no team: line, so devagent of one)" }' .vid/tw/settings 2> /dev/null || printf 'devagent\t1\t(no team: line, so devagent of one)\n'; }

triggers_() {
  : > "$T/f"; : > "$T/pend"; : > "$T/retk"; : > "$T/rec"
  if [ -n "$(applied)" ]; then ( pending_ ) > "$T/pe" 2>&1 || { : > "$T/pend"; : > "$T/retk"; : > "$T/rec"; printf 'U\tpending\t-\t%s\n' "$(tail -n 1 "$T/pe" | sed 's/^ViD next: //')" >> "$T/f"; }
  else printf 'U\tpending\t-\tno applied version: .vid/tw/applied names no commit\n' >> "$T/f"; fi
  mustread "$T/rows" planner rows --newest
  awk -F'\t' -v OFS='\t' '!/^#/ { print "R", $1, $2, $5, $6 }' "$T/rows" >> "$T/f"
  if [ -s "$T/retk" ]; then arows_; awk -F'\t' -v OFS='\t' '!/^#/ { print "AR", $1, $2, $6 }' "$T/arows" >> "$T/f"; fi
  { awk -F'\t' '{ print $1 "\t" $2 }' .vid/decide/state 2> /dev/null || true; sed -n 's/^row \([^ ]*\) \([^ |]*\).*/\1	\2/p' "$HAND" 2> /dev/null || true; } | sed 's/^/S	/' >> "$T/f"
  sed 's/^pending/P/' "$T/pend" >> "$T/f"; sed 's/^/C	/' "$T/rec" >> "$T/f"
  { awk 'NF >= 2 { print "TP\t" $1 "\t" $2 }' .vid/tw/to-place 2> /dev/null || true; } >> "$T/f"
  steps_; pubs_; sed 's/^/ST	/' "$T/steps" >> "$T/f"; sed 's/^/PUB	/' "$T/pub" >> "$T/f"
  teams_ | sed 's/^/TEAM	/' >> "$T/f"; items_ | sed 's/^/ITEM	/' >> "$T/f"
  printf 'LIM\t%s\nPX\t%s\nNOW\t%s\n' "$(sed -n 's/^open-tickets:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*$/\1/p' .vid/tw/settings 2> /dev/null | head -n 1)" "$(twkey labels-prefix)" "$(date -u +%s)" >> "$T/f"
  if [ -f "$RD" ]; then
    awk -F'\t' -v OFS='\t' '$1 == "unread" { print "U", $2, $3, substr($0, length($1 $2 $3) + 4) } $1 == "issue" { print "ISS", $2, $3, $4 } $1 == "open" { print "OPR", $2, $10 }
      $1 == "sub" || $1 == "assigned" { print }' "$RD" >> "$T/f"
    awk -F'\t' '$1 == "ticket" { print $2 "\t" $3 "\t" $4 "\t" $5 }' "$RD" | while IFS="$TAB" read -r n s a c; do printf 'TK\t%s\t%s\t%s\t%s\t%s\n' "$n" "$s" "$a" "$c" "$(epoch "$c")"; done >> "$T/f"
    changes_ | awk -F'\t' -v OFS='\t' '$1 == "unread" { print "U", $2, $3, $4; next } { print "CHG", $1, $2, $3, $4 }' >> "$T/f"
    cut -f1 "$T/pub" | while read -r n; do [ -f ".vid/tw/out/issue-$n.md" ] || continue; ( differ_ "$n" ) 2> /dev/null | sed 's/^differ/DIF/' || true; done >> "$T/f"
  else printf 'U\tread\t-\tno read kept (.vid/next/read): run next.sh read\n' >> "$T/f"; fi
  awk -F'\t' -v OFS='\t' '
    function num(s) { return s ~ /^[0-9]+$/ }
    function add(a, x) { return a == "" ? x : a "," x }
    # acc: accepted, for the stage-ahead warning: accepted, accepted by ruling, owed or paid (held is not accepted)
    function acc(x) { return x ~ /^(accepted|accepted-by-ruling|owed|paid)$/ }
    # stg <rows>: the stage most of the rows of class planned, moved or owed are in, the earliest on a tie (the planner'"'"'s rule; F2)
    function stg(l,   m, A, j, x, N, b) { m = split(l, A, " "); split("", N); b = ""
      for (j = 1; j <= m; j++) { x = A[j]; if (RC[x] ~ /^(planned|moved|owed)$/ && num(RG[x])) N[RG[x]]++ }
      for (x in N) if (b == "" || N[x] > N[b] || (N[x] == N[b] && x + 0 < b + 0)) b = x; return b }
    function trig(t, w, s, e) { TG[t] = TG[t] "trigger\t" t "\t" w "\t" s "\t" e "\n"; if (t != "minor") CI++ }
    $1 == "U" { print "unread", $2, $3, $4; UN[$2, $3] = 1; UP[$2] = 1; next }
    $1 == "R" { if (!($2 in RK)) RO[++nr] = $2; RK[$2] = $3; RG[$2] = $4; RC[$2] = $5; next }
    $1 == "S" { ST[$2] = $3; next }
    $1 == "P" { P[$3, $2] = 1; if (!($3 in PI)) NPI++; PI[$3] = 1; if (!($3 in PO)) { PO[$3] = ++np; PL[np] = $3 } next }
    $1 == "AR" { if (!($2 in ARK)) { ARK[$2] = $3; ARC[$2] = $4 } next }
    $1 == "C" { REC[++nc] = $2; next }
    $1 == "TP" { TP[$2] = $3; if (!($2 in PO)) { PO[$2] = ++np; PL[np] = $2 } next }
    $1 == "ST" { SO[++ns] = $2; SL[$2] = $3; SR[$2] = $4; m = split($4, a, " "); for (i = 1; i <= m; i++) if (!(a[i] in STEP)) STEP[a[i]] = $2; next }
    $1 == "PUB" { TO[++nt] = $2; TS[$2] = $3; TR[$2] = $4; PS[$3] = 1; m = split($4, a, " "); for (i = 1; i <= m; i++) IN[a[i]] = add(IN[a[i]], $2); next }
    $1 == "TEAM" { TM[++nm] = $2; TL[$2] = $4; if ($3 == 1) { LN[$2] = 1; LO1 = $2; nln++ } else for (i = 1; i <= $3; i++) { LN[$2 "-" i] = 1; LO1 = $2 "-" i; nln++ } next }
    $1 == "ITEM" { TG["critical"] = TG["critical"] "trigger\tcritical\t" $2 "\t" $3 "\tthe owner item " $3 " in .vid/decide, unanswered\n"; CI++; next }
    $1 == "LIM" { LIM = $2; next } $1 == "PX" { PX = $2; next } $1 == "NOW" { NOW = $2; next }
    $1 == "ISS" { IL[$2] = "," $3 ","; IH[$2] = $4; QO[++nq] = $2 SUBSEP $4; next }
    $1 == "OPR" { QO[++nq] = $2 SUBSEP $3; next }
    $1 == "sub" { SUBL[++nsub] = $0; HASSUB[$2] = 1; next }
    $1 == "assigned" { ASL[++nas] = $0; next }
    $1 == "TK" { TKS[$2] = $3; TKA[$2] = $4; TKC[$2] = $5; TKE[$2] = $6; if ($3 == "OPEN") OPEN++; next }
    $1 == "CHG" { CH[++nch] = $2 SUBSEP $3 SUBSEP $4 SUBSEP $5; next }
    $1 == "DIF" { DIF[$3] = add(DIF[$3], $2); next }
    END {
      # with exactly one lane, a step naming none is that lane'"'"'s, as the planner reads it
      if (nln == 1) for (i = 1; i <= ns; i++) if (SL[SO[i]] == "-" || SL[SO[i]] == "") SL[SO[i]] = LO1
      # the tests: rows of kind row, class planned, moved or owed, not a known limit by its handed state
      for (i = 1; i <= nr; i++) { r = RO[i]; if (RK[r] == "row" && RC[r] ~ /^(planned|moved|owed)$/ && ST[r] != "known-limit") { TEST[r] = 1; U[++nu] = r } }
      # a retired row, when the applied commit'"'"'s rows table gives it kind row and class planned, moved or owed, and it is no known limit
      for (i = 1; i <= np; i++) { r = PL[i]; if (P[r, "retired"] && ARK[r] == "row" && ARC[r] ~ /^(planned|moved|owed)$/ && ST[r] != "known-limit" && !(r in TEST)) { U[++nu] = r; TEST[r] = 1 } }
      # each ticket: its stage, taken, how
      for (i = 1; i <= nt; i++) { n = TO[i]; TST[n] = stg(TR[n])
        h = ""; if (index("\001" IH[n] "\001", "\001vid: claimed")) h = add(h, "a vid: claimed comment"); if (TKA[n] != "" && TKA[n] != "-") h = add(h, "assignee " TKA[n]); if (n in HASSUB) h = add(h, "a sub-issue")
        TK_[n] = h; if (TKS[n] == "OPEN" && num(TST[n])) ACT[TST[n]] = 1 }
      lo = ""; for (s in ACT) if (lo == "" || s + 0 < lo + 0) lo = s
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
      for (i = 1; i <= ns; i++) { s = SO[i]; if (SL[s] != "-" && !(SL[s] in LN)) { g = ""; for (x in LN) g = add(g, x); trig("critical", "lane-gone", s, "lane: " SL[s] "; the setup gives " g) } }
      for (i = 1; i <= nch; i++) { split(CH[i], CC, SUBSEP); trig("important", "team-" CC[1], "#" CC[2] " " CC[3], (CC[4] == "-" ? "in no step" : "step " CC[4])) }
      st = ""; for (i = 1; i <= nt; i++) { n = TO[i]; if (TKS[n] != "OPEN" || TK_[n] != "" || TKE[n] + 0 == 0 || (("ticket", n) in UN) || (("sub", n) in UN) || ("round" in UP)) continue
        dd = int((NOW - TKE[n]) / 86400); if (NOW - TKE[n] > 7 * 86400) { trig("important", "not-taken", "#" n, "created " TKC[n] ", " dd " days ago; no vid: claimed comment, assignee or sub-issue"); st = add(st, "#" n); nst++ } }
      for (i = 1; i <= nm; i++) { t = TM[i]; u = 0; for (j = 1; j <= ns; j++) { l = SL[SO[j]]; if (l == t || index(l, t "-") == 1 && substr(l, length(t) + 2) ~ /^[0-9]+$/) u = 1 } if (!u) trig("important", "team-no-lane", t, TL[t]) }
      printf "%s%s%s", TG["critical"], TG["important"], TG["minor"]
      # the questions
      for (i = 1; i <= nq; i++) { split(QO[i], q, SUBSEP); m = split(q[2], HH, "\001"); for (j = 1; j <= m; j++) if (HH[j] ~ /^Question:/ && !((q[1], HH[j]) in QS)) { QS[q[1], HH[j]] = 1; QQ[++nqq] = q[1] SUBSEP HH[j]; print "question", "#" q[1], HH[j] } }
      # the context
      for (i = 1; i <= nsub; i++) { split(SUBL[i], a, "\t"); print "context", "sub", "#" a[2], "#" a[3], "#" a[4], a[5], a[6], a[7] }
      for (i = 1; i <= nas; i++) { split(ASL[i], a, "\t"); print "context", "assigned", "#" a[2], a[3], a[6] }
      # the moves, each publish with its warnings (N13)
      k = 0; for (i = 1; i <= ns; i++) { s = SO[i]; if (s in PS) continue; print "move", ++k, "publish", s, "listed; done from phase 2"
        if (LIM != "" && OPEN + 1 > LIM + 0) print "warning", k, s, "limit", (OPEN + 0) " open tickets, " (OPEN + 1) " with this one, over open-tickets: " LIM, "work spread, the plan fixed early"
        g = stg(SR[s])
        if (lo != "" && g != "" && g + 0 > lo + 0) { c = 0; for (r in TEST) if (RG[r] == lo && !acc(ST[r])) c++; print "warning", k, s, "stage-ahead", "stage " g ", ahead of stage " lo ", the lowest active stage, whose " c " tests are not yet accepted", "half-built work in a release, lost learning" }
        if (nst) print "warning", k, s, "not-taken", nst " published tickets not taken 7 days after their creation: " st, "a stale ticket" }
      for (i = 1; i <= nch; i++) { split(CH[i], CC, SUBSEP); print "move", ++k, "team-change", "take in or decline: " CC[1] " " CC[3] " on #" CC[2], "listed; done from phase 2" }
      if (CI) print "move", ++k, "analyse", "the " CI " critical and important triggers", "listed; done from phase 3"
      if (NPI) print "move", ++k, "apply", "the pending changes, " NPI " rows", "listed; done from phase 3"
      for (i = 1; i <= nqq; i++) { split(QQ[i], q, SUBSEP); print "move", ++k, "answer", "#" q[1] ": " q[2], "listed; done from phase 2" } }' "$T/f"; }

case "${1:-}" in
  mode) GM=$(ghmode); [ "$GM" != manual ] || { echo 'mode: GitHub manual'; exit 0; }
    RM=$(sed -n 's/^mode:[[:space:]]*//p' .vid/RUN-STATE.md 2> /dev/null | head -n 1 | sed 's/[[:space:]]*$//')
    case $GM:$RM in
      auto:*|team:*) echo "ViD next: refused — this project is in GitHub $GM, not GitHub manual: /vid run works its tickets" ;;
      *:tickets) echo 'ViD next: refused — this ticket-mode project has no GitHub mode answered: /vid plan asks it' ;;
      *) if [ -f .vid/RUN-STATE.md ]; then echo 'ViD next: refused — this project is not in ticket mode: /vid develop builds it'; else echo 'ViD next: refused — this project is not planned for tickets: /vid plan plans it'; fi ;;
    esac; exit 1 ;;
  read) [ $# -eq 1 ] || die 'usage — sh checks/next.sh read'; mkdir -p .vid/next; RC=0; sh "$HERE/github.sh" next-read > "$T/r" 2> "$T/re" || RC=$?
    [ "$RC" -eq 0 ] || printf 'unread\tround\t-\tnext-read exited %s: %s\n' "$RC" "$(tail -n 1 "$T/re")" >> "$T/r"
    put "$RD" < "$T/r"; [ "$RC" -eq 0 ] || { sed 's/^/  /' "$T/re" >&2; exit 1; } ;;
  pending) [ $# -eq 1 ] || die 'usage — sh checks/next.sh pending'; pending_; cat "$T/pend" ;;
  differ) case ${2:-} in ''|*[!0-9]*) die 'usage — sh checks/next.sh differ <n> [<commit>]' ;; esac; [ $# -le 3 ] || die 'usage — sh checks/next.sh differ <n> [<commit>]'; differ_ "$2" "${3:-}" ;;
  changes) [ $# -eq 1 ] || die 'usage — sh checks/next.sh changes'; changes_ ;;
  triggers) [ $# -eq 1 ] || die 'usage — sh checks/next.sh triggers'; triggers_ ;;
  *) die 'usage — sh checks/next.sh mode | read | pending | differ <n> [<commit>] | changes | triggers' ;;
esac
