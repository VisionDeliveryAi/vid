#!/bin/sh
# Purpose: selftest case — writer.sh name knows a decision by its own leading id alone (0.26.10.29.5, DP-1 R5). On TW's toy with
# D-005, whose text quotes the marker - **D-999** of imported text, naming D-999 for S02 is refused as an unknown id and writes
# nothing to .vid/tw/named; naming D-005 still passes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "dp-r5-id-inside: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh
printf -- '- **D-005** keep the literal marker - **D-999** in imported text | why: the import reads it | enforced: convention | scope: project\n' >> DECISIONS.md
g commit -qam 'a decision quoting another id'
if sh "$W" name S02 D-999 > "$T/out" 2>&1; then fail 'D-999, only inside the text of D-005, was named'; fi
grep -q 'unknown decision id: D-999' "$T/out" || fail 'the refusal does not name D-999 as unknown'
[ ! -s .vid/tw/named ] || fail "a refused name wrote .vid/tw/named: $(cat .vid/tw/named)"
sh "$W" name S02 D-005 > "$T/out" 2>&1 || fail 'D-005, a decision of its own, was refused'
echo 'dp-r5-id-inside: ok'
