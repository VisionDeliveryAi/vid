#!/bin/sh
# Purpose: selftest case — the re-plan's check, `checks/replan.sh check <block>` (GM-3 U3; its case manual-replan-check). On the form
# fixture's toy (fixtures/form.sh), S02 posted as ticket N. Each candidate is a folder: its block, the ratified one edited, and its
# changes (`<subject>\t<triggers>\t<evidence>\t<expected effect>`). A clean candidate (S04's ROW-018 into a new step S06) prints no
# line and exits 0; four candidates each print exactly one breach and exit 1: a published row taken out (ROW-013 from S02 to S04:
# rule-2), a row put in another stage (stage 2's ROW-017 into S04: rule-4), a new step in two stages (S06 holding ROW-019 and
# ROW-017: rule-1), a change with no trigger (rule-6). A top-up of 6 rows to S02 prints its size warning, and ROW-002, sharing no
# requirement and no module with S02's rows, its builds warning; both exit 0. Then a re-cut and a retirement committed by hand
# (ROW-012 to stage 2 in STAGES.md, ROW-013's line deleted): S02 without ROW-013 and with ROW-012 left in it is clean; ROW-012 taken
# out into S05, named in the candidate's taken-out file, is clean; taken out and not named, it is a rule-2 breach.
# an owner's yes to the team's drop of ROW-013 from #N excuses its leaving only when recorded after #N's newest
# published or amended line (an older yes, a breach; a newer, clean); a row the to-place list holds as other-stage, moved from its
# step into another step of another stage, is a rule-4 breach although the planner drops its flag; the 6-row top-up's warning says
# over 5, and a 3-row top-up is warned by the fifth alone (exit 0); after the re-cut, the clean ROW-012 candidate analysed, the
# proposal's own block checks clean (its taken-out file read back); ROW-012 taken out into no step, named taken-out and left
# no-step, is a rule-2 breach; ROW-002 given `module: web` and topped up to S02 while the candidate adds web to S02's modules
# still prints its builds warning. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-replan-check: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
# cand <name> <sed argument>…: the candidate folder $T/<name>, its block the ratified one through sed; chg <name> <subject> <trigger>:
# one change line, evidence the commit, the trigger as given (empty for none)
cand() { _c=$1; shift; mkdir -p "$T/$_c"; blk | sed "$@" > "$T/$_c/block"; }
chg() { printf '%s\t%s\tcommit:%s\t%s\n' "$2" "$3" "$(git rev-parse --short HEAD)" "the step takes its rows as the toy plans them" >> "$T/$1/changes"; }
chk() { RC=0; sh "$CHECKS/replan.sh" check "$T/$1/block" > "$T/out" 2>&1 || RC=$?; }
S06='step S06 | name: the failure log | modules: digest | builds-on: S02 | rows: ROW-018 | lane: devagent'
# breach <name> <rule> <id>: exit 1, exactly one breach line, that one
breach() { chk "$1"; [ "$RC" = 1 ] || fail "candidate $1 exited $RC, not 1"
  [ "$(grep -c '^rule-' "$T/out")" = 1 ] && grep -q "^$2 $3 — " "$T/out" || fail "candidate $1 does not print exactly the one breach $2 $3"; }

# clean
cand clean -e 's/^\(step S04 .*\) ROW-018 /\1 /' -e "/^step S05 /{p;s/.*/$S06/;}"; chg clean S04 scope-change; chg clean S06 scope-change
chk clean; [ "$RC" = 0 ] && [ ! -s "$T/out" ] || fail "the clean candidate exited $RC or printed a line"
# a published row taken out
cand takeout -e 's/^\(step S02 .*\) ROW-013 /\1 /' -e 's/^\(step S04 .*rows:\) /\1 ROW-013 /'; chg takeout S02 scope-change; chg takeout S04 scope-change
breach takeout rule-2 ROW-013
# an owner's yes to the team's drop of ROW-013 from #N: older than #N's newest writing, it excuses nothing; newer, it does
mkdir -p .vid/next; printf '%s\tdropped\tROW-013\tabc123\tyes\t2026-01-01T00:00:00Z\tYes, let it go\n' "$N" > .vid/next/team-answers
breach takeout rule-2 ROW-013
printf '%s\tdropped\tROW-013\tabc123\tyes\t2099-01-01T00:00:00Z\tYes, let it go\n' "$N" > .vid/next/team-answers
chk takeout; [ "$RC" = 0 ] && ! grep -q '^rule-' "$T/out" || fail "a yes newer than #$N's writing does not excuse ROW-013's leaving (exit $RC)"
rm .vid/next/team-answers
# a row put in another stage (S05 goes, and S04's fakes: S05 with it)
cand stage -e 's/^\(step S04 .*rows:\) /\1 ROW-017 /' -e '/^step S05 /d' -e 's/ | fakes: S05//'; chg stage S04 scope-change; chg stage S05 scope-change
breach stage rule-4 ROW-017
# a row the to-place list holds as other-stage, moved into another step of another stage: still a rule-4 breach
printf 'ROW-017\tother-stage\t2026-11-03T09:00:00Z\tLeave it where it stands\n' > .vid/tw/to-place
breach stage rule-4 ROW-017
rm .vid/tw/to-place
# a new step in two stages
cand two -e 's/^\(step S03 .*\) ROW-019 /\1 /' -e 's/^step S05 .*$/step S06 | name: the footer and synonyms | modules: web search | builds-on: S02 | rows: ROW-019 ROW-017 | lane: devagent/' -e 's/ | fakes: S05//'
chg two S03 scope-change; chg two S04 scope-change; chg two S05 scope-change; chg two S06 scope-change
breach two rule-1 S06
# a change with no trigger
cand notrig -e 's/^\(step S04 .*\) ROW-018 /\1 /' -e "/^step S05 /{p;s/.*/$S06/;}"; chg notrig S04 scope-change; chg notrig S06 ''
breach notrig rule-6 S06
# a top-up of 6 rows: a size warning, never a refusal
cand six -e 's/^\(step S04 .*rows:\) ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004 /\1 DIF-001 /' -e 's/^\(step S02 .*rows:\) /\1 ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 RULE-004 /'
grep -q '^step S04 .*rows: DIF-001 |' "$T/six/block" || { cp "$T/six/block" "$T/out"; fail 'the six-row candidate was not made'; }
chg six S02 scope-change; chg six S04 scope-change
chk six; [ "$RC" = 0 ] && grep -q "^size #$N — .*over 5" "$T/out" || fail "the top-up of 6 rows exited $RC or printed no size warning for #$N saying over 5"
! grep -q '^rule-' "$T/out" || fail 'the top-up of 6 rows printed a breach'
# a top-up of 3 rows to a ticket of 11: over a fifth, not over 5
cand three -e 's/^\(step S04 .*rows:\) ROW-002 ROW-009 ROW-011 ROW-018 /\1 ROW-009 /' -e 's/^\(step S02 .*rows:\) /\1 ROW-002 ROW-011 ROW-018 /'
chg three S02 scope-change; chg three S04 scope-change
chk three; [ "$RC" = 0 ] && grep -q "^size #$N — .*over a fifth" "$T/out" || fail "the top-up of 3 rows exited $RC or printed no size warning for #$N saying over a fifth"
! grep -q '^rule-' "$T/out" || fail 'the top-up of 3 rows printed a breach'
# a top-up sharing nothing with the ticket: a builds warning
cand one -e 's/^\(step S04 .*rows:\) ROW-002 /\1 /' -e 's/^\(step S02 .*rows:\) /\1 ROW-002 /'; chg one S02 scope-change; chg one S04 scope-change
chk one; [ "$RC" = 0 ] && grep -q '^builds ROW-002 — .*REQ-006' "$T/out" || fail "ROW-002's top-up exited $RC or printed no builds warning with its requirement"
! grep -q -e '^rule-' -e '^size ' "$T/out" || fail "ROW-002's top-up printed a breach or a size warning"

