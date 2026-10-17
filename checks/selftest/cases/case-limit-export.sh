#!/bin/sh
# Purpose: selftest case — harness rule 4 reaches the runner (v0.9.7.0.11
# spec 3.2, R2). A harness declaring `case-limit: 45` under x-vid-harness:
# checks/test.sh exports VID_CASE_LIMIT=45 into the environment Compose
# interpolates — a gated request's run and a plain run outside a develop
# run alike (the stub records `case-limit=<value>` at `up`). A harness
# without the key sets none, whatever the caller's environment held.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "case-limit-export: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat "$STUB_LOG" >&2 2>/dev/null; exit 1; }
COMPOSEFILE=$(printf '%s' "$COMPOSEFILE" | awk '{ print } $0 == "  completed: [0, 1]" { print "  case-limit: 45" }')
gated_repo "$T/repo"
grep -qx '  case-limit: 45' docker-compose.test.yml || fail 'the fixture carries no case-limit:'
# outside a develop run: a plain scoped run
: > "$STUB_LOG"
sh checks/test.sh -- tests/x > "$T/out" 2>&1 || fail 'the plain run failed'
grep -qx 'case-limit=45' "$STUB_LOG" || fail 'a plain run did not export VID_CASE_LIMIT=45'
# inside: a request
gate_on; : > "$STUB_LOG"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'the limit' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
VID_WAIT_MAX=30 sh checks/test.sh wait "$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")" > "$T/out" 2>&1 || fail 'the request did not pass'
grep -qx 'case-limit=45' "$STUB_LOG" || fail 'a gated request did not export VID_CASE_LIMIT=45'
# no key: none, whatever the caller held
grep -v 'case-limit:' docker-compose.test.yml > c && mv c docker-compose.test.yml; g add -A && g commit -qm 'no limit'
: > "$STUB_LOG"
VID_CASE_LIMIT=99 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'no limit' -- tests/x > "$T/out" 2>&1 || fail 'the second request was refused'
VID_WAIT_MAX=30 sh checks/test.sh wait "$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")" > "$T/out" 2>&1 || fail 'the second request did not pass'
grep -q '^case-limit=' "$STUB_LOG" && fail 'a harness without case-limit: exported one'
exit 0
