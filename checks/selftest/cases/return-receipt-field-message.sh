#!/bin/sh
# Purpose: selftest case — one receipt per pass line, named (v0.9.8.1 R33, F-23). The brief-write fixture: a hand-back
# whose pass line carries a receipt and a note in the receipt field is refused, and the refusal says the field holds
# one receipt file name and notes go in the report; the same line with the receipt alone passes. In the plugin
# repository, vid-build says which receipt a pass names when a request publishes an inline and a deployed one.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "return-receipt-field-message: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
B=$(bw_out)
printf 'brief: %s\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s (deployed pass too, see notes)\nROW-102 | not | none | not built\n' "$B" "$(git rev-parse HEAD)" "$GREEN" > "${B%.md}.return.md"
if sh checks/brief.sh return "${B%.md}.return.md" > "$T/out" 2>&1; then fail 'a receipt field holding a note was taken'; fi
grep -q 'the receipt field holds one receipt file name; notes go in the report' "$T/out" || fail 'the refusal does not say what the field holds'
printf 'brief: %s\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$B" "$(git rev-parse HEAD)" "$GREEN" > "${B%.md}.return.md"
sh checks/brief.sh return "${B%.md}.return.md" > "$T/out" 2>&1 || fail 'the receipt alone was refused'
SK="$CHECKS/../skills/vid-build/SKILL.md"
if [ -f "$SK" ]; then
  F=$(tr '\n' ' ' < "$SK" | tr -s ' ')
  case "$F" in *'When one request publishes an inline and a deployed receipt, name the one that credits the row'*) ;; *) fail 'vid-build does not say which receipt a pass names' ;; esac
  case "$F" in *'The field holds one receipt file name; notes go in the report.'*) ;; *) fail 'vid-build does not say the field holds one file name' ;; esac
fi
exit 0
