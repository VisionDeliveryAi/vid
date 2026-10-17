#!/bin/sh
# Purpose: selftest case — under the per-screen layout each screen has its own canvas (v0.9.8.1 R20). The per-screen
# fixture with its index: clean as drawn (P03 wholly owed needs no file, C00 lives in group files); P02's states moved
# into P01's file convict `no own file` for P02; a file named for P02 that holds none of its markers convicts too.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/per-screen.sh"
fail() { echo "design-one-canvas-per-screen: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ps_pack; ps_index 'P01 Home.dc.html' 'P02 Jobs.dc.html' C00-forms.dc.html
join; [ "$JR" -eq 0 ] || fail 'the per-screen pack as drawn was refused'
cat "design/screens/P02 Jobs.dc.html" >> "design/screens/P01 Home.dc.html"; rm "design/screens/P02 Jobs.dc.html"
ps_index 'P01 Home.dc.html' C00-forms.dc.html
join; [ "$JR" -ne 0 ] && grep -q '^no own file  *P02/\*' "$T/out" || fail 'a screen drawn in another screen'"'"'s file was not convicted'
printf '<div>no markers</div>\n' > "design/screens/P02 Jobs.dc.html"; ps_index 'P01 Home.dc.html' 'P02 Jobs.dc.html' C00-forms.dc.html
join; [ "$JR" -ne 0 ] && grep -q '^no own file  *P02/\*' "$T/out" || fail 'a file named for the screen without its markers was not convicted'
exit 0
