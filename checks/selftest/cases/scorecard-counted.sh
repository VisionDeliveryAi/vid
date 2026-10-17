#!/bin/sh
# Purpose: selftest case — the PRD scorecard's counted half (v0.9.5 part B,
# R1-R2, R5, §3-4; phase A). The 0.9.4 good fixture raised to 0.9.5 with a
# plain sentence on every rule is the previous version; the current version
# drops INV-002, lowers INV-001 from T0 to T1, removes REQ-006's fail-if and
# REQ-012's plain sentence, adds a human answer, changes A-001's owner text,
# promotes A-005 to human and adds a ViD decision. Convicts unless the
# scorecard counts exactly those (gone 1, weaker 1, no fail-if 1, no plain
# 1, added 1, changed 1, promoted 1, new ViD decisions 1) and flags them;
# the same file against itself shows zeros and no flags; with no previous
# version every comparison shows "-", and against the pause-1 PRD growth
# shows "-"; under 0.9.4 plain sentences are not
# counted; --candidates lists the gone and weaker rules, the ViD decisions
# (not an answer promoted to the owner), the rules citing an owner answer and
# every demand item; --tally flags a lost rule, builder settings over 20% and
# an unanswered candidate, and not a kept rule; a pause-1 PRD and a legacy
# block-form PRD are not scored; and it
# exits 0 on a PRD the court refuses. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
SC="$CHECKS/scorecard.sh"
fail() { echo "scorecard-counted: $*" >&2; exit 1; }
has() { grep -qF -- "$2" "$1" || { sed -n 1,12p "$1" >&2; fail "missing '$2'"; }; }
awk 'NR <= 3 && /^grammar: 0\.9\.4$/ { print "grammar: 0.9.5"; next }
  /^(REQ|INV)-[0-9]+( AMENDED)? \|/ { print $0 " | plain: The owner reads this rule in plain words"; next }
  { print }' "$CHECKS/selftest/fixtures/prd-094-good.md" > prev.md
grep -q '^grammar: 0.9.5$' prev.md || fail 'the fixture has no 0.9.4 header to raise'
awk '/^INV-002 \|/ { next }
  /^INV-001 \|/ { sub(/\| T0 \|/, "| T1 |") }
  /^REQ-006 \|/ { sub(/ \| fail-if: [^|]*/, "") }
  /^REQ-012 \|/ { sub(/ \| plain: [^|]*$/, "") }
  /^A-001 \|/ { sub(/A: per search/, "A: per search, sent at seven") }
  /^A-005 \|/ { sub(/\| model_proposed \|/, "| human |") }
  /^A-009 \|/ { print; print "A-010 | human | 2026-09-01 | Q: may a subscriber pause digests? | A: yes, for up to a month | settles: REQ-001"; print "A-011 | model_proposed | 2026-09-01 | Q: how long is a pause? | A: thirty days | settles: REQ-001"; next }
  { print }' prev.md > cur.md
[ "$(grep -c '^A-01[01] |' cur.md)" = 2 ] || fail 'the fixture has no A-009 row to append after'

sh "$SC" cur.md --previous prev.md > out.txt || fail 'the scorecard exited non-zero'
has out.txt 'added=1 promoted=1 changed=1'
has out.txt 'ViD decisions=2 (new since the previous version=1)'
has out.txt 'previous rules gone=1 · previous rules weaker=1'
has out.txt 'demand items with no fail-if=1'
has out.txt 'rules with no plain sentence=1 of'
has out.txt 'complete (previous rules gone): INV-002(T0)'
has out.txt 'complete (previous rules weaker): INV-001(T0→T1)'
has out.txt 'owner-record changes: added A-010 · promoted A-005 · changed A-001'
has out.txt 'flags: previous rules gone 1, previous rules weaker 1, demand items with no fail-if 1, rules with no plain sentence 1'

