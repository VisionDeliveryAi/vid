#!/bin/sh
# Purpose: selftest case — a removal that cites a delegated answer waits for
# the owner, whatever the order (0.26.10.29.3, R2). From the known-good
# fixture in its 0.9.1 form: A-007, a `human` answer ViD wrote under the
# owner's delegation, carries `delegated: yes` on its row, and the court
# passes it (the label is part of the answer row's grammar). A later append
# amends REQ-012 with `arms: … withdrawn A-007`: a gap at commit, naming the
# arm, REQ-012 and A-007 as a delegated answer not yet confirmed; under
# --pause not refused, and listed as the owner's question. The answer
# restated `human` by an AMENDED row without the field (the owner's
# confirmation) passes and lists nothing. Consolidation keeps the field on
# the answer's row. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "late-removal-under-delegated-answer: $*" >&2; exit 1; }
{ sed -n '1p' "$FIXTURES/prd-known-good.md"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$FIXTURES/prd-known-good.md"; } | awk '
  /^```vid-prd$/ { inb = 1; print; next }
  /^```$/ { inb = 0 }
  { if (inb && $0 ~ /^[A-Z]+-[0-9]+/) { n = split($0, f, "|"); out = f[1]; for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] } sub(/[ \t]+$/, "", out); print out " | phase: pilot" } else print }' > HEAD.md
# the delegated answer, as HEAD holds it: no removal yet
printf '\n### 2026-09-30 (a delegated answer)\n\n```vid-prd-answers\nA-007 | human | 2026-09-30 | Q: may mail to the support address bounce at launch? | A: yes — a bounce is acceptable at launch | settles: REQ-012 | delegated: yes\n```\n' >> HEAD.md
sh "$COURT" HEAD.md >head.txt 2>&1 || { grep '^GAP' head.txt >&2; fail 'an answer row carrying delegated: yes is refused by the court'; }
# a later append removes a failure clause, citing it
{ cat HEAD.md; printf '\n### 2026-10-05 (the bounce arm, later)\n\n```vid-prd\nREQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address. | fail-if: the footer lacks a support address | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis, A-007 | covers: DIM-nfr-operability/support | phase: pilot | arms: 1 retained, 2 withdrawn A-007\n```\n'; } > LATE.md
if sh "$COURT" LATE.md >late.txt 2>&1; then fail 'an arm withdrawn under a delegated answer the owner has not confirmed passed at commit'; fi
grep '^GAP' late.txt | grep -F 'join 14 (REQ-012 AMENDED)' | grep 'A-007' | grep -q 'delegated' || { grep '^GAP' late.txt >&2; fail 'the gap does not name REQ-012 and A-007 as a delegated answer'; }
sh "$COURT" LATE.md --pause >pause.txt 2>&1 || { grep '^GAP' pause.txt >&2; fail 'the removal under a delegated answer was refused under --pause (it is an owner question there)'; }
grep -qxF '  arm 2 of REQ-012 withdrawn under A-007, a delegated answer not yet confirmed' pause.txt || { cat pause.txt >&2; fail 'the pause material does not list the owner question'; }
# the owner confirms: the answer restated human, without the field
{ cat LATE.md; printf '\n### 2026-10-06 (the owner confirms)\n\n```vid-prd-answers\nA-007 AMENDED | human | 2026-10-06 | Q: may mail to the support address bounce at launch? | A: yes — a bounce is acceptable at launch | settles: REQ-012\n```\n'; } > CONF.md
sh "$COURT" CONF.md >conf.txt 2>&1 || { grep '^GAP' conf.txt >&2; fail 'the answer confirmed (restated without delegated: yes), and the removal is still a gap'; }
sh "$COURT" CONF.md --pause >cpause.txt 2>&1 || fail 'the confirmed removal was refused under --pause'
grep -qE '^  arm [0-9]+ of .* withdrawn under ' cpause.txt && fail 'a removal under a confirmed answer is still listed as an owner question'
# consolidation keeps the field
mkdir c && cp HEAD.md c/PRD.md
sh "$CHECKS/prd-consolidate.sh" c/PRD.md --date 2026-10-07 >cons.txt 2>&1 || { cat cons.txt >&2; fail 'the consolidation refused the fixture'; }
grep -qE '^A-007 \| human \| .*\| delegated: yes$' c/PRD.md || { grep '^A-007' c/PRD.md >&2; fail 'the consolidation dropped delegated: yes from the answer row'; }
grep '^A-007' c/PRD.md | grep -q '| Q:' && fail 'the consolidation kept Q: on the delegated answer'
exit 0
