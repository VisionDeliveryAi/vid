#!/bin/sh
# Purpose: selftest case — the arms count gap names the arms (FB-4 C2). Join 14 on an AMENDED row whose arms: holds one
# entry for a predecessor with two arms says the count and lists the predecessor's arms, numbered, as the court splits
# them, so the next attempt counts as the court does; a `*` in an arm's words stays as written. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-arms-count-names-arms: $*" >&2; cat out.txt >&2 2>/dev/null; exit 1; }
G="$CHECKS/selftest/fixtures/prd-094-good.md"
: > aXb
R=$(grep '^REQ-012 ' "$G" | sed 's/^REQ-012 /REQ-012 AMENDED /')
mk() { { cat "$G"; printf '\n### 2026-09-02 (owner answer)\n\n```vid-prd\n%s\n%s | arms: 1 retained\n```\n' "$(printf '%s\n' "$R" | sed 's/mail to it bounces/*/; s/$/ | arms: 1 retained, 2 strengthened/')" "$R"; } > P.md; }
{ cat "$G"; printf '\n### 2026-09-02 (owner answer)\n\n```vid-prd\n%s | arms: 1 retained\n```\n' "$R"; } > P.md
if sh "$CHECKS/prd.sh" P.md > out.txt 2>&1; then fail 'one entry for two arms acquitted'; fi
grep -qF 'join 14 (REQ-012 AMENDED): arms: carries 1 entr(y/ies) for a predecessor with 2 arm(s)' out.txt || fail 'the count gap is not said'
grep -F 'join 14 (REQ-012 AMENDED): arms: carries 1' out.txt | grep -qF ' 1 "the footer lacks a support address" 2 "mail to it bounces"' || fail 'the count gap does not list the predecessor'"'"'s arms, numbered'
mk; if sh "$CHECKS/prd.sh" P.md > out.txt 2>&1; then fail 'one entry for two arms acquitted (the second revision)'; fi
grep -F 'join 14 (REQ-012 AMENDED): arms: carries 1' out.txt | grep -qF ' 2 "*"' || fail 'an arm written `*` is not printed as written'
exit 0
