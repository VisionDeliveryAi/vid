#!/bin/sh
# Purpose: selftest case — writer.sh name takes a decision id only in DECISIONS.md's own form, D- and digits (0.26.10.29.5,
# DP-1 R5). On TW's toy with D-001, naming 'D-\06001' (an escape awk would read as D-001) for S02 is refused as an unknown
# id and writes nothing to .vid/tw/named; naming D-001 still passes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "dp-r5-id-form: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; W=$CHECKS/writer.sh
grep -q '^- \*\*D-001\*\*' DECISIONS.md || fail 'the toy has no D-001'
if sh "$W" name S02 'D-\06001' > "$T/out" 2>&1; then fail "D-\\06001, no id of DECISIONS.md's form, was named: $(cat .vid/tw/named 2>/dev/null)"; fi
grep -q 'unknown decision id' "$T/out" || fail 'the refusal does not say the id is unknown'
[ ! -s .vid/tw/named ] || fail "a refused name wrote .vid/tw/named: $(cat .vid/tw/named)"
sh "$W" name S02 D-001 > "$T/out" 2>&1 || fail 'D-001 was refused'
echo 'dp-r5-id-form: ok'
