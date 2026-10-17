#!/bin/sh
# Purpose: selftest case — prd.sh join 14, arm accounting (v0.9.1 spec 3.5b,
# R15-i), gated on `grammar: 0.9.1`. From the known-good fixture in its
# 0.9.1 form: the accounted amendment acquits; an AMENDED row with two
# entries for a three-arm predecessor convicts; `moved` to an item whose
# revision before the move does not carry the arm convicts; a move followed
# by a lawful withdrawal from the target acquits both rows (R15-i);
# `withdrawn` citing a non-existent answer convicts; a disposition outside
# the list convicts; an AMENDED row without arms: convicts. On the legacy
# fixture an amendment losing an arm unaccounted is reported (NOTE,
# arm-losing=1) and one whose arm text changed at the same count is reported
# arm-changed, never convicted. Env: CHECKS (set by checks/selftest/run.sh).
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
to091() {
  { sed -n '1p' "$1"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$1"; } | awk '
    /^```vid-prd$/ { inb = 1; print; next }
    /^```$/ { inb = 0 }
    { if (inb && $0 ~ /^[A-Z]+-[0-9]+/) { n = split($0, f, "|"); out = f[1]; for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] } sub(/[ \t]+$/, "", out); print out " | phase: pilot" } else print }' > "$2"
}
to091 "$FIXTURES/prd-known-good.md" BASE.md
sh "$COURT" BASE.md >/dev/null 2>&1 || { echo 'prd-arms: the accounted 0.9.1 base does not acquit' >&2; sh "$COURT" BASE.md --report 2>&1 | grep '^GAP' | head -3 >&2; exit 1; }
gaps() { sh "$COURT" "$1" --report 2>&1 | grep '^GAP' || true; }
convicts() { # file, wanted GAP substring
  if sh "$COURT" "$1" >/dev/null 2>&1; then echo "prd-arms: $1 acquitted, expected a conviction" >&2; return 1; fi
  gaps "$1" | grep -qF "$2" || { echo "prd-arms: $1 convicted but not for '$2':" >&2; gaps "$1" | head -3 >&2; return 1; }
}
R12='REQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address that reaches a person, shown on every digest. | fail-if: the footer lacks a support address, or mail to it bounces, or the address is missing from any one digest | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained, 2 retained'
# (a) two entries for a three-arm predecessor
{ cat BASE.md; printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd\n%s\nREQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address that reaches a person. | fail-if: the footer lacks a support address, or mail to it bounces | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained, 2 retained\n```\n' "$R12"; } > A.md
convicts A.md 'GAP  join 14 (REQ-012 AMENDED): arms: carries 2 entr(y/ies) for a predecessor with 3 arm(s)'
# (b) moved to an item whose revision before the move does not carry the arm
{ cat BASE.md; printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd\nREQ-002 AMENDED | functional | T1 | Every digest carries a working one-click unsubscribe that stops all digests for that address within one day. | fail-if: a digest arrives more than one day after its address unsubscribed | serves: consent exit | authority: authoritative | source: seed | covers: DIM-consent | phase: pilot | arms: 1 retained, 2 moved REQ-012\n```\n'; } > B.md
convicts B.md "GAP  join 14 (REQ-002 AMENDED): arm 2 moved to REQ-012, but REQ-012's revision before this row does not carry it"
# (c) R15-i: REQ-001 moves its second arm to REQ-011 (which received it first); REQ-011 later withdraws it under a named ruling — both acquit
cat > C.append <<'APP'

### 2026-09-01 (owner answer — the one-per-day bound moves to the delivery log)

```vid-prd
REQ-011 AMENDED | nfr | T2 | Digest delivery failures surface in an operator-visible log with a daily failure count, and no search receives two digests in one day. | fail-if: a day of failed sends leaves no operator-visible trace, or two digests for one search arrive in one day | serves: operators learn the product is broken before subscribers do | authority: authoritative | source: thesis | covers: DIM-nfr-operability/observability | phase: pilot | arms: 1 retained
REQ-001 AMENDED | functional | T1 | A subscriber receives one digest per saved search per day, containing only new matches since the last digest. | fail-if: a digest repeats a job already delivered for that search | serves: trust in the alert channel — the reason a user hands over an email address | authority: authoritative | source: seed, A-001 | covers: DIM-notifications | derives: trigger-row | phase: pilot | arms: 1 retained, 2 moved REQ-011
```

### 2026-09-02 (owner answer — the bound withdrawn)

```vid-prd-answers
A-007 | human | 2026-09-02 | Q: may a search receive two digests in one day? | A: yes, when the subscriber changed the search that day — the one-per-day bound is withdrawn | settles: REQ-011
```

```vid-prd
REQ-011 AMENDED | nfr | T2 | Digest delivery failures surface in an operator-visible log with a daily failure count. | fail-if: a day of failed sends leaves no operator-visible trace | serves: operators learn the product is broken before subscribers do | authority: authoritative | source: thesis, A-007 | covers: DIM-nfr-operability/observability | phase: pilot | arms: 1 retained, 2 withdrawn A-007
```
APP
cat BASE.md C.append > C.md
sh "$COURT" C.md >/dev/null 2>&1 || { echo 'prd-arms: the move-then-withdraw fixture (R15-i) does not acquit:' >&2; gaps C.md | head -3 >&2; exit 1; }
# (d) withdrawn citing a non-existent answer
{ cat BASE.md; printf '\n### 2026-09-01 (owner answer)\n\n```vid-prd\nREQ-002 AMENDED | functional | T1 | Every digest carries a working one-click unsubscribe that stops all digests for that address within one day. | fail-if: a digest arrives more than one day after its address unsubscribed | serves: consent exit | authority: authoritative | source: seed | covers: DIM-consent | phase: pilot | arms: 1 retained, 2 withdrawn A-999\n```\n'; } > D.md
convicts D.md 'GAP  join 14 (REQ-002 AMENDED): arm 2 withdrawn under A-999, which is no effective answer.'
# (e) a disposition outside the list
sed 's/arms: 1 strengthened, 2 retained/arms: 1 kept, 2 retained/' BASE.md > E.md
convicts E.md "GAP  join 14 (REQ-002 AMENDED): arms: disposition 'kept' is not retained"
# (f) an AMENDED row without arms: under the grammar line
sed 's/ | arms: 1 strengthened, 2 retained//' BASE.md > F.md
grep -q 'arms:' F.md && exit 1
convicts F.md 'GAP  join 14 (REQ-002 AMENDED): no arms:'
# (g) legacy: the accounted known-good acquits; an unaccounted arm loss is reported, never convicted
OUT=$(sh "$COURT" "$FIXTURES/prd-known-good.md" --report 2>&1)
printf '%s\n' "$OUT" | grep -q 'gaps=0' || exit 1
printf '%s\n' "$OUT" | grep -q 'arm-losing=0' || exit 1
sed 's/ | arms: 1 strengthened, 2 retained$//; s/fail-if: a digest arrives more than one day after its address unsubscribed, or the unsubscribe link requires a sign-in/fail-if: a digest arrives more than one day after its address unsubscribed/' "$FIXTURES/prd-known-good.md" > L.md
grep -q 'arms:' L.md && exit 1
sh "$COURT" L.md >/dev/null 2>&1 || { echo 'prd-arms: the legacy arm-losing file was convicted — the grammar gate is broken' >&2; exit 1; }
OUT=$(sh "$COURT" L.md --report 2>&1)
printf '%s\n' "$OUT" | grep -qF 'NOTE  join 14 (REQ-002 AMENDED): arm-losing — 2 arm(s) before, 1 after, no arms: accounting' || exit 1
printf '%s\n' "$OUT" | grep -q 'arm-losing=1 arm-changed=0' || exit 1
sed 's/ | arms: 1 strengthened, 2 retained$//; s/fail-if: a digest arrives more than one day after its address unsubscribed, or the unsubscribe link requires a sign-in/fail-if: a digest arrives more than one day after its address unsubscribed, or the unsubscribe link demands a password/' "$FIXTURES/prd-known-good.md" > M.md
sh "$COURT" M.md >/dev/null 2>&1 || exit 1
OUT=$(sh "$COURT" M.md --report 2>&1)
printf '%s\n' "$OUT" | grep -qF 'NOTE  join 14 (REQ-002 AMENDED): arm-changed — 2 arm(s) before and after' || exit 1
printf '%s\n' "$OUT" | grep -q 'arm-losing=0 arm-changed=1' || exit 1
exit 0
