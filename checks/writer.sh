#!/bin/sh
# Purpose: ViD's ticket writer, TW (v0.26.10.12.3 R1, R3–R5, R7, R8) — the ratified plan made
# into tickets of product text, develop's builder brief part by part (§1.1). Run at the top of ViD's repository; it
# calls no outside service (checks/github.sh posts what it writes). Everything quoted is read at ViD's HEAD, the spec
# export's commit; GM-2 T1: in GitHub manual, at the applied commit (.vid/tw/applied), as the export reads it. Its records: .vid/tw/settings (repo:, spec-repo:, labels-prefix:, open-tickets:), .vid/tw/handed
# (what later roles hand in, each line ending `| stand-in: <who>` until their stages: `engines <primary> <other>…`,
# `engine-split <row>`, `closed <step>`, `row <id> <state> [fault-proven]`, `fix <row> [<row> …] | <reason> | <links>`, `lesson
# <ids> | <words>`, `reached <row> <REQ|INV id> [<the landing>]`, `candidate <stage>`), .vid/tw/log (github.sh's), .vid/tw/named (name's, 0.26.10.29.5), .vid/tw/out/.
#   gate      exit 0 only when planner.sh ratified exits 0, the newest publish-approved event's words are the newest
#             ratification's, the settings name repo:, spec-repo: (another repository), labels-prefix: (empty counts)
#             and, when set, an open-tickets: of 1 or more, and no exported or quoted file has an uncommitted change;
#             else one line per thing missing, exit 1. GM-2 T1: in GitHub manual no publish-approved event is asked, and
#             the uncommitted-change check covers PLAN.md and the issue form (issue-form:) alone
#   write skeleton | step <S> | fix <key|row> | reached | amend <n>   the gate first; then the ticket into
#             .vid/tw/out/<kind>-<arg>.md, its path printed, and <file>.meta (its log line's fields, then `sent <row>
#             <hash>` per row) for github.sh tw-post; then the check. A step ticket holds the started step's rows less
#             known limits, rows in an open ticket and rows sent unchanged; a fix ticket one unpublished fix line,
#             by its key or the oldest holding the row, its rows less known limits, in the step of the close it names
#             (`close #<n> of <S>`), else the first row's own started step (v0.26.10.25.4 R1, R2); `reached` the rows a ruling reached, in a ticket of their own;
#             `amend <n>` open ticket n again, its rows as the plan now holds them, naming the plan change or export.
#             Every new ticket carries the rows of rulings no ticket has listed (a ruling is a handed reached line, so a
#             row a later ruling reaches goes out again). 0.26.11.1.2 (R5): the retired state is cut; a handed `row <id> retired`
#             is out of form, and a row the owner no longer wants is ruled a known limit.
#             v0.26.10.25.5 (R4): an id landed (.vid/decide/landed) after a ticket was published is never added to it, and an amendment
#             drops it; a started step's landed rows owe a step ticket of their own, the skeleton's step too; a reached line is known
#             by its row, item and landing, so a second change reaches the row again. 0.26.10.28.10 (R1): they are owed once the
#             step has no open ticket, on main as it then is, never beside one; and a step ticket after the step's first, merged, is
#             a follow-up: `- follows: #<n>` in its header (n its newest earlier ticket), "Follow-up ticket" its title, and no T5 in
#             its asks, as a step has one grade, at its first ticket's first head (the stage's grade reads the rest).
#             Every ticket's Further reading (§1.1 §8) names the spec repository, then each file of its export by path
#   check <file>   exit 1, one line per refusal (`line <k>: <shape> — <word>`, or `item: …`): an item of the kind
#             missing, empty or out of order; a part over 60,000 bytes; outside the quoted lines (`> ` in The step,
#             Rows, Requirements, Decisions, Rules, Laws, Non-goals, Faulted rows, Rows a ruling reached, Grading
#             checklist, Golden sets, The stack and hosting, Further reading) code or a test (a backtick or { } < > $ \
#             =), a file path (a / outside a web address, a lowercase word.ext), a runner command (a word starting - or
#             -- and a letter); within them, a step's name: and the free text of PL's own rows (origin: plan) are
#             checked too, and Further reading may quote only a path of the export the header names (.vid/spec.git).
#             v0.26.10.12.3.1: an `owed: prerequisite` note in a row line; anywhere
#             but the header (the title too), a pointer into ViD's
#             records (a .vid/ path, a path into ViD's checks/, an artifact link or id); in a quoted decision or an answer of Requirements, one of
#             the three forms the writer rewrites (owner chose "…", owner: "…", A: "…"; ); anywhere, profanity. The writer
#             drops the note, writes "(ViD's records)" for a pointer, and rewrites those three forms; other quotes stay.
#   parts <file> <issue> <dir>   the ticket as one issue's body and comments, each at most 60,000 bytes, its sections
#             whole where they fit (ticket.sh's packer), each part's first line naming it; their paths printed
#   GM-2 T5: in GitHub manual `write amend <n> [--cause "<line>"]` names the move's own cause (the team change answered, or the
#             owner's amendment by default), never one read from the ticket's plan= hash; its `tell` lines name each test added,
#             restated (its quote changed since it was sent) or taken out (at the owner's word, and where it went). A ticket taken
#             over with no `sent` line has them rebuilt first: a row whose quote in the recorded writing matches the applied line, cut
#             as next.sh differ cuts it, reads as sent at the applied line's hash; one that differs, as restated
#   due       what the round owes, one line each: `withdraw <n> [decision=<D> what=<w>]` (its step left the plan, by
#             that newest change of its rows), `amend <n>` (rewritten, its rows or quoted text differ), then `new
#             skeleton|step <S>` (a started step with no ticket, or its rows changed after its tickets closed), `new fix
#             <key>` for a fix line with a row no known limit, and `new reached` when nothing else is new. A fix line's key
#             is a hash of its text less its stand-in label, never its place in the record (v0.26.10.25.4 R2)
#             GM-2 T5, T6: in GitHub manual an amendment is owed only when the plan's rows for the ticket differ from its log
#             line's rows (a difference in quoted text alone owes none), and a ticket that lost more than half its rows is amended,
#             never withdrawn for it; a withdrawal stays owed for a ticket whose step left the plan or that would hold no row
#   topup <added> <tests>   (GM-2 T6) the size flag, the one rule the listing and the amendment read: printed, exit 0, when more
#             than 5 tests are added, or more than a fifth of the <tests> a ticket held at its last writing; else nothing
#   fresh <file> [<n>]   exit 1, one line per thing moved since the file was written (github.sh tw-post asks it first):
#             the plan's recorded hash, the newest export, or its ticket work (new, or the amendment of #n) not owed now
#   pending   (v0.26.10.26.7, R9) the reached rows of rulings no open ticket holds yet, `<row> <step>` a line (`-` in no step)
#   where <n>  (0.26.10.29.2, R3, R11) where each row of ticket n went, `- <row> (<promise>): <where>` a line, for its withdrawal's comment
#   cause <n>  (0.26.10.29.2, R11) the `Cause:` lines an amendment of ticket n would name, for a withdrawal no plan change made
#   handovers  (0.26.10.29.2, R3) the handovers what due owes will make, `<n> TAB w|a TAB <rows>` a line, for github.sh tw-handovers
#   0.26.10.29.2 (R3): a ticket holding a row a plan change took out of an earlier ticket (withdrawn, or amended while its pull request was
#             open) names that ticket in its header, `- earlier work: ticket #<n>[, pull request #<p>]`, on every kind; asks and title stay
#   name <step> <D-id,…>   (0.26.10.29.5, DP-1 R5) RM names decisions for every ticket of a step, its fix tickets included: `<step> <ids>`
#             appended to .vid/tw/named, an unknown step or id refused before anything is written; each such ticket's Decisions section
#             joins them whatever their label and always keeps them, as brief.sh's --decisions ids, a decision about ViD's own settings
#             apart; the section is in the hash (qhash), so a name for a step with an open ticket makes due owe its amendment
# Usage: sh checks/writer.sh gate | write skeleton|step <S>|fix <row>|reached|amend <n> [--cause "<line>"] | topup <added> <tests> | check <file> | parts <f> <n> <dir> | due | pending | fresh <file> [<n>] | where <n> | cause <n> | handovers | name <step> <D-id,…>
# serves: tickets (0.26.10.28.4, M9)
set -eu
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
die() { echo "ViD writer: $*" >&2; exit 2; }
ref() { echo "ViD writer: refused — $*" >&2; exit 1; }
LOG=.vid/tw/log; HAND=.vid/tw/handed; OUT=.vid/tw/out; SET=.vid/tw/settings; LIM=60000
TR=$RNG' function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }'   # rng, the row-range expander, from lib.sh (0.26.10.28.4)
WHOLE='function has(s, id,   p, q, b, a) { q = s; while ((p = index(q, id)) > 0) { b = (p > 1) ? substr(q, p - 1, 1) : ""; a = substr(q, p + length(id), 1); if (b !~ /[A-Za-z0-9_-]/ && a !~ /[A-Za-z0-9_-]/) return 1; q = substr(q, p + 1) } return 0 }'
KV='function kv(k,   i) { for (i = 2; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }'
# A1 (Amendment 1): ptr, a pointer into ViD's records (an artifact id holds a digit; v0.26.10.24.2: a word that begins
# checks/ and names a file or a deeper path, never a path within a product's own src/checks/, nor the words health checks/alarms; unptr writes each as "(ViD's
# records)"); isr, a ruling line — a quoted decision, or an answer in Requirements, AMENDED or not; unq, its three
# rewrites and nothing else (owner chose "…" one or more, owner: "…", an answer's own A: "…"; ), check refusing any
# left (rw, a whole-word rewrite); prof, a word of lib.sh's list (PROF, which the spec export blanks by too)
A1='function ptr(l,   n, w, i, a, x) { if (match(l, /(https?:\/\/)?claude\.ai\/[^ \t)]*artifact\/[A-Za-z0-9_-]+/) || match(l, /[^ \t"(),;]*\.vid\/[^ \t"(),;]*/)) return substr(l, RSTART, RLENGTH)
    if (match(l, /(^|[^A-Za-z0-9_.\/-])(\.\/)?checks\/[A-Za-z0-9_.-]+(\/|\.[a-z])[A-Za-z0-9_.\/-]*/)) { x = substr(l, RSTART, RLENGTH); sub(/^[^A-Za-z0-9_.\/-]/, "", x); sub(/\.$/, "", x); return x }
    n = split(l, w, /[ \t]+/); for (i = 1; i < n; i++) { a = w[i]; sub(/^[^A-Za-z]+/, "", a); sub(/[^A-Za-z]+$/, "", a); x = w[i + 1]; sub(/^[^A-Za-z0-9_-]+/, "", x); sub(/[^A-Za-z0-9_-]+$/, "", x)
      if (tolower(a) ~ /^artifacts?$/ && x ~ /^[A-Za-z0-9_-]+$/ && x ~ /[0-9]/ && length(x) >= 16 && match(l, a "[^A-Za-z0-9_ \t-]*[ \t]+[^A-Za-z0-9_ \t-]*" x)) return substr(l, RSTART, RLENGTH) } return "" }
  function unptr(l,   p, i) { while ((p = ptr(l)) != "") { i = index(l, p); l = substr(l, 1, i - 1) "(ViD\047s records)" substr(l, i + length(p)) } return l }
  function isr(s, l) { return l ~ /^>/ && (s == "Decisions" || (s == "Requirements" && l ~ /^> *A-[0-9]+([ \t]+AMENDED)?[ \t]*[|]/)) }
  function rw(l, re, s,   r, b) { r = ""; while (match(l, "(^|[^A-Za-z0-9_])" re)) { b = substr(l, RSTART, 1); if (b ~ /[A-Za-z0-9_]/) b = ""; r = r substr(l, 1, RSTART - 1) b s; l = substr(l, RSTART + RLENGTH) } return r l }
  function unq(l) { l = rw(l, "owner chose:? \"[^\"]*\"(,? (and )?\"[^\"]*\")*", "chosen by the owner"); l = rw(l, "owner: \"[^\"]*\"", "confirmed by the owner"); return rw(l, "A: \"[^\"]*\"; ", "A: ") }'"$PROF"   # 0.26.11.1.2 (R7): prof, lib.sh's word check, the one list
# SP: a plan's steps, `id name modules builds rows kind`, tab-separated, ranges expanded
SP=' /^[ \t]*step[ \t]/ { n = split($0, f, "|"); id = tr(f[1]); sub(/^step[ \t]+/, "", id); nm = ""; md = ""; bo = ""; rw = ""; kd = ""
      for (i = 2; i <= n; i++) { x = tr(f[i]); if (x ~ /^name:/) nm = tr(substr(x, 6)); else if (x ~ /^modules:/) md = tr(substr(x, 9)); else if (x ~ /^builds-on:/) bo = tr(substr(x, 11)); else if (x ~ /^rows:/) rw = substr(x, 6); else if (x ~ /^kind:/) kd = tr(substr(x, 6)) }
      gsub(/\t/, " ", rw); m = split(rw, t, /[ ,]+/); r = ""
      for (j = 1; j <= m; j++) { x = t[j]; if (x == "") continue; r = r " " rng(x) }
      print id "\t" nm "\t" md "\t" (bo == "-" ? "" : bo) "\t" substr(r, 2) "\t" kd }'
twhas() { grep -q "^$1:" "$SET" 2>/dev/null; }
# GM-2 T1: in GitHub manual everything quoted is read at the applied commit, so the owner's work in progress on the spec never
# shuts the gate: its uncommitted-change check covers PLAN.md and the issue form (issue-form:) alone, both read at HEAD
specpaths() { if manual; then printf '%s\n' PLAN.md; skey issue-form | grep . || true; return 0; fi
  printf '%s\n' PRD.md INVENTORY.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md PLAN.md DECISIONS.md BASELINE.md CLAUDE.md design
  sed -n 's/.*|[[:space:]]*golden:[[:space:]]*\([^ |]*\).*/\1/p' INVENTORY.md 2>/dev/null | sort -u; }
