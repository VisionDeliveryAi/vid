#!/bin/sh
# Purpose: pass-output checker (vid-create-prd) — the court tradition applied
# to the three PRD reviewers (v0.9.1 spec 3.10). A calibration fixture
# directory holds a PRD.md (court-green, the enriched grammar) and an
# expected.md whose non-comment lines are assertions over the findings a
# FRESH pass returned for that fixture. The pass is a model's work; this
# script is deterministic — so the case runs procedurally (a fresh agent
# reviews, this script judges; protocol in README.md) and is never part of
# checks/selftest/run.sh. Exits 0 only when every expectation holds; prints
# one line per expectation, counts never scores. A fixture whose correct
# output is ZERO findings is a first-class case here — the reviewer that
# can accept good work is demonstrated, not assumed.
#
# The pass output is a markdown file carrying one ```vid-prd-findings block
# (the three reviewers) or one ```vid-prd-rewordings block (the wording
# lens, 3.5a) — possibly empty: an empty block IS the clean verdict; a
# missing block is "nothing returned" and fails closed. Finding rows are the
# PRD's own findings grammar, disposition `-` (the sitting's, not the
# pass's), plus the optional labeled fields `triage:` (the whole-set
# review's class) and `arms:` (a repair edit's accounting, 3.5b):
#   F-NN | pass | severity | target | - | evidence: … | triage: … | arms: …
# Rewording rows are one item per line with the restated fail-if and its
# accounting:
#   REQ-NNN | fail-if: … | arms: 1 retained, 2 strengthened, …
#
# Expectation grammar — one per line:
#   <verb> <class> [<field><op><value>]...  [<cmp> <n>]
#   verb  : exists | absent | count
#   class : finding | rewording
#   field : finding — id pass severity target disposition evidence triage arms row
#           rewording — id fail-if arms row
#   op    : =  (exact, trimmed)   ~  (case-insensitive regex)   !~ (not regex)
#   cmp   : >= | = | <=   (count only)
# Values may not contain spaces; `row` matches the whole line.
# Usage: sh pass-check.sh <fixture-dir> <pass-output.md>
set -eu
FIX=${1:?fixture dir}; OUT=${2:?pass output file}
[ -f "$FIX/expected.md" ] || { echo "pass-check: $FIX/expected.md missing" >&2; exit 1; }
[ -f "$OUT" ] || { echo "pass-check: $OUT missing" >&2; exit 1; }
blockof() { sed -n "/^\`\`\`$1/,/^\`\`\`\$/p" "$OUT" | sed '1d;$d' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true; }
FAILS=0; N=0
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  N=$((N + 1))
  cls=$(printf '%s\n' "$line" | awk '{print $2}')
  case "$cls" in
    finding) grep -q '^```vid-prd-findings' "$OUT" || { echo 'pass-check: no ```vid-prd-findings block — the pass returned nothing (an empty block is the clean verdict; no block is no verdict).' >&2; exit 1; }; BLOCK=$(blockof vid-prd-findings) ;;
    rewording) grep -q '^```vid-prd-rewordings' "$OUT" || { echo 'pass-check: no ```vid-prd-rewordings block — the lens returned nothing (an empty block is the clean verdict; no block is no verdict).' >&2; exit 1; }; BLOCK=$(blockof vid-prd-rewordings) ;;
    *) echo "pass-check: unknown class '$cls' in expectation: $line" >&2; exit 1 ;;
  esac
  got=$(printf '%s\n' "$BLOCK" | awk -v spec="$line" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function labeled(row, name,   n, i, parts, v) {
      n = split(row, parts, "|")
      for (i = 1; i <= n; i++) { v = trim(parts[i]); if (index(v, name ":") == 1) return trim(substr(v, length(name) + 2)) }
      return ""
    }
    function fieldval(row, f,   n, parts) {
      if (f == "row") return row
      if (f == "evidence" || f == "triage" || f == "arms" || f == "fail-if") return labeled(row, f)
      n = split(row, parts, "|")
      if (f == "id") return trim(parts[1])
      if (cls == "rewording") return ""
      if (f == "pass") return trim(parts[2]); if (f == "severity") return trim(parts[3])
      if (f == "target") return trim(parts[4]); if (f == "disposition") return trim(parts[5])
      return ""
    }
    BEGIN {
      nt = split(spec, tok, " "); verb = tok[1]; cls = tok[2]; np = 0; cmp = ">="; want = 1
      for (i = 3; i <= nt; i++) {
        if (tok[i] == ">=" || tok[i] == "=" || tok[i] == "<=") { cmp = tok[i]; want = tok[i + 1] + 0; break }
        np++; p[np] = tok[i]
      }
    }
    {
      if (cls == "finding" && $0 !~ /^[ \t]*F-/) next            # only finding rows count; a blank line is not a finding
      if (cls == "rewording" && $0 !~ /^[ \t]*[A-Z]+-[0-9]+[ \t]*\|/) next   # only item rows count
      if (cls != "finding" && cls != "rewording") next
      ok = 1
      for (k = 1; k <= np; k++) {
        s = p[k]
        if (match(s, /!~/)) { f = substr(s, 1, RSTART - 1); op = "!~"; v = substr(s, RSTART + 2) }
        else if (match(s, /~/)) { f = substr(s, 1, RSTART - 1); op = "~"; v = substr(s, RSTART + 1) }
        else if (match(s, /=/)) { f = substr(s, 1, RSTART - 1); op = "="; v = substr(s, RSTART + 1) }
        else { ok = 0; break }
        val = fieldval($0, f)
        if (op == "=" && val != v) ok = 0
        if (op == "~" && tolower(val) !~ tolower(v)) ok = 0
        if (op == "!~" && tolower(val) ~ tolower(v)) ok = 0
        if (!ok) break
      }
      if (ok) c++
    }
    END {
      c += 0
      if (verb == "exists") pass = (c >= 1)
      else if (verb == "absent") pass = (c == 0)
      else if (cmp == ">=") pass = (c >= want)
      else if (cmp == "<=") pass = (c <= want)
      else pass = (c == want)
      print (pass ? "PASS" : "FAIL") " matched=" c
    }')
  case "$got" in
    PASS*) echo "ok    $line  ($got)" ;;
    *) echo "FAIL  $line  ($got)"; FAILS=$((FAILS + 1)) ;;
  esac
done < "$FIX/expected.md"
echo "pass-check: expectations=$N failed=$FAILS"
[ "$FAILS" -eq 0 ] || { echo "pass-check: the pass missed $FAILS expectation(s)." >&2; exit 1; }
exit 0
