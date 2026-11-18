#!/bin/sh
# Purpose: selftest case — `Decisions: none` is a Decisions section (0.26.10.29.5, DP-1 R8). At a head whose runs accept every row,
# a description holding the line `Decisions: none` (alone, or with the commit template's words after it), or a `Decisions:` line
# with `- ` lines under it, makes the decision `ticket: accepted` with no `decisions missing` line; the description is read through
# `github.sh pr-body`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-decide.sh"
fail() { echo "dp-r8-none: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
for b in 'ticket: #3

Decisions: none' 'ticket: #3

Decisions: none — nothing surprising' 'ticket: #3

Decisions:
- pages hold 20 items | why: the list fits
- the cookie is signed | why: tampering | scope: project'; do
  dpd_body "$b"; : > "$T/gh/log"; dpd_dc; [ "$RC" = 0 ] || fail "decide exited $RC"
  sed -n 2p "$T/out" | grep -qx 'ticket: accepted' || fail "a description with its Decisions section was not accepted: $(printf %s "$b" | tail -n 1)"
  grep -q '^decisions missing' "$T/out" && fail 'decisions missing beside a Decisions section'
  grep -q '^gh pr view 4 .*--json body' "$T/gh/log" || fail 'the description was not read'
done
exit 0
