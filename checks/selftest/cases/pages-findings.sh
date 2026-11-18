#!/bin/sh
# Purpose: selftest case — the findings as a page (usability, B4). On the pages' toy, with an append's findings block
# adding a row with no disposition and no evidence, one overruled, and one routed to a question since resolved:
# `pages.sh findings` writes .vid/pages/FINDINGS.md with four groups in order (still open: no disposition, or routed to
# a question still open; fixed: repaired; your rulings: overruled or accepted; noted: the rest), every findings row of
# PRD.md in exactly one, the head's count of each group equal to its entries, and each entry from its row only: which
# review found it, how serious, what it is about, its evidence, or "No detail was recorded." Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-findings: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
pg_toy "$T/toy"
cat >> PRD.md <<'MD'

### 2026-08-30 (a later sitting)

```vid-prd-findings
F-06 | review | advisory | REQ-001 |
F-07 | review | blocking | REQ-005 | overruled A-001 | evidence: the timestamp rule reads as two rules
F-08 | audit | advisory | thesis | routed OQ-2 | evidence: one job twice was undecided
```
MD
sh "$CHECKS/pages.sh" findings > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'findings failed'; }
M=.vid/pages/FINDINGS.md; [ -f "$M" ] && [ -f .vid/pages/FINDINGS.html ] || fail 'no page'
sec() { awk -v h="## $1" '$0 == h { on = 1; next } on && /^## / { exit } on' "$M"; }
[ "$(grep '^## ' "$M" | tr '\n' '/')" = '## Still open/## Fixed/## Your rulings/## Noted/' ] || fail "the groups are not the four, in order: $(grep '^## ' "$M" | tr '\n' '/')"
ids() { sec "$1" | grep -oE '\{id: F-[0-9]+\}' | tr -d '{}' | sed 's/id: //' | tr '\n' ' '; }
[ "$(ids 'Still open')" = 'F-01 F-06 ' ] || fail "still open: $(ids 'Still open')"
[ "$(ids Fixed)" = 'F-03 F-05 ' ] || fail "fixed: $(ids Fixed)"
[ "$(ids 'Your rulings')" = 'F-04 F-07 ' ] || fail "your rulings: $(ids 'Your rulings')"
[ "$(ids Noted)" = 'F-02 F-08 ' ] || fail "noted: $(ids Noted)"
# every row of PRD.md in exactly one group
sed -n '/^```vid-prd-findings$/,/^```$/p' PRD.md | grep -oE '^F-[0-9]+' | sort > "$T/rows"
grep -oE '\{id: F-[0-9]+\}' "$M" | sed 's/{id: //; s/}//' | sort > "$T/page"
cmp -s "$T/rows" "$T/page" || fail 'a findings row is in no group, or in two'
# the head's counts equal the groups' entries
[ "$(awk '/^## /{exit} /^Still open: /' "$M")" = 'Still open: 2 · Fixed: 2 · Your rulings: 2 · Noted: 2' ] || fail "the head's counts: $(awk '/^## /{exit} /^Still open: /' "$M")"
for g in 'Still open' Fixed 'Your rulings' Noted; do [ "$(sec "$g" | grep -c '{id: F-')" = 2 ] || fail "$g does not hold two entries"; done
# each entry from its row only
e() { grep -F "{id: $1}" "$M"; }
e F-06 | grep -qF 'No detail was recorded.' || fail 'a row with no evidence does not say so'
[ "$(grep -cF 'No detail was recorded.' "$M")" = 1 ] || fail 'a row with evidence says no detail was recorded'
e F-07 | grep -qF 'Blocking' && e F-07 | grep -qF 'found by the review' && e F-07 | grep -qF 'the timestamp rule reads as two rules' || fail "F-07's entry is not its row"
e F-01 | grep -qF 'found by the red team' && e F-04 | grep -qF 'found by the completeness audit' && e F-05 | grep -qF 'found by an expert reading' || fail 'an entry does not say which review found it'
e F-02 | grep -qF 'Advisory' && e F-02 | grep -qF 'about the summary' || fail "F-02's entry is not its row"
e F-03 | grep -qF 'repaired by the REQ-002 AMENDED append' || fail "F-03's evidence is not as written"
grep -qiE 'was changed to|the repair (changed|made)' "$M" && fail 'the page states what a repair changed'
# 0.26.10.29.4: targets and passes written since 0.26.10.29.3 (INIT-FIXES-2 R3 and R6): another document by its name,
# an answer, and the final review as a pass
cat >> PRD.md <<'MD'

### 2026-09-02 (the final review)

```vid-prd-findings
F-30 | final | advisory | ARCHITECTURE.md, BASELINE.md | noted | evidence: the two give different retention periods
F-31 | final | advisory | GRADING-CHECKLIST.md | noted | evidence: a line no finite test can measure
F-32 | review | advisory | A-001 | noted | evidence: the answer still states the rule the later one retired
```
MD
sh "$CHECKS/pages.sh" findings > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'findings with the later target forms failed'; }
x30=$(grep -F '{id: F-30}' "$M"); x31=$(grep -F '{id: F-31}' "$M"); x32=$(grep -F '{id: F-32}' "$M")
printf '%s\n' "$x30" | grep -qF 'the architecture' && printf '%s\n' "$x30" | grep -qF 'the baseline' || fail 'a finding about two other documents does not name them'
printf '%s\n' "$x31" | grep -qF 'the grading checklist' || fail 'a finding about the grading checklist does not name it'
printf '%s\n%s\n%s\n' "$x30" "$x31" "$x32" | grep -qF 'no longer holds' && fail 'a finding about another document or an answer says the PRD no longer holds it'
printf '%s\n' "$x30" | grep -qF 'found by the final review' || fail 'the final review is not named as the pass'
printf '%s\n' "$x32" | grep -qF 'an answer' || fail 'a finding about an answer does not say so'
printf '%s\n%s\n' "$x30" "$x31" | sed 's/{id: [^}]*}//g' | grep -qE '\.md' && fail 'a document is shown by its file name'
exit 0
