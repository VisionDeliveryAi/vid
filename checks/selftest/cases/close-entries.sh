#!/bin/sh
# Purpose: selftest case — checks/close.sh's entries and its parts (FB-2 C3). In an empty repository with .vid/, an entry close.sh does not
# know exits 2 with its `usage:` line; each entry that needs an argument, given none, exits 1 with its own `ViD close: usage — <entry>`
# line; the entries that need none never print the fallthrough line. close.sh sources exactly the six `close-*.sh` beside it, each one
# exists and says `# serves: tickets` once, no part holds the dispatch, close.sh is at most 180 lines and each part at most 210, and no
# function is defined in two of the seven files. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "close-entries: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
CS=$CHECKS/close.sh; FB='usage: sh checks/close.sh'
mkdir -p "$T/bin" "$T/gh"; cp "$CHECKS/selftest/fixtures/fake-gh" "$T/bin/gh"; chmod +x "$T/bin/gh"; PATH="$T/bin:$PATH"; FAKEGH=$T/gh; export PATH FAKEGH
mkdir -p "$T/repo"; cd "$T/repo"; git init -q; mkdir -p .vid
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 < /dev/null || RC=$?; }
# the dispatch: an unknown entry, the entries that need an argument, the entries that need none
cs nosuch; [ "$RC" = 2 ] || fail "an unknown entry exited $RC, not 2"; grep -qF "$FB" "$T/out" || fail 'an unknown entry printed no usage: line'
for e in ask okay close-stage summary stage walk read-walk step decide deploy; do cs "$e"; [ "$RC" = 1 ] || fail "$e with no argument exited $RC, not 1"
  grep -q "^ViD close: usage — $e" "$T/out" || fail "$e with no argument printed no line of its own"; ! grep -qF "$FB" "$T/out" || fail "$e fell through to the usage: line"; done
for e in owed out owned why endconds nextplan step-stages 'conds 1' 'corrected 1'; do cs $e; ! grep -qF "$FB" "$T/out" || fail "$e fell through to the usage: line"; done
# the parts: exactly six, sourced from beside close.sh, each with its serves line; the dispatch in close.sh alone
P='step decide candidate staging end production'; : > "$T/out"
[ "$(ls "$CHECKS"/close-*.sh 2>/dev/null | wc -l | tr -d ' ')" = 6 ] || fail "checks/ holds $(ls "$CHECKS"/close-*.sh 2>/dev/null | wc -l | tr -d ' ') close-*.sh parts, not 6"
[ "$(grep -c '^\. "\$HERE/close-[a-z]*\.sh"' "$CS")" = 6 ] || fail 'close.sh does not source exactly six parts'
for p in $P; do F=$CHECKS/close-$p.sh; [ -f "$F" ] || fail "close-$p.sh does not exist"; grep -q "^\\. \"\\\$HERE/close-$p\\.sh\"" "$CS" || fail "close.sh does not source close-$p.sh"
  [ "$(grep -c '^# serves: tickets' "$F")" = 1 ] || fail "close-$p.sh does not say # serves: tickets once"; ! grep -q 'case \$CMD' "$F" || fail "close-$p.sh holds the dispatch"; done
# the sizes (FB-2 C3, after A4): close.sh at most 180 lines, each part at most 210
n=$(wc -l < "$CS" | tr -d ' '); [ "$n" -le 180 ] || fail "close.sh is $n lines, over 180"
for f in "$CHECKS"/close-*.sh; do n=$(wc -l < "$f" | tr -d ' '); [ "$n" -le 210 ] || fail "$(basename "$f") is $n lines, over 210"; done
# no function defined in two of the seven files
for f in "$CS" "$CHECKS"/close-*.sh; do grep -oE '(^|[;&|{( ])[A-Za-z_][A-Za-z0-9_]*\(\) *\{' "$f" | sed -E 's/^[;&|{( ]//; s/\(\).*//' | sort -u | sed "s#\$# $(basename "$f")#"; done > "$T/defs"
awk '{ n[$1]++; w[$1] = w[$1] " " $2 } END { for (f in n) if (n[f] > 1) print f ":" w[f] }' "$T/defs" > "$T/out"
[ ! -s "$T/out" ] || fail "a function is defined in two of the seven files: $(tr '\n' ';' < "$T/out")"
exit 0
