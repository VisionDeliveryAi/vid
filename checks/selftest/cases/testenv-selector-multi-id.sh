#!/bin/sh
# Purpose: selftest case — the proof reads its whole selection (v0.9.8.1 R25, F-14). A gated toy whose stub writes one
# case per selection word: measure of two ids stores `selector=<id 1> <id 2>` on one line; a .vid/testenv an older
# measure wrote (the ids one a line, continuation lines piled up) is cleaned at the next write; and the proof's two
# runs each request both ids, so their cases equal the serial receipt's and the proof holds. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; wait; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "testenv-selector-multi-id: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/testenv >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm 'testenv and a reader'
export DSTUB_HOME="$(pwd -P)" DOCKER_TOTAL_MB=8192 STUB_BYSEL=1
# an older measure's file: the selector's ids one a line, a stale continuation from an earlier pass
mkdir -p .vid; printf 'stale-id-from-before\nselector=t/a.py::x\nt/a.py::y\nrows=ROW-001\n' > .vid/testenv
touch "$T/hold"; release_sampled "$T/hold"
STUB_HOLD="$T/hold" sh checks/testenv.sh measure --rows ROW-001,ROW-002 -- 't/a.py::one' 't/a.py::two' > "$T/out" 2>&1 || fail 'measure'
grep -qx 'selector=t/a.py::one t/a.py::two' .vid/testenv || fail 'the selector is not stored on one line'
grep -v '^[a-z][a-z-]*=' .vid/testenv | grep -q . && fail 'lines that are no key=value were kept'
sh checks/testenv.sh pick > "$T/out" 2>&1 && grep -q 'k=3 ' "$T/out" || fail 'pick'
: > "$STUB_LOG"
touch "$T/hold"; release_overlap "$T/hold" 2
STUB_HOLD="$T/hold" sh checks/testenv.sh prove > "$T/out" 2>&1 || fail 'the proof of a two-id selection failed'
[ "$(grep -c '^[^|]*|[^|]*|[^|]*|t/a.py::one t/a.py::two|.* up ' "$STUB_LOG")" -ge 2 ] || fail "the proof's runs did not each request both ids: $(grep ' up ' "$STUB_LOG" | cut -d'|' -f4 | sort | uniq -c)"
grep -q '^testenv prove ok ' "$T/out" || fail 'the proof did not report ok'
exit 0
