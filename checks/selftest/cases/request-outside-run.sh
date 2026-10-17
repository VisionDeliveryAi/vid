#!/bin/sh
# Purpose: selftest case — requests outside a develop run (v0.9.7.0.2 spec
# 3.1, R5; §6 C-6). With no live run, `iterate` and `full` requests run
# (the ticket here, in this checkout's .vid/), and `close` and `checkpoint`
# are refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "request-outside-run: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"
sh checks/plan.sh gate > /dev/null 2>&1 && fail 'the gate is on'
for a in "--type iterate --role fixer --try t1 --rows ROW-001" "--type full --role orchestrator"; do
  # shellcheck disable=SC2086
  if [ "${a#*iterate}" != "$a" ]; then sh checks/test.sh request $a --why 'outside a run' -- tests/x > "$T/out" 2>&1 || fail "refused outside a run: $a"
  else sh checks/test.sh request $a --why 'outside a run' > "$T/out" 2>&1 || fail "refused outside a run: $a"; fi
  K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
  [ -d ".vid/requests/$K" ] || fail "no ticket here: $a"
  VID_WAIT_MAX=60 sh checks/test.sh wait "$K" > "$T/out" 2>&1 || fail "did not run green: $a"
done
if sh checks/test.sh request --type close --role orchestrator --steps S1 --why 'outside a run' -- sel > "$T/out" 2>&1; then fail 'a close was accepted outside a run'; fi
grep -q 'only inside a develop run' "$T/out" || fail 'the close refusal does not say why'
if sh checks/test.sh request --type checkpoint --role orchestrator --why 'outside a run' -- sel > "$T/out" 2>&1; then fail 'a checkpoint was accepted outside a run'; fi
grep -q 'only inside a develop run' "$T/out" || fail 'the checkpoint refusal does not say why'
exit 0
