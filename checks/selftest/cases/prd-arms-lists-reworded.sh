#!/bin/sh
# Purpose: selftest case — `checks/prd.sh --arms` lists a kept arm reworded (0.26.10.29.4, phase 3 R4). From the
# known-good PRD fixture without its one amendment: on that file, with no amendment, and on a missing file, --arms is
# silent and exits 0. An append rewording both arms of REQ-012, one marked `retained` and one `strengthened`, lists
# each, in the line form `<id> arm <n> <disposition> | was: <old arm> | now: <the whole new fail-if>`; an amendment of
# REQ-001 that keeps both arms word for word lists nothing; and the known-good fixture itself lists its REQ-002 arm 1,
# strengthened in other words. The listing judges nothing: the court still acquits the file. Env: CHECKS.
set -eu
fail() { echo "prd-arms-lists-reworded: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
F="$CHECKS/selftest/fixtures/prd-known-good.md"
grep -v '^REQ-002 AMENDED ' "$F" > BASE.md
arms() { sh "$CHECKS/prd.sh" --arms "$1" > out.txt 2> err.txt || { cat err.txt >&2; fail "--arms exited non-zero on $1"; }; }
arms BASE.md
[ ! -s out.txt ] || { cat out.txt >&2; fail 'a file with no amendment is not silent'; }
[ ! -s err.txt ] || { cat err.txt >&2; fail 'a file with no amendment printed to stderr'; }
arms nothere.md
[ ! -s out.txt ] || fail 'a missing file is not silent'
r12() { printf 'REQ-012 AMENDED | functional | T2 | P2 | Every digest footer carries a support contact address that reaches a person. | fail-if: %s | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | arms: %s\n' "$1" "$2"; }
NEW='the footer lacks a visible support address, or mail to it bounces twice'
{ cat BASE.md; printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd\n'
  r12 "$NEW" '1 retained, 2 strengthened'
  printf '%s\n' 'REQ-001 AMENDED | functional | T1 | P0 | A subscriber receives one digest per saved search per day, containing only new matches since the last digest, in the morning. | fail-if: a digest repeats a job already delivered for that search, or two digests for one search arrive in one day | serves: trust in the alert channel — the reason a user hands over an email address | authority: authoritative | source: seed, A-001 | covers: DIM-notifications | derives: trigger-row | arms: 1 retained, 2 retained'
  printf '```\n'; } > A.md
sh "$CHECKS/prd.sh" A.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the fixture with the two amendments is not a lawful PRD'; }
arms A.md
cat > want.txt <<W
REQ-012 arm 1 retained | was: the footer lacks a support address | now: $NEW
REQ-012 arm 2 strengthened | was: mail to it bounces | now: $NEW
W
cmp -s want.txt out.txt || { echo '--- wanted' >&2; cat want.txt >&2; echo '--- got' >&2; cat out.txt >&2; fail 'the reworded retained and strengthened arms are not listed exactly as above (and nothing else)'; }
arms "$F"
grep -qxF 'REQ-002 arm 1 strengthened | was: a digest arrives after its address unsubscribed | now: a digest arrives more than one day after its address unsubscribed, or the unsubscribe link requires a sign-in' out.txt \
  || { cat out.txt >&2; fail "the known-good fixture's REQ-002 arm 1, strengthened in other words, is not listed"; }
[ "$(grep -c . out.txt)" = 1 ] || { cat out.txt >&2; fail "the known-good fixture lists more than its REQ-002 arm 1 (its arm 2 is kept word for word)"; }
echo 'prd-arms-lists-reworded: ok'
