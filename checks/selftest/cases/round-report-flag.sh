#!/bin/sh
# Purpose: selftest case — a left-out report branch is flagged to the owner (FB-3 A2), checks/round.sh step on the toy and the fake gh, in
# GitHub auto and GitHub manual alike: `flag report-skipped <id>: <words>` once over two steps, the words naming the branch, its newest
# commit, its author and date, the number it reports on, why, and how to put it right; a heartbeat line; an id with no number names
# none. Once the branch holds its folder, or is gone, the flag is cleared, and no question is ever raised for it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "round-report-flag: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; sh "$CHECKS/github.sh" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
st() { ac_round step; [ "$RC" = 0 ] || fail "step failed ($RC)"; }
bad() { ( cd "$T/dev" && git checkout -q -B "bad-$1" main && echo "code $1" > app.py && git add app.py && g commit -q -m "$1" && git push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1" && git checkout -q -f main ); }
for md in manual auto; do
  printf 'setup-answered key=github-mode value="%s" words="the toy" at=2026-11-2%sT09:00:00Z\n' "$md" "$([ "$md" = auto ] && echo 1 || echo 0)" >> .vid/plan/setup
  st; bad "red-7-1"; bad stray; tk_dev "a commit $md"; st   # the main moved, so this step fetches
  c=$(git -C "$T/code.git" rev-parse refs/heads/vid-results/red-7-1 | cut -c1-12)
  grep -q "^flag report-skipped red-7-1: the branch vid-results/red-7-1 (its newest commit $c by [^,]*, [0-9T:+Z-]*) reports on #7: it has no folder red-7-1. Put the report's files in a folder named red-7-1 on that branch and push it again; whatever else the branch holds is not read.$" "$T/out" || fail "$md: no flag, or not its words"
  grep -q "^flag report-skipped stray: the branch vid-results/stray (its newest commit [0-9a-f]* by [^)]*): it has no folder stray\. " "$T/out" || fail "$md: an id with no number is not flagged, or names one"
  grep -q 'round: FLAG report-skipped red-7-1: the branch vid-results/red-7-1' .vid/HEARTBEAT.md && grep -qx 'report-skipped red-7-1' .vid/decide/flags || fail "$md: the flag has no heartbeat line or no record"
  st; ! grep -q '^flag report-skipped' "$T/out" || fail "$md: the flag was said twice"
  ! grep -rq 'report-skipped' .vid/decide/queue 2>/dev/null || fail "$md: a question was raised for it"
  rr_put red-7-1 results.txt "$(printf 'by: A Person\ncommit: %s' "$AC_C")"; ac_send red-7-1; git -C "$T/code.git" update-ref -d refs/heads/vid-results/stray
  st; ! grep -q '^report-skipped ' .vid/decide/flags && grep -q 'flag-cleared word=report-skipped on=red-7-1' .vid/metrics-events || fail "$md: a branch put right, or gone, keeps its flag"
  git -C "$T/code.git" update-ref -d refs/heads/vid-results/red-7-1; done
exit 0
