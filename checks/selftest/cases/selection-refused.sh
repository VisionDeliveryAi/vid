#!/bin/sh
# Purpose: selftest case — a selection word with a space or a quote is
# refused at once (v0.9.7.0.9 spec 3.3, R3). `request -- -k 'a or b'` is
# refused naming the word, with no ticket and no stack; so is a quoted word,
# and a spaced --deployed-selection word; the direct run refuses the same
# words before any lock or stack. A selection without such a word goes
# through request → serve → run with the selector string and its receipt's
# hash exactly as before: `-- tests/x.py::t1 tests/y.py::t2` reaches the
# compose command as `tests/x.py::t1 tests/y.py::t2`, and the receipt is
# named by that string's cksum. A word holding a glob character reaches the
# runner unexpanded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "selection-refused: $*" >&2; cat "$T/out" "$STUB_LOG" >&2 2>/dev/null; exit 1; }
refused() { # <word> <arguments…>: refused, exit 2, naming the word; no ticket, no stack call
  _w=$1; shift; : > "$STUB_LOG"; RC=0; sh checks/test.sh "$@" > "$T/out" 2>&1 || RC=$?
  [ "$RC" -eq 2 ] || fail "not refused (exit $RC): $*"
  grep -qF "ViD test: refused — the selection word '$_w' holds a space or a quote, which the harness command can't carry; select by test ids, without spaces" "$T/out" || fail "the refusal does not name '$_w': $*"
  [ ! -s "$STUB_LOG" ] || fail "a stack was called: $*"
  [ -z "$(ls .vid/requests 2>/dev/null)" ] || fail "a ticket was made: $*"
  [ ! -d .vid/ledger.lock ] || fail "the lock was left: $*"
}
gated_repo "$T/r"; gate_on
refused 'a or b' request --type iterate --role builder --try t1 --rows ROW-001 --why 'a spaced word' -- -k 'a or b'
refused "it's" request --type iterate --role builder --try t1 --rows ROW-001 --why 'a quoted word' -- -k "it's"
refused 'x"y' request --type iterate --role builder --try t1 --rows ROW-001 --why 'a double quote' -- 'x"y'
refused 'd e' request --type iterate --role builder --try t1 --rows ROW-001 --why 'a spaced deployed word' -- tests/x --deployed-selection 'd e'
# the direct run, outside the gate (inside it every run is a request)
printf 'run: complete\n' > .vid/RUN-STATE.md
refused 'a or b' -- -k 'a or b'
refused 'tab	word' --role builder -- 'tab	word'
gate_on
# a selection without such a word: request → serve → run, the joined string and its hash unchanged
mkdir -p tests; : > tests/zz1; : > tests/zz2
: > "$STUB_LOG"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'two ids' -- tests/x.py::t1 tests/y.py::t2 'tests/zz[12]' > "$T/out" 2>&1 || fail 'a selection without spaces was refused'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
grep -qxF 'sel=tests/x.py::t1 tests/y.py::t2 tests/zz[12]' ".vid/requests/$TK/request" || fail 'the ticket does not hold the joined selection'
VID_WAIT_MAX=60 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the run did not end green'
grep 'up --build --exit-code-from tests tests' "$STUB_LOG" | cut -d'|' -f4 | grep -qxF 'tests/x.py::t1 tests/y.py::t2 tests/zz[12]' || fail "the selector string changed: $(grep 'up --build' "$STUB_LOG" | cut -d'|' -f4)"
HASH=$(printf '%s' 'tests/x.py::t1 tests/y.py::t2 tests/zz[12]' | cksum | cut -d' ' -f1)
kept | grep -q "\.live\.sel-$HASH\.run-" || fail "the receipt is not named by the selection's hash ($HASH): $(kept)"
exit 0
