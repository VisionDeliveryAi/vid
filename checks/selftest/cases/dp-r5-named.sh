#!/bin/sh
# Purpose: selftest case — RM names a decision for a step's tickets (0.26.10.29.5, DP-1 R5). On TW's toy with two more
# decisions, D-005 labelled for a row no ticket holds and D-006 marked about ViD's own settings: writer.sh name refuses an
# unknown step and an unknown id, writing nothing; names D-005 and D-006 for S02 and D-005 for S01, a line each in
# .vid/tw/named. S02's step ticket then quotes D-005 in its Decisions section, whatever its label, and never D-006; a fix
# ticket of S01 (ROW-003) quotes D-005 too. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "dp-r5-named: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
{ printf -- '- **D-005** the digest lists at most fifty jobs a page | why: one screen | enforced: convention | applies-to: ROW-999\n'
  printf -- '- **D-006** the run keeps one builder at a time | why: one machine | enforced: convention | scope: project | about: vid-settings\n'; } >> DECISIONS.md
g commit -qam 'two decisions'
tw_skel || fail 'the skeleton round failed'
# refusals, before anything is written
if sh "$W" name S99 D-005 > "$T/out" 2>&1; then fail 'an unknown step was named'; fi
if sh "$W" name S02 D-005,D-999 > "$T/out" 2>&1; then fail 'an unknown decision was named'; fi
[ ! -s .vid/tw/named ] || fail "a refused name wrote .vid/tw/named: $(cat .vid/tw/named)"
sh "$W" name S02 D-005,D-006 > "$T/out" 2>&1 || fail 'a known step and known decisions were refused'
sh "$W" name S01 D-005 > "$T/out" 2>&1 || fail 'S01 and D-005 were refused'
[ "$(cat .vid/tw/named)" = 'S02 D-005,D-006
S01 D-005' ] || fail "the named record is not a line a name: $(cat .vid/tw/named)"
# the step ticket and a fix ticket of the named steps
tw_start S02 || fail 'S02 was refused'; tw_post step S02 || fail "S02's ticket was refused"; sec "$TW_F" Decisions > "$T/d"
grep -q 'D-005\*\* the digest lists at most fifty jobs' "$T/d" || fail "S02's ticket lacks D-005, named for its step"
! grep -q 'D-006' "$T/d" || fail "a named decision about ViD's own settings reaches S02's ticket"
tw_hand 'fix ROW-003 | the saved state lost its line in the close run | close run 4300'
tw_post fix ROW-003 || fail "ROW-003's fix ticket was refused"; grep -qx -- '- step: S01' "$TW_F" || fail 'the fix ticket is not of S01'
sec "$TW_F" Decisions | grep -q 'D-005' || fail "the fix ticket of S01 lacks D-005, named for its step"
echo 'dp-r5-named: ok'
