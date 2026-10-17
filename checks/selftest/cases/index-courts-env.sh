#!/bin/sh
# Purpose: selftest case — the index copy links the working tree's ignored
# top-level entries (v0.9.6 spec 3.12, R12; §7 case 2). An extractor needs
# an ignored top-level directory (an installed environment, .venv/ here);
# with an untracked file forcing the lane into the index copy, the directory
# is linked in and the census output the hook prints is the same, line for
# line, as the in-place run on a clean tree; the extractor records that it
# ran in the copy. Without the link it would report an orphan and the hook
# would refuse. Env: CHECKS.
set -eu
T=$(mktemp -d); O=$(mktemp -d); trap 'rm -rf "$T" "$O"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "index-courts-env: $*" >&2; cat "$O/out" >&2 2>/dev/null; exit 1; }
cp "$CHECKS/census.sh" checks/census.sh
mkdir -p checks/extractors .vid .venv/lib
cat > checks/extractors/invariant.env.sh <<'EOF'
#!/bin/sh
# Purpose: toy extractor that needs the installed environment
pwd -P > .vid/env.where
if [ -f .venv/lib/marker ]; then echo "ok $(cat .venv/lib/marker)"; else echo 'orphan env-missing .venv/lib/marker'; fi
EOF
printf '.venv/\n' >> .gitignore
printf 'installed\n' > .venv/lib/marker
g add -A && g commit -qm 'an extractor that needs the environment'
run() { rm -rf "$(git rev-parse --git-path vid-memo)"; sh checks/hooks/pre-commit > "$O/$1" 2>&1 || fail "the hook refused ($1)"; grep -v '^\(placement\|conformance\|imports\|seams\|inventory\|design-cite\|prd\|harness\) ok$' "$O/$1" > "$O/$1.census"; }
stage one
run inplace
[ "$(cat .vid/env.where)" = "$(pwd -P)" ] || fail 'the clean run did not run in place'
printf 'untracked\n' > app/untracked.txt
run copy
[ "$(cat .vid/env.where)" != "$(pwd -P)" ] || fail 'the lane did not run in the index copy'
grep -q 'census invariant.env: population=1 ok=1' "$O/copy" || { cp "$O/copy" "$O/out"; fail 'the extractor did not find the linked environment'; }
cmp -s "$O/inplace.census" "$O/copy.census" || { diff "$O/inplace.census" "$O/copy.census" >&2 || true; fail 'the copy printed a different census'; }
exit 0
