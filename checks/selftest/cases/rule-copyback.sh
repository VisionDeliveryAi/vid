#!/bin/sh
# Purpose: selftest case — M10's rule 1, counted (0.26.10.28.4, 9.3 R8): no ticket script copies a scratch file back over a record, by `cat <scratch> >
# <record>` or `cp <scratch> <record>`; a record is replaced through put. Scratch is what $T, $W, $Q, $L, $SX, $K or $X name, and .vid/round/; a copy
# into scratch is no copy-back. The count is zero, with no exception; its search finds a planted copy-back. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "rule-copyback: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
CB='function scr(x) { gsub(/^["'"'"']/, "", x); return (x ~ /^\$\{?(T|W|Q|L|SX|K|X)[}\/]/ || x ~ /^\.vid\/round\//) }
  function chk(m, src, dst) { if (scr(src) && !scr(dst)) { print FILENAME ":" FNR ": " m; c++ } }
  /^[ \t]*#/ { next } { s = $0
    while (match(s, /cat[ \t]+("[^"]*"|[^ \t";|&)]+)[ \t]*>[ \t]*("[^"]*"|[^ \t;|&)>]+)/)) { b = substr(s, 1, RSTART - 1); m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
      if (b ~ /\$\($/ || m ~ />>/) continue; src = m; sub(/^cat[ \t]+/, "", src); sub(/[ \t]*>.*$/, "", src); dst = m; sub(/^[^>]*>[ \t]*/, "", dst); chk(m, src, dst) }
    s = $0; while (match(s, /cp([ \t]+-[A-Za-z]+)?[ \t]+("[^"]*"|[^ \t";|&)]+)[ \t]+("[^"]*"|[^ \t;|&)]+)/)) { m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
      r = m; sub(/^cp([ \t]+-[A-Za-z]+)?[ \t]+/, "", r); if (r ~ /^"/) { src = substr(r, 1, index(substr(r, 2), "\"") + 1); dst = substr(r, length(src) + 1) } else { src = r; sub(/[ \t].*$/, "", src); dst = substr(r, length(src) + 1) }
      sub(/^[ \t]+/, "", dst); chk(m, src, dst) } }'
# FB-2 C3: close.sh's parts, by glob, with it
CP=$(for f in "$CHECKS"/close-*.sh; do b=${f##*/}; printf '%s ' "${b%.sh}"; done)
for s in close $CP decide end github grade land lib planner queue refresh results round walk writer; do awk "$CB" "$CHECKS/$s.sh"; done > "$T/out"
[ ! -s "$T/out" ] || fail 'a record copied back over:'
printf 'x() { cat "$T/new" > "$D/landed"; cp "$W/cm" .vid/decide/merges; cat "$T/a" > "$T/b"; cp "$SX/up1" "$SX/upa"; }\n' > "$T/plant.sh"; awk "$CB" "$T/plant.sh" > "$T/found"
[ "$(grep -c . "$T/found")" = 2 ] || { cp "$T/found" "$T/out"; fail 'the search does not find a planted copy-back, or finds a copy into scratch:'; }
echo 'rule-copyback: ok'
