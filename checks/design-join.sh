#!/bin/sh
# Purpose: ViD court — design import reconciliation, fail-closed. Compares the
# brief's manifest (```vid-design-manifest block: screen | state | REQs
# [| resolution]) against the @screen markers in the returned pack
# (<!-- @screen ID state=S reqs=REQ-… -->) and prints the four delta classes:
# missing surface | missing state | extra | untraceable. Exits nonzero while
# any row is unresolved — ratification cannot close over an unresolved delta.
# Resolutions are owner acts recorded in the manifest row's 4th field:
# "owed: <reason>" | "descoped: <PRD append ref>" | "fenced: <fence ref>" |
# "later: <the later item(s)>" (v0.9.1 3.6, R13: a drawn screen serving
# only `later` items is resolved, not a delta). Under a brief carrying the
# header line `grammar: 0.9.1` (v0.9.1 3.7): every manifest row names its
# `pins:` (the measurable properties the row's test reads) and the manifest
# carries the components canvas's rows (`C00 | <state> | …`) — a row without
# pins or a manifest without C00 is a delta; a pre-0.9.1 brief is reported.
# One more refusal (v0.9.1 3.3): a DESIGN-AMENDMENT-BRIEF.md beside the brief
# whose ```vid-design-amendments block carries an unruled line (status: open)
# or a `PRD wins` / `both change` line not yet `landed` (the design change
# not re-imported) exits nonzero — ratification cannot close over it.
# Element identifiers (v0.9.2 3.4, R20): under a brief carrying
# `grammar: 0.9.2` every canvas element carrying an inline style carries
# `data-element="<role>"`, unique within its section (the text from one
# @screen marker to the next) — a styled element without one is the delta
# `no identifier`, a repeated one `duplicate identifier`; the identifiers
# are what the surface instrument measures, and an element without one is
# visible only to the fidelity grader. A 0.9.1 or earlier brief is reported
# in one line, never convicted.
# One canvas per screen (v0.9.8.1 R20): a pack whose design/screens/index.json declares `"layout": "per-screen"`
# — `"files"`, every file of the pack, and `"components"`, per screen, the component group files it uses
# (`{"P03": ["C00-forms.dc.html"]}`) — is judged further: each manifest screen other than the component groups
# (C00) has its own file, named by its marker (`P03 <name>.dc.html`), holding its markers, unless every row of that
# screen is resolved (owed, descoped, fenced, later); and every file the index lists exists. A pack with no index
# declaring the layout — every existing pack, the self-test fixtures — is judged as before.
# `sh checks/design-join.sh --index [pack-dir]` prints the index as lines — `layout <value>`, `file <name>`,
# `component <screen> <file>` — for the brief writer; nothing for a pack without index.json.
# Usage: sh checks/design-join.sh [brief.md] [pack-dir] | --index [pack-dir]
set -eu
IFS='
'
# dindex <pack>: index.json as lines (a small reader of the index's own grammar: string values, arrays, one object)
dindex() {
  [ -f "$1/index.json" ] || return 0
  tr '\n\t' '  ' < "$1/index.json" | awk '{ s = $0; n = 0
      while (length(s)) { c = substr(s, 1, 1)
        if (c == "\"") { s = substr(s, 2); v = ""; while (length(s) && substr(s, 1, 1) != "\"") { if (substr(s, 1, 1) == "\\") { v = v substr(s, 2, 1); s = substr(s, 3) } else { v = v substr(s, 1, 1); s = substr(s, 2) } }
          s = substr(s, 2); T[++n] = "s" v; continue }
        if (index("[]{}:,", c)) T[++n] = c; s = substr(s, 2) }
      key = ""; d = 0; sc = ""
      for (i = 1; i <= n; i++) { t = T[i]
        if (t == "{" || t == "[") { d++; continue } if (t == "}" || t == "]") { d--; if (d == 1) { key = ""; sc = "" } if (d == 2 && key == "components") sc = ""; continue }
        if (t == ":" || t == ",") continue
        v = substr(t, 2)
        if (d == 1) { if (T[i + 1] == ":") key = v; else if (key == "layout") print "layout " v; continue }
        if (d == 2 && key == "files") { print "file " v; continue }
        if (d == 2 && key == "components" && T[i + 1] == ":") { sc = v; continue }
        if (d == 3 && key == "components" && sc != "") print "component " sc " " v } }'
}
if [ "${1:-}" = --index ]; then P=${2:-design/screens}; dindex "$P"; exit 0; fi

