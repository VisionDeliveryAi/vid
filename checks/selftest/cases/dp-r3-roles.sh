#!/bin/sh
# Purpose: selftest case — the ticket's own independence rule keeps every decision's why from every grader (0.26.10.29.5, DP-1
# R3). On TW's toy, a step ticket's (S02) rule 2 says GR reads the ticket without the why: of each decision, and a fix ticket
# also without its failed: lines and its History; no ticket limits the why's drop to a fix ticket; the step ticket passes
# writer.sh check, its roles ViD's word for word. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "dp-r3-roles: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
tw_skel || fail 'the skeleton round failed'
tw_start S02 || fail 'S02 was refused'; tw_post step S02 || fail "S02's ticket was refused"; F=$TW_F
sec "$F" Roles > "$T/roles"
grep -q '^2\. GR is .* GR reads the ticket without the why: of each decision, and a fix ticket also without its failed: lines and its History: the rows, the code and the results alone\.$' "$T/roles" || fail "the step ticket's rule 2 does not keep each decision's why from GR"
! grep -q 'In a fix ticket, GR reads the ticket without' "$T/roles" || fail "the step ticket's rule 2 limits the why's drop to a fix ticket"
sh "$W" check "$F" > "$T/out" 2>&1 || fail 'the step ticket fails writer.sh check'
echo 'dp-r3-roles: ok'
