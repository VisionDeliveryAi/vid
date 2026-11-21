#!/bin/sh
# Purpose: selftest case — a re-cut through the door in GitHub manual (GM-3 U2). On the switched toy (fixtures/manual.sh, the
# fake gh), stage 0 closed (`stage-closed 0` in .vid/tw/handed), RUN-STATE at `stage: 0`, and a named candidate of stage 2 whose
# ask is an open issue. A re-cut that moves ROW-003 out of stage 0 is refused at the draft, naming the closed stage, no draft made.
# A re-cut that moves ROW-019 to stage 2 (STAGES.md's row line and the owner's answer row in PRD.md, no plan block) is drafted
# and, on the owner's yes, lands: `next.sh pending` prints exactly `pending moved-stage ROW-019` and `spec STAGES.md 1 lines`;
# RUN-STATE's `stage:` and plan block, .vid/tw/applied and the ratification are unchanged. The candidate is withdrawn as today,
# its issue neither commented on nor closed (nothing reached the fake GitHub), and recorded in .vid/next/withdrawn; the landing
# prints `withdrawn #<n>: <why>`, and `next.sh triggers` lists `withdrawn #<n>` while the read shows the issue open, and not
# once it is closed. And: .vid/plan/ratified and .vid/tw/applied byte for byte as before after the draft and after
# the landing; the answer row the re-cut appends to PRD.md shows as pending too, `spec PRD.md 4 lines`, before STAGES.md's.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-door-recut: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); LS=$CHECKS/land.sh
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || { cp "$T/mo" "$T/out"; fail "the switch exited $MN_RC"; }
# stage 0 closed, RUN-STATE at stage 0, and stage 2's named candidate with its ask open on GitHub
printf 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1\n' >> .vid/tw/handed
awk '{ print } /^run:/ { print "stage: 0" }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
NC=$(gh_issue 'Stage 2, candidate 1'); mkdir -p .vid/decide/stage/2/1; printf 'issue\t%s\n' "$NC" > .vid/decide/stage/2/1/ask; : > .vid/decide/stage/2/1/named
gh_wclear; H0=$(git rev-parse HEAD); A0=$(cat .vid/tw/applied); cp .vid/plan/ratified "$T/rat0"; cp .vid/tw/applied "$T/app0"
same() { cmp -s .vid/plan/ratified "$T/rat0" && cmp -s .vid/tw/applied "$T/app0" || fail "$1 changed .vid/plan/ratified or .vid/tw/applied"; }
 sed -n '/^## The plan/,$p' .vid/RUN-STATE.md > "$T/plan0"
printf 'none\n' > "$T/rv"
ld() { RC=0; sh "$LS" "$@" > "$T/out" 2>&1 || RC=$?; }
answer() { { cat PRD.md; printf '\n### 2026-11-20 (the self-test)\n\n```vid-prd-answers\nA-301 | human | 2026-11-20 | Q: how should the product be delivered — in which stages? | A: %s | settles: contract\n```\n' "$1"; } > "$T/pr" && cat "$T/pr" > PRD.md; }
# a re-cut of the closed stage 0 is refused at the draft
grep -v '^row: ROW-003 -> STAGE-0$' STAGES.md > "$T/s" && cat "$T/s" > STAGES.md; answer 'the saved-search page waits for stage 1'
ld draft --review "$T/rv" --why '/vid stage: the saved-search page moves to stage 1, in the owner words'
[ "$RC" != 0 ] || fail 'a re-cut of the closed stage 0 was drafted'
grep -q 'stage 0, which is closed' "$T/out" || fail 'the refusal does not name the closed stage'
[ ! -d .vid/decide/drafts/1 ] || fail 'a refused re-cut was made a draft'
git checkout -q -- STAGES.md PRD.md
# the re-cut: ROW-019 to stage 2, the owner's answer, no plan block
awk '{ print } /^row: ROW-004 -> STAGE-0$/ { print "row: ROW-019 -> STAGE-2" }' STAGES.md > "$T/s" && cat "$T/s" > STAGES.md; answer 'the footer support address waits for stage 2'
ld draft --review "$T/rv" --why '/vid stage: the footer support address moves to stage 2, in the owner words'
[ "$RC" = 0 ] && grep -qx 'draft 1' "$T/out" || fail "the re-cut was not drafted in GitHub manual ($RC)"
[ "$(git rev-parse HEAD)" = "$H0" ] && [ -z "$(git status --porcelain -- STAGES.md PRD.md)" ] || fail 'the draft committed, or left the tree changed'
same 'the draft'
printf 'stage name=replan state=start session=call records=29 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events   # the call's stage, as vid-connect's start opens it (GM-4 F2, I4)
ld 1 --words 'Yes, move the footer to stage 2'
[ "$RC" = 0 ] || fail "the re-cut did not land in GitHub manual ($RC)"
git show HEAD:STAGES.md | grep -qx 'row: ROW-019 -> STAGE-2' || fail 'the re-cut is not in HEAD'
grep -qx "withdrawn #$NC: .*" "$T/out" || fail "the landing does not print the withdrawn ask #$NC"
same 'the landing'
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || fail 'next.sh pending failed after the re-cut'
printf 'pending\tmoved-stage\tROW-019\nspec\tPRD.md\t4 lines\nspec\tSTAGES.md\t1 lines\n' | cmp -s - "$T/out" || fail 'the landed re-cut does not show exactly pending moved-stage ROW-019, spec PRD.md 4 lines and spec STAGES.md 1 lines'
grep -qx 'stage: 0' .vid/RUN-STATE.md || fail "the landing moved RUN-STATE's stage: in GitHub manual"
sed -n '/^## The plan/,$p' .vid/RUN-STATE.md | cmp -s - "$T/plan0" || fail "the landing changed RUN-STATE's plan"
[ "$(cat .vid/tw/applied)" = "$A0" ] || fail 'the landing moved the applied version'
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'the re-cut ended the ratification'
# the candidate withdrawn as today; its issue neither commented on nor closed; recorded for the owner
[ -f .vid/decide/stage/2/1/withdrawn ] || fail 'the candidate of the stage the re-cut changed was not withdrawn'
[ ! -s "$FAKEGH/writes" ] || { cp "$FAKEGH/writes" "$T/out"; fail 'the landing reached the fake GitHub'; }
grep -q "^$NC${TB}" .vid/next/withdrawn || fail 'the withdrawn ask is not recorded in .vid/next/withdrawn'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
grep -q "^withdrawn${TB}#$NC${TB}." "$T/out" || fail "triggers does not list withdrawn #$NC while its issue is open"
gh issue close "$NC" -R owner/code > /dev/null 2>&1 || fail 'the fake could not close the issue'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed after the close'
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed after the close'
! grep -q "^withdrawn${TB}#$NC${TB}" "$T/out" || fail "triggers still lists withdrawn #$NC once its issue is closed"
exit 0
