#!/bin/sh
# Purpose: selftest case — no plan page is published (FB-5 A1, S4; it was GM-2 T12's private page). `next-move.sh shell` takes the
# re-plan page alone: plan.html is refused, and nothing is written beside it, while REPLAN-PAGE.html's shell is made as before, with no
# outside address. No skill writes, shells or publishes plan.html. Reads skills/ where they are. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "manual-plan-page-published: $*" >&2; cat "$T/o" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/v"; printf '<!doctype html><title>plan</title>\n' > "$T/v/plan.html"; cp "$T/v/plan.html" "$T/v/REPLAN-PAGE.html"
RC=0; sh "$CHECKS/next-move.sh" shell "$T/v/plan.html" > "$T/o" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'refused' "$T/o" || fail "next-move.sh shell took plan.html (exit $RC)"
[ "$(ls "$T/v" | paste -sd ' ' -)" = 'REPLAN-PAGE.html plan.html' ] || fail "a shell of plan.html was written: $(ls "$T/v" | paste -sd ' ' -)"
sh "$CHECKS/next-move.sh" shell "$T/v/REPLAN-PAGE.html" > "$T/o" 2>&1 || fail 'next-move.sh shell refused the re-plan page'
SH=$(sed -n 's/^shell //p' "$T/o"); [ -f "$SH" ] && [ "$(basename "$SH")" = replan-shell.html ] || fail "the re-plan page's shell is not written beside it: $(cat "$T/o")"
grep -q 'src="REPLAN-PAGE.html"' "$SH" && grep -q '<title>Re-plan page</title>' "$SH" && ! grep -qF 'plan.html' "$SH" || fail 'the shell does not show the re-plan page alone'
! grep -qiE 'https?://|//[a-z]' "$SH" || fail 'the shell holds an outside address'
S=$CHECKS/../skills; if [ -d "$S" ]; then grep -rlE '(^|[^A-Za-z-])plan(-shell)?\.html' "$S" > "$T/o" 2>/dev/null && fail 'a skill still names plan.html'; fi
echo 'manual-plan-page-published: ok'