BRIEF=${1:-DESIGN-BRIEF.md}
PACK=${2:-}
if [ -z "$PACK" ]; then
  if [ -d design/screens ]; then PACK=design/screens; else PACK=design; fi
fi

[ -f "$BRIEF" ] || { echo "ViD design-join: brief '$BRIEF' missing — failing closed." >&2; exit 1; }
[ -d "$PACK" ] || { echo "ViD design-join: pack directory '$PACK' missing — failing closed." >&2; exit 1; }

field() { printf '%s\n' "$1" | cut -d'|' -f"$2" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

GRAMMAR=$(awk '/^## /{exit} /^grammar:[ \t]*[0-9.]+[ \t]*$/{sub(/^grammar:[ \t]*/,""); sub(/[ \t]*$/,""); print; exit}' "$BRIEF")
[ -n "$GRAMMAR" ] || GRAMMAR=legacy
MANIFEST=$(sed -n '/^```vid-design-manifest/,/^```$/p' "$BRIEF" | sed '1d;$d' | grep -v '^[[:space:]]*$' | grep -v '^#' || true)
if [ -z "$MANIFEST" ]; then
  echo "ViD design-join: no \`\`\`vid-design-manifest block in '$BRIEF' — failing closed." >&2
  echo 'The brief emits the manifest at derivation; the join cannot run without it.' >&2
  exit 1
fi

# --- the amendment brief (v0.9.1 3.3): unruled or un-landed lines refuse ---
labeled() { printf '%s\n' "$1" | tr '|' '\n' | sed -n 's/^[[:space:]]*'"$2"':[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]]*$//'; }
AMEND="$(dirname "$BRIEF")/DESIGN-AMENDMENT-BRIEF.md"
if [ -f "$AMEND" ]; then
  if ! grep -q '^```vid-design-amendments' "$AMEND"; then
    echo "ViD design-join: '$AMEND' carries no \`\`\`vid-design-amendments block — failing closed (the sitting writes its rulings there, one row per line the consistency pass returned)." >&2
    exit 1
  fi
  AROWS=$(sed -n '/^```vid-design-amendments/,/^```$/p' "$AMEND" | sed '1d;$d' | grep -v '^[[:space:]]*$' | grep -v '^[[:space:]]*#' || true)
  ABAD=0
  for row in $AROWS; do
    aid=$(field "$row" 1); ruling=$(labeled "$row" ruling); status=$(labeled "$row" status)
    case "$status" in
      open) echo "ViD design-join: amendment brief line $aid is unruled (status: open) — the owner rules it (design wins · PRD wins · both change · not a disagreement) before ratification." >&2; ABAD=1 ;;
      ruled) case "$ruling" in
               'PRD wins'|'both change') echo "ViD design-join: amendment brief line $aid is ruled '$ruling' but not landed — the design change is re-imported and the consistency pass re-run empty before ratification." >&2; ABAD=1 ;;
               'design wins'|'not a disagreement') ;;
               *) echo "ViD design-join: amendment brief line $aid: unknown ruling '$ruling'." >&2; ABAD=1 ;;
             esac ;;
      landed) ;;
      *) echo "ViD design-join: amendment brief line $aid: unknown status '$status' — open · ruled · landed." >&2; ABAD=1 ;;
    esac
  done
  if [ "$ABAD" -ne 0 ]; then
    echo 'ViD design-join: the amendment brief is not closed — ratification cannot close over it (the same standing as an unresolved join delta).' >&2
    exit 1
  fi
fi

# Markers in the pack: one line per marker, "id/state<TAB>reqs".
MARKERS=''
for f in "$PACK"/*.html; do
  [ -f "$f" ] || continue
  for m in $(grep -oE '<!--[[:space:]]*@screen[[:space:]]+[^>]*-->' "$f" || true); do
    id=$(printf '%s\n' "$m" | sed -E 's/.*@screen[[:space:]]+([A-Za-z0-9_-]+).*/\1/')
    state=default
    case "$m" in *state=*) state=$(printf '%s\n' "$m" | sed -E 's/.*state=([A-Za-z0-9_-]+).*/\1/') ;; esac
    reqs=''
    case "$m" in *reqs=*) reqs=$(printf '%s\n' "$m" | sed -E 's/.*reqs=([A-Za-z0-9,_-]+).*/\1/') ;; esac
    MARKERS="$MARKERS$id/$state	$reqs
"
  done
done
MARKERS=$(printf '%s' "$MARKERS" | sort -u || true)
[ -n "$MARKERS" ] && MARKERS="$MARKERS
"

