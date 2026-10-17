#!/bin/sh
# Purpose: selftest case — one plain sentence per requirement (v0.9.5 spec
# 3.13, R13; §7 case 20). The 0.9.4 good fixture raised to `grammar: 0.9.5`
# with a `plain:` on every demand item and invariant must acquit. Convicts
# unless each of these convicts under 0.9.5: a missing `plain:`; two
# `plain:` fields; "Search is fast. Results are sorted"; 31 words; `REQ-12`
# in the text; a number its statement and fail-if lack — while "e.g. the",
# "3.5 s" (its fail-if holding 3.5) and "HIPAA-compliant" pass; the same
# convicting file under `grammar: 0.9.4` acquits; the real pre-commit hook
# refuses a staged grammar line lowered from 0.9.5 to 0.9.4 and accepts a
# raise; and `--pause` prints each sentence beside its statement. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
COURT="$CHECKS/prd.sh"
fail() { echo "prd-095-plain: $*" >&2; sh "$COURT" "$T/v.md" 2>&1 | grep -E 'GAP|NOTE' | head -5 >&2; exit 1; }
# the base: 0.9.5, every REQ and INV row with a plain sentence; REQ-012's fail-if gains a 3.5-second arm
awk 'NR <= 3 && /^grammar: 0\.9\.4$/ { print "grammar: 0.9.5"; next }
  /^(REQ|INV)-[0-9]+( AMENDED)? \|/ { if ($0 ~ /^REQ-012 /) { sub(/mail to it bounces/, "mail to it bounces, or a reply takes longer than 3.5 seconds"); print $0 " | plain: e.g. the support address answers within 3.5 s and stays HIPAA-compliant for every subscriber" }
    else print $0 " | plain: The owner reads this rule in plain words"; next }
  { print }' "$CHECKS/selftest/fixtures/prd-094-good.md" > base.md
grep -q '^grammar: 0.9.5$' base.md || { echo 'prd-095-plain: the fixture has no 0.9.4 header to raise' >&2; exit 1; }
cp base.md v.md; sh "$COURT" v.md >/dev/null 2>&1 || fail 'the 0.9.5 base does not acquit'
variant() { # $1=id $2=the replacement plain: field ('' to drop it) → v.md
  awk -v id="$1" -v rep="$2" 'index($0, id " ") == 1 && !d { sub(/ \| plain: [^|]*$/, ""); if (rep != "") $0 = $0 " | " rep; d = 1 } { print }' base.md > v.md; }
convicts() { variant "$1" "$2"; if sh "$COURT" v.md >/dev/null 2>&1; then fail "acquitted: $3"; fi
  sh "$COURT" v.md 2>&1 | grep -q "join 21 ($1)" || fail "no join 21 line for: $3"; }
convicts REQ-001 '' 'a missing plain:'
convicts REQ-001 'plain: One rule | plain: Another rule' 'two plain: fields'
convicts REQ-003 'plain: Search is fast. Results are sorted' 'two sentences'
convicts REQ-005 'plain: one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix twentyseven twentyeight twentynine thirty thirtyone' '31 words'
convicts REQ-006 'plain: A subscriber keeps searches, as REQ-12 says' 'an id in the text'
convicts REQ-006 'plain: A subscriber can hold at most 11 saved searches' 'a number the statement lacks'
variant REQ-001 'plain: One rule. i.e. one digest a day, e.g. the new matches only'
sh "$COURT" v.md >/dev/null 2>&1 || fail 'i.e. and e.g. followed by lowercase words convicted'
variant REQ-003 'plain: Search is fast. Results are sorted'
sed 's/^grammar: 0\.9\.5$/grammar: 0.9.4/' v.md > v4.md
sh "$COURT" v4.md >/dev/null 2>&1 || { cp v4.md v.md; fail 'the same file under 0.9.4 convicted'; }
sh "$COURT" --pause base.md > pause.txt 2>&1 || true
grep -q '^plain sentences (every demand item and invariant' pause.txt || { cat pause.txt >&2; fail 'no plain sentences in the pause material'; }
grep -qF '  REQ-001 | plain: The owner reads this rule in plain words | rule: A subscriber receives one digest per saved search per day' pause.txt || fail 'the sentence is not beside its statement'
# the hook: a grammar is never lowered
mkdir h && cd h
. "$CHECKS/selftest/fixtures/stub-courts.sh"
cp ../base.md PRD.md; g add PRD.md; g commit -qm 'the PRD at 0.9.5'
sed 's/^grammar: 0\.9\.5$/grammar: 0.9.4/' ../base.md > PRD.md; g add PRD.md
if sh checks/hooks/pre-commit > ../out 2>&1; then cat ../out >&2; echo 'prd-095-plain: a lowered grammar line was accepted' >&2; exit 1; fi
grep -q 'grammar line goes from 0.9.5 to 0.9.4' ../out || { cat ../out >&2; exit 1; }
sed 's/^grammar: 0\.9\.5$/grammar: 0.9.6/' ../base.md > PRD.md; g add PRD.md
sh checks/hooks/pre-commit > ../out 2>&1 || { cat ../out >&2; echo 'prd-095-plain: a raised grammar line was refused' >&2; exit 1; }
exit 0
