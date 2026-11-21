#!/bin/sh
# Purpose: selftest case — the call's three re-plan moves, listed and checked afresh (GM-3 U6; its case manual-replan-moves, on
# U7's toy). On the re-plan toy (fixtures/manual.sh's mn_replan_toy: a pending reset, addition and retirement, a landed re-cut, a
# to-place row, #N2 and #N3 open, stage 2's candidate withdrawn), two drafts the door made, 4 and 5, both on HEAD. `next.sh
# triggers` lists `planning-analysis -` once, naming the pending changes (5 rows, 2 spec files), the test to place and the
# triggers, and why implement-replan waits for it (the added ROW-021); no implement-replan; no accept-spec-change move (GM-4 F9: drafts 4 and 5 asked through the queue, `Q<n>` lines); the
# landing's `withdrawn #<n>`; and nothing left to a later phase (no `done from phase 3`, no analyse or apply move). With the listing
# kept: planning-analysis named before another move is a usage error, nothing done; once the to-place list changes,
# `implement-replan -- planning-analysis` shows each again, nothing done. the owner's yes to each, through the answer move (GM-4 K6): 5 lands
# (pending, the applied commit and the plan unchanged, nothing to the team's repositories), and 4, stale now that HEAD moved, is
# refused, its draft's state saying it is stale. planning-analysis named alone, as shown, is checked and records nothing. Once the
# analysis writes its proposal, implement-replan is listed with the proposal's plan; after a change to what the proposal read, it
# is shown again, not done. A move the owner did not name is never done. Implement-replan's line carries the
# proposal's own fingerprint beside its plan, so the proposal made again from the same block with another scope (a kind named)
# changes the line, and the named move is shown again, nothing applied; and the plan page names the moves as next-move.sh takes
# them (`/vid next planning-analysis`, `/vid next implement-replan "…"`), never with a `-` subject. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-replan-moves: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
mn_replan_toy "$T/toy" || { cp "$T/mr" "$T/out"; fail 'the re-plan toy could not be made'; }
# two drafts the door made, both on HEAD, neither answered: GRADING-CHECKLIST.md lines
dr() { printf -- '- **%s.** %s\n' "$1" "$2" >> GRADING-CHECKLIST.md; sh "$CHECKS/land.sh" draft --review "$T/mrv" --why "$3" > "$T/out" 2>&1 || fail "the draft of $1 was refused"; }
dr 'Digest footer' 'Check every digest names its support address.' '/vid fix: the digest footer line, in the owner words'
dr 'Digest subject' 'Check every digest subject names its saved search.' '/vid fix: the digest subject line, in the owner words'
[ -f .vid/decide/drafts/4/base ] && [ -f .vid/decide/drafts/5/base ] || fail 'drafts 4 and 5 were not made'
CLAUDE_CODE_SESSION_ID=replan-moves-case; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
HOME=$T/home; export HOME; mkdir -p "$HOME"
H0=$(git rev-parse HEAD); A0=$(cat .vid/tw/applied); gh_wclear
# none: nothing recorded by a move the owner did not name (the applied commit, no proposal, no amendment, nothing to the team)
none() { [ "$(cat .vid/tw/applied)" = "$A0" ] || fail "$1: the applied commit moved"; [ ! -e .vid/next/proposal ] || fail "$1: a proposal was written"
  ! grep -q '^amended ' .vid/tw/log || fail "$1: a ticket was amended"; ! grep -v -e '^owner/vid-state ' "$FAKEGH/writes" | grep -q . || { cp "$FAKEGH/writes" "$T/out"; fail "$1: something reached the team's repositories"; }; }
