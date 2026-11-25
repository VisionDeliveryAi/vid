#!/bin/sh
# Purpose: selftest case — the re-plan page says each added test in the inventory's own words, and opens as the plan page does (FB-3 E3).
# On the form fixture's toy, S02 posted as ticket N; ROW-021 to ROW-024 landed. The candidate tops N up with ROW-021, puts ROW-022 and
# ROW-023 in a new step S06 and ROW-024 in S04, a step not published yet. The page gives, after N's line, `ROW-021: <its promise>`, and after S06's, one line for each of its tests, after S04's
# one for the test it gains; the words the inventory holds at the target (a landing's newest, not the team's), a test whose promise is its fail-if alone by that; its other
# sections stand, and a restated or kept test has no such line. `next-move.sh shell` takes that page: replan-shell.html beside it, its own
# title and frame, no outside address; the plan page's shell is as it was, and a page of another name is refused. The skills publish it
# after the call's end, by plan-page:, its link kept in .vid/plan/replan-page. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "replan-page-words: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N
row() { printf '%s | behavior | REQ-001 | anonymous | n/a | %s | REQ-001 | owed: spec-only — first stage | origin: REQ-001\n' "$1" "$2"; }
{ row ROW-021 'A first wording of the day. Fails if it shows none.'; row ROW-022 'A digest names each job’s town, & its *county*. Fails if a job has no town.'; row ROW-023 'Fails if a digest is sent twice.'; row ROW-024 'A digest names its sender. Fails if it names none.'; } > "$T/rows"
awk -v R="$T/rows" '{ print } /^ROW-020 / && !d { while ((getline l < R) > 0) print l; d = 1 }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; g commit -qam 'four rows landed'
sed -e 's/A first wording of the day\. Fails if it shows none\./A saved search shows the day its last digest went out. Fails if a saved search shows no day./' -e 's/at the stated size of 10,000 active jobs/at the stated size of 20,000 active jobs/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; g commit -qam 'ROW-021 and ROW-012 reworded'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
C=$T/cand; mkdir -p "$C"; awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md |
  sed -e 's/^\(step S02 .*rows:\) /\1 ROW-021 /' -e 's/^needs ROW-001 /needs ROW-021 ROW-001 /' -e 's/^\(step S04 .*rows:\) /\1 ROW-024 /' -e 's/^needs ROW-002 /needs ROW-024 ROW-002 /' -e '/^step S05 /{p;s/.*/step S06 | name: the digest, better said | modules: digest | builds-on: S02 | rows: ROW-022 ROW-023 | lane: devagent/;}' -e '/^needs ROW-017 /{p;s/.*/needs ROW-022 ROW-023 | -/;}' > "$C/block"
