#!/bin/sh
# Purpose: selftest case — element identifiers (v0.9.2 spec 3.4, R20; §7.11).
# The join half: under a brief carrying `grammar: 0.9.2`, a canvas element
# carrying an inline style and no data-element convicts at the join naming
# the delta, the marker, the tag and the line; a duplicate identifier within
# one section convicts; the same canvas with every styled element identified
# acquits; a 0.9.1 brief and a legacy brief over the unidentified canvas are
# reported in one line, never convicted. The instrument half, on the toy
# harness of checks/selftest/fixtures/surface-instrument/: a descendant grid
# declaring three columns beside a page drawing two names the identifier and
# the property; a canvas element absent from the page is `missing element`
# by name; a page identifier the canvas lacks falls under the stray rule; a
# length declared in one unit and painted in another, and a colour in
# another notation, compare equal. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p design/screens
brief() { printf '# brief\n%s\n\n```vid-design-manifest\nP01 | default | REQ-001 | pins: the product name in the heading; one call to action\nC00 | shell-anonymous | REQ-001 | pins: one primary nav; a sign-in door\n```\n' "$1" > DESIGN-BRIEF.md; }
# a canvas whose grid carries a style and no identifier (line 4), beside an identified control
cat > design/screens/pack.html <<'HTML'
<!-- fixture canvas -->
<!-- @screen P01 state=default reqs=REQ-001 -->
<section>
  <div style="display:grid; grid-template-columns: 1fr 1fr 1fr; gap: 16px">{{ cards }}</div>
  <a data-element="primary-action" style="color: #0a5; padding: 8px 16px" href="#">Search</a>
</section>
<!-- @screen C00 state=shell-anonymous reqs=REQ-001 -->
<header data-element="shell-header" style="background: #fff"><nav data-element="primary-nav" style="display:flex">{{ nav }}</nav></header>
HTML
brief 'grammar: 0.9.2'
if sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1; then echo 'surface-identifiers: a styled element without data-element passed under 0.9.2' >&2; exit 1; fi
OUT=$(sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 || true)
printf '%s\n' "$OUT" | grep -q 'no identifier .*P01/default .*<div> at pack.html:4' || { printf '%s\n' "$OUT" >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'identifiers: styled elements=4 without identifier=1 duplicates=0' || { printf '%s\n' "$OUT" >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'C00/shell-anonymous' && exit 1   # the identified shell is never named
# every styled element identified: the join acquits
sed -i.bak 's/<div style=/<div data-element="featured-grid" style=/' design/screens/pack.html && rm design/screens/pack.html.bak
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || { echo 'surface-identifiers: the identified canvas does not acquit' >&2; sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | tail -4 >&2; exit 1; }
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'identifiers: styled elements=4 without identifier=0 duplicates=0' || exit 1
# a duplicate within one section convicts; the same identifier in ANOTHER section is legal
sed -i.bak 's/data-element="primary-action"/data-element="featured-grid"/' design/screens/pack.html && rm design/screens/pack.html.bak
if sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'duplicate identifier .*P01/default .*data-element="featured-grid" appears twice' || exit 1
sed -i.bak 's/data-element="shell-header"/data-element="featured-grid"/; s/<a data-element="featured-grid"/<a data-element="primary-action"/' design/screens/pack.html && rm design/screens/pack.html.bak
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1
# a 0.9.1 brief and a legacy brief over the unidentified canvas: one note, no conviction
sed -i.bak 's/<div data-element="featured-grid" style=/<div style=/' design/screens/pack.html && rm design/screens/pack.html.bak
brief 'grammar: 0.9.1'
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'note: 1 styled element(s) without data-element and 0 duplicate(s) .*pre-0.9.2 brief' || exit 1
brief ''
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'pre-0.9.2 brief, reported' || exit 1
# --- the instrument half (the fixture's reference through the toy runner)
FIX="$CHECKS/selftest/fixtures/surface-instrument"; H="$FIX/harness"; SC="$FIX/scaffolds"
toy() { (cd "$FIX" && HARNESS_LOG=/dev/null DESIGN_TOKENS="$FIX/design/tokens.css" sh "$H/run.sh" "$FIX/reference/surfaces.sh" "$SC/$1" "$SC/correct" 2>&1 || true); }
toy grid-columns | grep -q 'ROW-002 \[alpha\]: .*differs P01/default/featured-grid:grid-template-columns cited=1fr 1fr 1fr painted=1fr 1fr' || { echo 'surface-identifiers: the two-column grid is not named by identifier and property' >&2; exit 1; }
toy missing-element | grep -q 'missing element P01/default/featured-grid' || exit 1
toy extra-identifier | grep -q 'stray P01/default promo-banner' || exit 1
toy units-notation | grep -q ' failed ' && { echo 'surface-identifiers: a unit or notation variant was read as a difference' >&2; exit 1; }
[ "$(toy units-notation | grep -c ' passed ')" = 6 ] || exit 1
exit 0
