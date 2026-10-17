#!/bin/sh
# Purpose: selftest case — an incomplete hand-back is refused, naming the line (v0.9.7.0.7 spec 3.3,
# R7; §6 C-2). The brief-write fixture with bw_builder and bw_return. Convicts unless `sh
# checks/brief.sh return` refuses, recording no build-cost: a block without `agent:` (and one
# without `commit:`); a block missing ROW-102; one with ROW-101 twice; one with ROW-104, a row not
# in the brief; and one naming a brief that does not exist. A not line without a reason is refused
# too. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-return-refused: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
H=$(git rev-parse HEAD); RF=.vid/briefs/1/builder-1.return.md
OK1="ROW-101 | pass | $GREEN"; OK2='ROW-102 | not | none | not built in this step'
refused() { # $1=what $2=expected text, the block on stdin
  cat > "$RF"
  if sh checks/brief.sh return "$RF" > "$T/out" 2>&1; then fail "accepted: $1"; fi
  grep -qF -- "$2" "$T/out" || fail "the refusal for $1 does not say: $2"; }
printf 'brief: .vid/briefs/1/builder-1.md\nbranch: b\ncommit: %s\n%s\n%s\n' "$H" "$OK1" "$OK2" | refused 'no agent: header' "no 'agent:' line"
printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: b\n%s\n%s\n' "$OK1" "$OK2" | refused 'no commit: header' "no 'commit:' line"
printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: b\ncommit: %s\n%s\n' "$H" "$OK1" | refused 'a missing row' 'ROW-102 of the brief is missing'
printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: b\ncommit: %s\n%s\n%s\n%s\n' "$H" "$OK1" "$OK1" "$OK2" | refused 'a doubled row' 'line 6: ROW-101 appears twice'
printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: b\ncommit: %s\n%s\n%s\nROW-104 | not | none | another step\n' "$H" "$OK1" "$OK2" | refused 'a foreign row' 'line 7: ROW-104 is not a row of the brief'
printf 'brief: .vid/briefs/1/builder-9.md\nagent: a1\nbranch: b\ncommit: %s\n%s\n%s\n' "$H" "$OK1" "$OK2" | refused 'a brief that does not exist' 'does not exist'
printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: b\ncommit: %s\n%s\nROW-102 | not | none\n' "$H" "$OK1" | refused 'a not line with no reason' 'gives no reason'
grep -q '^build-cost ' .vid/metrics-events && fail 'a refused hand-back recorded build-cost'
exit 0