sh "$SC" prev.md --previous prev.md > same.txt || fail 'the scorecard exited non-zero on an unchanged PRD'
has same.txt 'added=0 promoted=0 changed=0'
has same.txt 'previous rules gone=0 · previous rules weaker=0'
has same.txt 'growth since the previous version=+0 (+0%)'
has same.txt 'flags: none'

sh "$SC" cur.md > nop.txt || fail 'the scorecard exited non-zero with no previous version'
has nop.txt 'added=- promoted=- changed=-'
has nop.txt 'previous rules gone=- · previous rules weaker=-'
has nop.txt 'growth since the previous version=- '

sed 's/^grammar: 0\.9\.5$/grammar: 0.9.4/' cur.md > cur4.md
sh "$SC" cur4.md --previous prev.md > g4.txt || fail 'the scorecard exited non-zero under 0.9.4'
has g4.txt 'rules with no plain sentence=- (plain sentences apply from grammar 0.9.5)'
grep -q 'flags:.*plain' g4.txt && fail 'a missing plain sentence flagged under grammar 0.9.4'

# phase C: the reader's candidates, and the tally of its answers
sh "$SC" cur.md --previous prev.md --candidates cands.txt > /dev/null || fail 'the scorecard exited non-zero writing candidates'
grep -q '^[0-9]* | complete | INV-002 | INV-002 \[T0\]: ' cands.txt || fail 'the gone rule is not a complete candidate with its text'
grep -q '^[0-9]* | complete | INV-001 | ' cands.txt || fail 'the weaker rule is not a complete candidate'
[ "$(grep -c '^[0-9]* | honest | ' cands.txt)" = 2 ] || fail 'the ViD decisions (A-007, A-011) are not the honest candidates'
grep -q '^[0-9]* | honest | A-005 | ' cands.txt && fail 'an answer promoted to the owner is still a ViD decision candidate'
grep -q '^[0-9]* | faithful | REQ-001~A-001 | ' cands.txt || fail 'a rule citing an owner answer is not a faithful candidate'
[ "$(grep -c '^[0-9]* | product-level | ' cands.txt)" = 9 ] || fail 'not every demand item is a product-level candidate'
awk -F'|' '{ n = $1 + 0; q = $2; gsub(/ /, "", q); c = "distinct"
  if (q == "complete") c = ($3 ~ /INV-002/) ? "lost" : "kept"
  if (q == "honest") c = "builder setting"
  if (q == "faithful") c = "agrees"
  if (q == "product-level") c = "product"
  if (q == "testable") c = "observable"
  if (q == "right-grained") c = "one rule"
  if (n > 1) print n " | " c " | - | a reason" }' cands.txt > reader.txt
sh "$SC" --tally cands.txt reader.txt > tally.txt || fail 'the tally exited non-zero'
has tally.txt 'complete/lost 1: INV-002'
has tally.txt 'builder settings 2 of 2 ViD decisions, over 20% (0.9.4 bar 4)'
has tally.txt 'candidates the reader did not answer 1: 1'
grep -q 'complete/kept' tally.txt && grep 'judged flags' tally.txt | grep -q 'kept' && fail 'a kept rule flagged'

awk '/^```vid-prd$/ { skip = 1; next } skip && /^```$/ { skip = 0; next } !skip' prev.md > p1.md
sh "$SC" p1.md > p1.txt || fail 'the scorecard exited non-zero on a pause-1 PRD'
has p1.txt 'no items yet'
sh "$SC" cur.md --previous p1.md > vs1.txt || fail 'the scorecard exited non-zero against a pause-1 previous version'
has vs1.txt 'growth since the previous version=- '
has vs1.txt 'ViD decisions=2 (new since the previous version=1)'
printf '# PRD\n\n### REQ-001 A rule\n\nfail-if: it breaks\n' > legacy.md
sh "$SC" legacy.md > lg.txt || fail 'the scorecard exited non-zero on a legacy PRD'
has lg.txt 'not scored — a legacy block-form PRD'
exit 0
