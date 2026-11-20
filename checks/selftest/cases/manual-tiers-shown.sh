#!/bin/sh
# Purpose: selftest case — the tiers shown (GM-2 T9). On the planner's toy in GitHub manual, #2 (S02) published, open and
# taken by an assignee, #3 (S03) published, open and not taken. After the applied commit ROW-001 (in #2) and ROW-006 (in #3)
# are reset, and ROW-021, of stage 2 with no open ticket, is added to S05. Over three calls (`next.sh triggers`, then
# `next.sh shown` with its lines): the critical reset-taken ROW-001 shows each time; the important reset-not-taken ROW-006
# shows at the first call and is counted unchanged at the second; the minor added-inactive ROW-021 is never shown, only
# counted. At the third call #3 is taken, so ROW-006 rises to the critical reset-taken and shows again; ROW-001 is reset once
# more and stays shown, its evidence key in .vid/next/shown new. Each `tiers` line counts every raised trigger once;
# `triggers` writes nothing; `shown` keeps each move of the listing, with its hash, in .vid/next/moves. #3
# was created 8 days less 30 seconds before call 1, so its important not-taken trigger shows at call 1 (7 days) and is counted
# unchanged at call 2, 31 seconds after that time was set (8 days): a day count is no change. With the handed record there, writer.sh due owes
# #2's amendment; S02's tests change between calls 2 and 3 (ROW-013 out), and the amend move's hash changes with them. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "manual-tiers-shown: $*" >&2; cat "$T/tr" >&2 2>/dev/null; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
ago() { agos $(( $1 * 86400 )); }
agos() { _s=$(( $(date -u +%s) - $1 )); date -u -r "$_s" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "@$_s" '+%Y-%m-%dT%H:%M:%SZ'; }
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied; : > .vid/tw/handed
D1=$(ago 1); [ -n "$D1" ] || fail 'no date a day ago'
{ printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=%s\n' "$D1"
  printf 'published 3 kind=step step=S03 rows=ROW-006 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=%s\n' "$D1"; } > .vid/tw/log
printf '# Step ticket S02\n\n## Rows\n\n> %s\n> %s\n' "$(grep '^ROW-001 ' INVENTORY.md)" "$(grep '^ROW-005 ' INVENTORY.md)" > .vid/tw/out/issue-2.md
printf '# Step ticket S03\n\n## Rows\n\n> %s\n' "$(grep '^ROW-006 ' INVENTORY.md)" > .vid/tw/out/issue-3.md
rd() { { printf 'ticket\t2\tOPEN\tana\t%s\n' "$D1"; printf 'body\t2\t%s\n' '## Tests' '- ROW-001' '- ROW-005'
  printf 'ticket\t3\tOPEN\t%s\t%s\n' "$1" "$D3"; printf 'body\t3\t%s\n' '## Tests' '- ROW-006'; } > .vid/next/read; }
sub() { sed "$1" INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; }
sub 's/^\(ROW-001 .*\)holding only jobs it has not sent before\./\1holding only jobs it has not sent before, newest first./'
sub 's/^\(ROW-006 .*\)and the unsubscribe help link\./\1and the unsubscribe help link, on every page./'
pt_rs 's/^\(step S05 .*rows: ROW-017\)/\1 ROW-021/'
pt_after ROW-020 'ROW-021 | behavior | REQ-003 | anonymous | n/a | A search for a job title finds the same job under its common short name. Fails if a golden-set query by short name misses a must-appear job. | REQ-003 | owed: spec-only — first stage | origin: REQ-003'
grep -q 'newest first' INVENTORY.md && grep -q 'on every page' INVENTORY.md && grep -q '^ROW-021 ' INVENTORY.md && grep -q '^step S05 .*ROW-017 ROW-021' .vid/RUN-STATE.md || fail 'the changes did not land'
snap() { find .vid -type f | sort | while read -r f; do printf '%s %s\n' "$f" "$(git hash-object "$f")"; done; }
call() { snap > "$T/s0"; sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail "call $1: next.sh triggers failed"; snap > "$T/s1"
  cmp -s "$T/s0" "$T/s1" || fail "call $1: triggers wrote a record: $(diff "$T/s0" "$T/s1" | head -n 3)"
  sh "$CHECKS/next.sh" shown "$T/tr" > "$T/out" 2>&1 || fail "call $1: next.sh shown failed"; }
