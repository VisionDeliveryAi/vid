#!/bin/sh
# Purpose: pass-output checker (vid-design) — the court tradition applied to
# the design-vs-PRD consistency pass (v0.9.1 spec 3.3). A fixture directory
# holds a design pack (DESIGN-BRIEF.md with its manifest, design/screens/,
# for a two-round fixture delta/) read against ../shortlink-PRD.md, and an
# expected.md whose non-comment lines are assertions over the disagreement
# lines a FRESH pass returned. The pass is a model's work; this script is
# deterministic — the case runs procedurally (a fresh agent reviews, this
# script judges; protocol in README.md) and is never part of
# checks/selftest/run.sh. Exits 0 only when every expectation holds; one
# line per expectation, counts never scores. A fixture whose correct
# output is ZERO lines is a first-class case — the pass that can accept a
# clean pack is demonstrated, not assumed.
#
# The pass output is a markdown file carrying one ```vid-design-disagreements
# block (possibly empty — an empty block IS the clean verdict; a missing
# block is "nothing returned" and fails closed). One line per disagreement,
# the fields separated by ` · ` (middle dot):
#   <marker> · <item id | context marker> · canvas says: … · row says: … (or canvas says: …)
#
# Expectation grammar — one per line:
#   <verb> line [<field><op><value>]...  [<cmp> <n>]
#   verb  : exists | absent | count
#   field : marker target canvas row line
#   op    : =  (exact, trimmed)   ~  (case-insensitive regex)   !~ (not regex)
#   cmp   : >= | = | <=   (count only)
# Values may not contain spaces; `line` matches the whole line.
# Usage: sh pass-check.sh <fixture-dir> <pass-output.md>
set -eu
FIX=${1:?fixture dir}; OUT=${2:?pass output file}
[ -f "$FIX/expected.md" ] || { echo "pass-check: $FIX/expected.md missing" >&2; exit 1; }
[ -f "$OUT" ] || { echo "pass-check: $OUT missing" >&2; exit 1; }
grep -q '^```vid-design-disagreements' "$OUT" || { echo 'pass-check: no ```vid-design-disagreements block — the pass returned nothing (an empty block is the clean verdict; no block is no verdict).' >&2; exit 1; }
BLOCK=$(sed -n '/^```vid-design-disagreements/,/^```$/p' "$OUT" | sed '1d;$d' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true)
FAILS=0; N=0
while IFS= read -r spec; do
  case "$spec" in ''|'#'*) continue ;; esac
  N=$((N + 1))
  got=$(printf '%s\n' "$BLOCK" | awk -v spec="$spec" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function fieldval(row, f,   n, parts) {
      if (f == "line") return row
      n = split(row, parts, / · /)
      if (f == "marker") return trim(parts[1]); if (f == "target") return trim(parts[2])
      if (f == "canvas") return trim(parts[3]); if (f == "row") return trim(parts[4])
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
      if ($0 !~ /^[ \t]*[A-Za-z][A-Za-z0-9_-]*\//) next   # a disagreement line opens with a marker ID/state; anything else is not a line
      if (cls != "line") next
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
    PASS*) echo "ok    $spec  ($got)" ;;
    *) echo "FAIL  $spec  ($got)"; FAILS=$((FAILS + 1)) ;;
  esac
done < "$FIX/expected.md"
echo "pass-check: expectations=$N failed=$FAILS"
[ "$FAILS" -eq 0 ] || { echo "pass-check: the pass missed $FAILS expectation(s)." >&2; exit 1; }
exit 0
