#!/bin/sh
# Purpose: selftest case — usability 3 (0.26.10.29.6, S7): ViD's own words and ids in a sitting are flagged to the
# session, never refused. A sitting's lines hold one item whose words carry an id (REQ-004), one whose detail
# carries a listed word (ledger), an item whose id alone is an id with plain words, and plain lines. Convicts unless
# the sitting is written whole and the script prints exactly one notice line, naming the two lines that hold an id or
# a listed word and no other; unless a word that only contains a listed one (harm, framework) is not named; and
# unless a plain sitting prints no notice; and unless a judged scorecard line holding a listed word is named too.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-plain-notice: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
cat > C <<'L'
section changes
item C1 | Two rules on digests are one now: REQ-004 holds both
recommend | Fine
item REQ-005 | The sign-up rule reads more plainly
detail | Nothing it tests has changed.
item C3 | The unsubscribe rule is shorter
detail | Its ledger row stays as it was.
item C4 | The framework of the digest does no harm
empty alone | none
L
fc_run write consolidation C; [ "$RC" = 0 ] || fail "a sitting with ViD's words was refused: $OUT"
[ "$(fc_json "len(d['sections'][0]['items'])")" = 4 ] || fail 'the sitting was not written whole'
n=$(printf '%s\n' "$OUT" | grep -c 'plain words' || true)
[ "$n" = 1 ] || fail "$n notice lines, not one: $OUT"
l=$(printf '%s\n' "$OUT" | grep 'plain words')
for k in 2 7; do printf '%s\n' "$l" | grep -qE "line $k([^0-9]|$)" || fail "the notice does not name line $k: $l"; done
for k in 1 3 4 5 6 8 9; do printf '%s\n' "$l" | grep -qE "line $k([^0-9]|$)" && fail "the notice names line $k, which holds no id and no listed word: $l"; done
printf 'section changes\nitem C1 | Two rules on digests are one now\nempty alone | none\n' > P
fc_run write consolidation P; [ "$RC" = 0 ] || fail "a plain sitting was refused: $OUT"
printf '%s\n' "$OUT" | grep -q 'plain words' && fail "a plain sitting printed a notice: $OUT"
# every line whose words the person sees is read: a judged scorecard line too
sed 's/^judged product-level | .*/judged product-level | 9, the ledger agrees/' lines.pause-2 > J
n=$(grep -n '^judged ' J | cut -d: -f1)
rm -f .vid/face/sitting.json   # the stop-8 sitting on disk would pass stop 4
fc_run write pause-2 J; [ "$RC" = 0 ] || fail "pause-2 refused: $OUT"
printf '%s\n' "$OUT" | grep 'plain words' | grep -qE "line $n([^0-9]|$)" || fail "a judged line holding a listed word is not named (line $n): $OUT"
exit 0
