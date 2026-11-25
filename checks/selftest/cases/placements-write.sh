#!/bin/sh
# Purpose: selftest case — the placements two readers judge, listed (FB-4 A1.1). On the planner's toy (fixtures/planner-toy.sh), with no
# ratification `planner.sh placements write <dir>` lists every planned test, one part, its steps in the block's order, each placement in
# the inventory's own words (stage, marks, requirements, needs, promise, fail-if, transitions), and empties <dir> first. Ratified, it
# lists against the newest recorded plan: nothing with no change; a test moved, a test of a new step, the tests of a step whose
# builds-on: reaches another set of steps (and of the steps that reach it), a planned test in no step and each row of .vid/tw/to-place, and no other; each
# step new or changed is said, and each step's open published ticket, a withdrawn one not. `--since <hash>` lists against that plan;
# `--block <file>` reads that block. `--again` lists what differs from the block the first round judged, and the tests of a finding that stands (of one that
# names a step alone, the step's), and nothing else; `--all` every one. Parts hold whole steps, at most 150 placements, a larger step
# one of its own, and each part says what the steps are the first to set up, a store of no step too (A5's list, stood in for here). In
# the second round a transition stands for its journey, and a range for each of its tests. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "placements-write: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
TB=$(printf '\t'); D=.vid/plan/placement
w() { sh "$CHECKS/planner.sh" placements write "$@" > "$T/out" 2>&1 || fail "placements write $* was refused"; LN=$(sed -n 's/^listed //p' "$T/out"); }
# ids: the tests listed, sorted, on one line
ids() { grep -v '^round ' "$D/listed" | cut -f1 | sort | tr '\n' ' ' | sed 's/ $//'; }
is() { [ "$(ids)" = "$1" ] || { cp "$D/listed" "$T/out"; fail "$2: listed $(ids), not $1"; }; }
pt_toy "$T/toy"
N=$(sh "$CHECKS/planner.sh" rows | awk -F'\t' '$2 == "row" && $6 ~ /^(planned|moved|owed)$/' | grep -c .)
# the first plan: every placement
mkdir -p "$D"; echo old > "$D/part-9.md"; echo old > "$D/result"
w "$D"; [ "$LN" = "$N" ] || fail "the first plan lists $LN placements, not its $N planned tests"
[ -f "$D/part-1.md" ] && [ ! -e "$D/part-2.md" ] && [ ! -e "$D/part-9.md" ] && [ ! -e "$D/result" ] || fail 'the first round did not empty the folder, or is not one part'
P=$D/part-1.md; cp "$P" "$T/out"
[ "$(grep -o '^- S0[1-5] — ' "$P" | tr -d '\n—')" = '- S01  - S02  - S03  - S04  - S05  ' ] || fail 'the part does not hold every step, in order'
grep -q '^  tests: ROW-003, ROW-004$' "$P" || fail 'a step does not name all its tests'
grep -q '^  stage 1; modules: digest, ingest; builds-on: S02, S03; fakes: none; open published ticket: none$' "$P" || fail 'a step does not name its stage, modules, links and ticket'
awk '/^ROW-004$/ { on = 1 } on && /^$/ { exit } on' "$P" > "$T/one"
grep -q '^- stage: 0; marks: journey; requirements: REQ-001, REQ-002, REQ-005; needs: its own step alone$' "$T/one" || fail 'a placement does not give its stage, marks, requirements and needs'
grep -q '^- promise: The new subscriber: hears of the board' "$T/one" && grep -q '^- fails if: ' "$T/one" && [ "$(grep -c '^  - ROW-004-T' "$T/one")" = 3 ] || fail 'a placement does not give its promise, fail-if and transitions'
! grep -qE '^(ROW-020|DIF-003)$' "$P" || fail 'a later-phase test or a record is listed'
# ratified: what differs from the newest recorded plan
H=$(sed -n 's/^plan-change .* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1); cp ".vid/plans/$H.plan" "$T/plan0"
printf 'ratified hash=0 plan=%s at=2026-11-01T09:00:00Z words=yes\n' "$H" > .vid/plan/ratified
w "$D"; [ "$LN" = 0 ] || fail "with no change, $LN placements are listed"
pt_set 'step S05' 'step S05 | name: synonym-aware search | modules: search | builds-on: S02 | rows: ROW-017 ROW-018 | lane: devagent'
pt_set 'step S04' 'step S04 | name: limits, backups and the data move | modules: digest ingest | builds-on: S02 S03 | rows: ROW-002 ROW-009 ROW-011 DIF-001 RULE-004 | lane: devagent'
w "$D"; is 'HOS-003 ROW-018' 'a test moved and a test in no step'
grep -q '^- S05 — .*' "$D/part-1.md" && grep -q 'open published ticket: none; changed$' "$D/part-1.md" || { cp "$D/part-1.md" "$T/out"; fail 'a changed step is not said'; }
grep -q '^- from: S04$' "$D/part-1.md" && grep -q '^### In no step$' "$D/part-1.md" || { cp "$D/part-1.md" "$T/out"; fail 'where a test was, or that it is in no step, is not said'; }
# the order alone: S03 builds on S02, so S03's tests and those of S04 (which reached both before) — S04 reaches the same set
cp "$T/plan0" "$T/b"; sed 's/^\(step S03 .*builds-on: \)S01/\1S01 S02/' "$T/plan0" > "$T/b"
w "$D" --block "$T/b"; is "$(awk '/^step S03 /' "$T/plan0" | sed 's/.*rows: //; s/ |.*//; s/RULE-001\.\.RULE-003/RULE-001 RULE-002 RULE-003/' | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')" 'a builds-on that reaches another step'
sed 's/^\(step S02 .*builds-on: \)S01/\1-/' "$T/plan0" > "$T/b"; w "$D" --block "$T/b"
grep -q "^ROW-001${TB}S02${TB}" "$D/listed" && grep -q "^ROW-017${TB}S05${TB}" "$D/listed" && ! grep -q "^ROW-002${TB}" "$D/listed" || { cp "$D/listed" "$T/out"; fail 'a link taken out does not list the tests of every step that reached through it, or lists others'; }
# a new step, its ticket, and the to-place list
sed -e '/^step S05 /{p;s/.*/step S06 | name: the log of failed sends | modules: digest | builds-on: S02 | rows: ROW-018 | lane: devagent/;}' -e 's/^\(step S04 .*\) ROW-018 /\1 /' "$T/plan0" > "$T/b"
mkdir -p .vid/tw .vid/round; printf 'published 7 kind=step step=S02 rows=ROW-001 at=2026-11-01T09:00:00Z\npublished 8 kind=step step=S03 rows=ROW-006 at=2026-11-01T09:00:00Z\nwithdrawn 8 at=2026-11-02T09:00:00Z\npublished 9 kind=step step=S04 rows=ROW-002 at=2026-11-01T09:00:00Z\n' > .vid/tw/log; printf 'ticket\t9\tCLOSED\n' > .vid/round/read
printf 'ROW-002\tother-stage\t2026-11-01T09:00:00Z\tLeave it there\n' > .vid/tw/to-place
w "$D" --block "$T/b"; is 'ROW-002 ROW-018' 'a new step and the to-place list'; cp "$D/part-1.md" "$T/out"
awk '/^- S06 / { getline; print }' "$D/part-1.md" | grep -q '; new$' || fail 'a new step is not said'
awk '/^- S02 / { getline; print }' "$D/part-1.md" | grep -q 'open published ticket: #7$' || fail 'a step does not name its open published ticket'
for s in S03 S04; do awk -v s="- $s " 'index($0, s) == 1 { getline; print }' "$D/part-1.md" | grep -q 'open published ticket: none' || fail "$s names a withdrawn or closed ticket"; done
grep -q 'on the to-place list (other-stage)$' "$D/part-1.md" || fail 'a placement on the to-place list does not say so'
rm -f .vid/tw/to-place .vid/tw/log
# --since an older plan, and --all
sh "$CHECKS/plan.sh" change rows 'ROW-018 moves' --trigger initial --expect 'its step holds it' > "$T/out" 2>&1 || fail 'the change could not be recorded'
w "$D"; is HOS-003 'the newest recorded plan is the base, and a planned test in no step is listed still'
w "$D" --since "$H"; is 'HOS-003 ROW-018' 'listed since the plan given'
w "$D" --all; [ "$LN" = "$N" ] || fail "--all lists $LN of $N"
# the second round: what differs from the block judged, and the findings' tests (a step alone: the step's)
cp "$T/b" "$T/b1"; w "$D" --block "$T/b1" --all
cp "$D/judged" "$D/reviewed"; { printf 'placed round=1 listed=%s right=0 stands=1 partly=1 refuted=0 unjudged=0 at=2026-11-01T09:00:00Z\n' "$N"
  printf 'finding\tstands\t1\tROW-005, ROW-008\tS02\t2\twrong\tS03\t"q" (PRD.md, REQ-001)\tharm\twhy\nfinding\tpartly\t1\tS05\tS05\t7\tdoubt\tS05 alone\t"q" (PLAN, S05)\tharm\twhy\n'; } > "$D/result"
sed -e 's/^\(step S03 .*\) ROW-019 /\1 /' -e 's/^\(step S06 .*rows:\) /\1 ROW-019 /' "$T/b1" > "$T/b2"
w "$D" --again --block "$T/b2"; is 'ROW-005 ROW-008 ROW-017 ROW-019' 'the second round'
grep -q '^placed round=1 ' "$D/result" && [ -f "$D/part-1.md" ] || fail 'the second round lost the first'"'"'s result, or wrote no part'
# a standing finding on a transition, on a range and on a known test: each read again
{ printf 'placed round=1 listed=%s right=0 stands=3 partly=0 refuted=0 unjudged=0 at=2026-11-01T09:00:00Z\n' "$N"
  for i in ROW-004-T2 'RULE-001..RULE-003' 'ROW-012 and ROW-013'; do printf 'finding\tstands\t1\t%s\tS02\t2\twrong\tS03\t"q" (PRD.md, REQ-001)\tharm\twhy\n' "$i"; done; } > "$D/result"
cp "$T/b2" "$D/reviewed"; w "$D" --again --block "$T/b2"; is 'ROW-004 ROW-012 ROW-013 RULE-001 RULE-002 RULE-003' 'a finding on a transition, or on a range, read again'
# parts: whole steps, at most 150, a larger step a part of its own
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }; fresh
add() { awk -v a="$1" -v b="$2" '{ print } /^ROW-019 / { for (i = a; i <= b; i++) print "ROW-" i " | behavior | REQ-001 | anonymous | n/a | Promise " i ". Fails if it is not kept. | REQ-001 | owed: spec-only — first stage | origin: REQ-001" }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; }
add 100 520
pt_rs 's/^\(step S02 .*\) RULE-005 /\1 RULE-005 ROW-100..ROW-199 /'; pt_rs 's/^\(step S03 .*rows:\) /\1 ROW-200..ROW-259 /'; pt_rs 's/^\(step S05 .*rows:\) /\1 ROW-260..ROW-519 /'
w "$D"; [ "$LN" = $((N + 421)) ] || fail "the larger plan lists $LN"
for x in '1:S01 S02' '2:S03 S04' '3:S05' '4:-'; do [ "$(awk -F'\t' -v k="${x%%:*}" '$3 == k && !s[$2]++ { printf "%s ", $2 }' "$D/listed" | sed 's/ $//')" = "${x#*:}" ] || { awk -F'\t' '{ print $2, $3 }' "$D/listed" | sort | uniq -c > "$T/out"; fail "part ${x%%:*} does not hold ${x#*:} alone"; }; done
[ ! -e "$D/part-5.md" ] || fail 'a fifth part'
# what the steps are the first to set up, a store no step sets up too, in every part
mkdir "$T/ck"; cp "$CHECKS"/*.sh "$T/ck/"
awk '/^CMD=/ && !d { print "setsup() { printf \047S02\\tingest\\tjob_posting\\n-\\tarchive\\tdigest_archive\\n\047; }"; d = 1 } { print }' "$CHECKS/planner.sh" > "$T/ck/planner.sh"
sh "$T/ck/planner.sh" placements write "$D" > "$T/out" 2>&1 || fail 'placements write, with the list of what is set up, was refused'
for k in 1 2 3 4; do cp "$D/part-$k.md" "$T/out"; awk '/^- S02 / { getline; getline; print }' "$D/part-$k.md" | grep -q '^  first to set up: ingest: job_posting$' || fail "part $k does not say what S02 is the first to set up"
  grep -q '^- in no step: first to set up: archive: digest_archive$' "$D/part-$k.md" || fail "part $k leaves out a store no step sets up"; done
exit 0
