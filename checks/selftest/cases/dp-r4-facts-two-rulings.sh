#!/bin/sh
# Purpose: selftest case — two rulings on one held row since the newest close are two stage facts (0.26.10.29.5, DP-1 R4), checks/close.sh
# summary and close-stage on a bare record set. A delegate's `more 1` and then the round's stand-in `limit` on ROW-005, neither with a Q
# line, both reach the facts, as the status and the completion report read both; a ruling written twice alike is one fact. The summary
# check, naming ROW-005 once, holds the repeated id and closes the stage. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "dp-r4-facts-two-rulings: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
cd "$T"; git init -q; g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p .vid/tw .vid/decide/queue .vid/round; printf '# Run state\n\nrun: active\nstage: 1\n' > .vid/RUN-STATE.md; : > .vid/tw/handed; printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\n```\n' > INVENTORY.md; printf '.vid/\n' > .gitignore   # 0.26.11.1.2 (R6): an INVENTORY.md with no rows, so the plan's rows read empty, never unreadable
printf '# Decisions\n' > DECISIONS.md; printf '# PRD\n' > PRD.md; g add -A; g commit -qm root
X=$(git rev-parse HEAD); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs" "$F/w1"; printf 'commit\t%s\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"
: > "$F/named"; : > "$F/passed"; : > "$F/d1/passed"; : > "$F/cs/passed"; echo 'no walk: this stage has no screens and no journey' > "$F/w1/none"
printf 'stage-closed n=0 sha=000000000000 at=2026-11-10T00:00:00Z\n' > .vid/metrics-events
{ printf '2026-11-11T10:00:00Z\tROW-005\tmore\t1\tdelegate\n'; printf '2026-11-11T10:05:00Z\tROW-005\tlimit\t\tstand-in\n'
  printf '2026-11-11T10:06:00Z\tROW-005\tlimit\t\tstand-in\n'; } > .vid/decide/rulings   # the last, the second written alike
sh "$CHECKS/close.sh" summary --stage 1 > "$T/out" 2>&1 || fail 'the summary failed'
awk -F'\t' '$1 == "decided" && $2 == "ROW-005"' "$F/facts.txt" > "$T/r5"
grep -q 'more: 1 (by delegate)' "$T/r5" || fail "the delegate's ruling is not a fact: $(cat "$T/r5")"
grep -q 'limit (by stand-in)' "$T/r5" || fail "the stand-in's later ruling on the same row is not a fact: $(cat "$T/r5")"
[ "$(grep -c . "$T/r5")" = 2 ] || fail "not two facts for ROW-005: $(cat "$T/r5")"
printf '**Working now:** nothing yet · **Went back:** nothing · **Decided for you:** ROW-005, more runs and then a known limit · no walk: this stage has no screens and no journey\n' > "$F/summary.md"
sh "$CHECKS/close.sh" close-stage --stage 1 > "$T/out" 2>&1 || true; grep -q '^stage-closed 1 at [0-9a-f]*$' "$T/out" || fail 'a summary naming ROW-005 once did not close the stage'
exit 0
