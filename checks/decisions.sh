#!/bin/sh
# Purpose: ViD decision labels — the labelling pass (v0.9.7.3 spec 3.3, R3). A
# decision line carries a label after its enforced: field, `| applies-to: <ids
# and codes>` or `| scope: project` (checks/hooks/pre-commit 4c); a brief quotes
# it where its label applies (checks/brief.sh, R2). The pass labels the lines
# that have none, once: an agent proposes, and `apply` writes them — with no
# question to the owner: a label the agent is unsure
# of, or one no brief could join, is written `scope: project`, so the decision
# still reaches every builder brief as an unlabelled one does today.
#   propose [--all]   the unlabelled decisions of DECISIONS.md citing no ROW,
#                     REQ or RULE id (whole ids) — with --all, every unlabelled
#                     line (init's pass, before the initial commit) — each with
#                     its text hash (the line with any label field stripped,
#                     git hash-object, 12 hex), into a new brief
#                     .vid/briefs/labels-<n>.md for one general-purpose agent:
#                     the list, the items a label may name (INVENTORY.md's
#                     screen codes, rule rows, the REQ ids rows derive from,
#                     DIF ids, ARCHITECTURE.md's module ids — v0.26.10.2 R17c)
#                     and the return form, read access only, no edits.
#                     Prints `propose: <k> decisions → <brief>`; none, writes nothing.
#                     0.26.10.29.3 (R7): both forms also list every labelled line
#                     whose label the commit hook would refuse (checks/labels.sh, the
#                     hook's own join), so "no decision to label" is never printed
#                     while the hook would refuse one.
#   apply [<file>] [--no-commit]
#                     reads the proposals (default .vid/decision-labels.proposed,
#                     the agent's return saved unchanged, one line per decision:
#                     `D-NNN <hash> | applies-to: <items> | sure`, or `| scope:
#                     project |`, or `| unsure`) and writes each label after its
#                     line's enforced: field, only where the line's text hash
#                     still matches its proposal (a changed line is not labelled
#                     and is listed; a line gone or already labelled is skipped —
#                     0.26.10.29.3 (R7): but a label the hook would refuse is replaced,
#                     so a line never carries two).
#                     A module id is an item a brief joins on (R17c).
#                     Unsure, malformed, or naming an item no brief joins on: the
#                     label written is `scope: project` (widened). Keeps the
#                     record .vid/decision-labels.applied (`D-NNN<TAB><label
#                     written><TAB>sure|widened: <why>`). Then one commit of
#                     DECISIONS.md alone, in the project's commit template
#                     (refused when anything else is staged); --no-commit (init,
#                     step 7) writes without committing, the labels landing in
#                     the initial commit. Records `decision-labels applied=<a>
#                     widened=<w> changed=<c> skipped=<s>`.
#   next [--try <try>]
#                     v0.26.10.4 (R13, F-48): prints the next free `D-NNN` and
#                     reserves it in the home's .vid/decision-ids (`D-NNN<TAB>
#                     <try|manager><TAB><UTC>`), under the home's lock
#                     (.vid/decision-ids.lock). Free means above every D-number
#                     in the caller's HEAD, in the home's checked-out HEAD and
#                     in every reservation, so a caller whose branch lags the
#                     home can't pick one already used. The home is
#                     checks/plan.sh home-of's, else this checkout. A reserved
#                     number never used is a gap; no court reads D-numbers in
#                     order. Every writer of a new D-number takes it here.
#   section <file>    0.26.10.29.5 (DP-1 R8, R2): a pull request description's Decisions section, the one reader of it
#                     (decide.sh's decision and record): `none` for a line `Decisions: none` (words may follow, as in
#                     the commit template), `missing` with no section, else each `- ` line under the first `Decisions:`
#                     line, its `- ` dropped, to the first line that is neither one nor blank; every `- ` line is a
#                     decision. `none` is the line `Decisions: none` alone or followed by ` — <words>`. A `Decisions:` line
#                     with no `- ` line under it is no section.
#   record            0.26.10.29.5 (DP-1 R2), run by the round after the merges it records, in ticket mode: each pull request
#                     of .vid/decide/merges with no `decisions-recorded pr=<p>` event, its description read once
#                     (github.sh pr-body), and each deploy report the reader read and did not refuse, whatever its outcome
#                     (.vid/decide/stage/*/*/d1|rh|d2*/read), with no `decisions-recorded deploy=<id>` event, its report.txt
#                     read once from .vid/code; a deploy line whose words a dev-side deploy line holds already is left out
#                     (`n=0`, no commit, when all are). Each line
#                     appended as `- **D-NNN** <what> | why: <why, or not given> | enforced: ticket <n> | <label> | origin:
#                     dev-side` (a deploy's `enforced: deploy <id> | scope: project`), numbered by next, each `|` in the
#                     dev side's words written `/`; the label `scope: project` when the line ends `| scope: project`, else
#                     applies-to: the ticket's ROW and RULE ids and its step's modules (the writer's form: backticks
#                     stripped, dots as slashes), only those the label hook joins on at HEAD (labels.sh), and `scope:
#                     project` when none is left. One commit of DECISIONS.md alone a pull request or report, its
#                     Decisions: line naming the ids; then `decisions-recorded pr=<p> n=<k>` (`deploy=<id>`), and
#                     github.sh spec-export once after any commit. `n=none` for `Decisions: none`, `n=missing` for no
#                     section: nothing written, never read again. A commit the hooks refuse leaves DECISIONS.md as HEAD
#                     has it, records `n=refused`, never tried again, and prints `decisions refused pr=<p> <the hook's
#                     first line>`. While a draft of land.sh waits (not landed, declined or replaced) it reads and writes
#                     nothing and prints `decisions wait draft=<n>`. Prints `decisions recorded pr=<p> n=<k> <ids>` a commit;
#                     `decisions unread pr=<p>: <why>` for a description it could not read, or a commit it could not
#                     make clean (other changes staged, DECISIONS.md changed), with no event, so the next round tries
#                     again; `decisions export failed: <why>`. Exit 0 but for a usage error (2) or a refusal (1).
# Reads the working tree; writes only DECISIONS.md, the record (apply), the brief
# (propose), the reservations (next) and the event. Usage: sh checks/decisions.sh propose [--all] | apply [<file>] [--no-commit] | next [--try <try>] | section <file> | record
# serves: both (0.26.10.28.4, M9)
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); . "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R4): the lock, lib.sh beside this file
IFS='
'
usage() { echo "ViD decisions: usage — sh checks/decisions.sh propose [--all] | apply [<file>] [--no-commit] | next [--try <try>] | section <file> | record" >&2; exit 2; }
refuse() { echo "ViD decisions: refused — $*" >&2; exit 1; }
[ $# -ge 1 ] || usage
CMD=$1; shift
# --- v0.26.10.4 (R13): next — a D-number reserved at the home --------------------------------------------------
if [ "$CMD" = next ]; then
  NTRY=manager
  case "${1:-}" in --try) [ -n "${2:-}" ] || usage; NTRY=$2 ;; '') ;; *) usage ;; esac
  case "$NTRY" in *[!A-Za-z0-9._:-]*) refuse "--try takes an attempt id: letters, digits, '.', '_', ':' and '-'" ;; esac
  NH=''; [ -f checks/plan.sh ] && NH=$(sh checks/plan.sh home-of 2>/dev/null | head -n 1) || true
  [ -n "$NH" ] && [ -d "$NH/.vid" ] || NH=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  mkdir -p "$NH/.vid"
  # 0.26.10.28.4 (9.3 R4): lib.sh's lock, which names its holder, so a dead holder's lock is taken over and needs no person
  NL="$NH/.vid/decision-ids.lock"; lock_take "$NL" 30 || refuse "the home's lock $NL is held by a live process for 30 s — another reservation is under way"
  trap 'lock_free "$NL"' EXIT
  dnum() { awk '{ s = $0; while (match(s, /D-[0-9]+/)) { x = (RSTART > 1) ? substr(s, RSTART - 1, 1) : ""; if (x !~ /[A-Za-z0-9_-]/) { v = substr(s, RSTART + 2, RLENGTH - 2) + 0; if (v > m) m = v } s = substr(s, RSTART + RLENGTH) } } END { print m + 0 }'; }
  M1=$(git show HEAD:DECISIONS.md 2>/dev/null | dnum)
  M2=$(git -C "$NH" show HEAD:DECISIONS.md 2>/dev/null | dnum)
  M3=$(cut -f1 "$NH/.vid/decision-ids" 2>/dev/null | dnum)
  N=$(printf '%s\n%s\n%s\n' "$M1" "$M2" "$M3" | sort -n | tail -n 1); N=$((N + 1))
  ID=$(printf 'D-%03d' "$N")
  printf '%s\t%s\t%s\n' "$ID" "$NTRY" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$NH/.vid/decision-ids"
  echo "$ID"
  exit 0
