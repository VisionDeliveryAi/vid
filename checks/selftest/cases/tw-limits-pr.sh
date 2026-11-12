#!/bin/sh
# Purpose: selftest case — a fix ticket whose rows all became known limits while a pull request names it (0.26.10.28.6 R2, kept),
# checks/round.sh, writer.sh, decide.sh and github.sh tw-close on TW's toy and the fake gh. The skeleton merged, S01 not closed, stage 0's
# candidate named; the round publishes the fix ticket of ROW-003, and the dev side opens its pull request, ROW-003 failing at its head. The
# owner rules ROW-003 a known limit (decide.sh rule): the head is decided again, accepted; `writer.sh due` owes nothing for the ticket and
# tw-close refuses it, its issue open; the pull request merges, the round records the merge and closes the issue, never withdrawn, and the
# step prints `nothing-left`. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "tw-limits-pr: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; W=$CHECKS/writer.sh; R=owner/code; mkdir -p "$T/r"
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1 failed ($RC)"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
tw_skel || fail 'the skeleton round failed'; M=$(git --git-dir="$T/code.git" rev-parse main); mkdir -p .vid/decide; echo 2 >> .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
grep -v '^closed S01 ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed; tw_hand 'candidate 1'
tw_hand 'fix ROW-003 | ROW-003: ROW-003 in chromium | close #9 of S01: req-9-p1c1-1'
rd next; F=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out"); [ -n "$F" ] && grep -q "^published $F kind=fix step=S01 rows=ROW-003 " .vid/tw/log || fail 'the fix ticket was not published'
# the dev side's pull request naming it, ROW-003 failing at its head, the regression row ROW-004 passing
Wd=$T/w; git clone -q "$T/code.git" "$Wd" 2>/dev/null; git -C "$Wd" checkout -q -B fix-a origin/main 2>/dev/null; git -C "$Wd" -c user.name=a -c user.email=a@b commit -q --allow-empty -m fix-a; git -C "$Wd" push -q -f origin fix-a; H=$(git -C "$Wd" rev-parse HEAD); h=$(printf %s "$H" | cut -c1-12)
P=$(gh pr create -R $R --head fix-a --base main --title t --body "ticket: #$F" | sed 's/.*\///')
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rr_put "pr-$P-$h-1" results.txt "$(printf 'by: TM\ncommit: %s\nengines: chromium\nenvironments: 2' "$H")"; rr_put "pr-$P-$h-1" cases-chromium.xml "$(rr_cases ROW-003=fail:broke ROW-004-T1=pass ROW-004-T2=pass ROW-004-T3=pass)"; send "pr-$P-$h-1"
rr_put "grade-pr-$P-$h-1" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-003 kept — a' "$H")"; send "grade-pr-$P-$h-1"
printf 'vid: decide %s\nby: MR\n' "$H" > "$T/c"; gh pr comment "$P" -R $R --body-file "$T/c" > /dev/null; rd step; ok "^decided $P $h ticket: not yet"
# the owner's ruling: the head decided again, accepted; nothing owed for the ticket, and tw-close refuses it
sh "$CHECKS/decide.sh" rule ROW-003 limit > "$T/out" 2>&1 || fail 'the ruling failed'; grep -q '^row ROW-003 known-limit ' .vid/tw/handed || fail 'the ruling is not handed'
rd step; ok "^decided $P $h ticket: accepted"; sh "$W" due > "$T/out" 2>&1 || fail 'due failed'; no "^withdraw $F"; no "^amend $F"
rd next; no "^withdrawn $F"; if sh "$GS" tw-close "$F" > "$T/out" 2>&1; then fail "tw-close withdrew #$F, its pull request open"; fi; ok "the round owes no withdrawal of #$F"
[ "$(cat "$T/gh/issues/$F/state")" = OPEN ] && ! grep -q "^withdrawn $F " .vid/tw/log || fail "#$F was withdrawn"
# it merges: the merge recorded, its issue closed by the round, never withdrawn; nothing left
gh pr ready "$P" -R $R; gh pr merge "$P" -R $R --merge --match-head-commit "$H" --body 'Role: MR' > /dev/null; rd step; ok "^merged $P\$"
[ "$(cat "$T/gh/issues/$F/state")" = CLOSED ] && grep -q "^$P	$F	" .vid/decide/merges && ! grep -q "^withdrawn $F " .vid/tw/log || fail "#$F did not merge as a merge"
rd next; rd step; ok '^nothing-left$'
exit 0
