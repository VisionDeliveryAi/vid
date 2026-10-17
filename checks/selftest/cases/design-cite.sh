#!/bin/sh
# Purpose: selftest case — design-cite.sh must reject an uncited rule block
# (no citation at all), and a block after a NON-citing comment (sections run
# comment-to-comment — one citation never legalises a stylesheet); the
# field-proven pattern (one citation, several blocks, no interposed comment)
# must still pass.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
mkdir -p design/screens app
printf '<!-- @screen P01 state=default reqs=REQ-001 -->\n<html></html>\n' > design/screens/p01.html
printf '.uncited { color: var(--x); }\n' > app/styles.css
if sh "$CHECKS/design-cite.sh" >/dev/null 2>&1; then exit 1; fi
printf '/* Header (P01/default) */\n.a { color: var(--x); }\n/* misc helpers */\n.b { color: var(--y); }\n' > app/styles.css
if sh "$CHECKS/design-cite.sh" >/dev/null 2>&1; then exit 1; fi
printf '/* Header (P01/default) */\n.a { color: var(--x); }\n.a2 { color: var(--y); }\n' > app/styles.css
sh "$CHECKS/design-cite.sh" >/dev/null 2>&1 || exit 1
exit 0
