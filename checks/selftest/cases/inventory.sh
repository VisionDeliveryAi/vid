#!/bin/sh
# Purpose: selftest case — inventory.sh must reject a code route with no
# inventory row (route table via the routes extractor). Exits 0 only if the
# court convicts.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '# toy\n```vid-inventory\nROW-001 | surface | / | anonymous | n/a | home renders | REQ-001 | owed: scaffold\n```\n' > INVENTORY.md
mkdir -p checks/extractors
printf '#!/bin/sh\necho "ok /"\necho "ok /ghost"\n' > checks/extractors/routes.sh
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi
exit 0
