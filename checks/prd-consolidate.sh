#!/bin/sh
# Purpose: ViD consolidation — the mechanical copy (v0.9.1 spec 3.4, 7a). A
# script, no model. Rewrites PRD.md as its effective content, history
# relocated: header with the grammar line — the input's own when it is 0.9.4
# or later (v0.9.4 3.9), `grammar: 0.9.1` otherwise, the migration — and
# `Seed: SEED.md (sha256 <hash>)`
# (the seed text moved verbatim to SEED.md, created once, hash verified and
# never rewritten); Sources, Thesis, Actors and journeys, Mechanisms, Content
# contract and Criticality tiers verbatim; `## Items` holding exactly the
# effective rows (latest per id, AMENDED marker stripped, ordered by first
# appearance — prd.sh's EFF computation), each row given `phase: pilot` when
# absent and its legacy priority column removed (3.6, 3.8), preceded by one
# ```vid-prd-features block of the effective feature rows (base and appends,
# latest per id, AMENDED stripped; v0.9.4 3.9) — the features fences found
# in `## Items` are removed, so the base block is never copied twice; `## Answer
# ledger` holding the effective rulings without their `Q:` text; `## Open
# decisions` holding every open carrier and every RESOLVED one-liner (a
# resolved carrier is law, not history — R12-ii); Findings and Ratifications
# untouched; Appends emptied to its comment. PRD-HISTORY-<date>.md keeps,
# verbatim and in order, the base's rows and rulings as first written, the
# open-decisions prose and every append section; .vid/consolidation-arms-
# <date>.md lists, per amended item, its fail-if arms at first ratified text
# and at consolidated text side by side, flagged arm-losing (fewer arms) or
# arm-changed (an arm of the first text no longer found) — 7b reads it. Byte-level
# reproducible; refuses to write unless checks/prd.sh passes on the output.
# 7a can only produce UNCHANGED rows and CHANGED-by-field-removal rows —
# anything else is a script defect and refuses.
# Usage: sh checks/prd-consolidate.sh [PRD.md] [--date YYYY-MM-DD]
set -eu
IFS='
'
PRD=./PRD.md; DATE=''
while [ $# -gt 0 ]; do
  case "$1" in --date) DATE=$2; shift 2 ;; *) PRD=$1; shift ;; esac
done
[ -n "$DATE" ] || DATE=$(date -u +%Y-%m-%d)
[ -f "$PRD" ] || { echo "ViD consolidate: '$PRD' missing." >&2; exit 1; }
grep -q '^```vid-prd$' "$PRD" || { echo 'ViD consolidate: no ```vid-prd block — only the enriched grammar consolidates.' >&2; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd); COURT="$HERE/prd.sh"
[ -f "$COURT" ] || { echo "ViD consolidate: $COURT missing — the court gates every write." >&2; exit 1; }
DIR=$(cd "$(dirname "$PRD")" && pwd); BASE=$(basename "$PRD")
sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }

