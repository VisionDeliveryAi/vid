#!/bin/sh
# Purpose: selftest case — the forbidden-terms court reads the project's own source, never ViD's installed checks/
# (0.26.10.29.3, R7, F32). A BASELINE.md forbidding `electron`, and a staged file under checks/ whose text holds
# "Electronics sales" (a self-test fixture's words) and whose extension the allowed list lacks: checks/conformance.sh
# passes, as checks/placement.sh already skips checks/. The same term staged in app/ is still refused, and so is the
# unlisted extension there. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "conformance-skips-checks: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
git init -q
printf '# Baseline\n\n```vid-allowed-extensions\n.md .sh .txt\n```\n\n```vid-forbidden\nelectron\n```\n' > BASELINE.md
g add -A; g commit -qm root
mkdir -p checks/selftest/fixtures app
printf 'Electronics sales | the shop\n' > checks/selftest/fixtures/shop.sh
printf 'name: shop\n' > checks/selftest/fixtures/shop.awk
g add checks
RC=0; sh "$CHECKS/conformance.sh" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "a forbidden term or an extension under checks/ alone was refused ($RC)"
printf 'import electron\n' > app/main.txt; g add app/main.txt
RC=0; sh "$CHECKS/conformance.sh" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q "forbidden term 'electron'" "$T/out" || fail "the term staged in app/ was not refused ($RC)"
grep -q 'checks/selftest' "$T/out" && fail 'the refusal quotes a line under checks/'
g reset -q app/main.txt; printf 'x\n' > app/main.awk; g add app/main.awk
RC=0; sh "$CHECKS/conformance.sh" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q "'app/main.awk' introduces extension '.awk'" "$T/out" || fail "an unlisted extension in app/ was not refused ($RC)"
echo 'conformance-skips-checks: ok'
