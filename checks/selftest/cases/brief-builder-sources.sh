#!/bin/sh
# Purpose: selftest case — the check of a builder brief's sections 9–11 against their sources
# (v0.9.7.0.7 spec 3.2; §6 B-5). The brief-write fixture with bw_builder. The stamp is removed first,
# so the stamp is not what refuses. Convicts unless checks/brief.sh passes the unstamped brief as
# written (the control); refuses it, naming the section, with: a section 10 step line changed; a
# section 10 module row changed; a section 11 rule row changed; a section 9 location changed; and
# passes it with section 12 changed (the run manager's words are not checked). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-builder-sources: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
printf 'Mind the token field.\n' > "$T/notes.txt"
bw_write --role builder --slice 2 --step S2 --rows ROW-104,ROW-120,ROW-105 --notes "$T/notes.txt" || { cat "$T/wout" >&2; fail 'the writer refused the builder brief'; }
B=$(bw_out); grep -v '^written: brief\.sh write ' "$B" > "$T/plain.md"
sh checks/brief.sh "$T/plain.md" > "$T/out" 2>&1 || fail 'the unstamped brief as written was refused'
refused() { # $1=sed expression $2=the section named
  sed "$1" "$T/plain.md" > "$T/m.md"; cmp -s "$T/m.md" "$T/plain.md" && fail "the edit changed nothing: $1"
  if sh checks/brief.sh "$T/m.md" > "$T/out" 2>&1; then fail "a changed $2 line was accepted: $1"; fi
  grep -qF "$2:" "$T/out" || fail "the refusal does not name $2: $1"; }
refused 's/^step S2 | name: deletion/step S2 | name: removal/' 'section 10'
refused 's/^| tests\.invariants | the ledger/| tests.invariants | the tests/' 'section 10'
refused 's/^\(rule | RULE-001 | a deletion never succeeds\) without the token/\1 without a token/' 'section 11'
refused 's/^\(ROW-104 tests\/invariants\/links\.sh:\)[0-9,]*/\199/' 'section 9'
sed 's/Mind the token field\./Mind the marker./' "$T/plain.md" > "$T/m.md"
sh checks/brief.sh "$T/m.md" > "$T/out" 2>&1 || fail 'a changed section 12 (the notes) was refused'
exit 0
