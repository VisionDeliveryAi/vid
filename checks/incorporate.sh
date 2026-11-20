#!/bin/sh
# Purpose: /vid incorporate's helper (IR I1, I2, I4): the record's cite, the mark on a replaced decision line, and the check
# of an amendment against its map. Run at the top of ViD's repository (the project, in develop). It reads git and the spec
# files; it writes only DECISIONS.md (mark), with what checks/decisions.sh apply writes for the one line it labels.
#   cite <path>
#       IR I1: the record's cite, `<path>@<12-hex HEAD>`, for a path (from the top of the repository) committed and
#       unchanged in the tree, staged or not, a regular file (a symlink is refused); else refused.
#   mark <old D-id> <new D-id> [--label "<label>"]
#       IR I2: puts ` | replaced-by: <new>` in the old line's rule part, right before ` | why:`, or adds <new> to the mark
#       it has, after the ids there; no other word of the line changes. When the old line has no label the commit hook's
#       check 4c accepts (checks/labels.sh, over the working tree's INVENTORY.md and ARCHITECTURE.md), it is labelled
#       first, by `checks/decisions.sh apply --no-commit` on a proposals file holding that line alone, so no other line
#       is labelled: the label given, else `scope: project` (apply widens one no brief joins on). Both ids are lines of
#       the working tree's DECISIONS.md; an id the mark holds already changes nothing. Refused, DECISIONS.md is left as
#       it was: an id it lacks, the same id twice, an old line with no ` | why:` field.
#   check <map> --record <cite> [--record <cite>…] [--base <commit>] [--text]
#       IR I1, I4: the amendment (the spec files, CLAUDE.md PRD.md BASELINE.md ARCHITECTURE.md DECISIONS.md INVENTORY.md
#       GRADING-CHECKLIST.md STAGES.md PLAN.md, as <commit>, default HEAD, holds them and as the working tree does)
#       against its map, one entry a line, `#` lines and blank ones skipped: `<file> | <where> | today: <text> | change:
#       <text> | record: <text>`, `left: <file> | <where> | <why>` or `open: <question>`. Each added, changed or removed
#       decision line is a change line of DECISIONS.md by its D-id; each other changed spec file has a change line naming
#       it; no change line names a spec file, or a decision line, the amendment leaves as it was. Each new decision line's
#       why: holds the cite (`<path>@<12 hex>`, a file at that commit, or `https://github.com/<owner>/<repo>/blob/<40 hex>/
#       <path>`; --record repeats, and any one of them will do) and its enforced: is `convention`; an old decision line
#       gains a label or a mark and nothing else, and none is removed. INVENTORY.md is placed by row id, every kind (a
#       ROW id first, or a kind's word then its id), and PRD.md by item id (REQ INV NG RISK HYP OUT MET CON, AMENDED
#       taken off): each added, changed or removed row or item needs a change line naming its id; the other files are placed file by file. Each new or changed
#       row derives from requirement ids, never a D-id (a ROW in derived-from, any other kind in its origin); each new
#       row, any kind, carries `origin: incorporation <YYYY-MM-DD> D-NNN` naming a new decision line (a rule row then
#       names its requirement ids, `… D-NNN REQ-NNN`; a ROW nothing more); each new decision line
#       is named by a new row's origin, of any kind, or by a `left:` line. --text, the first part in develop and GitHub manual: the
#       spec text alone, so INVENTORY.md is as <commit> holds it and the rows' rules wait for the rows. Prints `map: <c>
#       changes, <l> left, <o> open`; refused, it prints each difference on a line of its own.
# Exit 0; 1 refused; 2 usage.
# serves: both
set -eu
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
usage() { echo 'ViD incorporate: usage — sh checks/incorporate.sh cite <path> | mark <old D-id> <new D-id> [--label "<label>"] | check <map> --record <cite> [--record <cite>…] [--base <commit>] [--text]' >&2; exit 2; }
refuse() { echo "ViD incorporate: refused — $*" >&2; exit 1; }
[ $# -ge 1 ] || usage
CMD=$1; shift
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# bare: a decision line with its label and its mark taken off, by name (the words the mark never changes)
bare() { awk -F'|' '{ o = ""; n = 0; for (i = 1; i <= NF; i++) { f = $i; sub(/^[ \t]+/, "", f); if (i > 1 && f ~ /^(applies-to|scope|replaced-by):/) continue; o = (n++ ? o "|" : "") $i } sub(/[ \t]+$/, "", o); print o }'; }
# unlabel: the line with its label taken off, as checks/decisions.sh hashes it for its proposals
unlabel() { awk -F'|' '{ o = ""; n = 0; for (i = 1; i <= NF; i++) { f = $i; sub(/^[ \t]+/, "", f); if (f ~ /^(applies-to|scope):/) continue; o = (n++ ? o "|" : "") $i } sub(/[ \t]+$/, "", o); print o }'; }
dline() { grep -E "^- \*\*$1\*\*( |$)" DECISIONS.md || true; }

cmd_mark() {
  [ $# -ge 2 ] || usage
  OLD=$1; NEW=$2; shift 2; LAB='scope: project'
  while [ $# -gt 0 ]; do case "$1" in --label) [ $# -ge 2 ] && [ -n "$2" ] || usage; LAB=$2; shift 2 ;; *) usage ;; esac; done
  for x in "$OLD" "$NEW"; do case "$x" in D-[0-9]*) case "$x" in *[!0-9D-]*|D-*-*) usage ;; esac ;; *) usage ;; esac; done
  [ -f DECISIONS.md ] || refuse 'no DECISIONS.md here: run it at the top of the repository'
  [ "$OLD" != "$NEW" ] || refuse "$OLD cannot replace itself"
  [ "$(dline "$OLD" | grep -c .)" = 1 ] || refuse "DECISIONS.md holds no line $OLD (or more than one)"
  [ -n "$(dline "$NEW")" ] || refuse "DECISIONS.md holds no line $NEW: write the replacing line first"
  ol=$(dline "$OLD")
  case "$ol" in *' | why:'*) ;; *) refuse "$OLD has no ' | why:' field, where the mark goes" ;; esac
  W0=$(printf '%s\n' "$ol" | bare); cp DECISIONS.md "$T/orig"
  # the label first, when 4c would refuse the line's own (apply writes it only while the text hash matches)
  . "$HERE/labels.sh"
  label_items INVENTORY.md ARCHITECTURE.md > "$T/items"
  LABELLED=''
  if [ -n "$(printf '%s\n' "$ol" | label_bad "$T/items")" ]; then
    h=$(printf '%s\n' "$ol" | unlabel | git hash-object --stdin | cut -c1-12)
    printf '%s %s | %s | sure\n' "$OLD" "$h" "$LAB" > "$T/proposal"
    sh "$HERE/decisions.sh" apply "$T/proposal" --no-commit > "$T/apply" 2>&1 || { cp "$T/orig" DECISIONS.md; cat "$T/apply" >&2; refuse "the labelling pass did not label $OLD"; }
    ol=$(dline "$OLD")
    [ -z "$(printf '%s\n' "$ol" | label_bad "$T/items")" ] || { cp "$T/orig" DECISIONS.md; cat "$T/apply" >&2; refuse "$OLD still has no label the commit hook accepts"; }
    LABELLED=$(sed -n "s/^$OLD	\([^	]*\)	.*/\1/p" .vid/decision-labels.applied 2>/dev/null | tail -n 1)
  fi
  cp DECISIONS.md "$T/before"
  awk -F'|' -v OFS='|' -v old="$OLD" -v new="$NEW" '
    function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    index($0, "- **" old "**") == 1 && !done { done = 1
      for (i = 2; i <= NF; i++) { f = tr($i); if (f !~ /^replaced-by:/) continue
        v = f; sub(/^replaced-by:[ \t]*/, "", v); n = split(v, a, /[ ,]+/); for (k = 1; k <= n; k++) if (a[k] == new) { print; next }
        $i = " " f ", " new " "; print; next }
      i = index($0, " | why:"); print substr($0, 1, i - 1) " | replaced-by: " new substr($0, i); next }
    { print }' "$T/before" > "$T/after"
  nl=$(grep -E "^- \*\*$OLD\*\*( |$)" "$T/after")
  [ "$(printf '%s\n' "$nl" | bare)" = "$W0" ] || { cp "$T/orig" DECISIONS.md; refuse "the mark would change $OLD's words"; }
  cmp -s "$T/before" "$T/after" && { echo "mark: $OLD already names $NEW"; return 0; }
  cp "$T/after" DECISIONS.md
  echo "mark: $OLD $(printf '%s\n' "$nl" | tr '|' '\n' | sed -n 's/^[ \t]*\(replaced-by:.*[^ \t]\)[ \t]*$/\1/p')${LABELLED:+ (labelled first: $LABELLED)}"
}

