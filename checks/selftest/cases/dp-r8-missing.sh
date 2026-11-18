#!/bin/sh
# Purpose: selftest case — a pull request that states no decisions is not accepted (0.26.10.29.5, DP-1 R8). At a head whose runs
# accept every row, a description with no Decisions section, and one with an empty one (a `Decisions:` line and no `- ` line under
# it), make the decision `ticket: not yet` with the one line
# `decisions missing — the pull request's description has no Decisions section, nor Decisions: none`, against no row, beside every
# other line of the decision as the same head reads with the section there. No row's state, count, hold or record moves for it.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-decide.sh"
fail() { echo "dp-r8-missing: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
LINE="decisions missing — the pull request's description has no Decisions section, nor Decisions: none"
snap() { rm -rf "$T/s-$1"; mkdir -p "$T/s-$1"; for f in state counts limits halted record rulings pr-4-$RR_H12.rows; do cp ".vid/decide/$f" "$T/s-$1/$f" 2>/dev/null || : > "$T/s-$1/$f"; done; cp .vid/tw/handed "$T/s-$1/handed" 2>/dev/null || : > "$T/s-$1/handed"; }
dpd_body 'ticket: #3

Decisions: none'
dpd_dc; [ "$RC" = 0 ] || fail "decide exited $RC"; sed -n 2p "$T/out" | grep -qx 'ticket: accepted' || fail 'the head is not accepted with the section there'; dpd_rows > "$T/with"; snap with
for b in 'ticket: #3

What the branch does.' 'ticket: #3

Decisions:

More words.'; do
  dpd_body "$b"; dpd_dc; [ "$RC" = 0 ] || fail "decide exited $RC"
  sed -n 2p "$T/out" | grep -qx 'ticket: not yet' || fail 'a description with no Decisions section, or an empty one, was accepted'
  [ "$(grep -cxF "$LINE" "$T/out")" = 1 ] || fail 'not the one line decisions missing'
  dpd_rows > "$T/without"; cmp -s "$T/with" "$T/without" || fail "the decision's other lines differ beside the line: $(diff "$T/with" "$T/without" | head -n 4)"
  snap without; for f in state counts limits halted record rulings pr-4-$RR_H12.rows handed; do
    if [ "$f" = state ]; then cut -f1-4 "$T/s-with/$f" > "$T/a"; cut -f1-4 "$T/s-without/$f" > "$T/b"; else cp "$T/s-with/$f" "$T/a"; cp "$T/s-without/$f" "$T/b"; fi
    cmp -s "$T/a" "$T/b" || fail "the line moved .vid/decide/$f"; done
done
exit 0
