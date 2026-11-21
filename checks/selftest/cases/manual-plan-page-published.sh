#!/bin/sh
# Purpose: selftest case — the plan page published as a private page with one link (GM-2 T12; its case
# manual-plan-page-published). GM-4 K9: the page's show is the vid-triggers skill's, which vid-next names after its call's end
# (step 7), and which publishes it only once the records are saved and the lock freed; with `plan-page: artifact` it writes the fixed shell (next-move.sh shell), publishes it with the page as its
# data file and keeps the link through planner.sh setup; with a link it reads that artifact first, then publishes the data file
# to the same link; a publish refused or failed is said in one line with the page's path, never the link as current, and never
# fails the call; without the yes, or with no artifact tool, nothing is published and the path is said. The shell itself shows
# plan.html and holds no outside address. Reads skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -f "$S/vid-next/SKILL.md" ] || { echo 'manual-plan-page-published: no skills/ beside checks/ (a project layout)'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "manual-plan-page-published: $*" >&2; exit 1; }
N=$S/vid-triggers/SKILL.md; [ -f "$N" ] || fail 'there is no vid-triggers skill'
ln_() { grep -n "$1" "$N" | head -n 1 | cut -d: -f1; }
X=$S/vid-next/SKILL.md; e=$(grep -n '^7\. \*\*' "$X" | cut -d: -f1); p=$(grep -n 'plan page' "$X" | grep 'vid-triggers' | tail -n 1 | cut -d: -f1)
[ -n "$e" ] && [ -n "$p" ] && [ "$p" -gt "$e" ] || fail "vid-next does not name vid-triggers' plan page after the call has ended (step 7)"
grep -q 'plan-page:' "$N" || fail 'vid-triggers names no plan-page: setting'
grep -q 'saved the records and freed the lock' "$N" || fail 'vid-triggers does not say the publish waits for the records saved and the lock freed'
grep -q 'next-move.sh shell' "$N" || fail 'vid-triggers does not write the fixed shell'
grep -q 'planner.sh setup plan-page' "$N" || fail 'vid-triggers does not keep the link in the setup'
r=$(ln_ 'action: "read"'); u=$(ln_ 'to that same link'); [ -n "$r" ] && [ -n "$u" ] && [ "$r" -le "$u" ] || fail 'vid-triggers does not read the published shell first, then publish the data file to the same link'
grep -q 'in one line, with the page' "$N" && grep -q 'Never give the link as current' "$N" && grep -q 'never fail the call' "$N" || fail 'vid-triggers does not say a failed publish plainly, with the path'
grep -q 'nothing is published; say the page' "$N" || fail 'vid-triggers publishes without plan-page: artifact'
# the shell
mkdir -p "$T/v"; printf '<!doctype html><title>plan</title>\n' > "$T/v/plan.html"
sh "$CHECKS/next-move.sh" shell "$T/v/plan.html" > "$T/o" 2>&1 || { cat "$T/o" >&2; fail 'next-move.sh shell failed'; }
SH=$(sed -n 's/^shell //p' "$T/o"); [ "$SH" = "$T/v/plan-shell.html" ] && [ -f "$SH" ] || fail "the shell is not written beside the page: $(cat "$T/o")"
grep -q 'src="plan.html"' "$SH" || fail 'the shell does not show plan.html'
! grep -qiE 'https?://|//[a-z]' "$SH" || fail 'the shell holds an outside address'
exit 0
