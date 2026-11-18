#!/bin/sh
# Purpose: selftest case — an answer given under a delegation never takes a
# failure clause away (0.26.10.29.3, R2). From the known-good fixture in its
# 0.9.1 form, REQ-012 AMENDED withdrawing its second arm under A-007: with
# A-007 written `human`, `sh checks/metrics.sh delegated --answer A-007` is
# refused, naming REQ-012, and writes nothing, while a human answer no
# withdrawn arm cites (A-001) is marked; a later REQ-012 AMENDED row that
# brings the arm back changes nothing (every item row is read, superseded or
# not, as the court judges them): A-007 is still refused.
# Written as the rule says, `model_proposed`, the mark is refused as ViD's
# own, the court holds the withdrawal as a gap at commit and --pause lists it
# as the owner's question. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; mkdir -p checks .vid; cp "$CHECKS/metrics.sh" checks/; : > .vid/metrics-events
fail() { echo "delegated-answer-cannot-withdraw: $*" >&2; exit 1; }
to091() {
  { sed -n '1p' "$1"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$1"; } | awk '
    /^```vid-prd$/ { inb = 1; print; next }
    /^```$/ { inb = 0 }
    { if (inb && $0 ~ /^[A-Z]+-[0-9]+/) { n = split($0, f, "|"); out = f[1]; for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] } sub(/[ \t]+$/, "", out); print out " | phase: pilot" } else print }' > "$2"
}
to091 "$FIXTURES/prd-known-good.md" BASE.0
sed 's/^\(A-001 | human | .*\)$/\1 | delegated: yes/' BASE.0 > BASE.md   # a delegated answer's row says so; the mark asks for it
withdraw() { # tier (the human one: with its field) → PRD.md
  { cat BASE.md; printf '\n### 2026-09-30 (the bounce arm)\n\n```vid-prd-answers\nA-007 | %s | 2026-09-30 | Q: may mail to the support address bounce at launch? | A: yes — a bounce is acceptable at launch; the bounce arm is withdrawn | settles: REQ-012\n```\n\n```vid-prd\nREQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address. | fail-if: the footer lacks a support address | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis, A-007 | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained, 2 withdrawn A-007\n```\n' "$1"; } > PRD.md
}
mark() { sh checks/metrics.sh delegated --answer "$1" > "$T/out" 2>&1; }
# written human: the mark is refused, naming the item whose arm it withdraws
withdraw 'human'; sed 's/^\(A-007 | human | .*\)$/\1 | delegated: yes/' PRD.md > p && mv p PRD.md
if mark A-007; then fail "a human answer a withdrawn arm cites was marked delegated: $(cat "$T/out")"; fi
grep -q 'refused' "$T/out" && grep -q 'REQ-012' "$T/out" || fail "the refusal does not name REQ-012: $(cat "$T/out")"
[ ! -s .vid/metrics-events ] || fail "the refused mark wrote: $(cat .vid/metrics-events)"
mark A-001 || fail "a human answer no withdrawn arm cites was refused: $(cat "$T/out")"
# every item row is read, as the court judges them: the arm brought back by a later row, the old row still cites the answer
printf '\n### 2026-10-02 (the bounce arm stays)\n\n```vid-prd\nREQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address that reaches a person. | fail-if: the footer lacks a support address, or mail to it bounces | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained\n```\n' >> PRD.md
if mark A-007; then fail "the withdrawing row superseded, the answer it cites was marked delegated: $(cat "$T/out")"; fi
grep -q 'REQ-012' "$T/out" || fail "the refusal for the superseded row does not name REQ-012: $(cat "$T/out")"
# written as the rule says, model_proposed: no mark, a gap at commit, the owner's question at the pause
: > .vid/metrics-events; withdraw model_proposed
if mark A-007; then fail 'a model_proposed answer was marked delegated'; fi
if sh "$COURT" PRD.md >court.txt 2>&1; then fail 'the withdrawal under the draft passed at commit'; fi
grep '^GAP' court.txt | grep -F 'join 14 (REQ-012 AMENDED)' | grep -q 'A-007' || { grep '^GAP' court.txt >&2; fail 'the gap does not name REQ-012 and A-007'; }
sh "$COURT" PRD.md --pause >pause.txt 2>&1 || fail 'the withdrawal under the draft was refused under --pause'
grep -qxF "  arm 2 of REQ-012 withdrawn under ViD's draft A-007" pause.txt || fail 'the pause material does not list the owner question'
exit 0
