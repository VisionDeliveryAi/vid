#!/bin/sh
# Purpose: selftest case — the planner's review stops after at most 3 rounds a sitting (low-1, R5). On the planner's toy
# (fixtures/planner-toy.sh): the rounds close after the sitting's 3rd review, or after a review that finds no fewer than the
# one before; once closed, `review` records nothing, says so and why, and exits 0; ratify needs no review at the current hash;
# the open findings are every unanswered finding at the newest review's hash; the page drops "no review of this plan" and
# notes the close (and, after a spec change, that the changes are not reviewed); `answer <n> fixed` joins keep. Scenes:
# {A,B},{B},{B} at one hash; 2,1,1 with the hash changed before each, then a PRD.md edit; 1,1; 2 then 0 at one hash (open,
# as before); a review of 0 and a ratification in the same second, then a spec change; a base-form record (no marker
# line), then a spec change. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-review-cap: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
PN=$CHECKS/planner.sh
pl() { RC=0; sh "$PN" "$@" > "$T/out" 2>&1 || RC=$?; }
rv() { : > "$T/rv"; for r; do printf 'finding %s | %s is vague\n' "$r" "$r" >> "$T/rv"; done; [ $# -gt 0 ] || echo none > "$T/rv"; pl review --in "$T/rv"; }
nrev() { grep -c '^review ' .vid/plan/review || true; }
pg() { pl page; [ "$RC" = 0 ] || fail "page failed ($RC)"; PG=.vid/plan/PLAN-PAGE.md; }
sec() { awk -v h="## $1" '$0 == h { on = 1; next } on && /^## / { exit } on' "$PG"; }
has() { grep -qF -- "$1" "$T/out" || fail "no line: $1"; }
bump() { printf '\n' >> PLAN.md; }   # the spec files' hash changes, the check stays clean

# {A,B}, {B}, {B} at one hash: closed after the 3rd review; A stays open; ratify refuses until A too is answered
fresh; rv RULE-004 RULE-005; rv RULE-005; [ "$(nrev)" = 2 ] || fail 'the second review was not recorded'; rv RULE-005
[ "$RC" = 0 ] && [ "$(nrev)" = 3 ] || fail "the third review was not recorded ($RC)"
rv HOS-005; [ "$RC" = 0 ] || fail "a review after the rounds closed exited $RC"; [ "$(nrev)" = 3 ] || fail 'a fourth review was recorded'
has 'the rounds of review are closed after review number 3'; ! grep -q '^finding .* HOS-005 ' .vid/plan/review || fail 'the closed review recorded a finding'
pg; sec Flags | grep -q '^- finding 1 on RULE-004, not answered: ' || fail "A (finding 1) is not among the open findings: $(sec Flags)"
for n in 2 3 4; do pl answer $n keep --words 'keep it'; [ "$RC" = 0 ] || fail "answer $n keep refused"; done
pg; pl ratify --words 'yes'; [ "$RC" = 1 ] || fail 'ratify passed with A unanswered'; has 'finding 1 on RULE-004 has no answer'
pl answer 1 keep --words 'keep A'; pg; pl ratify --words 'yes'; [ "$RC" = 0 ] || fail "ratify refused once every finding is answered ($RC)"

# 2, 1, 1, the hash changed before each; then a PRD.md edit
fresh; rv HOS-005 RULE-004; bump; rv RULE-004; bump; rv RULE-005; [ "$(nrev)" = 3 ] || fail 'the three reviews were not recorded'
printf '\n' >> PRD.md; pl check; [ "$RC" = 0 ] || fail "the PRD.md edit flagged the plan ($RC)"
rv HOS-005; [ "$RC" = 0 ] || fail "a fourth review --in exited $RC"; [ "$(nrev)" = 3 ] || fail 'a fourth review was recorded'
has 'the rounds of review are closed after review number 3 (it was the 3rd review of this sitting)'
pg; ! sec Flags | grep -q 'no review of this plan' || fail 'the closed page shows "no review of this plan"'
F=$(sed -n 's/^finding \([0-9]*\) review=3 .*/\1/p' .vid/plan/review); [ -n "$F" ] || fail 'no finding of the 3rd review'
sec Flags | grep -q "^- finding $F on RULE-005, not answered: " || fail "the page lacks the 3rd review's open finding: $(sec Flags)"
sec Notes | grep -q 'the rounds of review are closed after review number 3' || fail "the page lacks the closed note: $(sec Notes)"
sec Notes | grep -q 'not reviewed' || fail 'the closed note does not say the changes since are not reviewed'
pl ratify --words 'yes'; [ "$RC" = 1 ] || fail "ratify passed before the 3rd review's finding was answered"; has "finding $F on RULE-005 has no answer"
! grep -qF 'no review has this plan' "$T/out" || fail 'the closed ratify still asks for a review at the current hash'
pl answer "$F" fixed --words 'I had it fixed'; [ "$RC" = 0 ] || fail "answer fixed was refused ($RC)"
grep -q "^answer $F fixed hash=.* words=I had it fixed\$" .vid/plan/review || fail 'the fixed answer is not recorded'
pg; pl ratify --words 'yes'; [ "$RC" = 0 ] || fail "ratify refused once the finding is answered fixed ($RC)"
grep -q '^ratified after-review=3$' .vid/plan/review || fail 'ratify appended no marker line to the review record'

# 1, 1: closed after the 2nd review
fresh; rv RULE-004; bump; rv RULE-004; bump; rv RULE-005; [ "$RC" = 0 ] && [ "$(nrev)" = 2 ] || fail "two reviews of 1 and 1 did not close the rounds ($(nrev) reviews)"
has 'the rounds of review are closed after review number 2 (review number 2 found 1, no fewer than review number 1'

# 2, then 0 at the current hash: open, as before
fresh; rv HOS-005 RULE-004; rv; [ "$(nrev)" = 2 ] || fail 'the 0 review was not recorded'; pg
[ "$(sec Flags | grep '^- ')" = "$(printf '%s\n' '- finding 1 on HOS-005, not answered: HOS-005 is vague' '- finding 2 on RULE-004, not answered: RULE-004 is vague')" ] || fail "2 then 0 changed the flags: $(sec Flags)"
! sec Notes | grep -q 'closed' || fail '2 then 0 closed the rounds'
pl ratify --words 'yes'; [ "$RC" = 1 ] && has 'finding 1 on HOS-005 has no answer' || fail '2 then 0: ratify passed with findings open'
bump; pg; sec Flags | grep -qx -- '- no review of this plan' || fail '2 then 0: a changed plan does not show "no review of this plan"'
pl answer 1 keep --words 'k'; [ "$RC" != 0 ] || fail '2 then 0: an answer to a finding of an earlier hash was taken'
rv; [ "$(nrev)" = 3 ] || fail '2 then 0: the next review was not recorded'

# a review of 0 and a ratification in the same second, then a spec change: the next sitting opens
fresh; rv; pg; pl ratify --words 'yes'; [ "$RC" = 0 ] || fail "the toy was refused ($RC)"
A=$(sed -n 's/^review [1] .* at=\([^ ]*\)$/\1/p' .vid/plan/review); sed "s/ at=[^ ]* words=/ at=$A words=/" .vid/plan/ratified > "$T/r"; cat "$T/r" > .vid/plan/ratified
printf '\n' >> PRD.md; rv RULE-004; [ "$RC" = 0 ] && [ "$(nrev)" = 2 ] || fail "the next sitting's first review was not recorded ($RC)"; has "review $(nrev) recorded"
pg; ! sec Notes | grep -q 'closed' || fail "the next sitting's rounds read closed"; sec Flags | grep -q '^- finding 1 on RULE-004, not answered' || fail 'the new finding is not on the page'
bump; rv RULE-004; [ "$(nrev)" = 3 ] || fail "the next sitting's second review was not recorded"

# a base-form record: 2, 1, 1 and a ratification with no marker line; then a spec change: the next sitting opens
fresh; rv HOS-005 RULE-004; bump; rv RULE-004; bump; rv RULE-005; F=$(sed -n 's/^finding \([0-9]*\) review=3 .*/\1/p' .vid/plan/review)
pl answer "$F" keep --words 'keep'; pg; pl ratify --words 'yes'; [ "$RC" = 0 ] || fail "the base-form ratify was refused ($RC)"
grep -v '^ratified after-review=' .vid/plan/review > "$T/r"; cat "$T/r" > .vid/plan/review
printf '\n' >> PRD.md; rv RULE-004; [ "$RC" = 0 ] && [ "$(nrev)" = 4 ] || fail "after a base-form ratification the next review was not recorded ($(nrev) reviews)"
pg; ! sec Notes | grep -q 'closed' || fail 'after a base-form ratification the rounds read closed'

# a history the base wrote: 2, 1, 0 and 1 at four hashes, the 4th at the current hash, not ratified. The rounds closed at the 3rd
# review, yet the open findings are the newest one's: ratify refuses until the 4th review's finding is answered
fresh; rv HOS-005 RULE-004; bump; rv RULE-004; bump; rv; bump; H=$(sh "$PN" hash)
printf 'review %s hash=%s findings=1 at=2026-11-03T09:00:00Z\nfinding %s review=%s hash=%s | RULE-005 | RULE-005 is vague\n' 4 "$H" 4 4 "$H" >> .vid/plan/review
pg; sec Flags | grep -q '^- finding 4 on RULE-005, not answered: ' || fail "the page lacks the 4th review's open finding: $(sec Flags)"
pl ratify --words 'yes'; [ "$RC" = 1 ] && has 'finding 4 on RULE-005 has no answer' || fail "ratify passed with the 4th review's finding unanswered ($RC)"
pl answer 4 keep --words 'keep it'; [ "$RC" = 0 ] || fail "the 4th review's finding could not be answered ($RC)"; pg; pl ratify --words 'yes'; [ "$RC" = 0 ] || fail "ratify refused once the 4th review's finding is answered ($RC)"
echo 'planner-review-cap: ok'
