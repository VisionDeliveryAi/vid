#!/bin/sh
# Purpose: selftest case — the stage summary's "decided for you" names every answer given in the owner's place (0.26.10.29.5, DP-1 R4),
# checks/close.sh summary and close-stage on a bare record set. Since the newest close: the queue's answers by a delegate, by RM and by a
# stand-in, a delegate's continue, RM's held-row ruling (by its Q line) and the round's own stand-in ruling on a held row (by its row,
# as it has no Q line) are facts; the owner's answers and rulings, a later head's undo, a landing's reset, the hold's second record of
# one continue, the queue's held-row answer (its ruling is the record) and anything before the close are not. The summary check
# refuses a summary that leaves the stand-in's ruling out and closes the stage once it names every fact. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "dp-r4-facts-not-owner: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cd "$T"; git init -q; g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p .vid/tw .vid/decide/queue .vid/round; printf '# Run state\n\nrun: active\nstage: 1\n' > .vid/RUN-STATE.md; : > .vid/tw/handed; printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\n```\n' > INVENTORY.md; printf '.vid/\n' > .gitignore   # 0.26.11.1.2 (R6): an INVENTORY.md with no rows, so the plan's rows read empty, never unreadable
printf '# Decisions\n' > DECISIONS.md; printf '# PRD\n' > PRD.md; g add -A; g commit -qm root
# stage 1's candidate, every close condition met but the summary; stage 0 closed on 2026-11-10
X=$(git rev-parse HEAD); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs" "$F/w1"; printf 'commit\t%s\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"
: > "$F/named"; : > "$F/passed"; : > "$F/d1/passed"; : > "$F/cs/passed"; echo 'no walk: this stage has no screens and no journey' > "$F/w1/none"
printf 'stage-closed n=0 sha=000000000000 at=2026-11-10T00:00:00Z\n' > .vid/metrics-events
TAB=$(printf '\t')
{ printf '2026-11-09T10:00:00Z\tquestion:4:1\t-\tbefore the close\tdelegate\tdelegated\n'
  printf '2026-11-11T10:00:00Z\tquestion:5:1\t-\tthe owner own words\towner\tanswered\n'
  printf '2026-11-11T10:01:00Z\tquestion:6:1\t-\tseven days, as the spec says\tdelegate\tdelegated\n'
  printf '2026-11-11T10:02:00Z\tfinding:7:1\tno\tas built is fine\tRM\truled\n'
  printf '2026-11-11T10:03:00Z\tquestion:8:1\t-\tthe round answered for an absent answerer\tstand-in\tdelegated\n'
  printf '2026-11-11T10:04:00Z\theld:ROW-005\ta\t\tRM\taccept\n'
  printf '2026-11-11T10:04:10Z\tstage:1:case:test_login\tagain\tonce more\tRM\truled\n'
  printf '2026-11-11T10:04:20Z\tstage:1:case:test_login_twice\tlimit\tas it is\tRM\truled\n'
  printf '2026-11-11T10:04:30Z\tshrink:1@ROW-001\tyes\tsmaller\tRM\truled\n'
  printf '2026-11-11T10:04:40Z\tshrink:1@ROW-001,ROW-004\tyes\tsmaller\tRM\truled\n'
  printf '2026-11-11T10:05:00Z\tcontrol:hold\toff\tbuild on\tdelegate\tdone\n'
  printf '2026-11-11T10:06:00Z\tcontrol:continue\thold off 1\tgo on\tdelegate\tdone\n'; } > .vid/decide/queue/answers
printf 'held:ROW-005\tQ3\n' > .vid/decide/queue/ids
{ printf '2026-11-11T10:04:00Z\tROW-005\taccept\t\tRM\n'
  printf '2026-11-11T10:07:00Z\tROW-009-T1\tlimit\t\tstand-in\n'
  printf '2026-11-11T10:08:00Z\tROW-001\taccept\tyes\towner\n'
  printf '2026-11-11T10:09:00Z\tROW-002\tundone\ta later head failed it\tdecide\n'
  printf '2026-11-11T10:10:00Z\tROW-003\treset\tlanded at abc\tSP\n'
  printf '2026-11-09T10:00:00Z\tROW-010\tlimit\t\tstand-in\n'; } > .vid/decide/rulings
