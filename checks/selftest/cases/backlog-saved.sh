#!/bin/sh
# Purpose: selftest case — the backlog is saved with ViD's records and comes back as it was (FB-3 D1). On the writer's toy, an own
# question and two own items, reordered and marked; state-save, then state-restore in an empty folder: the file byte for byte, and a
# sync there keeps the order and the marks. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "backlog-saved: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; QS=$CHECKS/queue.sh; B=.vid/decide/queue/backlog
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "queue.sh $* exited $RC"; }
qs ask own 'Which colour is the footer?'; qs backlog add 'push the branch'; qs backlog add 'wait for Ann' --who Ann
qs backlog set B2 --place top --state waiting --note 'asked on Monday'; qs backlog set B1 --state doing
cp "$B" "$T/b"; sh "$GS" state-save > "$T/out" 2>&1 || fail 'state-save failed'
mkdir "$T/new"; cd "$T/new"; rm -rf "$T/toy"; sh "$GS" state-restore owner/code-spec > "$T/out" 2>&1 || fail 'state-restore failed'
cmp -s "$T/b" "$B" || { diff "$T/b" "$B" > "$T/out" 2>&1 || true; fail 'the backlog did not come back as it was saved'; }
qs sync; cmp -s "$T/b" "$B" || { diff "$T/b" "$B" > "$T/out" 2>&1 || true; fail 'a sync in the restored folder changed the backlog'; }
exit 0
