#!/bin/sh
# Purpose: ViD court — design citation, marker unit (never the filename).
# Every rule block in an app stylesheet falls under a preceding comment citing
# a pack marker as ID/state (section comments sectionize; the successful field
# build's 48 cited blocks are the model). With --strict, every unresolved pack
# marker must additionally be cited by at least one rule or template — the
# completion bar checks/coverage.sh --strict shares. Presence-gated: inactive
# until the design pack carries @screen markers.
# Usage: sh checks/design-cite.sh [--strict]
set -eu
IFS='
'

STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

PACK=''
if [ -d design/screens ]; then PACK=design/screens; elif [ -d design ]; then PACK=design; fi
MARKERS=''
if [ -n "$PACK" ]; then
  for f in "$PACK"/*.html; do
    [ -f "$f" ] || continue
    for m in $(grep -oE '<!--[[:space:]]*@screen[[:space:]]+[^>]*-->' "$f" || true); do
      id=$(printf '%s\n' "$m" | sed -E 's/.*@screen[[:space:]]+([A-Za-z0-9_-]+).*/\1/')
      state=default
      case "$m" in *state=*) state=$(printf '%s\n' "$m" | sed -E 's/.*state=([A-Za-z0-9_-]+).*/\1/') ;; esac
      MARKERS="$MARKERS$id/$state
"
    done
  done
fi
MARKERS=$(printf '%s' "$MARKERS" | sort -u || true)
# Presence-gated: silent when the pack carries no markers — courts speak only
# to reject or report.
[ -n "$MARKERS" ] || exit 0

# Markers resolved in the manifest (owed/descoped/fenced) carry no citation
# obligation; everything else must be built and cited.
UNRESOLVED=$MARKERS
if [ -f DESIGN-BRIEF.md ]; then
  RESOLVED=$(sed -n '/^```vid-design-manifest/,/^```$/p' DESIGN-BRIEF.md | sed '1d;$d' \
    | grep -E '\|[[:space:]]*(owed|descoped|fenced|later):' \
    | sed -E 's/^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*\|[[:space:]]*([A-Za-z0-9_-]+).*/\1\/\2/' || true)
  for r in $RESOLVED; do
    UNRESOLVED=$(printf '%s\n' "$UNRESOLVED" | grep -vxF "$r" || true)
  done
fi

[ -f CLAUDE.md ] || { echo 'ViD design-cite: CLAUDE.md missing — failing closed.' >&2; exit 1; }
PREFIXES=$(sed -n '/^```vid-placement/,/^```$/p' CLAUDE.md | sed '1d;$d' | sed 's/[[:space:]]*$//' | grep -v '^$' || true)
[ -n "$PREFIXES" ] || { echo 'ViD design-cite: no ```vid-placement block in CLAUDE.md — failing closed.' >&2; exit 1; }

MTMP=$(mktemp); printf '%s\n' "$MARKERS" > "$MTMP"
trap 'rm -f "$MTMP"' EXIT

# Part A — every rule block in an app stylesheet is under a marker citation.
FAIL=0
for p in $PREFIXES; do
  case "$p" in tests*|checks*|design*) continue ;; esac
  [ -e "$p" ] || continue
  for css in $(find "$p" -type f -name '*.css' 2>/dev/null); do
    BAD=$(awk -v markers="$MTMP" '
      BEGIN { while ((getline line < markers) > 0) if (line != "") marks[line] = 1; cited = 0; depth = 0; incomment = 0 }
      {
        line = $0
        # comments: a citation comment mentions at least one pack marker
        # ID/state. Sections run comment-to-comment: a NEW comment redefines
        # the citation state, so a non-citing comment ENDS a cited section —
        # one citation can never legalise a whole stylesheet.
        scan = line
        if (index(scan, "/*") > 0 && !incomment) cited = 0
        if (incomment || index(scan, "/*") > 0) {
          for (tok in marks) if (index(scan, tok) > 0) cited = 1
          if (incomment) { if (index(scan, "*/") > 0) { incomment = 0; sub(/.*\*\//, "", line) } else next }
          while (index(line, "/*") > 0) {
            pre = substr(line, 1, index(line, "/*") - 1)
            rest = substr(line, index(line, "/*") + 2)
            if (index(rest, "*/") > 0) line = pre substr(rest, index(rest, "*/") + 2)
            else { line = pre; incomment = 1 }
          }
        }
        n = length(line)
        for (i = 1; i <= n; i++) {
          c = substr(line, i, 1)
          if (c == "{") { if (depth == 0 && !cited) { print FNR; exit } ; depth++ }
          else if (c == "}") { if (depth > 0) depth-- }
        }
      }' "$css" || true)
    if [ -n "$BAD" ]; then
      echo "ViD design-cite: rejected — '$css' line $BAD: rule block with no preceding marker citation." >&2
      echo '    Cite the canvas section it transcribes, e.g. /* Result cards (P02/populated — REQ-030) */' >&2
      FAIL=1
    fi
  done
done

# Part B — every unresolved pack marker cited by at least one rule or template.
GAPS=0
for tok in $UNRESOLVED; do
  CITED=no
  for p in $PREFIXES; do
    case "$p" in tests*|checks*|design*) continue ;; esac
    [ -e "$p" ] || continue
    grep -rqF "$tok" --exclude='*.md' "$p" 2>/dev/null && { CITED=yes; break; }
  done
  if [ "$CITED" = no ]; then
    echo "GAP  marker $tok drawn but cited by no rule or template"
    GAPS=$((GAPS + 1))
  fi
done

TOTAL=$(printf '%s\n' "$MARKERS" | grep -c . || true)
echo ''
echo "markers: $TOTAL   uncited (unresolved): $GAPS"
if [ "$FAIL" -ne 0 ]; then exit 1; fi
if [ "$STRICT" -eq 1 ] && [ "$GAPS" -gt 0 ]; then
  echo 'ViD design-cite --strict: not done — every drawn marker is cited, or its manifest row is resolved.' >&2
  exit 1
fi
exit 0
