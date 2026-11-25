#!/bin/sh
# Purpose: selftest case — checks/prd.sh --arms-accepted (FB-4 C1): one line, `F-NN <id> arm <n> <word> A-NNN`, a tab and the amending row as it stands, for each
# arm an AMENDED row marks retained or strengthened, not word for word the same, that a findings row of pass `review`
# on that one item, evidence opening `arm <n>`, records `accepted A-NNN` in the amending row's own section, the answer
# effective, human and not delegated. Silent and 0 with none, with a word-for-word arm, with the finding in another
# section, with another pass, with no file. --arms itself is unchanged by it. Env: CHECKS.
set -eu
fail() { echo "prd-arms-accepted: $*" >&2; cat out.txt err.txt >&2 2>/dev/null; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
G="$CHECKS/selftest/fixtures/prd-094-good.md"
R1=$(grep '^REQ-001 ' "$G" | sed 's/^REQ-001 /REQ-001 AMENDED /')
NARROW=$(printf '%s\n' "$R1" | sed 's/already delivered for that search/already delivered for that search in the same week/')
# mk <item row> <arms> <findings row> [<answer tail>]: P.md, the good PRD and one append
mk() { { cat "$G"; printf '\n### 2026-09-02 (owner answer)\n\n```vid-prd-answers\n%s\n```\n\n```vid-prd\n%s | arms: %s\n```\n\nreview: delta, round 1, 1 findings\n\n```vid-prd-findings\n%s\n```\n' \
  "A-100 | human | 2026-09-02 | Q: may a job repeat after a week? | A: yes, a later week may repeat it | settles: REQ-001${4:-}" "$1" "$2" "$3"; } > P.md; }
F='F-06 | review | blocking | REQ-001 | accepted A-100 | evidence: arm 1 — a repeat in a later week passes now'
run() { sh "$CHECKS/prd.sh" --arms-accepted "${1:-P.md}" > out.txt 2> err.txt || fail "the mode exited non-zero (${2:-})"; }
says() { run P.md "$1"; printf '%s\t%s\n' "$2" "$NARROW | arms: 1 ${1}, 2 retained" | cmp -s - out.txt || fail "$1: not the line '$2'"; }
silent() { run "${2:-P.md}" "$1"; [ ! -s out.txt ] || fail "$1: the mode printed something"; }
mk "$NARROW" '1 strengthened, 2 retained' "$F"
sh "$CHECKS/prd.sh" P.md > court.txt 2>&1 || { cat court.txt >&2; fail 'the fixture is not a lawful PRD'; }
says 'strengthened' 'F-06 REQ-001 arm 1 strengthened A-100'
sh "$CHECKS/prd.sh" --arms P.md > out.txt 2> err.txt || fail '--arms exited non-zero'
! grep -q '^REQ-001 ' out.txt || fail '--arms lists an entry the ruling closed'
mk "$NARROW" '1 retained, 2 retained' "$F"; says 'retained' 'F-06 REQ-001 arm 1 retained A-100'
mk "$NARROW" '1 withdrawn A-100, 2 retained' "$F"; silent 'withdrawn'
mk "$R1" '1 retained, 2 retained' "$F"; silent 'word for word'
mk "$NARROW" '1 retained, 2 retained' "$(printf '%s\n' "$F" | sed 's/arm 1/arm 2/')"; silent 'the finding on another arm, which stands word for word'
mk "$NARROW" '1 retained, 2 retained' "$(printf '%s\n' "$F" | sed 's/| review |/| audit |/')"; silent 'another pass'
mk "$NARROW" '1 retained, 2 retained' "$(printf '%s\n' "$F" | sed 's/accepted A-100/overruled A-100/')"; silent 'overruled'
mk "$NARROW" '1 retained, 2 retained' "$F" ' | delegated: yes'; silent 'a delegated answer'
# the finding in another section than the amending row's
mk "$NARROW" '1 retained, 2 retained' "$F"
awk '/^```vid-prd-findings$/ { k++; if (k == 3) print "### 2026-09-03 (another section)\n" } { print }' P.md > Q.md
grep -q '^### 2026-09-03' Q.md || fail 'the fixture did not split the section'
silent 'the finding in another section' Q.md
silent 'no amendment' "$G"; silent 'no file' none.md
echo 'prd-arms-accepted: ok'
