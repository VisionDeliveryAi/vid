#!/bin/sh
# Purpose: selftest case — a kept label on an arm the owner accepted narrower is refused at the commit that adds it
# (FB-4 C1). Real commits with the real hooks, the PRD the 0.9.4 good fixture: an append rewording REQ-001's arm 1 and
# marking it `strengthened` (and `retained`) beside its own review row `accepted A-100` on arm 1 is refused
# (by=arm-accepted), the message naming `1 withdrawn A-100` and the other two ways out. Accepted: `withdrawn A-100`; the
# finding `overruled`; the arm word for word; a finding on two items; two AMENDED rows of the item in the section; an
# answer that is ViD's draft, or delegated. A violation committed with the hooks off never refuses a later append, and
# one merged in from a branch that holds it is not refused here. The AMENDED row is what the commit must add: the owner's
# ruling written later on a committed row's finding lands, with a correcting row beside it and without; a restoring row
# under a committed violation lands; an AMENDED row added under a committed accepted finding is refused. With a law file
# edited and not staged the arm is named beside it, but not when checks/prd.sh itself is the file. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
git config user.email vid@selftest; git config user.name vid
fail() { echo "arm-accepted-narrower-refused: $*" >&2; cat out.txt >&2 2>/dev/null; exit 1; }
mkdir -p checks/hooks app .vid
for c in placement.sh conformance.sh prd.sh lawfiles event.sh; do cp "$CHECKS/$c" checks/; done
for h in pre-commit commit-msg; do cp "$CHECKS/hooks/$h" checks/hooks/ && chmod +x "checks/hooks/$h"; done
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
cp "$CHECKS/selftest/fixtures/prd-094-good.md" PRD.md
printf '.vid/\nout.txt\n' > .gitignore
git add -A && git commit -qm 'root

Decisions: none — nothing surprising'
git config core.hooksPath checks/hooks
ROOT=$(git rev-parse HEAD)
R1=$(grep '^REQ-001 ' PRD.md | sed 's/^REQ-001 /REQ-001 AMENDED /')
NARROW=$(printf '%s\n' "$R1" | sed 's/already delivered for that search/already delivered for that search in the same week/')
ANS='A-100 | human | 2026-09-02 | Q: may a job repeat after a week? | A: yes, a later week may repeat it | settles: REQ-001'
FIND='F-06 | review | blocking | REQ-001 | accepted A-100 | evidence: arm 1 — a repeat in a later week passes now'
# append <answer> <item rows> <findings rows>
append() { printf '\n### 2026-09-02 (owner answer)\n\n```vid-prd-answers\n%s\n```\n\n```vid-prd\n%s\n```\n\nreview: delta, round 1, %s findings\n\n```vid-prd-findings\n%s\n```\n' "$1" "$2" "$(printf '%s\n' "$3" | grep -c .)" "$3" >> PRD.md; git add PRD.md; }
MSG='an append

Decisions: none — a probe
Owner: "yes, a later week may repeat it"'
door() { git reset -q --hard "$ROOT"; append "$@"; if git commit -qm "$MSG" > out.txt 2>&1; then echo ACCEPTED; else echo REFUSED; fi; }
taken() { [ "$(door "$2" "$3" "$4")" = ACCEPTED ] || fail "refused: $1"; }
for w in strengthened retained; do
  : > .vid/metrics-events; : > .vid/hook-times
  [ "$(door "$ANS" "$NARROW | arms: 1 $w, 2 retained" "$FIND")" = REFUSED ] || fail "arm 1 marked $w beside its accepted finding was committed"
  grep -q "REQ-001 AMENDED: arms: marks arm 1 $w, and F-06 records that the owner accepted it narrower: 1 withdrawn A-100" out.txt || fail "the refusal ($w) does not name the row, the finding and \`1 withdrawn A-100\`"
  grep -q 'restore the old words' out.txt && grep -q 'overruled A-NNN' out.txt || fail 'the refusal does not name the other two ways out'
  grep -q '^refused phase=pre-commit by=arm-accepted ' .vid/metrics-events || fail "not recorded by=arm-accepted ($w)"
  tail -n 1 .vid/hook-times | grep -q ' by=arm-accepted at=' || fail "hook-times does not say by=arm-accepted ($w)"
