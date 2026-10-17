#!/bin/sh
# Purpose: selftest case — the dirty-law refusal says what to do (v0.9.8.1 R3, F-13). Under the real hook with stub
# courts: a commit staging only a product file, while a court file is edited but unstaged and a design file is
# untracked, is refused (by=law-dirty), and the refusal names both files and both ways through — commit them as
# their own law commit, or set them aside with a WIP commit — and never says to restore them; with the law files
# committed first, the same commit passes. In the plugin repository, vid-build's text says the same: no "never stash
# or park work" line, the WIP commit named. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "hook-dirty-law-message: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
printf '# edited\n' >> checks/placement.sh; mkdir -p design; printf 'x\n' > design/new.dc.html
stage product
if sh checks/hooks/pre-commit > "$T/out" 2>&1; then fail 'a commit passed beside unstaged law'; fi
grep -q 'law files are edited but not staged' "$T/out" || fail 'the refusal does not say law files are edited but not staged'
grep -qx '    checks/placement.sh' "$T/out" && grep -qx '    design/new.dc.html' "$T/out" || fail 'the refusal does not name the dirty law files'
grep -q 'as their own law commit' "$T/out" && grep -q 'set them aside with a WIP commit' "$T/out" || fail 'the refusal does not name both ways through'
grep -qi 'restore the files' "$T/out" && fail 'the refusal still says to restore the files'
grep -q 'refused phase=pre-commit by=law-dirty ' .vid/metrics-events || fail 'no refused by=law-dirty event'
g add checks/placement.sh design/new.dc.html; g commit -qm 'the law change, alone' --no-verify
sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'the commit was refused once the law was committed'
SK="$CHECKS/../skills/vid-build/SKILL.md"
if [ -f "$SK" ]; then
  tr '\n' ' ' < "$SK" | tr -s ' ' | grep -q 'never stash or park work' && fail 'vid-build still says never stash or park work'
  tr '\n' ' ' < "$SK" | tr -s ' ' | grep -q 'set them aside with a WIP commit' || fail 'vid-build does not name the WIP commit'
fi
exit 0
