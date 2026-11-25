#!/bin/sh
# Purpose: selftest case — a review on the owner's own pull request is said (FB-5 C2). GitHub manual's toy: each call says `context
# publish #<n> <words>`, in `--short` too, and the backlog holds one item keyed publish:<n>, its words those, kept by a read in part,
# closed once the pull request is open no more; a view that fails is said so, and the queue forgets as before. GitHub auto, the ticket
# writer's toy: round.sh step says `publish #<n> <words>` once a change, a wait ends on it, the backlog holds it, and the call has no
# context line of it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
R=$(mktemp -d); trap 'rm -rf "$R"' EXIT
HOME=$R/home; export HOME; T=$R/manual; mkdir -p "$HOME" "$T" "$R/auto"
. "$CHECKS/selftest/fixtures/tw-toy.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "publish-review-said: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/backlog >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); H=0123456789abcdef0123456789abcdef01234567; B=.vid/decide/queue/backlog; QS=$CHECKS/queue.sh
pr() { d=$FAKEGH/prs/$1; mkdir -p "$d/comments"; echo 'a change' > "$d/title"; echo 'ticket: none' > "$d/body"; echo "br-$1" > "$d/head"; echo main > "$d/base"; echo OPEN > "$d/state"; echo false > "$d/draft"; echo "$H" > "$d/headoid"; echo "$2" > "$d/author"; echo 2026-11-20T08:00:00Z > "$d/commits"; }
rev() { printf '%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" >> "$FAKEGH/prs/$1/reviews"; }
item() { awk -F'\t' -v k="publish:$1" '$2 == k { print $3 "|" $4 "|" $5 "|" $7 }' "$B" | tail -n 1; }
# --- GitHub manual
mn_project "$T/p"; { printf 'mode: tickets\nplan: required\nrun: waiting\n\n## The plan\n\n```vid-plan\n'; cat "$T/plan.blk"; printf '```\n'; } > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup; printf 'owner-questions: all\n' >> .vid/tw/settings
git rev-parse HEAD > .vid/tw/applied; mkdir -p .vid/tw/out .vid/decide .vid/next; : > .vid/tw/handed; : > .vid/tw/log
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail "next.sh read failed ($1)"; sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail "next.sh triggers failed ($1)"; sh "$CHECKS/next.sh" triggers --short > "$T/S" 2> "$T/out" || fail "--short failed ($1)"; sh "$QS" raise "$T/L" > "$T/out" 2>&1 || fail "queue.sh raise failed ($1)"; cp "$T/L" "$T/out"; }
said() { grep -qxF "context${TB}publish${TB}#31${TB}$1" "$T/L" && grep -qxF "context${TB}publish${TB}#31${TB}$1" "$T/S" || fail "the call does not say: #31 $1"; }
pr 30 bo; pr 31 toy; rev 31 ana CHANGES_REQUESTED 2026-11-21T09:00:00Z 'Please drop the second file'
call 'asked'; said 'ana asks for changes'; [ "$(grep -c "^context${TB}publish" "$T/L")" = 1 ] || fail "a team's pull request is said"
[ "$(item 31)" = 'to do|you|pull request #31: ana asks for changes|-' ] || fail "the backlog's item is $(item 31)"
call 'asked still'; said 'ana asks for changes'; [ "$(grep -c "${TB}publish:31$TB" "$B")" = 1 ] || fail 'the item is there twice'
rev 31 ana APPROVED 2026-11-22T09:00:00Z ''; call 'approved'; said 'ana approved'; [ "$(item 31)" = 'to do|you|pull request #31: ana approved|-' ] || fail "the item's words did not follow"
# a view that fails: said so, the item kept, and the call not read as one read in part: the queue forgets what is raised no more
echo 'HTTP 502' > "$FAKEGH/prs/31/view-fail"; printf 'trigger:made-up:important:0123456789ab:S99\t1\timportant\ta made-up trigger\n' >> .vid/decide/queue/raised; call 'a failed view'
said 'its reviews could not be read'; [ "$(item 31 | cut -d'|' -f1)" = 'to do' ] || fail 'a failed view closed the item'; ! grep -q made-up .vid/decide/queue/raised || fail 'a failed view stops the forgetting'; rm -f "$FAKEGH/prs/31/view-fail"
# a read in part keeps it; open no more, it is done
call 'read again'; grep -vE "^(open|publish)$TB" .vid/round/read > "$T/r"; printf 'unread\tround\t-\tthe list failed\n' >> "$T/r"; cp "$T/r" .vid/round/read; sh "$QS" list > "$T/out" 2>&1 || fail 'queue.sh list failed'
[ "$(item 31 | cut -d'|' -f1)" = 'to do' ] || fail 'a read in part closed the item'
echo MERGED > "$FAKEGH/prs/31/state"; call 'merged'; ! grep -q "^context${TB}publish" "$T/L" || fail 'a merged pull request is said'
case $(awk -F'\t' '$5 ~ /^pull request #31:/ { print $3 "|" $7 }' "$B") in 'done|open no more') ;; *) fail 'the item is not done, with why, once the pull request is open no more' ;; esac
# the owner ended one: not again while it stands
pr 41 toy; call 'another'; n=$(awk -F'\t' '$2 == "publish:41" { print $1 }' "$B"); [ -n "$n" ] || fail 'another pull request is no item'; sh "$QS" backlog set "$n" --state 'done' > "$T/out" 2>&1 || fail 'the owner could not mark it done'
call 'ended by the owner'; [ "$(grep -c "${TB}publish:41$TB" "$B")" = 1 ] && [ "$(item 41 | cut -d'|' -f1)" = 'done' ] || fail 'one the owner ended came back while it stands'
# --- GitHub auto
T=$R/auto; tw_toy "$T/toy"; GS=$CHECKS/github.sh
rs() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $* exited $RC"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
pr 30 bo; pr 31 toy; printf 'spec-published pr=30 export=0123456789ab path=upstream/vid stamp=- at=2026-11-20T09:00:00Z\n' >> .vid/tw/log; rs step
grep -qxF 'publish #30 waits for an approval' "$T/out" && ! grep -q '^publish #31' "$T/out" || fail 'the step does not say the logged publish alone'
[ "$(item 30)" = 'to do|you|pull request #30: waits for an approval|-' ] || fail 'the backlog does not hold it in GitHub auto'
rs step; ! grep -q '^publish #' "$T/out" || fail 'said again with nothing changed'
VID_WAIT_TICK=1 VID_WAIT_MAX=1 rs wait; grep -qx timeout "$T/out" || fail 'a wait ended with nothing changed'
rev 30 ana CHANGES_REQUESTED 2026-11-21T09:00:00Z 'No'; VID_WAIT_TICK=1 VID_WAIT_MAX=5 rs wait; grep -qx new "$T/out" || fail 'a review did not end the wait'
rs step; grep -qxF 'publish #30 ana asks for changes' "$T/out" || fail 'the change is not said'; rs step; ! grep -q '^publish #' "$T/out" || fail 'the change is said twice'
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed in GitHub auto'; ! grep -q "^context${TB}publish" "$T/out" || fail 'GitHub auto has a context publish line'
F=$CHECKS/../skills; [ ! -d "$F/vid-run" ] || { grep -qF 'publish #<n> <words>' "$F/vid-run/SKILL.md" || fail 'vid-run has no line for it'; grep -qF 'context publish' "$F/vid-triggers/SKILL.md" || fail 'vid-triggers has no line for it'; }
echo 'publish-review-said: ok'
