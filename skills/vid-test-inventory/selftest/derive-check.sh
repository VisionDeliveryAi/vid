#!/bin/sh
# Purpose: derivation self-test checker (vid-test-inventory) — the court
# tradition applied to a judgment step. A fixture directory holds a PRD.md
# (court-green, the enriched grammar), optionally an ARCHITECTURE.md, and an
# expected.md whose non-comment lines are assertions over the INVENTORY.md a
# session derived from that fixture. This script is deterministic; the
# derivation is a session's work — so the case runs procedurally (a fresh
# session derives, this script judges) and is never part of
# checks/selftest/run.sh. Shipped with the skill, never installed into a
# project. Exits 0 only when every expectation holds; prints one line per
# expectation, counts never scores.
#
# Expectation grammar — one per line:
#   <verb> <class> [<field><op><value>]...  [<cmp> <n>]
#   verb  : exists | absent | count
#   class : ROW | rule | hostility | difference | seam | exception | suppression
#   field : kind subject obligation derived-from test id statement command
#           attempt protects disable origin row
#   op    : =  (exact, trimmed)   ~  (case-insensitive regex)   !~ (not regex)
#   cmp   : >= | = | <=   (count only)
# Values may not contain spaces; `row` matches the whole line.
# Usage: sh derive-check.sh <fixture-dir> <INVENTORY.md>
set -eu
FIX=${1:?fixture dir}; INV=${2:?derived INVENTORY.md}
[ -f "$FIX/expected.md" ] || { echo "derive-check: $FIX/expected.md missing" >&2; exit 1; }
[ -f "$INV" ] || { echo "derive-check: $INV missing" >&2; exit 1; }
BLOCK=$(sed -n '/^```vid-inventory/,/^```$/p' "$INV" | sed '1d;$d' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true)
[ -n "$BLOCK" ] || { echo 'derive-check: no ```vid-inventory block — nothing derived.' >&2; exit 1; }
FAILS=0; N=0
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  N=$((N + 1))
  got=$(printf '%s\n' "$BLOCK" | awk -v spec="$line" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function labeled(row, name,   n, i, parts, v) {
      n = split(row, parts, "|")
      for (i = 1; i <= n; i++) { v = trim(parts[i]); if (index(v, name ":") == 1) return trim(substr(v, length(name) + 2)) }
      return ""
    }
    function fieldval(row, cls, f,   n, parts) {
      n = split(row, parts, "|")
      if (f == "row") return row
      if (f == "origin" || f == "protects" || f == "disable" || f == "proved-red") return labeled(row, f)
      if (cls == "ROW") {
        if (f == "id") return trim(parts[1]); if (f == "kind") return trim(parts[2]); if (f == "subject") return trim(parts[3])
        if (f == "obligation") return trim(parts[6]); if (f == "derived-from") return trim(parts[7]); if (f == "test") return trim(parts[8])
      } else {
        if (f == "id") return trim(parts[2])
        if (f == "statement" || f == "attempt" || f == "subject" || f == "knob" || f == "service") return trim(parts[3])
        if (f == "command") return trim(parts[4])
        if (f == "test") { n = split(row, parts, "|"); while (n > 3 && (parts[n] ~ /^[ \t]*(origin|proved-red):/)) n--; return trim(parts[n]) }
      }
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
      first = trim($1); sub(/[ \t]*\|.*/, "", first)
      rc = (first ~ /^ROW-/) ? "ROW" : first
      if (rc != cls) next
      ok = 1
      for (k = 1; k <= np; k++) {
        s = p[k]
        if (match(s, /!~/)) { f = substr(s, 1, RSTART - 1); op = "!~"; v = substr(s, RSTART + 2) }
        else if (match(s, /~/)) { f = substr(s, 1, RSTART - 1); op = "~"; v = substr(s, RSTART + 1) }
        else if (match(s, /=/)) { f = substr(s, 1, RSTART - 1); op = "="; v = substr(s, RSTART + 1) }
        else { ok = 0; break }
        val = fieldval($0, rc, f)
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
echo "derive-check: expectations=$N failed=$FAILS"
[ "$FAILS" -eq 0 ] || { echo "derive-check: the derivation missed $FAILS expectation(s) — an axis regressed." >&2; exit 1; }
exit 0
