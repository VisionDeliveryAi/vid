#!/bin/sh
# Purpose: selftest case — every grader reads a decision's rule only, this head's too (0.26.10.29.5, DP-1 R3). The test
# manager's rules drop each decision's why: from every grader's plain ticket, at every head and of every kind, not a fix
# ticket's alone (whose failed: lines and history still go), the break job note too; a head grader's job note carries this pull
# request's Decisions section, each line up to | why:. The grader's decision sweep and the stage grader read each exported
# decision up to | why: and never past it. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$CHECKS/..
[ -d "$R/devagent" ] || { echo 'needs devagent/'; exit 77; }
fail() { echo "dp-r3-grader-note: $*" >&2; exit 1; }
TM=$R/devagent/test-manager/SKILL.md; GR=$R/devagent/agents/grader.md; SG=$R/devagent/agents/stage-grader.md
j() { tr '\n' ' ' < "$1"; }   # a file joined, its line breaks as spaces
has() { j "$1" | grep -qF -- "$2" || fail "$3"; }
has "$TM" "Every grader's plain ticket, at every head and of every kind, drops the \`why:\` of each decision, each decision line kept up to \` | why:\`" "a step ticket's grader still reads each decision's why"
has "$TM" "a fix ticket's also drops its \`failed:\` lines and its history" "a fix ticket's grader reads its failed: lines or history"
! j "$TM" | grep -qF "a fix ticket's plain ticket drops its \`failed:\` lines, its history and the \`why:\` of each decision" || fail 'the why is still dropped for a fix ticket alone'
has "$TM" "the plain ticket (its body and parts, no other comment; each decision's \`why:\` dropped, as step 4 says)" "the break grader's job note keeps each decision's why"
has "$TM" "before the job note is written, each line up to \` | why:\`" "the head grader's job note lacks this head's Decisions section, its rules alone"
has "$GR" "the decision sweep reads the exported decisions, each up to \` | why:\` and never past it, and the Decisions section your job note carries" "the grader's sweep reads an exported decision past its rule"
has "$GR" "at a head, this pull request's Decisions section, each line up to \` | why:\`" "the grader's job note does not name this head's Decisions section"
has "$SG" "each read up to \` | why:\` and never past it" "the stage grader reads an exported decision past its rule"
echo 'dp-r3-grader-note: ok'
