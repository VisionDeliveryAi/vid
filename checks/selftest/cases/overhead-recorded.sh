#!/bin/sh
# Purpose: selftest case — each published pass records its overhead
# (v0.9.7.0.10 spec 3.2, R5). Inside a develop run, a request whose run
# lasts about 3 s with cases of 0.4 s and 0.6 s writes `overhead=<its
# seconds − 1>` on its `ledger-run` event, after the request's fields and
# before `why=`; a run whose case seconds exceed its own seconds writes
# `overhead=0`, never below. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "overhead-recorded: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm 'a reader'
rep() { { printf '<report>\n'; for t in "$@"; do printf '<case name="tests/invariants/t.py::a%s[ROW-001]" status="passed" time="%s"/>\n' "$t" "$t"; done; printf '</report>\n'; } > "$T/rep.xml"; }
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
ev() { grep "^ledger-run .* request=$1 " .vid/metrics-events; }
# about 4 s of run, 1 s of cases
rep 0.4 0.6; : > "$T/hold"; ( sleep 4; rm -f "$T/hold" ) &
STUB_REPORT="$T/rep.xml" STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'overhead' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
TK=$(tk); VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the run did not pass'
L=$(ev "$TK"); S=$(printf '%s\n' "$L" | sed -n 's/^ledger-run seconds=\([0-9]*\) .*/\1/p')
[ "${S:-0}" -ge 2 ] || fail "the run did not last 2 s: $L"
printf '%s\n' "$L" | grep -qE " request=$TK .* overhead=$((S - 1)) why=\"overhead\" at=" || fail "the event does not carry overhead=$((S - 1)) after the request's fields: $L"
# case seconds above the run's seconds: overhead=0
rep 500
STUB_REPORT="$T/rep.xml" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'never below' -- tests/x > "$T/out" 2>&1 || fail 'the second request was refused'
TK=$(tk); VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the second run did not pass'
ev "$TK" | grep -q ' overhead=0 ' || fail "a run shorter than its cases is not overhead=0: $(ev "$TK")"
exit 0