gate() {
  : > "$T/why"
  sh "$HERE/planner.sh" ratified > "$T/rat" 2>&1 || echo "the plan is not ratified: $(sed 's/^planner: not ratified — //' "$T/rat" | head -n 1)" >> "$T/why"
  RW=$(tail -n 1 .vid/plan/ratified 2>/dev/null | sed -n 's/^ratified .* words=//p')
  AW=$(grep '^publish-approved ' .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/^publish-approved words="\(.*\)" at=[^ ]*$/\1/p')
  # GM-2 T1: in GitHub manual no publish-approved event is asked: each publish carries the owner's own words (T4)
  if manual; then :
  elif [ -z "$AW" ]; then echo 'no publish-approved event: the owner has not given the go' >> "$T/why"
  elif [ "$AW" != "$RW" ]; then echo "the newest publish-approved event's words (\"$AW\") are not the newest ratification's (\"$RW\")" >> "$T/why"; fi
  R=$(twkey repo); S=$(twkey spec-repo); L=$(twkey open-tickets)
  [ -n "$R" ] || echo "the settings name no repo: (the code repository; .vid/tw/settings)" >> "$T/why"
  if [ -z "$S" ]; then echo "the settings name no spec-repo: (the spec repository; .vid/tw/settings)" >> "$T/why"
  elif [ "$S" = "$R" ]; then echo "spec-repo: names the code repository $R; the spec repository is another" >> "$T/why"; fi
  twhas labels-prefix || echo "the settings have no labels-prefix: line (an empty one counts)" >> "$T/why"
  if twhas open-tickets; then case "$L" in ''|0*|*[!0-9]*) echo "open-tickets: '$L' is not a whole number of 1 or more" >> "$T/why" ;; esac; fi
  specpaths > "$T/sp"; git status --porcelain -- $(cat "$T/sp") 2>/dev/null | cut -c4- | sed 's/$/ has an uncommitted change/' >> "$T/why"
  [ ! -s "$T/why" ]; }

# load: at ViD's HEAD — $T/inv (the inventory's block lines, as brief.sh reads them), $T/eff (prd.sh --effective),
# $T/prd, $T/dec (DECISIONS.md's decision lines), $T/arch; $T/rows (planner.sh rows); PH and PF (the plan's recorded
# hash, read from the plan-change event's own hash= field, and its kept file); $T/steps (`id name modules builds rows
# kind`, tab-separated, ranges expanded); $T/st (the handed records, tab-separated: eng, split, closed, rs <row> <state>
# <fp|->, fix <key> <rows,…> <why> <links>, lesson <ids> <words>, reached <row> <item> <line>); $T/lg (the log)
# GM-2 T1: AT, the commit every quote is read at, and AN, its name in a refusal: HEAD, or in GitHub manual the applied commit
AT=HEAD; AN=HEAD
load() {
  [ -f PRD.md ] && [ -f INVENTORY.md ] || die "no PRD.md or INVENTORY.md here — run at the top of ViD's repository"
  if manual; then AT=$(applied); AN='the applied commit'; [ -n "$AT" ] && git cat-file -e "$AT^{commit}" 2>/dev/null || die "GitHub manual: .vid/tw/applied names no commit of this repository${AT:+ ($AT)}; /vid mode manual records the applied version the team has"; fi
  git show "$AT:INVENTORY.md" > "$T/invf" 2>/dev/null || die "no INVENTORY.md at $AN"
  sed -n '/^```vid-inventory/,/^```$/p' "$T/invf" | sed '1d;$d' > "$T/inv"
  git show "$AT:PRD.md" > "$T/prd" 2>/dev/null || die "no PRD.md at $AN"
  sh "$HERE/prd.sh" --effective "$T/prd" > "$T/eff" 2>/dev/null || die "prd.sh --effective failed on PRD.md at $AN"
  ! grep -q '^### REQ-' "$T/eff" || die 'a legacy PRD (### REQ- blocks): ticket mode reads the enriched form'
  { git show "$AT:DECISIONS.md" 2>/dev/null || true; } | grep -E '^- \*\*D-[0-9]+\*\*' > "$T/dec" || true
  { git show "$AT:ARCHITECTURE.md" 2>/dev/null || true; } > "$T/arch"
  sh "$HERE/planner.sh" rows > "$T/rows0" 2>/dev/null || die 'planner.sh rows failed'; grep -v '^#' "$T/rows0" > "$T/rows" || true
  PH=$(grep '^plan-change ' .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/^plan-change what=[^ ]* hash=\([0-9a-f]*\) .*/\1/p'); PF=.vid/plans/$PH.plan
  [ -n "$PH" ] && [ -f "$PF" ] || die 'no recorded plan (sh checks/plan.sh change create …)'
  awk "$TR$SP" "$PF" > "$T/steps"
  mkdir -p .vid/tw "$OUT"; touch "$LOG" "$HAND"; cp "$LOG" "$T/lg"
  # v0.26.10.27.3 (8.1b R2): the log with every ticket withdrawn closed-outside read as never published (its published, amended and
  # sent lines out), for what a step is owed; a plan change's withdrawal stays as it is
  # 0.26.10.29.2 (R11): and a step ticket withdrawn for a big change with its step kept (`kept=`), so the rows the step keeps go out again
  awk '$1 == "withdrawn" && ($3 == "decision=closed-outside" || / kept=/) { print $2 }' "$T/lg" | sort -u > "$T/cow"
  awk -v C="$T/cow" 'BEGIN { while ((getline l < C) > 0) W[l] = 1 } ($1 == "published" || $1 == "amended") && ($2 in W) { next } $1 == "sent" { for (i = 3; i <= NF; i++) if ($i ~ /^ticket=/ && (substr($i, 8) in W)) next } { print }' "$T/lg" > "$T/lgc"
  awk -v ST="$T/st" -v BAD="$T/badh" '{ l = $0; if (l ~ /^[ \t]*(#|$)/) next
      if (l !~ /[|][ \t]*stand-in/) { print "line " FNR ": no stand-in label" > BAD; next }
      sub(/[ \t]*[|][ \t]*stand-in.*$/, "", l); n = split(l, w, " "); split(l, p, /[ \t]*[|][ \t]*/)
      if (w[1] == "engines" && n > 1) { e = l; sub(/^engines[ \t]+/, "", e); print "eng\t" e > ST }
      else if (w[1] == "engine-split" && n == 2) print "split\t" w[2] > ST
      else if (w[1] == "closed" && n == 2) print "closed\t" w[2] > ST
      else if (w[1] == "row" && w[3] ~ /^(accepted|accepted-by-ruling|owed|paid|failing|held|known-limit)$/) print "rs\t" w[2] "\t" w[3] "\t" (w[4] == "fault-proven" ? "fp" : "-") > ST
      else if (w[1] == "fix" && p[2] != "" && (rs = p[1]) ~ /^fix[ \t]+[A-Z]+-[0-9]/) { sub(/^fix[ \t]+/, "", rs); gsub(/[ \t]+/, ",", rs); print "fixr\t" l "\t" rs "\t" p[2] "\t" p[3] > ST }
      else if (w[1] == "lesson" && w[3] == "|" && p[2] != "") print "lesson\t" w[2] "\t" p[2] > ST
      else if (w[1] == "reached" && w[3] ~ /^[A-Z]+-[0-9]+$/) print "reached\t" w[2] "\t" w[3] "\t" ((w[4] ~ /^[0-9a-f]+$/) ? w[2] ":" w[3] ":" w[4] : FNR) > ST
      else if (w[1] != "candidate" && w[1] != "staged" && w[1] != "setup-hold" && w[1] != "stage-closed" && w[1] != "production") print "line " FNR ": out of form" > BAD }' "$HAND"   # v0.26.10.26.2: staged and setup-hold too, plan.sh reads them
  touch "$T/st" "$T/badh"; [ ! -s "$T/badh" ] || ref ".vid/tw/handed: $(paste -sd ';' "$T/badh")"
  # R2: a fix line known by a hash of its text
  { grep -v '^fixr	' "$T/st" || true; awk -F'\t' '$1 == "fixr"' "$T/st" | while IFS='	' read -r _x l rs y z; do printf 'fix\t%s\t%s\t%s\t%s\n' "$(printf '%s' "$l" | cksum | cut -d' ' -f1)" "$rs" "$y" "$z"; done; } > "$T/st2"; cat "$T/st2" > "$T/st"
}
sv() { awk -F'\t' -v k="$1" '$1 == k { v = $2 } END { print v }' "$T/st"; }
state() { awk -F'\t' -v r="$1" '$1 == "rs" && $2 == r { v = $3 } END { print v }' "$T/st"; }
started() { grep "^step-start " .vid/metrics-events 2>/dev/null | grep -q " step=$1 "; }
# the log: tk <n> — ticket n's newest published or amended line; opn — the open tickets: the newest sync's, and each
# published after it, less the withdrawn; rowsof <step> — every row any ticket of the step has held
tk() { awk -v n="$1" '($1 == "published" || $1 == "amended") && $2 == n { l = $0 } END { print l }' "$T/lg"; }
opn() { awk "$KV"' $1 == "sync" { split("", O); m = split(kv("open"), a, ","); for (i = 1; i <= m; i++) if (a[i] ~ /^[0-9]+$/) O[a[i]] = 1 }
    $1 == "published" { O[$2] = 1 } $1 == "withdrawn" { W[$2] = 1 } END { for (t in O) if (!(t in W)) print t }' "$T/lg" | sort -n; }
fld() { printf '%s\n' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -n 1; }
rowsof() { awk "$KV"' ($1 == "published" || $1 == "amended") && kv("step") == s { print kv("rows") }' s="$1" "$T/lg" | tr ',' '\n' | grep -v '^-*$' | sort -u; }
srows() { awk -F'\t' -v s="$1" '$1 == s { print $5 }' "$T/steps" | tr ' ' '\n' | grep -v '^$' || true; }
rline() { awk -F'|' "$TR"' { k = tr($1); id = (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr($2) : k } id == r { print; exit }' r="$1" "$T/inv"; }
rhash() { rline "$1" | git hash-object --stdin | cut -c1-12; }
# sentin <row> <step>: the row's hash as a ticket of that step last sent it (a row moved in from another step is unsent)
sentin() { awk "$KV"' ($1 == "published" || $1 == "amended") && kv("step") == s { K[$2] = 1 } $1 == "sent" && $2 == r && (kv("ticket") in K) { h = kv("hash") } END { print h }' r="$1" s="$2" "$(lgof "$2")"; }
# lgof <step>: the log a step is owed by: closed-outside tickets as never published. 0.26.10.29.2 (R4): for a step of a closed stage
# too, whose rows then go out again in a new ticket, the stage left closed (round.sh leaves its step closed)
lgof() { echo "$T/lgc"; }
lim() { awk -F'\t' -v r="$1" '$1 == r && $2 == "row" && $6 ~ /^(limit|later|record)$/ { f = 1 } END { exit !f }' "$T/rows" || case "$(state "$1")" in known-limit) true ;; *) false ;; esac; }
owed() { awk -F'\t' -v r="$1" '$1 == r && $2 == "row" && $7 ~ /(^| )(owed-[a-z]+|seam)( |$)/ { f = 1 } END { exit !f }' "$T/rows"; }

# q <file>: each line of the file quoted (`> `)
q() { sed 's/^/> /; s/^> $/>/' "$1"; }
# the step section (§1.1 §10, brief.sh steplines, archrows, callrows copied): the step's line and its builds-on lines
# from the kept plan, the shared: line, the module table's rows of its modules, then those it may call, at most 40
stepsec() {
  awk -v st="$1" "$TR"' /^[ \t]*step[ \t]/ { n = split($0, f, "|"); id = tr(f[1]); sub(/^step[ \t]+/, "", id); id = tr(id); L[id] = $0
      for (k = 2; k <= n; k++) { x = tr(f[k]); if (x ~ /^builds-on:/) B[id] = tr(substr(x, 11)) } }
    END { if (!(st in L)) exit 1; print L[st]; n = split(B[st], a, /[ ,\t]+/); for (k = 1; k <= n; k++) if (a[k] != "" && a[k] != "-" && (a[k] in L)) print L[a[k]] }' "$PF" > "$T/sl" || ref "$1 is no step of the recorded plan $PH"
  grep -m 1 '^[[:space:]]*shared:' "$PF" >> "$T/sl" || true
  _m=$(sed -n 1p "$T/sl" | awk -F'|' '{ for (k = 2; k <= NF; k++) { x = $k; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^modules:/) print substr(x, 9) } }')
  awk -v mods="$_m" 'function nm(s) { gsub(/^[ \t`]+|[ \t`]+$/, "", s); gsub(/\./, "/", s); sub(/\/+$/, "", s); return s }
    BEGIN { n = split(mods, a, /[ ,\t]+/); for (k = 1; k <= n; k++) if (a[k] != "") M[nm(a[k])] = 1 }
    /^[ \t]*\|/ { if (!col) { n = split($0, c, "|"); for (k = 2; k < n; k++) { x = c[k]; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x == "Module") col = k; if (x == "Dependents") dc = k } if (col) { hdr = $0; got = 1 } next }
      if ($0 ~ /^[ \t]*\|[ \t:|-]*$/) { sep = $0; next } split($0, c, "|"); if (nm(c[col]) in M) { O[++r] = $0; next }
      if (dc) { m = split(c[dc], d, /[ ,]+/); for (k = 1; k <= m; k++) { x = nm(d[k]); if (x == "all" || (x in M)) { C[++s] = $0; break } } } next }
    col && !/^[ \t]*\|/ { col = 0; dc = 0 }
    END { if (!r && !s) exit; print ""; print hdr; if (sep != "") print sep; t = 0; for (k = 1; k <= r; k++) if (++t <= 40) print O[k]; for (k = 1; k <= s; k++) if (++t <= 40) print C[k]
      if (t > 40) printf "(+%d rows: ARCHITECTURE.md)\n", t - 40 }' "$T/arch" >> "$T/sl"; }
