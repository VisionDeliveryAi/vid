#!/bin/sh
# Purpose: selftest case — the return block, vid-return 1 (v0.26.10.9 spec R21; §5 return-check). The briefing's I4
# example, its ids adapted, passes `ticket.sh return-check`, alone and against a ticket naming its three rows; a
# skeleton ticket's block (rows: none and the five skeleton: lines) passes. Each refusal of R21 is convicted once,
# naming its line or section: no block, two blocks, a missing section, a ticket row missing, doubled, not of the
# ticket, an unknown state, an unknown discovery kind, a fail and a not-run without a reason, a pass and a fail without
# ci:, and a skeleton block missing a skeleton: line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "return-check: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rc() { sh "$CHECKS/ticket.sh" return-check "$@" > "$T/out" 2>&1; }
blk() { printf 'Implements the ticket.\n\n```vid-return\n%s\n```\n' "$1"; }
I4='ticket: #142
rows:
  REQ-031/ROW-311   pass   ci: 9001
  REQ-031/ROW-312   pass   ci: 9001
  REQ-034/ROW-319   fail   ci: 9001   reason: see law-needed
decisions:
  - the list is kept in one table
discovered:
  - early-technical: the date helper, built ahead of plan
  - user-visible:    what a blank title shows
  - new-work:        an export the spec does not have
  - blocked-by:      #140
law-needed:
  - ROW-319: the test expects 404 where the requirement says 410
questions:
  - may a title be blank?'
printf 'role: builder    slice: 1    step: S1\nquoted-at: x\n\n## 1 rows\n\nROW-311 | behavior | REQ-031 | a | n/a | x | REQ-031 | tests/a.py\nROW-312 | behavior | REQ-031 | a | n/a | y | REQ-031 | tests/a.py\nROW-319 | behavior | REQ-034 | a | n/a | z | REQ-034 | tests/b.py\n\n## 2 items\n' > "$T/ticket.md"
blk "$I4" > "$T/b"; rc "$T/b" || fail 'the I4 example was refused'; grep -qx 'return-check: ok' "$T/out" || fail 'no ok line'
rc "$T/b" --ticket "$T/ticket.md" || fail 'the I4 example was refused against its ticket'
SK='ticket: #4
rows: none
skeleton: test-framework: the runner
skeleton: test-dir: tests/acceptance
skeleton: run-one: make test ONLY=<names>
skeleton: ci-workflow: CI
skeleton: report: vid-junit-<run attempt>
decisions:
  - none
discovered:
  - none
law-needed:
  - none
questions:
  - none'
blk "$SK" > "$T/b"; rc "$T/b" || fail 'the skeleton block was refused'
no() { printf '%s\n' "$1" > "$T/b"; if rc "$T/b" $3; then fail "passed: $2"; fi; grep -q -- "$4" "$T/out" || fail "the refusal of $2 does not say '$4'"; }
sub() { printf '%s\n' "$I4" | sed "$1"; }
no "$(printf 'Implements the ticket.\n')" 'no block' '' 'no ```vid-return block'
no "$(blk "$I4"; blk "$I4")" 'two blocks' '' '2 vid-return blocks'
no "$(blk "$(sub '/^questions:/,$d')")" 'a missing section' '' 'no questions: section'
no "$(blk "$(sub '/ROW-312/d')")" 'a ticket row missing' "--ticket $T/ticket.md" 'ROW-312 of the ticket is missing'
no "$(blk "$(sub 's#REQ-031/ROW-312#REQ-031/ROW-311#')")" 'a row doubled' '' 'ROW-311 appears twice'
no "$(blk "$(sub 's#ROW-312#ROW-399#')")" 'a row not of the ticket' "--ticket $T/ticket.md" 'ROW-399 is not a row of the ticket'
no "$(blk "$(sub 's#ROW-312   pass#ROW-312   maybe#')")" 'an unknown state' '' 'unknown state "maybe"'
no "$(blk "$(sub 's#new-work:#side-quest:#')")" 'an unknown discovery kind' '' 'unknown discovery kind "side-quest"'
no "$(blk "$(sub 's#   reason: see law-needed##')")" 'a fail without a reason' '' 'ROW-319: a fail gives its reason'
no "$(blk "$(sub 's#ROW-312   pass   ci: 9001#ROW-312   not-run#')")" 'a not-run without a reason' '' 'ROW-312: a not-run gives its reason'
no "$(blk "$(sub 's#ROW-311   pass   ci: 9001#ROW-311   pass#')")" 'a pass without ci:' '' 'ROW-311: a pass names its CI run'
no "$(blk "$(sub 's#fail   ci: 9001   reason#fail   reason#')")" 'a fail without ci:' '' 'ROW-319: a fail names its CI run'
no "$(blk "$(printf '%s\n' "$SK" | sed '/run-one/d')")" 'a skeleton block missing a skeleton: line' '' 'no skeleton: run-one: line'
exit 0