lines() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'; }
listed() { sh "$CHECKS/queue.sh" raise "$T/tr" > "$T/out" 2>&1 || fail 'queue.sh raise failed'; }   # GM-4 F4: the call's raise
# GM-4 F9 (I5): the door's drafts asked through the owner's queue, each a Q line
for n in 4 5; do sh "$CHECKS/queue.sh" ask draft "$n" > "$T/out" 2>&1 || fail "draft $n could not be asked through the queue"; eval "Q$n=\$(sed -n 's/^asked \(Q[0-9]*\) draft $n\$/\1/p' \"\$T/out\")"; done
[ -n "$Q4" ] && [ -n "$Q5" ] || fail 'the drafts were asked with no Q line'
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; }
# the listing
lines; cp "$T/tr" "$T/out"
[ "$(grep -c "^move${TB}planning-analysis${TB}-${TB}" "$T/tr")" = 1 ] || fail 'planning-analysis is not listed once'
grep -q "^move${TB}planning-analysis${TB}-${TB}[0-9a-f]*${TB}proposes how the plan takes in the pending changes, 5 rows, 2 spec files; 1 tests to place; the [1-9][0-9]* critical and important triggers not declined; implement-replan needs it first: added ROW-021" "$T/tr" ||
  fail 'planning-analysis does not name the pending changes, the test to place, the triggers and why implement-replan waits'
