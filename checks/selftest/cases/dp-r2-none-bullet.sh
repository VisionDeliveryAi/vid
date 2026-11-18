#!/bin/sh
# Purpose: selftest case — a `- none` line inside a Decisions section hides no decision under it (0.26.10.29.5, DP-1 R2, R8).
# A description whose section is `Decisions:`, then `- none`, then `- sessions use the shared store | why: shared storage`,
# reads that decision, never `none`; a section of `- none` alone reads none, and still counts as the section. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "dp-r2-none-bullet: $*" >&2; exit 1; }
printf 'ticket: #3\n\nDecisions:\n- none\n- sessions use the shared store | why: shared storage\n' > "$T/b1"
sh "$CHECKS/decisions.sh" section "$T/b1" > "$T/o1" 2>&1 || fail "section exited non-zero: $(cat "$T/o1")"
[ "$(cat "$T/o1")" = '- sessions use the shared store | why: shared storage' ] || [ "$(cat "$T/o1")" = 'sessions use the shared store | why: shared storage' ] || fail "a - none line hid the decision under it: $(cat "$T/o1")"
printf 'ticket: #3\n\nDecisions:\n- none\n' > "$T/b2"
sh "$CHECKS/decisions.sh" section "$T/b2" > "$T/o2" 2>&1 || fail "section exited non-zero: $(cat "$T/o2")"
[ "$(cat "$T/o2")" = none ] || fail "a section of - none alone did not read none: $(cat "$T/o2")"
exit 0
