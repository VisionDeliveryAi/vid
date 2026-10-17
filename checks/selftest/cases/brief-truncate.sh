#!/bin/sh
# Purpose: selftest case — over-long sections are cut, never refused (v0.9.7.1 spec 3.2f, R2). The brief-write
# fixture with bw_builder and bw_return; RED's failing case carries a 400-character name, and ARCHITECTURE gains
# 45 rows any module may call (`all`). Convicts unless a builder brief is written and checked ok, its section 5
# line for that case is 300 characters ending `… (receipt)`, its section 10 holds 40 module rows and ends
# `(+N rows: ARCHITECTURE.md)` with N the rest; and the check refuses a section 5 line over 300 characters that
# lacks the marker. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-truncate: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
i=0; while [ $i -lt 45 ]; do i=$((i + 1)); printf '| m%s | module %s | none | `m%s/x.sh` — x | all |\n' $i $i $i >> ARCHITECTURE.md; done
g add -A && g commit -qm many
bw_return || fail 'the fixture brief was refused'
LONG=$(awk 'BEGIN { for (i = 0; i < 400; i++) printf "x" }')
printf 'case tests/invariants/links.sh::test_row101_%s[ROW-101] failed 0.1\ncase tests/invariants/links.sh::test_row102[ROW-102] passed 0.1\n' "$LONG" > .vid/ledger-results/$RED.cases
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || fail 'a long brief was refused'
B=$(bw_out); grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok'
sec() { awk -v n="$1" '/^## [0-9]/ { on = ($2 == n); next } on' "$B"; }
L=$(sec 5 | grep '^ROW-101 .*xxxxxxxxxx')
[ "$(printf '%s' "$L" | awk '{ print length($0) }')" -eq 300 ] || fail "the long line is not cut to 300: $(printf '%s' "$L" | awk '{ print length($0) }')"
case "$L" in *'… (receipt)') ;; *) fail 'the cut line does not end with the marker' ;; esac
[ "$(sec 10 | grep -c '^| m[0-9]')" -le 40 ] || fail 'section 10 holds more than 40 rows'
[ "$(sec 10 | grep -c '^|')" -eq 42 ] || fail "section 10 is not the header, separator and 40 rows: $(sec 10 | grep -c '^|')"
sec 10 | grep -qxE '\(\+[0-9]+ rows: ARCHITECTURE\.md\)' || fail 'section 10 has no truncation marker'
N=$(sec 10 | sed -n 's/^(+\([0-9]*\) rows: ARCHITECTURE.md)$/\1/p'); [ "$N" -eq 6 ] || fail "the marker counts $N rows, not 6 (app and 45 called modules, 40 kept)"
# a section 5 line over 300 characters without the marker is refused by the check
awk -v long="$LONG" '{ print } /^history: / { print "ROW-102 " long }' "$B" | grep -v '^written: ' > "$T/hand.md"
if sh checks/brief.sh "$T/hand.md" > "$T/wout" 2>&1; then fail 'a long unmarked section 5 line passed the check'; fi
grep -qF "does not end with the marker" "$T/wout" || fail 'the refusal does not name the marker'
exit 0
