#!/bin/sh
# Purpose: ViD decision labels — the labelling pass (v0.9.7.3 spec 3.3, R3). A
# decision line carries a label after its enforced: field, `| applies-to: <ids
# and codes>` or `| scope: project` (checks/hooks/pre-commit 4c); a brief quotes
# it where its label applies (checks/brief.sh, R2). The pass labels the lines
# that have none, once: an agent proposes, and `apply` writes them — with no
# question to the owner (the owner, 2026-10-14): a label the agent is unsure
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
#                     DIF ids) and the return form, read access only, no edits.
#                     Prints `propose: <k> decisions → <brief>`; none, writes nothing.
#   apply [<file>] [--no-commit]
#                     reads the proposals (default .vid/decision-labels.proposed,
#                     the agent's return saved unchanged, one line per decision:
#                     `D-NNN <hash> | applies-to: <items> | sure`, or `| scope:
#                     project |`, or `| unsure`) and writes each label after its
#                     line's enforced: field, only where the line's text hash
#                     still matches its proposal (a changed line is not labelled
#                     and is listed; a line gone or already labelled is skipped).
#                     Unsure, malformed, or naming an item no brief joins on: the
#                     label written is `scope: project` (widened). Keeps the
#                     record .vid/decision-labels.applied (`D-NNN<TAB><label
#                     written><TAB>sure|widened: <why>`). Then one commit of
#                     DECISIONS.md alone, in the project's commit template
#                     (refused when anything else is staged); --no-commit (init,
#                     step 7) writes without committing, the labels landing in
#                     the initial commit. Records `decision-labels applied=<a>
#                     widened=<w> changed=<c> skipped=<s>`.
# Reads the working tree; writes only DECISIONS.md, the record (apply), the brief
# (propose) and the event. Usage: sh checks/decisions.sh propose [--all] | apply [<file>] [--no-commit]
set -eu
IFS='
'
usage() { echo "ViD decisions: usage — sh checks/decisions.sh propose [--all] | apply [<file>] [--no-commit]" >&2; exit 2; }
refuse() { echo "ViD decisions: refused — $*" >&2; exit 1; }
[ $# -ge 1 ] || usage
CMD=$1; shift
[ -f DECISIONS.md ] || refuse 'no DECISIONS.md here'
TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
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
}

case "$CMD" in
  propose)
    ALL=no; [ "${1:-}" = --all ] && ALL=yes
    if [ "$ALL" = yes ]; then awk -F'\t' '$2 == "no"' "$TMPD/dec"; else awk -F'\t' '$2 == "no" && $3 == "no"' "$TMPD/dec"; fi > "$TMPD/sel"
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
      printf 'only when it bears on many areas. Say `sure` or `unsure`. Return exactly one line per\n'
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
    } > "$B"
    echo "propose: $K decisions → $B"
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
inv_read
# the proposals: `<D-id><TAB><hash><TAB><label written><TAB><sure|widened: why>` — a malformed line naming no decision is `?`
awk -F'\t' -v OFS='\t' 'FILENAME == ARGV[1] { if ($1 == "ROW") { J[$2] = 1; n = split($3, a, " "); for (k = 1; k <= n; k++) if (a[k] ~ /^REQ-/) J[a[k]] = 1; n = split($4, a, " "); for (k = 1; k <= n; k++) J[a[k]] = 1; n = split($5, a, " "); for (k = 1; k <= n; k++) J[a[k]] = 1 } else if ($1 == "RULE") J[$2] = 1; next }
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
    print id, hs, lab, "sure" }' "$TMPD/inv" "$PF" > "$TMPD/plan"
# write: a line is labelled when it is present, unlabelled, and its text hash matches its proposal
: > "$TMPD/changed"; : > "$TMPD/skipped"; : > "$TMPD/labels"; : > "$TMPD/record"
while IFS="$TAB" read -r id h lab why; do
  if [ "$id" = '?' ]; then printf '? (a malformed line naming no decision)\n' >> "$TMPD/skipped"; continue; fi
  line=$(awk -F'\t' -v d="$id" '$1 == d { print $4; exit }' "$TMPD/dec")
  labd=$(awk -F'\t' -v d="$id" '$1 == d { print $2; exit }' "$TMPD/dec")
  if [ -z "$line" ]; then printf '%s (not in DECISIONS.md)\n' "$id" >> "$TMPD/skipped"; continue; fi
  if [ "$labd" = yes ]; then printf '%s (already labelled)\n' "$id" >> "$TMPD/skipped"; continue; fi
  if [ "$(thash "$line")" != "$h" ]; then printf '%s\n' "$id" >> "$TMPD/changed"; continue; fi
  printf '%s\t%s\n' "$id" "$lab" >> "$TMPD/labels"; printf '%s\t%s\t%s\n' "$id" "$lab" "$why" >> "$TMPD/record"
done < "$TMPD/plan"
# the label goes after the enforced: field (before origin: or model:), else at the end
awk -F'|' -v lf="$TMPD/labels" 'BEGIN { while ((getline l < lf) > 0) { split(l, a, "\t"); L[a[1]] = a[2] } }
  /^- \*\*D-[0-9]+\*\*/ { match($0, /D-[0-9]+/); id = substr($0, RSTART, RLENGTH)
    if (id in L) { o = ""; done = 0
      for (i = 1; i <= NF; i++) { o = o (i > 1 ? "|" : "") $i; f = $i; sub(/^[ \t]+/, "", f); if (!done && f ~ /^enforced:/) { if (i < NF) o = o "| " L[id] " "; else { sub(/[ \t]+$/, "", o); o = o " | " L[id] } done = 1 } }
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