fi
# --- 0.26.10.29.5 (DP-1 R8, R2): section — a pull request description's Decisions section, read one way ----------------
# none: the line `Decisions: none` exactly, or followed by ` — ` and words (the commit template's form); every `- ` line is a decision
# but a `- none` line itself, which marks nothing and must hide no decision under it
sect() { awk 'function isnone(x) { return x == "none" || index(x, "none — ") == 1 }
    function fin(   i) { if (n) for (i = 1; i <= n; i++) print L[i]; else print "none"; D = 1 }
    { sub(/\r$/, "") }
    f && /^[ \t]*-[ \t]/ { l = $0; sub(/^[ \t]*-[ \t]+/, "", l); sub(/[ \t]+$/, "", l); k++; if (l != "" && !isnone(tolower(l))) L[++n] = l; next }
    f && /^[ \t]*$/ { next }
    f && k { fin(); exit }
    { f = 0 }
    /^[ \t]*Decisions:/ { r = $0; sub(/^[ \t]*Decisions:[ \t]*/, "", r); sub(/[ \t]+$/, "", r); if (r == "") { f = 1; n = 0; k = 0 } else if (isnone(r)) { print "none"; D = 1; exit } }
    END { if (!D) { if (f && k) fin(); else print "missing" } }' "$1"; }
if [ "$CMD" = section ]; then [ $# -eq 1 ] && [ -f "$1" ] || usage; sect "$1"; exit 0; fi
[ -f DECISIONS.md ] || refuse 'no DECISIONS.md here'
TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
# 0.26.10.29.3 (R7): the label join is the commit hook's own (labels.sh, beside this file): `badlab` holds the D-ids of the
# labelled lines the hook would refuse, from the working tree's INVENTORY.md and ARCHITECTURE.md
. "$HERE/labels.sh"
TAB=$(printf '\t')

# unlabel: the line with any applies-to:/scope: field stripped by name (the hook's 4c comparison)
unlabel() { awk -F'|' '{ o = ""; n = 0; for (i = 1; i <= NF; i++) { f = $i; sub(/^[ \t]+/, "", f); if (f ~ /^(applies-to|scope):/) continue; o = (n++ ? o "|" : "") $i } sub(/[ \t]+$/, "", o); print o }'; }
thash() { printf '%s\n' "$1" | unlabel | git hash-object --stdin 2>/dev/null | cut -c1-12; }
# the decision lines: `<D-id><TAB><labelled yes|no><TAB><cites an id yes|no><TAB><line>`
grep -E '^- \*\*D-[0-9]+\*\*' DECISIONS.md | awk -v OFS='\t' '
  function anyid(s,   o, q, x, y) { q = s; o = 0; while (match(q, /(ROW|REQ|RULE)-[0-9]+/)) { x = (o + RSTART > 1) ? substr(s, o + RSTART - 1, 1) : ""; y = substr(s, o + RSTART + RLENGTH, 1); if (x !~ /[A-Za-z0-9_-]/ && y !~ /[A-Za-z0-9_-]/) return 1; o += RSTART; q = substr(s, o + 1) } return 0 }
  { match($0, /D-[0-9]+/); id = substr($0, RSTART, RLENGTH); lab = "no"; n = split($0, t, "|")
    for (k = 2; k <= n; k++) { f = t[k]; gsub(/^[ \t]+/, "", f); if (f ~ /^(applies-to|scope):/) lab = "yes" }
    print id, lab, (anyid($0) ? "yes" : "no"), $0 }' > "$TMPD/dec" || : > "$TMPD/dec"
label_items INVENTORY.md ARCHITECTURE.md > "$TMPD/items"
awk -F'\t' '$2 == "yes" { print $4 }' "$TMPD/dec" | label_bad "$TMPD/items" | sed -n 's/^    - \*\*\(D-[0-9][0-9]*\)\*\*.*/\1/p' > "$TMPD/badlab"

# the inventory, read once: rows `ROW<TAB>id<TAB>derived-from<TAB>screen codes<TAB>DIF ids`, rules `RULE<TAB>id<TAB>tier0 yes|no<TAB>origin ids<TAB>text`
inv_read() {
  [ -f INVENTORY.md ] || { : > "$TMPD/inv"; return 0; }
  sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | sed '1d;$d' | awk -F'|' -v OFS='\t' '
    function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function j(s,   n, a, k, o) { n = split(s, a, /[ ,]+/); o = ""; for (k = 1; k <= n; k++) if (a[k] != "") o = o (o == "" ? "" : " ") a[k]; return o }
    { id = tr($1)
      if (id ~ /^ROW-[0-9]+$/) { sc = ""; n = split(tr($5), a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] != "n/a" && index(a[k], "/") > 1) sc = sc (sc == "" ? "" : " ") substr(a[k], 1, index(a[k], "/") - 1)
        dv = ""; for (i = 8; i <= NF; i++) { f = tr($i); if (f ~ /^divergence:/) { sub(/^divergence:[ \t]*/, "", f); dv = j(f) } }
        print "ROW", id, j(tr($7)), sc, dv }
      else if (id == "rule" && tr($2) ~ /^RULE-[0-9]+$/) { n = NF; og = ""
        while (n > 4 && tr($n) ~ /^(origin|proved-red|paid-at):/) { f = tr($n); if (f ~ /^origin:/) { sub(/^origin:[ \t]*/, "", f); og = j(f) } n-- }
        t0 = "no"; if (n >= 6) { t = tr($(n - 1)); if (t ~ /^(0|T0|t0|tier-0|tier0|Tier-0)$/) t0 = "yes" }
        print "RULE", tr($2), t0, og, tr($3) } }' > "$TMPD/inv"
  # v0.26.10.2 (R17c): `MOD<TAB>id`, the module ids of ARCHITECTURE.md's module table, as the commit hook reads them
  [ -f ARCHITECTURE.md ] && awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /^[ \t]*\|/ { if (done) next; if (!intab) { intab = 1; if (!col) { n = split($0, c, "|"); for (k = 2; k < n; k++) if (tr(c[k]) == "Module") col = k } next }
      if (!col || $0 ~ /^[ \t]*\|[ \t:|-]*$/) next; split($0, c, "|"); m = c[col]; gsub(/`/, "", m); m = tr(m)
      if (m == "" || index(m, "{{") == 1 || m == "Module") next; if (m !~ /\// && m ~ /\./) gsub(/\./, "/", m); print m; next }
    { if (intab && col) done = 1; intab = 0 }' ARCHITECTURE.md | awk -v OFS='\t' '{ print "MOD", $0 }' >> "$TMPD/inv"
  return 0
}

case "$CMD" in
  propose)
    ALL=no; [ "${1:-}" = --all ] && ALL=yes
    # 0.26.10.29.3 (R7): and every labelled line whose label the hook would refuse (badlab), whatever it cites
    awk -F'\t' -v all="$ALL" 'FILENAME == ARGV[1] { B[$1] = 1; next } ($1 in B) || ($2 == "no" && (all == "yes" || $3 == "no"))' "$TMPD/badlab" "$TMPD/dec" > "$TMPD/sel"
    K=$(grep -c . "$TMPD/sel" || true)
    [ "$K" -gt 0 ] || { echo 'propose: no decision to label'; exit 0; }
    inv_read
    mkdir -p .vid/briefs; N=1; while [ -e ".vid/briefs/labels-$N.md" ]; do N=$((N + 1)); done
    B=.vid/briefs/labels-$N.md
    {
      printf 'role: labeller (general-purpose)    receives: the decisions below; read access to DECISIONS.md, INVENTORY.md, PRD.md and DESIGN-BRIEF.md    must not receive: any edit — you change no file\n'
      printf 'written: decisions.sh propose %s\n\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
      printf '## The task\n\nFor each decision below, propose the label that says where it applies, so a\n'
      printf 'brief quotes it only where it bears: `applies-to: <items>`, comma separated, naming\n'
      printf 'the ROW, RULE or REQ ids, screen codes or DIF ids it bears on (only the items listed\n'
      printf 'under "The items a label may name", or a ROW id of INVENTORY.md); or `scope: project`,\n'
      printf 'only when it bears on many areas. A decision that bears on one module, or a few, also\n'
      printf 'names their module ids, beside its row, requirement or screen items, never instead of\n'
      printf 'them. A decision listed with a label already is one no brief can join on: propose its\n'
      printf 'replacement. Say `sure` or `unsure`. Return exactly one line per\n'
      printf 'decision, nothing else, the hash copied as given:\n\n'
      printf '    D-NNN <hash> | applies-to: <items> | sure\n    D-NNN <hash> | scope: project | unsure\n\n'
      printf '## The decisions (%s)\n\n' "$K"
      while IFS="$TAB" read -r id _l _c line; do printf '%s %s | %s\n' "$id" "$(thash "$line")" "$line"; done < "$TMPD/sel"
      printf '\n## The items a label may name\n\n'
      printf 'Screen codes (rows marking each): %s\n\n' "$(awk -F'\t' '$1 == "ROW" { n = split($4, a, " "); for (k = 1; k <= n; k++) c[a[k]]++ } END { for (s in c) print s " (" c[s] ")" }' "$TMPD/inv" | sort | paste -sd ',' - | sed 's/,/, /g')"
      printf 'DIF ids: %s\n\n' "$(awk -F'\t' '$1 == "ROW" && $5 != "" { n = split($5, a, " "); for (k = 1; k <= n; k++) print a[k] }' "$TMPD/inv" | sort -u | paste -sd ' ' -)"
      printf 'Rule rows:\n'; awk -F'\t' '$1 == "RULE" { print "- " $2 " " $5 (($4 != "") ? " (origin: " $4 ")" : "") }' "$TMPD/inv"
      printf '\nRequirements rows derive from (statements in PRD.md): %s\n' "$(awk -F'\t' '$1 == "ROW" { n = split($3, a, " "); for (k = 1; k <= n; k++) if (a[k] ~ /^REQ-/) print a[k] }' "$TMPD/inv" | sort -u | paste -sd ' ' -)"
      printf 'Rows: every ROW id of INVENTORY.md'"'"'s vid-inventory block (%s rows).\n' "$(awk -F'\t' '$1 == "ROW"' "$TMPD/inv" | grep -c . || true)"
      printf 'Module ids (ARCHITECTURE.md): %s\n' "$(awk -F'\t' '$1 == "MOD" { print $2 }' "$TMPD/inv" | paste -sd ' ' -)"
    } > "$B"
    echo "propose: $K decisions → $B"
    exit 0 ;;
  record)   # 0.26.10.29.5 (DP-1 R2): the dev side's decisions into DECISIONS.md, from merged pull requests and read deploy reports (header)
    [ $# -eq 0 ] || usage
    [ -f .vid/RUN-STATE.md ] && [ -f .vid/tw/settings ] || refuse "record runs at the top of ViD's repository, in ticket mode"
    # while a draft waits on the owner nothing is read or written: a commit would make the draft stale (land.sh), and the draft
    # holds whole files, DECISIONS.md among them, so its landing would drop the lines; the next round after it is settled records them
    for _d in $(ls .vid/decide/drafts 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do _x=.vid/decide/drafts/$_d
      [ -f "$_x/base" ] && [ ! -f "$_x/landed" ] && [ ! -f "$_x/declined" ] && [ ! -f "$_x/replaced" ] || continue; echo "decisions wait draft=$_d"; exit 0; done
    # the label hook's join set at HEAD, as labels.sh reads it for the hook (the commit stages DECISIONS.md alone, so the index is HEAD's)
    git show HEAD:INVENTORY.md > "$TMPD/hi" 2>/dev/null || : > "$TMPD/hi"; git show HEAD:ARCHITECTURE.md > "$TMPD/ha" 2>/dev/null || : > "$TMPD/ha"
    label_items "$TMPD/hi" "$TMPD/ha" > "$TMPD/hj"
    rdone() { grep -q "^decisions-recorded $1 " .vid/metrics-events 2>/dev/null; }
    # items <ticket>: the ticket's ROW and RULE ids, then its step's modules as the writer reads them, kept where the hook joins
    items() { _f=.vid/tw/out/issue-$1.md; { sed -n 's/^- rows: //p' "$_f" 2>/dev/null | head -n 1 | tr ' ,' '\n\n' | grep -E '^(ROW|RULE)-[0-9]+$' || true
        _s=$(sed -n 's/^- step: //p' "$_f" 2>/dev/null | head -n 1 | sed 's/[[:space:]]*$//')
        [ -z "$_s" ] || plan_block | awk -F'|' -v s="$_s" 'function nm(x) { gsub(/^[ \t`]+|[ \t`]+$/, "", x); gsub(/\./, "/", x); sub(/\/+$/, "", x); return x }
          { h = $1; gsub(/^[ \t]+|[ \t]+$/, "", h); split(h, w, /[ \t]+/); if (w[1] != "step" || w[2] != s) next
            for (k = 2; k <= NF; k++) { x = $k; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x ~ /^modules:/) { n = split(substr(x, 9), a, /[ ,\t]+/); for (i = 1; i <= n; i++) if (a[i] != "") print nm(a[i]) } } }'
      } | awk 'FILENAME == ARGV[1] { J[$0] = 1; next } ($0 in J) && !s[$0]++' "$TMPD/hj" -; }
    # lines <enforced> <label>: each section line on standard input as a decision line less its id; a `|` in the words written `/`
    lines() { awk -v E="$1" -v LB="$2" '{ s = $0; sub(/\r$/, "", s); sc = 0
        if (match(s, /[ \t]*\|[ \t]*scope:[ \t]*project[ \t]*$/)) { sc = 1; s = substr(s, 1, RSTART - 1) }
        w = ""; if (match(s, /\|[ \t]*why:/)) { w = substr(s, RSTART + RLENGTH); s = substr(s, 1, RSTART - 1) }
        gsub(/\|/, "/", s); gsub(/\|/, "/", w); gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", w); if (s == "") next
        print s " | why: " (w == "" ? "not given" : w) " | enforced: " E " | " (sc ? "scope: project" : LB) " | origin: dev-side" }'; }
    # one <key> <lines file> <what>: the lines numbered and appended, one commit of DECISIONS.md alone; its event and its line;
    # refused for now, nothing recorded and tried again next time, while other changes are staged or DECISIONS.md holds changes HEAD
    # does not, so the commit holds DECISIONS.md alone and only these lines
    one() { _o=$(git diff --cached --name-only 2>/dev/null | grep -vxF DECISIONS.md || true)
      if [ -n "$_o" ] || ! git diff --quiet HEAD -- DECISIONS.md 2>/dev/null; then echo "decisions unread $1: $( [ -n "$_o" ] && echo "other changes are staged ($(printf '%s' "$_o" | paste -sd ' ' -))" || echo 'DECISIONS.md holds changes HEAD does not')"; return 0; fi
      : > "$TMPD/ids"; [ -z "$(tail -c 1 DECISIONS.md)" ] || echo >> DECISIONS.md
      while IFS= read -r _l; do _i=$(sh "$HERE/decisions.sh" next) || { git checkout -q HEAD -- DECISIONS.md; echo "decisions unread $1: no number could be reserved"; return 0; }
        printf -- '- **%s** %s\n' "$_i" "$_l" >> DECISIONS.md; echo "$_i" >> "$TMPD/ids"; done < "$2"
      _k=$(grep -c . "$TMPD/ids"); _ids=$(paste -sd , "$TMPD/ids" | sed 's/,/, /g'); git add DECISIONS.md
      if printf 'decisions: the dev side'"'"'s, from %s\n\nREQs: none\nDecisions: %s — the dev side'"'"'s decisions on %s, recorded in its words (origin: dev-side)\nSeams: none\n' "$3" "$_ids" "$3" | git commit -q -F - -- DECISIONS.md > "$TMPD/co" 2>&1; then
        ev "decisions-recorded $1 n=$_k"; echo "decisions recorded $1 n=$_k $(paste -sd , "$TMPD/ids")"; CM=1
      else git checkout -q HEAD -- DECISIONS.md; ev "decisions-recorded $1 n=refused"
        echo "decisions refused $1 $(grep -m 1 '^ViD ' "$TMPD/co" || head -n 1 "$TMPD/co")"; fi; }
    CM=''
    # each merged pull request ViD decided, its description read once
    if [ -f .vid/decide/merges ]; then while IFS="$TAB" read -r _p _t _h _m <&3; do [ -n "$_p" ] && ! rdone "pr=$_p" || continue
        case $_t in ''|*[!0-9]*) ev "decisions-recorded pr=$_p n=missing"; continue ;; esac   # no ticket, no ref to enforce it by
        sh "$HERE/github.sh" pr-body "$_p" > "$TMPD/body" 2> "$TMPD/e" || { echo "decisions unread pr=$_p: $(tail -n 1 "$TMPD/e")"; continue; }
        sect "$TMPD/body" > "$TMPD/sec"; case $(head -n 1 "$TMPD/sec") in missing|none) ev "decisions-recorded pr=$_p n=$(head -n 1 "$TMPD/sec")"; continue ;; esac
        _it=$(items "$_t" | paste -sd , - | sed 's/,/, /g'); lines "ticket $_t" "$( [ -n "$_it" ] && echo "applies-to: $_it" || echo 'scope: project')" < "$TMPD/sec" > "$TMPD/ln"
        if [ -s "$TMPD/ln" ]; then one "pr=$_p" "$TMPD/ln" "pull request #$_p (ticket #$_t)"; else ev "decisions-recorded pr=$_p n=none"; fi
      done 3< .vid/decide/merges; fi
    # each deploy report the reader read and did not refuse, whatever its outcome, its report.txt read once: decision: lines, or
    # decisions: none. DevAgent's deployer copies its standing record's lines into every report, so a line whose words (what and
    # why, as recorded) an origin: dev-side deploy line of DECISIONS.md holds already is left out: in neither n nor the commit
    for _f in $(ls .vid/decide/stage/*/*/d1*/read .vid/decide/stage/*/*/rh*/read .vid/decide/stage/*/*/d2*/read 2>/dev/null); do
      case $(awk -F'\t' 'NR == 1 { print $2 }' "$_f") in passed|failed|no-backup) ;; *) continue ;; esac; _k=$(awk -F'\t' 'NR == 1 { print $3 }' "$_f")
      _n=$(sed -n "s/^issue$TAB//p" "$(dirname "$_f")/ask" 2>/dev/null | head -n 1); [ -n "$_n" ] && [ -n "$_k" ] || continue; _id=deploy-$_n-$_k; ! rdone "deploy=$_id" || continue
      git --git-dir=.vid/code show "refs/heads/vid-results/$_id:$_id/report.txt" > "$TMPD/rp0" 2>/dev/null || continue; tr -d '\r' < "$TMPD/rp0" > "$TMPD/rp"
      sed -n 's/^decision: *//p' "$TMPD/rp" > "$TMPD/sec"
      if [ ! -s "$TMPD/sec" ]; then grep -qE '^decisions: *none[[:space:]]*$' "$TMPD/rp" && ev "decisions-recorded deploy=$_id n=none"; continue; fi
      git show HEAD:DECISIONS.md > "$TMPD/hd" 2>/dev/null || : > "$TMPD/hd"   # held by HEAD's lines alone: an edit not committed holds nothing
      lines "deploy $_id" 'scope: project' < "$TMPD/sec" | awk 'FILENAME == ARGV[1] { if ($0 !~ /^- \*\*D-[0-9]+\*\* / || index($0, " | enforced: deploy ") == 0 || $0 !~ /\| origin: dev-side$/) next
          w = $0; sub(/^- \*\*D-[0-9]+\*\* /, "", w); sub(/ \| enforced: deploy .*$/, "", w); H[w] = 1; next }
        { w = $0; sub(/ \| enforced: deploy .*$/, "", w); if (!(w in H)) { H[w] = 1; print } }' "$TMPD/hd" - > "$TMPD/ln"
      if [ -s "$TMPD/ln" ]; then one "deploy=$_id" "$TMPD/ln" "deploy report $_id"; else ev "decisions-recorded deploy=$_id n=0"; fi; done
    # the export at once, so a grade asked after this round reads these lines
    if [ -n "$CM" ]; then sh "$HERE/github.sh" spec-export > "$TMPD/x" 2>&1 || { echo "decisions export failed: $(tail -n 1 "$TMPD/x")"; }; fi
    exit 0 ;;
  apply) ;;
  *) usage ;;
esac

# --- apply: the proposals, written --------------------------------------------------------
PF=.vid/decision-labels.proposed
case "${1:-}" in ''|--*) ;; *) PF=$1; shift ;; esac
[ -f "$PF" ] || refuse "no proposals at $PF (the labeller's return, saved by the run manager)"
COMMIT=yes
while [ $# -gt 0 ]; do case "$1" in --no-commit) COMMIT=no ;; *) usage ;; esac; shift; done
if [ "$COMMIT" = yes ]; then
  _other=$(git diff --cached --name-only 2>/dev/null | grep -vxF DECISIONS.md || true)
  [ -z "$_other" ] || refuse "other changes are staged ($(printf '%s' "$_other" | paste -sd ' ' -)); the labels are their own commit"
fi
# the proposals: `<D-id><TAB><hash><TAB><label written><TAB><sure|widened: why>` — a malformed line naming no decision is `?`
awk -F'\t' -v OFS='\t' 'FILENAME == ARGV[1] { J[$0] = 1; next }
  function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  NF == 0 { next }
  { n = split($0, p, "|"); h = tr(p[1]); split(h, hp, /[ \t]+/); id = hp[1]; hs = hp[2]
    if (id !~ /^D-[0-9]+$/) { print "?", "-", "-", "-"; next }
    lab = tr(p[2]); s = tr(p[3])
    if (n != 3 || hs !~ /^[0-9a-f]+$/) { print id, hs, "scope: project", "widened: the proposal line is malformed"; next }
    if (lab == "scope: project") { print id, hs, lab, (s == "sure" ? "sure" : "widened: not sure"); next }
    if (lab !~ /^applies-to:[ \t]*[^ \t]/) { print id, hs, "scope: project", "widened: neither applies-to: nor scope: project"; next }
    if (s != "sure") { print id, hs, "scope: project", "widened: not sure (proposed " lab ")"; next }
    v = lab; sub(/^applies-to:[ \t]*/, "", v); m = split(v, it, /[ ,]+/); bad = ""
    for (k = 1; k <= m; k++) if (it[k] != "" && !(it[k] in J)) bad = bad " " it[k]
    if (bad != "") { print id, hs, "scope: project", "widened: no brief joins on" bad " (proposed " lab ")"; next }
    print id, hs, lab, "sure" }' "$TMPD/items" "$PF" > "$TMPD/plan"
# write: a line is labelled when it is present, unlabelled or labelled as the hook refuses (0.26.10.29.3, R7: that label
# is replaced, so a line never carries two), and its text hash matches its proposal
: > "$TMPD/changed"; : > "$TMPD/skipped"; : > "$TMPD/labels"; : > "$TMPD/record"
while IFS="$TAB" read -r id h lab why; do
  if [ "$id" = '?' ]; then printf '? (a malformed line naming no decision)\n' >> "$TMPD/skipped"; continue; fi
  line=$(awk -F'\t' -v d="$id" '$1 == d { print $4; exit }' "$TMPD/dec")
  labd=$(awk -F'\t' -v d="$id" '$1 == d { print $2; exit }' "$TMPD/dec")
  if [ -z "$line" ]; then printf '%s (not in DECISIONS.md)\n' "$id" >> "$TMPD/skipped"; continue; fi
  if [ "$labd" = yes ] && ! grep -qxF "$id" "$TMPD/badlab"; then printf '%s (already labelled)\n' "$id" >> "$TMPD/skipped"; continue; fi
  if [ "$(thash "$line")" != "$h" ]; then printf '%s\n' "$id" >> "$TMPD/changed"; continue; fi
  printf '%s\t%s\n' "$id" "$lab" >> "$TMPD/labels"; printf '%s\t%s\t%s\n' "$id" "$lab" "$why" >> "$TMPD/record"
done < "$TMPD/plan"
# the label goes after the enforced: field (before origin: or model:), else at the end; a label the line already carries is
# dropped first (0.26.10.29.3, R7)
awk -F'|' -v lf="$TMPD/labels" 'BEGIN { while ((getline l < lf) > 0) { split(l, a, "\t"); L[a[1]] = a[2] } }
  /^- \*\*D-[0-9]+\*\*/ { match($0, /D-[0-9]+/); id = substr($0, RSTART, RLENGTH)
    if (id in L) { o = ""; done = 0; m = 0
      for (i = 1; i <= NF; i++) { f = $i; sub(/^[ \t]+/, "", f); if (i > 1 && f ~ /^(applies-to|scope):/) continue; u[++m] = $i }
      for (i = 1; i <= m; i++) { o = o (i > 1 ? "|" : "") u[i]; f = u[i]; sub(/^[ \t]+/, "", f); if (!done && f ~ /^enforced:/) { if (i < m) o = o "| " L[id] " "; else { sub(/[ \t]+$/, "", o); o = o " | " L[id] } done = 1 } }
      if (!done) { sub(/[ \t]+$/, "", o); o = o " | " L[id] }
      print o; next } }
  { print }' DECISIONS.md > "$TMPD/DECISIONS.md"
A=$(grep -c . "$TMPD/labels" || true); WD=$(grep -c "$(printf '\t')widened:" "$TMPD/record" || true); C=$(grep -c . "$TMPD/changed" || true); SK=$(grep -c . "$TMPD/skipped" || true)
if [ "$A" -gt 0 ]; then cp "$TMPD/DECISIONS.md" DECISIONS.md; mkdir -p .vid; cat "$TMPD/record" >> .vid/decision-labels.applied; fi
[ "$C" -eq 0 ] || { echo "apply: $C changed since their proposal, not labelled: $(paste -sd ' ' "$TMPD/changed")"; }
[ "$SK" -eq 0 ] || { echo "apply: $SK skipped: $(paste -sd ',' "$TMPD/skipped" | sed 's/,/, /g')"; }
if [ "$COMMIT" = yes ] && [ "$A" -gt 0 ]; then
  git add DECISIONS.md
  # the project's commit template (CLAUDE.md law; checks/hooks/commit-msg reads Decisions:)
  git commit -q -F - -- DECISIONS.md <<MSG || refuse 'the labels commit was refused (DECISIONS.md is left labelled, uncommitted)'
decisions: labels from the labelling pass (applied=$A widened=$WD changed=$C skipped=$SK)

REQs: none
Decisions: none — labels on existing decision lines only, no decision added or changed
Seams: none
MSG
fi
if [ -f checks/event.sh ]; then sh checks/event.sh "decision-labels applied=$A widened=$WD changed=$C skipped=$SK"
else mkdir -p .vid; printf 'decision-labels applied=%s widened=%s changed=%s skipped=%s at=%s\n' "$A" "$WD" "$C" "$SK" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; fi
echo "apply: decision-labels applied=$A widened=$WD changed=$C skipped=$SK — the record: .vid/decision-labels.applied$( [ "$COMMIT" = no ] && echo ' (not committed: they land in the next commit)' )"
exit 0
