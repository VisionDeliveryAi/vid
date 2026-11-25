#!/bin/sh
# Purpose: selftest case — a re-plan's placements, read before the proposal (FB-4 A1.4). On the form fixture's toy (fixtures/form.sh) in
# GitHub manual, S02 posted, ROW-021 landed and pending. A candidate that puts ROW-021 in a new step S06 has one placement listed (`placements
# write … --block … --at HEAD`, HEAD's words of it) and no reading: `replan.sh analyse` is refused (exit 1), naming it, nothing
# written. With a result, a finding that stands in it, it is written: the proposal holds that result as `placements`, and the page the section, the counts
# and the finding with its better place: a finding refuses nothing. A candidate that places nothing new is asked for none, its page
# saying so; nor is the apply's own proposal, with a row on the to-place list. The move's hash holds the reading: the same candidate
# read again, its result another, and analysed again, implement-replan's line has another hash. Env: CHECKS.
# selftest-limit: 900 s
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "replan-placements: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
P=.vid/next/proposal; G=$P/REPLAN-PAGE.md
sec() { awk '/^## Where the tests go: what two readers found$/ { on = 1; next } on && /^## / { exit } on' "$G" > "$T/sec"; cat "$T/sec" > "$T/out"; [ -s "$T/sec" ] || fail 'the re-plan page has no section of the two readers'; }
# nothing placed: a reworded row alone, the plan as ratified
sed 's/at the stated size of 10,000 active jobs/at the stated size of 20,000 active jobs/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; g commit -qam 'ROW-012 reworded'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
C=$T/same; mkdir -p "$C"; blk > "$C/block"; printf 'none\n' > "$C/review"
RC=0; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "a candidate that places nothing new exited $RC: it is asked for no reading"
sec; grep -q 'not reviewed' "$T/sec" && [ ! -s "$P/placements" ] || fail 'a candidate that places nothing new does not say it is not reviewed'
# the apply's own proposal, a row on the to-place list: none asked
printf 'ROW-018\tno-step\t2026-11-19T10:00:00Z\tleave it to place\n' > .vid/tw/to-place; rm -rf "$P"
RC=0; sh "$CHECKS/replan.sh" own > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && [ "$(cat "$P/made")" = own ] || fail "the apply's own proposal exited $RC: it places no test, and is asked for no reading"
sec; grep -q 'not reviewed' "$T/sec" || fail 'the own proposal does not say it is not reviewed'
rm -rf "$P" .vid/tw/to-place .vid/pages/REPLAN-PAGE.html
# a test placed
awk '{ print } /^ROW-020 / && !d { print "ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day. | REQ-001 | owed: spec-only — first stage | origin: REQ-001"; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-021 landed'; am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
C=.vid/next/candidate; mkdir -p "$C"; printf 'none\n' > "$C/review"
blk | sed -e '/^step S05 /{p;s/.*/step S06 | name: the day of the last digest | modules: digest | builds-on: S02 | rows: ROW-021 | lane: devagent/;}' -e '/^needs ROW-017 /{p;s/.*/needs ROW-021 | -/;}' > "$C/block"
printf 'S06\tscope-change\tcommit:%s\tROW-021 is built and tested in a step of its own\n' "$(git rev-parse --short HEAD)" > "$C/changes"
RC=0; sh "$CHECKS/replan.sh" analyse > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q '^placements — 1 to read ' "$T/out" || fail "the analysis of a candidate with a placement listed and no result exited $RC, or does not name it"
[ ! -e "$P" ] && [ ! -e .vid/pages/REPLAN-PAGE.html ] || fail 'the refused analysis wrote a proposal or a page'
# read, as the skill reads a candidate's
set -- "$C/placement" --block "$C/block" --at HEAD
sh "$CHECKS/planner.sh" placements write "$@" > "$T/out" 2>&1 && grep -qx 'listed 1' "$T/out" || fail 'the candidate does not list its one placement'
grep -q '^ROW-021$' "$C/placement/part-1.md" && grep -q '^- promise: A saved search shows the day its last digest went out\.' "$C/placement/part-1.md" || { cp "$C/placement/part-1.md" "$T/out"; fail 'the placement is not in HEAD'"'"'s words'; }
printf 'finding 1 | ROW-021 | in S06 | rule 5 | doubt | better: S02 | quote: "the day its last digest went out" (INVENTORY.md, ROW-021) | harm: the digest is shown in two places\nplaced right=0 finding=1 unjudged=0\n' > "$C/placement/part-1.reader"
printf 'stands 1 | better: S02 | S02 makes the digest\n' > "$C/placement/part-1.refuter"
sh "$CHECKS/planner.sh" placements result "$@" > "$T/out" 2>&1 || fail 'the result was refused'
RC=0; sh "$CHECKS/replan.sh" analyse > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the analysis exited $RC with the placements read: a finding refuses nothing"
cmp -s "$C/placement/result" "$P/placements" || fail 'the proposal does not hold the result'
sec; grep -qF -- '- round 1: 1 placements read, 0 right, 0 could not be judged; findings: 1 stand, 0 stand in part, 0 refuted' "$T/sec" || fail 'the page does not give the result'"'"'s counts'
grep -F -- '- **ROW-021** in S06' "$T/sec" | grep -F 'better: S02.' | grep -qF 'S02 makes the digest' || fail 'the page does not show the finding with its better place'
# the move's hash holds the reading
ln_() { sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'; grep "^move${TB}implement-replan${TB}" "$T/out" > "$1" || fail 'implement-replan is not listed'; }
ln_ "$T/l1"; ln_ "$T/l2"; cmp -s "$T/l1" "$T/l2" || fail 'the line changes with nothing changed'
sed "s/${TB}stands${TB}/${TB}partly${TB}/; s/stands=1 partly=0/stands=0 partly=1/" "$C/placement/result" > "$T/x"; cat "$T/x" > "$C/placement/result"
sh "$CHECKS/replan.sh" analyse > "$T/out" 2>&1 || fail 'the analysis again was refused'; ln_ "$T/l2"
[ "$(cut -f4 "$T/l1")" != "$(cut -f4 "$T/l2")" ] || fail 'implement-replan'"'"'s hash does not hold what the two readers found'
exit 0
