#!/bin/sh
# Purpose: selftest case — a red run's result is short and sorted (v0.9.7.0.2
# spec 3.2, R2; §6 B-3). The result of a red request holds the status line
# (`status=<n> ran-to-end=<yes|no> capped=<yes|no> report=<receipt>`), the
# counts by case status, and checks/evidence.sh red's groups — never more
# than the stated lines, and never the run's log. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "wait-result: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/evidence.sh" checks/; mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm 'a reader'
STUB_CASE=failed STUB_STATUS=1 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a red run' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
RC=0; VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] || fail "wait exited $RC, not the run's own 1"
sed -n 1p "$T/out" | grep -qE '^status=1 ran-to-end=yes capped=no report=[^ ]+\.run-[0-9TZ]+-[0-9]+\.xml$' || fail 'the first line is not the status line'
grep -qx 'cases failed=1' "$T/out" || fail 'no counts by case status'
grep -q '^red .* setup=0 failed=1$' "$T/out" && grep -q '^group failed n=1 ' "$T/out" || fail 'no sorted groups'
[ "$(grep -c . "$T/out")" -le 27 ] || fail 'the result is longer than its stated lines'
grep -q 'ViD test: report' "$T/out" && fail 'wait printed the run log'
grep -q 'ViD test: report' ".vid/requests/$TK/log" || fail 'the log does not hold the run output'
exit 0
