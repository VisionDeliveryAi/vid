#!/bin/sh
# Purpose: selftest case — a withdrawal lands on the owner's own word
# (0.26.10.29.3, R2). HEAD holds the known-good fixture in its 0.9.1 form and
# ViD's draft A-007 (model_proposed), its withdrawing amendment not committed.
# The owner's yes: A-007 restated `human` by an AMENDED row, with REQ-012
# AMENDED withdrawing its second arm under it, in one append. The court
# passes the file; commit-msg refuses the commit with no Owner: trailer,
# naming A-007, and accepts it with `Owner: A-007 "<words>"`; and the answer
# is not one to mark delegated: `metrics.sh delegated --answer A-007` is
# refused, naming REQ-012. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"; HOOK="$CHECKS/hooks/commit-msg"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; mkdir -p checks .vid; cp "$CHECKS/metrics.sh" checks/; : > .vid/metrics-events
fail() { echo "confirmed-answer-withdraws: $*" >&2; exit 1; }
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
{ sed -n '1p' "$FIXTURES/prd-known-good.md"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$FIXTURES/prd-known-good.md"; } | awk '
  /^```vid-prd$/ { inb = 1; print; next }
  /^```$/ { inb = 0 }
  { if (inb && $0 ~ /^[A-Z]+-[0-9]+/) { n = split($0, f, "|"); out = f[1]; for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] } sub(/[ \t]+$/, "", out); print out " | phase: pilot" } else print }' > PRD.md
printf '\n### 2026-09-30 (the bounce arm, ViD'"'"'s draft)\n\n```vid-prd-answers\nA-007 | model_proposed | 2026-09-30 | Q: may mail to the support address bounce at launch? | A: yes — a bounce is acceptable at launch; the bounce arm is withdrawn | settles: REQ-012\n```\n' >> PRD.md
sh "$COURT" PRD.md >/dev/null 2>&1 || fail 'the draft alone, its withdrawal not written, does not pass the court'
g add PRD.md && g commit -qm 'the draft' --no-verify
printf '\n### 2026-10-02 (the owner says yes)\n\n```vid-prd-answers\nA-007 AMENDED | human | 2026-10-02 | Q: may mail to the support address bounce at launch? | A: yes — a bounce is acceptable at launch; the bounce arm is withdrawn | settles: REQ-012\n```\n\n```vid-prd\nREQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address. | fail-if: the footer lacks a support address | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis, A-007 | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained, 2 withdrawn A-007\n```\n' >> PRD.md
sh "$COURT" PRD.md >court.txt 2>&1 || { grep '^GAP' court.txt >&2; fail 'the withdrawal under the confirmed answer was refused'; }
g add PRD.md
printf 'The bounce arm withdrawn\n\nDecisions: none — nothing surprising\n' > msg
if sh "$HOOK" msg >out 2>&1; then fail 'the confirmation was accepted with no Owner: trailer'; fi
grep -q 'A-007' out || { cat out >&2; fail 'the refusal does not name A-007'; }
printf 'Owner: A-007 "yes, a bounce is fine at launch"\n' >> msg
sh "$HOOK" msg >out 2>&1 || { cat out >&2; fail 'the confirmation with its Owner: trailer was refused'; }
if sh checks/metrics.sh delegated --answer A-007 >out 2>&1; then fail "the confirmed answer, which withdraws an arm, was marked delegated: $(cat out)"; fi
grep -q 'REQ-012' out || fail "the mark's refusal does not name REQ-012: $(cat out)"
exit 0
