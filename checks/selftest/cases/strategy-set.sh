#!/bin/sh
# Purpose: selftest case — the owner's strategy (v0.9.7.2 spec 3.1, R1). `plan.sh strategy` is refused without
# --by owner and without the owner's words, and with --by anything else; refused, nothing changes. With both it writes
# `strategy: breadth-first` in RUN-STATE (missing before: depth first), keeps the words verbatim — two lines, quotes
# and all — in a decision file under .vid/plans/decisions/, and records `strategy set=breadth-first by=owner
# decision=<that file's id>`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "strategy-set: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
grep -q '^strategy:' .vid/RUN-STATE.md && fail 'the fixture starts with a strategy line'
if sh checks/plan.sh strategy breadth-first --words 'core first' > "$T/out" 2>&1; then fail 'set without --by owner'; fi
grep -q "the owner's choice" "$T/out" || fail 'the refusal does not say whose choice it is'
if sh checks/plan.sh strategy breadth-first --by owner > "$T/out" 2>&1; then fail 'set without the words'; fi
if sh checks/plan.sh strategy breadth-first --by develop --words 'core first' > "$T/out" 2>&1; then fail 'set by someone else'; fi
grep -q '^strategy:' .vid/RUN-STATE.md && fail 'a refusal wrote the strategy line'
grep -q '^strategy set' .vid/metrics-events && fail 'a refusal recorded an event'
W='"breadth first", it really paid —
core rows first, then harden'
sh checks/plan.sh strategy breadth-first --by owner --words "$W" > "$T/out" 2>&1 || fail 'the owner'"'"'s strategy was refused'
grep -qx 'strategy: breadth-first' .vid/RUN-STATE.md || fail 'no strategy line'
E=$(grep '^strategy set=breadth-first by=owner decision=' .vid/metrics-events) || fail 'no strategy event'
D=$(printf '%s\n' "$E" | sed -n 's/.* decision=\([^ ]*\) .*/\1/p')
F=".vid/plans/decisions/$D.why"; [ -f "$F" ] || fail "no decision file $F"
grep -qx 'set=breadth-first' "$F" && grep -qx 'by=owner' "$F" || fail 'the decision does not name the strategy and the owner'
[ "$(sed -n '/^words:$/,$p' "$F" | sed 1d)" = "$W" ] || fail 'the words are not kept verbatim'
exit 0
