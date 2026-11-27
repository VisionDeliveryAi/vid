#!/bin/sh
# Purpose: selftest case — the call reads a quoted field the writer wrote as unchanged (FIX-BATCH-T2 §10, OW-3).
# The writer writes a quoted line pointers first (unptr), then lib.sh's words blanked (profx); next.sh's same() must take that
# form, or an unchanged row whose field holds a word of the list inside a path reads as restated. Runs the shipped awk: lib.sh's
# PROF, writer.sh's PTRF and next.sh's norm and same. Convicts unless each field, written so, is the same as the inventory's, and
# a changed field is not. Made-up words only. Env: CHECKS.
set -eu
fail() { echo "next-same-blanked: $*" >&2; exit 1; }
for f in lib.sh writer.sh next.sh; do [ -f "$CHECKS/$f" ] || fail "no checks/$f"; done
PROF=$(sed -n '/^PROF=/,/^# BLKL/p' "$CHECKS/lib.sh" | sed '$d'); eval "$PROF"
PT=$(sed -n '/^PTRF=/,/^A1=/p' "$CHECKS/writer.sh" | sed '$d'); eval "$PT"
CMP=$(sed -n '/^    function norm(s)/p; /^    function same(q, v)/p' "$CHECKS/next.sh")
[ -n "$PROF" ] && [ -n "$PTRF" ] && [ "$(printf '%s\n' "$CMP" | grep -c 'function')" = 2 ] || fail 'the shipped functions could not be read'
r=$(printf '%s\n' 'damn .vid/damn.txt' 'a damn bad case' 'see .vid/plan/review' 'plain words' | awk "$PTRF$PROF$CMP"'function tr(s) { return s }
  { q = profx(unptr($0)); printf "%s", same(q, $0) } END { print "" }')
[ "$r" = 1111 ] || fail "a field written as the writer writes it reads as changed: $r (each of four, 1 the same)"
c=$(printf '%s\n' 'damn .vid/damn.txt' | awk "$PTRF$PROF$CMP"'function tr(s) { return s } { print same(profx(unptr("other .vid/damn.txt")), $0) }')
[ "$c" = 0 ] || fail 'a changed field reads as the same'
exit 0
