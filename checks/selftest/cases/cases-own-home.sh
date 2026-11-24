#!/bin/sh
# Purpose: selftest case — no case writes into the home of whoever runs it: each one that runs `next-move.sh call` or `next-page.sh
# write`, which put the plan page under HOME's ViD Viewer folder, sets a HOME of its own (or runs it through fixtures/plan-page.sh's
# pp_write, which does). A planted case with none is convicted. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "cases-own-home: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# bare <case…>: the cases with such a call and no HOME= of their own, comment lines apart
bare() { awk 'FNR == 1 { if (f != "" && c && !h) print f; f = FILENAME; c = 0; h = 0 } /^[ \t]*#/ { next }
  /(^|[^A-Za-z])sh[ \t]+"?[^ \t"]*next-(move\.sh"?[ \t]+call|page\.sh"?[ \t]+write)/ { c = 1 } /(^|[^A-Za-z_])HOME=/ { h = 1 } END { if (f != "" && c && !h) print f }' "$@"; }
bare "$CHECKS"/selftest/cases/*.sh | grep -v '/cases-own-home\.sh$' > "$T/out" || :
[ ! -s "$T/out" ] || fail 'a case runs the call or writes the plan page with the HOME of whoever runs it:'
printf '#!/bin/sh\nset -eu\nsh "$CHECKS/next-move.sh" call > "$T/out"\n' > "$T/planted.sh"
[ "$(bare "$T/planted.sh")" = "$T/planted.sh" ] || fail 'a planted case with no HOME of its own is not found'
echo 'cases-own-home: ok'
