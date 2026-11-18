#!/bin/sh
# Purpose: selftest case — the technical foundation as a page (usability, B3). On the pages' toy, `pages.sh foundation`
# writes .vid/pages/FOUNDATION.md: BASELINE.md, ARCHITECTURE.md and DECISIONS.md in that order, as written; every
# decision line of DECISIONS.md once, as what was decided and why, the one `origin: proposal` marked "ViD's proposal"
# and no other; "Where it runs" shows the hosting answers by name; the blocks written for ViD's own checks (the
# fenced machine blocks and the annotations) are folded under "For ViD's checks". Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-foundation: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
pg_toy "$T/toy"
sh "$CHECKS/pages.sh" foundation > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'foundation failed'; }
M=.vid/pages/FOUNDATION.md; [ -f "$M" ] && [ -f .vid/pages/FOUNDATION.html ] || fail 'no page'
# the three documents, in order
[ "$(grep -nE '^## JobDigest — (BASELINE|ARCHITECTURE|DECISIONS)$' "$M" | cut -d' ' -f4 | tr '\n' ' ')" = 'BASELINE ARCHITECTURE DECISIONS ' ] || fail 'the three documents are not there, in order'
grep -qF '| web | a server-rendered app | a single-page framework |' "$M" && grep -qF '"It'"'"'s a website."' "$M" || fail 'BASELINE.md is not as written'
grep -qF '| app/digest | the daily digest | digests | `app/digest` — send | none |' "$M" || fail 'ARCHITECTURE.md is not as written'
# every decision line once, ViD's proposal marked on the one that is
n=$(grep -cE '^- \*\*D-[0-9]+\*\*' DECISIONS.md)
[ "$(grep -cE '\{id: D-[0-9]+\}' "$M")" = "$n" ] || fail "not $n decision lines"
for d in $(grep -oE '^- \*\*D-[0-9]+' DECISIONS.md | sed 's/^- \*\*//'); do [ "$(grep -cF "{id: $d}" "$M")" = 1 ] || fail "$d is not on the page once"; done
grep -F '{id: D-001}' "$M" | grep -qF -- '- one digest per saved search — why: the owner' || fail 'a decision is not what was decided and why'
grep -F '{id: D-002}' "$M" | grep -qF "ViD's proposal" || fail "the proposal is not marked ViD's"
[ "$(grep -cF "ViD's proposal" "$M")" = 1 ] || fail "a decision the owner gave is marked ViD's proposal"
# where it runs, by name; the blocks for ViD's checks folded
awk '/^### Where it runs$/ { on = 1; next } on && /^##/ { exit } on' "$M" > "$T/w"
grep -qxF -- '- platform: a hosting platform' "$T/w" && grep -qxF -- '- access: env HOST_TOKEN' "$T/w" || fail 'the hosting answers are not shown by name'
grep -q '```vid-hosting' "$M" && fail 'the hosting block is shown as a machine block'
[ "$(grep -cxF "::: fold For ViD's checks" "$M")" -ge 3 ] || fail "the machine blocks are not folded for ViD's checks"
awk "/^::: fold For ViD's checks\$/ { on = 1 } on && /^:::\$/ { on = 0 } !on && (/sqlalchemy/ || /an annotation for the import court/ || /^\\.md \\.sh/) { bad = 1 } END { exit bad }" "$M" || fail "a block for ViD's checks is outside its fold"
exit 0
