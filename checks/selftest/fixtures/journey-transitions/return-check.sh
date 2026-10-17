#!/bin/sh
# Purpose: the pass-return checker for the journey fixture (v0.9.2 3.1, 3.5;
# spec §5 Phase C's cut line, §7.7). Judges what a test-author pass RETURNED
# over this fixture's five rows: (1) completeness — one return line per row
# briefed, never fewer, in the return shape (`<row> → <path>::<fn>` or
# `<row> → unwritable: <class> — …`), no line for a row not briefed; (2) the
# journey's actions against its transition table — the cited test run
# through harness/run.sh must collect one case per transition, and between
# each transition's begin and end the log must show the ENGINE door
# operated (`press`) and never the API door (`api`) — a transition reached
# through the API is rejected naming it, a missing step likewise; (3) with
# --verdicts <file>, the verdict half: the file carries one
# `verdict … row=<journey row> … transition=k/n` line per transition (four
# transitions → four verdicts; three convict). Deterministic; one line per
# expectation, counts never scores.
# Usage: sh return-check.sh <RETURN.md> [--tests <dir>] [--verdicts <file>] [--product empty]
#   the test files the return cites are read from <dir> by basename (default: the return's directory)
set -u
RET=${1:?return file}; shift
FIX=$(cd "$(dirname "$0")" && pwd); H="$FIX/harness"
TESTS=$(cd "$(dirname "$RET")" && pwd); VERD=''; PRODUCT=''
while [ $# -gt 0 ]; do case "$1" in --tests) TESTS=$2; shift 2 ;; --verdicts) VERD=$2; shift 2 ;; --product) PRODUCT=$2; shift 2 ;; *) echo "return-check: unknown option $1" >&2; exit 2 ;; esac; done
[ -f "$RET" ] || { echo "return-check: $RET missing" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
N=0; FAILS=0
expect() { N=$((N + 1)); if [ "$2" = 0 ]; then echo "ok    $1"; else echo "FAIL  $1"; FAILS=$((FAILS + 1)); fi; }
ROWS=$(sed -n '/^```vid-inventory/,/^```$/p' "$FIX/INVENTORY.md" | grep -oE '^ROW-[0-9]+' )
NROWS=$(printf '%s\n' "$ROWS" | grep -c .)
JROW=$(sed -n '/^```vid-inventory/,/^```$/p' "$FIX/INVENTORY.md" | awk -F'|' '$2 ~ /journey/ { gsub(/ /, "", $1); print $1 }')
NTRANS=$(sed -n '/^```vid-inventory/,/^```$/p' "$FIX/INVENTORY.md" | grep "^$JROW " | grep -oE '[0-9]+\. [a-z]+ at ' | wc -l | tr -d ' ')

# (1) completeness and shape
missing=''; for r in $ROWS; do grep -qE "^$r[[:space:]]*(→|->)" "$RET" || missing="$missing $r"; done
expect "completeness: one return line per briefed row ($NROWS rows → $NROWS returns)" "$( [ -z "$missing" ] && [ "$(grep -cE '^ROW-[0-9]+[[:space:]]*(→|->)' "$RET")" = "$NROWS" ] && echo 0 || echo 1)"
[ -n "$missing" ] && echo "      no return for:$missing"
bad=$(grep -E '^ROW-' "$RET" | grep -vE '^ROW-[0-9]+[[:space:]]*(→|->)[[:space:]]*(tests/invariants/[A-Za-z0-9_./-]+::[A-Za-z_][A-Za-z0-9_]*|unwritable: (ambiguous obligation|missing oracle|missing prerequisite) — .+)' || true)
expect 'shape: every line is <path>::<fn> or an unwritable: line with its class and reason' "$( [ -z "$bad" ] && echo 0 || echo 1)"
[ -n "$bad" ] && printf '      %s\n' "$bad"
extra=$(grep -oE '^ROW-[0-9]+' "$RET" | sort -u | while read -r r; do printf '%s\n' "$ROWS" | grep -qx "$r" || echo "$r"; done)
expect 'no line for a row that was not briefed' "$( [ -z "$extra" ] && echo 0 || echo 1)"

# (2) the journey's actions against the transition table
jline=$(grep -E "^$JROW[[:space:]]*(→|->)" "$RET" | head -n 1 || true)
case "$jline" in
  *unwritable:*) expect "journey $JROW: returned unwritable — the transition table has no missing prerequisite in this fixture" 1 ;;
  *) path=$(printf '%s' "$jline" | sed -E 's/.*(→|->)[[:space:]]*//; s/::.*//'); tf="$TESTS/$(basename "$path")"
     if [ ! -f "$tf" ]; then expect "journey $JROW: the cited test file exists ($tf)" 1
     else
       LOG="$T/j.log"; OUT="$T/j.out"
       (cd "$FIX" && HARNESS_LOG="$LOG" TOY_PRODUCT="$PRODUCT" sh "$H/run.sh" "$tf") > "$OUT" 2>&1 || true
       expect "journey $JROW: one case per transition collected ($NTRANS)" "$( [ "$(grep -c "::$JROW\[transition=[0-9]*/$NTRANS\]" "$OUT")" = "$NTRANS" ] && echo 0 || echo 1)"
       if [ "$PRODUCT" = empty ]; then
         expect "empty product: every transition case and behavior case collected and failed, none skipped" "$( [ "$(grep -c '^case .* passed' "$OUT")" = 0 ] && [ "$(grep -c '^case ' "$OUT")" -ge "$NTRANS" ] && ! grep -qiE 'skip|owed' "$OUT" && echo 0 || echo 1)"
       else
         k=1; badk=''
         while [ "$k" -le "$NTRANS" ]; do
           seg=$(awk -v r="$JROW" -v k="$k" '$1 == "transition" && $2 == r && $3 == k && $4 == "begin" { on = 1; next } $1 == "transition" && $2 == r && $3 == k && $4 == "end" { on = 0 } on' "$LOG")
           printf '%s\n' "$seg" | grep -q '^press ' || badk="$badk $k(no control operated)"
           printf '%s\n' "$seg" | grep -q '^api ' && badk="$badk $k(operated through the API door)"
           k=$((k + 1))
         done
         expect "journey $JROW: every transition operated through the engine door, none through the API" "$( [ -z "$badk" ] && echo 0 || echo 1)"
         [ -n "$badk" ] && echo "      rejected transitions:$badk"
         expect "journey $JROW: every transition's step asserts its effect (all $NTRANS cases pass on the toy product)" "$( [ "$(grep -c "::$JROW\[transition=[0-9]*/$NTRANS\] passed" "$OUT")" = "$NTRANS" ] && echo 0 || echo 1)"
       fi
     fi ;;
