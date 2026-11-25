#!/bin/sh
# Purpose: selftest case — the placements' two readers, one skill (FB-4 A1.2, A1.3). vid-placement-review is the owner's command in both
# GitHub modes (vid-help lists it), runs the list, the two passes and the result through `planner.sh placements`, spawns each agent
# fresh, in the foreground, with no model override, renews the lock before each set, saves the outputs as given and asks one second round. The eight
# rules stand once, in its passes/reader.md, which the refuter's brief names and does not copy; neither pass, nor any skill, holds a
# second copy. vid-plan and vid-replan (both modes) invoke it and hold no spawn of it; vid-run and vid-next name neither pass. Reads
# skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-plan" ] || { echo 'placement-review-skill: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "placement-review-skill: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
one() { tr '\n' ' ' < "$1" | tr -s ' '; }
K=$S/vid-placement-review; V=$K/SKILL.md; R=$K/passes/reader.md; F=$K/passes/refuter.md
for f in "$V" "$R" "$F"; do [ -f "$f" ] || fail "there is no ${f#"$S/"}"; done
grep -q '^name: vid-placement-review$' "$V" || fail 'the skill does not name itself'
awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$V" > "$T/fm"
! grep -q 'user-invocable: false' "$T/fm" && ! grep -qE '^description: *"?Internal' "$T/fm" || fail 'the skill is not the owner'"'"'s command'
grep -q '^| \*\*/vid:vid-placement-review\*\* |' "$S/vid-help/SKILL.md" || fail 'vid-help does not list it'
one "$V" > "$T/v"
for p in 'in either GitHub mode' 'placements write' 'placements result' 'placements show' '.vid/plan/placement-check' '--all' 'no model override' 'run_in_background: false' 'lock-renew' 'passes/reader.md' 'passes/refuter.md' 'never edited' '--again' 'There is no third'; do
  grep -qF -- "$p" "$T/v" || fail "the skill lacks: $p"; done
! grep -qE -- '--model|model: ?"' "$T/v" || fail 'the skill overrides the model'
! grep -q 'GitHub manual alone\|GitHub auto alone' "$T/v" || fail 'the skill is for one mode only'
# the rules, once
for p in 'The step builds what the test checks' 'Everything the test needs to be shown exists by then' 'The step is of the test'"'"'s own stage\|The scripts hold each test to a step of its own stage' 'gains a test only when it already builds what the test checks' 'The tests of one behaviour stand in one step' 'builds something no other step does' 'names what its tests need, and nothing in it that none of them needs' 'are set up by a step, a ticket or a stated issue'; do
  one "$R" | grep -q "$p" || fail "the reader's brief lacks the rule: $p"
  for f in $(find "$S" -name '*.md' ! -path "$R"); do ! one "$f" | grep -q "$p" || fail "${f#"$S/"} holds a second copy of a rule: $p"; done; done
[ "$(grep -cE '^[1-8]\. \*\*' "$R")" = 8 ] || fail "the reader's brief does not hold eight rules"
for f in "$R" "$F"; do grep -q '^receives: ' "$f" && grep -q '^must not receive: ' "$f" && one "$f" | grep -qF 'Spawned as a SEPARATE AGENT' || fail "${f#"$S/"} lacks the pass header"; done
grep -qF 'passes/reader.md' "$F" || fail 'the refuter is not sent to the one text of the rules'
one "$R" | grep -qF 'None is a good answer' && one "$R" | grep -qF 'At most 15' && one "$R" | grep -qF 'A finding needs all four' || fail "the reader's brief lacks the owner's bar"
# the return forms are the ones `placements result` reads
grep -qF 'placed right=<n> finding=<n> unjudged=<n>' "$R" && grep -q '^ *finding <n> | ' "$R" && grep -q '^ *refuted <n> | ' "$F" && grep -q '^ *partly <n> | better: ' "$F" || fail 'a return form is not the script'"'"'s'
# a refused first reader: step 3 again for its part
one "$V" | grep -qF "a refused first reader's second reader goes with it: step 3 is done again for that part" || fail 'the skill does not run the second reader again after a refused first reader'
! one "$S/vid-replan/SKILL.md" | grep -qF 'its reason in `left`' || fail 'vid-replan sends the reason of a finding not taken up to left, which refuses it'
# the callers
for k in vid-plan vid-replan; do one "$S/$k/SKILL.md" | grep -qF 'the `vid-placement-review` skill' || fail "$k does not invoke it"; done
awk '/^## GitHub auto/ { on = 1; next } /^## GitHub manual/ { on = 0 } on' "$S/vid-replan/SKILL.md" | grep -qF 'vid-placement-review' || fail 'vid-replan does not invoke it in GitHub auto'
awk '/^## GitHub manual/ { on = 1 } on' "$S/vid-replan/SKILL.md" | grep -qF 'vid-placement-review' || fail 'vid-replan does not invoke it in GitHub manual'
for k in vid-plan vid-replan vid-run vid-next vid-mode; do ! grep -qE 'passes/(reader|refuter)\.md' "$S/$k/SKILL.md" || fail "$k holds the review's own text"; done
echo 'placement-review-skill: ok'
