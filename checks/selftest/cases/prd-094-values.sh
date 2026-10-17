#!/bin/sh
# Purpose: selftest case — prd.sh join 19, values traced (v0.9.4 spec §3.4,
# §7 case 7), gated on `grammar: 0.9.4`, run under LC_ALL=C. Every value
# token in the statement of an authoritative or provisional owner-decision
# item must appear in a text its source: cites (the seed, a cited answer's
# A:, the thesis, the sources). From the 0.9.4 known-good fixture: 72 hours
# against a cited A: of 48 convicts naming '72'; the value only in the Q:
# convicts; the A: stating 72 acquits; a fail-if-only "21 jobs" acquits;
# REQ-120, §7.1, Phase 1 and G4 are not values; 100,000 against 100000
# acquits both ways; a provisional owner-decision item whose number is only
# in its ViD decision's A: acquits, and convicts once the A: loses it; a
# metric with an unsourced threshold convicts; an AMENDED row keeping its
# value and the citation grounding it acquits, dropping the citation
# convicts; `source: seed, draft` with an invented value convicts (an
# unknown entry exempts nothing); `thesis G2` reads the thesis; a row citing
# `fix 2026-09-09` acquits and counts in values-unchecked=1. Env: CHECKS.
set -eu
LC_ALL=C; export LC_ALL
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-values: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
gaps() { printf '%s\n' "$OUT" | grep '^GAP' || true; }
convicts() { # file, wanted GAP substring — one run: default mode prints the gaps and the report line
  run "$1"; [ "$RC" -ne 0 ] || fail "$1 acquitted, expected a conviction ($2)"
  gaps | grep -qF "$2" || { gaps | head -3 >&2; fail "$1 convicted but not for '$2'"; }
}
acquits() { run "$1" ${2:-}; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail "$1 convicted, expected an acquittal"; }; }
cp "$FIXTURES/prd-094-good.md" G.md
acquits G.md
# row <id> <statement> <source> [<fail-if>]: an authoritative functional row in FEAT-01
row() { printf '%s | functional | T2 | %s | fail-if: %s | serves: a planted case | authority: authoritative | source: %s | phase: pilot | feature: FEAT-01' "$1" "$2" "${4:-the stated behaviour is absent}" "$3"; }
# mk <out> <item rows> <answer rows>: the fixture plus one dated append carrying them
mk() {
  cp "${4:-G.md}" "$1"
  printf '\n### 2026-09-03 (owner answer)\n' >> "$1"
  [ -z "$3" ] || printf '\n```vid-prd-answers\n%s\n```\n' "$3" >> "$1"
  [ -z "$2" ] || printf '\n```vid-prd\n%s\n```\n' "$2" >> "$1"
}
A48='A-010 | human | 2026-09-03 | Q: how long do digest links live? | A: links expire after 48 hours | settles: REQ-030'
mk V72.md "$(row REQ-030 'A digest'"'"'s links expire after 72 hours.' A-010)" "$A48"
convicts V72.md "GAP  join 19 (REQ-030): value '72' appears in none of its cited sources (A-010) — cite the decision that states it"
mk Q72.md "$(row REQ-030 'A digest'"'"'s links expire after 72 hours.' A-010)" 'A-010 | human | 2026-09-03 | Q: should digest links expire after 72 hours? | A: yes, as asked | settles: REQ-030'
convicts Q72.md "GAP  join 19 (REQ-030): value '72'"
mk A72.md "$(row REQ-030 'A digest'"'"'s links expire after 72 hours.' A-010)" 'A-010 | human | 2026-09-03 | Q: how long do digest links live? | A: links expire after 72 hours | settles: REQ-030'
acquits A72.md
# a fail-if-only value is a falsifier at work, not a claim
mk F21.md "$(row REQ-031 'A digest lists its new matches most recent first.' seed 'a digest carries 21 jobs in any order but most recent first')" ''
acquits F21.md
# ids, sections, labels and ordinals are not values
mk IDS.md "$(row REQ-032 'Per REQ-120 and §7.1, Phase 1 ships the G4 digest to T0 subscribers.' seed)" ''
acquits IDS.md
# thousands commas, both ways
mk K1.md "$(row REQ-033 'The listing store holds up to 100,000 live listings.' A-011)" 'A-011 | human | 2026-09-03 | Q: how large is the store at launch? | A: size it for 100000 live listings | settles: REQ-033'
acquits K1.md
mk K2.md "$(row REQ-033 'The listing store holds up to 100000 live listings.' A-011)" 'A-011 | human | 2026-09-03 | Q: how large is the store at launch? | A: size it for 100,000 live listings | settles: REQ-033'
acquits K2.md
# a provisional owner-decision item: its number in its ViD decision's A:, then not
sed -e 's/^\(REQ-006 | functional | T2 | \)A subscriber can hold up to ten saved searches; creating an eleventh is refused/\1A subscriber can hold up to 10 saved searches; creating one more is refused/' \
    -e 's/^\(A-005 | model_proposed | .* | A: \)cap at ten saved searches/\1cap at 10 saved searches/' G.md > P10.md
