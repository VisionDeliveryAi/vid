#!/bin/sh
# Purpose: selftest case — a stale or breaking proposal refuses the apply, nothing recorded (GM-3 U4; its case manual-apply-stale).
# On the form fixture's toy (fixtures/form.sh), S02 posted as #N; ROW-021 added and committed (a landing, by hand); the call's
# read made; the analysis writes a proposal topping #N up with ROW-021. Then a commit after the analysis: `replan.sh apply --words`
# is refused (exit 4), naming the analysis to run again, and ViD's records (.vid/, the proposal and its page apart), the commit and
# the working tree, and the fake GitHub (its every file) are byte for byte as before. Analysed again at the new HEAD, the proposal's
# block is then edited to take ROW-013 out of S02 (a published row): the apply is refused at the check (exit 1), naming rule-2 and
# ROW-013, and nothing is recorded, the same way. A proposal whose change cites a commit that does not exist is refused at the
# analysis (FIX-BATCH-T3 F-35: the check judges the apply's own arguments), a rule-6 line naming it, nothing recorded; a proposal changing PLAN.md, whose commit in the dry run a commit hook of the toy's
# own refuses (the toy with its own git identity), passes the check and refuses in the dry run (exit 1, naming it), nothing
# recorded; and a review written into the proposal after the
# analysis, a finding its page never showed, refuses the apply (exit 1), showing the finding, nothing recorded. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-apply-stale: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
awk '{ print } /^ROW-020 / && !d { print "ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day. | REQ-001 | owed: spec-only — first stage | origin: REQ-001"; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
g commit -qam 'ROW-021 landed'
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
C=$T/cand; mkdir -p "$C"; printf 'none\n' > "$C/review"
blk | sed -e 's/^\(step S02 .*rows:\) /\1 ROW-021 /' -e '/^needs ROW-017 /{p;s/.*/needs ROW-021 | -/;}' > "$C/block"
cand() { printf 'S02\tscope-change\tcommit:%s\tROW-021 joins #%s\n' "$(git rev-parse --short HEAD)" "$N" > "$C/changes"; }
cand; pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis was refused'
snap() { { find .vid -type f ! -path '.vid/next/proposal/*' ! -path .vid/pages/REPLAN-PAGE.html | sort | while IFS= read -r f; do cksum "$f"; done
  git rev-parse HEAD; git status --porcelain; find "$FAKEGH" -type f | sort | while IFS= read -r f; do cksum "$f"; done; } > "$1"; }
# a commit after the analysis
printf 'a note of the owner\n' > NOTES.txt; g add NOTES.txt; g commit -qm 'a note'
snap "$T/s0"
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 4 ] && grep -qi 'analyse again' "$T/out" || fail "the apply after a later commit exited $RC, or did not name the analysis to run again"
snap "$T/s1"; cmp -s "$T/s0" "$T/s1" || { diff "$T/s0" "$T/s1" > "$T/out" || :; fail 'the stale apply recorded something'; }
# analysed again; the proposal's block then takes ROW-013 out of #N
cand; pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the second analysis was refused'
sed 's/^\(step S02 .*\) ROW-013 /\1 /; s/^\(step S05 .*rows:\) /\1 ROW-013 /' .vid/next/proposal/block > "$T/b" && cat "$T/b" > .vid/next/proposal/block
grep -q '^step S05 .* ROW-013 ' .vid/next/proposal/block || fail 'the edit of the proposal did not take'
snap "$T/s2"
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'rule-2 ROW-013' "$T/out" || fail "the apply of a block taking ROW-013 out of #$N exited $RC, or named no rule-2 breach"
snap "$T/s3"; cmp -s "$T/s2" "$T/s3" || { diff "$T/s2" "$T/s3" > "$T/out" || :; fail 'the apply refused at the check recorded something'; }
# a proposal whose change's evidence names no commit: refused at the analysis, before the owner is asked (FIX-BATCH-T3 F-35)
printf 'S02\tscope-change\tcommit:0123456789ab\tROW-021 joins #%s\n' "$N" > "$C/changes"
snap "$T/s4"
RC=0; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] && grep -q '^rule-6 .*commit:0123456789ab' "$T/out" || fail "the analysis citing a missing commit exited $RC, or named no rule-6 line for it"
snap "$T/s5"; cmp -s "$T/s4" "$T/s5" || { diff "$T/s4" "$T/s5" > "$T/out" || :; fail 'the analysis refused for a missing commit recorded something'; }
# a proposal the check passes and the apply's dry run refuses: its PLAN.md, committed in the dry run, meets a commit hook of the
# toy's own (outside ViD's scripts) that refuses every commit; the toy has its own git identity, so the machine does not matter
cand; printf 'PLAN.md\tscope-change\tcommit:%s\tthe plan'"'"'s words follow the step\n' "$(git rev-parse --short HEAD)" >> "$C/changes"
{ git show HEAD:PLAN.md 2>/dev/null || :; printf '\nThe digest step takes ROW-021 too.\n'; } > "$C/PLAN.md"
pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis of a proposal changing PLAN.md was refused'
git config user.name vid; git config user.email vid@selftest; mkdir -p "$T/hk"; printf '#!/bin/sh\necho "the toy refuses every commit" >&2\nexit 1\n' > "$T/hk/pre-commit"; chmod +x "$T/hk/pre-commit"; git config core.hooksPath "$T/hk"
snap "$T/s4"
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it' > "$T/out" 2>&1 || RC=$?
git config --unset core.hooksPath; rm -f "$C/PLAN.md"
[ "$RC" = 1 ] && grep -q 'dry run' "$T/out" || fail "the apply whose PLAN.md commit is refused in the dry run exited $RC, or did not name the dry run"
snap "$T/s5"; cmp -s "$T/s4" "$T/s5" || { diff "$T/s4" "$T/s5" > "$T/out" || :; fail 'the apply refused in its dry run recorded something'; }
# the review the apply records is the one the page showed: one changed after the analysis refuses, shown again
cand; pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the third analysis was refused'
AD=$(sh "$CHECKS/planner.sh" rows --added --at HEAD 2>/dev/null | awk -F'|' 'NF { k = $1; gsub(/^[ \t]+|[ \t]+$/, "", k); if (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) { k = $2; gsub(/^[ \t]+|[ \t]+$/, "", k) } print k; exit }')
[ -n "$AD" ] || fail 'the toy has no row its planner added, for a finding'
printf 'finding %s | the page never showed this\n' "$AD" > .vid/next/proposal/review
snap "$T/s6"
RC=0; sh "$CHECKS/replan.sh" apply --words 'Yes, apply it' > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'review' "$T/out" && grep -q "$AD" "$T/out" || fail "the apply with a review the page did not show exited $RC, or did not show it"
snap "$T/s7"; cmp -s "$T/s6" "$T/s7" || { diff "$T/s6" "$T/s7" > "$T/out" || :; fail 'the apply refused for a changed review recorded something'; }
exit 0
