#!/bin/sh
# Purpose: selftest case — the page is the owner's design, changed only as recorded (v0.9.7.4 spec 3.10, R9; v0.26.10.2
# R11: the design is the v0.26.10.2 pack's v3). Convicts unless applying every change viewer/page/CHANGES.md lists —
# each entry's ~~~old text, found exactly once, replaced by its ~~~new text, in the file's order — to
# docs/releases/V0.26.10.2-DESIGN/VID Viewer v3.dc.html gives viewer/page/ViD Viewer v3.dc.html byte for byte, v2 is
# gone, the note and every screenshot of the v3 pack are unchanged, the runtime and v2's screenshots are the 0.9.7.4
# pack's; and unless the same check fails a page carrying one change the file does not list, and a CHANGES.md entry
# whose old text the design does not hold. Env: CHECKS.
set -eu
R="$CHECKS/.."
[ -d "$R/viewer/page" ] && [ -d "$R/docs/releases/V0.26.10.2-DESIGN" ] && [ -d "$R/docs/releases/V0.9.7.4-DESIGN" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "view-page-diff: $*" >&2; exit 1; }
# apply <design> <changes.md> <out>: the design with every listed change applied, or exit 1 naming the entry
apply() {
  LC_ALL=C awk -v D="$1" -v O="$3" '
    BEGIN { while ((getline l < D) > 0) s = s l "\n"; close(D) }
    /^### C-/ { id = $2 }
    /^~~~old$/ { mode = "old"; o = ""; first = 1; next }
    /^~~~new$/ { mode = "new"; nw = ""; first = 1; next }
    /^~~~$/ { if (mode == "old") { OLD = o } else if (mode == "new") { n = 0; q = s; p = 0; pos = 0
          while ((k = index(q, OLD)) > 0) { n++; if (n == 1) pos = p + k; p += k; q = substr(q, k + 1) }
          if (n != 1) { print id ": its old text occurs " n " times" > "/dev/stderr"; bad = 1; exit 1 }
          s = substr(s, 1, pos - 1) nw substr(s, pos + length(OLD)) }
        mode = ""; next }
    mode == "old" { o = o (first ? "" : "\n") $0; first = 0; next }
    mode == "new" { nw = nw (first ? "" : "\n") $0; first = 0; next }
    END { if (!bad) printf "%s", s > O }' "$2"
}
N="$R/docs/releases/V0.26.10.2-DESIGN"; O="$R/docs/releases/V0.9.7.4-DESIGN"; PG="$R/viewer/page/ViD Viewer v3.dc.html"
apply "$N/VID Viewer v3.dc.html" "$R/viewer/page/CHANGES.md" "$T/applied" || fail 'CHANGES.md does not apply to the design'
cmp -s "$T/applied" "$PG" || { diff "$T/applied" "$PG" | head -20 >&2; fail 'the page differs from the design in a way CHANGES.md does not list'; }
[ ! -e "$R/viewer/page/ViD Viewer v2.dc.html" ] || fail 'v2 is still beside v3'
cmp -s "$N/NOTE.md" "$R/viewer/page/NOTE.md" || fail 'NOTE.md differs from the design'
cmp -s "$O/support.js" "$R/viewer/page/support.js" || fail 'support.js differs from the 0.9.7.4 design'
for f in "$N/screenshots/"* "$O/screenshots/"*; do cmp -s "$f" "$R/viewer/page/screenshots/${f##*/}" || fail "screenshots/${f##*/} differs from the design"; done
[ "$(grep -c '^### C-' "$R/viewer/page/CHANGES.md")" -gt 0 ] || fail 'CHANGES.md lists no change'
grep -q '^### C-[0-9]* · kind [23] · ' "$R/viewer/page/CHANGES.md" || fail 'a change does not name its kind'
if grep '^### C-' "$R/viewer/page/CHANGES.md" | grep -qv '^### C-[0-9]* · kind [23] · '; then fail 'a change of no permitted kind'; fi
# the check convicts: an unlisted change, and an entry the design does not hold
sed 's/Approved screens/Approved designs/' "$PG" > "$T/stray"
cmp -s "$T/applied" "$T/stray" && fail 'the planted stray change was not detected'
awk '{ print } /^## Kind 2/ && !d { print "\n### C-99 · kind 2 · nowhere\n\nplanted\n\n~~~old\nthis text is in no design\n~~~\n~~~new\nx\n~~~\n"; d = 1 }' "$R/viewer/page/CHANGES.md" > "$T/bad.md"
if apply "$N/VID Viewer v3.dc.html" "$T/bad.md" "$T/x" 2>/dev/null; then fail 'an entry the design does not hold was applied'; fi
exit 0
