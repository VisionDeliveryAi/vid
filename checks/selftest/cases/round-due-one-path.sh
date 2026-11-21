#!/bin/sh
# Purpose: selftest case — every ticket the round owes goes out by tw-hand's steps (GM-4 K1: no ticket, amendment, withdrawal, fix
# or reached ticket by any other path). Read: round.sh's due_ writes and posts nothing itself (no writer.sh write, tw-post, tw-close
# or tw-tell of its own): each owed line, `withdraw`, `tell`, `amend` and `new …`, goes through `github.sh tw-act`, the steps
# tw-hand's own actions run (its amend, withdraw, close, tell, fix, reached and write each through tw-act), with the round's own
# refusal kept (tw-act's exit 4, the write refused, is the round's `refuse`). tw-act's write of a fix or reached ticket prints its
# step's publish warnings, as tw-hand's did. Env: CHECKS.
set -eu
fail() { echo "round-due-one-path: $*" >&2; exit 1; }
RS=$CHECKS/round.sh; GS=$CHECKS/github.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; D=$T/d
awk '/^due_\(\) \{/ { s = 1 } s && /^cmd_next\(\)/ { exit } s' "$RS" > "$D"
[ -s "$D" ] || fail 'no due_ in round.sh'
for w in 'wr write' 'tw-post' 'tw-close' 'tw-tell'; do ! grep -q -- "$w" "$D" || fail "round.sh's due_ still runs $w itself"; done
for k in withdraw tell amend new; do grep -q "tw-act $k\|tw-act \"\$@\"" "$D" || fail "round.sh's due_ does not send $k through github.sh tw-act"; done
grep -q '4) refuse' "$D" || fail "round.sh's due_ does not keep the round's refusal for a write tw-act refuses (its exit 4)"
grep -q '^  tw-act)' "$GS" || fail 'github.sh has no tw-act entry'
awk '/^  tw-hand\)/ { s = 1 } s && /^  [a-z-]*\)/ && !/^  tw-hand\)/ { exit } s' "$GS" > "$D"
for k in amend withdraw tell new; do grep -q "tw-act $k" "$D" || fail "tw-hand does not run its $k through tw-act"; done
! grep -q 'writer.sh" write\|"\$0" tw-post\|"\$0" tw-close\|"\$0" tw-tell' "$D" || fail 'tw-hand still writes or posts a ticket itself, beside tw-act'
awk '/^  tw-act\)/ { s = 1; next } s && /^  [a-z-]*\)/ { exit } s' "$GS" | grep -q 'plan.sh" warnings' || fail "tw-act does not print a fix or reached ticket's publish warnings"
exit 0
