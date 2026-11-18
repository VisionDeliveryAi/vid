#!/bin/sh
# Purpose: selftest case — DevAgent's role text keeps the pull request's Decisions section (0.26.10.29.5, DP-1 R1). The dev
# manager rewrites the section at each head, once its build or fix hand-back is in, before the head graders' job notes and
# before each decide ask, from the branch commits' Decisions: lines since main and its own settled technical questions, a none
# line left out, Decisions: none when nothing is left, the rest of the body kept with its ticket line first; a settled
# technical question goes in the record and in the section, no longer "nowhere else"; a "not yet" reading decisions missing
# is a same-head route, no agent and no new head. The test manager's grade job note comes after the rewrite. The builder
# points at the ticket's Decisions paragraph and sends a new or extended lifecycle back as a question. Skips where devagent/
# is absent (a project's layout). Env: CHECKS.
set -eu
R=$CHECKS/..
[ -d "$R/devagent" ] || { echo 'needs devagent/'; exit 77; }
fail() { echo "dp-r1-devagent-text: $*" >&2; exit 1; }
DM=$R/devagent/agents/dev-manager.md; BU=$R/devagent/agents/builder.md; TM=$R/devagent/test-manager/SKILL.md
j() { tr '\n' ' ' < "$1"; }   # a file joined, its line breaks as spaces
has() { j "$1" | grep -qF -- "$2" || fail "$3"; }
# the dev manager: the rewrite, its time and its sources
has "$DM" '**The Decisions section**' 'the dev manager has no Decisions section paragraph'
P=$(awk '/^\*\*The Decisions section\*\*/ { on = 1 } on && /^$/ { exit } on' "$DM" | tr '\n' ' ')
for w in 'as soon as its build or fix hand-back is in' "before the head graders' job notes" 'before each `vid: decide <the head>`' \
  '`git log origin/main..<the head>`' "each technical question you settled in the ticket's record" 'A `none` line is left out' \
  'the one line `Decisions: none`' 'its `ticket: #<n>` line first' "the ticket's asks, its Decisions paragraph"; do
  printf '%s' "$P" | grep -qF -- "$w" || fail "the Decisions section paragraph lacks: $w"; done
has "$DM" "| A technical question | Settle it, in the ticket's record and in the pull request's Decisions section | Nothing |" 'a settled technical question does not go in the section'
! grep -q 'Nowhere else' "$DM" || fail 'a technical question still goes nowhere else'
# the not-yet route: same-head, no agent, no new head
n=$(grep -n '^\*\*A "not yet"\*\*' "$DM" | cut -d: -f1); m=$(grep -n '^Only when none of those is left' "$DM" | cut -d: -f1); d=$(grep -n '^- `decisions missing`:' "$DM" | cut -d: -f1 || true)
[ -n "$d" ] || fail 'the not-yet routes lack decisions missing'
[ "$d" -gt "$n" ] && [ "$d" -lt "$m" ] || fail 'decisions missing is not a same-head route'
sed -n "${d}p" "$DM" | grep -q 'no agent, no new head' || fail 'decisions missing is answered with an agent or a new head'
# the test manager: the grade's job note after the rewrite
has "$TM" "this pull request's Decisions section, rewritten for this head before the job note is written" "the test manager's grade job note does not wait for the section"
# the builder: the pointer and the lifecycle
has "$BU" "what counts as a decision is the ticket's Decisions paragraph, in its asks" "the builder's Decisions: line does not point at the ticket's paragraph"
has "$BU" "a new or extended lifecycle (the states a stored record moves through) or work outside the ticket's modules goes back in your hand-back as a question" 'the builder does not send a new lifecycle back as a question'
echo 'dp-r1-devagent-text: ok'
