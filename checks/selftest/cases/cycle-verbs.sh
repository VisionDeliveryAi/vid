#!/bin/sh
# Purpose: selftest case — every cycle skill a verb (GM-4 F14, 4a's part). vid-answer, vid-read, vid-triggers and vid-replan are
# commands the owner calls: none says `user-invocable: false`, none's description opens "Internal" or says "Not a verb", and
# each names its `/vid:vid-<name>` command. vid-help lists each in its verbs table. vid-read reads GitHub through the one read
# (`round.sh read`, into `.vid/round/read`) and names no `next-read` and no `.vid/next/read`; vid-triggers reads `.vid/round/read`.
# Reads skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-help" ] || { echo 'cycle-verbs: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "cycle-verbs: $*" >&2; exit 1; }
H=$S/vid-help/SKILL.md; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
for k in vid-answer vid-read vid-triggers vid-replan; do F=$S/$k/SKILL.md; [ -f "$F" ] || fail "there is no $k skill"
  awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$F" > "$T/fm"
  ! grep -q '^user-invocable: false' "$T/fm" || fail "$k is not a command (user-invocable: false)"
  ! grep -qE '^description: *"?Internal' "$T/fm" && ! grep -q 'Not a verb' "$T/fm" || fail "$k's description says it is internal, not a verb"
  grep -qF "/vid:$k" "$F" || fail "$k does not name its command /vid:$k"
  grep -q "^| \*\*/vid:$k\*\* |" "$H" || fail "vid-help does not list /vid:$k"; done
R=$S/vid-read/SKILL.md
grep -qF 'sh checks/round.sh read' "$R" && grep -qF '.vid/round/read' "$R" || fail 'vid-read does not read through round.sh read into .vid/round/read'
! grep -qE 'next-read|\.vid/next/read' "$R" || fail 'vid-read still names next-read or .vid/next/read'
! grep -qE 'next-read|\.vid/next/read' "$S/vid-triggers/SKILL.md" && grep -qF '.vid/round/read' "$S/vid-triggers/SKILL.md" || fail 'vid-triggers does not read .vid/round/read'
echo 'cycle-verbs: ok'