h=$(git rev-parse --short HEAD); printf 'S06\tscope-change\tcommit:%s\tthe two are built and tested in a step of their own\nS02\tscope-change\tcommit:%s\tROW-021 joins the step it belongs to\nS04\tscope-change\tcommit:%s\tROW-024 joins the step it belongs to\n' "$h" "$h" "$h" > "$C/changes"
printf 'none\n' > "$C/review"; sh "$CHECKS/replan.sh" scope > "$T/out" 2>&1 || fail 'scope failed'; awk -F'\t' '$1 == "trigger" { print "trigger\t" $3 " " $4 "\tno plan change helps it" }' "$T/out" > "$C/left"
pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis was refused'
M=.vid/next/proposal/REPLAN-PAGE.md; H=.vid/pages/REPLAN-PAGE.html; cp "$M" "$T/out"
sec() { awk -v s="## $1" '$0 == s { f = 1; next } /^## / { f = 0 } f' "$M"; }
L1='ROW-021: A saved search shows the day its last digest went out.'
[ "$(sec "Each ticket's top-ups" | grep -A1 "^- \*\*#$N\*\* " | sed -n 's/^ *- //p' | sed -n 2p)" = "$L1" ] || fail "the added test of #$N is not given in its own words, after its line"
[ "$(sec 'New or split steps' | grep -A2 '^- \*\*S06\*\* (new' | sed -n 's/^ *- \(ROW-\)/\1/p')" = "$(printf 'ROW-022: A digest names each job’s town, & its *county*.\nROW-023: Fails if a digest is sent twice.')" ] || fail "S06's tests are not given in their own words, after its line"
sec 'New or split steps' | grep -A1 '^- \*\*S04\*\* (changed)' | sed -n 's/^ *- \(ROW-\)/\1/p' | grep -qx 'ROW-024: A digest names its sender.' || fail 'the test S04 gains is not given in its own words'
[ "$(grep -cE '^ *- ROW-[0-9]+: A|^ *- ROW-[0-9]+: Fails' "$M")" = 4 ] || fail 'a test not added has a line of its own'; ! grep -q 'first wording' "$M" || fail "the words are not the target's"
grep -q '^- \*\*S02\*\* (changed): its tests ' "$M" && grep -q "^- \*\*#$N\*\* (step S02): adds ROW-021; restates ROW-012" "$M" || fail 'a line of the page is not as it was'
for s in "Each ticket's top-ups" 'New or split steps' 'What moves' 'The warnings' 'What it leaves alone, and why' 'The triggers it covers' 'The changes' 'What is pending' 'The review of the tests ViD adds'; do grep -qxF "## $s" "$M" || fail "the page has no section: $s"; done
grep -qF "$L1" "$H" || fail 'the rendered page does not hold the words'
# the shell, on that page
sh "$CHECKS/next-move.sh" shell "$H" > "$T/out" 2>&1 || fail 'next-move.sh shell refused the re-plan page'
S=$(sed -n 's/^shell //p' "$T/out"); [ "$S" = "$(cd .vid/pages && pwd)/replan-shell.html" ] && [ -f "$S" ] || fail 'the shell is not written beside the page'
grep -q 'src="REPLAN-PAGE.html"' "$S" && grep -q '<title>Re-plan page</title>' "$S" && ! grep -q 'plan\.html' "$S" || { cp "$S" "$T/out"; fail 'the shell does not show the re-plan page, under its own title'; }; ! grep -qiE 'https?://|//[a-z]' "$S" || fail 'the shell holds an outside address'
mkdir "$T/v"; echo '<!doctype html><title>p</title>' > "$T/v/plan.html"; cp "$T/v/plan.html" "$T/v/other.html"; sh "$CHECKS/next-move.sh" shell "$T/v/plan.html" > "$T/out" 2>&1 || fail 'the plan page shell failed'
[ -f "$T/v/plan-shell.html" ] && grep -q '<title>Plan page</title>' "$T/v/plan-shell.html" && grep -q '<iframe src="plan.html" title="The plan page"></iframe>' "$T/v/plan-shell.html" || fail 'the plan page shell changed'
if sh "$CHECKS/next-move.sh" shell "$T/v/other.html" > "$T/out" 2>&1; then fail 'a page of another name was taken'; fi
# the skills
K=$CHECKS/../skills; [ -f "$K/vid-replan/SKILL.md" ] || exit 0; R=$K/vid-replan/SKILL.md; : > "$T/out"
for x in 'next-move.sh shell .vid/pages/REPLAN-PAGE.html' '.vid/plan/replan-page' 'plan-page:' "The plan page" 'own words'; do grep -qF -- "$x" "$R" || fail "vid-replan does not say: $x"; done
awk '/^## The re-plan page/ { f = 1; next } /^## / { f = 0 } f' "$R" > "$T/sec"; for x in 'has ended' 'implement-replan' 'action: "read"' 'none' 'its path'; do grep -qF -- "$x" "$T/sec" || fail "vid-replan's re-plan page does not say: $x"; done
e=$(grep -n '^7\. \*\*' "$K/vid-next/SKILL.md" | cut -d: -f1); p=$(grep -n 'The re-plan page' "$K/vid-next/SKILL.md" | tail -n 1 | cut -d: -f1); [ -n "$p" ] && [ "$p" -gt "$e" ] || fail 'vid-next does not name its show after the call has ended'
echo 'replan-page-words: ok'