cmd_cite() {
  [ $# -eq 1 ] && [ -n "$1" ] || usage
  p=$1
  [ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$(pwd -P)" ] || refuse 'run it at the top of the repository'
  case "$p" in /*|../*|*/../*|*/..) refuse "$p: name the record by its path from the top of the repository" ;; esac
  [ ! -L "$p" ] || refuse "$p is a symlink: the record is a committed regular file"
  [ -n "$(git ls-files -- "$p")" ] && [ -f "$p" ] || refuse "$p is not committed: commit the record, on the owner's word, before it is read"
  git diff --quiet HEAD -- "$p" 2>/dev/null || refuse "$p differs from HEAD's: the record read must be the one committed"
  echo "$p@$(git rev-parse HEAD | cut -c1-12)"
}

SPECF='CLAUDE.md PRD.md BASELINE.md ARCHITECTURE.md DECISIONS.md INVENTORY.md GRADING-CHECKLIST.md STAGES.md PLAN.md'
cmd_check() {
  [ $# -ge 1 ] || usage
  MAP=$1; shift; CITES=''; BASE=HEAD; TEXT=no
  while [ $# -gt 0 ]; do case "$1" in
    --record) [ $# -ge 2 ] && [ -n "$2" ] || usage; CITES="$CITES$2
"; shift 2 ;;
    --base) [ $# -ge 2 ] || usage; BASE=$2; shift 2 ;;
    --text) TEXT=yes; shift ;;
    *) usage ;; esac; done
  [ -f "$MAP" ] && [ -n "$CITES" ] || usage
  [ -f DECISIONS.md ] || refuse 'no DECISIONS.md here: run it at the top of the repository'
  B=$(git rev-parse -q --verify "$BASE^{commit}" 2>/dev/null) || refuse "$BASE is no commit"
  printf '%s' "$CITES" > "$T/cites"
  while IFS= read -r CITE; do
    if printf '%s\n' "$CITE" | grep -qE '^https://github\.com/[^/ ]+/[^/ ]+/blob/[0-9a-f]{40}/[^ ]+$'; then :
    elif printf '%s\n' "$CITE" | grep -qE '^[^@ ]+@[0-9a-f]{12}$'; then
      git cat-file -e "${CITE##*@}:${CITE%@*}" 2>/dev/null || refuse "the cite $CITE names no file at that commit"
    else refuse "the cite $CITE is neither <path>@<12-hex commit> nor a blob link at a commit"; fi
  done < "$T/cites"
  # the spec files as the base and the working tree hold them; the files that differ
  mkdir "$T/b" "$T/w"; : > "$T/changed"
  for f in $SPECF; do
    git show "$B:$f" > "$T/b/$f" 2>/dev/null || : > "$T/b/$f"
    if [ -f "$f" ]; then cp "$f" "$T/w/$f"; else : > "$T/w/$f"; fi
    cmp -s "$T/b/$f" "$T/w/$f" || echo "$f" >> "$T/changed"
  done
  # the places, by id: `<id><TAB><line>` — DECISIONS.md's lines by D-id, INVENTORY.md's block rows by id (every kind: the
  # first field, or the second after the kind's word), PRD.md's item rows by id (REQ INV NG RISK HYP OUT MET CON, a
  # trailing AMENDED taken off, as checks/prd.sh reads them; answers and findings stay file by file) and `### REQ-NNN`
  # headings; an id written twice (an amended item) is compared as all its lines. A tab inside a line travels as \002,
  # so no line is split on it
  keyed() { case $2 in
    DECISIONS.md) grep -E '^- \*\*D-[0-9]+\*\*' "$1" | awk '{ match($0, /D-[0-9]+/); print substr($0, RSTART, RLENGTH) "\t" $0 }' ;;
    INVENTORY.md) sed -n '/^```vid-inventory/,/^```$/p' "$1" | sed '1d;$d' | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        { a = tr($1); b = tr($2); id = (a ~ /^[A-Z]+-[0-9]+$/) ? a : ((b ~ /^[A-Z]+-[0-9]+$/) ? b : ""); if (id != "") print id "\t" $0 }' ;;
    PRD.md) awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        { a = tr($1); sub(/[ \t]+AMENDED$/, "", a); if (a ~ /^(REQ|INV|NG|RISK|HYP|OUT|MET|CON)-[0-9]+$/) { print a "\t" $0; next } if (match($0, /^#+[ \t]+REQ-[0-9]+/)) { x = substr($0, RSTART, RLENGTH); sub(/^#+[ \t]+/, "", x); print x "\t" $0 } }' "$1" ;;
    esac || true; }
  # `new|changed|removed<TAB><file><TAB><id>`, and the new lines' and changed lines' text beside: `<TAB><base><TAB><now>`
  : > "$T/pl"
  for f in DECISIONS.md INVENTORY.md PRD.md; do
    keyed "$T/b/$f" "$f" > "$T/k.b"; keyed "$T/w/$f" "$f" > "$T/k.w"
    awk -F'\t' -v OFS='\t' -v f="$f" 'FILENAME == ARGV[1] { l = substr($0, index($0, "\t") + 1); gsub(/\t/, "\002", l); B[$1] = ($1 in B) ? B[$1] "\001" l : l; next }
      { l = substr($0, index($0, "\t") + 1); gsub(/\t/, "\002", l); if (!($1 in W)) o[++n] = $1; W[$1] = ($1 in W) ? W[$1] "\001" l : l }
      END { for (i = 1; i <= n; i++) { k = o[i]; if (!(k in B)) print "new", f, k, "", W[k]; else if (B[k] != W[k]) print "changed", f, k, B[k], W[k] }
        for (k in B) if (!(k in W)) print "removed", f, k, B[k], "" }' "$T/k.b" "$T/k.w" >> "$T/pl"
  done
  awk -F'\t' -v OFS='\t' '$2 == "DECISIONS.md" { print $1, $3, $5 }' "$T/pl" > "$T/dd"
  awk -F'\t' '$1 == "new" { print $2 }' "$T/dd" > "$T/newd"
  # the map: `C<TAB>file<TAB>where`, `L<TAB>file<TAB>where`, `O`, or `X<TAB>the line`
  awk -v OFS='\t' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    { sub(/\r$/, ""); l = tr($0) } l == "" || l ~ /^#/ { next }
    l ~ /^open:/ { if (tr(substr(l, 6)) == "") print "X", l; else print "O"; next }
    l ~ /^left:/ { r = substr(l, 6); i = index(r, " | "); f = tr(substr(r, 1, i - 1)); r = substr(r, i + 3); j = index(r, " | ")
      if (!i || !j || f == "" || tr(substr(r, 1, j - 1)) == "" || tr(substr(r, j + 3)) == "") print "X", l; else print "L", f, tr(substr(r, 1, j - 1)); next }
    { i = index(l, " | "); f = tr(substr(l, 1, i - 1)); r = substr(l, i + 3); j = index(r, " | "); w = tr(substr(r, 1, j - 1)); r = substr(r, j + 3)
      a = index(r, " | change:"); c = substr(r, a + 3); b = index(c, " | record:")
      if (!i || !j || f == "" || w == "" || r !~ /^today:/ || !a || !b || tr(substr(r, 7, a - 7)) == "" || tr(substr(c, 8, b - 8)) == "" || tr(substr(c, b + 10)) == "") print "X", l
      else print "C", f, w }' "$MAP" > "$T/mp"
  : > "$T/bad"; bad() { printf '%s\n' "$*" >> "$T/bad"; }
  awk -F'\t' '$1 == "X" { print "a map line of no form: " $2 }' "$T/mp" >> "$T/bad"
  has() { awk -F'\t' -v k="$1" -v f="$2" -v w="${3:-}" '$1 == k && $2 == f && (w == "" || $3 == w) { x = 1 } END { exit !x }' "$T/mp"; }
  # every change on the map
  while IFS= read -r f; do has C "$f" || bad "$f changes, and no change line of the map names it"; done < "$T/changed"
  while IFS='	' read -r k f id _b _w; do has C "$f" "$id" || bad "$id of $f is $k, and the map has no change line $f | $id"; done < "$T/pl"
  # an old decision line gains a label or a mark, nothing else; none is removed (DECISIONS.md is append-only)
  awk -F'\t' '$2 == "DECISIONS.md" && $1 != "new"' "$T/pl" | while IFS='	' read -r k _f id ob nw; do
    if [ "$k" = removed ]; then bad "decision line $id is removed: DECISIONS.md is append-only"
    elif [ "$(printf '%s\n' "$ob" | bare)" != "$(printf '%s\n' "$nw" | bare)" ]; then bad "decision line $id: its words change; an old line gains a label or a replaced-by: mark, nothing else"; fi
  done
  # and nothing on the map the amendment leaves as it was
  awk -F'\t' '$1 == "C" { print $2 "\t" $3 }' "$T/mp" | while IFS='	' read -r f w; do
    case " $SPECF " in *" $f "*) ;; *) bad "the map's change line names $f, which is not a spec file"; continue ;; esac
    grep -qxF "$f" "$T/changed" || { bad "the map changes $f | $w, and the amendment leaves $f as it was"; continue; }
    case "$f" in DECISIONS.md|INVENTORY.md|PRD.md) if printf '%s\n' "$w" | grep -qE '^[A-Z]+-[0-9]+$'; then
      awk -F'\t' -v f="$f" -v d="$w" '$2 == f && $3 == d { x = 1 } END { exit !x }' "$T/pl" || bad "the map changes $f | $w, and the amendment leaves $w as it was"; fi ;; esac
  done
  # each new decision line: the cite in its why:, enforced: convention
  awk -F'\t' '$1 == "new" { print $2 "\t" $3 }' "$T/dd" | while IFS='	' read -r id l; do
    printf '%s\n' "$l" | awk -F'|' -v cf="$T/cites" 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      BEGIN { while ((getline x < cf) > 0) if (x != "") C[++n] = x }
      { for (i = 2; i <= NF; i++) { f = tr($i); if (f ~ /^why:/) for (k = 1; k <= n; k++) if (index(f, C[k])) w = 1 } } END { exit !w }' || bad "new decision line $id: its why: holds no cite of the record ($(paste -sd ' ' "$T/cites"))"
    e=$(printf '%s\n' "$l" | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } { for (i = 2; i <= NF; i++) { f = tr($i); if (f ~ /^enforced:/) { sub(/^enforced:[ \t]*/, "", f); print f; exit } } }')
    [ "$e" = convention ] || bad "new decision line $id: its enforced: is \"$e\", not convention (its rows land after it)"
  done
  # the rows
  if [ "$TEXT" = yes ]; then
    ! grep -qxF INVENTORY.md "$T/changed" || bad 'INVENTORY.md changes in the first part: the rows come after the spec text has landed'
  else
    # the new and changed rows, every kind, each `<new|changed><TAB><id><TAB><derived-from><TAB><origin>`: a ROW's
    # derived-from its field; another kind has none, its requirements in its origin (a rule row's after the decision)
    awk -F'\t' '$2 == "INVENTORY.md" && $1 != "removed" { print $1 "\t" $5 }' "$T/pl" | awk -F'\t' -v OFS='\t' '
      function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      { st = $1; v = $2; gsub(/\002/, "\t", v); n = split(v, f, "|"); a = tr(f[1]); id = (a ~ /^[A-Z]+-[0-9]+$/) ? a : tr(f[2]); og = ""
        for (i = 3; i <= n; i++) { x = tr(f[i]); if (x ~ /^origin:/) og = x }
        print st, id, (id ~ /^ROW-/ ? tr(f[7]) : ""), og }' > "$T/rows"
    awk -F'\t' -v OFS='\t' -v ND="$T/newd" '
      BEGIN { while ((getline l < ND) > 0) N[l] = 1 }
      function did(src, id,   m, a, k, dd, rq) { m = split(src, a, /[ ,]+/); dd = ""; rq = 0
        for (k = 1; k <= m; k++) { if (a[k] ~ /^D-[0-9]+$/) dd = dd " " a[k]; else if (a[k] ~ /^[A-Z]+-[0-9]+$/) rq++ }
        if (dd != "") { print "bad", id " derives from a decision id (" substr(dd, 2) "): a row derives from requirements"; return -1 }
        return rq }
      { st = $1; id = $2; og = $4; inc = (og ~ /^origin: incorporation [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] D-[0-9]+( |$)/)
        tail = ""; d = ""; if (inc) { n = split(og, t, /[ ,]+/); d = t[4]; for (k = 5; k <= n; k++) tail = tail " " t[k]; tail = substr(tail, 2) }
        else if (og != "") { tail = og; sub(/^origin:[ \t]*/, "", tail) }
        if (st == "changed") { did((id ~ /^ROW-/) ? $3 : tail, id); next }
        if (!inc) { print "bad", id " carries no origin: incorporation <YYYY-MM-DD> D-NNN" (og == "" ? "" : " (it has \"" og "\")"); next }
        if (id ~ /^ROW-/ && tail != "") { print "bad", id "'"'"'s origin goes past its decision (" tail "): a row names its requirements in derived-from"; next }
        rq = did((id ~ /^ROW-/) ? $3 : tail, id)
        if (rq == 0 && id ~ /^(ROW|RULE)-/) print "bad", id " derives from no requirement id" (id ~ /^RULE-/ ? " (a rule row names it after the decision in its origin)" : "")
        if (!(d in N)) print "bad", id "'"'"'s origin names " d ", which is no new decision line of this amendment"
        else print "reach", d }' "$T/rows" > "$T/rw"
    awk -F'\t' '$1 == "bad" { print "row " $2 }' "$T/rw" >> "$T/bad"
    while IFS= read -r d; do
      awk -F'\t' -v d="$d" '$1 == "reach" && $2 == d { x = 1 } END { exit !x }' "$T/rw" || awk -F'\t' -v d="$d" '$1 == "L" && $3 == d { x = 1 } END { exit !x }' "$T/mp" \
        || bad "new decision line $d: no new row's origin names it, and no left: line of the map does"
    done < "$T/newd"
  fi
  if [ -s "$T/bad" ]; then
    echo 'ViD incorporate: refused — the amendment and its map differ:' >&2; sed 's/^/    /' "$T/bad" >&2; exit 1; fi
  echo "map: $(grep -c '^C' "$T/mp" || true) changes, $(grep -c '^L' "$T/mp" || true) left, $(grep -c '^O' "$T/mp" || true) open"
}

case "$CMD" in
  cite) cmd_cite "$@" ;;
  mark) cmd_mark "$@" ;;
  check) cmd_check "$@" ;;
  *) usage ;;
esac
