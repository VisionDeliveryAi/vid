#!/bin/sh
# Purpose: selftest case — the status names the answers given in the owner's place and the merges whose decisions were not recorded
# (0.26.10.29.5, DP-1 R4), checks/queue.sh status on a bare record set. Its delegated answers are the same set as the stage facts' and
# the completion report's: a delegate's answer and continue, RM's finding answer, the round's stand-in ruling on a held row, never the
# owner's, the hold's second record or a landing's reset. From the decisions-recorded events: `merged with no decisions stated: #<p>, …`
# for n=missing and `decisions refused: #<p>, …` for n=refused, each pull request once; and both say none in words when there is
# none. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "dp-r4-status-lines: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mk() { rm -rf "$T/p"; mkdir -p "$T/p"; cd "$T/p"; git init -q; mkdir -p .vid/tw .vid/decide/queue .vid/round; printf '# Run state\n\nrun: active\nstage: 1\n' > .vid/RUN-STATE.md; : > .vid/tw/handed
  printf '# Decisions\n' > DECISIONS.md; printf '# PRD\n' > PRD.md; : > .vid/metrics-events; }
st() { VID_STATUS_KEEP=1 sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail "the status failed: $(tail -n 2 "$T/out")"; }
# none of either: said in words
mk; st; grep -qx 'merged with no decisions stated: none' "$T/out" || fail 'no merge without decisions is not said in words'
grep -qx 'decisions refused: none' "$T/out" || fail 'no refused decisions is not said in words'
# the events, one pull request recorded twice, a deploy's apart
{ printf 'decisions-recorded pr=12 n=missing at=2026-11-11T10:00:00Z\n'; printf 'decisions-recorded pr=13 n=2 at=2026-11-11T10:01:00Z\n'
  printf 'decisions-recorded pr=14 n=missing at=2026-11-11T10:02:00Z\n'; printf 'decisions-recorded pr=15 n=refused at=2026-11-11T10:03:00Z\n'
  printf 'decisions-recorded pr=16 n=none at=2026-11-11T10:04:00Z\n'; printf 'decisions-recorded pr=12 n=missing at=2026-11-11T10:05:00Z\n'
  printf 'decisions-recorded deploy=4 n=1 at=2026-11-11T10:06:00Z\n'; } >> .vid/metrics-events
{ printf '2026-11-11T10:00:00Z\tquestion:5:1\t-\tthe owner own words\towner\tanswered\n'
  printf '2026-11-11T10:01:00Z\tquestion:6:1\t-\tseven days, as the spec says\tdelegate\tdelegated\n'
  printf '2026-11-11T10:02:00Z\tfinding:7:1\tno\tas built is fine\tRM\truled\n'
  printf '2026-11-11T10:05:00Z\tcontrol:hold\toff\tbuild on\tdelegate\tdone\n'
  printf '2026-11-11T10:06:00Z\tcontrol:continue\thold off 1\tgo on\tdelegate\tdone\n'; } > .vid/decide/queue/answers
{ printf '2026-11-11T10:07:00Z\tROW-009-T1\tlimit\t\tstand-in\n'; printf '2026-11-11T10:08:00Z\tROW-001\taccept\tyes\towner\n'
  printf '2026-11-11T10:10:00Z\tROW-003\treset\tlanded at abc\tSP\n'; } > .vid/decide/rulings
st; grep -qx 'merged with no decisions stated: #12, #14' "$T/out" || fail "the merges with no decisions stated: $(grep '^merged with' "$T/out")"
grep -qx 'decisions refused: #15' "$T/out" || fail "the refused decisions: $(grep '^decisions refused' "$T/out")"
awk '/^delegated answers since the last update:$/ { on = 1; next } on && /^  / { print; next } { on = 0 }' "$T/out" > "$T/da"
for i in question:6:1 finding:7:1 control:continue ROW-009-T1; do grep -qF -- "$i" "$T/da" || fail "the status's answers miss $i: $(cat "$T/da")"; done
for i in question:5:1 control:hold ROW-001 ROW-003; do ! grep -qF -- "$i" "$T/da" || fail "the status's answers hold $i: $(cat "$T/da")"; done
grep -qx '  question:6:1 — seven days, as the spec says · answered for you, under your delegation' "$T/da" || fail "the delegate's line: $(cat "$T/da")"
exit 0
