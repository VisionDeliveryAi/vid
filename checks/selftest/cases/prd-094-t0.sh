#!/bin/sh
# Purpose: selftest case — prd.sh join 18, must-never-break (v0.9.4 spec
# §3.3, §7 case 5), gated on `grammar: 0.9.4`. From the 0.9.4 known-good
# fixture, whose T0 invariant INV-002 rests on the ViD decision A-007 and is
# provisional, `confirms_via: owner-decision OQ-3/yes`, OQ-3 naming A-007:
# the item with `owner-decision/no` convicts; the pending form convicts; a
# carrier naming no ViD decision convicts; an item citing two ViD decisions
# whose confirms_via lists one carrier convicts, and with both acquits;
# partial resolution (A-007 restated human, OQ-3 RESOLVED) keeps the item
# provisional on the other and acquits, amending it authoritative then
# convicts under join 17, and with both resolved it acquits authoritative;
# a T0 constraint citing a ViD decision with `owner-decision/no` convicts;
# after resolution, the row restated human and the item authoritative, it
# acquits; an open carrier naming a decision already restated human
# convicts (an answered question is RESOLVED). Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-t0: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
gaps() { printf '%s\n' "$OUT" | grep '^GAP' || true; }
convicts() { # file, wanted GAP substring — one run: default mode prints the gaps and the report line
  run "$1"; [ "$RC" -ne 0 ] || fail "$1 acquitted, expected a conviction ($2)"
  gaps | grep -qF "$2" || { gaps | head -3 >&2; fail "$1 convicted but not for '$2'"; }
}
acquits() { run "$1" ${2:-}; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail "$1 convicted, expected an acquittal"; }; }
cp "$FIXTURES/prd-094-good.md" G.md
acquits G.md                                                            # OQ-3/yes with an open carrier naming A-007
sed 's|^\(INV-002 .*\)confirms_via: owner-decision OQ-3/yes|\1confirms_via: owner-decision OQ-3/no|' G.md > NO.md
convicts NO.md 'GAP  join 18 (INV-002): a T0 item resting on ViD decision(s) A-007 waits on the owner — confirms_via ends /yes, got /no.'
sed 's|^\(INV-002 .*\)authority: provisional|\1authority: pending|' G.md > PEND.md
convicts PEND.md "GAP  join 18 (INV-002): a T0 item resting on ViD decision(s) A-007 is provisional, confirms_via: owner-decision <one open question per decision>/yes — got 'pending' (the pending form is excluded"
sed 's|^VID-QUESTION: (OQ-3) A-007 — |VID-QUESTION: (OQ-3) |' G.md > NODEC.md
convicts NODEC.md 'GAP  join 18 (OQ-3): a must-never-break question names no ViD decision'
convicts NODEC.md 'GAP  join 18 (INV-002): ViD decision A-007 has no open question'
# two ViD decisions, one carrier each
cat > two.awk <<'AWK'
/^INV-002 \|/ { sub(/source: A-007/, "source: A-007, A-010") }
/^A-009 \| human/ { print; print "A-010 | model_proposed | 2026-08-28 | Q: may a feed source receive an anonymous subscriber count? | A: yes — a count, never an address | settles: INV-002 | shown: pause-2 1"; next }
/^VID-QUESTION: \(OQ-3\)/ { print; print ""; print "VID-QUESTION: (OQ-4) A-010 — May a feed source receive an anonymous subscriber count?"; next }
{ print }
AWK
awk -f two.awk G.md > TWO1.md
convicts TWO1.md 'GAP  join 18 (INV-002): confirms_via omits OQ-4, the open question asking A-010'
sed 's|^\(INV-002 .*\)confirms_via: owner-decision OQ-3/yes|\1confirms_via: owner-decision OQ-3 OQ-4/yes|' TWO1.md > TWO2.md
acquits TWO2.md
# partial resolution: A-007 answered by the owner — restated human, priority; OQ-3 RESOLVED
sed -e 's/^A-007 | model_proposed | \(.*\) | shown: pause-2 [0-9]*$/A-007 | human | \1 | importance: priority/' \
    -e 's/^VID-QUESTION: (OQ-3) A-007 — /RESOLVED: (OQ-3) A-007 — /' TWO2.md > PART.md
grep -q '^A-007 | human ' PART.md && grep -q '^RESOLVED: (OQ-3) A-007' PART.md || fail 'the partial resolution did not apply'
acquits PART.md                                                          # provisional on A-010 still
sed 's#^\(INV-002 .*\)authority: provisional | confirms_via: owner-decision OQ-3 OQ-4/yes#\1authority: authoritative#' PART.md > PARTAUTH.md
grep -q '^INV-002 .*authority: authoritative | source: A-007, A-010' PARTAUTH.md || fail 'the PARTAUTH mutation did not apply'
convicts PARTAUTH.md 'GAP  join 17 (INV-002): authoritative but cites A-010'
sed -e 's/^A-010 | model_proposed | \(.*\) | shown: pause-2 1$/A-010 | human | \1 | importance: priority/' \
    -e 's/^VID-QUESTION: (OQ-4) A-010 — /RESOLVED: (OQ-4) A-010 — /' PARTAUTH.md > BOTH.md
acquits BOTH.md                                                          # both resolved: authoritative
# a T0 constraint citing a ViD decision with owner-decision/no
awk '{ print } /^NG-001 \| non_goal / { print "CON-001 | constraint | T0 | Feed credentials are held by the operator only; no subscriber-facing surface can read them. | authority: provisional | confirms_via: owner-decision OQ-3/no | source: A-007" }' G.md > CON.md
grep -q '^CON-001 | constraint | T0 ' CON.md || fail 'the CON plant did not apply'
convicts CON.md 'GAP  join 18 (CON-001): a T0 item resting on ViD decision(s) A-007 waits on the owner — confirms_via ends /yes, got /no.'
# after resolution: the row restated human and the item authoritative
sed -e 's/^A-007 | model_proposed | \(.*\) | shown: pause-2 [0-9]*$/A-007 | human | \1 | importance: priority/' \
    -e 's/^VID-QUESTION: (OQ-3) A-007 — /RESOLVED: (OQ-3) A-007 — /' \
    -e 's#^\(INV-002 .*\)authority: provisional | confirms_via: owner-decision OQ-3/yes#\1authority: authoritative#' G.md > RES.md
acquits RES.md
# an open carrier naming a decision already restated human: the question was answered
sed 's/^RESOLVED: (OQ-3) A-007 — /VID-QUESTION: (OQ-3) A-007 — /' RES.md > STALE.md
convicts STALE.md 'GAP  join 18 (OQ-3): names A-007, which is human, not a ViD decision'
# the grammar gate: /no under 0.9.1 convicts nothing new
sed 's/^grammar: 0\.9\.4$/grammar: 0.9.1/' NO.md > NO091.md
acquits NO091.md
exit 0
