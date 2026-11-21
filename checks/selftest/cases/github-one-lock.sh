#!/bin/sh
# Purpose: selftest case — GM-4 F2's github.sh parts: one caller mark and one rule for where the lock lives. On the fake gh with
# ViD's state repository: while another live session holds the lock, a post marked as /vid next's call (VID_CALLER=next) is refused,
# naming the holder, as any call outside the round is; only the round's own mark (VID_CALLER=round) is let past that check; with this
# session's own lock, /vid next's call is not refused for the lock. The lock lives by one rule in both modes: in state-repo:, and
# with no state-repo: in the spec repository, in GitHub auto and GitHub manual alike, each take and free seen in the fake gh's lock
# log (K12); github.sh writes that rule once (no stsole). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "github-one-lock: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
gh repo create owner/vid-state --private > /dev/null
G=$CHECKS/github.sh
# one caller mark: /vid next's calls are checked as any call outside the round is
CLAUDE_CODE_SESSION_ID=other sh "$G" lock-take > "$T/out" 2>&1 || fail 'the other session could not take the lock'
rc=0; CLAUDE_CODE_SESSION_ID=me VID_CALLER=next sh "$G" tw-handovers > "$T/out" 2>&1 || rc=$?
[ "$rc" = 1 ] && grep -q "the run's lock is held by other" "$T/out" || fail "a call marked VID_CALLER=next was not refused while another session holds the lock (exit $rc)"
CLAUDE_CODE_SESSION_ID=me VID_CALLER=round sh "$G" tw-handovers > "$T/out" 2>&1 || :
! grep -q 'lock is held' "$T/out" || fail "the round's own call was refused for the lock"
CLAUDE_CODE_SESSION_ID=other sh "$G" lock-free > "$T/out" 2>&1 || fail 'the other session could not free the lock'
CLAUDE_CODE_SESSION_ID=me sh "$G" lock-take > "$T/out" 2>&1 || fail 'this session could not take the lock'
CLAUDE_CODE_SESSION_ID=me VID_CALLER=next sh "$G" tw-handovers > "$T/out" 2>&1 || :
! grep -q 'lock is held' "$T/out" || fail "/vid next's call was refused with this session's own lock"
CLAUDE_CODE_SESSION_ID=me sh "$G" lock-free > "$T/out" 2>&1 || fail 'this session could not free the lock'
# one rule for where the lock lives, in both modes
where() { : > "$FAKEGH/locks"; CLAUDE_CODE_SESSION_ID=me sh "$G" lock-take > "$T/out" 2>&1 || fail "the lock could not be taken ($1)"
  CLAUDE_CODE_SESSION_ID=me sh "$G" lock-free > "$T/out" 2>&1 || fail "the lock could not be freed ($1)"
  [ "$(cat "$FAKEGH/locks")" = "$(printf '%s taken\n%s freed' "$2" "$2")" ] || { cat "$FAKEGH/locks" >&2; fail "the lock was not taken and freed in $2 ($1)"; }; }
where 'GitHub auto, state-repo: set' owner/vid-state
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
where 'GitHub manual, state-repo: set' owner/vid-state
grep -v '^state-repo:' .vid/tw/settings > "$T/s"; cat "$T/s" > .vid/tw/settings
where 'GitHub manual, no state-repo:' owner/code-spec
grep -v '^setup-answered key=github-mode ' .vid/plan/setup > "$T/st" || true; cat "$T/st" > .vid/plan/setup
where 'GitHub auto, no state-repo:' owner/code-spec
! grep -q 'stsole' "$G" || fail 'github.sh still holds stsole, a second rule for the lock in GitHub manual'
[ "$(grep -c '|| ST=\$SPEC' "$G")" = 1 ] || fail 'the rule for where the lock lives is not written once'
echo 'github-one-lock: ok'
