#!/bin/sh
# Purpose: selftest case — the inventory and census lane judges the staged
# index, not the working tree (v0.9.6 spec 3.12, R12; §7 case 1). Stub
# courts, the real inventory court and a routes extractor reading app/*.py:
# an UNTRACKED product file declaring a route no row covers fails 0.9.5's
# hook (fixtures/pre-commit-0.9.5.sh, which judged the working tree); the
# 0.9.6 hook passes the same commit while the file is unstaged, and an
# unstaged edit to a tracked file adding such a route passes too; once the
# file is staged, the 0.9.6 hook refuses. With nothing differing the lane
# runs in place (the routes extractor records where it ran). Env: CHECKS.
set -eu
T=$(mktemp -d); O=$(mktemp -d); trap 'rm -rf "$T" "$O"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
OLD="$CHECKS/selftest/fixtures/pre-commit-0.9.5.sh"
fail() { echo "index-courts: $*" >&2; cat "$O/out" >&2 2>/dev/null; exit 1; }
cp "$CHECKS/inventory.sh" checks/inventory.sh
mkdir -p checks/extractors
cat > checks/extractors/routes.sh <<'EOF'
#!/bin/sh
# Purpose: toy routes extractor — one `route: <path>` line per route in app/*.py
pwd -P > .vid/routes.where
cat app/*.py 2>/dev/null | sed -n 's/^route: \([^ ]*\).*/ok \1/p'
EOF
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '# Inventory\n\n```vid-inventory\nROW-001 | surface | /a | anon | - | x | REQ-001 | owed: later\n```\n' > INVENTORY.md
printf 'route: /a\n' > app/a.py
mkdir -p .vid
g add -A && g commit -qm 'the real inventory court and a route'
verdict() { rm -rf "$(git rev-parse --git-path vid-memo)"; if sh "$1" > "$O/out" 2>&1; then echo pass; else echo refused; fi; }
# nothing differs: in place
stage one
[ "$(verdict checks/hooks/pre-commit)" = pass ] || fail 'the clean commit was refused'
[ "$(cat .vid/routes.where)" = "$(pwd -P)" ] || fail 'with nothing differing the lane did not run in place'
# an untracked product file with an uncovered route
printf '# Purpose: toy\nroute: /b\n' > app/b.py
[ "$(verdict "$OLD")" = refused ] || fail "0.9.5's hook passed an untracked uncovered route (the fixture no longer shows the measured failure)"
grep -q 'route /b exists in code' "$O/out" || fail "0.9.5's hook refused for another reason"
[ "$(verdict checks/hooks/pre-commit)" = pass ] || fail 'the 0.9.6 hook judged an untracked file'
[ "$(cat .vid/routes.where)" != "$(pwd -P)" ] || fail 'the lane ran in the working tree while an untracked file differed'
# an unstaged edit to a tracked file
printf 'route: /c\n' >> app/a.py
[ "$(verdict checks/hooks/pre-commit)" = pass ] || fail 'the 0.9.6 hook judged an unstaged edit'
g checkout -q -- app/a.py
# staged: refused
g add app/b.py
[ "$(verdict checks/hooks/pre-commit)" = refused ] || fail 'a staged uncovered route passed'
grep -q 'route /b exists in code' "$O/out" || fail 'the staged route was refused for another reason'
exit 0
