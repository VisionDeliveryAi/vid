#!/bin/sh
# Purpose: selftest case — `wait` counts from the kept receipt (v0.26.10.3 R9, F-43). A request served with the gate off
# (no run here: the receipt is kept with no .cases beside it) runs one passing case. Convicts unless its wait prints
# `cases passed=1`, never `cases none`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "wait-cases-kept: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/r"
mkdir -p checks/extractors; printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm reader
sh checks/plan.sh gate > /dev/null 2>&1 && fail 'the gate is on'
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'gate off' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); [ -n "$TK" ] || fail 'no ticket'
VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the run did not pass'
grep -qx 'cases passed=1' "$T/out" || fail "wait does not count the kept receipt's case: $(grep '^cases' "$T/out")"
exit 0
