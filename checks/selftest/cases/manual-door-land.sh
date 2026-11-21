#!/bin/sh
# Purpose: selftest case — the door drafts, counts and lands again in GitHub manual, as a pending change (GM-3 U2). On the
# switched toy (fixtures/manual.sh: S01's ticket published and taken over, the fake gh), a /vid fix draft in the working tree:
# ROW-007's obligation restated and REQ-005's fail-if changed (reaching ROW-004, which S01's ticket holds). `land.sh draft`
# prints `draft 1` and its count, commits nothing and puts the tree back; a draft holding a PLAN.md change, and one with
# --plan, are refused, naming the analysis (/vid next planning-analysis), and keep the tree. The owner's yes, `land.sh 1
# --words`, lands it: its commits are in, `next.sh pending` shows reset ROW-007, .vid/tw/applied, RUN-STATE's plan block, the
# recorded plans and PLAN.md are as before, `planner.sh ratified` exits 0, no publish-approved event is written, the landing
# opened and ended no stage of its own (GM-4 F2, I4: with no stage open it is refused, the gate off; inside the call's stage, as
# vid-connect's start opens it, it lands, the call's stage still open after), and nothing reached the fake GitHub. The landing's
# reached line for ROW-004 (S01's ticket since closed, a sync naming no open ticket) waits for the apply: `writer.sh pending`
# lists ROW-004 only once .vid/tw/applied holds the landing. Before the yes, `land.sh 1` with no --words and
# with empty words is refused, HEAD unchanged, no landed marker, nothing on the fake GitHub; .vid/plan/ratified and
# .vid/tw/applied are byte for byte as before after the draft and after the landing; and a draft planted by hand with a plan
# block, a PLAN.md file or PLAN.md deleted (as a draft made in GitHub auto before the switch) is refused at the landing, naming
# the analysis, HEAD and .vid/plan/ratified unchanged. With the count's `inventory.sh impact --tickets --detail`
# made to fail with no output (a copy of checks/ whose inventory.sh exits 7 on it alone), the draft is refused, no draft is
# saved, HEAD is unchanged, the working tree's edit is kept, and nothing reaches the fake GitHub.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-door-land: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); LS=$CHECKS/land.sh
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || { cp "$T/mo" "$T/out"; fail "the switch exited $MN_RC"; }
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'not ratified after the switch'
printf 'sync main=none open=- at=2026-11-20T09:00:00Z\n' >> .vid/tw/log   # S01's ticket since closed: the round's sync names no open ticket
gh_wclear; H0=$(git rev-parse HEAD); A0=$(cat .vid/tw/applied); cp .vid/plan/ratified "$T/rat0"; cp .vid/tw/applied "$T/app0"
same() { cmp -s .vid/plan/ratified "$T/rat0" && cmp -s .vid/tw/applied "$T/app0" || fail "$1 changed .vid/plan/ratified or .vid/tw/applied"; }
sed -n '/^## The plan/,$p' .vid/RUN-STATE.md > "$T/plan0"; ls .vid/plans > "$T/plans0"; cp PLAN.md "$T/pm0"; grep -c '^plan-change ' .vid/metrics-events > "$T/pc0" || true
printf 'none\n' > "$T/rv"
ld() { RC=0; sh "$LS" "$@" > "$T/out" 2>&1 || RC=$?; }
# the change, in the working tree: ROW-007 restated, REQ-005's fail-if changed
change() { sed 's/^\(ROW-007 .*\)opens the unsubscribe page with no sign-in/\1opens the unsubscribe page at once, with no sign-in/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
  sed 's/fail-if: a feed outage or re-poll loses a saved search or resets its last-sent timestamp/fail-if: a feed outage or re-poll loses a saved search, or resets or moves its last-sent timestamp/' PRD.md > "$T/pr" && cat "$T/pr" > PRD.md
  grep -q 'page at once, with no sign-in' INVENTORY.md && grep -q 'resets or moves its last-sent' PRD.md || fail 'the change did not land in the working tree'; }
