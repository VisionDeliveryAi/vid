#!/bin/sh
# Purpose: selftest case — the inventory court agrees with the census court on a census over a folder not there yet
# (0.26.10.29.3, R7, F32). A rule row written with an inline census command that searches src/, which does not exist:
# checks/census.sh refuses it (the command wrote to standard error), and checks/inventory.sh now refuses it too, naming
# the row and saying to use an extractor-path census. The same row once src/ exists passes; a rule row whose census is an
# extractor path is not judged by this court. Inside a repository the row is judged while it is new against HEAD: once
# committed, the inventory court leaves it to the census court. The test is the census court's own: any word on standard
# error refuses, so a `git grep` over the missing folder, which says so in other words, is refused too, its words quoted.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "inventory-refuses-census-on-missing-path: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
printf '```vid-placement\napp/\nsrc/\n```\n' > CLAUDE.md
row() { printf '# Inventory\n\n```vid-inventory\nROW-001 | behavior | list | user | n/a | the list shows ten | REQ-001 | owed: later\nrule | RULE-001 | every handler is bounded | grep -rl handler src/ | 1 | owed: census-armed — later\nrule | RULE-002 | every query is bounded | checks/extractors/invariant.bounded.sh | 1 | owed: census-armed — later\n```\n' > INVENTORY.md; }
iv() { RC=0; sh "$CHECKS/inventory.sh" > "$T/out" 2>&1 || RC=$?; }
row
RC=0; sh "$CHECKS/census.sh" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'RULE-001  census command wrote to standard error' "$T/out" || fail "the census court did not refuse the census over a missing folder ($RC) — the fixture is not the case"
iv
[ "$RC" = 1 ] || fail "the inventory court passed a census command that searches a missing folder ($RC)"
grep -q '^GAP  RULE-001 .*a path that does not exist' "$T/out" || fail 'the refusal does not name RULE-001 and the missing path'
grep -q 'extractor-path census' "$T/out" || fail 'the refusal does not say to use an extractor-path census'
grep -q '^GAP  RULE-002' "$T/out" && fail 'the extractor-path census was judged'
mkdir src; printf 'handler\n' > src/a.txt
iv; [ "$RC" = 0 ] || fail "the census over an existing folder was refused ($RC)"
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
git init -q; g add -A; g commit -qm law
rm -rf src
iv; grep -q '^GAP  RULE-001' "$T/out" && fail 'a committed rule row was judged again'
[ "$RC" = 0 ] || fail "the committed row was refused ($RC)"
sed 's#grep -rl handler src/#grep -rl handler lib/#' INVENTORY.md > x && mv x INVENTORY.md
iv; [ "$RC" = 1 ] && grep -q '^GAP  RULE-001' "$T/out" || fail "a rule row changed against HEAD to search a missing folder was not refused ($RC)"
# any word on standard error, as the census court reads it: a search tool that names the missing folder in other words
sed 's#grep -rl handler lib/#git grep -l handler lib/#' INVENTORY.md > x && mv x INVENTORY.md
RC=0; sh "$CHECKS/census.sh" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'RULE-001  census command wrote to standard error' "$T/out" || fail "the census court did not refuse the git grep form ($RC) — the fixture is not the case"
iv; [ "$RC" = 1 ] && grep -q '^GAP  RULE-001 .*wrote to standard error' "$T/out" || fail "the inventory court passed a census command the census court refuses for writing to standard error ($RC)"
grep -q '^GAP  RULE-001 .*lib/' "$T/out" || fail "the refusal does not quote the command's standard error"
echo 'inventory-refuses-census-on-missing-path: ok'
