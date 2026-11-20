#!/bin/sh
# Purpose: selftest case — a step's close asks only merged tickets' rows (0.26.11.1.4, R4), checks/close.sh on the toy and the fake gh. S02
# builds on S01; S01 has a merged ticket and an open step ticket, whose row ROW-004 no other ticket holds; S02's one ticket is merged.
# `close.sh ask S02` asks the merged tickets' rows, S01's and S02's own, and never the open ticket's ROW-004: its code is not at the
# close's commit. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "close-open-builds-on: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
M=$(git --git-dir="$T/code.git" rev-parse main); printf 'close-chunk-minutes: 1\nclose-wait-minutes: 99\n' >> .vid/tw/settings
tk() { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n\n## Rows\n\n> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: none\n\n## Regression rows\n\n- ROW-001\n' "$1" "$2" "$3" "$3" > ".vid/tw/out/issue-$1.md"
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$4" "$3" >> .vid/tw/log; }
# S01: #1 merged (pull request 2); #3, a step ticket, open. S02: #5 merged (pull request 6)
tk 1 skeleton ROW-003 S01; tk 3 step ROW-004 S01; tk 5 step ROW-005 S02
printf '2\n6\n' > .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n6\t5\t%s\t%s\n' "$M" "$M" "$M" "$M" > .vid/decide/merges
printf 'engines alpha beta | stand-in: results reader\n' >> .vid/tw/handed
cs ask S02; [ "$RC" = 0 ] || fail "the ask failed ($RC)"; K=.vid/decide/close/S02/1/rows; [ -f "$K" ] || fail 'no rows for the close'
grep -q '^ROW-005 ' "$K" && grep -q '^ROW-003 ' "$K" || fail "a merged ticket's row is not in the close: $(cut -d' ' -f1 "$K" | tr '\n' ' ')"
! grep -q '^ROW-004 ' "$K" || fail "the open S01 ticket's row is in S02's close: $(cut -d' ' -f1 "$K" | tr '\n' ' ')"
echo 'close-open-builds-on: ok'