sh "$CHECKS/close.sh" summary --stage 1 > "$T/out" 2>&1 || fail 'the summary failed'
awk -F'\t' '$1 == "decided" { print $2 }' "$F/facts.txt" | sort > "$T/ids"
for i in question:6:1 finding:7:1 question:8:1 control:continue Q3 ROW-009-T1 stage:1:case:test_login stage:1:case:test_login_twice shrink:1@ROW-001 shrink:1@ROW-001,ROW-004; do grep -qxF "$i" "$T/ids" || fail "the facts miss $i, an answer not the owner's: $(paste -sd ' ' "$T/ids")"; done
for i in question:4:1 question:5:1 control:hold ROW-001 ROW-002 ROW-003 ROW-010 held:ROW-005; do ! grep -qxF "$i" "$T/ids" || fail "the facts hold $i, the owner's, a reset or undo, the hold's second record, or before the close"; done
[ "$(grep -c . "$T/ids")" = 10 ] || fail "not ten decided facts: $(paste -sd ' ' "$T/ids")"
# FB-8 E5: an id that a longer decided id begins with counts only where it stands by itself, the two in either order
L2='stage:1:case:test_login_twice: a word, shrink:1@ROW-001,ROW-004: a word'
printf '**Working now:** nothing yet · **Went back:** nothing · **Decided for you:** question:6:1, finding:7:1, question:8:1, control:continue, Q3, ROW-009-T1, %s · no walk: this stage has no screens and no journey\n' "$L2" > "$F/summary.md"
sh "$CHECKS/close.sh" close-stage --stage 1 > "$T/out" 2>&1 || true; grep -q '^summary-refused 1 the summary misses the decisions shrink:1@ROW-001, stage:1:case:test_login$' "$T/out" || fail 'a longer decided id counted for one it begins with'
L2="$L2, stage:1:case:test_login: a word, shrink:1@ROW-001, a word"
# the summary check: the stand-in's ruling left out is refused; every fact named closes the stage
printf '**Working now:** nothing yet · **Went back:** nothing · **Decided for you:** question:6:1, finding:7:1, question:8:1, control:continue, Q3, %s · no walk: this stage has no screens and no journey\n' "$L2" > "$F/summary.md"
sh "$CHECKS/close.sh" close-stage --stage 1 > "$T/out" 2>&1 || true; grep -q '^summary-refused 1 the summary misses the decision ROW-009-T1$' "$T/out" || fail 'a summary without the stand-in ruling was not refused'
# FB-8 E5: the ids missing, all in one line; a key that is the start of another never counts by it; an id followed by a colon or a hyphen and a space does
printf '**Working now:** nothing yet · **Went back:** nothing · **Decided for you:** question:6:1:2, finding:7:1 - y, question:8:1, control:continue, Q3-T1, ROW-009-T1, %s · no walk: this stage has no screens and no journey\n' "$L2" > "$F/summary.md"
sh "$CHECKS/close.sh" close-stage --stage 1 > "$T/out" 2>&1 || true; grep -q '^summary-refused 1 the summary misses the decisions Q3, question:6:1$' "$T/out" || fail 'the two ids missing were not named in one line, or an id counted by one it begins'
printf '**Working now:** nothing yet · **Went back:** nothing · **Decided for you:** question:6:1: a word, finding:7:1 - y, question:8:1:, control:continue: a word, Q3- a word, ROW-009-T1: a word, %s · no walk: this stage has no screens and no journey\n' "$L2" > "$F/summary.md"
sh "$CHECKS/close.sh" close-stage --stage 1 > "$T/out" 2>&1 || true; grep -q '^stage-closed 1 at [0-9a-f]*$' "$T/out" || fail 'a summary naming every fact did not close the stage'
exit 0
