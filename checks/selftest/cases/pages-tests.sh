#!/bin/sh
# Purpose: selftest case — the test list as a page (usability, B5). On the full pages' toy (fixtures/pages-toy.sh
# pg_full: the planner's toy with an entry of every kind, one test waiting on the owner's decision (ROW-018), one owed
# with no class (ROW-012), and six strength findings: one open, one repaired, one repaired and one open about entries
# the list no longer holds, one overruled, one noted about a requirement), `pages.sh tests` writes .vid/pages/TESTS.md:
# the head ("This list has N tests. You are asked to approve it, not to read every line.", N and each count by kind
# equal to the entries of parts 4 and 5); every entry of INVENTORY.md has exactly one full entry, in part 4, 5 or 6; a
# test under a feature is under the feature of the first requirement it names, the rest "Across the whole product";
# "Look here first" links the two entries that need the owner and lists the two open strength findings, the gone one
# by its id, hidden as every id is, and "No current entry"; "Ways the product could be wrong" holds all six, the open
# first, then the repaired, then the rest, each "Nothing catches this yet", "Repaired", "Your ruling" or "Noted" as its
# row says, "No current entry" only for an entry of the list, the one with no evidence "No detail was recorded."; the
# grading checklist as written; nowhere does the page say the list was reviewed or read. With no strength finding,
# "No finding of ViD's strength check is recorded for this list." and no part 3. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-tests: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
pg_full "$T/toy"
# an attack that protects two entries, separated by a space as inventory.sh reads them
sed 's/| protects: ROW-002 |/| protects: ROW-002 RULE-001 |/' INVENTORY.md > I.x && mv I.x INVENTORY.md
sh "$CHECKS/pages.sh" tests > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'tests failed'; }
M=.vid/pages/TESTS.md; [ -f "$M" ] && [ -f .vid/pages/TESTS.html ] || fail 'no page'
sec() { awk -v h="## $1" '$0 == h { on = 1; next } on && /^## / { exit } on' "$M"; }
[ "$(grep '^## ' "$M" | tr '\n' '/')" = '## Look here first/## Ways the product could be wrong/## By feature/## Rules checked across the product, and the attacks tried/## What is deliberately not tested/## The grading checklist/' ] || fail "the parts: $(grep '^## ' "$M" | tr '\n' '/')"
# every entry once, in part 4, 5 or 6
sed -n '/^```vid-inventory$/,/^```$/p' INVENTORY.md | grep -v '^```' | grep -v '^grammar:' | awk -F'|' '{ a = $1; gsub(/ /, "", a); if (a !~ /^ROW-/) { a = $2; gsub(/ /, "", a) } print a }' > "$T/ids"
[ "$(grep -c . "$T/ids")" = 38 ] || fail "the toy does not hold 38 entries: $(grep -c . "$T/ids")"
full=$(awk '/^## By feature$/ { on = 1 } /^## The grading checklist$/ { on = 0 } on' "$M")
while IFS= read -r i; do l=$(printf '%s' "$i" | tr 'A-Z' 'a-z')
  [ "$(printf '%s\n' "$full" | grep -cxF "{at: $l}")" = 1 ] || fail "$i has not exactly one full entry"
  [ "$(printf '%s\n' "$full" | grep -cF "{id: $i}")" = 1 ] || fail "$i is shown in full more than once"; done < "$T/ids"
