#!/bin/sh
# Purpose: selftest case — checks/prd-consolidate.sh under grammar 0.9.4
# (v0.9.4 spec §3.9, §7 case 12). From the 0.9.4 known-good fixture with an
# append carrying a new feature (FEAT-04, goal -), a renamed one (FEAT-02
# AMENDED) and an amended item (REQ-011 AMENDED, a new feature: and arms:):
# the output keeps `grammar: 0.9.4`, carries exactly ONE features fence,
# before the items block, holding the four effective rows (the rename
# folded, AMENDED stripped), the labels riding their rows (feature:,
# importance:, shown:); it acquits by default and under --pause (the
# shown: sums survive — consolidation drops Q:, never A:); the appended
# features block is archived verbatim in PRD-HISTORY; a second run is
# byte-identical; a 0.9.1 input writes `grammar: 0.9.1` and no features
# fence. Env: CHECKS.
set -eu
SCRIPT="$CHECKS/prd-consolidate.sh"; COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-consolidate: $*" >&2; exit 1; }
mkdir a && cp "$FIXTURES/prd-094-good.md" a/PRD.md
cat >> a/PRD.md <<'APP'

### 2026-09-03 (/vid add)

```vid-prd-features
FEAT-04 | - | referral rewards
FEAT-02 AMENDED | G2 | synonym-aware search and ranking
```

```vid-prd
REQ-011 AMENDED | nfr | T2 | Digest delivery failures surface in an operator-visible log with a daily failure count and the failing addresses. | fail-if: a day of failed sends leaves no operator-visible trace, or the trace omits which addresses failed | serves: operators learn the product is broken before subscribers do | authority: authoritative | source: thesis | covers: DIM-nfr-operability/observability | phase: pilot | feature: FEAT-04 | arms: 1 strengthened
```
APP
sh "$COURT" a/PRD.md >/dev/null 2>&1 || { sh "$COURT" a/PRD.md --report 2>&1 | grep '^GAP' | head -3 >&2; fail 'the seeded input is not court-green'; }
sh "$SCRIPT" a/PRD.md --date 2026-09-25 >a/run1.txt 2>&1 || { cat a/run1.txt >&2; fail 'the first consolidation refused'; }
sed -n '2p' a/PRD.md | grep -qx 'grammar: 0.9.4' || fail "the output's grammar is $(sed -n '2p' a/PRD.md)"
[ "$(grep -c '^```vid-prd-features$' a/PRD.md)" -eq 1 ] || fail "$(grep -c '^```vid-prd-features$' a/PRD.md) features fences, expected exactly one"
F=$(sed -n '/^```vid-prd-features$/,/^```$/p' a/PRD.md | sed '1d;$d')
[ "$F" = "FEAT-01 | G1 | the daily digest
FEAT-02 | G2 | synonym-aware search and ranking
FEAT-03 | G1 | subscriber care and exit
FEAT-04 | - | referral rewards" ] || { printf '%s\n' "$F" >&2; fail 'the folded features block is not the four effective rows'; }
awk '/^```vid-prd-features$/ { f = NR } /^```vid-prd$/ { i = NR } END { exit !(f && i && f < i) }' a/PRD.md || fail 'the features block does not precede the items block'
grep -q '^REQ-011 | nfr | T2 | .*| feature: FEAT-04 | arms: 1 strengthened$' a/PRD.md || fail 'the amended row did not keep its labels'
grep -q '^A-005 | model_proposed | .* | shown: pause-1 2042538$' a/PRD.md || fail 'the shown: label did not ride its row'
grep -q '^A-006 | human | .* | importance: priority$' a/PRD.md || fail 'the importance: label did not ride its row'
grep -q '| Q:' a/PRD.md && fail 'a Q: text survived in the live file'
sh "$COURT" a/PRD.md >/dev/null 2>&1 || { sh "$COURT" a/PRD.md --report 2>&1 | grep '^GAP' | head -3 >&2; fail 'the output does not acquit'; }
sh "$COURT" a/PRD.md --pause >/dev/null 2>&1 || { sh "$COURT" a/PRD.md --report --pause 2>&1 | grep '^GAP' | head -3 >&2; fail 'the output does not acquit under --pause'; }
grep -q '^FEAT-02 AMENDED | G2 | synonym-aware search and ranking$' a/PRD-HISTORY-2026-09-25.md || fail 'the appended features block is not archived'
cp a/PRD.md a/PRD.first
sh "$SCRIPT" a/PRD.md --date 2026-09-26 >a/run2.txt 2>&1 || { cat a/run2.txt >&2; fail 'the second consolidation refused'; }
cmp -s a/PRD.md a/PRD.first || { diff a/PRD.first a/PRD.md | head -10 >&2; fail 'the second run is not byte-identical'; }
[ -f a/PRD-HISTORY-2026-09-26.md ] && fail 'the no-op run wrote a second archive'
# a 0.9.1 input writes grammar: 0.9.1 and no features fence
mkdir b && { sed -n '1p' "$FIXTURES/prd-known-good.md"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$FIXTURES/prd-known-good.md"; } | awk '
  /^```vid-prd$/ { inb = 1; print; next }
  /^```$/ { inb = 0 }
  { if (inb && $0 ~ /^[A-Z]+-[0-9]+/) { n = split($0, f, "|"); out = f[1]; for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] } sub(/[ \t]+$/, "", out); print out " | phase: pilot" } else print }' > b/PRD.md
sh "$SCRIPT" b/PRD.md --date 2026-09-25 >b/run.txt 2>&1 || { cat b/run.txt >&2; fail 'the 0.9.1 consolidation refused'; }
sed -n '2p' b/PRD.md | grep -qx 'grammar: 0.9.1' || fail "the 0.9.1 input's output grammar is $(sed -n '2p' b/PRD.md)"
grep -q '^```vid-prd-features$' b/PRD.md && fail 'a features fence appeared on a file that had none'
exit 0