# sect NAME: the section's lines from its heading to the line before the next ## heading.
sect() { awk -v h="## $1" '$0 == h { on = 1; print; next } on && /^## / { on = 0 } on { print }' "$PRD"; }
has_sect() { grep -qx "## $1" "$PRD"; }
blk() { sed -n "/^\`\`\`$1\$/,/^\`\`\`\$/p" "$PRD" | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true; }
trim() { printf '%s\n' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

for s in Items 'Answer ledger' 'Open decisions' Findings Ratifications Appends; do
  has_sect "$s" || { echo "ViD consolidate: no '## $s' section — the enriched layout is required." >&2; exit 1; }
done

GRAMMAR=$(awk '/^## /{exit} /^grammar:[ \t]*[0-9.]+[ \t]*$/{sub(/^grammar:[ \t]*/,""); sub(/[ \t]*$/,""); print; exit}' "$PRD")
[ -n "$GRAMMAR" ] || GRAMMAR=legacy
# v0.9.4 3.9: the output keeps a grammar at or past 0.9.4; everything older migrates to 0.9.1.
OUTGRAMMAR=0.9.1
[ "$GRAMMAR" = legacy ] || OUTGRAMMAR=$(printf '%s\n' "$GRAMMAR" | awk -F. '{ split("0.9.4", w, ".")
  for (i = 1; i <= 3; i++) { a = $i + 0; if (a > w[i] + 0) { print $0; exit } if (a < w[i] + 0) { print "0.9.1"; exit } }
  print $0 }')

# --- the seed: section → SEED.md, or an existing pointer verified ----------
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
SEEDPTR=$(awk '/^## /{exit} /^Seed:[ \t]+[^ \t]+[ \t]+\(sha256 [0-9a-f]+\)/{print; exit}' "$PRD")
if has_sect Seed; then
  sect Seed | sed '1d' > "$T/SEED.md"
  SEEDHASH=$(sha256 "$T/SEED.md")
  if [ -f "$DIR/SEED.md" ]; then
    [ "$(sha256 "$DIR/SEED.md")" = "$SEEDHASH" ] || { echo "ViD consolidate: $DIR/SEED.md exists with different content from the '## Seed' section — the seed is never rewritten; refusing." >&2; exit 1; }
    WRITE_SEED=no
  else WRITE_SEED=yes; fi
elif [ -n "$SEEDPTR" ]; then
  SEEDFILE=$(printf '%s\n' "$SEEDPTR" | sed -E 's/^Seed:[ \t]+([^ \t]+).*/\1/')
  [ "$SEEDFILE" = SEED.md ] || { echo "ViD consolidate: the Seed: line points at '$SEEDFILE'; this script keeps the seed in SEED.md." >&2; exit 1; }
  [ -f "$DIR/SEED.md" ] || { echo "ViD consolidate: the Seed: line points at SEED.md, which is missing beside the PRD." >&2; exit 1; }
  SEEDHASH=$(sha256 "$DIR/SEED.md")
  [ "$SEEDHASH" = "$(printf '%s\n' "$SEEDPTR" | sed -E 's/.*\(sha256 ([0-9a-f]+)\).*/\1/')" ] || { echo "ViD consolidate: SEED.md's sha256 differs from the Seed: line — the seed is never edited; refusing." >&2; exit 1; }
  WRITE_SEED=no
else
  echo "ViD consolidate: neither a '## Seed' section nor a Seed: pointer line." >&2; exit 1
fi

# --- header: title, grammar line, seed pointer, then the rest verbatim ------
HEADER=$(awk '/^## /{exit} {print}' "$PRD" | grep -vE '^(grammar:|Seed:)' || true)
TITLE=$(printf '%s\n' "$HEADER" | sed -n '1p')
HEADER_REST=$(printf '%s\n' "$HEADER" | sed '1d')

# --- the verbatim middle: after the seed section (or the header) up to ## Items
MIDDLE=$(awk '
  BEGIN { started = 0; inseed = 0 }
  /^## Seed$/ { inseed = 1; next }
  /^## / { if ($0 == "## Items") stop = 1; if (!started) started = 1; inseed = 0 }
  started && !inseed && !stop { print }' "$PRD")

# --- items: the effective rows, four fields, phase: pilot when absent -----
ITEMS_RAW=$(blk vid-prd)
EFF=$(printf '%s\n' "$ITEMS_RAW" | awk -F'|' '{
  id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id);
  rest=$0; sub(/^[^|]*\|/,"",rest); row[id]=id " |" rest;
  if (!(id in seen)) { order[++n]=id; seen[id]=1 }
} END { for (i=1;i<=n;i++) print row[order[i]] }')
FIRST=$(printf '%s\n' "$ITEMS_RAW" | awk -F'|' '{
  id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id);
  if (!(id in seen)) { seen[id]=1; rest=$0; sub(/^[^|]*\|/,"",rest); print id " |" rest }
}')
NAMENDED=$(printf '%s\n' "$ITEMS_RAW" | grep -cE '^[A-Z]+-[0-9]+[[:space:]]+AMENDED[[:space:]]*\|' || true)
# rebuild: trimmed fields joined by " | "; legacy rows lose field 4 (priority)
NEWITEMS=$(printf '%s\n' "$EFF" | awk -F'|' -v legacy="$( [ "$GRAMMAR" = legacy ] && echo 1 || echo 0 )" '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  {
    out = ""; hasphase = 0
    for (i = 1; i <= NF; i++) {
      if (legacy == 1 && i == 4) continue
      f = trim($i)
      if (f ~ /^phase:/) hasphase = 1
      out = (out == "" ? f : out " | " f)
    }
    if (!hasphase) out = out " | phase: pilot"
    print out
  }')