shows() { grep -q "^trigger${TB}$2${TB}$3${TB}$4${TB}" "$T/tr" || fail "call $1: $3 $4 is not shown $2"; }
quiet() { grep -q "^quiet${TB}$2${TB}$3${TB}$4${TB}.*${TB}$5\$" "$T/tr" && ! grep -q "^trigger${TB}[a-z]*${TB}$3${TB}$4${TB}" "$T/tr" || fail "call $1: $3 $4 is not counted $5, unshown"; }
tiers() { grep -qx "tiers${TB}$2" "$T/tr" || fail "call $1: the tiers line is not '$2': $(grep '^tiers' "$T/tr")"; }
key() { awk -F'\t' -v w="$1" -v s="$2" '$1 == w && $2 == s { print $4 }' .vid/next/shown; }
S0=$(date -u +%s); D3=$(agos $(( 8 * 86400 - 30 ))); [ -n "$D3" ] || fail 'no date 8 days less 30 seconds ago'
rd -; call 1; shows 1 critical reset-taken ROW-001; shows 1 important reset-not-taken ROW-006; quiet 1 minor added-inactive ROW-021 minor
grep -q "^trigger${TB}important${TB}not-taken${TB}#3${TB}.* 7 days ago;" "$T/tr" || fail 'call 1: #3, 7 days old, is not shown not taken'
tiers 1 'critical=1 important=2 unchanged=0 minor=1 declined=0'
awk -F'\t' '$1 == "move" { print $2 "\t" $3 "\t" $4 }' "$T/tr" > "$T/mv"; [ -s "$T/mv" ] && cmp -s "$T/mv" .vid/next/moves || fail "call 1: .vid/next/moves is not the listing's moves with their hashes"
[ -n "$(key reset-taken ROW-001)" ] && [ -n "$(key reset-not-taken ROW-006)" ] && [ -z "$(key added-inactive ROW-021)" ] || fail "call 1: .vid/next/shown does not hold exactly what was shown: $(cat .vid/next/shown)"
K1=$(key reset-taken ROW-001)
W=$(( S0 + 31 - $(date -u +%s) )); [ "$W" -le 0 ] || sleep "$W"
rd -; call 2; shows 2 critical reset-taken ROW-001; quiet 2 important reset-not-taken ROW-006 unchanged; quiet 2 minor added-inactive ROW-021 minor
grep -q "^quiet${TB}important${TB}not-taken${TB}#3${TB}.* 8 days ago;.*${TB}unchanged\$" "$T/tr" || fail 'call 2: #3, a day older and nothing else, is not counted unchanged'
tiers 2 'critical=1 important=0 unchanged=2 minor=1 declined=0'
M2=$(awk -F'\t' '$1 == "amend" && $2 == "#2" { print $3 }' .vid/next/moves); [ -n "$M2" ] || fail "call 2: no amend #2 move kept: $(cat .vid/next/moves)"
pt_rs 's/^\(step S02 .*rows: .*\) ROW-013 /\1 /'; ! grep -q '^step S02 .* ROW-013 ' .vid/RUN-STATE.md || fail 'ROW-013 did not leave S02'
sub 's/newest first\./newest first, ten a page./'; grep -q 'ten a page' INVENTORY.md || fail 'ROW-001 was not reset again'
rd bo; call 3; shows 3 critical reset-taken ROW-001; shows 3 critical reset-taken ROW-006; quiet 3 minor added-inactive ROW-021 minor
! grep -q "^[a-z]*${TB}[a-z]*${TB}reset-not-taken${TB}ROW-006${TB}" "$T/tr" || fail 'call 3: ROW-006 is still read as not taken'
tiers 3 'critical=2 important=0 unchanged=0 minor=1 declined=0'
[ -n "$(key reset-taken ROW-001)" ] && [ "$(key reset-taken ROW-001)" != "$K1" ] || fail "call 3: ROW-001 reset again keeps its old evidence key"
M3=$(awk -F'\t' '$1 == "amend" && $2 == "#2" { print $3 }' .vid/next/moves); [ -n "$M3" ] && [ "$M3" != "$M2" ] || fail "call 3: the amend #2 move's hash did not change with its step's tests"
exit 0