# reqs: from $T/ids — $T/rl (each row's inventory line), $T/dfids (a ROW's derived-from tokens, as brief.sh; another
# row's items), $T/items and $T/itemids (each effective line, whole, once, in brief.sh's order), $T/ans (the answers
# their source: fields cite, each answer's newest row), $T/rules (brief.sh's rulerows), $T/decs (brief.sh's builder join)
reqs() {
  : > "$T/itemids"   # R3: each ticket's own, so due's rewrites carry nothing from one open ticket into the next
  awk -F'|' -v IDS="$T/ids" "$TR"' BEGIN { while ((getline l < IDS) > 0) W[l] = ++n } { k = tr($1); id = (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr($2) : k; if ((id in W) && !(id in L)) L[id] = $0 }
    END { for (i = 1; i <= n; i++) for (id in W) if (W[id] == i && (id in L)) print L[id] }' "$T/inv" > "$T/rl"
  { awk -F'|' '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); if (id ~ /^ROW-/) { n = split($7, a, /[ ,]+/); for (i = 1; i <= n; i++) if (a[i] != "") print a[i] } }' "$T/rl"
    awk -F'\t' -v IDS="$T/ids" 'BEGIN { while ((getline l < IDS) > 0) W[l] = 1 } ($1 in W) && $1 !~ /^ROW-/ && $2 == "row" { n = split($4, b, " "); for (i = 1; i <= n; i++) print b[i] }' "$T/rows"; } | sort -u > "$T/dfids"
  awk -F'|' -v DF="$T/dfids" -v IT="$T/itemids" '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id); if (!(id in L)) L[id] = $0 }
    END { while ((getline i < DF) > 0) if (i in L) { print L[i]; print i > IT } }' "$T/eff" > "$T/items"
  awk '/^```/ { if (b == "") { b = substr($0, 4); sub(/[ \t].*/, "", b); if (b == "") b = "-" } else b = ""; next }
    b == "vid-prd-answers" && !/^[ \t]*#/ { id = $0; sub(/[ \t]*\|.*/, "", id); sub(/[ \t]+AMENDED$/, "", id); if (id ~ /^A-[0-9]+$/) L[id] = $0 }
    END { for (k in L) print k "\t" L[k] }' "$T/prd" > "$T/ansall"
  awk -F'|' '{ for (i = 2; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (index(f, "source:") == 1) while (match(f, /A-[0-9]+/)) { print substr(f, RSTART, RLENGTH); f = substr(f, RSTART + RLENGTH) } } }' "$T/items" | awk '!s[$0]++' |
    awk -F'\t' 'NR == FNR { L[$1] = $2; next } ($1 in L) { print L[$1] }' "$T/ansall" - > "$T/ans"
  awk -F'|' -v idf="$T/itemids" "$WHOLE"' BEGIN { while ((getline l < idf) > 0) if (l != "") I[++ni] = l }
    { k1 = $1; gsub(/^[ \t]+|[ \t]+$/, "", k1); if (k1 != "rule") next
      for (i = 2; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (index(f, "origin:") != 1) continue; for (k = 1; k <= ni; k++) if (has(f, I[k])) { print; next } } }' "$T/inv" > "$T/rules"
  { cat "$T/ids" "$T/dfids"; awk -F'|' '{ x = $2; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^RULE-[0-9]+$/) print x }' "$T/rules"; } > "$T/joinids"
  SC='function sc(f,   n, a, k) { n = split(f, a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "n/a" && index(a[k], "/") > 1) print substr(a[k], 1, index(a[k], "/") - 1) }'
  awk -F'|' "$TR$SC"' tr($1) ~ /^ROW-/ { sc(tr($5)) }' "$T/inv" | sort -u > "$T/scall"; awk -F'|' "$TR$SC"' tr($1) ~ /^ROW-/ { sc(tr($5)) }' "$T/rl" | sort -u > "$T/scbrief"
  awk -F'|' '{ for (i = 8; i <= NF; i++) { f = $i; gsub(/^[ \t]+|[ \t]+$/, "", f); if (f ~ /^divergence:/) { sub(/^divergence:[ \t]*/, "", f); n = split(f, a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] ~ /^DIF-[0-9]+$/) print a[k] } } }' "$T/rl" | sort -u > "$T/difbrief"
  sed -n 1p "$T/sl" | awk -F'|' 'function nm(s) { gsub(/^[ \t`]+|[ \t`]+$/, "", s); gsub(/\./, "/", s); sub(/\/+$/, "", s); return s }
    { for (k = 2; k <= NF; k++) { x = $k; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^modules:/) { n = split(substr(x, 9), a, /[ ,\t]+/); for (i = 1; i <= n; i++) if (a[i] != "") print nm(a[i]) } } }' > "$T/stepmods"
  # 0.26.10.29.5 (DP-1 R5): $T/named, the ids `writer.sh name` named for this ticket's step (.vid/tw/named), joined whatever their label, as brief.sh's --decisions
  awk -v s="$S" '$1 == s { n = split($2, a, ","); for (i = 1; i <= n; i++) if (a[i] != "") print a[i] }' .vid/tw/named > "$T/named" 2>/dev/null || : > "$T/named"
  # brief.sh's section 3 join, copied: the id join (every field, why: included), a label's items, the safe rule narrowed to the step's screens
  awk -v jf="$T/joinids" -v saf="$T/scall" -v sbf="$T/scbrief" -v dbf="$T/difbrief" -v smf="$T/stepmods" -v nmf="$T/named" "$WHOLE"'
    function anyid(s,   o, q, x, y) { q = s; o = 0; while (match(q, /(ROW|REQ|RULE)-[0-9]+/)) { x = (o + RSTART > 1) ? substr(s, o + RSTART - 1, 1) : ""; y = substr(s, o + RSTART + RLENGTH, 1); if (x !~ /[A-Za-z0-9_-]/ && y !~ /[A-Za-z0-9_-]/) return 1; o += RSTART; q = substr(s, o + 1) } return 0 }
    function label(   n, k, f, t, m, a, i2) { split("", AP); nap = 0; n = split($0, t, "|")
      for (k = 2; k <= n; k++) { f = t[k]; gsub(/^[ \t]+|[ \t]+$/, "", f)
        if (f ~ /^scope:[ \t]*project$/) return "project"
        if (f ~ /^applies-to:/) { sub(/^applies-to:[ \t]*/, "", f); m = split(f, a, /[ ,]+/); for (i2 = 1; i2 <= m; i2++) if (a[i2] != "") AP[++nap] = a[i2]; return "applies" } }
      return "" }
    BEGIN { while ((getline l < jf) > 0) { J[++nj] = l; JS[l] = 1 } while ((getline l < saf) > 0) SA[++ns] = l; while ((getline l < sbf) > 0) SB[l] = 1
      while ((getline l < dbf) > 0) DB[l] = 1; while ((getline l < smf) > 0) SM[l] = 1; while ((getline l < nmf) > 0) N["**" l "**"] = 1 }
    function mnm(s) { gsub(/\./, "/", s); sub(/\/+$/, "", s); return s }
    # 0.26.10.28.5 (R2): a decision about the settings of ViD itself never reaches a ticket, whatever its label or join: it carries the mark
    # `| about: vid-settings` beside its label, or it records keys of the records of ViD (.vid/budget and its keys), as a project made before the mark has it
    function own(   n, t, k, f) { n = split($0, t, "|"); for (k = 2; k <= n; k++) { f = t[k]; gsub(/^[ \t]+|[ \t]+$/, "", f); if (f ~ /^about:[ \t]*vid-settings$/) return 1 }
      return (index($0, ".vid/budget") || $0 ~ /(^|[^A-Za-z0-9_-])(stacks|memory-headroom-mb|claims-per-slice|wall-hours-per-slice|court-seconds|builder-context-tokens|chunk-seconds|unverified-rows|env-mb|silence-minutes|startup-minutes|run-limit-minutes|builders-target|builder-tool|codex-model|codex-effort)=/) }
    own() { next }
    # IR I3 (brief.sh'"'"'s emit, copied): line i, then each line its rule part'"'"'s `replaced-by:` mark names, whatever their
    # labels, each line once in the section; a line about ViD'"'"'s own settings is never one of them (own(), above)
    function emit(i,   p, r, n, t, k, f, m, a, q) { if (i in P) return; P[i] = 1; print L[i]
      p = index(L[i], " | why:"); r = p ? substr(L[i], 1, p - 1) : L[i]
      n = split(r, t, "|"); for (k = 2; k <= n; k++) { f = t[k]; gsub(/^[ \t]+|[ \t]+$/, "", f)
        if (f ~ /^replaced-by:/) { m = split(substr(f, 13), a, /[ ,]+/); for (q = 1; q <= m; q++) if (a[q] in ID) emit(ID[a[q]]) } } }
    { L[++nl] = $0; if (match($0, /^- \*\*D-[0-9]+\*\*/) && !(substr($0, 5, RLENGTH - 6) in ID)) ID[substr($0, 5, RLENGTH - 6)] = nl
      hit = 0; if (match($0, /\*\*D-[0-9]+\*\*/) && (substr($0, RSTART, RLENGTH) in N)) hit = 1   # a named id always stays, the settings own() apart
      for (i = 1; !hit && i <= nj; i++) if (has($0, J[i])) hit = 1
      lab = label()
      for (i = 1; !hit && i <= nap; i++) if ((AP[i] in JS) || (AP[i] in SB) || (AP[i] in DB)) hit = 1
      for (i = 1; !hit && i <= nap; i++) if (mnm(AP[i]) in SM) hit = 1
      if (!hit && (lab == "project" || (lab == "" && !anyid($0)))) { named = 0; mine = 0; for (i = 1; i <= ns; i++) if (has($0, SA[i])) { named = 1; if (SA[i] in SB) mine = 1 } hit = (!named || mine) }
      if (hit) H[nl] = 1 }
    END { for (i = 1; i <= nl; i++) if (i in H) emit(i) }' "$T/dec" > "$T/decs"
}
# rowsec: each row's inventory line less the fields a ticket leaves out (a test path, proved-red:, golden:, a one-path census, a
# seam's evidence paths, module:, match:), quoted, then its marks, a fix's reason. A rule's or hostility row's test or
# census field that is one path is the path left out
rowsec() {
  awk -F'|' -v ST="$T/rows" "$TR$A1"' function clean(v,   n, a, i, o) { n = split(v, a, " "); o = ""; for (i = 1; i <= n; i++) o = o (o == "" ? "" : " ") (prof(a[i]) != "" ? "(a word)" : a[i]); return o }
    BEGIN { while ((getline l < ST) > 0) { split(l, a, "\t"); if (a[2] == "row") { M[a[1]] = a[7]; if (index(a[11], "actor: (process)") || a[7] ~ /journey/) P[a[1]] = 1 } } }
    { k = tr($1); id = (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr($2) : k; m = split($0, f, "|"); o = ""
      for (i = 1; i <= m; i++) { x = tr(f[i]); y = x; sub(/[ \t].*/, "", y)
        if (x ~ /^(proved-red|golden|module|match):/ || (x ~ /^evidence:/ && x !~ /^evidence:[ \t]*owed$/) || (k ~ /^ROW-/ && i == 8 && x !~ /^owed:/ && y ~ /\//) || x ~ /^owed:[ \t]*prerequisite/ || (k ~ /^(rule|hostility)$/ && i >= 4 && x !~ /[ \t:]/ && x ~ /\//)) continue
        o = o (o == "" ? "" : "|") f[i] }
      sub(/[ \t]+$/, "", o); print "> " o; print "- " id " marks: " (M[id] == "" ? "none" : M[id]) (id in P ? "; run with the product'"'"'s processes" : "")
      if (W != "") { m = split(W, wp, "; "); v = W; for (j = 1; j <= m; j++) if (index(wp[j], id ": ") == 1) { v = substr(wp[j], length(id) + 3); break } print "- " id " failed: " clean(v) } }' W="${WHY:-}" "$T/rl"; }
# lists: $T/reg and $T/flt — the regression rows (accepted or by ruling, of the golden path, a journey, a protection row
# with fault-proven, a shell or reachability row, a rule row (v0.26.10.26.4 R5), a row of a bug finding, a reached row; never a known limit, a
# deploy-owed row or the ticket's own) and the faulted rows (the ticket's rows not deploy-owed: every protection row with
# its disable: note, a journey's lowest transition, every other row whose number is a multiple of ten); a reached-rows
# ticket's rows are regression rows, faulted only when retested (T4)
lists() {
  G=$(awk -F'\t' '$6 == "skeleton" { print $5; exit }' "$T/steps")
  awk -F'\t' -v IDS="$T/ids" -v ST="$T/st" -v G=" $G " -v RC=" $REACH " -v RG="$T/reg" -v FL="$T/flt" -v K="$K" '
    BEGIN { while ((getline l < IDS) > 0) W[l] = 1; while ((getline l < ST) > 0) { split(l, a, "\t"); if (a[1] == "rs") { S[a[2]] = a[3]; F[a[2]] = a[4] } } }
    function has(m, x) { return index(" " m " ", " " x " ") }
    $2 == "tr" { k = $1; sub(/.*-T/, "", k); if (!($3 in lo) || k + 0 < lo[$3]) { lo[$3] = k + 0; ft[$3] = $1 } next }
    $2 == "row" { o[++n] = $1; mk[$1] = $7; cl[$1] = $6; d = $11; dis[$1] = ""; p = index(d, "disable: "); if (p) { x = substr(d, p); q = index(x, " · "); dis[$1] = q ? substr(x, 1, q - 1) : x } bug[$1] = (d ~ /origin: finding/) }
    END { for (i = 1; i <= n; i++) { r = o[i]; m = mk[r]; ow = (m ~ /(^| )(owed-[a-z]+|seam)( |$)/)
        if ((r in W) && K != "reached") { if (ow) continue; k = r; sub(/^[A-Z]+-/, "", k)
          if (has(m, "protection")) { print "- " r ": make this row'"'"'s fail-if true, and nothing else; its disable: note, quoted:" > FL; d = dis[r]; sub(/[ \t]+$/, "", d); print "> " (d == "" ? "disable: none" : d) > FL }
          else if (has(m, "journey")) print "- " ft[r] " (of the journey " r "): make this transition'"'"'s fail-if true, and nothing else" > FL
          else if (k % 10 == 0) print "- " r ": make this row'"'"'s fail-if true, and nothing else" > FL; continue }
        if ((S[r] == "accepted" || S[r] == "accepted-by-ruling") && !ow && cl[r] != "limit" && (has(G, r) || has(m, "journey") || (has(m, "protection") && F[r] == "fp") || has(m, "shell") || has(m, "reachability") || has(m, "rule") || bug[r] || has(RC, r))) print "- " r > RG } }' "$T/rows"   # v0.26.10.26.4 (R5): an accepted rule row, kept armed
  touch "$T/reg" "$T/flt"; }
q_() { if [ -s "$1" ]; then q "$1"; else echo none; fi; }
# laws: the sections of CLAUDE.md that bind the product, Import law and Design law, quoted; 0.26.10.28.1 (stage 9 R6, LW-03):
# the complexity law is this plugin's own law for ViD's checks, never quoted into a ticket
laws() { git cat-file -e "$AT:CLAUDE.md" 2>/dev/null || { echo 'none: the project has no CLAUDE.md'; return 0; }
  git show "$AT:CLAUDE.md" | awk '/^## / { on = ($0 ~ /^## (Import law|Design law)/); sk = 0 } on && /^```vid-placement/ { sk = 1; next } sk && /^```/ { sk = 0; next } on && !sk' > "$T/law"
  if [ -s "$T/law" ]; then q "$T/law"; else echo 'none: no section of CLAUDE.md binds the product'; fi; }
stack() { printf 'The stack, decided at init:\n\n'; { git show "$AT:BASELINE.md" 2>/dev/null || true; } | awk '/^## Stack[ \t]*$/ { on = 1; next } on && /^## / { exit } on' > "$T/sk"; q_ "$T/sk"
  printf '\nThe hosting, decided at init:\n\n'; sed -n '/^```vid-hosting[[:space:]]*$/,/^```[[:space:]]*$/p' "$T/arch" | grep -v '^```' > "$T/ho" || true; q_ "$T/ho"; }
engines() { set -- $(sv eng); printf '\n## Engines\n\n- primary: %s\n' "$1"; shift
  if grep -q '^split' "$T/st"; then for e; do printf -- '- also: %s\n' "$e"; done; printf '\nEvery engine is asked: a row has failed in one engine and passed in another.\n'
  else printf '\nThe primary alone is asked: no row has yet failed in one engine and passed in another.\n'; fi; }
reached() { if [ -n "$REACH" ]; then for r in $REACH; do i=$(awk -F'\t' -v r="$r" '$1 == "reached" && $2 == r { v = $3 } END { print v }' "$T/st")
      case $i in REQ-*|INV-*) w="its requirement $i" ;; *) w="the line $i it rests on" ;; esac
      printf -- '- %s, %s changed%s:\n' "$r" "$w" "$(! owed "$r" || echo '; deploy-owed, so no regression row: kept, its state stands; rewritten, it is retested and owed again')"
      case $i in REQ-*|INV-*) awk -F'|' -v r="$i" '{ id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id) } id == r { print "> " $0; exit }' "$T/eff" ;; *) rline "$i" | sed 's/^/> /' ;; esac; done
  else echo none; fi; }
hist() { for r in $(cat "$T/ids"); do
    t=$(awk "$KV"' $1 == "published" && $2 != n && index("," kv("rows") ",", "," r ",") { printf "%s#%s", (c++ ? ", " : ""), $2 }' r="$r" n="$NUM" "$T/lg")
    x=$(awk -F'\t' -v r="$r" '$1 == "fix" && index("," $3 ",", "," r ",") && $5 != "" { printf "%s%s", (c++ ? "; " : ""), $5 }' "$T/st")
    [ -z "$t$x" ] || printf -- '- %s: its earlier tickets %s; its failing decisions, fix tickets and runs: %s.\n' "$r" "${t:-none}" "${x:-none}"; done > "$T/hi"
  if [ -s "$T/hi" ]; then cat "$T/hi"; else echo 'none: no row of this ticket has an earlier attempt'; fi; }
# reading (§1.1 §8): the spec repository by name, then each file of the export the ticket rests on, by its path there
xpaths() { git --git-dir=.vid/spec.git ls-tree -r -z --name-only "$1" > "$T/xz" 2>/dev/null && tr '\0' '\n' < "$T/xz"; }
reading() { xpaths "$EXP" > "$T/xr" || ref "the export $EXP is not in .vid/spec.git: sh checks/github.sh spec-export"
  printf 'The spec repository, https://github.com/%s, at the export %s; each of its files, by its path there:\n\n' "$(twkey spec-repo)" "$EXP"; q "$T/xr"; }
# known (v0.26.10.25.3, R4): the findings the owner ruled known, each quoted, so a later grader reads them as the ticket's own words
known() { if [ -s .vid/tw/known-findings ]; then q .vid/tw/known-findings; else echo none; fi; }
lessons() { awk -F'\t' -v IDS="$T/ids" 'BEGIN { while ((getline l < IDS) > 0) W[l] = 1 } $1 == "lesson" { n = split($2, a, ","); for (i = 1; i <= n; i++) if (a[i] in W) { print "- " $3 " (" $2 ")"; c++; break } } END { if (!c) print "none" }' "$T/st"; }
# 0.26.10.29.5 (DP-1 R3): rule 2 keeps each decision's why: from every GR, not a fix ticket's alone; a fix ticket's failed: lines and History as before
roles() { cat <<'R'
DevAgent's roles; each report names the role that made it:

- DM, DevAgent's manager: claims the ticket, starts DevAgent's agents and keeps them apart, and integrates their work.
- TA, test author: writes each row's tests from the row and its fail-if, before any product code, and commits them alone.
- TM, test manager: keeps the test environments, runs every test run reported to ViD, and plants each fault.
- AN, test analyst: finds why a run failed when the cause is not plain.
- BU, builder: writes the product code until the row tests and the regression rows pass.
- FX, fixer: fixes the failing rows of an open pull request, and builds fix tickets.
- GR, grader: gives each row its verdict, and writes each needed fault's change.
- SR, second reviewer: sorts GR's breached and unclear lines, once a ticket.
- MR, merger: does DevAgent's own review of the code, asks for ViD's decision, and merges once ViD accepts.
- DP, deployer: deploys on ViD's okay, and reports each deploy.

The independence rules, which ViD takes DevAgent's word it keeps:

1. TA, TM and GR are never BU or FX. TA and TM may be one agent.
2. GR is a separate agent, never TA or TM, in a fresh context: it reads the code, the tests and the results, never the reasoning of BU, FX, TA or TM. A GR writing a break at a later head is not told an earlier decision or a fix. GR reads the ticket without the why: of each decision, and a fix ticket also without its failed: lines and its History: the rows, the code and the results alone.
3. BU and FX never write, change or weaken a test.
4. Only TM's test runs are reported. DP reports deploys, and the deploy steps that are no row.
5. TA never weakens a test below its row's promise. It may correct a test that asks more than the promise; the row is then retested.
6. DM, AN, MR and DP may be any of DevAgent's agents, but each report names its role.
7. SR is a fresh agent, never the GR, BU, FX or TA of the ticket. It is given no earlier sorting, no fix history, no spend or time, no count either way, and no push to find problems, clear them, finish a ticket or keep it open.
8. DevAgent reads the spec repository's main alone: its other branches hold ViD's records, and are no part of the spec.
R
}
asks() {
  t3='- T3 (TM): at the pull request'"'"'s head, run every row and every regression row, in each asked engine.'
  t4='- T4 (GR, then TM): at the same head, GR writes each needed fault'"'"'s change: make this row'"'"'s fail-if true, and nothing else; a later head may plant a row'"'"'s earlier patch again. TM plants it and runs the faulted row'"'"'s test and the control'"'"'s, in the primary engine; TM picks each control, a row or another case of the faulted row that passed at this head'"'"'s T3. The needed faults: the faulted rows'"'"', each row with no red'"'"'s, each retested row'"'"'s.'
  t5='- T5 (GR, SR): at the ticket'"'"'s first head alone, two fresh GRs, each in its own blind copy, grade each row against its fail-if, the grading checklist and the test differences, a screen row also against the design, and their lines are combined. SR sorts what the grade leaves, once. No later head has a grade or a sort.'
  case $K in
    reached) echo '- T1 (TA): for each row, keep its test when the changed clause is not one it tests, or rewrite it; when unsure, rewrite it. A rewritten test makes its row retested. When every test is kept, commit nothing but one empty commit naming the kept rows, so the pull request has a head.'; echo "$t3"; echo "$t4" ;;   # v0.26.10.26.7 (R6, W-8)
    *) echo '- T1 (TA): write at least one test per row, per transition for a journey, its name matching the row'"'"'s id.'
      if [ "$K" = skeleton ]; then echo '- T3 (TM): at the pull request'"'"'s head, run every row in each engine you declare. The head report declares the engines, the primary first, and how many test environments you run.'
        echo '- T4 (GR, then TM): at the same head, the skeleton'"'"'s fault: GR writes the change that makes its rows'"'"' fail-if true, and nothing else; TM plants it and runs the rows'"'"' tests in the primary engine, with no control.'; echo "$t5"
        printf '\nThere is no T2: the skeleton has no red, so its fault stands in for it.\n'
      elif [ "$AO" = yes ]; then echo '- T3 (TM): at the pull request'"'"'s head, run the regression rows, in each asked engine.'; [ -n "$FU" ] || echo "$t5"
        printf '\nEvery row of this ticket is deploy-owed: no red and no fault, so no T2 and no T4; its next staging, rehearsal or production run proves it.\n'
      else printf '%s%s\n' '- T2 (TA, then TM): TA commits those tests alone, before any product code; TM runs them in the primary engine. This is the red proof.' "$([ "$K" != fix ] || echo ' In this fix ticket TA first makes the test catch the reason; TM may name the base as the tests-first commit when the test already fails there.')"
        echo "$t3"; echo "$t4"; [ -n "$FU" ] || echo "$t5"; fi ;;
  esac; echo
  [ -z "$FU" ] || printf 'This ticket follows #%s. This step had its grade at its first ticket, #%s: this one asks no T5, so it has no grade and no sort. The stage'"'"'s grade reads its code.\n\n' "$FU" "$(ffst "$S")"   # 0.26.10.28.10 (R1)
  awk -F'\t' -v IDS="$T/ids" -v FU="$FU" 'BEGIN { while ((getline l < IDS) > 0) W[l] = 1 } ($1 in W) && $2 == "row" { m = " " $7 " "
      if (index(m, " protection ")) print "- " $1 ": its test'"'"'s failure message carries the line vid-forbidden-effect: " $1 ". A protection row names something that must never happen, and the line marks evidence of that thing alone."
      if (index(m, " seam ")) print "- " $1 ": the seam'"'"'s probe: its test makes one real action through the service, on staging."
      if (index(m, " rule ")) print "- " $1 ": the report gives the number of places its test covered; zero places means the row fails."
      if ($1 ~ /^DIF-/) print "- " $1 ": a test difference: the test environment uses its test value as the stand-in, and the report names it."
      if (index($11, "actor: (process)") || index(m, " journey ")) print "- " $1 ": run with the product'"'"'s own declared processes, not inline."
      if (m ~ / (owed-[a-z]+|seam) /) D = D " " $1 } END { if (D != "") print "- Deploy-owed rows take part in " (FU == "" ? "T1 and T5" : "T1") " only:" D "." }' "$T/rows"
  printf '\nQuestions: a product question goes as a comment on this issue, its pull request or a run ask, its first line beginning Question: and naming the rows or step it concerns. Label the issue %sblocked only when the work cannot go on without the answer; otherwise build on your default, and say the default in the question.\n\nDecisions: the pull request'"'"'s body holds a section that begins with the line Decisions:, then one line a technical decision of the branch, "- what was chosen | why: the reason", or the one line Decisions: none. A decision is a choice that picked between plausible alternatives, constrains later code, or would surprise a competent newcomer. A hand-rolled security mechanism (cryptography, one-time codes, session tokens, signing) is always one, and names the standard it implements; so is a change to stored data, naming what it changes and how it is rolled back. A new or extended lifecycle, the states a stored record moves through, is a question on this ticket before it is built. A line that bears on many areas of the product ends with | scope: project. Keep the section current from the first head on; ViD records it when the pull request merges. A pull request whose body lacks the section is not accepted: its decision reads not yet until the section is there.\n\nA decision line beginning analyst due asks for DevAgent'"'"'s test analyst on the cases that could not run.\n\nResults: every report in ViD'"'"'s results format, by name: ViD results format 1.\n\nWork on any branch, from the base above; open one pull request into main whose body begins ticket: #, then this issue'"'"'s number.\n' "$PFX"; }   # v0.26.10.26.7 (R6, W-7): outside the hash (qhash); 0.26.10.29.5 (DP-1 R1): the Decisions paragraph after the Questions one, outside it too