esac
# the behavior rows' files: each cited file runs and, on the toy product, each case passes
for r in $ROWS; do
  [ "$r" = "$JROW" ] && continue
  line=$(grep -E "^$r[[:space:]]*(→|->)" "$RET" | head -n 1 || true)
  case "$line" in *::*) path=$(printf '%s' "$line" | sed -E 's/.*(→|->)[[:space:]]*//; s/::.*//'); tf="$TESTS/$(basename "$path")"
    if [ -f "$tf" ]; then
      OUT="$T/$r.out"; (cd "$FIX" && HARNESS_LOG="$T/$r.log" TOY_PRODUCT="$PRODUCT" sh "$H/run.sh" "$tf") > "$OUT" 2>&1 || true
      if [ "$PRODUCT" = empty ]; then expect "$r: collected and failed on the empty product" "$( grep -q "::$r failed" "$OUT" && echo 0 || echo 1)"
      else expect "$r: its case runs through the API door and passes on the toy product" "$( grep -q "::$r passed" "$OUT" && grep -q '^api ' "$T/$r.log" && echo 0 || echo 1)"; fi
    else expect "$r: the cited test file exists" 1; fi ;;
  esac
done

# (3) the verdict half
if [ -n "$VERD" ]; then
  nv=$(grep -cE "^verdict .*row=$JROW .*transition=[0-9]+/$NTRANS" "$VERD" 2>/dev/null || echo 0)
  expect "verdicts: one per transition for $JROW ($NTRANS transitions → $NTRANS verdict lines; found $nv)" "$( [ "$nv" = "$NTRANS" ] && echo 0 || echo 1)"
fi
echo "return-check: expectations=$N failed=$FAILS"
[ "$FAILS" -eq 0 ] || { echo "return-check: the return missed $FAILS expectation(s)." >&2; exit 1; }
exit 0
