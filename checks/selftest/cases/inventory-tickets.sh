#!/bin/sh
# Purpose: selftest case — the inventory court in a ticket-mode spec repository (v0.26.10.26.7, R5 a, W-6), checks/inventory.sh on
# the writer's toy. With RUN-STATE's mode: tickets and no CLAUDE.md, it reads no placement and runs its other checks: its verdict is
# the one it gives with CLAUDE.md, and a hostility row with no disable: toggle is still convicted. Outside ticket mode, no CLAUDE.md still
# fails closed. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "inventory-tickets: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; IV=$CHECKS/inventory.sh; iv() { RC=0; sh "$IV" "$@" > "$T/out" 2>&1 || RC=$?; }
grep -q '^mode: tickets' .vid/RUN-STATE.md || fail 'the toy is not in ticket mode'
iv; RC0=$RC; cp "$T/out" "$T/out0"; rm -f CLAUDE.md
iv; ! grep -q 'CLAUDE.md missing' "$T/out" || fail 'ticket mode, no CLAUDE.md: the court failed closed on it'
grep -q '^inventory: rows=' "$T/out" || fail 'ticket mode, no CLAUDE.md: the other checks did not run'; [ "$RC" = "$RC0" ] || fail "ticket mode, no CLAUDE.md: exit $RC, with it $RC0"
awk '/^hostility \| HOS-001 \|/ { sub(/[|][^|]*disable:[^|]*/, "| no toggle") } { print }' INVENTORY.md > "$T/i"; ! cmp -s "$T/i" INVENTORY.md || fail 'no hostility row to plant on'; cp "$T/i" INVENTORY.md
iv; [ "$RC" = 1 ] && grep -q "^GAP  HOS-001 (INV-001) — no usable 'disable:' toggle" "$T/out" || fail "ticket mode: a hostility row with no disable: toggle was not convicted ($RC)"; git checkout -q -- INVENTORY.md
sed '/^mode:/d' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md; iv; [ "$RC" = 1 ] && grep -q 'CLAUDE.md missing — failing closed' "$T/out" || fail "outside ticket mode, no CLAUDE.md did not fail closed ($RC)"
echo 'inventory-tickets: ok'