# qhash: what an amendment is owed on; 0.26.10.29.2 (R3): the earlier work lines too
qhash() { awk '/^## / { s = substr($0, 4); next } s == "Header" && /^- (kind|step|rows|earlier work):/ { print; next } s ~ /^(The step|Rows|Requirements|Decisions|Rules that bear on these rows|Laws|Non-goals|Rows a ruling reached|Grading checklist and records|Golden sets|The stack and hosting)$/' "$1" | git hash-object --stdin | cut -c1-12; }
# ticket <file>: the ticket of K, S, $T/ids, NUM, BASE, EXP, WHY, FIXL, REACH, RUL and AMW, and its meta
ticket() {
  F=$1; PFX=$(twkey labels-prefix); stepsec "$S"; reqs
  SN=$(awk -F'\t' -v s="$S" '$1 == s { print $2 }' "$T/steps"); STG=$(awk -F'\t' -v r="$(head -n 1 "$T/ids")" '$1 == r { print $5; exit }' "$T/rows")
  STN=$(git show "$AT:STAGES.md" 2>/dev/null | sed -n "s/^[[:space:]]*STAGE-0*${STG:-x}[[:space:]]*|[[:space:]]*\([^|]*[^|[:space:]]\)[[:space:]]*|.*/\1/p" | head -n 1)
  AO=yes; for r in $(cat "$T/ids"); do owed "$r" || AO=no; done
  : > "$T/reg"; : > "$T/flt"; [ "$K" = skeleton ] || lists
  case $K in skeleton) TT=Skeleton ;; step) TT=Step; [ -z "$FU" ] || TT=Follow-up ;; fix) TT=Fix ;; *) TT=Reached-rows ;; esac
  {
    printf '# %s ticket %s: %s\n\n## Header\n\n- number: %s\n- kind: %s\n- step: %s\n- stage: %s%s\n- plan: %s\n- base: %s\n- export: %s\n- rows: %s\n' "$TT" "$S" "$SN" "$NUM" "$K" "$S" "${STG:-?}" "${STN:+, $STN}" "$PH" "$BASE" "$EXP" "$(paste -sd ' ' "$T/ids")"
    [ -z "$FU" ] || printf -- '- follows: #%s\n' "$FU"
    earlier   # 0.26.10.29.2 (R3)
    [ -z "$AMW" ] || printf -- '- amended: %s\n' "$AMW"
    [ "$BASE" != none ] || printf '\nThe code repository is empty: start main with your first commit, then work from it.\n'   # v0.26.10.28.2 (R3)
    printf '\n## The step\n\n'; q "$T/sl"; printf '\n## Rows\n\n'; rowsec
    printf '\n## Requirements\n\n'; q_ "$T/items"; printf '\nThe answers they cite:\n\n'; q_ "$T/ans"
    printf '\n## Decisions\n\n'; q_ "$T/decs"; printf '\n## Rules that bear on these rows\n\n'; q_ "$T/rules"; printf '\n## Laws\n\n'; laws
    awk -F'|' '{ k = $2; gsub(/^[ \t]+|[ \t]+$/, "", k); if (k == "non_goal") print }' "$T/eff" > "$T/ng"; printf '\n## Non-goals\n\n'; q_ "$T/ng"
    if [ "$K" = skeleton ]; then printf '\n## The stack and hosting\n\n'; stack
    else engines; printf '\n## Regression rows\n\n'; if [ -s "$T/reg" ]; then cat "$T/reg"; else echo none; fi; printf '\n## Faulted rows\n\n'; if [ -s "$T/flt" ]; then cat "$T/flt"; else echo none; fi
      printf '\n## Rows a ruling reached\n\n'; reached; fi
    { git show "$AT:GRADING-CHECKLIST.md" 2>/dev/null || true; } > "$T/gc"; printf '\n## Grading checklist and records\n\n'; q_ "$T/gc"
    awk -F'\t' '$2 == "record" { print $1 }' "$T/rows" | while IFS= read -r r; do rline "$r"; done > "$T/rec"; printf '\nThe records, deliberately not tested:\n\n'; q_ "$T/rec"
    printf '\n## Golden sets\n\n'; awk -F'\t' -v IDS="$T/ids" 'BEGIN { while ((getline l < IDS) > 0) W[l] = 1 } ($1 in W) && $12 != "-" && $12 != "" { print $1 "\t" $12 }' "$T/rows" > "$T/gs"
    if [ -s "$T/gs" ]; then while IFS='	' read -r r g; do printf 'The golden set of %s:\n\n' "$r"; git show "$AT:$g" > "$T/g1" 2>/dev/null || : > "$T/g1"; q_ "$T/g1"; echo; done < "$T/gs"; else echo none; fi
    printf '\n## History\n\n'; hist; [ "$K" = skeleton ] || { printf '\n## Test lessons\n\n'; lessons; }; printf '\n## Known, ruled by the owner\n\n'; known; printf '\n## Further reading\n\n'; reading
    printf '\n## Roles\n\n'; roles; printf '\n## Asks\n\n'; asks
  } > "$T/wf" || exit 1
  awk "$A1"' /^## / { s = substr($0, 4) } /^>/ { $0 = unptr($0); if (isr(s, $0)) $0 = unq($0) } { print }' "$T/wf" > "$T/a1" || exit 1; put "$F" < "$T/a1" || exit 1   # Amendment 1
  { printf 'kind=%s step=%s rows=%s reached=%s rulings=%s fix=%s qhash=%s plan=%s base=%s export=%s\n' "$K" "$S" "$(paste -sd , "$T/ids")" "$(echo $REACH | tr ' ' ,)" "$(echo $RUL | tr ' ' ,)" "${FIXL:--}" "$(qhash "$F")" "$PH" "$BASE" "$EXP"
    [ -z "$AMW" ] || { printf 'why %s\n' "$AMW"; sed 's/^/tell /' "$T/tell"; }; for r in $(cat "$T/ids"); do printf 'sent %s %s\n' "$r" "$(rhash "$r")"; done; } > "$T/wm" || exit 1; put "${F%.md}.meta" < "$T/wm" || exit 1
}
# 0.26.10.29.2 (R3): earlier, the `- earlier work: ticket #<n>[, pull request #<p>]` lines of the ticket being written: each ticket a
# plan change withdrew, or took rows out of while its pull request was open (the log's `handover <n> pr=<p|-> rows=<…>`, github.sh's),
# one of whose rows this ticket holds and no ticket published or amended since has carried. Its work stays committed on that ticket's
# branch; DevAgent carries forward what still applies. In the hash (qhash), so a ticket written before the handover is owed it;
# no follow-up: it changes neither asks nor title
earlier() { awk -v IDS="$T/ids" -v me="$NUM" "$KV"' BEGIN { while ((getline l < IDS) > 0) W[l] = 1 }
    $1 == "handover" { m = split(kv("rows"), a, ","); for (j = 1; j <= m; j++) if (a[j] in W) { H[$2 SUBSEP a[j]] = 1; P[$2] = kv("pr"); if (!($2 in O)) O[$2] = ++k } next }
    ($1 == "published" || $1 == "amended") && $2 != me { m = split(kv("rows"), a, ","); for (j = 1; j <= m; j++) for (h in H) { split(h, x, SUBSEP); if (x[2] == a[j]) delete H[h] } }
    END { for (h in H) { split(h, x, SUBSEP); E[x[1]] = 1 } for (n in E) { p = P[n]; gsub(/,/, ", pull request #", p); printf "%d\t- earlier work: ticket #%s%s\n", O[n], n, (p != "" && p != "-") ? ", pull request #" p : "" } }' "$T/lg" | sort -n | cut -f2; }
# 0.26.10.29.2 (R3, R11): where <n>, where each row of ticket n's newest writing went, for its withdrawal's comment, one a line:
# `- <row> (<its promise>): <where>` — a known limit; out of the plan; to an open ticket of its step, or one holding it; or back to
# planned, a new ticket of its step to carry it
where_() { L0=$(tk "$1"); [ -n "$L0" ] || ref "#$1 is no ticket TW published"; s0=$(fld "$L0" step)
  for r in $(fld "$L0" rows | tr , ' '); do pr=$(awk -F'\t' -v r="$r" '$1 == r { print $8; exit }' "$T/rows"); s=$(stepof "$r"); m=''
    if lim "$r"; then w='a known limit, or not built in this phase: nothing to build'
    elif [ -z "$s" ]; then w='out of the plan'
    else for x in $(opn); do [ "$x" != "$1" ] || continue; l=$(tk "$x"); k=$(fld "$l" kind)
        if { [ "$(fld "$l" step)" = "$s" ] && { [ "$k" = step ] || [ "$k" = skeleton ]; }; } || fld "$l" rows | tr , '\n' | grep -qxF "$r"; then m=$x; break; fi; done
      if [ -n "$m" ]; then w="to step $s, ticket #$m"; elif [ "$s" = "$s0" ]; then w="stays in step $s: a new ticket of it carries it"; else w="to step $s, back to planned: a new ticket of it carries it"; fi; fi
    printf -- '- %s (%s): %s\n' "$r" "${pr:-no promise}" "$w"; done; }
# check <file>: one refusal per line into $T/ref (R8)
check() {
  : > "$T/ref"; parts_ "$1" 0 "$T/pk" > /dev/null 2>> "$T/ref" || true; roles > "$T/roles"; X=$(sed -n 's/^- export: //p' "$1" | head -n 1)
  xpaths "${X:-none}" > "$T/xp" || { : > "$T/xp"; echo "item: the export ${X:-none} is not in .vid/spec.git, so no path of ## Further reading can be checked" >> "$T/ref"; }
  awk -v REF="$T/ref" -v RL="$T/roles" -v XF="$T/xp" -v X="$X" "$A1"'
    function ref(s) { print s > REF }
    function word(l, c,   n, w, i) { n = split(l, w, /[ \t]+/); for (i = 1; i <= n; i++) if (index(w[i], c)) return w[i]; return c }
    function shapes(l, k,   i, c, u, n, w, x) { for (i = 1; i <= length(SET); i++) { c = substr(SET, i, 1); if (index(l, c)) ref("line " k ": code or a test — " word(l, c)) }
      u = l; gsub(/https?:\/\/[^ \t]*/, "", u); if (index(u, "/")) ref("line " k ": a file path — " word(u, "/")); n = split(u, w, /[ \t]+/)
      for (i = 1; i <= n; i++) { x = w[i]; if (x !~ /@/ && x ~ /(^|[^A-Za-z0-9_-])[a-z0-9_-][a-z0-9_-]+\.[a-z][a-z]?[a-z]?[a-z]?([^A-Za-z0-9]|$)/) ref("line " k ": a file path — " x)
        if (x ~ /^--?[A-Za-z]/) ref("line " k ": a runner command — " x) } }
    BEGIN { SET = "`{}<>$\\="; QS = "|The step|Rows|Requirements|Decisions|Rules that bear on these rows|Laws|Non-goals|Faulted rows|Rows a ruling reached|Grading checklist and records|Golden sets|The stack and hosting|Known, ruled by the owner|Further reading|"
      while ((getline x < RL) > 0) rl = rl x "\n"; while ((getline x < XF) > 0) XP[x] = 1 }
    { l = $0 }
    sec != "Header" && (x = ptr(l)) != "" { ref("line " NR ": a pointer into ViD" "\047" "s records — " x) }
    (x = prof(l)) != "" { ref("line " NR ": profanity — " x) }
    NR == 1 { TL = l; if (l !~ /^# (Skeleton|Step|Follow-up|Fix|Reached-rows) ticket [A-Za-z0-9_.-]+: ./) ref("item: the title is not # <kind> ticket <step>: <its name>"); else { t = l; sub(/^# [A-Za-z-]+ ticket [^:]*: /, "", t); shapes(t, 1) } next }
    /^## / { sec = substr(l, 4); so[++ns] = sec; seen[sec] = 1; next }
    sec != "" && l ~ /[^ \t]/ { body[sec]++ }
    { qd = (index(QS, "|" sec "|") && (l ~ /^> / || l == ">")) }
    sec ~ /^(Rows|Faulted rows|Rows a ruling reached|Regression rows)$/ && index(l, "owed: prerequisite") { x = (match(l, /[A-Z]+-[0-9]+/) ? substr(l, RSTART, RLENGTH) : "?"); ref("line " NR ": a prerequisite note — " x) }
    isr(sec, l) && unq(l) != l { x = (match(l, /owner chose:? "[^"]*"|owner: "[^"]*"|A: "[^"]*"; /) ? substr(l, RSTART, RLENGTH) : l); ref("line " NR ": an owner quote — " substr(x, 1, 40)) }
    qd && sec == "The step" && l ~ /^> [ \t]*step[ \t]/ { n = split(l, f, "|"); for (i = 2; i <= n; i++) { x = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^name:/) shapes(x, NR) } }
    qd && sec == "Rows" { n = split(substr(l, 3), f, "|"); a = f[1]; gsub(/^[ \t]+|[ \t]+$/, "", a); if (a !~ /^ROW-/) { a = f[2]; gsub(/^[ \t]+|[ \t]+$/, "", a) } RW[a] = 1
      if (l ~ /[|][ \t]*origin: plan/) for (i = 2; i <= n; i++) { x = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x !~ /^(owed|protects|disable|origin):/ && x != "n/a") shapes(x, NR) } }
    !qd { shapes(l, NR) }
    qd && sec == "Further reading" && !(substr(l, 3) in XP) { ref("line " NR ": a path outside the export " X " — " substr(l, 3)) }
    sec == "Further reading" && index(l, "The spec repository, https://github.com/") == 1 { srn = 1 }
    sec == "Header" && match(l, /^- [a-z]+: /) { k = substr(l, 3, RLENGTH - 4); v = substr(l, RLENGTH + 1); gsub(/[ \t]+$/, "", v); hv[k] = v }
    sec == "Rows" && l ~ /^- [A-Z]+-[0-9]+ failed: [^ ]/ { why++ }
    sec == "Asks" { at = at " " l; if (l ~ /^- T[1-5] /) ask[substr(l, 3, 2)] = 1 }
    sec == "Engines" && l ~ /^- primary: [^ ]/ { prim = 1 }
    sec == "Roles" { rb = rb l "\n" }
    sec == "The stack and hosting" && l ~ /^The (stack|hosting), decided at init:/ { part = substr(l, 5, 5); next }
    sec == "The stack and hosting" && l ~ /^>/ && l != ">" { sh[part]++ }
    END { K = hv["kind"]; if (K !~ /^(skeleton|step|fix|reached)$/) { ref("item: the header'"'"'s kind is missing, or not skeleton, step, fix or reached"); K = "step" }
      want = "Header|The step|Rows|Requirements|Decisions|Rules that bear on these rows|Laws|Non-goals|" (K == "skeleton" ? "The stack and hosting" : "Engines|Regression rows|Faulted rows|Rows a ruling reached") "|Grading checklist and records|Golden sets|History|" (K == "skeleton" ? "" : "Test lessons|") "Known, ruled by the owner|Further reading|Roles|Asks"
      n = split(want, Wn, "|"); got = ""; for (i = 1; i <= ns; i++) got = got (i > 1 ? "|" : "") so[i]
      for (i = 1; i <= n; i++) { if (!(Wn[i] in seen)) ref("item: the section ## " Wn[i] " is missing"); else if (!body[Wn[i]]) ref("item: the section ## " Wn[i] " is empty") }
      if (got != want) ref("item: the sections are not, in order, " want)
      split("number kind step stage plan base export rows", H, " "); for (i = 1; i <= 8; i++) if (hv[H[i]] == "") ref("item: the header has no " H[i])
      m = split(hv["rows"], R, " "); for (i = 1; i <= m; i++) if (!(R[i] in RW)) ref("item: the row " R[i] " is not quoted in ## Rows")
      if (!srn) ref("item: the further reading does not name the spec repository")
      if (K == "fix" && !why) ref("item: the fix ticket gives no reason its row failed")
      need = (K == "skeleton") ? "T1 T3 T4 T5" : (K == "reached") ? "T1 T3 T4" : (index(at, "Every row of this ticket is deploy-owed") ? "T1 T3 T5" : "T1 T2 T3 T4 T5")
      FW = hv["follows"]; if (FW != "") { if (K != "step" || FW !~ /^#[0-9]+$/) ref("item: follows: is #<n> on a step ticket alone"); sub(/ T5$/, "", need) }   # 0.26.10.28.10 (R1)
      if ((FW != "") != (substr(TL, 3, 9) == "Follow-up")) ref("item: a follow-up is titled Follow-up ticket and has a follows: line, and only it")
      for (i = 1; i <= 5; i++) { t = "T" i; if (index(need, t) && !ask[t]) ref("item: the asks lack " t); if (!index(need, t) && ask[t]) ref("item: the asks hold " t ", which this ticket must not ask") }
      if (!index(at, "ViD results format 1")) ref("item: the asks do not name the results format")
      if (!index(at, "its first line beginning Question:")) ref("item: the asks do not give the question channel")
      if (!index(at, "Decisions: the pull request" "\047" "s body holds a section")) ref("item: the asks do not ask for the decisions")   # 0.26.10.29.5 (DP-1 R1): every kind asks for the Decisions section of the pull request
      if (K == "skeleton" && !(index(at, "declares the engines") && index(at, "test environments"))) ref("item: the skeleton ticket does not ask for the engines and the test environments")
      if (K == "skeleton" && (!sh["stack"] || !sh["hosti"])) ref("item: the stack or the hosting is missing")
      if (K != "skeleton" && !prim) ref("item: the engines name no primary")
      gsub(/^\n+|\n+$/, "", rb); gsub(/^\n+|\n+$/, "", rl); if (rb != rl) ref("item: the roles and the independence rules are not ViD'"'"'s, word for word") }' "$1"
}
# parts_ <file> <issue> <dir>: the parts' paths (ticket.sh's packer: sections whole where they fit, a larger one at
# line boundaries), each at most 60,000 bytes with its first line naming it
parts_() {
  mkdir -p "$3"; rm -f "$3"/part-*.md; H=$(git hash-object "$1" | cut -c1-12); BUD=$((LIM - $(printf 'Ticket #%s, part 99 of 99, writing %s.\n\n' "$2" "$H" | wc -c) - 8))
  awk -v bud="$BUD" '{ L[NR] = length($0) + 1; if ($0 ~ /^## /) S[NR] = 1 }
    END { ns = 0; st[++ns] = 1; for (i = 2; i <= NR; i++) if (S[i]) st[++ns] = i; st[ns + 1] = NR + 1; from = 1; size = 0
      for (k = 1; k <= ns; k++) { a = st[k]; b = st[k + 1] - 1; z = 0; for (i = a; i <= b; i++) z += L[i]
        if (size + z <= bud) { size += z; continue } if (size > 0) { print from "\t" a - 1; from = a; size = 0 } if (z <= bud) { size = z; continue }
        for (i = a; i <= b; i++) { if (L[i] > bud) { print "LINE\t" i; exit 1 } if (size + L[i] > bud) { print from "\t" i - 1; from = i; size = 0 } size += L[i] } }
      if (NR >= from) print from "\t" NR }' "$1" > "$3/ranges" || { echo "item: line $(sed -n 's/^LINE.//p' "$3/ranges") is longer than a part of 60,000 bytes can hold" >&2; return 1; }
  NP=$(grep -c . "$3/ranges"); k=0
  while IFS='	' read -r a b; do k=$((k + 1)); o=$3/part-$k.md; { printf 'Ticket #%s, part %s of %s, writing %s.\n\n' "$2" "$k" "$NP" "$H"; sed -n "${a},${b}p" "$1"; } > "$o"
    [ "$(wc -c < "$o")" -le "$LIM" ] || { echo "item: part $k is over 60,000 bytes" >&2; return 1; }; printf '%s\n' "$o"; done < "$3/ranges"; }
# the open tickets' rows; listed <key>: every value a published or amended line gives the key; unruled: each ruling (a
# handed reached line, by its line) no ticket has listed, `<line>\t<row>`; pendreach: REACH and RUL, those rulings'
# rows in no open ticket and the rulings
# v0.26.10.25.5 (R4): pubt <n>, ticket n's first publication; stl <n>, the ids landed after it (.vid/decide/landed), never in it;
# lnew <step>, the step's landed rows no ticket published since their landing holds, known limits apart
# by the log's order, a landing's `landed … ids=` line (checks/land.sh) against each ticket's `published` line, never by the second
stl() { awk -v n="$1" '$1 == "published" && $2 == n { p = 1; next } p && $1 == "landed" { for (i = 2; i <= NF; i++) if ($i ~ /^ids=/) { m = split(substr($i, 5), a, ","); for (j = 1; j <= m; j++) print a[j] } }' "$T/lg" | sort -u; }
lnew() { srows "$1" > "$T/lr"; [ -s "$T/lr" ] || return 0
  awk -v LR="$T/lr" 'BEGIN { while ((getline l < LR) > 0) W[l] = 1 }
    $1 == "landed" { for (i = 2; i <= NF; i++) if ($i ~ /^ids=/) { m = split(substr($i, 5), a, ","); for (j = 1; j <= m; j++) if (a[j] in W) { L[a[j]] = 1; delete G[a[j]] } } }
    $1 == "published" { for (i = 3; i <= NF; i++) if ($i ~ /^rows=/) { m = split(substr($i, 6), a, ","); for (j = 1; j <= m; j++) if (a[j] in L) G[a[j]] = 1 } }
    END { for (r in L) if (!(r in G)) print r }' "$(lgof "$1")" | while read -r r; do lim "$r" || echo "$r"; done | sort; }
openrows() { for n in $(opn); do stl "$n" > "$T/sl.$n"; fld "$(tk "$n")" rows | tr , '\n' | grep -vxF -f "$T/sl.$n" || true; done | grep -v '^-*$' | sort -u; }
# 0.26.10.29.2 (R4): listed reads the closed-outside log, so a fix line or a ruling a ticket closed outside carried is owed a new ticket,
# whatever its kind and stage; its rows accepted on that ticket's unmerged pull request go out too (known limits left out, lim)
listed() { awk "$KV"' $1 == "published" || $1 == "amended" { print kv(k) }' k="$1" "$T/lgc" | tr , '\n' | grep -v '^-*$' | sort -u; }
unruled() { listed rulings > "$T/lu"; awk -F'\t' -v LU="$T/lu" 'BEGIN { while ((getline l < LU) > 0) D[l] = 1 } $1 == "reached" && !($4 in D) { print $4 "\t" $2 }' "$T/st"; }
pendreach() { openrows > "$T/or"; unruled | awk -F'\t' -v OR="$T/or" 'BEGIN { while ((getline l < OR) > 0) O[l] = 1 } !($2 in O)' > "$T/pr"
  REACH=$(cut -f2 "$T/pr" | awk '!s[$0]++' | paste -sd ' ' -); RUL=$(cut -f1 "$T/pr" | paste -sd ' ' -); }
stepof() { awk -F'\t' -v r="$1" '{ n = split($5, a, " "); for (i = 1; i <= n; i++) if (a[i] == r) { print $1; exit } }' "$T/steps"; }
# sopen <step>: an open ticket of the step; fup <step> [<n>]: the step's newest step or skeleton ticket published (before
# ticket n) and not withdrawn, by the step's log — the ticket a new step ticket follows, or nothing (0.26.10.28.10, R1)
sopen() { for _n in $(opn); do [ "$(fld "$(tk "$_n")" step)" = "$1" ] && ! mgd "$_n" && return 0; done; return 1; }
# mgd <n>: ticket n's pull request merged, as ViD recorded it (merges, merged-prs) or the round's read says, so a sync not yet taken
# keeps no merged ticket open (the close's owed asks due before next syncs)
mgd() { awk -F'\t' -v n="$1" -v M=.vid/decide/merged-prs 'BEGIN { while ((getline l < M) > 0) m[l] = 1 } $2 == n && ($1 in m) { f = 1 } END { exit !f }' .vid/decide/merges 2>/dev/null && return 0
  awk -F'\t' -v n="$1" '$1 == "merged" && $3 == n { f = 1 } END { exit !f }' .vid/round/read 2>/dev/null; }
fup() { awk "$KV"' $1 == "published" && $2 == n { exit } $1 == "published" && kv("step") == s && kv("kind") ~ /^(step|skeleton)$/ { P[$2] = 1 }
    $1 == "withdrawn" { delete P[$2] } END { m = ""; for (x in P) if (m == "" || x + 0 > m + 0) m = x; print m }' s="$1" n="${2:-}" "$(lgof "$1")"; }
# ffst <step>: the step's first step or skeleton ticket not withdrawn, the one its grade was at (0.26.10.28.10)
ffst() { awk "$KV"' $1 == "published" && kv("step") == s && kv("kind") ~ /^(step|skeleton)$/ { P[$2] = 1 } $1 == "withdrawn" { delete P[$2] }
    END { m = ""; for (x in P) if (m == "" || x + 0 < m + 0) m = x; print m }' s="$1" "$(lgof "$1")"; }
# newset <kind> <arg>: a new ticket's K, S, $T/ids, NUM, BASE (the newest sync's main), WHY, FIXL, REACH, RUL, FU
newset() {
  NUM=pending; AMW=''; WHY=''; FIXL=''; FU=''; BASE=$(awk "$KV"' $1 == "sync" { v = kv("main") } END { print v }' "$T/lg"); pendreach
  case "$1" in
    skeleton) K=skeleton; S=$(awk -F'\t' '$6 == "skeleton" { print $1; exit }' "$T/steps"); [ -n "$S" ] || ref 'the plan has no skeleton step'; srows "$S" > "$T/ids"; REACH=''; RUL='' ;;
    step) K=step; S=$2; awk -F'\t' -v s="$S" '$1 == s { f = 1 } END { exit !f }' "$T/steps" || ref "${S:-(none)} is no step of the recorded plan"
      lnew "$S" > "$T/ln"; SO=$(for n in $(opn); do [ "$(fld "$(tk "$n")" step)" != "$S" ] || echo "$n"; done)
      [ "$(awk -F'\t' -v s="$S" '$1 == s { print $6 }' "$T/steps")" != skeleton ] || [ -s "$T/ln" ] || ref "$S is the skeleton: write skeleton"
      if [ -s "$T/ln" ] && { [ -n "$SO" ] || [ "$(awk -F'\t' -v s="$S" '$1 == s { print $6 }' "$T/steps")" = skeleton ]; }; then cp "$T/ln" "$T/ids"   # R4: its own ticket, beside the open one
      else openrows > "$T/or"; srows "$S" | while IFS= read -r r; do lim "$r" || grep -qxF "$r" "$T/or" || [ "$(sentin "$r" "$S")" = "$(rhash "$r")" ] || echo "$r"; done > "$T/ids"; fi
      [ -s "$T/ids" ] || ref "$S has no row to send: each is a known limit, in an open ticket, or sent unchanged"; FU=$(fup "$S") ;;
    fix) K=fix; R=${2:-}; isrow() { awk -F'\t' -v r="$1" '$1 == r && $2 == "row" { f = 1 } END { exit !f }' "$T/rows"; }
      case $R in *[!0-9]*|'') isrow "$R" || ref "${R:-(none)} is no row of the inventory"; ! lim "$R" || ref "$R is a known limit, a later-phase row or a record: it gets no fix ticket" ;; esac
      openrows > "$T/or"; listed fix > "$T/lf"; FL=$(awk -F'\t' -v a="$R" -v LF="$T/lf" 'BEGIN { while ((getline l < LF) > 0) D[l] = 1 } $1 == "fix" && !($2 in D) && ($2 == a || index("," $3 ",", "," a ",")) { print $2 "\t" $3 "\t" $4 "\t" $5; exit }' "$T/st")
      [ -n "$FL" ] || ref "no fix ask for $R waits in .vid/tw/handed"; IFS='	' read -r FIXL RS WHY LK <<EOF
$FL
EOF
      for r in $(printf '%s' "$RS" | tr , ' '); do isrow "$r" || ref "$r is no row of the inventory"; lim "$r" && continue; ! grep -qxF "$r" "$T/or" || ref "$r is in an open ticket: FX fixes it in that pull request"; echo "$r"; done > "$T/ids"
      [ -s "$T/ids" ] || ref "every row of the fix ask $FIXL is a known limit: it owes nothing"
      S=$(printf '%s' "$LK" | sed -n 's/.*close #[0-9]* of \([^ :,]*\).*/\1/p'); [ -n "$S" ] || S=$(stepof "$(head -n 1 "$T/ids")") ;;
    reached) K=reached; [ -n "$REACH" ] || ref 'no row a ruling reached waits'; printf '%s\n' $REACH > "$T/ids"; S=$(stepof "$(head -n 1 "$T/ids")") ;;
    *) die 'usage — sh checks/writer.sh write skeleton | step <S> | fix <key|row> | reached | amend <n>' ;;
  esac
  [ -n "$S" ] && started "$S" || ref "step ${S:-(none)} was never admitted (no step-start event): sh checks/plan.sh start ${S:-<step>}"; }
# amendset <n>: open ticket n written again — its kind, step, base and number; a step's rows as the plan now holds them
# (its rows still in the step, and the step's rows no ticket of it has held); the reached rows and rulings it lists, and
# those of its rows an unlisted ruling reached; AMW names each plan change after its last writing's plan that changed
# its step's rows, else the export
amendset() {
  L=$(tk "$1"); [ -n "$L" ] || ref "#$1 is no ticket TW published"; opn | grep -qx "$1" || ref "#$1 is not open: a merged or closed ticket is never changed"
  NUM=$1; K=$(fld "$L" kind); S=$(fld "$L" step); BASE=$(fld "$L" base); FIXL=$(fld "$L" fix); [ "$FIXL" != - ] || FIXL=''; LD=''
  FU=''; [ "$K" != step ] || FU=$(fup "$S" "$1")
  [ "$BASE" != none ] || { _b=$(awk "$KV"' $1 == "sync" { v = kv("main") } END { print v }' "$T/lg"); case $_b in ''|*[!0-9a-f]*) ;; *) BASE=$_b ;; esac; }   # v0.26.10.28.2 (R3): main started since
  stl "$1" > "$T/st1"; fld "$L" rows | tr , '\n' | grep -vxF -f "$T/st1" > "$T/ids0" || true   # R4: a landed id leaves a ticket published before its landing
  if [ "$K" = step ] || [ "$K" = skeleton ]; then srows "$S" > "$T/sr"; rowsof "$S" > "$T/all"
    { grep -xF -f "$T/sr" "$T/ids0" || true; grep -vxF -f "$T/all" "$T/sr" | grep -vxF -f "$T/st1" | while IFS= read -r r; do lim "$r" || echo "$r"; done; } > "$T/keep"
    grep -xF -f "$T/keep" "$T/sr" > "$T/ids" || true
  else # 0.26.10.29.2 (R11): a fix or reached ticket drops the rows a plan change moved out of the step that held them at its last
    # writing (or into no step), amended and told; the step that now holds them owes them, with R3's `- earlier work:` line
    if [ -f ".vid/plans/$(fld "$L" plan).plan" ]; then awk "$TR$SP" ".vid/plans/$(fld "$L" plan).plan" > "$T/steps0"
      while IFS= read -r r; do [ "$(awk -F'\t' -v r="$r" '{ n = split($5, a, " "); for (i = 1; i <= n; i++) if (a[i] == r) { print $1; exit } }' "$T/steps0")" = "$(stepof "$r")" ] && echo "$r"; done < "$T/ids0" > "$T/ids1" || true; cat "$T/ids1" > "$T/ids0"; fi
    while IFS= read -r r; do lim "$r" || echo "$r"; done < "$T/ids0" > "$T/ids"   # 0.26.10.28.6 (R2): a fix ticket drops its rows ruled known limits
    [ -s "$T/ids" ] || [ ! -s "$T/ids0" ] || { echo "ViD writer: refused — every row of #$1 is a known limit: it is withdrawn while no pull request names it (sh checks/github.sh tw-close $1), and merges as it is once one does" >&2; exit 4; }
    LD=$(grep -vxF -f "$T/ids" "$T/ids0" | paste -sd ' ' -); fi   # the rows dropped, named in the amendment
  [ -s "$T/ids" ] || { echo "ViD writer: refused — #$1 would hold no row: withdraw it (sh checks/github.sh tw-close $1)" >&2; exit 3; }
  unruled | awk -F'\t' -v I="$T/ids" 'BEGIN { while ((getline l < I) > 0) W[l] = 1 } ($2 in W)' > "$T/ur"
  REACH=$( { fld "$L" reached | tr , '\n'; cut -f2 "$T/ur"; } | grep -v '^-*$' | awk '!s[$0]++' | paste -sd ' ' -); RUL=$( { fld "$L" rulings | tr , '\n'; cut -f1 "$T/ur"; } | grep -v '^-*$' | paste -sd ' ' -)
  WHY=''; [ -z "$FIXL" ] || WHY=$(awk -F'\t' -v k="$FIXL" '$1 == "fix" && $2 == k { print $4 }' "$T/st")
  AMW=$(chgs "$1" "$S" | awk -F'\t' '{ printf "%s%s, what %s", (c++ ? "; " : ""), $1, $2 }')
  awk '/^## / { on = ($0 == "## Laws"); next } on' ".vid/tw/out/issue-$1.md" > "$T/ol" 2>/dev/null || :; { echo; laws; echo; } | awk "$A1"' /^>/ { $0 = unptr($0) } { print }' > "$T/nl"   # the laws alone, as written
  # GM-2 T5: in GitHub manual the cause is the move's own, never read from the plan= hash a taken-over ticket brings
  if manual; then AMW=${AMC:-the owner\'s amendment}; [ -n "${NOTELL:-}" ] || mtells "$1" "$L"; return 0; fi
  if [ -n "$AMW" ]; then AMW="by plan change $AMW"; elif [ -n "$LD" ]; then AMW="as its rows $LD were ruled known limits or taken out of the plan"; elif [ "$(fld "$L" export)" = "$EXP" ] && [ -s "$T/ol" ] && ! cmp -s "$T/ol" "$T/nl"; then AMW="at the spec export $EXP, the laws it quotes changed"
  else AMW="at the spec export $EXP, the text it quotes changed"; fi; tells "$1" "$L"; }
# GM-2 T5, T6: mtells <n> <its log line>, GitHub manual's `tell` lines into $T/tell: each test added, restated or taken out since its
# last writing. The hash a row was sent at is the log's; a ticket taken over with none has them rebuilt (next.sh differ against the
# applied commit: a quote that matches reads as sent at the applied line's hash, one that differs as restated). A test taken out is
# named as taken out at the owner's word, and where it went: a step (its open ticket), the to-place list, or out of the plan
mtells() { : > "$T/tell"; fld "$2" rows | tr , '\n' | grep -v '^-*$' > "$T/p0" || true
  awk -v n="$1" '$1 == "sent" && $3 == "ticket=" n { h = $4; sub(/^hash=/, "", h); H[$2] = h } END { for (r in H) print r " " H[r] }' "$T/lg" > "$T/sh"
  if [ ! -s "$T/sh" ]; then sh "$HERE/next.sh" differ "$1" "$AT" > "$T/dif" 2>/dev/null || :
    while IFS= read -r r; do awk -F'\t' -v r="$r" '$3 == r { f = 1 } END { exit !f }' "$T/dif" || echo "$r $(rhash "$r")"; done < "$T/p0" > "$T/sh"; fi
  pm() { awk -F'\t' -v r="$1" '$1 == r { print $8; exit }' "$T/rows"; }
  went() { _s=$(stepof "$1"); if [ -n "$_s" ]; then _m=''; for _x in $(opn); do [ "$_x" != "$2" ] && [ "$(fld "$(tk "$_x")" step)" = "$_s" ] && _m=$_x; done
      if [ -n "$_m" ]; then echo "step $_s, ticket #$_m"; else echo "step $_s, not yet published"; fi
    elif awk -F'\t' -v r="$1" '$1 == r { f = 1 } END { exit !f }' .vid/tw/to-place 2>/dev/null; then echo 'the to-place list'; else echo 'out of the plan'; fi; }
  { grep -vxF -f "$T/p0" "$T/ids" | while IFS= read -r r; do printf -- '- added: %s (%s)\n' "$r" "$(pm "$r")"; done
    grep -xF -f "$T/p0" "$T/ids" | while IFS= read -r r; do h=$(awk -v r="$r" '$1 == r { print $2 }' "$T/sh"); [ "$h" = "$(rhash "$r")" ] || printf -- '- restated: %s (%s)\n' "$r" "$(pm "$r")"; done
    grep -vxF -f "$T/ids" "$T/p0" | while IFS= read -r r; do printf -- '- taken out: %s (%s), at the owner'"'"'s word; it went to %s\n' "$r" "$(pm "$r")" "$(went "$r" "$1")"; done; } > "$T/tell" || true; }
# 0.26.10.29.2 (R11): tells <n> <its log line>, the amendment's comment lines into $T/tell, which ticket writes into the meta as `tell` lines
# and github.sh tw-post posts: its cause (each plan change, its what and why; else the rows ruled known limits, a landing, a ruling, or
# the export), then each row added, removed or changed since its last writing, by id and promise, one a line
tells() { : > "$T/tell"; fld "$2" rows | tr , '\n' | grep -v '^-*$' > "$T/p0" || true; chgs "$1" "$S" > "$T/cg"
  while IFS='	' read -r d w; do y=$(grep "^plan-change .* decision=$d " .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/.* why="\(.*\)" at=[^ ]*$/\1/p'); echo "Cause: plan change $d, what $w${y:+: $y}."; done < "$T/cg" > "$T/tell"   # the first lines of $T/tell
  [ -z "$LD" ] || echo "Cause: its rows $LD were ruled known limits or taken out of the plan." >> "$T/tell"
  x=$(grep -xF -f "$T/p0" "$T/st1" 2>/dev/null | paste -sd ' ' -); [ -z "$x" ] || echo "Cause: a landing changed $x, which go out in a ticket of their own." >> "$T/tell"
  x=$(for r in $REACH; do fld "$2" reached | tr , '\n' | grep -qxF "$r" || echo "$r"; done | paste -sd ' ' -); [ -z "$x" ] || echo "Cause: a ruling reached $x." >> "$T/tell"
  [ -s "$T/tell" ] || echo "Cause: the export ${EXP:-none}: the text it quotes changed." >> "$T/tell"
  pm() { awk -F'\t' -v r="$1" '$1 == r { print $8; exit }' "$T/rows"; }
  { grep -vxF -f "$T/p0" "$T/ids" | while IFS= read -r r; do printf -- '- added: %s (%s)\n' "$r" "$(pm "$r")"; done
    grep -vxF -f "$T/ids" "$T/p0" | while IFS= read -r r; do printf -- '- removed: %s (%s)\n' "$r" "$(pm "$r")"; done
    grep -xF -f "$T/p0" "$T/ids" | while IFS= read -r r; do h=$(awk -v r="$r" -v n="$1" '$1 == "sent" && $2 == r && $3 == "ticket=" n { v = $4 } END { sub(/^hash=/, "", v); print v }' "$T/lg")
      [ "$h" = "$(rhash "$r")" ] || printf -- '- changed: %s (%s)\n' "$r" "$(pm "$r")"; done; } > "$T/tr"
  if [ -s "$T/tr" ]; then { echo; cat "$T/tr"; } >> "$T/tell"; else printf '\nNo row was added, removed or changed.\n' >> "$T/tell"; fi; }
# chgs <n> <step>: each plan change recorded after the plan ticket n was last written for that changed the step's rows
# (against the plan before it), `<decision>\t<what>`
chgs() { awk -v lp="$(fld "$(tk "$1")" plan)" '$1 == "plan-change" { h = $3; sub(/^hash=/, "", h); if (on) B[++k] = p "\t" h "\t" $4 "\t" $2; if (h == lp) { on = 1; k = 0 } p = h }
    END { for (i = 1; i <= k; i++) print B[i] }' .vid/metrics-events |
    while IFS='	' read -r p h d w; do x=$(awk "$TR$SP" ".vid/plans/$p.plan" 2>/dev/null | awk -F'\t' -v s="$2" '$1 == s { print $5 }'); y=$(awk "$TR$SP" ".vid/plans/$h.plan" | awk -F'\t' -v s="$2" '$1 == s { print $5 }')
      [ "$x" = "$y" ] || printf '%s\t%s\n' "${d#decision=}" "${w#what=}"; done; }
# wd <n> <step>: `withdraw <n>`, with the newest change that changed the step's rows (decision= what=)
wd() { c=$(chgs "$1" "$2" | tail -n 1); echo "withdraw $1${c:+ decision=${c%%	*} what=${c#*	}}"; }
# prn <n> (0.26.10.28.6, R2): a pull request names ticket n, open or merged — in the round's read (github.sh round-read, kept
# by round.sh at .vid/round/read before each step and next), or in the merges ViD recorded; with no read yet, one is taken to
prn() { [ -f .vid/round/read ] || return 0; awk -F'\t' -v n="$1" '($1 == "open" || $1 == "merged") && $3 == n { f = 1 } END { exit !f }' .vid/round/read && return 0
  cat .vid/decide/merges .vid/decide/merged-tickets 2>/dev/null | awk -F'\t' -v n="$1" '(NF >= 4 && $2 == n) || (NF == 2 && $1 == n) { f = 1 } END { exit !f }'; }
# due: what the round owes (R7, R9); R2 (0.26.10.28.6): a fix ticket whose every row is a known limit, with no pull request
# naming it, `withdraw <n> limits=<rows>`; with one, nothing, so it merges
due() {
  EXP=$(awk '$1 == "export" { v = $2 } END { print v }' "$T/lg"); : > "$T/due"; : > "$T/ho"
  for n in $(opn); do L=$(tk "$n"); k=$(fld "$L" kind); s=$(fld "$L" step)
    if { [ "$k" = step ] || [ "$k" = skeleton ]; } && ! awk -F'\t' -v s="$s" '$1 == s { f = 1 } END { exit !f }' "$T/steps"; then wd "$n" "$s"; continue; fi
    rc=0; if manual; then ( NOTELL=1; amendset "$n" ) > /dev/null 2>&1 || rc=$?; else ( amendset "$n"; ticket "$T/re.md" ) > /dev/null 2>&1 || rc=$?; fi
    # 0.26.10.29.2 (R11): with a pull request naming it, the known-limit fix ticket is told once (`tell <n> limits=`, github.sh tw-tell), not withdrawn
    if [ "$rc" = 4 ]; then x=$(paste -sd , "$T/ids0"); if prn "$n"; then grep -qx "told $n limits=$x at=.*" "$T/lg" || echo "tell $n limits=$x"; else echo "withdraw $n limits=$x"; fi
    elif [ "$rc" = 3 ]; then wd "$n" "$s"
    # GM-2 T5, T6: in GitHub manual an amendment is owed only when the plan's rows differ from the log line's; never a withdrawal for size
    elif manual; then if [ "$rc" = 0 ] && [ "$(sort -u "$T/ids")" != "$(fld "$L" rows | tr , '\n' | grep -v '^-*$' | sort -u)" ]; then
        if fld "$L" rows | tr , '\n' | grep -v '^-*$' | grep -qvxF -f "$T/ids"; then echo "2 amend $n"; printf '%s\ta\t%s\n' "$n" "$(fld "$L" rows | tr , '\n' | grep -v '^-*$' | grep -vxF -f "$T/ids" | paste -sd , -)" >> "$T/ho"; else echo "3 amend $n"; fi; fi
    # 0.26.10.29.2 (R11): a step or skeleton ticket that lost more than half of the rows it held at its last writing is withdrawn, not
    # amended, its step kept (`kept=`): its kept rows go out in a new ticket that names it (R3's `- earlier work:`)
    elif [ "$rc" = 0 ] && { [ "$k" = step ] || [ "$k" = skeleton ]; } && [ "$(fld "$L" rows | tr , '\n' | grep -v '^-*$' | grep -cvxF -f "$T/ids")" -gt "$(($(fld "$L" rows | tr , '\n' | grep -c .) / 2))" ]; then echo "$(wd "$n" "$s") kept=$s"
    elif [ "$rc" != 0 ] || [ "$(fld "$(sed -n 1p "$T/re.meta")" qhash)" != "$(fld "$L" qhash)" ] || [ "$(fld "$(sed -n 1p "$T/re.meta")" rows)" != "$(fld "$L" rows)" ]; then if [ "$rc" = 0 ] && fld "$L" rows | tr , '\n' | grep -v '^-*$' | grep -qvxF -f "$T/ids"; then echo "2 amend $n"; printf '%s\ta\t%s\n' "$n" "$(fld "$L" rows | tr , '\n' | grep -v '^-*$' | grep -vxF -f "$T/ids" | paste -sd , -)" >> "$T/ho"; else echo "3 amend $n"; fi; fi
  done > "$T/dt"   # 0.26.10.29.2 (R3): withdrawals, then the amendments of tickets losing rows, then the rest, so each loser's handover is logged before any ticket receiving its rows is written
  { grep -v '^[23] ' "$T/dt"; sed -n 's/^2 //p' "$T/dt"; sed -n 's/^3 //p' "$T/dt"; } || true
  # 0.26.10.29.2 (R3): $T/ho, the handovers these lines will make, `<n> TAB w|a TAB <rows>` (a withdrawal's every row, an
  # amendment's lost rows), for `handovers`: github.sh tw-handovers logs them before any ticket is written, so their order never matters
  { grep '^withdraw ' "$T/dt" || true; } | grep -v ' limits=' | while read -r _w n _x; do printf '%s\tw\t%s\n' "$n" "$(fld "$(tk "$n")" rows)" >> "$T/ho"; done
  awk -F'\t' '{ print $1 "\t" $6 }' "$T/steps" | while IFS='	' read -r s kd; do started "$s" || continue
    if ! awk "$KV"' $1 == "published" && kv("step") == s && kv("kind") ~ /^(step|skeleton)$/ { f = 1 } END { exit !f }' s="$s" "$(lgof "$s")"; then
      if [ "$kd" = skeleton ]; then echo 'new skeleton'; else echo "new step $s"; fi
    elif [ -n "$(lnew "$s")" ]; then sopen "$s" || echo "new step $s"   # R1 (0.26.10.28.10): never beside an open ticket of the step
    elif [ "$kd" != skeleton ] && ! for n in $(opn); do [ "$(fld "$(tk "$n")" step)" = "$s" ] && echo y; done | grep -q y; then
      srows "$s" | while IFS= read -r r; do lim "$r" || [ "$(sentin "$r" "$s")" = "$(rhash "$r")" ] || { echo "new step $s"; break; }; done; fi
  done > "$T/due"
  listed fix > "$T/lf"; awk -F'\t' -v LF="$T/lf" 'BEGIN { while ((getline l < LF) > 0) D[l] = 1 } $1 == "fix" && !($2 in D) && !s[$2]++ { print $2 "\t" $3 }' "$T/st" | while IFS='	' read -r k rs; do
    for r in $(printf '%s' "$rs" | tr , ' '); do lim "$r" || { echo "new fix $k"; break; }; done; done >> "$T/due"
  cat "$T/due"; grep -q '^new ' "$T/due" || { pendreach; [ -z "$REACH" ]; } || echo 'new reached'; }
# fresh <file> [<n>] (fix 2): one line per thing that moved since the file was written — the plan's recorded hash, the
# newest export, and its ticket work (new, or the amendment of #n), which due must owe now — so no stale file is posted
fresh() {
  M=$(sed -n 1p "${1%.md}.meta"); NB=$(sed -n 's/^- number: //p' "$1" | head -n 1); EXP=$(awk '$1 == "export" { v = $2 } END { print v }' "$T/lg")
  [ "$(fld "$M" plan)" = "$PH" ] || echo "the plan moved: $1 was written for the plan $(fld "$M" plan); the recorded plan is now $PH"
  [ "$(fld "$M" export)" = "$EXP" ] || echo "the export moved: $1 was written at the export $(fld "$M" export); the newest is ${EXP:-none}"
  case $(fld "$M" kind) in skeleton) w='new skeleton' ;; step) w="new step $(fld "$M" step)" ;; fix) w="new fix $(fld "$M" fix)" ;; *) w='new reached' ;; esac
  [ "$(fld "$M" kind)" != fix ] || for r in $(fld "$M" rows | tr , ' '); do ! lim "$r" || echo "the fix rows moved: $r is now a known limit, and $1 still holds it"; done
  if [ "$NB" != pending ]; then w="amend $NB"; [ "$2" = "$NB" ] || echo "the ticket work moved: $1 was written as the amendment of #$NB, not posted as one"
  elif [ -n "$2" ]; then echo "the ticket work moved: $1 was written as a new ticket, not the amendment of #$2"; fi
  ( due ) > "$T/dn" 2>&1 || true; grep -qxF "$w" "$T/dn" || echo "the ticket work moved: $1 was written for '$w', which the round no longer owes (due: $(paste -sd ';' "$T/dn" | sed 's/^$/nothing/'))"; }

CMD=${1:-}; [ $# -gt 0 ] && shift
case "$CMD" in
  gate) if gate; then echo "writer: gate open — the plan ratified, the owner's go, $R, $S, open-tickets: ${L:-no limit}"; else sed 's/^/writer: gate — /' "$T/why"; exit 1; fi ;;
  write)
    gate || { sed 's/^/ViD writer: refused — the gate: /' "$T/why" >&2; exit 1; }
    load; EXP=$(awk '$1 == "export" { v = $2 } END { print v }' "$T/lg"); [ -n "$EXP" ] || ref 'no export yet — sh checks/github.sh spec-export first'
    if [ "${1:-}" = amend ]; then AMC=''; if manual && [ "${3:-}" = --cause ]; then AMC=$(printf '%s' "${4:-}" | tr '\t\n' '  '); [ -n "$AMC" ] || die 'write amend <n> --cause takes a line'; fi   # GM-2 T5
      amendset "${2:-}"; F=$OUT/amend-$2.md; else newset "${1:-}" "${2:-}"; F=$OUT/$K-${2:-$S}.md; fi
    [ "$K" = skeleton ] || [ -n "$(sv eng)" ] || ref "no engines line in .vid/tw/handed: the skeleton's head report declares them first"
    # v0.26.10.28.2 (R3): a base is a commit; none, an empty code repository, the skeleton's alone: DevAgent starts main
    case $BASE in none) [ "$K" = skeleton ] || ref "no base: the code repository is empty, and only the skeleton starts main" ;; ''|*[!0-9a-f]*) ref "no base: the code repository's main is not known${BASE:+ ($BASE)} (sh checks/github.sh tw-sync first)" ;; esac
    ticket "$F"; echo "$F"; check "$F"; if [ -s "$T/ref" ]; then sed 's/^/ViD writer: check refused — /' "$T/ref" >&2; exit 1; fi ;;
  check) [ -f "${1:-}" ] || die 'usage — sh checks/writer.sh check <file>'; check "$1"
    if [ -s "$T/ref" ]; then sed 's/^/writer: check refused — /' "$T/ref"; exit 1; fi; echo "writer: check passed — $1" ;;
  parts) [ -f "${1:-}" ] && [ -n "${2:-}" ] && [ -n "${3:-}" ] || die 'usage — sh checks/writer.sh parts <file> <issue> <dir>'; parts_ "$1" "$2" "$3" ;;
  due) load; due ;;
  topup) for _v in "${1:-x}" "${2:-x}"; do case $_v in *[!0-9]*) die 'usage — sh checks/writer.sh topup <added> <tests>' ;; esac; done   # GM-2 T6: the size flag, one rule
    if [ "$1" -gt 5 ]; then echo "$1 added, more than 5"; elif [ $(($1 * 5)) -gt "$2" ]; then echo "$1 added to $2, more than a fifth"; fi ;;
  where) load; where_ "${1:-}" ;;   # 0.26.10.29.2 (R3, R11)
  handovers) load; due > /dev/null; cat "$T/ho" ;;   # 0.26.10.29.2 (R3)
  cause) load; EXP=$(awk '$1 == "export" { v = $2 } END { print v }' "$T/lg"); : > "$T/tell"; ( amendset "${1:-}" ) > /dev/null 2>&1 || true; grep '^Cause: ' "$T/tell" || true ;;   # 0.26.10.29.2 (R11): an amendment's causes, for a withdrawal no plan change made
  name) load; NS=${1:-}; NI=${2:-}; [ -n "$NS" ] && [ -n "$NI" ] || die 'usage — sh checks/writer.sh name <step> <D-id,…>'   # 0.26.10.29.5 (DP-1 R5)
    awk -F'\t' -v s="$NS" '$1 == s { f = 1 } END { exit !f }' "$T/steps" || ref "$NS is no step of the recorded plan $PH"
    NL=''; for d in $(printf '%s\n' "$NI" | tr ', ' '\n\n' | grep -v '^$' || true); do case $d in D-*[!0-9]*|D-) ref "unknown decision id: $d (not in DECISIONS.md at $AN)" ;; D-*) ;; *) ref "unknown decision id: $d (not in DECISIONS.md at $AN)" ;; esac; awk -v d="- **$d**" 'index($0, d) == 1 { f = 1 } END { exit !f }' "$T/dec" || ref "unknown decision id: $d (not in DECISIONS.md at $AN)"; NL="$NL${NL:+,}$d"; done
    [ -n "$NL" ] || die 'usage — sh checks/writer.sh name <step> <D-id,…>'; printf '%s %s\n' "$NS" "$NL" >> .vid/tw/named; echo "writer: named $NL for $NS" ;;
  pending) load; pendreach; for r in $REACH; do printf '%s %s\n' "$r" "$(stepof "$r" | grep . || echo -)"; done ;;   # v0.26.10.26.7 (R9): the reached rows no ticket holds yet, `<row> <step>`
  fresh) [ -f "${1:-}" ] && [ -f "${1%.md}.meta" ] || die 'usage — sh checks/writer.sh fresh <file> [<n>]'; load; fresh "$1" "${2:-}" > "$T/fr"
    if [ -s "$T/fr" ]; then sed 's/^/writer: stale — /' "$T/fr"; exit 1; fi; echo "writer: fresh — $1" ;;
  *) die "unknown subcommand ${CMD:-(none)} — gate, write, check, parts, due, topup, pending, fresh, where, cause, handovers, name" ;;
esac
