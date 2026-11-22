#!/bin/sh
# Purpose: selftest case — ViD's face R4 (0.26.10.29): vid-create-prd presents each sitting exactly as before and
# writes the sitting whether or not a panel is there. A text check, like create-prd-sentences.sh, gated on ViD's own
# skills beside checks/. Convicts unless: the skill, its added face paragraphs (each opening "**The face (0.26.10.29)")
# taken out, is byte for byte the skill of 0.26.10.28.9 (cksum 218076248 41748; a later release that changes the
# skill on purpose sets the new sum here; 0.26.10.29.3 lane A: R1's 7a, R2's "The owner's words", R3's 7b, R4's
# raised questions; lane C: R9's seed with its own headings at the import door, and the standalone hand-back's
# SEED.md; lane B: R6's standalone WSL question; phase 2 lane F: R1's converging reviews, R2's line, R5's second reader, R6's
# record, R7's wait, R8's running passes; 0.26.10.29.4 phase 3 lane I: R1's pass strength in the findings record, in
# "Reviews converge" and "The second reader", and the whole-set review's --arms input; R7's cut feature line; phase 4 lane L:
# R4's size sentence at pauses 2 and 3, no size number before pause 2, and the scorecard's count line scoped;
# 0.26.10.29.6 lane K1: S1's sitting in each pause's own step and consolidation's sitting, S2's items asked on their
# own, recommendations and blanket yes, S4's changed-since section and repairs in two groups, S5's research request,
# S6's priority marks after answers are written, S7's plain words and counted numbers, S10's where to look, S11's wait
# parts and drafts; the join of its lanes: consolidation's section ids as face.sh takes them; 0.26.11.1.2: R3's foreground sentence, R7's rule, R13's numbered parts;
# 0.26.11.1.3: R2's WSL notice in place of the standalone WSL question, its comment naming the version);
# the added paragraphs are exactly two, writing the interview and each pause and ending each; and no line of them makes anything depend on a panel being present.
# 0.26.10.29.6 (S1): also convicts unless each of the six skills that owns a sitting of stops 6 to 9 carries the
# `face.sh" write <sitting>` call for each, and names each section id face.sh's table holds for that sitting
# (`section <id>` or `empty <id>`), the ids read from the table in checks/face.sh. Env: CHECKS.
set -eu
F="$CHECKS/../skills/vid-create-prd/SKILL.md"
[ -f "$F" ] || { echo 'needs skills/vid-create-prd/SKILL.md'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "face-r4-skill: $*" >&2; exit 1; }
awk '/^\*\*The face \(0\.26\.10\.29\)/ { skip = 1 } skip && /^$/ { skip = 0; next } !skip { print }' "$F" > "$T/base"
# FB-1 A2: the PRD writer's sentence, five times, word for word, is taken out too; the rest is the skill as before
A2S='Write the rulings as an edits file and apply it with `sh "${CLAUDE_PLUGIN_ROOT}/checks/prd-apply.sh" PRD.md <file>`; never edit the machine blocks by hand or with a script of your own. '
awk -v s="$A2S" 'BEGIN { c = 0 } { l = $0; out = ""; while ((i = index(l, s)) > 0) { out = out substr(l, 1, i - 1); l = substr(l, i + length(s)); c++ } print out l } END { print c > "/dev/stderr" }' "$T/base" > "$T/base2" 2> "$T/a2n"
[ "$(cat "$T/a2n")" = 5 ] || fail "the PRD writer's sentence is not in the skill five times (FB-1 A2)"
[ "$(cksum < "$T/base2" | awk '{ print $1, $2 }')" = '115045415 71731' ] || fail 'the skill changed beyond its face paragraphs'
awk '/^\*\*The face \(0\.26\.10\.29\)/ { on = 1 } on && /^$/ { on = 0 } on' "$F" > "$T/face"
[ "$(grep -c '^\*\*The face (0\.26\.10\.29)' "$F")" = 2 ] || fail 'the face paragraphs are not two'
for c in 'face.sh" write interview' 'face.sh" end interview' 'face.sh" write pause-N' 'face.sh" end pause-N'; do
  tr '\n' ' ' < "$T/face" | grep -qF "$c" || fail "no face instruction '$c'"; done
grep -inE 'if (a|the) panel|when (a|the) panel|unless (a|the) panel|panel (is )?(open|present|shown)' "$T/face" && fail 'a face instruction depends on a panel'
grep -q 'whether or not a panel is there' "$T/face" || fail 'the face instructions do not say they hold with or without a panel'
# 0.26.10.29.6 (S1): the skills that carry a call for the sittings of stops 6 to 9, and the sections they name
S=$CHECKS/../skills
ids() { awk -F'\t' -v s="$1" '$1 == "sitting" { on = ($2 == s); next } on && $1 == "section" && $4 == "session" { print $2 }' "$CHECKS/face.sh"; }
for pair in vid-create-prd:consolidation vid-init:technical vid-init:settings vid-staging-setup:technical vid-design:design-who \
    vid-design:design-gaps vid-design:design-lines vid-design:design-approval vid-test-inventory:tests \
    vid-test-inventory:tests-review vid-stage:stages vid-stage:stages-own; do
  k=${pair%%:*}; st=${pair#*:}; K=$S/$k/SKILL.md
  [ -f "$K" ] || fail "no skills/$k/SKILL.md"
  tr '\n' ' ' < "$K" | tr -s ' ' > "$T/flat"
  grep -qF "face.sh\" write $st " "$T/flat" || fail "$k does not write the $st sitting (face.sh\" write $st)"
  n=0; for id in $(ids "$st"); do n=$((n + 1))
    grep -qE "\`(section|empty) $id( |\`)" "$T/flat" || fail "$k does not name the $st sitting's section $id"; done
  [ "$n" -gt 0 ] || fail "face.sh's table holds no section of $st"
done
exit 0
