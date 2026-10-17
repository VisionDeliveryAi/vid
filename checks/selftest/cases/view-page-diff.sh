#!/bin/sh
# Purpose: selftest case — the page is the owner's design, changed only as recorded (v0.9.7.4 spec 3.10, R9).
# Convicts unless applying every change viewer/page/CHANGES.md lists — each entry's ~~~old text, found exactly once,
# replaced by its ~~~new text, in the file's order — to docs/releases/V0.9.7.4-DESIGN/VID Viewer v2.dc.html gives
# viewer/page/ViD Viewer v2.dc.html byte for byte, and the pack's other files (the runtime, the note, the
# screenshots) are unchanged; and unless the same check fails a page carrying one change the file does not list,
# and a CHANGES.md entry whose old text the design does not hold. Env: CHECKS.
set -eu
R="$CHECKS/.."
[ -d "$R/viewer/page" ] && [ -d "$R/docs/releases/V0.9.7.4-DESIGN" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
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
apply "$R/docs/releases/V0.9.7.4-DESIGN/VID Viewer v2.dc.html" "$R/viewer/page/CHANGES.md" "$T/applied" || fail 'CHANGES.md does not apply to the design'
cmp -s "$T/applied" "$R/viewer/page/ViD Viewer v2.dc.html" || { diff "$T/applied" "$R/viewer/page/ViD Viewer v2.dc.html" | head -20 >&2; fail 'the page differs from the design in a way CHANGES.md does not list'; }
for f in support.js NOTE.md; do cmp -s "$R/docs/releases/V0.9.7.4-DESIGN/$f" "$R/viewer/page/$f" || fail "$f differs from the design"; done
for f in "$R/docs/releases/V0.9.7.4-DESIGN/screenshots/"*; do cmp -s "$f" "$R/viewer/page/screenshots/${f##*/}" || fail "screenshots/${f##*/} differs from the design"; done
[ "$(grep -c '^### C-' "$R/viewer/page/CHANGES.md")" -gt 0 ] || fail 'CHANGES.md lists no change'
grep -q '^### C-[0-9]* · kind [23] · ' "$R/viewer/page/CHANGES.md" || fail 'a change does not name its kind'
if grep '^### C-' "$R/viewer/page/CHANGES.md" | grep -qv '^### C-[0-9]* · kind [23] · '; then fail 'a change of no permitted kind'; fi
# the check convicts: an unlisted change, and an entry the design does not hold
sed 's/Approved screens/Approved designs/' "$R/viewer/page/ViD Viewer v2.dc.html" > "$T/stray"
cmp -s "$T/applied" "$T/stray" && fail 'the planted stray change was not detected'
awk '{ print } /^## Kind 2/ && !d { print "\n### C-99 · kind 2 · nowhere\n\nplanted\n\n~~~old\nthis text is in no design\n~~~\n~~~new\nx\n~~~\n"; d = 1 }' "$R/viewer/page/CHANGES.md" > "$T/bad.md"
if apply "$R/docs/releases/V0.9.7.4-DESIGN/VID Viewer v2.dc.html" "$T/bad.md" "$T/x" 2>/dev/null; then fail 'an entry the design does not hold was applied'; fi
exit 0