! grep -q "^move${TB}implement-replan${TB}" "$T/tr" || fail 'implement-replan is listed though a pending addition needs the analysis first'
! grep -q "accept-spec-change" "$T/tr" || fail 'an accept-spec-change move is still listed (GM-4 F9: the drafts are the queue'"'"'s)'
grep -q "^withdrawn${TB}#$MN_NW${TB}" "$T/tr" || fail "the landing's withdrawn #$MN_NW is not shown"
! grep -q 'done from phase 3' "$T/tr" && ! grep -q "^move${TB}\(analyse\|apply\)${TB}" "$T/tr" || fail 'a move is still left to phase 3'
listed
# planning-analysis named before another move: a usage error, nothing done
call planning-analysis -- answer "$Q5" yes 'Yes, land it'
[ "$RC" = 2 ] || fail "planning-analysis named before another move exited $RC, not 2"
[ ! -f .vid/decide/drafts/5/landed ] && [ "$(git rev-parse HEAD)" = "$H0" ] || fail 'the call refused as a usage error landed draft 5'
none 'the usage error'
# the to-place list changed since the listing: implement-replan (not listed) and planning-analysis (changed) shown again, not done
cp .vid/tw/to-place "$T/tp0"; printf 'ROW-021\tno-step\t2026-11-20T09:00:00Z\tleave ROW-021 to place\n' >> .vid/tw/to-place
call implement-replan 'Yes, apply it' -- planning-analysis
[ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^again implement-replan -: no proposal is ready to apply now' "$T/out" || fail 'implement-replan, not listed, is not shown again'
grep -q '^again planning-analysis -: .*changed since the listing; shown again, not done' "$T/out" || fail 'planning-analysis, changed since the listing, is not shown again'
! grep -q '^checked planning-analysis' "$T/out" || fail 'planning-analysis was checked though it changed since the listing'
none 'the moves shown again'
cp "$T/tp0" .vid/tw/to-place
# the owner's yes through the answer move (GM-4 K6, I5): 5 lands; 4, stale once HEAD moved, is refused and not landed
call answer "$Q5" yes 'Yes, land the subject line' -- answer "$Q4" yes 'Yes, land the footer line'
[ "$RC" = 0 ] || fail "the call exited $RC"
grep -q "^done answer $Q5: " "$T/out" || fail "the answer $Q5 yes was not done"
[ -f .vid/decide/drafts/5/landed ] && [ "$(git rev-parse HEAD)" != "$H0" ] || fail 'draft 5 did not land'
grep -q "^refused answer $Q4 at the answer: " "$T/out" && grep -q '^stale' .vid/decide/drafts/4/state || fail 'accept-spec-change 4, stale after the landing, is not refused with its draft line'
[ ! -f .vid/decide/drafts/4/landed ] || fail 'the stale draft 4 landed'
sed -n '/^after the moves:/,$p' "$T/out" > "$T/after"; ! grep -q "^move${TB}accept-spec-change${TB}" "$T/after" || fail 'an accept-spec-change is still listed after the moves'
sh "$CHECKS/next.sh" pending > "$T/pd" 2>&1 && grep -q "^spec${TB}GRADING-CHECKLIST.md${TB}" "$T/pd" || { cp "$T/pd" "$T/out"; fail 'the landed draft does not show as pending'; }
none 'the landing'
# planning-analysis named alone, as the last listing showed it: checked, and nothing recorded
H1=$(git rev-parse HEAD); call planning-analysis
[ "$RC" = 0 ] && grep -q '^checked planning-analysis -: as the listing showed it; the vid-replan skill runs the analysis after the call'"'"'s moves, with no arguments' "$T/out" || fail 'planning-analysis named as shown was not checked'
[ "$(git rev-parse HEAD)" = "$H1" ] || fail 'the checked planning-analysis moved HEAD'
none 'the checked planning-analysis'
# the analysis (the vid-replan skill's): the candidate tops #N2 up with ROW-021, takes ROW-019 out of S03, and moves ROW-002 and
# HOS-003 with the re-cut into S05, of stage 2
C=$T/cand; mkdir -p "$C"; printf 'none\n' > "$C/review"
awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md |
  sed -e 's/^\(step S02 .*rows:\) /\1 ROW-021 /' -e 's/^\(step S03 .*\) ROW-019 /\1 /' -e 's/^\(step S04 .*rows:\) ROW-002 \(.*\) HOS-003 /\1 \2 /' -e 's/^\(step S05 .*rows: ROW-017\)/\1 ROW-002 HOS-003/' \
    -e 's/^needs ROW-001 /needs ROW-021 ROW-001 /' -e 's/^\(needs .*\) ROW-019 /\1 /' -e 's/^needs ROW-002 \(.*\) HOS-003 /needs \1 /' -e 's/^needs ROW-017 /needs ROW-017 ROW-002 HOS-003 /' > "$C/block"
S=$(git rev-parse --short HEAD); for s in S02 S03 S04 S05; do printf '%s\tscope-change\tcommit:%s\tthe landed changes placed\n' "$s" "$S"; done > "$C/changes"
sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis was refused'
BH=$(cat .vid/next/proposal/block-hash)
lines; cp "$T/tr" "$T/out"
grep -q "^move${TB}implement-replan${TB}-${TB}[0-9a-f]*${TB}applies the analysis's proposal $(cat .vid/next/proposal/hash), the plan $BH, as its page shows (its fingerprint [0-9a-f]\\{12\\}); needs your words\$" "$T/tr" || fail 'implement-replan is not listed with the fresh proposal as its page shows it, its plan and its fingerprint'
listed; A1=$(cat .vid/tw/applied)
# the proposal made again from the same block with a kind named (another scope): its line changes, and the named
# move is shown again, nothing applied
sh "$CHECKS/replan.sh" analyse --candidate "$C" reset-not-taken > "$T/out" 2>&1 || fail 'the analysis with a kind named was refused'
[ "$(cat .vid/next/proposal/block-hash)" = "$BH" ] || fail 'the analysis with a kind named changed the plan block'
cp -R .vid/next/proposal "$T/prop0"
call implement-replan 'Yes, apply the re-plan'
[ "$RC" = 0 ] && grep -q '^again implement-replan -: what it would do, or its warnings, changed since the listing; shown again, not done' "$T/out" || fail 'implement-replan, its proposal made again since the listing, is not shown again'
! grep -q '^done implement-replan' "$T/out" || fail 'implement-replan was done though its proposal was stale'
[ "$(cat .vid/tw/applied)" = "$A1" ] && ! grep -q '^amended ' .vid/tw/log && diff -r "$T/prop0" .vid/next/proposal > /dev/null || fail 'the stale implement-replan applied something'
# the plan page's to-dos name the re-plan moves as next-move.sh takes them
PG=$(sed -n 's/^page //p' "$T/out" | tail -n 1); [ -f "$PG" ] || fail 'the call wrote no plan page'
grep -o '<span class="cmd">/vid next [^<]*</span>' "$PG" | grep -v '/vid next done ' > "$T/cmds" || :
grep -qx '<span class="cmd">/vid next planning-analysis</span>' "$T/cmds" && grep -qx '<span class="cmd">/vid next implement-replan &quot;…&quot;</span>' "$T/cmds" ||
  { cp "$T/cmds" "$T/out"; fail 'the page does not name planning-analysis and implement-replan as next-move.sh takes them'; }
! grep -q 'planning-analysis -\|implement-replan -' "$T/cmds" || { cp "$T/cmds" "$T/out"; fail 'the page names a re-plan move with a - subject'; }
exit 0
