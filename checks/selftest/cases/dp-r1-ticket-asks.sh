#!/bin/sh
# Purpose: selftest case — every ticket asks for the decisions on its pull request (0.26.10.29.5, DP-1 R1). On TW's toy, the
# skeleton ticket, a step ticket (S02) and a fix ticket (ROW-003) each hold, in their asks, the Decisions paragraph word for word,
# right after the Questions paragraph, and each passes writer.sh check; the check refuses a ticket whose asks lack it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "dp-r1-ticket-asks: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
cat > "$T/para" <<'E'
Decisions: the pull request's body holds a section that begins with the line Decisions:, then one line a technical decision of the branch, "- what was chosen | why: the reason", or the one line Decisions: none. A decision is a choice that picked between plausible alternatives, constrains later code, or would surprise a competent newcomer. A hand-rolled security mechanism (cryptography, one-time codes, session tokens, signing) is always one, and names the standard it implements; so is a change to stored data, naming what it changes and how it is rolled back. A new or extended lifecycle, the states a stored record moves through, is a question on this ticket before it is built. A line that bears on many areas of the product ends with | scope: project. Keep the section current from the first head on; ViD records it when the pull request merges. A pull request whose body lacks the section is not accepted: its decision reads not yet until the section is there.
E
P=$(cat "$T/para")
has() {   # has <ticket> <kind>: the paragraph in the asks, right after the Questions paragraph, and the check passes
  sec "$1" Asks > "$T/asks"; grep -qxF "$P" "$T/asks" || fail "the $2 ticket's asks lack the Decisions paragraph, word for word"
  awk '/^Questions: / { q = NR } q && NR == q + 2 { print; exit }' "$T/asks" > "$T/next"; [ "$(cat "$T/next")" = "$P" ] || fail "in the $2 ticket the Decisions paragraph does not follow the Questions paragraph"
  sh "$W" check "$1" > "$T/out" 2>&1 || fail "the $2 ticket fails writer.sh check"; }
tw_skel || fail 'the skeleton round failed'; has "$TW_F" skeleton; SK=$TW_F
tw_start S02 || fail 'S02 was refused'; tw_post step S02 || fail "S02's ticket was refused"; has "$TW_F" step
tw_hand 'fix ROW-003 | the saved state lost its line in the close run | close run 4300'
tw_post fix ROW-003 || fail "ROW-003's fix ticket was refused"; has "$TW_F" fix
# a ticket whose asks lack it is refused
grep -vxF "$P" "$SK" > "$T/cut.md"
if sh "$W" check "$T/cut.md" > "$T/out" 2>&1; then fail 'a ticket whose asks lack the Decisions paragraph passed the check'; fi
grep -q 'the asks do not ask for the decisions' "$T/out" || fail 'the missing paragraph is not named'
echo 'dp-r1-ticket-asks: ok'
