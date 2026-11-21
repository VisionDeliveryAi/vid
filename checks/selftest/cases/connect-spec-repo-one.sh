#!/bin/sh
# Purpose: selftest case — the private spec repository stays in both layouts (GM-4 J5): on the GitHub manual toy
# (fixtures/manual.sh) with `layout: one` set, connect.sh start makes the spec repository the settings name and the log does not
# (github.sh spec-setup --make-only, `connect spec-repo` among its steps, a `spec-repo` line in .vid/tw/log, the repository
# private), as it does with two repositories, then is ready; its end frees the lock. Env: CHECKS.
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
C start; [ "$RC" = 0 ] || fail "with layout: one the start exited $RC"
grep -q '^connect spec-repo' "$T/out" || fail 'with layout: one the start did not make the spec repository (no connect spec-repo step)'
grep -q '^spec-repo owner/code-spec ' .vid/tw/log || fail 'with layout: one the log names no spec repository made'
[ "$(gh repo view owner/code-spec --json isPrivate --jq .isPrivate)" = true ] || fail 'with layout: one the spec repository is not private'
grep -q '^connect: ready$' "$T/out" || fail 'with layout: one the start did not say ready'
C end; [ "$RC" = 0 ] || fail "the end exited $RC"
[ -z "$(mn_lock)" ] || fail 'after the end the lock is held'
exit 0
