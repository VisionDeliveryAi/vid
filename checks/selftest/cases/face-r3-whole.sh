#!/bin/sh
# Purpose: selftest case — ViD's face R3 (0.26.10.29): the sitting is written by a script, whole or not at all, and
# what the session contributes is checked line by line. Convicts unless: each malformed line (an unknown keyword, a
# section the sitting lacks or a script prints, a detail before any item, a choice outside questions, an id given
# twice, a section given twice) is refused naming its line number, with the sitting already there left byte for
# byte and no temporary file left beside it; the JSON written parses; and face.sh only ever renames into
# sitting.json and standing.json, never writes them in place. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-r3-whole: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
fc_run write pause-1 lines.pause-1; [ "$RC" = 0 ] || fail "the good lines were refused: $OUT"
fc_json "d['format']" >/dev/null || fail 'the sitting does not parse'
cp .vid/face/sitting.json before
n=0
while IFS='#' read -r line want; do n=$((n + 1))
  { cat lines.pause-1; printf '%s\n' "$line"; } > "bad$n"
  fc_run write pause-1 "bad$n"
  [ "$RC" != 0 ] || fail "malformed line $n ($line) was taken"
  want=$((want + $(wc -l < lines.pause-1) - 9))   # 0.26.10.29.6: the fixture's pause-1 grew by its recommendations
  printf '%s\n' "$OUT" | grep -q "line $want:" || fail "malformed line $n is not refused by its number $want: $OUT"
  cmp -s before .vid/face/sitting.json || fail "a refused write ($line) changed the sitting"
  [ -z "$(ls -A .vid/face | grep -vxE 'sitting.json|standing.json' || true)" ] || fail "a refused write left a file: $(ls -A .vid/face)"
done <<'B'
frobnicate X#10
section gaps#10
section features#10
section thesis#10
item F-01 | again#10
choice | yes#10
B
printf 'section thesis\ndetail | before any item\n' > early; fc_run write pause-1 early
printf '%s\n' "$OUT" | grep -q 'line 2:' || fail "a detail before any item is not refused by its line: $OUT"
# whole or not at all: only renames reach the two files
F="$CHECKS/face.sh"
grep -nE '>>? *"?\$F/(sitting|standing)\.json' "$F" && fail 'face.sh writes a face file in place'
grep -q 'mv -f "$F/.sitting.$$" "$F/sitting.json"' "$F" && grep -q 'mv -f "$F/.standing.$$" "$F/standing.json"' "$F" || fail 'face.sh does not rename into the face files'
exit 0
