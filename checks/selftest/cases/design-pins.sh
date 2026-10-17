#!/bin/sh
# Purpose: selftest case — pinned constraints (v0.9.1 spec 3.7b). Under a
# brief carrying `grammar: 0.9.1`, a manifest row without `pins:` convicts at
# the join, naming the row; the same row with pins acquits; a pre-0.9.1
# brief's row without pins is reported, never convicted; a trailing field
# that is neither a resolution nor pins: is still a bad resolution. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p design/screens
printf '<!-- @screen P01 state=default reqs=REQ-001 -->\n<section>{{ home }}</section>\n<!-- @screen C00 state=shell-anonymous reqs=REQ-001 -->\n<header>{{ shell }}</header>\n' > design/screens/pack.html
brief() { printf '# brief\ngrammar: 0.9.1\n\n```vid-design-manifest\n%s\n```\n' "$1" > DESIGN-BRIEF.md; }
brief 'P01 | default | REQ-001
C00 | shell-anonymous | REQ-001 | pins: one primary nav; a sign-in door'
if sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1; then echo 'design-pins: a 0.9.1 row without pins passed' >&2; exit 1; fi
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'no pins .*P01/default' || exit 1
brief 'P01 | default | REQ-001 | pins: the product name in the heading; one call to action
C00 | shell-anonymous | REQ-001 | pins: one primary nav; a sign-in door'
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || { echo 'design-pins: the pinned rows do not acquit' >&2; sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | tail -3 >&2; exit 1; }
# a resolution and pins: together, in either order, are legal; a stray field is not
brief 'P01 | default | REQ-001 | later: REQ-001 is later | pins: the product name in the heading
C00 | shell-anonymous | REQ-001 | pins: one primary nav; a sign-in door | descoped: A-002'
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1
brief 'P01 | default | REQ-001 | pins: the product name | someday: maybe
C00 | shell-anonymous | REQ-001 | pins: one primary nav'
if sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'bad resolution' || exit 1
# a pre-0.9.1 brief: reported, never convicted
printf '# brief\n\n```vid-design-manifest\nP01 | default | REQ-001\nC00 | shell-anonymous | REQ-001\n```\n' > DESIGN-BRIEF.md
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1 || exit 1
sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens 2>&1 | grep -q 'note: P01/default carries no pins: (pre-0.9.1 brief' || exit 1
exit 0
