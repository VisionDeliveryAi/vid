#!/bin/sh
# Purpose: selftest case — an ask as a team writes it (FB-5 B1.3), on GitHub manual's toy and the fake gh (fixtures/accept.sh): 7 to 40
# characters of a commit, a line end's CR dropped; its one reading lib.sh's, the round and the call's lines holding no copy. A 7 character ask and one ending in a CR are each `decide #<n> <the
# full commit>`, listed by the call, answered once with the full commit, and owed no more. One of 6 characters is no ask. One
# no commit of .vid/code begins with, or more than one, is said to the owner at each call, `undecided #<n> <it> — …`, decided by nothing and answered by nothing; a full one the copy
# lacks is answered `not on main`, as before. `engines:` is read by spaces or commas. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "ask-short: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); ac_project "$T/p" || fail 'the toy could not be made'; c12=$(printf %.12s "$AC_C")
ask() { printf "$1" > "$T/ask"; gh issue comment "$AC_N" -R owner/code --body-file "$T/ask" > /dev/null; }
listed() { sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; grep "^context${TB}ask${TB}" "$T/L" > "$T/out" || true; }
ask "vid: decide $(printf %.6s "$AC_C")\nby: A. Person\n"; ac_round step; ! grep -q '^decide \|^undecided ' "$T/out" || fail 'six characters were read as an ask'
# 7 characters, with a row missing: not yet, once
ac_head "$AC_C" 1 ROW-001=pass; ask "vid: decide $(printf %.7s "$AC_C")\nby: A. Person\n"
ac_round step; [ "$RC" = 0 ] && [ "$(grep -c "^decide #$AC_N $AC_C\$" "$T/out")" = 1 ] || fail 'an ask of 7 characters is not a decision owed at the full commit'
listed; grep -qx "context${TB}ask${TB}#$AC_N${TB}$(printf %.7s "$AC_C")${TB}/vid:vid-accept-step $AC_N $(printf %.7s "$AC_C")" "$T/L" || fail 'the call does not list it'
ac_round accept "$AC_N" "$(printf %.7s "$AC_C")"; [ "$RC" = 0 ] && grep -q "^decided #$AC_N $c12 ticket: not yet" "$T/out" || fail 'it was not decided at the commit it names'
[ "$(ac_last | head -n 1)" = "vid: decision $AC_C" ] || fail 'its answer does not name the full commit'; c=$(ac_comments)
ac_round step; ! grep -q '^decide ' "$T/out" || fail 'the answered ask is still owed'; listed; [ ! -s "$T/out" ] || fail 'the answered ask is still listed'
# a CR at the line's end, as the read's @tsv gives it (two characters) and raw
for e in '\\r' '\r'; do ask "vid: decide $AC_C$e\nby: A. Person\n"; ac_round step; grep -q "^decide #$AC_N $AC_C\$" "$T/out" || fail "an ask ending in a CR ($e) is not a decision owed"
  ac_round accept "$AC_N" "$AC_C"; [ "$(ac_comments)" = $((c + 2)) ] || fail "an ask ending in a CR ($e) was not answered once"; c=$(ac_comments)
  ac_round step; ! grep -q '^decide ' "$T/out" || fail "an answered ask ending in a CR ($e) is still owed"; done
# no commit begins with it: said at each call, nothing posted; a full one the copy lacks is answered as before
ask 'vid: decide 0123456789\nby: A. Person\n'; c=$(ac_comments)
for k in 1 2; do ac_round step; [ "$(grep -c "^undecided #$AC_N 0123456789 — " "$T/out")" = 1 ] && ! grep -q '^decide ' "$T/out" || fail "step $k does not say the ask no commit begins with"; done
ac_round accept "$AC_N" 0123456789; grep -q "^undecided #$AC_N 0123456789 — " "$T/out" && [ "$(ac_comments)" = "$c" ] || fail 'the owner'"'"'s command at it did not say so, or posted'
# two commits of the copy begin with it: the same
X=0a1b2c3; mkdir -p "$T/gb"; rg=$(command -v git); printf '#!/bin/sh\nfor a in "$@"; do [ "$a" != --disambiguate=%s ] || { printf "%%s\\n" %s %s; exit 0; }; done\nexec %s "$@"\n' "$X" "$AC_C" "$AC_RED" "$rg" > "$T/gb/git"; chmod +x "$T/gb/git"
ask "vid: decide $X\nby: A. Person\n"; P0=$PATH; PATH=$T/gb:$PATH; ac_round step; PATH=$P0; grep -q "^undecided #$AC_N $X — " "$T/out" && ! grep -q '^decide ' "$T/out" || fail 'an ask two commits begin with was decided, or not said'
Z=0123456789abcdef0123456789abcdef01234567; ask "vid: decide $Z\nby: A. Person\n"; ac_round accept "$AC_N" "$Z"; ac_last | grep -qx "not on main — $Z" || { ac_last > "$T/out"; fail 'a full commit the copy lacks is not answered not on main'; }
# engines by commas, and by spaces
for e in 'alpha, beta' 'alpha,beta' 'alpha beta'; do rr_put any-1 results.txt "$(printf 'by: A. Person\ncommit: %s\nengines: %s' "$AC_RED" "$e")"; rr_put any-1 c.xml "$(rr_cases ROW-001=pass)"; ac_send any-1; sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || fail 'results-fetch failed'
  sh "$CHECKS/results.sh" declare --ticket "$AC_N" --at "$AC_RED" > "$T/out" 2>&1; grep -q '^engines alpha beta | stand-in: ' .vid/tw/handed || { cp .vid/tw/handed "$T/out"; fail "engines: $e was not read as two engines"; }; done
# one copy
[ "$(grep -c '^tasks_()' "$CHECKS/lib.sh")" = 1 ] && ! grep -q '^tasks_()' "$CHECKS/round.sh" "$CHECKS/next.sh" || fail 'the ask is read in more than one place'
echo 'ask-short: ok'
