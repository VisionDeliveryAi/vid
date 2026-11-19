#!/bin/sh
# Purpose: selftest case — the owner's words stay in the commit trailer (0.26.11.1.2, R7, the rule half). Records
# copy what they hold into briefs and the exported spec, and no form rule can tell an owner quote from a quoted screen
# string, so the copy is stopped at the source: one rule, word for word, in vid-create-prd's "The owner's words, and the
# questions raised", and one pointer to it in templates/DECISIONS.md's format text (before its log) and in
# vid-test-inventory §4.6 (golden sets). A text check, gated on ViD's own skills and templates beside checks/. Env: CHECKS.
set -eu
CP="$CHECKS/../skills/vid-create-prd/SKILL.md"; TI="$CHECKS/../skills/vid-test-inventory/SKILL.md"; DT="$CHECKS/../templates/DECISIONS.md"
[ -f "$CP" ] && [ -f "$TI" ] && [ -f "$DT" ] || { echo 'needs skills/ and templates/'; exit 77; }
fail() { echo "owner-words-source: $*" >&2; exit 1; }
flat() { tr '\n' ' ' | sed 's/^[[:space:]]*> *//' | tr -s ' \t' ' '; }
R='**The owner'"'"'s words live in the commit'"'"'s `Owner:` trailer alone.** An answer row, a decision line and a golden set'"'"'s provenance state the ruling in ViD'"'"'s own words and cite its id; they never quote the owner.'
P='never the owner'"'"'s words, which stay in the commit'"'"'s `Owner:` trailer (vid-create-prd, "The owner'"'"'s words, and the questions raised")'
awk '/^## The owner.s words, and the questions raised/ { on = 1; next } on && /^## / { exit } on' "$CP" | flat | grep -qF "$R" || fail 'vid-create-prd'"'"'s "The owner'"'"'s words" section lacks the rule'
[ "$(flat < "$CP" | grep -oF "$R" | grep -c .)" = 1 ] || fail 'the rule is not stated exactly once in vid-create-prd'
awk '/^## Log/ { exit } 1' "$DT" | flat | grep -qF "$P" || fail 'templates/DECISIONS.md'"'"'s format text lacks the pointer'
awk '/^### 4\.6 / { on = 1; next } on && /^##/ { exit } on' "$TI" | flat | grep -qF "$P" || fail 'vid-test-inventory §4.6 lacks the pointer'
exit 0
