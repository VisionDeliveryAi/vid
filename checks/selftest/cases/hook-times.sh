#!/bin/sh
# Purpose: selftest case — the hook times what it runs (v0.9.5 spec 3.7, R7;
# §7 case 10). Stub courts under the real hook. Convicts unless a passing
# attempt writes one .vid/hook-times line, `result=pass`, a number for every
# court and `at=`; a refused attempt writes `result=refused`; an attempt
# with nothing staged (the early exit 0) writes a line whose court fields
# are all `-`; an unwritable .vid/ never turns a passing attempt into a
# refusal; and a TERM sent to the hook while a court runs writes
# `result=killed`, exits non-zero and leaves no court process behind.
# Env: CHECKS.
set -eu
T=$(mktemp -d); P=''; trap 'chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "hook-times: $*" >&2; cat .vid/hook-times >&2 2>/dev/null; cat "$T/out" >&2 2>/dev/null; exit 1; }
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
N='[0-9]+'
stage one
sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the passing attempt was refused'
[ "$(grep -c . .vid/hook-times)" -eq 1 ] || fail 'not one line'
grep -qxE "hook result=pass seconds=$N placement=$N conformance=$N imports=$N seams=$N inventory\\+census=$N design-cite=$N prd=$N harness=$N selftest=- redstamp=- $ATRE" .vid/hook-times || fail 'the passing line is not in its form'
: > .fail/census
sh checks/hooks/pre-commit > "$T/out" 2>&1 && fail 'the refusing attempt passed'
tail -n 1 .vid/hook-times | grep -qE '^hook result=refused ' || fail 'no refused line'
rm -f .fail/census
g commit -qm 'the staged change' --no-verify
sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the empty attempt was refused'
tail -n 1 .vid/hook-times | grep -qxE "hook result=pass seconds=$N placement=- conformance=- imports=- seams=- inventory\\+census=- design-cite=- prd=- harness=- selftest=- redstamp=- $ATRE" || fail 'the early exit wrote no line with every field -'
stage two
rm -rf .vid; mkdir .vid; chmod 555 .vid
sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'an unwritable .vid/ turned a passing attempt into a refusal'
chmod 755 .vid
# TERM while a court runs: a line, a non-zero exit, no court left behind
printf '#!/bin/sh\n# Purpose: slow stub\necho $$ > .ran/harness.pid\nsleep 30 &\necho $! > .ran/sleep.pid\nwait\n' > checks/harness.sh
g add checks/harness.sh; g commit -qm 'a slow harness' --no-verify
stage three
sh checks/hooks/pre-commit > "$T/out" 2>&1 & HP=$!
i=0; while [ ! -s .ran/sleep.pid ] && [ "$i" -lt 100 ]; do sleep 1; i=$((i + 10)); done
[ -s .ran/sleep.pid ] || fail 'the slow court never started'
kill -TERM "$HP"; RC=0; wait "$HP" || RC=$?
[ "$RC" -ne 0 ] || fail 'the killed hook exited 0'
tail -n 1 .vid/hook-times | grep -qE '^hook result=killed ' || fail 'no killed line'
sleep 1
for p in "$(cat .ran/harness.pid)" "$(cat .ran/sleep.pid)"; do kill -0 "$p" 2>/dev/null && { kill "$p" 2>/dev/null; fail "a court process ($p) was left behind"; }; done
exit 0
