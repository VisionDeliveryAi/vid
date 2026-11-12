#!/bin/sh
# Purpose: selftest case — the first ticket mode is removed and nothing calls it (0.26.10.28.1, 9.1 R1, R2, R8; stage 9 S2).
# checks/ticket.sh, the skills vid-replan, vid-ticket-approve and vid-ticket-implement and the fixture
# checks/selftest/fixtures/round.sh are gone; no script, hook, skill or case calls ticket.sh or one of github.sh's ten
# removed subcommands (publish, pull, run-full, session, clone, next-ticket, claim, push, review, merge), by name or by
# $0 — a call is `sh …ticket.sh` or `sh …github.sh <removed>`, never a mention; develop's own files (metrics.sh,
# brief.sh, vid-skeleton), untouched by ruling, keep their stale messages. No file but the changelog names the old round
# fixture, and the README names no case count. Plugin layout checks the tree; a project's checks/ alone checks only
# checks/. Env: CHECKS.
set -eu
fail() { echo "old-mode-removed: $*" >&2; exit 1; }
R=$CHECKS/..; [ -d "$R/skills" ] && [ -d "$R/devagent" ] || R=''
[ ! -e "$CHECKS/ticket.sh" ] || fail 'checks/ticket.sh is still there'
[ ! -e "$CHECKS/selftest/fixtures/round.sh" ] || fail 'the old round fixture is still there'
if [ -n "$R" ]; then for s in vid-replan vid-ticket-approve vid-ticket-implement; do [ ! -e "$R/skills/$s" ] || fail "skills/$s is still there"; done; fi
OLD='publish|pull|run-full|session|clone|next-ticket|claim|push|review|merge'
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
if [ -n "$R" ]; then set -- "$R/checks" "$R/hooks" "$R/skills" "$R/devagent" "$R/agents" "$R/templates"; else set -- "$CHECKS"; fi
grep -rnE "(^|[^a-z])sh [^|;&]*ticket\.sh|(github\.sh\"?|\\\$0\"?) +($OLD)([^a-z-]|$)" "$@" 2>/dev/null \
  | grep -vE '/(metrics|brief)\.sh:|/vid-skeleton/|/old-mode-removed\.sh:|/github-allow-list\.sh:|/planner-scope\.sh:|/tw-lane\.sh:' > "$T/calls" || true
[ ! -s "$T/calls" ] || { cat "$T/calls" >&2; fail 'a call to the removed old ticket mode is left'; }
if [ -n "$R" ]; then
  B=$(grep -rln 'fixtures/round\.sh' "$R" --exclude-dir=.git --exclude-dir=releases --exclude=CHANGELOG.md --exclude=old-mode-removed.sh 2>/dev/null || true)
  [ -z "$B" ] || fail "a file names the old round fixture: $B"
  ! grep -qE 'selftest: [0-9]+/[0-9]+' "$R/README.md" || fail 'the README names a case count'
fi
exit 0
