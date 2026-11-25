#!/bin/sh
# Purpose: selftest case — search, then ask; quote the line, or it is open (FB-5 C3). The rule stands in vid-connect, which every
# ticket-mode call names, once, in both directions: the answers, the decisions and the spec searched before a question to the owner, a
# line that settles it done and told, never asked; the line's id and words quoted before "the spec settles it", and open with no line.
# No other skill holds it. Skips where the skills are not (a project's own checks/). Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -f "$S/vid-connect/SKILL.md" ] || exit 77
fail() { echo "search-then-ask: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
A='before a question to the owner, search the answers, the decisions and the spec'; B='quote the line'"'"'s id and words'
n() { flat "$1" | awk -v s="$2" '{ c = 0; l = tolower($0); while ((i = index(l, s))) { c++; l = substr(l, i + length(s)) } print c }'; }
C=$S/vid-connect/SKILL.md
[ "$(n "$C" "$A")" = 1 ] || fail 'vid-connect does not say once to search before a question to the owner'
flat "$C" | grep -qF 'is done and told in one line, never asked' || fail 'vid-connect does not say what a line that settles it is for'
[ "$(n "$C" "$B")" = 1 ] || fail "vid-connect does not say once to quote the line's id and words"
flat "$C" | grep -qF "with no line, it is open, and the owner's" || fail 'vid-connect does not say what no line means'
for f in "$S"/*/SKILL.md; do [ "$f" != "$C" ] || continue; [ "$(n "$f" "$A")" = 0 ] && [ "$(n "$f" "$B")" = 0 ] || fail "${f#"$S"/} holds the rule too"; done
echo 'search-then-ask: ok'