NEFF=$(printf '%s\n' "$EFF" | grep -c . || true); NNEW=$(printf '%s\n' "$NEWITEMS" | grep -c . || true)
[ "$NEFF" -eq "$NNEW" ] || { echo "ViD consolidate: script defect — $NEFF effective rows in, $NNEW out; refusing." >&2; exit 1; }
for i in $(seq 1 "$NEFF"); do
  a=$(printf '%s\n' "$EFF" | sed -n "${i}p" | cut -d'|' -f1); b=$(printf '%s\n' "$NEWITEMS" | sed -n "${i}p" | cut -d'|' -f1)
  [ "$(trim "$a")" = "$(trim "$b")" ] || { echo "ViD consolidate: script defect — row $i changed id ($a → $b); refusing." >&2; exit 1; }
done
ITEMS_SECT=$(sect Items)
# nofeat: a text with every ```vid-prd-features fence (and the blank line after it) removed (3.9).
nofeat() { awk 'skip && /^[ \t]*$/ { skip = 0; next } { skip = 0 } /^```vid-prd-features$/ { inf = 1; next } inf { if ($0 ~ /^```$/) { inf = 0; skip = 1 } next } { print }'; }
ITEMS_PRE=$(printf '%s\n' "$ITEMS_SECT" | awk '/^```vid-prd$/ { stop = 1 } !stop { print }' | nofeat)
ITEMS_POST=$(printf '%s\n' "$ITEMS_SECT" | awk 'BEGIN{inb=0; done=0} done { print; next } /^```vid-prd$/ { inb = 1; next } inb && /^```$/ { done = 1; next }' | nofeat)
# the effective feature rows: base and appends in file order, latest per id, AMENDED stripped.
FEATS=$(blk vid-prd-features | awk -F'|' '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  { id = trim($1); sub(/[ \t]+AMENDED$/, "", id); out = id; for (i = 2; i <= NF; i++) out = out " | " trim($i)
    row[id] = out; if (!(id in seen)) { order[++n] = id; seen[id] = 1 } }
  END { for (i = 1; i <= n; i++) print row[order[i]] }')

# --- answers: the effective rulings without Q: -----------------------------
ANSWERS_RAW=$(blk vid-prd-answers)
AEFF=$(printf '%s\n' "$ANSWERS_RAW" | awk -F'|' '{
  id=$1; gsub(/^[ \t]+|[ \t]+$/,"",id); sub(/[ \t]+AMENDED$/,"",id);
  rest=$0; sub(/^[^|]*\|/,"",rest); row[id]=id " |" rest;
  if (!(id in seen)) { order[++n]=id; seen[id]=1 }
} END { for (i=1;i<=n;i++) print row[order[i]] }')
NEWANSWERS=$(printf '%s\n' "$AEFF" | awk -F'|' '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  { out = ""; for (i = 1; i <= NF; i++) { f = trim($i); if (i > 3 && f ~ /^Q:/) continue; out = (out == "" ? f : out " | " f) } print out }')
NQ=$(printf '%s\n' "$ANSWERS_RAW" | grep -c '| *Q:' || true)
ANS_SECT=$(sect 'Answer ledger')
ANS_PRE=$(printf '%s\n' "$ANS_SECT" | awk '/^```vid-prd-answers$/ { stop = 1 } !stop { print }')
ANS_POST=$(printf '%s\n' "$ANS_SECT" | awk 'BEGIN{inb=0; done=0} done { print; next } /^```vid-prd-answers$/ { inb = 1; next } inb && /^```$/ { done = 1; next }')

# --- open decisions: the carriers, one line each; prose to history ---------
OQ_SECT=$(sect 'Open decisions')
OQ_COMMENT=$(printf '%s\n' "$OQ_SECT" | awk 'NR==1{next} /^<!--/ && !done {on=1} on {print} /-->/ && on {on=0; done=1}')
CARRIERS=$(grep -E '^(VID-QUESTION:|RESOLVED: \(OQ-[0-9]+\))' "$PRD" || true)
OQ_PROSE=$(printf '%s\n' "$OQ_SECT" | sed '1d' | awk '/<!--/ {inc=1} !inc {print} /-->/ {inc=0}' | grep -vE '^(VID-QUESTION:|RESOLVED: \(OQ-[0-9]+\))' | grep -v '^[[:space:]]*$' || true)

# --- findings, ratifications verbatim; appends emptied to the comment -------
FINDINGS_SECT=$(sect Findings); RAT_SECT=$(sect Ratifications)
APP_SECT=$(sect Appends)
APP_HEAD=$(printf '%s\n' "$APP_SECT" | awk 'NR==1 { print; next } /^### / { stop = 1 } !stop { print }' | awk '{ lines[NR] = $0 } END { last = NR; while (last > 1 && lines[last] ~ /^[ \t]*$/) last--; for (i = 1; i <= last; i++) print lines[i] }')
APP_BODY=$(printf '%s\n' "$APP_SECT" | sed '1d')
APP_CONTENT=$(printf '%s\n' "$APP_SECT" | awk 'NR==1{next} /^### /{on=1} on{print}')

