#!/bin/sh
# Purpose: selftest case — ViD's copy of a ticket's tests, through the hooks (v0.26.10.9 spec R12; §5
# vid-repo-copies). The toy spec-only tree (fixtures/spec-only.sh), its spec committed; then R12's two commits under
# the real hooks, with no product code present: ViD's copy of two tickets' test files under tests/acceptance/ (an
# ordinary commit) passes; INVENTORY.md alone, ROW-001..ROW-003 citing them (a standalone law commit), passes. The same
# files and INVENTORY.md in one commit are refused by the standalone-law rule (by=law-standalone); a test path outside
# tests/ is refused by the inventory court (by=inventory). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/spec-only.sh"
fail() { echo "vid-repo-copies: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
so_tree "$T/r"; so_commit 'the spec' > "$T/out" 2>&1 || fail 'the spec commit was refused'
copies() { mkdir -p tests/acceptance
  printf '# Purpose: ticket 7 acceptance tests\ndef test_wrong_password_refused():  # ROW-001\n    assert False\n' > tests/acceptance/test_signin.py
  printf '# Purpose: ticket 8 acceptance tests\ndef test_note_survives():  # ROW-002\n    assert False\ndef test_own_text():  # ROW-003\n    assert False\n' > tests/acceptance/test_notes.py; }
cite() { so_row ROW-001 tests/acceptance/test_signin.py; so_row ROW-002 tests/acceptance/test_notes.py; so_row ROW-003 tests/acceptance/test_notes.py; }
# both at once: refused by the standalone-law rule
copies; cite; g add -A
if g commit -q -m "$(so_msg 'copies and citations together')" > "$T/out" 2>&1; then fail 'the copies and INVENTORY.md in one commit were accepted'; fi
tail -n 1 .vid/hook-times | grep -q ' by=law-standalone' || fail 'the one-commit form was not refused by the standalone-law rule'
g reset -q; g checkout -q HEAD -- INVENTORY.md
# commit 1: the copies, an ordinary commit
g add tests/acceptance
g commit -q -m "$(so_msg 'ViD copy: tickets 7 and 8 acceptance tests')" > "$T/out" 2>&1 || fail "ViD's copy (an ordinary commit) was refused"
# commit 2: INVENTORY.md alone, a standalone law commit
cite; g add INVENTORY.md
g commit -q -m "$(so_msg 'rows 1-3 cite their tests')" > "$T/out" 2>&1 || fail 'INVENTORY.md citing the copies (a standalone law commit) was refused'
[ "$(git log --format=%s | head -n 1)" = 'rows 1-3 cite their tests' ] || fail 'the law commit did not land'
[ ! -d app ] || fail 'product code is present'
# a test path outside tests/: refused by the inventory court
so_row ROW-004 spec/test_x.py; g add INVENTORY.md
if g commit -q -m "$(so_msg 'a row citing outside tests/')" > "$T/out" 2>&1; then fail 'a test path outside tests/ was accepted'; fi
grep -q "GAP  ROW-004 .*unrecognized test field 'spec/test_x.py'" "$T/out" && tail -n 1 .vid/hook-times | grep -q ' by=inventory' || fail 'the path outside tests/ was not refused by the inventory court'
exit 0
