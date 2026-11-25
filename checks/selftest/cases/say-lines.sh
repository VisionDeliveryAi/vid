#!/bin/sh
# Purpose: selftest case — what the owner is told is printed as words to say (FB-7 B3, the toy run of 26.11.1.12: the run read its
# questions, a flag and an hourly update in command output and said none). GitHub auto, on the ticket writer's toy and the fake gh:
# `say to the owner now, as text: …` once for each question, under the command that bears it — a dev side's question asked through
# the queue (`queue.sh ask <n>:<k>`), one of ViD's own (`ask own`), and one a step raises itself, at that step; not at the next one,
# nor for a question that closed before; a sync of another command swallows none. The step's `update` and each `flag` line have one
# too, once. GitHub manual prints none of them. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "say-lines: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; QS=$CHECKS/queue.sh; R=owner/code; W='say to the owner now, as text: '
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $* exited $RC"; }
q() { sh "$QS" "$@" > "$T/out" 2>&1 || fail "queue.sh $* failed"; }
says() { [ "$(grep -cF -- "$W" "$T/out")" = "$1" ] || fail "$2: not $1 say line(s)"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd next; grep -q '^published 1$' "$T/out" || fail 'no ticket 1'
# the first step is an hourly update's: its words once, not at the next
rd step; grep -qx update "$T/out" || fail 'the first step printed no update'; says 1 'the update'; grep -qF -- "${W}the status, whole" "$T/out" || fail 'the update'"'"'s say line does not name the status'
rd step; says 0 'the step after the update'
# a dev side's question
printf 'Question: Which rounding does the total use?\nby: BU\n' > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; rd step; grep -q '^question 1 ' "$T/out" || fail 'no question line'; says 0 'a question not asked of the owner'
K=$(sed -n 's/^question 1 //p' "$T/out"); q ask "1:$K"; N=$(sed -n 's/^asked \(Q[0-9]*\)$/\1/p' "$T/out"); grep -qF -- "$W$N: Question: Which rounding does the total use?" "$T/out" || fail 'the asked question has no say line of its words'; says 1 'the question asked'
q ask "1:$K"; says 0 'the same question asked again'; rd step; says 0 'the step after the ask'
# one of ViD's own
q ask own 'Which days count as working days?' --gates ROW-002; N=$(sed -n 's/^asked \(Q[0-9]*\) own .*/\1/p' "$T/out"); grep -qF -- "$W$N: ViD's question: Which days count as working days?" "$T/out" || fail "ViD's own question has no say line"
# one a step raises itself: born at its sync; another command's sync before it swallows none, and one that closed is not said
printf 'z1\t2026-11-25T10:00:00Z\tROW-002\tIs a half day a day?\nz2\t2026-11-25T10:00:00Z\tROW-002\tClosed at once?\n' >> .vid/decide/queue/own
sh "$QS" sync > /dev/null 2>&1; grep -v 'Closed at once' .vid/decide/queue/own > "$T/own"; cat "$T/own" > .vid/decide/queue/own
rd step; grep -q -- "^${W}Q[0-9]*: ViD's question: Is a half day a day?" "$T/out" || fail 'a question the step raised has no say line'; says 1 'the step that raised it'; rd step; says 0 'the step after it'
# a flag
awk -F'\t' -v OFS='\t' 'NR == 1 { $1 = "2020-01-01T00:00:00Z" } { print }' .vid/round/dev > "$T/dv"; cat "$T/dv" > .vid/round/dev
rd step; grep -q '^flag devagent-quiet ' "$T/out" || fail 'no flag'; grep -qF -- "${W}this flag, in its row's words: devagent-quiet #1" "$T/out" || fail 'the flag has no say line'; says 1 'the flag'; rd step; says 0 'the step after the flag'
# GitHub manual: none
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-25T09:00:00Z\n' >> .vid/plan/setup
q ask own 'In manual, which holidays?' --gates ROW-002; says 0 'GitHub manual, ask own'; printf 'z3\t2026-11-25T10:00:00Z\tROW-002\tIn manual too?\n' >> .vid/decide/queue/own; RC=0; sh "$CHECKS/round.sh" step > "$T/out" 2>&1 || RC=$?; says 0 'GitHub manual, a step'
echo 'say-lines: ok'