# --- assemble ---------------------------------------------------------------
OUT="$T/PRD.md"
{
  printf '%s\n' "$TITLE"
  printf 'grammar: %s\n' "$OUTGRAMMAR"
  printf 'Seed: SEED.md (sha256 %s)\n' "$SEEDHASH"
  [ -n "$HEADER_REST" ] && printf '%s\n' "$HEADER_REST"
  printf '%s\n' "$MIDDLE"
  printf '%s\n' "$ITEMS_PRE"
  [ -z "$FEATS" ] || printf '\n```vid-prd-features\n%s\n```\n\n' "$FEATS"
  printf '```vid-prd\n%s\n```\n' "$NEWITEMS"
  [ -n "$ITEMS_POST" ] && printf '%s\n' "$ITEMS_POST"
  printf '%s\n' "$ANS_PRE"
  printf '```vid-prd-answers\n%s\n```\n' "$NEWANSWERS"
  [ -n "$ANS_POST" ] && printf '%s\n' "$ANS_POST"
  printf '## Open decisions\n\n'
  [ -n "$OQ_COMMENT" ] && printf '%s\n\n' "$OQ_COMMENT"
  if [ -n "$CARRIERS" ]; then printf '%s\n' "$CARRIERS" | awk '{ print; print "" }'; else printf '<!-- No open decisions. -->\n\n'; fi
  printf '%s\n' "$FINDINGS_SECT"
  printf '%s\n' "$RAT_SECT"
  printf '%s\n\n' "$APP_HEAD"
} | awk '{ lines[NR] = $0 } END { last = NR; while (last > 1 && lines[last] ~ /^[ \t]*$/) last--; for (i = 1; i <= last; i++) print lines[i] }' > "$OUT"
cp "$T/SEED.md" "$T/SEED.keep" 2>/dev/null || cp "$DIR/SEED.md" "$T/SEED.md"

# --- the court gates the write ---------------------------------------------
if ! sh "$COURT" "$OUT" >"$T/court.txt" 2>&1; then
  echo 'ViD consolidate: refused — checks/prd.sh does not pass on the consolidated output; nothing written.' >&2
  grep '^GAP' "$T/court.txt" >&2 || cat "$T/court.txt" >&2
  exit 1
fi

# --- the archive and the arm ledger (only when there is something to keep) -
ARCHIVE=no
{ [ -n "$APP_CONTENT" ] || [ "$NAMENDED" -gt 0 ] || [ "$NQ" -gt 0 ] || [ -n "$OQ_PROSE" ]; } && ARCHIVE=yes
HIST="$DIR/PRD-HISTORY-$DATE.md"; k=1
while [ "$ARCHIVE" = yes ] && [ -f "$HIST" ]; do k=$((k + 1)); HIST="$DIR/PRD-HISTORY-$DATE-$k.md"; done
if [ "$ARCHIVE" = yes ]; then
  {
    printf '%s — history (consolidated %s)\n\n' "$TITLE" "$DATE"
    printf '<!-- Written by checks/prd-consolidate.sh (v0.9.1 3.4). Verbatim and in\n     order: the base rows and rulings as first written (every superseded\n     row, every question text), the open-decisions prose, and every append\n     section. Invisible to the live-question census; the live law is\n     PRD.md. -->\n\n'
    printf '## Base — Items as ratified\n\n'; printf '%s\n\n' "$(printf '%s\n' "$ITEMS_SECT" | sed '1d')"
    printf '## Base — Answer ledger as ratified\n\n'; printf '%s\n\n' "$(printf '%s\n' "$ANS_SECT" | sed '1d')"
    printf '## Base — Open decisions as ratified\n\n'; printf '%s\n\n' "$(printf '%s\n' "$OQ_SECT" | sed '1d')"
    printf '## Appends\n\n'; printf '%s\n' "$APP_BODY"
  } | awk '{ lines[NR] = $0 } END { last = NR; while (last > 1 && lines[last] ~ /^[ \t]*$/) last--; for (i = 1; i <= last; i++) print lines[i] }' > "$T/HISTORY.md"
