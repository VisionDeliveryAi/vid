#!/bin/sh
# Purpose: selftest case — a refused commit says every reason at once (FB-4 C2). A toy ViD project with the real hooks
# and courts; one uncommitted change with five faults — an ARCHITECTURE.md law change staged with other files, a PRD
# append with a 39-word plain sentence, one arms: entry for two arms and no review: line, a DECISIONS line with two
# labels, and a human answer whose message needs Owner: — is refused once, by=law-standalone,decisions-label,prd,append-review,
# with each reason, the order of commits (architecture, PRD, inventory, DECISIONS with the rest) and what the message
# needs; the index and its attempt give one refused event. Repaired as it says and committed in that order, each commit
# lands at its first try: the decision's label is a row the INVENTORY commit adds. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/spec-only.sh"
fail() { echo "hook-says-every-reason: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
so_tree "$T/p"; cd "$T/p"
awk 'NR <= 3 && /^grammar: 0\.9\.4$/ { print "grammar: 0.9.5"; next }
  /^## Ratifications/ { print "### 2026-08-30 — final review\n\nreview: final, round 1, 0 findings, read: PRD.md ARCHITECTURE.md DECISIONS.md BASELINE.md INVENTORY.md GRADING-CHECKLIST.md\n" }
  /^(REQ|INV)-[0-9]+( AMENDED)? \|/ { print $0 " | plain: The owner reads this rule in plain words"; next } { print }' "$CHECKS/selftest/fixtures/prd-094-good.md" > PRD.md
so_commit 'the spec' > "$T/out" 2>&1 || fail 'the toy spec commit was refused'
# the whole change, finished, kept aside; then the same with its five faults in the working tree
mkdir -p "$T/new"
ROW=$(grep '^REQ-012 ' PRD.md | sed 's/^REQ-012 /REQ-012 AMENDED /; s/mail to it bounces/mail to it bounces twice in one week/; s/ | plain: .*//')
prd() { # <plain> <arms> <review and findings>
  git show HEAD:PRD.md; printf '\n### 2026-09-02 (owner answer)\n\n```vid-prd-answers\nA-100 | human | 2026-09-02 | Q: may the footer bounce once? | A: yes, once | settles: REQ-012\n```\n\n```vid-prd\n%s | plain: %s | arms: %s\n```\n%s\n' "$ROW" "$1" "$2" "$3"; }
prd 'Every digest names an address that answers' '1 retained, 2 withdrawn A-100' '
review: delta, round 1, 1 findings

```vid-prd-findings
F-06 | review | blocking | REQ-012 | accepted A-100 | evidence: arm 2 — one bounce passes now
```' > "$T/new/PRD.md"
awk '{ print } /^\| app\/notes \|/ { print "| app/digest | digests | digests | `app.digest.api` | none |" }' ARCHITECTURE.md > "$T/new/ARCHITECTURE.md"
awk '{ print } /^ROW-005 / { print "ROW-006 | behavior | REQ-002 | anonymous | n/a | a digest names its support address | REQ-002 | owed: spec-only — first stage" }' INVENTORY.md > "$T/new/INVENTORY.md"
D='- **D-001** the footer address is written by the digest module | why: one place | enforced: convention | applies-to: ROW-006'
{ cat DECISIONS.md; printf '%s\n' "$D"; } > "$T/new/DECISIONS.md"
cp "$T/new/ARCHITECTURE.md" "$T/new/INVENTORY.md" .
{ cat DECISIONS.md; printf '%s | scope: project\n' "$D"; } > D.t && mv D.t DECISIONS.md
prd 'one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix twentyseven twentyeight twentynine thirty thirtyone thirtytwo thirtythree thirtyfour thirtyfive thirtysix thirtyseven thirtyeight thirtynine' '1 retained' '' > P.t && mv P.t PRD.md
# draft: the message as a first try writes it
: > .vid/metrics-events
if so_commit 'the change' > "$T/out" 2>&1; then fail 'the change with five faults was committed'; fi
[ "$(grep -c '^refused ' .vid/metrics-events)" = 1 ] || fail 'not one refused event for the attempt'
grep -q '^refused phase=pre-commit by=law-standalone,decisions-label,prd,append-review ' .vid/metrics-events || fail "the event does not name every reason: $(grep '^refused ' .vid/metrics-events)"
[ "$(tail -n 1 .vid/hook-times | sed -n 's/.* by=\([^ ]*\) .*/\1/p')" = law-standalone,decisions-label,prd,append-review ] || fail 'hook-times does not name every reason'
for m in 'this commit changes law and must touch nothing else' 'more than one label' 'join 21 (REQ-012)' 'join 14 (REQ-012 AMENDED): arms: carries 1' 'no review: line' \
  'refused by: law-standalone decisions-label prd append-review'; do grep -qF "$m" "$T/out" || fail "the refusal does not say: $m"; done
printf '  1. ARCHITECTURE.md\n  2. PRD.md\n  3. INVENTORY.md\n  4. DECISIONS.md\n' > "$T/order"
grep -A 4 '^The order of commits the law asks for' "$T/out" | sed 1d | cmp -s - "$T/order" || fail 'the order of commits is not the four lines'
grep -q 'the message needs' "$T/out" && grep -q '    Owner: "<the owner' "$T/out" || fail 'the refusal does not say the message needs Owner:'
# repaired, in that order
git reset -q --hard
n=0; for f in ARCHITECTURE.md PRD.md INVENTORY.md DECISIONS.md; do n=$((n + 1)); cp "$T/new/$f" "$f"
  tr=''; [ "$f" != PRD.md ] || tr='Owner: "yes, once"'
  so_commit "part $n: $f" "$tr" > "$T/out" 2>&1 || fail "part $n ($f) was refused"; done
[ -z "$(git status --porcelain)" ] || fail 'the change is not wholly committed'
[ "$(grep -c '^refused ' .vid/metrics-events)" = 1 ] || fail 'a commit made in the order was refused'
exit 0
