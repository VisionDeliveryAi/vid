#!/bin/sh
# Purpose: selftest case — the merge is bound to the reviewed head (v0.26.10.9 spec R23; §5 approve-match-head). A
# feature ticket's pull request (fixtures/tickets.sh gh_feature) passes `github.sh review`; then the worker pushes a
# new commit; `github.sh merge` is refused (gh pr merge --match-head-commit names the reviewed head) and nothing is
# merged — main unchanged, the pull request open, the passing review dropped so the new head is reviewed. A merge with
# no passing review is refused before gh is called. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "approve-match-head: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"; gh_feature || fail 'the feature ticket and its pull request were not made'
cd "$T/wa"
if sh "$CHECKS/github.sh" merge "$P" > "$T/out" 2>&1; then fail 'a merge with no review was accepted'; fi
grep -q 'no passing review' "$T/out" && ! grep -q "^gh pr merge $P" "$T/gh/log" || fail 'the unreviewed merge was not refused before gh'
sh "$CHECKS/github.sh" review "$P" > "$T/out" 2>&1 || fail 'the review failed'
M0=$(git -C "$T/code.git" rev-parse main)
( cd "$T/w1" && printf 'later\n' >> app/login/main.py && git commit -qam 'after the review' && sh "$CHECKS/github.sh" push "vid/$N" > /dev/null 2>&1 ) || fail 'the new commit was not pushed'
if sh "$CHECKS/github.sh" merge "$P" > "$T/out" 2>&1; then fail 'the merge of a moved head was accepted'; fi
grep -q "^gh pr merge $P -R owner/code --merge --match-head-commit $HEAD1 --body Stand-in: approver" "$T/gh/log" || fail 'the merge did not name the reviewed head'
[ "$(git -C "$T/code.git" rev-parse main)" = "$M0" ] && [ "$(cat "$T/gh/prs/$P/state")" = OPEN ] || fail 'something was merged'
[ ! -f "$T/wa/.git/vid/reviews/$P" ] || fail 'the passing review of the old head was kept'
exit 0