[ "$(printf '%s\n' "$full" | grep -c '^{at: ')" = 38 ] || fail 'a full entry is for no entry of the list'
# N and the counts by kind: the entries of parts 4 and 5
p45=$(awk '/^## By feature$/ { on = 1 } /^## What is deliberately not tested$/ { on = 0 } on' "$M")
n=$(printf '%s\n' "$p45" | grep -c '^{at: ')
grep -qxF "This list has $n tests. You are asked to approve it, not to read every line." "$M" || fail "the head does not say $n tests"
[ "$n" = 32 ] || fail "parts 4 and 5 hold $n entries, not the toy's 32"
kinds=$(awk '/^## /{exit} /^Behaviours: /' "$M")
kc() { printf '%s\n' "$p45" | grep -cxF "Kind: $1"; }
[ "$kinds" = "Behaviours: $(kc 'a behaviour') · Screens as drawn: $(kc 'a screen as drawn') · Journeys: $(kc 'a journey') · The parts on every page: $(kc 'the parts on every page') · Ways to reach a screen: $(kc 'a way to reach a screen') · Rules: $(kc 'a rule checked across the product') · Attacks tried: $(kc 'an attack tried') · Outside services: $(kc "an outside service's contract")" ] || fail "the counts by kind: $kinds"
s=0; for x in $(printf '%s\n' "$kinds" | grep -oE '[0-9]+'); do s=$((s + x)); done; [ "$s" = "$n" ] || fail 'the counts by kind do not add up to N'
# each test under the feature of the first requirement it names
sh "$CHECKS/prd.sh" --effective PRD.md | awk -F'|' '{ i = $1; gsub(/ /, "", i); f = ""; for (k = 2; k <= NF; k++) if ($k ~ /^ *feature:/) { f = $k; sub(/^ *feature: */, "", f); sub(/ *$/, "", f) } print i, f }' > "$T/feat"
sed -n '/^```vid-prd-features$/,/^```$/p' PRD.md | grep '^FEAT-' | awk -F'|' '{ i = $1; n = $3; gsub(/^ +| +$/, "", i); gsub(/^ +| +$/, "", n); print i "|" n }' > "$T/fn"
printf '%s\n' "$p45" | awk '/^::: fold / { f = substr($0, 10); sub(/ — [0-9]+ tests?$/, "", f) } /^\{at: row-/ { print f "|" substr($0, 6, 7) }' > "$T/placed"
while IFS='|' read -r fname row; do R=$(printf '%s' "$row" | tr 'a-z' 'A-Z')
  first=$(awk -F'|' -v r="$R" '{ a = $1; gsub(/ /, "", a) } a == r { d = $7; n = split(d, x, ","); for (k = 1; k <= n; k++) { gsub(/ /, "", x[k]); if (x[k] ~ /^(REQ|INV)-/) { print x[k]; exit } } }' INVENTORY.md)
  want='Across the whole product'; if [ -n "$first" ]; then fe=$(awk -v i="$first" '$1 == i { print $2 }' "$T/feat"); [ -n "$fe" ] && want=$(awk -F'|' -v i="$fe" '$1 == i { print $2 }' "$T/fn"); fi
  [ "$fname" = "$want" ] || fail "$R is under '$fname', not '$want'"; done < "$T/placed"
# look here first: what needs the owner, and the open strength findings
L=$(sec 'Look here first')
printf '%s\n' "$L" | grep -F '](#row-018)' | grep -qF 'owner-decision — OQ-3' || fail 'the test waiting on the owner is not linked first'
printf '%s\n' "$L" | grep -F '](#row-012)' | grep -qF 'waiting on the partner' || fail 'the owed test with no class is not linked first'
printf '%s\n' "$L" | grep -F '](#row-007)' | grep -qF 'never stops the digests' || fail 'the open strength finding is not listed first'
printf '%s\n' "$L" | grep -F '{id: ROW-098}' | grep -qF 'No current entry' || fail 'the open finding about a gone entry is not listed by its hidden id'
printf '%s\n' "$L" | grep '^- Nothing catches' | sed 's/{id: [^}]*}//g' | grep -qE '(^|[^A-Za-z])[A-Z]{1,6}-[0-9]+' && fail 'a finding in look here first shows an id bare'
printf '%s\n' "$L" | grep -qE 'footer whose support|ROW-099|once a week|wider than' && fail 'a finding not open is listed first'
[ "$(printf '%s\n' "$L" | grep -c '^- ')" = 4 ] || fail 'look here first does not hold four lines'
# ways the product could be wrong: all six, open, then repaired, then the rest, each as its row says
W=$(sec 'Ways the product could be wrong' | grep '^- ')
[ "$(printf '%s\n' "$W" | grep -c .)" = 6 ] || fail 'not six ways the product could be wrong'
[ "$(printf '%s\n' "$W" | sed -n '1,2p' | grep -c 'Nothing catches this yet$')" = 2 ] && [ "$(printf '%s\n' "$W" | sed -n '3,4p' | grep -c 'Repaired$')" = 2 ] || fail 'the open ones and then the repaired ones do not come first'
printf '%s\n' "$W" | sed -n 5p | grep -F 'once a week' | grep -q 'Your ruling$' && printf '%s\n' "$W" | sed -n 6p | grep -F 'wider than' | grep -q 'Noted$' || fail 'a finding ruled on or noted is not said so, after the rest'
printf '%s\n' "$W" | grep -F 'wider than' | grep -qF 'No current entry' && fail 'a finding about something not in the list says no current entry'
printf '%s\n' "$W" | grep -F '{id: ROW-099}' | grep -qF 'No current entry' || fail 'a finding about a dropped entry is left off'
printf '%s\n' "$W" | grep -F '{id: ROW-098}' | grep -qF 'No detail was recorded.' || fail 'a finding with no evidence does not say so'
grep -qiE 'caught by|catches it|is caught' "$M" && fail 'the page names a test as catching a finding'
printf '%s\n' "$full" | grep '^It protects: ' | sed 's/{id: [^}]*}//g; s/](#[^)]*)//g' | grep -qE '(^|[^A-Za-z#-])[A-Z]{1,6}-[0-9]+' && fail 'what an attack protects shows an id bare'
printf '%s\n' "$full" | grep -qF 'It protects: [A subscriber can keep up to ten saved searches' || fail 'what an attack protects is not named in words'
# the entries say what is not tested yet, the kinds in plain words; the grading checklist as written
printf '%s\n' "$full" | grep -qxF 'Not tested yet: guard-first — the protection HOS-002 does not exist yet; paid in the slice that builds it' || fail 'an owed reason is not given as the list gives it'
sec 'The grading checklist' | grep -qF '**Digest repeats.** Check that no job reaches the same search' || fail 'the grading checklist is not as written'
# never reviewed or read
grep -iE 'reviewed|you read|have read|was read' "$M" | grep -vxF "This list has $n tests. You are asked to approve it, not to read every line." | grep -q . && fail 'the page says the list was reviewed or read'
# 0.26.10.29.4: the strength check's findings as it writes them (INIT-FIXES-3 R1, the lens brief): a target that lists
# every entry of a disagreement, comma-separated; a requirement beside the test of it; another document by its name
awk '{ print } /^F-15 \| strength/ { print "F-16 | strength | blocking | INVENTORY.md:ROW-002, INVENTORY.md:ROW-007 | | evidence: the two entries disagree on when the digests stop"
  print "F-17 | strength | advisory | GRADING-CHECKLIST.md | noted | evidence: a checklist line no finite test can measure"
  print "F-18 | strength | blocking | REQ-002, INVENTORY.md:ROW-003 | | evidence: the new words let a late digest through" }' PRD.md > P.x && mv P.x PRD.md
