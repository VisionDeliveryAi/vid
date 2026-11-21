#!/bin/sh
# Purpose: selftest case — the switch to auto opens the writer's gate (the GM-4 proof's D5). The switch ratifies the plan in the
# owner's words; GitHub auto's writer posts only when the newest publish-approved event's words are the newest ratification's,
# so the switch records the owner's go in the same words, as a landing in GitHub auto does. On the GitHub manual toy
# (fixtures/manual.sh), switched to GitHub manual and back to auto, in the owner's words, then a `publish-approved` event in exactly
# those words, and `writer.sh gate` names no publish-approved gap; so too after a take-stock in GitHub auto in new words. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-auto-writer-gate: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mode_() { sh -c '. "$1/lib.sh"; ghmode' x "$CHECKS"; }
auto_() { MN_RC=0; sh "$CHECKS/mode.sh" auto --register "$T/register" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
gate_() { sh "$CHECKS/writer.sh" gate > "$T/gt" 2>&1 || :; ! grep -q 'publish-approved' "$T/gt" || { cp "$T/gt" "$T/mo"; fail "$1: the writer's gate still names the owner's go"; }; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 0 ] && [ "$(mode_)" = manual ] || fail "the switch to manual exited $MN_RC"
W1='Yes, I ratify this plan for GitHub auto'
auto_ --words "$W1"; [ "$MN_RC" = 0 ] && [ "$(mode_)" = auto ] || fail "the switch to auto exited $MN_RC"
grep '^publish-approved ' .vid/metrics-events | tail -n 1 | grep -q "^publish-approved words=\"$W1\" at=" || fail 'the switch to auto recorded no publish-approved event in the words of its ratification'
gate_ 'after the switch to auto'
W2='Yes, ratify it again in GitHub auto'
auto_ --words "$W2"; [ "$MN_RC" = 0 ] && grep -qx 'mode: GitHub auto, re-taken' "$T/mo" || fail "the take-stock in GitHub auto exited $MN_RC"
grep '^publish-approved ' .vid/metrics-events | tail -n 1 | grep -q "^publish-approved words=\"$W2\" at=" || fail 'the take-stock in GitHub auto recorded no publish-approved event in its words'
gate_ 'after the take-stock in GitHub auto'
echo 'mode-auto-writer-gate: ok'
