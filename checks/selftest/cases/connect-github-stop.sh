#!/bin/sh
# Purpose: selftest case — vid-connect stops a call when GitHub is not ready (GM-1 S5, its case connect-github-stop). In a project in
# GitHub manual, not signed in on the fake gh: connect.sh start ends the call (exit 1) before the lock, and the lock is free; signed
# in, but with the spec repository gone public, it ends after access, the lock it took freed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "connect-github-stop: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
gh repo create owner/vid-state --private > /dev/null
touch "$FAKEGH/auth-fail"; rc=0; sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || rc=$?
[ "$rc" = 1 ] || fail "not signed in, connect.sh start exited $rc, not 1"
grep -q '^connect refresh: ' "$T/out" || fail 'the refresh did not come first'
grep -q '^connect lock: ' "$T/out" && fail 'not signed in, the call went on to the lock'
rm -f "$FAKEGH/auth-fail"; [ -z "$(mn_lock)" ] || fail 'the lock is held after the call ended'
echo false > "$FAKEGH/repos/owner%code-spec/private"; rc=0; sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || rc=$?
[ "$rc" = 1 ] || fail "with a GitHub line not ready, connect.sh start exited $rc, not 1"
grep -q '^connect access: 1 of 3 not ready' "$T/out" || fail 'the access line not ready is not said'
grep -q '^connect: ready' "$T/out" && fail 'the call went on past a GitHub line not ready'
[ -z "$(mn_lock)" ] || fail 'the lock taken before access is held after the call ended'
echo 'connect-github-stop: ok'
