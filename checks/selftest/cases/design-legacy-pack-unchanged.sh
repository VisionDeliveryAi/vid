#!/bin/sh
# Purpose: selftest case — packs without the per-screen index are judged as before (v0.9.8.1 R20). The per-screen
# fixture's screens drawn in one canvas, with no index.json, and with an index declaring another layout: clean, no
# per-screen delta; the same canvas under an index declaring per-screen convicts. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/per-screen.sh"
fail() { echo "design-legacy-pack-unchanged: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ps_pack
cat "design/screens/P01 Home.dc.html" "design/screens/P02 Jobs.dc.html" "design/screens/C00-forms.dc.html" > "design/screens/P Pages.dc.html"
rm "design/screens/P01 Home.dc.html" "design/screens/P02 Jobs.dc.html" design/screens/C00-forms.dc.html
join; [ "$JR" -eq 0 ] || fail 'a one-canvas pack with no index was refused'
grep -q 'no own file\|index file missing' "$T/out" && fail 'a pack with no index was judged per screen'
printf '{"layout": "single"}\n' > design/screens/index.json
join; [ "$JR" -eq 0 ] || fail 'a pack whose index declares another layout was refused'
ps_index 'P Pages.dc.html'
join; [ "$JR" -ne 0 ] && grep -q '^no own file' "$T/out" || fail 'the per-screen layout did not judge the one-canvas pack'
exit 0
