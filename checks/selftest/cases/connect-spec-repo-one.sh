#!/bin/sh
# Purpose: selftest case — with one repository GitHub manual has no spec repository (FB-3 B2, which replaces GM-4 J5's rule there): on
# the GitHub manual toy (fixtures/manual.sh) with `layout: one` set and `spec-repo:` still standing, connect.sh start makes no spec
# repository and logs none, reads none, and is ready; its end frees the lock. With `layout: separate` the start makes the one the
# settings name and the log does not (github.sh spec-setup --make-only, `connect spec-repo` among its steps, a `spec-repo` line in
# .vid/tw/log, the repository private), then is ready. The old spec
# repository named as the state repository: the connect takes it with one repository (a `state-repo` line), refuses it with two. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "connect-spec-repo-one: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
C() { RC=0; sh "$CHECKS/connect.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
gh repo create owner/vid-state --private > /dev/null
grep -v '^layout:' .vid/tw/settings > "$T/s" || :; { cat "$T/s"; printf 'layout: one\n'; } > .vid/tw/settings
grep -q '^spec-repo: owner/code-spec$' .vid/tw/settings && ! grep -q '^spec-repo ' .vid/tw/log 2>/dev/null || fail 'the toy does not name a spec repository its log has no line for'
: > "$FAKEGH/log"; C start; [ "$RC" = 0 ] || fail "with layout: one the start exited $RC"
! grep -q '^connect spec-repo' "$T/out" && ! grep -q '^spec-repo ' .vid/tw/log || fail 'with layout: one the start made or logged a spec repository'
! grep -q 'code-spec' "$FAKEGH/log" || fail 'with layout: one the start read the spec repository'
grep -q '^connect: ready$' "$T/out" || fail 'with layout: one the start did not say ready'
C end; [ "$RC" = 0 ] || fail "the end exited $RC"
[ -z "$(mn_lock)" ] || fail 'after the end the lock is held'
sed 's/^layout: one$/layout: separate/' .vid/tw/settings > "$T/s"; cat "$T/s" > .vid/tw/settings
C start; [ "$RC" = 0 ] || fail "with layout: separate the start exited $RC"
grep -q '^connect spec-repo' "$T/out" || fail 'with layout: separate the start did not make the spec repository (no connect spec-repo step)'
grep -q '^spec-repo owner/code-spec ' .vid/tw/log || fail 'with layout: separate the log names no spec repository made'
[ "$(gh repo view owner/code-spec --json isPrivate --jq .isPrivate)" = true ] || fail 'with layout: separate the spec repository is not private'
grep -q '^connect: ready$' "$T/out" || fail 'with layout: separate the start did not say ready'
C end; [ "$RC" = 0 ] || fail "the second end exited $RC"
# the old spec repository as the state repository: made so by the connect with one repository, refused with two
as_state() { sed "s/^layout: .*/layout: $1/; s#^state-repo: .*#state-repo: owner/code-spec#" .vid/tw/settings > "$T/s"; cat "$T/s" > .vid/tw/settings; grep -v '^state-repo ' .vid/tw/log > "$T/lg" || :; cat "$T/lg" > .vid/tw/log; rm -f .vid/state-at; }
as_state one; C start; [ "$RC" = 0 ] && grep -q '^connect: ready$' "$T/out" && grep -q '^state-repo owner/code-spec ' .vid/tw/log || fail "with layout: one the old spec repository was not taken as the state repository at the connect ($RC)"
C end; [ "$RC" = 0 ] || fail "the third end exited $RC"
as_state separate; C start; [ "$RC" = 1 ] && grep -q 'state-repo' "$T/out" || fail "with layout: separate the spec repository was taken as the state repository at the connect ($RC)"
exit 0