# the count's --detail read failing with no output refuses the draft (U1), nothing saved, the tree kept
cp -R "$CHECKS" "$T/ck"
printf '#!/bin/sh\nif [ "${1:-}" = impact ]; then case " $* " in *" --detail "*) case " $* " in *" --tickets "*) exit 7 ;; esac ;; esac; fi\nexec sh "%s/inventory.sh" "$@"\n' "$CHECKS" > "$T/ck/inventory.sh"
change; RC=0; sh "$T/ck/land.sh" draft --review "$T/rv" --why '/vid fix: the unsubscribe page opens at once, in the owner words' > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] || fail 'a draft whose count could not be read (impact --tickets --detail exited 7) was made'
[ ! -d .vid/decide/drafts/1 ] || fail 'a draft whose count failed was saved'
[ "$(git rev-parse HEAD)" = "$H0" ] || fail 'a draft whose count failed moved HEAD'
grep -q 'page at once, with no sign-in' INVENTORY.md && grep -q 'resets or moves its last-sent' PRD.md || fail "a draft whose count failed did not keep the working tree's edit"
[ ! -s "$FAKEGH/writes" ] || fail 'a draft whose count failed reached the fake GitHub'
git checkout -q -- INVENTORY.md PRD.md
# a draft holding a PLAN.md change is refused, naming the analysis, and the tree is kept
change; printf 'standing extra | ROW-007\n' >> PLAN.md
ld draft --review "$T/rv" --why '/vid fix: the unsubscribe page opens at once, in the owner words'
[ "$RC" != 0 ] || fail 'a draft holding a PLAN.md change was made in GitHub manual'
grep -qF '/vid next planning-analysis' "$T/out" || fail 'the PLAN.md refusal does not name the analysis'
[ ! -d .vid/decide/drafts/1 ] || fail 'a refused draft was made'
[ -n "$(git status --porcelain -- PLAN.md INVENTORY.md)" ] || fail 'the refused draft did not keep the tree'
cp "$T/pm0" PLAN.md
# --plan is refused too, naming the analysis
sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md > "$T/blk"
ld draft --review "$T/rv" --why '/vid fix: the unsubscribe page opens at once, in the owner words' --plan "$T/blk"
[ "$RC" != 0 ] && grep -qF '/vid next planning-analysis' "$T/out" || fail "a draft with --plan was not refused naming the analysis ($RC)"
[ ! -d .vid/decide/drafts/1 ] || fail 'a draft with --plan was made'
# the draft: its count, nothing committed, the tree put back
ld draft --review "$T/rv" --why '/vid fix: the unsubscribe page opens at once, in the owner words'
[ "$RC" = 0 ] || fail "the draft was refused in GitHub manual ($RC)"
grep -qx 'draft 1' "$T/out" || fail 'no draft 1'
grep -q '^impact reset=1 added=0 reached=' "$T/out" && grep -qx 'reset ROW-007' "$T/out" || fail 'the draft does not count ROW-007 reset'
grep -q '^reached .*ROW-004' "$T/out" || fail 'the draft does not count ROW-004 reached'
[ "$(git rev-parse HEAD)" = "$H0" ] && [ -z "$(git status --porcelain -- PRD.md INVENTORY.md)" ] || fail 'the draft committed, or left the tree changed'
sh "$CHECKS/plan.sh" gate > "$T/out" 2>&1 && fail 'the gate is on after the draft: it opened a stage of its own'
same 'the draft'
# no yes, no landing: no --words, and empty words, are refused, nothing landed, nothing posted
for w in none empty; do if [ "$w" = none ]; then ld 1; else ld 1 --words ''; fi
  [ "$RC" != 0 ] || fail "a landing with $w words was not refused"
  [ "$(git rev-parse HEAD)" = "$H0" ] && [ ! -f .vid/decide/drafts/1/landed ] || fail "a landing with $w words landed something"
  [ ! -s "$FAKEGH/writes" ] || fail "a landing with $w words reached the fake GitHub"; done
