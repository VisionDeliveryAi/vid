#!/bin/sh
# Purpose: selftest case — outside the gate a test edit stales the whole file
# (v0.9.6.1 spec 3.4, revision 11, amendment 5; §6; R7). The same edit as
# test-edit-one, with the run stopped: all three rows read stale, as in
# 0.9.6. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"; . "$CHECKS/selftest/fixtures/test-edit.sh"
fail() { echo "test-edit-gate-off: $*" >&2; exit 1; }
edit_repo "$T/repo"
line 10 '    b = 3'; commit_all 'test_002 changed'
sed 's/^run: .*/run: stopped paused/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
sh checks/plan.sh gate > /dev/null 2>&1 && fail 'the gate is still on'
printf 'ROW-001\tS1\t\nROW-002\tS1\t\nROW-003\tS1\t\n' > "$T/map"
for r in ROW-001 ROW-002 ROW-003; do
  s=$(sh checks/evidence.sh rows --at HEAD --map "$T/map" | awk -F'\t' -v r="$r" '$1 == r { print $2 }')
  [ "$s" = stale ] || fail "outside the gate $r is $s, not stale as in 0.9.6"
done
exit 0