done
taken 'withdrawn A-100' "$ANS" "$NARROW | arms: 1 withdrawn A-100, 2 retained" "$FIND"
taken 'the finding overruled' "$ANS" "$NARROW | arms: 1 retained, 2 retained" "$(printf '%s\n' "$FIND" | sed 's/accepted/overruled/')"
taken 'the arm word for word' "$ANS" "$R1 | arms: 1 retained, 2 retained" "$FIND"
taken 'a finding on two items' "$ANS" "$NARROW | arms: 1 retained, 2 retained" "$(printf '%s\n' "$FIND" | sed 's/| REQ-001 |/| REQ-001, REQ-012 |/')"
taken 'two AMENDED rows of the item in the section' "$ANS" "$NARROW | arms: 1 retained, 2 retained
$NARROW | arms: 1 retained, 2 retained" "$FIND"
taken "ViD's draft" "$(printf '%s\n' "$ANS" | sed 's/| human |/| model_proposed |/')" "$NARROW | arms: 1 retained, 2 retained" "$FIND"
taken 'a delegated answer' "$ANS | delegated: yes" "$NARROW | arms: 1 retained, 2 retained" "$FIND"
# law edited and not staged: the arm is said in the same attempt, unless checks/prd.sh itself is what is edited
by() { sed -n 's/.* by=\([^ ]*\) .*/\1/p' .vid/hook-times | tail -n 1; }
dirty() { git reset -q --hard "$ROOT"; append "$ANS" "$NARROW | arms: 1 retained, 2 retained" "$FIND"; printf '# more\n' >> "$1"; if git commit -qm "$MSG" > out.txt 2>&1; then fail "committed with $1 edited and not staged"; fi; }
dirty BASELINE.md; [ "$(by)" = law-dirty,arm-accepted ] || fail "BASELINE.md edited, not staged: by=$(by), not law-dirty,arm-accepted"
dirty checks/prd.sh; [ "$(by)" = law-dirty ] || fail "checks/prd.sh edited, not staged: by=$(by), not law-dirty"
# the owner's ruling written later on the finding of a committed row
ROUTED=$(printf '%s\n' "$FIND" | sed 's/accepted A-100/routed OQ-1/')
land() { git commit -qm "$MSG" > out.txt 2>&1 || fail "refused: $1"; }
ruling() { sed 's/^\(F-06 .*\)routed OQ-1/\1accepted A-120/' PRD.md > P.t && mv P.t PRD.md
  printf '\n### 2026-09-04 (owner answer)\n\n```vid-prd-answers\nA-120 | human | 2026-09-04 | Q: is a later repeat accepted? | A: yes | settles: REQ-001\n```\n' >> PRD.md
  grep -q '^F-06 .*accepted A-120' PRD.md || fail 'the fixture recorded no ruling'; }
git reset -q --hard "$ROOT"; append "$ANS" "$NARROW | arms: 1 strengthened, 2 retained" "$ROUTED"; land 'the amendment, its finding still routed'
RT=$(git rev-parse HEAD)
ruling; printf '\nreview: delta, round 1, 0 findings\n' >> PRD.md; git add PRD.md; land "the owner's ruling on a committed row's finding"
git reset -q --hard "$RT"; ruling
printf '\n```vid-prd\n%s | arms: 1 withdrawn A-120, 2 retained\n```\n\nreview: delta, round 1, 0 findings\n' "$(printf '%s\n' "$NARROW" | sed 's/in the same week/in the same month/')" >> PRD.md; git add PRD.md; land 'the ruling beside a correcting row of the item'
# the AMENDED row added under an accepted finding already committed
git reset -q --hard "$ROOT"
printf '\n### 2026-09-02 (owner answer)\n\n```vid-prd-answers\n%s\n```\n\nreview: delta, round 1, 1 findings\n\n```vid-prd-findings\n%s\n```\n' "$ANS" "$FIND" >> PRD.md; git add PRD.md; land 'the finding alone'
printf '\n```vid-prd\n%s | arms: 1 retained, 2 retained\n```\n' "$NARROW" >> PRD.md; git add PRD.md
if git commit -qm "$MSG" > out.txt 2>&1; then fail 'an AMENDED row added under a committed accepted finding was committed'; fi
[ "$(by)" = arm-accepted ] || fail "the AMENDED row under a committed finding: by=$(by), not arm-accepted"
# one committed with the hooks off stays, and the next append commits
git reset -q --hard "$ROOT"; append "$ANS" "$NARROW | arms: 1 strengthened, 2 retained" "$FIND"; git commit -q --no-verify -m 'committed under older hooks'
BAD=$(git rev-parse HEAD)
printf '\n### 2026-09-05 (owner answer)\n\n```vid-prd-answers\nA-101 | human | 2026-09-05 | Q: is the footer kept? | A: yes, as it is | settles: REQ-012\n```\n\nreview: delta, round 1, 0 findings\n' >> PRD.md; git add PRD.md
git commit -qm "$MSG" > out.txt 2>&1 || fail 'a later append was refused for a label committed before it'
printf '\n### 2026-09-06 (owner answer)\n\n```vid-prd\n%s | arms: 1 withdrawn A-100, 2 retained\n```\n\nreview: delta, round 1, 0 findings\n' "$R1" >> PRD.md; git add PRD.md
git commit -qm "$MSG" > out.txt 2>&1 || fail 'a row restoring the old words, under a label committed before it, was refused'
# merged in from a branch that holds it
git checkout -q -b other "$ROOT"; printf '# Purpose: toy\n' > app/a.py; git add app/a.py; git commit -qm "$MSG" > out.txt 2>&1 || fail 'the other branch was refused'
git merge -q --no-ff --no-commit "$BAD" > out.txt 2>&1 || fail 'the merge did not prepare'
git commit -qm "$MSG" > out.txt 2>&1 || fail 'a merge bringing a committed label in was refused'
git show HEAD:PRD.md | grep -q '^F-06 ' || fail 'the merge did not bring the section in'
exit 0
