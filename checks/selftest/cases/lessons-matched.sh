#!/bin/sh
# Purpose: selftest case — briefs carry the lessons that match (v0.9.8 spec 3.5, R8; amendment 3). .vid/test-lessons.md
# holds three entries: L-1 (rules: REQ-001), L-2 (helpers: tests/invariants/links.sh) and L-3 (rules: REQ-009). A
# test-author's brief for ROW-201 (REQ-001; its test file links.sh) carries `## 17 lessons` with L-1 and L-2, whole,
# never L-3 nor the whole file; a brief for ROW-205 (nothing matching) carries none; the check refuses an entry that is
# not the file's, whole. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "lessons-matched: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
au_repo "$T/repo"; au_more; au_stamp
mkdir -p .vid
cat > .vid/test-lessons.md <<'L'
# Test lessons

## L-1 · 2026-10-10 · from ROW-101
helpers: none
rules: REQ-001
bad: the test read the link at six days, where right and wrong agree
why: a product whose links never expire passed
good: read it one second past seven days, and one second before

## L-2 · 2026-10-11 · from ROW-102
helpers: tests/invariants/links.sh
rules: REQ-005
bad: fresh() reused one code for every test
why: a product that ignores the code passed
good: fresh() draws a new code per run

## L-3 · 2026-10-11 · from ROW-103
helpers: none
rules: REQ-009
bad: the deleted code was never asked for again
why: a product that keeps deleted codes passed
good: ask for it after the deletion
L
w() { CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role "$1" --slice 1 --rows "$2" > "$T/out" 2>&1 || fail "the $1 brief for $2 was refused"; sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1; }
for r in test-author; do
  B=$(w "$r" ROW-201)
  awk '/^## [0-9]/ { on = ($2 == 17); next } on' "$B" > "$T/s17"
  [ "$(grep -o '^## L-[0-9]*' "$T/s17" | paste -sd ' ' -)" = '## L-1 ## L-2' ] || fail "the $r brief carries $(grep -o '^## L-[0-9]*' "$T/s17" | paste -sd ' ' -), not L-1 and L-2"
  grep -qx 'good: fresh() draws a new code per run' "$T/s17" || fail "the $r brief does not quote L-2 whole"
done
grep -qx '## 17 lessons' "$(w test-author ROW-205)" && fail 'a brief with nothing matching carries lessons'
B=$(w test-author ROW-201); grep -v '^written: ' "$B" | sed 's/^good: fresh() draws a new code per run$/good: anything works/' > "$T/b.md"
if sh checks/brief.sh "$T/b.md" > "$T/out" 2>&1; then fail 'a lesson that is not the file'"'"'s passed the check'; fi
grep -q "section 17: the lesson '## L-2" "$T/out" || fail 'the refusal does not name the lesson'
exit 0
