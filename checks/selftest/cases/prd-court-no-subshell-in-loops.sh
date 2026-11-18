#!/bin/sh
# Purpose: selftest case — no `$(…)` inside the PRD court's loops (0.26.10.29.3, R6). A reader of checks/prd.sh's
# shell text (its one awk program, the J094 text, left out) follows every `for`, `while` and `until` loop from its
# `do` to its `done`, and every `while`/`until` condition, and names each `$(` met there (`$((`, arithmetic, is not
# one). It must find none, and it must see the court's loops (at least ten). The reader is shown to work: a planted
# loop holding `$(…)` is named. Env: CHECKS.
set -eu
fail() { echo "prd-court-no-subshell-in-loops: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
scan() { awk '
  /^J094=\047/ { inj = 1 }
  inj { if ($0 ~ /^}\047/) inj = 0; next }
  /^[ \t]*#/ { next }
  { s = $0; sub(/(^|[ \t])#[^\047"]*$/, "", s)
    while (match(s, /\$\(\(|\$\(|(^|[;&|({])[ \t]*(do|done|while|until)([ \t;)&|]|$)/)) {
      t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
      if (t == "$((") continue
      if (t == "$(") { if (depth > 0 || inw) { print FILENAME ":" FNR ": " $0; bad++ } continue }
      gsub(/[^a-z]/, "", t)
      if (t == "while" || t == "until") inw = 1
      else if (t == "do") { depth++; loops++; inw = 0 }
      else if (t == "done" && depth > 0) depth--
    } }
  END { print "loops=" loops + 0 " bad=" bad + 0 }' "$1"; }
printf '#!/bin/sh\nfor r in $X; do\n  y=$(printf %%s "$r" | cut -d"|" -f1)\ndone\nwhile [ -n "$(echo x)" ]; do :; done\nfor i in $(seq 3); do n=$((n + 1)); done\n' > "$T/plant.sh"
P=$(scan "$T/plant.sh")
case "$P" in *'loops=3 bad=2') ;; *) fail "the reader does not name the planted \$(…) in a loop body and in a while condition: $P" ;; esac
R=$(scan "$CHECKS/prd.sh")
L=$(printf '%s\n' "$R" | sed -n 's/^loops=\([0-9]*\) bad=\([0-9]*\)$/\1 \2/p')
n=${L% *}; b=${L#* }
[ "$n" -ge 10 ] || fail "the reader saw only $n loops in prd.sh — it does not see the court's loops"
[ "$b" = 0 ] || { printf '%s\n' "$R" | sed '$d' | head -n 10 >&2; fail "$b \$(…) inside prd.sh's loops (above)"; }
echo 'prd-court-no-subshell-in-loops: ok'