sh "$CHECKS/pages.sh" tests > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'tests with the strength check'"'"'s own target forms failed'; }
L=$(sec 'Look here first'); W=$(sec 'Ways the product could be wrong')
printf '%s\n' "$L" | grep -F 'disagree on when the digests stop' | grep -F '](#row-002)' | grep -qF '](#row-007)' || fail 'a finding about two entries does not link both'
printf '%s\n' "$L" | grep -F 'disagree on when the digests stop' | grep -qF 'No current entry' && fail 'a finding about two entries that are both here says no current entry'
printf '%s\n' "$L" | grep -F 'let a late digest through' | grep -F '](#row-003)' | grep -qF '{id: REQ-002}' || fail 'a finding about a requirement and its test does not link the test and keep the requirement by its hidden id'
printf '%s\n' "$W" | grep -F 'no finite test can measure' | grep -qF 'the grading checklist' || fail 'a finding about the grading checklist does not name it'
printf '%s\n' "$W" | grep -F 'no finite test can measure' | grep -qF 'a part of the PRD' && fail 'a finding about another document is called a part of the PRD'
printf '%s\n%s\n' "$L" "$W" | sed 's/{id: [^}]*}//g' | grep -E 'disagree on when|late digest|finite test' | grep -qE '(^|[^A-Za-z])[A-Z]{1,6}-[0-9]+|\.md' && fail 'a finding with a listed target shows an id or a file name bare'
# before the strength check: no finding of its pass
awk '!/\| strength \|/' PRD.md > P.x && mv P.x PRD.md
sh "$CHECKS/pages.sh" tests > "$T/out" 2>&1 || fail 'tests with no strength finding failed'
sec 'Look here first' | grep -qxF "No finding of ViD's strength check is recorded for this list." || fail 'with no strength finding, it does not say none is recorded'
grep -qxF '## Ways the product could be wrong' "$M" && fail 'with no strength finding, part 3 is not left out'
exit 0
