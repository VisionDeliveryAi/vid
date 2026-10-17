#!/bin/sh
# Purpose: selftest case — the two create-prd sentences (v0.9.5 spec 3.16,
# 3.17; R14, R15; §7 case 27). A text check, like passes.sh, gated on ViD's
# own skills beside checks/ (a project keeps no copy, so there it proves
# nothing). Convicts unless vid-create-prd holds exactly two copies of the
# one-writer rule, identical, each carrying §3.16's sentence word for word,
# and §6 (item authoring) carries §3.17's sentence word for word.
# Env: CHECKS.
set -eu
F="$CHECKS/../skills/vid-create-prd/SKILL.md"
[ -f "$F" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "create-prd-sentences: $*" >&2; exit 1; }
awk -v d="$T" '/^> \*\*One writer per step\*\*/ { n++; on = 1 } on && !/^>/ { on = 0 } on { print > (d "/copy" n) }' "$F"
[ -f "$T/copy1" ] && [ -f "$T/copy2" ] && [ ! -f "$T/copy3" ] || fail 'not exactly two copies of the one-writer rule'
cmp -s "$T/copy1" "$T/copy2" || fail 'the two copies differ'
S16='The one writer writes PRD.md in several appends, each in its own response, never the whole set in one: a response has an output cap, and its thinking counts against it. The appends are one agent'"'"'s writes in sequence, over the whole input it has read; they are not a split of the work.'
for c in 1 2; do sed 's/^> *//' "$T/copy$c" | tr '\n' ' ' | tr -s ' ' | grep -qF "$S16" || fail "copy $c lacks the several-appends sentence"; done
S17='A human answer that a T0 item rests on — one the item cites, one whose `settles:` names it, or one that resolves a question it routes to — carries `importance: priority`. When an item you write makes that true, add the label to the answer as you write the item, and list the answers you marked in your output. The owner may lower any of them at pause 2.'
awk '/^### 6\. Item authoring/ { on = 1; next } on && /^### / { exit } on' "$F" | sed 's/^[[:space:]]*> *//' | tr '\n' ' ' | tr -s ' ' | grep -qF "$S17" || fail '§6 lacks the importance sentence'
exit 0
