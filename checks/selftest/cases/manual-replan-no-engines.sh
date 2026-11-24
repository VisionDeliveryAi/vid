#!/bin/sh
# Purpose: selftest case — a project switched with its tickets can re-plan (FB-3 C5). The toy switched to GitHub manual with two
# tickets taken over: no engines line on record, no export made; then a change of ARCHITECTURE.md. `replan.sh own` makes the apply's own
# proposal and `replan.sh analyse` an analysis, exit 0, the proposal whole. A real writing still refuses with no engines line
# (GM-4 F16), and an analysis that dies half way leaves no folder of its own beside the proposal. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-replan-no-engines: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step ROW-001 ROW-005 > "$T/t2"; gh_writing "$N2" "$T/t2" body 2
printf '%s S01\n%s S02\n' "$N1" "$N2" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; cp "$T/mo" "$T/out"; [ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
! grep -qs '^engines ' .vid/tw/handed && ! grep -q '^export ' .vid/tw/log || fail 'the switched project has engines or an export on record'
printf '\nThe pages are served by one process.\n' >> ARCHITECTURE.md; git commit -qam 'the architecture, one line more'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
left() { [ -z "$(ls -d .vid/next/.proposal.* 2>/dev/null)" ] || fail "$1 left its folder behind"; }
RC=0; sh "$CHECKS/replan.sh" own > "$T/out" 2>&1 || RC=$?; left 'replan.sh own'
[ "$RC" = 0 ] && [ "$(cat .vid/next/proposal/made)" = own ] && [ -s .vid/next/proposal/block ] && [ -f .vid/pages/REPLAN-PAGE.html ] || fail "replan.sh own exited $RC with no engines line and no export"
mkdir -p "$T/c"; sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' > "$T/c/block"; printf 'none\n' > "$T/c/review"
RC=0; sh "$CHECKS/replan.sh" analyse --candidate "$T/c" > "$T/out" 2>&1 || RC=$?; left 'the analysis'
[ "$RC" = 0 ] && [ "$(cat .vid/next/proposal/made)" = analysis ] || fail "replan.sh analyse exited $RC with no engines line and no export"
# a real writing refuses as before
RC=0; sh "$CHECKS/writer.sh" write step S03 > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a ticket was written with no engines line'
# an analysis that dies half way: no folder left
rm -rf .vid/next/proposal; mv ".vid/tw/out/issue-$N2.md" "$T/kept"
RC=0; sh "$CHECKS/replan.sh" own > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && [ ! -d .vid/next/proposal ] || fail 'a proposal was made with a ticket no writing of is on record'; left 'the refused own proposal'
echo 'manual-replan-no-engines: ok'
