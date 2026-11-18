#!/bin/sh
# Purpose: selftest case — the PRD as a page (usability, B2). On the pages' toy, with an append that amends A-001 and
# adds a ViD answer never shown: `pages.sh prd` writes .vid/pages/PRD.md whose head line carries six of `prd.sh
# --report`'s figures, each equal; parts 2 to 6 (the summary, the qualities, the features, the decisions, the open
# questions) hold every effective item of `prd.sh --effective` by id, each requirement's every way to fail from
# `--failifs` one line each, "Must never break" on each T0 item and "Rests on a ViD decision" on each provisional one,
# each feature headed with its counts from `--pause`; REQ-002 and A-001 only in their latest wording; the owner's answers
# under "Yours" and ViD's under "ViD's", each marked seen or not; the open questions; every quality, the one ruled out
# last; the append as history under its warning, and the ratification lines. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-prd: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
pg_toy "$T/toy"
cat >> PRD.md <<'MD'

### 2026-08-30 (owner answer)

```vid-prd-answers
A-001 AMENDED | human | 2026-08-30 | Q: one digest per search or one combined? | A: per search, always | settles: REQ-001
A-010 | model_proposed | 2026-08-30 | Q: which hour by default? | A: seven in the morning | settles: REQ-020
```
MD
sh "$CHECKS/pages.sh" prd > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'prd failed'; }
M=.vid/pages/PRD.md; [ -f "$M" ] || fail 'no page'
sec() { awk -v h="## $1" '$0 == h { on = 1; next } on && /^## / { exit } on' "$M"; }
body=$(awk '/^## The summary$/ { on = 1 } /^## History/ { on = 0 } on' "$M")
# the head: six figures of --report, each equal
R=$(sh "$CHECKS/prd.sh" PRD.md --report 2>/dev/null | grep '^prd:' || true)
fig() { printf '%s\n' "$R" | tr ' ' '\n' | sed -n "s/^$1=//p" | head -n 1; }
head=$(awk '/^## /{exit} /^Requirements: /' "$M")
[ "$head" = "Requirements: $(fig demand) · Features: $(fig features) · Open questions: $(fig open-OQs) · Answers of yours: $(printf '%s\n' "$R" | sed -n 's/.*(human=\([0-9]*\).*/\1/p') · Answers of ViD's: $(printf '%s\n' "$R" | sed -n 's/.* model=\([0-9]*\)).*/\1/p') · Findings: $(fig findings)" ] || fail "the head differs from --report: $head"
# every effective item, by id, in parts 2 to 6
sh "$CHECKS/prd.sh" --effective PRD.md | cut -d'|' -f1 | tr -d ' ' > "$T/ids"
[ "$(grep -c . "$T/ids")" = 13 ] || fail 'the fixture does not hold 13 effective items'
while IFS= read -r i; do printf '%s\n' "$body" | grep -qF "{id: $i}" || fail "$i is on none of parts 2 to 6"; done < "$T/ids"
# the latest wording only
printf '%s\n' "$body" | grep -qF 'stops all digests for that address within one day.' || fail "REQ-002's amended wording is not shown"
printf '%s\n' "$body" | grep -qF 'stops all digests for that address.' && fail "REQ-002's replaced wording is shown"
printf '%s\n' "$body" | grep -qF 'per search, always' || fail "A-001's latest answer is not shown"
printf '%s\n' "$body" | grep -qF 'combined digests bury the niche searches' && fail "A-001's replaced answer is shown"
# every way to fail, one line each, in its requirement's entry
sh "$CHECKS/prd.sh" --failifs PRD.md > "$T/fi"
while IFS="$(printf '\t')" read -r i f; do
  e=$(printf '%s\n' "$body" | awk -v a="{at: $(printf '%s' "$i" | tr 'A-Z' 'a-z')}" '$0 == a { on = 1; next } on && /^\{at: / { exit } on && /^(::: |## )/ { exit } on')
  [ -n "$e" ] || fail "$i has no entry"
  printf '%s\n' "$e" | grep -qx 'It fails if:' || fail "$i has no It fails if:"
  printf '%s\n' "$f" | awk '{ s = $0; d = 0; c = ""; i = 1; L = length(s)
      while (i <= L) { ch = substr(s, i, 1); if (ch == "(") d++; else if (ch == ")" && d > 0) d--
        if (d == 0) { if (substr(s, i, 5) == "; or " || substr(s, i, 5) == ", or ") { print c; c = ""; i += 5; continue }
          if (substr(s, i, 4) == " or ") { print c; c = ""; i += 4; continue } }
        c = c ch; i++ } print c }' | while IFS= read -r a; do printf '%s\n' "$e" | grep -qxF -- "- $a" || fail "$i: the way to fail \"$a\" is not one line"; done
done < "$T/fi"
# marks: must never break on the T0 items, a ViD decision on the provisional ones
[ "$(printf '%s\n' "$body" | grep -cx 'Must never break')" = 2 ] || fail 'not two "Must never break"'
[ "$(printf '%s\n' "$body" | grep -cx 'Rests on a ViD decision')" = 3 ] || fail 'not three "Rests on a ViD decision"'
for i in inv-001 inv-002; do printf '%s\n' "$body" | awk -v a="{at: $i}" '$0 == a { on = 1; next } on && /^\{at: / { exit } on' | grep -qx 'Must never break' || fail "$i is not marked must never break"; done
for i in req-003 req-006 inv-002; do printf '%s\n' "$body" | awk -v a="{at: $i}" '$0 == a { on = 1; next } on && /^\{at: / { exit } on' | grep -qx 'Rests on a ViD decision' || fail "$i is not marked as resting on a ViD decision"; done
# the features, each with its --pause counts
sh "$CHECKS/prd.sh" PRD.md --pause 2>/dev/null | grep -E '^  FEAT-[0-9]+ \|' > "$T/fe" || true
[ "$(grep -c . "$T/fe")" = 3 ] || fail 'the fixture does not have three features'
while IFS='|' read -r id g n pd t0; do n=$(echo $n); pd=$(echo $pd | sed 's/pilot demand //'); t0=$(echo $t0 | sed 's/T0 //')
  w=requirements; [ "$pd" = 1 ] && w=requirement
  sec 'The features' | grep -qxF "::: fold $n — $pd $w in the first version, $t0 must never break {id: $(echo $id)}" || fail "the feature $n is not headed with its counts"; done < "$T/fe"