DELTAS=0
delta() { printf '%-16s  %-24s  %s\n' "$1" "$2" "$3"; DELTAS=$((DELTAS + 1)); }
printf '%-16s  %-24s  %s\n' 'delta' 'row' 'resolutions (owner, per row)'

ROWS=0; RESOLVED=0; NOPINS=0
for row in $MANIFEST; do
  id=$(field "$row" 1); state=$(field "$row" 2); reqs=$(field "$row" 3)
  [ -n "$id" ] || continue
  ROWS=$((ROWS + 1))
  # trailing labeled fields, any order: one resolution (owed:/descoped:/fenced:/later:) and pins:
  res=''; bad=''
  for f in $(printf '%s\n' "$row" | tr '|' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed -n '4,$p' | grep -v '^$'); do
    case "$f" in owed:*|descoped:*|fenced:*|later:*) res=$f ;; pins:*) ;; *) bad=$f ;; esac
  done
  if [ -z "$(labeled "$row" pins)" ]; then
    if [ "$GRAMMAR" = legacy ]; then echo "note: $id/$state carries no pins: (pre-0.9.1 brief, reported — v0.9.1 3.7b)"
    else delta 'no pins' "$id/$state" 'pins: the two or three measurable properties the row test reads, as constraints'; fi
    NOPINS=$((NOPINS + 1))
  fi
  if [ -n "$bad" ]; then delta 'bad resolution' "$id/$state" "'$bad' — use owed:/descoped:/fenced:/later: with a reason, or pins:"; continue; fi
  case "$res" in
    owed:*|descoped:*|fenced:*|later:*) RESOLVED=$((RESOLVED + 1)); continue ;;
  esac
  if printf '%s' "$MARKERS" | grep -q "^$id/$state	"; then
    continue
  elif printf '%s' "$MARKERS" | grep -q "^$id/"; then
    delta 'missing state' "$id/$state" 'draw it · descope (PRD append) · owed: <reason>'
  else
    delta 'missing surface' "$id/$state" 'draw it · descope (PRD append) · owed: <reason>'
  fi
done

# the components canvas (v0.9.1 3.7a): C00's rows are ordinary rows the manifest must carry under 0.9.1
if ! printf '%s\n' "$MANIFEST" | grep -qE '^[[:space:]]*C00[[:space:]]*\|'; then
  if [ "$GRAMMAR" = legacy ]; then echo 'note: the manifest carries no C00 rows (pre-0.9.1 brief, reported — v0.9.1 3.7a)'
  else delta 'no components canvas' 'C00/*' 'the pack contains one components canvas: shared elements as states under the ordinary marker'; fi
fi

MCOUNT=0
for m in $MARKERS; do
  tok=${m%%	*}; mreqs=${m#*	}
  MCOUNT=$((MCOUNT + 1))
  id=${tok%%/*}; state=${tok#*/}
  row=$(printf '%s\n' "$MANIFEST" | grep -E "^[[:space:]]*$id[[:space:]]*\|[[:space:]]*$state[[:space:]]*(\||$)" | head -n 1 || true)
  if [ -z "$row" ]; then
    delta 'extra' "$tok" 'adopt → new REQ + Fail-if · drop from pack · fence'
    continue
  fi
  rreqs=$(field "$row" 3)
  case "$mreqs$rreqs" in
    *REQ-*) ;;
    *) delta 'untraceable' "$tok" 'owner names the REQs · session proposes, owner confirms' ;;
  esac
done

# v0.9.8.1 (R20): one canvas per screen, only under an index declaring the layout
LAYOUT=$(dindex "$PACK" | sed -n 's/^layout //p' | head -n 1)
if [ "$LAYOUT" = per-screen ]; then
  for lf in $(dindex "$PACK" | awk '$1 == "file" { print substr($0, 6) } $1 == "component" { sub(/^component [^ ]+ /, ""); print }' | sort -u); do
    [ -f "$PACK/$lf" ] || delta 'index file missing' "$lf" 'design/screens/index.json lists it: add the file, or drop it from the index'
  done
  for sid in $(printf '%s\n' "$MANIFEST" | awk -F'|' '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x != "" && x != "C00") print x }' | sort -u); do
    open=$(printf '%s\n' "$MANIFEST" | awk -F'|' -v id="$sid" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x != id) next; r = 0
        for (i = 4; i <= NF; i++) { f = $i; gsub(/^[ \t]+/, "", f); if (f ~ /^(owed|descoped|fenced|later):/) r = 1 } if (!r) n++ } END { print n + 0 }')
    [ "$open" -gt 0 ] || continue
    own=''; for f in "$PACK/$sid "*.dc.html "$PACK/$sid.dc.html"; do [ -f "$f" ] && grep -qE "@screen[[:space:]]+$sid([^A-Za-z0-9_-]|\$)" "$f" && own=$f; done
    [ -n "$own" ] || delta 'no own file' "$sid/*" "the per-screen layout: draw $sid in its own file, \"$sid <name>.dc.html\", holding its markers"
  done