fi
LEDGER="$DIR/.vid/consolidation-arms-$DATE.md"; NLOSING=0; NLEDGER=0
if [ "$NAMENDED" -gt 0 ]; then
  {
    printf '# Consolidation arm ledger — %s\n\n' "$DATE"
    printf '<!-- Per effective item amended since first ratification: its fail-if arms at\n     first ratified text and at consolidated text, side by side (an arm is one\n     clause split at top-level " or " / ", or " / "; or ", spec 3.5b). arm-losing\n     marks an item whose consolidated text carries fewer arms; arm-changed one\n     whose count held while an arm of the first text is no longer found. Read\n     by 7b, which proposes restorations; counts, never scores. -->\n\n'
    for row in $EFF; do
      id=$(trim "$(printf '%s\n' "$row" | cut -d'|' -f1)")
      n=$(printf '%s\n' "$ITEMS_RAW" | grep -cE "^[[:space:]]*$id([[:space:]]+AMENDED)?[[:space:]]*\|" || true)
      [ "$n" -gt 1 ] || continue
      first=$(printf '%s\n' "$FIRST" | grep -E "^$id \|" || true)
      f1=$(printf '%s\n' "$first" | tr '|' '\n' | sed -n 's/^[[:space:]]*fail-if:[[:space:]]*//p' | head -n 1)
      f2=$(printf '%s\n' "$row" | tr '|' '\n' | sed -n 's/^[[:space:]]*fail-if:[[:space:]]*//p' | head -n 1)
      printf '%s\n%s\n' "$f1" "$f2" | awk -v id="$id" -v n="$n" '
        function norm(s) { gsub(/[ \t]+/, " ", s); gsub(/^ | $/, "", s); return s }
        function arms(s, arr,   k, depth, i, c, cur, L) {
          k = 0; depth = 0; cur = ""; i = 1; L = length(s)
          while (i <= L) {
            c = substr(s, i, 1)
            if (c == "(") depth++; else if (c == ")" && depth > 0) depth--
            if (depth == 0) {
              if (substr(s, i, 5) == "; or " || substr(s, i, 5) == ", or ") { arr[++k] = norm(cur); cur = ""; i += 5; continue }
              if (substr(s, i, 4) == " or ") { arr[++k] = norm(cur); cur = ""; i += 4; continue }
            }
            cur = cur c; i++
          }
          arr[++k] = norm(cur); return k
        }
        NR == 1 { a = arms($0, A) } NR == 2 { b = arms($0, B) }
        END {
          losing = (b < a) ? 1 : 0; changed = 0
          for (i = 1; i <= a; i++) { found = 0; for (j = 1; j <= b; j++) if (index(B[j], A[i]) > 0 || index(A[i], B[j]) > 0) found = 1; if (!found) changed = 1 }
          flag = losing ? " — arm-losing" : (changed ? " — arm-changed" : "")
          printf "## %s — %d rows — arms first=%d consolidated=%d%s\n\n", id, n, a, b, flag
          print "first:"; for (i = 1; i <= a; i++) printf "  %d. %s\n", i, A[i]
          print "consolidated:"; for (j = 1; j <= b; j++) printf "  %d. %s\n", j, B[j]
          print ""
          if (losing) print "LOSING" > "/dev/stderr"
        }' 2>>"$T/losing.txt"
      NLEDGER=$((NLEDGER + 1))
    done
  } > "$T/LEDGER.md"
  NLOSING=$(grep -c LOSING "$T/losing.txt" 2>/dev/null || true)
fi

# --- write ------------------------------------------------------------------
cp "$OUT" "$DIR/$BASE"
[ "$WRITE_SEED" = yes ] && cp "$T/SEED.md" "$DIR/SEED.md"
[ "$ARCHIVE" = yes ] && cp "$T/HISTORY.md" "$HIST"
if [ "$NAMENDED" -gt 0 ]; then mkdir -p "$DIR/.vid"; cp "$T/LEDGER.md" "$LEDGER"; fi
NOPEN=$(printf '%s\n' "$CARRIERS" | grep -c '^VID-QUESTION:' || true); NRES=$(printf '%s\n' "$CARRIERS" | grep -c '^RESOLVED:' || true)
echo "consolidate: items=$NEFF (amended-rows-folded=$NAMENDED) answers=$(printf '%s\n' "$AEFF" | grep -c . || true) (questions-archived=$NQ) carriers open=$NOPEN resolved=$NRES seed=$( [ "$WRITE_SEED" = yes ] && echo written || echo verified ) history=$( [ "$ARCHIVE" = yes ] && basename "$HIST" || echo none ) arm-ledger=$( [ "$NAMENDED" -gt 0 ] && echo "$NLEDGER items ($NLOSING arm-losing)" || echo none ) court=green"
exit 0
