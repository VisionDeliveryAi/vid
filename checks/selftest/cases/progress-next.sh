#!/bin/sh
# Purpose: selftest case — the progress of a /vid next call and of a direct one (FB-3 D2). On GitHub manual's toy (fixtures/manual.sh),
# its checks/ a copy whose face.sh records its arguments: connect.sh start, once it holds the lock, names the call's parts, the first
# running, ViD's own work among them only when it is on, and says what it does as it goes; round.sh step is ViD's own work; the one
# read is Reading GitHub, `ticket <i> of <n>` each, and, read, Working out what changed; results-fetch and the closes' report reads say
# so, and so does the sort of the list (FB-5 A1); connect.sh end is Saving the records and leaves no parts, but keeps a stop. GitHub auto names the same. A start refused before
# the lock writes nothing under .vid/face; one that ends after it leaves the part stopped, with what it needs. In /vid mode's own call
# the connect names and clears no parts, and says its words alone. A read with no parts named writes nothing under .vid/face; a
# face.sh that fails fails no call. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"   # the plan page goes under HOME
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "progress-next: $*" >&2; cat "$T/out" >&2 2>/dev/null; echo '-- the calls of face.sh:' >&2; cat "$T/calls" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
gh repo create owner/vid-state --private > /dev/null; git config core.hooksPath checks/hooks
# the project's own checks/, the connect run from it, so the refresh finds it current
mkdir checks; ( cd "$CHECKS" && tar cf - --exclude ./selftest . ) | ( cd checks && tar xf - ); mv checks/face.sh checks/face-real.sh
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/calls"\nexec sh "${0%%/*}/face-real.sh" "$@"\n' "$T" > checks/face.sh
printf '# JobDigest — DECISIONS\n' > DECISIONS.md; mkdir "$T/nohooks"; git -c core.hooksPath="$T/nohooks" add -A; git -c core.hooksPath="$T/nohooks" commit -qm 'checks'; git rev-parse HEAD > .vid/tw/applied
N1=$(gh_issue 'Step S01'); N2=$(gh_issue 'Step S02'); for n in $N1 $N2; do printf 'published %s | step: S0%s | rows: - | at=2026-11-19T09:00:00Z\n' "$n" "$n" >> .vid/tw/log; done
C() { : > "$T/calls"; RC=0; sh checks/connect.sh "$@" > "$T/out" 2>&1 || RC=$?; }
calls() { grep '^wait ' "$T/calls" | sed 's/^wait //' > "$T/w" || :; }
has() { calls; grep -qxF -- "$1" "$T/w" || fail "${2:-no call}: wait $1"; }
st() { sh checks/face-real.sh standing 2> /dev/null | tr -d '\n' | sed 's/.*"wait":\({.*}\),"backlog".*/\1/'; }
run_() { st | sed -n 's/.*{"name":"\([^"]*\)","state":"now"}.*/\1/p'; }
# a start refused before the lock: another session's lock
CLAUDE_CODE_SESSION_ID=other sh checks/connect.sh start > "$T/out" 2>&1 || fail 'the other session could not start'
rm -rf .vid/face .vid/lock-session; C start; [ "$RC" = 1 ] || fail "a start under another session's lock exited $RC"
[ ! -e .vid/face ] || fail 'a start refused at the lock wrote under .vid/face'
git push -q "$(mn_state)" :refs/heads/vid-state/lock; rm -f .vid/connect-stage .vid/lock-session; : > "$T/calls"
# a read alone
sh checks/round.sh read > "$T/out" 2>&1 || fail 'the read alone failed'; [ ! -e .vid/face ] || fail 'a read with no parts named wrote under .vid/face'
# the whole call, own work off
C start; [ "$RC" = 0 ] || fail "the start exited $RC"
calls; [ "$(grep -v '^now' "$T/w" | head -n 2)" = 'parts Connecting and checking the project Reading GitHub Working out what changed Your list Saving the records
on Connecting and checking the project' ] || fail 'the start did not name the parts, the first running'
has "now checking the project's rules" 'the start does not say what it does'; has 'now checking GitHub access' 'the start does not say what it does'
[ "$(run_)" = 'Connecting and checking the project' ] || fail "after the start the running part is $(run_)"
: > "$T/calls"; sh checks/round.sh read > "$T/out" 2>&1 || fail 'the read failed'
calls; printf '%s\n' 'on Reading GitHub' 'now ticket 1 of 2' 'now ticket 2 of 2' 'on Working out what changed' > "$T/x"; cmp -s "$T/x" "$T/w" || fail 'the read does not say its part, each ticket and the next part, in order'
[ "$(run_)" = 'Working out what changed' ] || fail "after the read the running part is $(run_)"
: > "$T/calls"; sh checks/next-move.sh call > "$T/out" 2>&1 || fail 'the call'"'"'s show failed'
calls; printf '%s\n' 'on Working out what changed' 'on Your list' > "$T/x"; cmp -s "$T/x" "$T/w" || fail 'the call does not say its last two parts, in order'
[ "$(run_)" = 'Your list' ] || fail "after the call the running part is $(run_)"
: > "$T/calls"; : > "$T/empty"; sh checks/queue.sh sort "$T/empty" > "$T/out" 2>&1 || :; has 'now sorting your list' 'the sort does not say its part'
: > "$T/calls"; sh checks/github.sh results-fetch > "$T/out" 2>&1 || fail 'results-fetch failed'; has "now fetching the team's reports"
C end; [ "$RC" = 0 ] || fail "the end exited $RC"; calls; [ "$(paste -sd '|' "$T/w")" = 'on Saving the records|done' ] || fail 'the end is not Saving the records, then done'
[ ! -e .vid/face/wait ] || fail 'an ended call left its parts'
# own work on: its part is named, and round.sh step is it
printf 'setup-answered key=own-work value="on" words="yes" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
C start; [ "$RC" = 0 ] || fail "the start with own work on exited $RC"; calls; grep -qxF "parts Connecting and checking the project ViD's own work Reading GitHub Working out what changed Your list Saving the records" "$T/w" || fail 'with own work on its part is not named'
: > "$T/calls"; sh checks/round.sh step > "$T/out" 2>&1 || fail 'the round'"'"'s step failed'; calls; [ "$(grep -v '^now ' "$T/w" | head -n 1)" = "on ViD's own work" ] || fail "round.sh step is not ViD's own work"
[ "$(run_)" = "ViD's own work" ] || fail "in the round's step the running part is $(run_)"
sh checks/face-real.sh wait stop 'your yes' > /dev/null 2>&1; C end; [ "$RC" = 0 ] || fail 'the end failed'; st | grep -q '"stop":"your yes"' || fail 'the end dropped a stop'
grep -v 'key=own-work' .vid/plan/setup > "$T/s"; cat "$T/s" > .vid/plan/setup
# a call that fails on the way: the part it was at stopped, with what it needs, kept by the end
mv_() { : > "$T/calls"; RC=0; sh checks/next-move.sh call "$@" > "$T/out" 2>&1 || RC=$?; calls; }
lst() { [ "$(tail -n 1 "$T/w")" = "stop $1" ] || fail "the last word is not: stop $1"; }
C start; sh checks/round.sh read > /dev/null 2>&1; cp checks/queue.sh "$T/qreal.sh"; mv checks/queue.sh checks/queue-real.sh; printf '#!/bin/sh\n[ "$1" != raise ] || { echo "the list is held" >&2; exit 1; }\nexec sh "${0%%/*}/queue-real.sh" "$@"\n' > checks/queue.sh
mv_; [ "$RC" = 1 ] && grep -q 'could not be kept' "$T/out" || fail "with the list not to be kept the call exited $RC"
lst 'a look at the chat: your list could not be kept'; st | grep -qF '{"name":"Your list","state":"stopped"}' || fail "the part the list failed at is not stopped: $(st)"
C end; [ "$RC" = 0 ] || fail 'the end failed'; st | grep -q '"stop":"a look at the chat: your list' || fail 'the end dropped the stop of a call whose list was not kept'
rm checks/queue-real.sh; mv "$T/qreal.sh" checks/queue.sh
C start; sh checks/round.sh read > /dev/null 2>&1; mkdir "$T/nosave"; printf '#!/bin/sh\ncase "$*" in *vid-state*) exit 1 ;; esac\nexec %s "$@"\n' "$(command -v gh)" > "$T/nosave/gh"; chmod +x "$T/nosave/gh"
: > "$T/calls"; RC=0; PATH="$T/nosave:$PATH" sh checks/next-move.sh call own-work off 'no more' > "$T/out" 2>&1 || RC=$?; calls; [ "$RC" = 1 ] && grep -q '^not saved' "$T/out" || fail "with the records not to be saved the call exited $RC"
lst 'a look at the chat: the records were not saved, so the moves after it were not done'; C end
C start; mv .vid/round/read "$T/rd"; mv_; [ "$RC" = 1 ] || fail "with no read the call exited $RC"; lst 'a look at the chat, which says why it stopped'
# on its own, with no parts named: nothing of the panel's
rm -rf .vid/face; mv_; [ "$RC" = 1 ] && [ ! -e .vid/face ] || fail 'a call on its own that failed wrote .vid/face'
mv "$T/rd" .vid/round/read; C end
# between two moves: the lines that cannot be made again, the lock that cannot be renewed
wrap() { mv "checks/$1.sh" "checks/$1-real.sh"; printf '#!/bin/sh\n%s\nexec sh "${0%%/*}/%s-real.sh" "$@"\n' "$2" "$1" > "checks/$1.sh"; }
unwrap() { mv "checks/$1-real.sh" "checks/$1.sh"; }
two() { C start; sh checks/round.sh read > /dev/null 2>&1; : > "$T/tn"; mv_ own-work off 'no more' -- own-work off 'again'; [ "$RC" = 1 ] && grep -q '^done own-work off' "$T/out" && grep -q "^not done own-work off: $1" "$T/out" || fail "a call that fails between two moves exited $RC"; lst "$2"; C end; }
wrap next "[ \"\$1\" != triggers ] || { echo x >> '$T/tn'; [ \"\$(grep -c . '$T/tn')\" -lt 2 ] || exit 1; }"
two 'the call.s lines could not be made again' 'a look at the chat: what changed could not be worked out again, so the moves after it were not done'; unwrap next
wrap github '[ "$1" != lock-renew ] || exit 1'
two 'the call.s lock could not be renewed' "a look at the chat: the call's lock could not be renewed, so the moves after it were not done"; unwrap github
# a read and a round's step that fail: the part stopped, with what it needs, kept by the end; on their own, nothing of the panel's
mkdir "$T/nogh"; printf '#!/bin/sh\nexit 1\n' > "$T/nogh/gh"; chmod +x "$T/nogh/gh"
rf() { : > "$T/calls"; RC=0; PATH="$T/nogh:$PATH" sh checks/round.sh "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] || fail "with GitHub out of reach round.sh $1 exited $RC"; calls; }
C start; rf read; lst 'a look at the chat: GitHub could not be read'; st | grep -qF '{"name":"Reading GitHub","state":"stopped"}' || fail "the read that failed is not stopped: $(st)"
C end; st | grep -q '"stop":"a look at the chat: GitHub' || fail 'the end dropped the stop of a read that failed'
C start; rf step; grep -q '^error ' "$T/out" || fail 'the failed step printed no error line'; lst 'a look at the chat, which says why it stopped'; C end
# a read that fails inside a call that goes on (next-move.sh's, marked VID_CALLER=next) stops nothing
C start; : > "$T/calls"; RC=0; PATH="$T/nogh:$PATH" VID_CALLER=next sh checks/round.sh read > "$T/out" 2>&1 || RC=$?; calls; [ "$RC" = 1 ] && ! grep -q '^stop' "$T/w" || fail 'a read that fails inside a call that goes on stopped its part'; C end
rm -rf .vid/face; rf read; rf step; [ ! -e .vid/face ] || fail 'a read or a step on its own that failed wrote .vid/face'
# ended after the lock: the owner's no to the refresh
mkdir -p .vid/next; printf 'not now at=x\n' > .vid/next/refresh-no; C start; [ "$RC" = 3 ] || fail "a start under the owner's no exited $RC"
st | grep -q '"name":"Connecting and checking the project","state":"stopped"' && st | grep -q '"stop":"your yes to update the project' || fail "a start ended by the owner's no does not leave the part stopped with what it needs: $(st)"
rm .vid/next/refresh-no; printf '#!/bin/sh\ncase "$*" in *viewerPermission*) exit 1 ;; esac\nexec %s "$@"\n' "$(command -v gh)" > "$T/ghx"; mkdir "$T/badgh"; mv "$T/ghx" "$T/badgh/gh"; chmod +x "$T/badgh/gh"
RC=0; PATH="$T/badgh:$PATH" sh checks/connect.sh start > "$T/out" 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'GitHub is not ready' "$T/out" || fail "with GitHub not ready the start exited $RC"
st | grep -q '"stop":"GitHub' || fail "a start GitHub was not ready for says no need: $(st)"
# /vid mode's own call: no parts, its words alone; the end clears nothing
sh checks/face-real.sh wait parts 'Connecting and checking the project' 'Finding the published tickets' > /dev/null 2>&1; sh checks/face-real.sh wait on 'Connecting and checking the project' > /dev/null 2>&1
: > "$T/calls"; VID_CALLER=mode sh checks/connect.sh start > "$T/out" 2>&1 || fail "in /vid mode's call the start failed"; calls; ! grep -qE '^(parts|on|done|stop)' "$T/w" || fail "in /vid mode's call the connect named or cleared parts"
has 'now bringing the records up to date'; has 'now taking the turn'; has 'now checking GitHub access'
VID_CALLER=mode sh checks/connect.sh end > "$T/out" 2>&1 || fail "in /vid mode's call the end failed"; [ -s .vid/face/wait ] || fail "in /vid mode's call the end cleared the parts"
# GitHub auto: the same parts, none of own work
printf 'setup-answered key=github-mode value="auto" words="ViD builds it" at=2026-11-21T09:00:00Z\n' >> .vid/plan/setup
C start; [ "$RC" = 0 ] || fail "in GitHub auto the start exited $RC"; calls; grep -qxF 'parts Connecting and checking the project Reading GitHub Working out what changed Your list Saving the records' "$T/w" || fail 'GitHub auto does not name the same parts'
C end; [ "$RC" = 0 ] && [ ! -e .vid/face/wait ] || fail 'in GitHub auto the end left the parts'
# the closes' report reads
grep -q 'prog now' checks/close-decide.sh && grep -q 'prog now' checks/close-candidate.sh || fail 'a close'"'"'s report read does not say itself'
# a face.sh that fails
printf '#!/bin/sh\nexit 1\n' > checks/face.sh; C start; [ "$RC" = 0 ] || fail "with a failing face.sh the start exited $RC"; sh checks/round.sh read > "$T/out" 2>&1 || fail 'with a failing face.sh the read failed'; C end; [ "$RC" = 0 ] || fail "with a failing face.sh the end exited $RC"
exit 0
