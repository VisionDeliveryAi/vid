#!/bin/sh
# Purpose: selftest case — FB-2 A4: a take-down's report read, checks/close.sh on the writer's toy and the fake gh, stage 1's
# candidate planted with its test site up (a passed D1 that stays up, its run and walk done). A D1 that did not stay up, its staging
# run's issue closed, is nothing up: `down staging` refused, nothing posted. The take-down posted (`deploy down staging`) is out (`out
# down-staging`) until its report is read. Its report with no `down:` line is refused and posted back once, `vid: refused dn-1`;
# `outcome: failed down — x` gives `down-failed staging: x`, the issue closed, the test site still up in `queue.sh addresses`; a
# second take-down's `outcome: down` report gives `down staging 1`, the issue closed, a `deploy-down` event with the owner's words,
# and the addresses say `taken down at the owner's word`; nothing is out then. While closing an issue fails (a 502), a take-down read
# down, failed or lost stays out, its issue open and nothing said, and the next read closes it. A take-down never reported is asked
# again once (`close-again down-staging dn`), then is lost: `down-lost staging`, `lost` in its folder, the issue closed, the site
# still up, and staging free for the next one; so is one whose refused report was posted back and that is quiet past the wait after
# it, once asked again. The live copy on this machine taken down: `down production 1`, and the addresses name no live copy, and a
# further take-down of it is refused, nothing up, nothing posted; a newer production line after it brings the live copy back, and a
# further take-down posts. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "deploy-down-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; R=owner/code; mkdir -p "$T/r"
# closing an issue fails while $FAKEGH/close-fail exists (a wrapper before the fake gh on PATH)
mv "$T/bin/gh" "$T/bin/gh-fake"; printf '#!/bin/sh\nif [ "${1:-} ${2:-}" = "issue close" ] && [ -f "$FAKEGH/close-fail" ]; then echo "HTTP 502: the close failed" >&2; exit 1; fi\nexec sh "%s" "$@"\n' "$T/bin/gh-fake" > "$T/bin/gh"; chmod +x "$T/bin/gh"
# held: the take-down still out and its issue open, nothing said read
held() { ! grep -q "$2" "$T/out" || fail "$1: said read while its close failed"; [ "$(cat "$T/gh/issues/$3/state")" != CLOSED ] || fail "$1: closed while closing fails"
  cs out; grep -qx 'out down-staging' "$T/out" || fail "$1: no longer out while its issue is open"; }
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
CLAUDE_CODE_SESSION_ID=dr; export CLAUDE_CODE_SESSION_ID; sh "$GS" lock-take dr > "$T/out" 2>&1 || fail 'the lock could not be taken'
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rep() { Q=deploy-$1-$2; rm -rf "$T/r/$Q"; rr_put "$Q" report.txt "$(printf 'by: DP\ncommit: %s\ndecisions: none\n%s' "$X" "$3")"; send "$Q"; sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
ad() { sh "$QS" addresses 1 > "$T/ad" 2>&1 || fail 'addresses failed'; }
X=$(git --git-dir="$T/code.git" rev-parse main); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs" "$F/w1"
printf 'issue\t90\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"; : > "$F/named"; : > "$F/passed"; : > "$F/done"
tw_hand "candidate 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
printf 'issue\t91\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > "$F/d1/ask"; : > "$F/d1/passed"; printf 'd1\tpassed\t1\nstaging\thttp://127.0.0.1:5001\nstays\tup\n' > "$F/d1/read"
printf 'issue\t92\n' > "$F/cs/ask"; : > "$F/cs/passed"; : > "$F/cs/done"; : > "$F/w1/done"
# FB-2 A4: a D1 that did not stay up, its staging run's issue closed: nothing is up, nothing posted
printf 'd1\tpassed\t1\nstaging\thttp://127.0.0.1:5001\n' > "$F/d1/read"; : > "$F/cs/issue-closed"; n0=$(ls "$T/gh/issues" 2>/dev/null | grep -c . || true)
cs deploy down staging 'Take the test site down'; [ "$RC" = 1 ] && ok "^refused down staging: nothing is up: the test site at http://127.0.0.1:5001 was taken down after its run$"
[ "$(ls "$T/gh/issues" 2>/dev/null | grep -c . || true)" = "$n0" ] || fail 'a take-down was posted with nothing up'
printf 'd1\tpassed\t1\nstaging\thttp://127.0.0.1:5001\nstays\tup\n' > "$F/d1/read"; rm -f "$F/cs/issue-closed"
ad; grep -qx 'test site: http://127.0.0.1:5001, up' "$T/ad" || fail "the test site before its take-down: $(cat "$T/ad")"
cs deploy down staging 'Take the test site down'; [ "$RC" = 0 ] || fail "the take-down exited $RC"; I=$(sed -n 's/^asked \([0-9]*\) down staging$/\1/p' "$T/out"); [ -n "$I" ] || fail 'no take-down posted'
cs out; ok '^out down-staging$'
# a report with no down: line: refused, posted back once
rep "$I" 1 'outcome: down'; cs decide down-staging; [ "$RC" = 0 ] || fail "the read exited $RC"; ok '^dn-refused staging 1$'
K=$(ls "$T/gh/issues/$I/comments" | sort -n | tail -n 1); [ "$(head -n 1 "$T/gh/issues/$I/comments/$K")" = 'vid: refused dn-1' ] || fail 'the refused report was not posted back'
cs decide down-staging; ! grep -q '^dn-refused' "$T/out" || fail 'the refused report was posted back twice'
# failed down: told, the issue closed, the site still up
rep "$I" 2 'outcome: failed down — x'; : > "$FAKEGH/close-fail"; cs decide down-staging; held 'the failed take-down' '^down-failed' "$I"; rm -f "$FAKEGH/close-fail"
cs decide down-staging; ok '^down-failed staging: x$'
[ "$(cat "$T/gh/issues/$I/state")" = CLOSED ] || fail 'the failed take-down was not closed'
ad; grep -qx 'test site: http://127.0.0.1:5001, up' "$T/ad" || fail "the test site after a failed take-down: $(cat "$T/ad")"
cs out; ! grep -q '^out down-' "$T/out" || fail 'a read take-down is still out'
# FB-2 A4: a take-down never reported: asked again once, then lost: `down-lost staging`, closed, the site still up, staging free
cs deploy down staging 'Take the test site down'; [ "$RC" = 0 ] || fail "the lost take-down exited $RC"; L=$(sed -n 's/^asked \([0-9]*\) down staging$/\1/p' "$T/out")
printf 'close-wait-minutes: 0\n' >> .vid/tw/settings
cs decide down-staging; [ "$RC" = 0 ] && ok '^close-again down-staging dn$'
: > "$FAKEGH/close-fail"; cs decide down-staging; held 'the lost take-down' '^down-lost' "$L"; rm -f "$FAKEGH/close-fail"
cs decide down-staging; [ "$RC" = 0 ] || fail "the lost read exited $RC"; ok '^down-lost staging$'
[ "$(cat "$T/gh/issues/$L/state")" = CLOSED ] || fail 'the lost take-down was not closed'
ls -d .vid/decide/stage/1/1/dn-staging*/lost > /dev/null 2>&1 || fail 'the lost take-down has no lost in its folder'
cs out; ! grep -q '^out down-' "$T/out" || fail 'a lost take-down is still out'
ad; grep -qx 'test site: http://127.0.0.1:5001, up' "$T/ad" || fail "the test site after a lost take-down: $(cat "$T/ad")"
# FB-2 A4: a refused report posted back, then quiet past the wait: lost as well, the issue closed, staging free
cs deploy down staging 'Take the test site down'; [ "$RC" = 0 ] || fail "the refused-then-quiet take-down exited $RC"; M=$(sed -n 's/^asked \([0-9]*\) down staging$/\1/p' "$T/out")
rep "$M" 1 'outcome: down'; cs decide down-staging; [ "$RC" = 0 ] && ok '^dn-refused staging 1$'
cs decide down-staging; [ "$RC" = 0 ] && ok '^close-again down-staging dn$'; ! grep -q '^down-lost' "$T/out" || fail 'the refused-then-quiet take-down was lost before it was asked again'
K=$(ls "$T/gh/issues/$M/comments" | sort -n | tail -n 1); [ "$(head -n 1 "$T/gh/issues/$M/comments/$K")" = 'vid: again dn' ] || fail 'the refused-then-quiet take-down was not asked again'
cs decide down-staging; [ "$RC" = 0 ] || fail "the refused-then-quiet read exited $RC"; ok '^down-lost staging$'
[ "$(cat "$T/gh/issues/$M/state")" = CLOSED ] || fail 'the refused-then-quiet take-down was not closed'
cs out; ! grep -q '^out down-' "$T/out" || fail 'a refused-then-quiet take-down is still out'
# a second take-down, down: read, closed, the addresses say so
cs deploy down staging 'Take the test site down'; [ "$RC" = 0 ] || fail "the second take-down exited $RC"; J=$(sed -n 's/^asked \([0-9]*\) down staging$/\1/p' "$T/out")
rep "$J" 1 "$(printf 'outcome: down\ndown: staging http://127.0.0.1:5001')"; : > "$FAKEGH/close-fail"; cs decide down-staging; held 'the take-down read down' '^down staging' "$J"; rm -f "$FAKEGH/close-fail"
cs decide down-staging; ok '^down staging 1$'
[ "$(cat "$T/gh/issues/$J/state")" = CLOSED ] || fail 'the take-down was not closed'
grep -q "^deploy-down target=staging at=$X stage=1 issue=$J result=down words=\"Take the test site down\"" .vid/metrics-events || fail "no deploy-down event: $(grep deploy-down .vid/metrics-events)"
ad; grep -qx "test site: http://127.0.0.1:5001, taken down at the owner's word" "$T/ad" || fail "the test site after its take-down: $(cat "$T/ad")"
cs deploy down staging 'Take the test site down'; [ "$RC" = 1 ] && ok "^refused down staging: nothing is up: the test site at http://127.0.0.1:5001 was taken down at the owner's word$"
# the live copy on this machine
mkdir -p "$F/d2" "$F/cp"; printf 'issue\t95\ncommit\t%s\nasked\t2026-11-10T12:00:00Z\n' "$X" > "$F/d2/ask"; : > "$F/d2/passed"; : > "$F/cp/passed"
printf 'd2\tpassed\t1\nproduction\thttp://127.0.0.1:5201\n' > "$F/d2/read"; printf '%s\tD2 #95\t2026-11-10T12:30:00Z\n' "$X" > .vid/decide/production; tw_hand "production 1 | stand-in: D2 #95 at $(printf %.12s "$X")"
ad; grep -qx 'live copy: http://127.0.0.1:5201' "$T/ad" || fail "the live copy before its take-down: $(cat "$T/ad")"
cs deploy down production 'Take the practice copy down'; [ "$RC" = 0 ] || fail "the live copy's take-down exited $RC"; P=$(sed -n 's/^asked \([0-9]*\) down production$/\1/p' "$T/out")
rep "$P" 1 "$(printf 'outcome: down\ndown: production http://127.0.0.1:5201')"; cs decide down-production; ok '^down production 1$'
ad; ! grep -q '^live copy:' "$T/ad" || fail "the addresses still name the live copy: $(cat "$T/ad")"
n0=$(ls "$T/gh/issues" | grep -c .); cs deploy down production 'Again'; [ "$RC" = 1 ] || fail "a take-down of the live copy already down exited $RC"
ok "^refused down production: nothing is up: the live copy at http://127.0.0.1:5201 was taken down at the owner's word$"; [ "$(ls "$T/gh/issues" | grep -c .)" = "$n0" ] || fail 'a take-down of the live copy already down was posted'
# FB-2 A4: a newer production line (a recovery), after the take-down: the live copy is up again, and a further take-down posts
NT=$(date -u -v+1H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '+1 hour' '+%Y-%m-%dT%H:%M:%SZ'); printf '%s\trecovered #95\t%s\n' "$X" "$NT" >> .vid/decide/production
ad; grep -qx 'live copy: http://127.0.0.1:5201' "$T/ad" || fail "the live copy after a newer production line: $(cat "$T/ad")"
cs deploy down production 'Take it down again'; [ "$RC" = 0 ] && ok '^asked [0-9]* down production$' || fail "a further take-down of the live copy exited $RC"
exit 0
