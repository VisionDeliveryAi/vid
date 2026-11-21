#!/bin/sh
# Purpose: selftest case — a step close's ticket close that fails after its comment posts (GM-4 K3, GM M8), in GitHub manual on the
# writer's toy and the fake gh. The step's ticket is accepted (E4's merge line) and its close read green, while closing an issue on
# GitHub fails: the step closes, its ticket left open (`ticket-open #1`) with its one comment, `vid: closed — the step's close passed
# at <commit12>`. Once closing works again, `close.sh owed` closes the ticket, and the ticket holds exactly one comment: the comment
# and the issue's close are recorded apart, so the retry never posts the comment twice; a later owed changes nothing. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "manual-ticket-close-retry: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; mkdir -p "$T/r"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
ncom() { ls "$T/gh/issues/$1/comments" 2>/dev/null | grep -c . || true; }
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$1-p1c1-$2; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$M")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-003=pass)"; send "$Q"; }
# the toy in GitHub manual, S01's ticket #1 (its issue on the fake gh, ROW-003 alone), one engine
tw_toy "$T/man"; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
M=$(git --git-dir="$T/code.git" rev-parse main); M12=$(printf %.12s "$M"); printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings
gh issue create -R $R --title 'Skeleton' --body 'the skeleton' > /dev/null
printf '# t\n\n## Header\n\n- number: 1\n- kind: skeleton\n\n## Rows\n\n> ROW-003 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-003 marks: none\n' > .vid/tw/out/issue-1.md
printf 'published 1 kind=skeleton step=S01 rows=ROW-003 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log; printf 'engines alpha | stand-in: results reader\n' >> .vid/tw/handed
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied
# closing an issue fails while $FAKEGH/close-fail exists (a wrapper before the fake gh on PATH)
mv "$T/bin/gh" "$T/bin/gh-fake"; printf '#!/bin/sh\nif [ "${1:-} ${2:-}" = "issue close" ] && [ -f "$FAKEGH/close-fail" ]; then echo "HTTP 502: the close failed" >&2; exit 1; fi\nexec sh "%s" "$@"\n' "$T/bin/gh-fake" > "$T/bin/gh"; chmod +x "$T/bin/gh"
# accepted at main's commit (E4's line), the close asked and read green while closing fails
printf 'step-1-%s\n' "$M12" > .vid/decide/merged-prs; printf 'step-1-%s\t1\t%s\t%s\n' "$M12" "$M" "$M" > .vid/decide/merges
cs step S01; [ "$RC" = 0 ] || fail "the owed close exited $RC"; ok '^asked [0-9]* close S01$'; N=$(sed -n 's/^asked \([0-9]*\) close S01$/\1/p' "$T/out")
rq "$N" 1; : > "$FAKEGH/close-fail"; cs step S01; [ "$RC" = 0 ] || fail "the read exited $RC"; ok '^closed S01$'; ok '^ticket-open #1$'
[ "$(cat "$T/gh/issues/1/state")" != CLOSED ] || fail 'the ticket closed while closing fails'
[ "$(ncom 1)" = 1 ] || fail "after the failed close the ticket has $(ncom 1) comments, not one"
# closing works again: owed closes it, the comment not posted again
rm -f "$FAKEGH/close-fail"; cs owed; [ "$RC" = 0 ] || fail "owed exited $RC"
[ "$(cat "$T/gh/issues/1/state")" = CLOSED ] || fail 'the retry through owed did not close the ticket'
[ "$(ncom 1)" = 1 ] || fail "after the retry the ticket has $(ncom 1) comments, not exactly one"
head -n 1 "$T/gh/issues/1/comments/$(ls "$T/gh/issues/1/comments")" | grep -qx "vid: closed — the step's close passed at $M12" || fail "the ticket's comment: $(cat "$T/gh/issues/1/comments"/*)"
cs owed; [ "$(ncom 1)" = 1 ] && [ "$(cat "$T/gh/issues/1/state")" = CLOSED ] || fail 'a later owed told or changed the ticket again'
echo 'manual-ticket-close-retry: ok'
