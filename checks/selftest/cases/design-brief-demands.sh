#!/bin/sh
# Purpose: selftest case — the design brief asks only what the import needs (0.26.11.1.2, R12, LA-12). The
# import refuses only a pack with no screen markers and judges a per-screen layout only when design/screens/index.json
# declares one, so vid-design must not say a pack without the index fails the import, nor demand the index; the
# canvases named by their markers stay asked (the walk and a per-screen join find a screen's canvas by that name).
# The join's own behaviour is pinned by design-legacy-pack-unchanged.sh. A text check, gated on ViD's own skills
# beside checks/. Env: CHECKS.
set -eu
F="$CHECKS/../skills/vid-design/SKILL.md"
[ -f "$F" ] || { echo 'needs skills/vid-design/SKILL.md'; exit 77; }
fail() { echo "design-brief-demands: $*" >&2; exit 1; }
X=$(tr '\n' ' ' < "$F" | sed 's/[*"]//g' | tr -s ' \t' ' ')
has() { printf '%s' "$X" | grep -qF -- "$1"; }
for b in 'The pack returns an index' 'its absence fails the import' 'the pack carries `design/screens/index.json`' '`design/screens/index.json` lists every screen.'; do
  has "$b" && fail "vid-design still demands the index: \"$b\""
done
has 'The screen markers are the index' || fail 'rule 3 does not say the markers are the index'
has 'the pack need not return one' || fail 'rule 3 does not say the pack need not return an index'
has '`design/screens/index.json` is optional' || fail 'rule 6 does not say the index is optional'
for k in 'HTML canvases (`.dc.html`)' 'C00 Components.dc.html' 'each screen is its own canvas, named by its marker — `P03 <name>.dc.html`' 'C00-<group>.dc.html'; do
  has "$k" || fail "vid-design no longer asks the marker-named canvases: \"$k\""
done
exit 0
