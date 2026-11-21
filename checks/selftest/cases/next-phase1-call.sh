#!/bin/sh
# Purpose: selftest case — one /vid next call in phase 1 (GM-1 S9, its case next-phase1-call). After a switch on the fake gh, the
# call's scripts in the skill's order (devagent-start.sh mode, GM-4 F15; connect.sh start, next.sh read, next.sh triggers, connect.sh end) write only to
# state-repo: (the fake's write log), save the records (GM-4 F3: the call's read is .vid/round/read, no longer under .vid/next/), and free the lock. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "next-phase1-call: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || { cp "$T/mo" "$T/out"; fail "the switch exited $MN_RC"; }
P=$(gh_issue 'Phase 1'); gh_sub "$N1" "$P"; gh_wclear
sh "$CHECKS/devagent-start.sh" mode > "$T/out" 2>&1 && grep -qx manual "$T/out" || fail 'the mode command does not read GitHub manual'   # GM-4 F15: the one mode command
sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || fail 'connect.sh start failed'
sh checks/next.sh read > "$T/out" 2>&1 || fail 'next.sh read failed'
grep -q "^sub	$N1	$N1	$P	" .vid/round/read || fail 'the read did not record the sub-issue'
sh checks/next.sh triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
sh checks/connect.sh end > "$T/out" 2>&1 || fail 'connect.sh end failed'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the call'
[ -s "$FAKEGH/writes" ] || fail 'the call saved nothing'
grep -v '^owner/vid-state ' "$FAKEGH/writes" > "$T/w" && { cp "$T/w" "$T/out"; fail 'the call wrote to a repository but state-repo:'; }
git init -q "$T/r"; git -C "$T/r" fetch -q "$(mn_state)" refs/heads/vid-state/records && git -C "$T/r" cat-file -e FETCH_HEAD:RUN-STATE.md || fail 'the records were not saved'   # GM-4 F3: the read is .vid/round/read now, no .vid/next/read
echo 'next-phase1-call: ok'
