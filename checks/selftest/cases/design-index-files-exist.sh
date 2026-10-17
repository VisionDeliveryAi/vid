#!/bin/sh
# Purpose: selftest case — every file the per-screen index lists exists (v0.9.8.1 R20). The per-screen fixture: an
# index listing a file the pack lacks, and one whose components name a missing group file, each convict `index file
# missing`, naming the file. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/per-screen.sh"
fail() { echo "design-index-files-exist: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ps_pack; ps_index 'P01 Home.dc.html' 'P02 Jobs.dc.html' C00-forms.dc.html 'P09 Gone.dc.html'
join; [ "$JR" -ne 0 ] && grep -q '^index file missing  *P09 Gone.dc.html' "$T/out" || fail 'a listed file the pack lacks was not convicted'
ps_index 'P01 Home.dc.html' 'P02 Jobs.dc.html' C00-forms.dc.html
sed 's/"P02": \["C00-forms.dc.html"\]/"P02": ["C00-tables.dc.html"]/' design/screens/index.json > x && mv x design/screens/index.json
join; [ "$JR" -ne 0 ] && grep -q '^index file missing  *C00-tables.dc.html' "$T/out" || fail 'a missing component file was not convicted'
exit 0
