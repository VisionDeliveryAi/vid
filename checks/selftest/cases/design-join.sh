#!/bin/sh
# Purpose: selftest case — design-join.sh must fail closed on a manifest row
# with no marker in the returned pack. Exits 0 only if the court convicts.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
printf '# brief\n```vid-design-manifest\nP01 | default | REQ-001\n```\n' > DESIGN-BRIEF.md
mkdir -p design/screens
printf '<html><body>no markers</body></html>\n' > design/screens/p01.html
if sh "$CHECKS/design-join.sh" DESIGN-BRIEF.md design/screens >/dev/null 2>&1; then exit 1; fi
exit 0