same 'a landing with no yes'
# the owner's yes with no stage open: refused, the gate off (GM-4 F2: the call's stage is vid-connect's)
ld 1 --words 'Yes, land the unsubscribe change'
[ "$RC" = 3 ] && grep -q "gate is off" "$T/out" || fail "with no stage open the landing was not refused for the gate ($RC)"
[ "$(git rev-parse HEAD)" = "$H0" ] || fail 'a landing with no stage open landed something'
# the owner's yes lands it, inside the call's stage
printf 'stage name=replan state=start session=call records=29 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
K=$(grep -c '^stage name=replan ' .vid/metrics-events)
ld 1 --words 'Yes, land the unsubscribe change'
[ "$RC" = 0 ] || fail "the landing was refused in GitHub manual ($RC)"
grep -q '^landed 1 at ' "$T/out" || fail 'the landing printed no landed line'
[ "$(git rev-parse HEAD)" != "$H0" ] && git log --format=%s "$H0..HEAD" | grep -q '^Land draft 1, ' || fail 'the commits are not in'
git show HEAD:INVENTORY.md | grep -q 'page at once, with no sign-in' || fail 'the restated row is not in HEAD'
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || fail 'next.sh pending failed after the landing'
grep -qx "pending${TB}reset${TB}ROW-007" "$T/out" || fail 'the landed change does not show as pending'
[ "$(cat .vid/tw/applied)" = "$A0" ] || fail 'the landing moved the applied version'
sed -n '/^## The plan/,$p' .vid/RUN-STATE.md | cmp -s - "$T/plan0" || fail "the landing changed RUN-STATE's plan"
ls .vid/plans | cmp -s - "$T/plans0" || fail 'the landing recorded a plan'
[ "$(grep -c '^plan-change ' .vid/metrics-events || true)" = "$(cat "$T/pc0")" ] || fail 'the landing recorded a plan change'
cmp -s PLAN.md "$T/pm0" || fail 'the landing changed PLAN.md'
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'the landing ended the ratification'
same 'the landing'
! grep -q '^publish-approved ' .vid/metrics-events || fail 'the landing wrote a publish-approved event in GitHub manual'
[ "$(grep -c '^stage name=replan ' .vid/metrics-events)" = "$K" ] || fail 'the landing opened or ended a stage of its own'
sh "$CHECKS/plan.sh" gate > "$T/out" 2>&1 || fail 'the gate is off after the landing: the call'"'"'s stage was ended'
printf 'stage name=replan state=end session=call at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
[ ! -s "$FAKEGH/writes" ] || { cp "$FAKEGH/writes" "$T/out"; fail 'the landing reached the fake GitHub'; }
# the reached line waits for the apply
grep -q '^reached ROW-004 REQ-005 ' .vid/tw/handed || fail 'the landing recorded no reached line for ROW-004'
sh "$CHECKS/writer.sh" pending > "$T/out" 2>&1 || fail 'writer.sh pending failed'
! grep -q '^ROW-004 ' "$T/out" || fail 'the reached line reaches the writer before the apply'
git rev-parse HEAD > .vid/tw/applied
sh "$CHECKS/writer.sh" pending > "$T/out" 2>&1 || fail 'writer.sh pending failed once applied'
grep -q '^ROW-004 ' "$T/out" || fail 'the reached line does not reach the writer once the applied commit holds the landing'
cp "$T/app0" .vid/tw/applied
# a saved draft that places rows or changes PLAN.md (made in GitHub auto before the switch) is refused at the landing
H1=$(git rev-parse HEAD); cp .vid/plan/ratified "$T/rat1"
plant() { X=.vid/decide/drafts/$1; mkdir -p "$X/files"; git rev-parse HEAD > "$X/base"; printf '/vid fix: a change drafted before the switch\n' > "$X/why"
  cp "$T/rv" "$X/review"; printf 'impact reset=0 added=0 reached=0 records=0\n' > "$X/count"; : > "$X/sets"
  cp GRADING-CHECKLIST.md "$X/files/GRADING-CHECKLIST.md"; printf -- '- **Footer.** Check every digest names its support address.\n' >> "$X/files/GRADING-CHECKLIST.md"; }
plant 2; cp "$T/blk" .vid/decide/drafts/2/plan
plant 3; { cp PLAN.md .vid/decide/drafts/3/files/PLAN.md; printf 'standing extra | ROW-007\n' >> .vid/decide/drafts/3/files/PLAN.md; }
plant 4; printf 'PLAN.md\n' > .vid/decide/drafts/4/deleted
for k in 2 3 4; do ld "$k" --words 'Yes, land it'
  [ "$RC" = 1 ] && grep -qF '/vid next planning-analysis' "$T/out" || fail "planted draft $k (plan block, PLAN.md, or PLAN.md deleted) was not refused at the landing naming the analysis ($RC)"
  [ "$(git rev-parse HEAD)" = "$H1" ] && cmp -s .vid/plan/ratified "$T/rat1" && [ ! -f ".vid/decide/drafts/$k/landed" ] || fail "planted draft $k changed HEAD or the ratification"; done
exit 0