# a re-cut and a retirement committed by hand: ROW-012 to stage 2, ROW-013 retired
awk '{ print } /^row: ROW-004 -> STAGE-0/ { print "row: ROW-012 -> STAGE-2" }' STAGES.md > "$T/st" && cat "$T/st" > STAGES.md
awk '!/^ROW-013 /' INVENTORY.md | sed 's/^\(ROW-002 | .*\) | origin: REQ-006$/\1 | module: web | origin: REQ-006/' > "$T/inv" && cat "$T/inv" > INVENTORY.md
grep -q '^ROW-002 .* | module: web | ' INVENTORY.md || fail 'ROW-002 was not given its module'
g commit -qam 'the re-cut: ROW-012 to stage 2; ROW-013 retired; ROW-002 in the web module'
cand kept -e 's/ ROW-013 / /g'; chg kept S02 scope-change
chk kept; [ "$RC" = 0 ] && ! grep -q '^rule-' "$T/out" || fail "S02 with ROW-013 retired and ROW-012 left in it exited $RC or printed a breach"
cand moved -e 's/ ROW-013 / /g' -e 's/^\(step S02 .*\) ROW-012 /\1 /' -e 's/^\(step S05 .*rows:\) /\1 ROW-012 /'; chg moved S02 scope-change; chg moved S05 scope-change
printf 'ROW-012\n' > "$T/moved/taken-out"
chk moved; [ "$RC" = 0 ] && ! grep -q '^rule-' "$T/out" || fail "ROW-012 taken out into S05, named, exited $RC or printed a breach"
# its proposal's block checks clean: the proposal's taken-out file read back
printf 'none\n' > "$T/moved/review"
RC=0; sh "$CHECKS/replan.sh" analyse --candidate "$T/moved" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the analysis of ROW-012 taken out into S05 exited $RC"
grep -q "^ROW-012${TB}$N${TB}S05\$" .vid/next/proposal/taken-out || { cp .vid/next/proposal/taken-out "$T/out"; fail 'the proposal does not take ROW-012 out of #N into S05'; }
RC=0; sh "$CHECKS/replan.sh" check .vid/next/proposal/block > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] && ! grep -q '^rule-' "$T/out" || fail "the proposal's own block does not check clean (exit $RC)"
rm "$T/moved/taken-out"; breach moved rule-2 ROW-012
# taken out into no step: no destination of its new stage, a rule-2 breach although named and left no-step
cand nowhere -e 's/ ROW-013 / /g' -e 's/ ROW-012 / /g'; chg nowhere S02 scope-change
printf 'ROW-012\n' > "$T/nowhere/taken-out"; printf 'no-step\tROW-012\tlater\n' > "$T/nowhere/left"
breach nowhere rule-2 ROW-012
# a top-up whose module the candidate adds to the step: still sharing nothing with the ticket
cand modw -e 's/ ROW-013 / /g' -e 's/^\(step S04 .*rows:\) ROW-002 /\1 /' -e 's/^\(step S02 .*rows:\) /\1 ROW-002 /' -e 's/^\(step S02 .*modules: ingest digest\) /\1 web /'
grep -q '^step S02 .*modules: ingest digest web |' "$T/modw/block" || { cp "$T/modw/block" "$T/out"; fail 'the module candidate was not made'; }
chg modw S02 scope-change; chg modw S04 scope-change
chk modw; [ "$RC" = 0 ] && grep -q '^builds ROW-002 — ' "$T/out" || fail "ROW-002's top-up, its module added to S02 by the candidate, exited $RC or printed no builds warning"
exit 0
