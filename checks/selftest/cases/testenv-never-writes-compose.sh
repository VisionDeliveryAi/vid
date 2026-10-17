#!/bin/sh
# Purpose: selftest case — the test-environment step changes no tracked
# file (v0.9.6 spec 3.9, R9; §7 case 19). A whole step — measure, pick
# (k=3), prove, record — in a gated toy whose compose file carries fixed
# ports and a fixed container name: afterwards `git status --porcelain` is
# empty, docker-compose.test.yml is byte-identical to the commit, and what
# the step wrote is under .vid/ only (the budget, the working figures, the
# receipts and the event). v0.9.7.0.11 (3.5, R5): the proof's runs are
# held a moment so they overlap, as a proof must. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; wait; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "testenv-never-writes-compose: $*" >&2; cat "$T/out" >&2 2>/dev/null; git status --porcelain >&2; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm 'testenv and a reader'
export DSTUB_HOME="$(pwd -P)" DOCKER_TOTAL_MB=8192
cp docker-compose.test.yml "$T/compose.before"
touch "$T/hold"; release_sampled "$T/hold"   # v0.9.7.3 (R7): held until sampled, not for 3 s
STUB_HOLD="$T/hold" sh checks/testenv.sh measure --rows ROW-001 -- 'tests/x' > "$T/out" 2>&1 || fail 'measure'
sh checks/testenv.sh pick > "$T/out" 2>&1 && grep -q 'k=3 ' "$T/out" || fail 'pick'
touch "$T/hold"; release_overlap "$T/hold" 2   # v0.9.7.0.11 (R5): the proof's two runs overlap — v0.9.7.3 (R7): held until both are up
STUB_HOLD="$T/hold" sh checks/testenv.sh prove > "$T/out" 2>&1 || fail 'prove'
sh checks/testenv.sh record > "$T/out" 2>&1 || fail 'record'
[ -z "$(git status --porcelain)" ] || fail 'the step changed a tracked or untracked file outside .vid/'
cmp -s "$T/compose.before" docker-compose.test.yml || fail 'the compose file changed'
git diff --quiet HEAD || fail 'a tracked file differs from the commit'
[ -f .vid/budget ] && [ -f .vid/testenv ] || fail 'the step wrote nothing under .vid/'
exit 0
