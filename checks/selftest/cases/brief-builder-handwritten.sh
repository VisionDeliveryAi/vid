#!/bin/sh
# Purpose: selftest case — a hand-written builder brief still passes (v0.9.7.0.7 spec 3.2; §6 B-6).
# The brief-write fixture with bw_builder. A run already under way has builder briefs written by
# hand: no stamp, no `skill:` line, sections 1–8 with section 4's laws and no 9–12. Convicts unless
# checks/brief.sh says ok on one; and, its polarity, refuses the same brief with a row paraphrased.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-builder-handwritten: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
Q=$(git rev-parse HEAD)
{ printf 'role: builder    slice: 2    step: S2\nquoted-at: %s\nreceives: 1–8    must not receive: another batch'"'"'s brief or verdicts\n\n' "$Q"
  printf '## 1 rows\n\n%s\n\n' "$(grep '^ROW-104 ' INVENTORY.md)"
  printf '## 3 decisions\n\n%s\n\n' "$(grep '^- \*\*D-006\*\*' DECISIONS.md)"
  printf '## 4 laws\n\n- Every import crosses a seam the table declares.\n\n'
  printf '## 5 start and receipt\n\nstart: %s    receipt: none named\n\n## 8 further reading (optional)\n\nPRD.md\n' "$Q"; } > "$T/hand.md"
sh checks/brief.sh "$T/hand.md" > "$T/out" 2>&1 || fail 'a hand-written builder brief was refused'
sed 's/a wrong deletion token is refused/a bad deletion token is refused/' "$T/hand.md" > "$T/bad.md"
if sh checks/brief.sh "$T/bad.md" > "$T/out" 2>&1; then fail 'a paraphrased row in a hand-written builder brief was accepted'; fi
exit 0
