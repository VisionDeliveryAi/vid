#!/bin/sh
# Purpose: selftest case — prd.sh join 20, ViD decisions shown once (v0.9.4
# spec §3.5, §7 case 10), under `grammar: 0.9.4` and --pause only. Every
# effective model_proposed answer carries a current `shown: pause-N <sum>`,
# the sum the cksum of its whitespace-collapsed A: text as presented. From
# the 0.9.4 known-good fixture: a ViD decision without shown: acquits by
# default and convicts under --pause; with its current label it acquits
# under --pause; its A: edited while the old label stays convicts and
# prints `(revised)` — in place, and as an AMENDED row copying the label;
# the label rewritten with the sum --pause prints acquits again; on 0.9.1,
# --pause convicts nothing new. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-pause: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
gaps() { printf '%s\n' "$OUT" | grep '^GAP' || true; }
cp "$FIXTURES/prd-094-good.md" G.md
run G.md --pause; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail 'the fixture with current labels convicts under --pause'; }
printf '%s\n' "$OUT" | grep -q '^new ViD decisions (not yet shown; ranked by T0, T1, total grounded, id): 0$' || fail 'a shown decision is listed as new'
# no shown: — acquits by default, convicts under --pause
sed 's/^\(A-005 | model_proposed | .*\) | shown: pause-1 [0-9]*$/\1/' G.md > NOSHOW.md
grep -q '^A-005 .*shown:' NOSHOW.md && fail 'the NOSHOW mutation did not apply'
run NOSHOW.md; [ "$RC" -eq 0 ] || fail 'an unshown ViD decision convicts by default'
run NOSHOW.md --pause; [ "$RC" -ne 0 ] || fail 'an unshown ViD decision acquits under --pause'
gaps | grep -qF 'GAP  join 20 (A-005): a ViD decision not yet shown to the owner — present it at this pause, then label it shown: pause-N ' || { gaps | head -3 >&2; fail 'join 20 does not name A-005'; }
printf '%s\n' "$OUT" | grep -qE '^  A-005 \| [0-9]+ \| grounds T0 0 · T1 0 · T2 1 \(items REQ-006\) \| A: cap at ten saved searches per subscriber for MVP$' || fail 'the new decision line is missing'
# revised in place: the A: changed, the old label kept
sed 's/^\(A-005 | model_proposed | .* | A: \)cap at ten saved searches per subscriber for MVP/\1cap at twelve saved searches per subscriber for MVP/' G.md > INPLACE.md
grep -q 'cap at twelve' INPLACE.md || fail 'the INPLACE mutation did not apply'
run INPLACE.md; [ "$RC" -eq 0 ] || fail 'a revised decision convicts by default'
run INPLACE.md --pause; [ "$RC" -ne 0 ] || fail 'a revised decision acquits under --pause'
gaps | grep -qF 'GAP  join 20 (A-005): revised since it was shown (shown: pause-1 2042538 no longer matches its A:)' || { gaps | head -3 >&2; fail 'the in-place revision is not named'; }
printf '%s\n' "$OUT" | grep -qE '^  A-005 \(revised\) \| [0-9]+ \| ' || fail 'the in-place revision does not print (revised)'
SUM=$(printf '%s\n' "$OUT" | sed -n 's/^  A-005 (revised) | \([0-9]*\) | .*/\1/p')
[ -n "$SUM" ] && [ "$SUM" != 2042538 ] || fail "the revised sum is missing or unchanged ('$SUM')"
# relabelled with the sum --pause printed: acquits
sed "s/| shown: pause-1 2042538\$/| shown: pause-3 $SUM/" INPLACE.md > RELABEL.md
run RELABEL.md --pause; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail 'the relabelled decision still convicts'; }
# revised as an AMENDED row copying the old label
cp G.md AMEND.md
printf '\n### 2026-09-03 (owner answer)\n\n```vid-prd-answers\nA-005 AMENDED | model_proposed | 2026-09-03 | Q: how many saved searches per subscriber? | A: cap at twelve saved searches per subscriber for MVP | settles: REQ-006 | shown: pause-1 2042538\n```\n' >> AMEND.md
run AMEND.md --pause; [ "$RC" -ne 0 ] || fail 'an AMENDED revision copying the label acquits under --pause'
gaps | grep -qF 'GAP  join 20 (A-005): revised since it was shown' || { gaps | head -3 >&2; fail 'the AMENDED revision is not named'; }
printf '%s\n' "$OUT" | grep -qE '^  A-005 \(revised\) \| ' || fail 'the AMENDED revision does not print (revised)'
# 0.9.1: --pause convicts nothing new — an unshown decision, a floor breach and a door row alike
sed -e 's/^grammar: 0\.9\.4$/grammar: 0.9.1/' -e 's/^\(A-006 | human | .*\) | importance: priority$/\1/' NOSHOW.md > OLD.md
printf '\n### 2026-09-03 (/vid fix correction)\n\n```vid-prd\nREQ-040 | functional | T2 | An unsubscribe takes effect within 72 hours. | fail-if: a digest arrives more than 72 hours after an unsubscribe | serves: the corrected exit | authority: authoritative | source: fix 2026-09-03 | phase: pilot\n```\n' >> OLD.md
run OLD.md; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail 'the 0.9.1 file convicts by default'; }
D=$(gaps)
run OLD.md --pause; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail 'the 0.9.1 file convicts under --pause'; }
[ "$(gaps)" = "$D" ] || fail '--pause changed the gaps on a 0.9.1 file'
printf '%s\n' "$OUT" | grep -q '^pause material ' || fail '--pause prints no material on the 0.9.1 file'
exit 0