grep -q '^REQ-006 .*up to 10 saved' P10.md && grep -q '^A-005 .*cap at 10 saved' P10.md || fail 'the P10 mutation did not apply'
acquits P10.md
sed 's/^\(A-005 | model_proposed | .* | A: \)cap at 10 saved searches/\1cap at ten saved searches/' P10.md > P10X.md
convicts P10X.md "GAP  join 19 (REQ-006): value '10' appears in none of its cited sources (A-005)"
# a metric with an unsourced threshold
sed 's/^\(MET-001 .*\)| source: A-008 |/\1| source: thesis |/' G.md > MET.md
convicts MET.md "GAP  join 19 (MET-001): value '28' appears in none of its cited sources (thesis)"
# an AMENDED row keeping its value and its grounding citation acquits; dropping the citation convicts
M1=$(grep '^MET-001 ' G.md | sed 's/^MET-001 /MET-001 AMENDED /; s/weak band below 30 percent/weak band below 30 percent of delivered digests/')
mk AMK.md "$M1" ''
acquits AMK.md
mk AMD.md "$(printf '%s\n' "$M1" | sed 's/| source: A-008 |/| source: thesis |/')" ''
convicts AMD.md "GAP  join 19 (MET-001): value '28'"
# an unknown entry contributes no text and exempts nothing
mk DRAFT.md "$(row REQ-034 'A digest is sent within 5 minutes of the daily run.' 'seed, draft')" ''
convicts DRAFT.md "GAP  join 19 (REQ-034): value '5' appears in none of its cited sources (seed, draft)"
# `thesis G2` reads ## Thesis
sed 's/^Job seekers in niche trades who save a handful of targeted searches and$/Job seekers in niche trades who save up to 12 targeted searches and/' G.md > TH.md
grep -q 'save up to 12 targeted' TH.md || fail 'the thesis plant did not apply'
mk TH12.md "$(row REQ-035 'A subscriber may hold 12 saved searches at once.' 'thesis G2')" '' TH.md
acquits TH12.md
mk TH12S.md "$(row REQ-035 'A subscriber may hold 12 saved searches at once.' seed)" '' TH.md
convicts TH12S.md "GAP  join 19 (REQ-035): value '12' appears in none of its cited sources (seed)"
# a door sitting reference: counted, not traced
mk FIX.md "$(row REQ-036 'An unsubscribe takes effect within 72 hours.' 'fix 2026-09-09')" ''
acquits FIX.md
printf '%s\n' "$OUT" | grep -q ' values-unchecked=1$' || fail "the fix-cited row is not counted: $(printf '%s\n' "$OUT" | tail -1)"
# the grammar gate: under 0.9.1 an untraced value convicts nothing
sed 's/^grammar: 0\.9\.4$/grammar: 0.9.1/' V72.md > V72-091.md
acquits V72-091.md
exit 0