fi

# element identifiers (v0.9.2 3.4): every styled element inside a marked section names its role
STYLED=0; NOID=0; DUPID=0
for f in "$PACK"/*.html; do
  [ -f "$f" ] || continue
  base=${f##*/}
  for l in $(awk 'BEGIN { RS = "<"; line = 1; marker = "" }
    {
      rec = $0; at = line; n = gsub(/\n/, "\n", rec); line += n
      if (rec ~ /^!--[ \t]*@screen[ \t]/) {
        id = rec; sub(/^!--[ \t]*@screen[ \t]+/, "", id); sub(/[^A-Za-z0-9_-].*/, "", id)
        st = "default"; if (match(rec, /state=[A-Za-z0-9_-]+/)) st = substr(rec, RSTART + 6, RLENGTH - 6)
        marker = id "/" st; split("", seen); next
      }
      if (marker == "") next
      if (rec !~ /^[A-Za-z][A-Za-z0-9-]*([ \t\n]|>|$)/) next
      head = rec; if (index(head, ">") > 0) head = substr(head, 1, index(head, ">") - 1)
      if (head !~ /(^|[ \t\n])style[ \t]*=/) next
      tag = head; sub(/[ \t\n].*/, "", tag)
      if (head !~ /(^|[ \t\n])data-element[ \t]*=/) { print "noid\t" marker "\t" tag "\t" at; next }
      ident = head; sub(/.*data-element[ \t]*=[ \t]*/, "", ident); q = substr(ident, 1, 1)
      if (q == "\"" || q == "\047") { ident = substr(ident, 2); sub(q ".*", "", ident) } else sub(/[ \t\n].*/, "", ident)
      if (ident in seen) { print "dup\t" marker "\t" ident "\t" at; next }
      seen[ident] = 1; print "ok\t" marker "\t" ident "\t" at
    }' "$f"); do
    kind=${l%%	*}; rest=${l#*	}; mk=${rest%%	*}; rest=${rest#*	}; what=${rest%%	*}; at=${rest#*	}
    STYLED=$((STYLED + 1))
    case "$kind" in
      noid) NOID=$((NOID + 1))
            case "$GRAMMAR" in legacy|0.9.1) ;; *) delta 'no identifier' "$mk" "<$what> at $base:$at carries an inline style and no data-element=\"<role>\" (unique within the section; the instrument measures by it)" ;; esac ;;
      dup)  DUPID=$((DUPID + 1))
            case "$GRAMMAR" in legacy|0.9.1) ;; *) delta 'duplicate identifier' "$mk" "data-element=\"$what\" appears twice in the section (at $base:$at) — one role, one identifier" ;; esac ;;
    esac
  done
done
if [ $((NOID + DUPID)) -gt 0 ]; then
  case "$GRAMMAR" in legacy|0.9.1) echo "note: $NOID styled element(s) without data-element and $DUPID duplicate(s) across the pack's sections (pre-0.9.2 brief, reported — v0.9.2 3.4)" ;; esac
fi

echo ''
echo "manifest rows: $ROWS (resolved: $RESOLVED, without pins: $NOPINS)   pack markers: $MCOUNT   unresolved deltas: $DELTAS   grammar: $GRAMMAR"
echo "identifiers: styled elements=$STYLED without identifier=$NOID duplicates=$DUPID"
if [ "$MCOUNT" -eq 0 ]; then
  echo 'ViD design-join: the pack carries NO @screen markers — the join fails immediately.' >&2
  echo 'Every screen × state carries a marker (brief return contract); the row list above names what is required.' >&2
  exit 1
fi
if [ "$DELTAS" -gt 0 ]; then
  echo 'ViD design-join: unresolved deltas — ratification cannot close. Resolve each row (owner act) and re-run.' >&2
  exit 1
fi
echo 'ViD design-join: clean — every required surface x state is drawn or resolved, every marker traceable.'
exit 0