printf '%s\n' "$body" | grep -qxF '::: fold Beyond the features' || fail 'the items under no feature have no block'
# the decisions: yours and ViD's, never mixed
Y=$(sec Decisions | awk '/^### Yours$/ { on = 1; next } /^### / { on = 0 } on'); V=$(sec Decisions | awk "/^### ViD's\$/ { on = 1; next } /^### / { on = 0 } on")
for a in A-001 A-002 A-003 A-004 A-006 A-008 A-009; do printf '%s\n' "$Y" | grep -qF "{id: $a}" || fail "$a is not under Yours"; printf '%s\n' "$V" | grep -qF "{id: $a}" && fail "$a is under ViD's"; done
for a in A-005 A-007 A-010; do printf '%s\n' "$V" | grep -qF "{id: $a}" || fail "$a is not under ViD's"; printf '%s\n' "$Y" | grep -qF "{id: $a}" && fail "$a is under Yours"; done
printf '%s\n' "$V" | grep -F '{id: A-005}' | grep -q 'you have seen this' && printf '%s\n' "$V" | grep -F '{id: A-010}' | grep -q 'not shown to you yet' || fail "ViD's answers are not marked seen or not"
# the open questions; the qualities, the one ruled out last
O=$(sec 'Open questions'); printf '%s\n' "$O" | grep -qF '{id: OQ-1}' && printf '%s\n' "$O" | grep -qF '{id: OQ-3}' || fail 'an open question is missing'
printf '%s\n' "$O" | grep -qF 'OQ-2' && fail 'a resolved question is listed as open'
Q=$(sec 'The qualities it must have' | grep '^- ')
[ "$(printf '%s\n' "$Q" | grep -c .)" = 6 ] || fail 'not six qualities'
printf '%s\n' "$Q" | tail -n 1 | grep -q 'Technical SEO contract.*Not needed (your ruling)' || fail 'the quality ruled out is not last, as not needed'
[ "$(printf '%s\n' "$Q" | grep -c 'Needs it')" = 5 ] || fail 'not five qualities needed'
# the summary as written; history under its warning; the ratification lines
sec 'The summary' | grep -qF 'JobDigest merges two job feeds into one deduplicated listing store' || fail 'the summary is not as written'
H=$(sec 'History: what changed after the final wording was agreed')
printf '%s\n' "$H" | grep -qxF 'Wording here may have been replaced since. Parts 2 to 6 show what holds now.' || fail 'the history has no warning'
printf '%s\n' "$H" | grep -qxF '::: fold 2026-08-29 (owner answer)' && printf '%s\n' "$H" | grep -qxF '::: fold 2026-08-30 (owner answer)' || fail 'an append is not its own block'
[ "$(sec 'When it was agreed' | grep -c '^- 2026-08-2')" = 3 ] || fail 'the ratification lines are not shown'
[ -f .vid/pages/PRD.html ] || fail 'no html'
# a ViD answer revised since it was shown is not said to be seen: its shown: sum no longer matches its words
sed 's/A: cap at ten saved searches per subscriber for MVP/A: cap at twelve saved searches per subscriber for MVP/' PRD.md > P.x && mv P.x PRD.md
sh "$CHECKS/pages.sh" prd > "$T/out" 2>&1 || fail 'prd with a revised answer failed'
grep -F '{id: A-005}' "$M" | grep -qF 'twelve' || fail 'the revised answer is not shown'
grep -F '{id: A-005}' "$M" | grep -qF 'you have seen this' && fail 'an answer revised since it was shown is said to be seen'
grep -F '{id: A-007}' "$M" | grep -qF 'you have seen this' || fail 'an answer shown as it stands is not said to be seen'
# the older grammar: five positions (the priority column), the header line under the seed, read as prd.sh reads it
mkdir "$T/old"; cd "$T/old"; mkdir .vid
awk '{ print } /^## Seed$/ { print ""; print "grammar: 0.9.4" }' "$CHECKS/selftest/fixtures/prd-known-good.md" > PRD.md
sh "$CHECKS/pages.sh" prd > "$T/out" 2>&1 || fail 'prd in the older grammar failed'
grep -qE '^\*\*P[0-9]\*\* ' "$M" && fail 'a requirement shows its priority in place of its words'
sh "$CHECKS/prd.sh" --effective PRD.md | awk -F'|' '$1 ~ /^(REQ|INV)-/ { s = $5; gsub(/^ +| +$/, "", s); print s }' > "$T/st"
[ -s "$T/st" ] || fail 'the older fixture holds no requirement'
while IFS= read -r s; do grep -qxF "**$s** {id: $(grep -F "| $s |" PRD.md | head -n 1 | cut -d' ' -f1)}" "$M" || fail "a requirement in the older grammar is not shown by its words: $s"; done < "$T/st"
exit 0
