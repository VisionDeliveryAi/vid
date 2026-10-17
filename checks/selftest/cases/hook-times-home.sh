#!/bin/sh
# Purpose: selftest case — hook times at the run's home (v0.9.7.0.11 spec
# 3.14, R14). Stub courts under the real hook, with checks/plan.sh. With a
# live develop run at the home, a commit attempt in a builder's linked
# worktree writes its hook-times line to the home's .vid/hook-times with
# `checkout=<the worktree's basename>`, and none in the worktree's own
# .vid/; an attempt at the home writes the home's line as before, with no
# checkout=. With the run stopped (no live run), the worktree's attempt
# writes its own .vid/hook-times, as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/home"; cd "$T/home"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "hook-times-home: $*" >&2; cat "$T/home/.vid/hook-times" "$T/wt-b/.vid/hook-times" >&2 2>/dev/null; exit 1; }
cp "$CHECKS/plan.sh" checks/; g add checks/plan.sh; g commit -qm 'plan.sh'
mkdir -p .vid
printf 'run: active\nsession: S1\nplan: required\nquestions: - · next Q1\nslice: 1 open    since: x    commit: x\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=14 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > .vid/metrics-events
g worktree add -q "$T/wt-b" -b builder
cd "$T/wt-b"; mkdir -p .ran .fail
stage one
sh checks/hooks/pre-commit > /dev/null 2>&1 || fail 'the worktree attempt was refused'
tail -n 1 "$T/home/.vid/hook-times" | grep -qE '^hook result=pass .* checkout=wt-b at=' || fail "the worktree's line is not at the home with checkout=wt-b"
[ ! -f .vid/hook-times ] || fail "the worktree kept a line of its own"
cd "$T/home"; stage two
sh checks/hooks/pre-commit > /dev/null 2>&1 || fail 'the home attempt was refused'
tail -n 1 .vid/hook-times | grep -q 'checkout=' && fail "the home's own line carries checkout="
[ "$(grep -c . .vid/hook-times)" -eq 2 ] || fail 'the home does not hold both lines'
sed -i.bak 's/^run: active/run: stopped/' .vid/RUN-STATE.md
cd "$T/wt-b"; stage three
sh checks/hooks/pre-commit > /dev/null 2>&1 || fail 'the worktree attempt with no live run was refused'
[ "$(grep -c . .vid/hook-times 2>/dev/null)" = 1 ] || fail 'with no live run the worktree did not write its own line'
[ "$(grep -c . "$T/home/.vid/hook-times")" -eq 2 ] || fail 'with no live run a line went to the home'
exit 0
