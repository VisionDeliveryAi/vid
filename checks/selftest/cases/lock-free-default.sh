#!/bin/sh
# Purpose: selftest case — the lock freed when it is the repository's default branch (FIX-BATCH-T2 §11, OW-4). On the GitHub
# manual toy, its state repository with the hook state-lock-empty-repo uses for GitHub's rules, and refs/heads/vid-state/lock
# its default branch, as on a repository whose first push was the lock (before the guard): lock-free by the holder passes and
# says the lock is freed in place; the branch is kept, naming no session; a second session's lock-take passes at once; the first
# session's lock-renew says the lock is lost (exit 3). Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "lock-free-default: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
mn_project "$T/p" > /dev/null 2>&1; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
gh repo create owner/vid-state --private > /dev/null; SR=$(mn_state)
cat > "$SR/hooks/pre-receive" <<'HOOK'
#!/bin/sh
D=$(git rev-parse --git-dir)/default-branch
while read -r o n r; do case $n in *[!0]*) ;; *) if [ "$r" = "$(cat "$D" 2>/dev/null)" ]; then echo "error: refusing to delete the current branch: $r" >&2; exit 1; fi ;; esac; done; exit 0
HOOK
chmod +x "$SR/hooks/pre-receive"; printf 'refs/heads/vid-state/lock\n' > "$SR/default-branch"
CLAUDE_CODE_SESSION_ID=old-a; export CLAUDE_CODE_SESSION_ID
sh "$GS" lock-take > "$T/out" 2>&1 || fail 'the lock-take failed'
L0=$(mn_lock); [ -n "$L0" ] || fail 'no lock after the take'
RC=0; sh "$GS" lock-free > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "lock-free of a lock that is the default branch exited $RC"
grep -q 'the lock freed in place' "$T/out" || fail 'lock-free did not say the lock is freed in place'
L1=$(mn_lock); [ -n "$L1" ] && [ "$L1" != "$L0" ] || fail 'the freed lock is not a new commit on the kept branch'
git --git-dir="$SR" show refs/heads/vid-state/lock:lock | grep -qx 'session: -' || fail 'the freed lock still names a session'
[ ! -f .vid/lock-session ] || fail "this folder still records its lock's session"
CLAUDE_CODE_SESSION_ID=new-b; export CLAUDE_CODE_SESSION_ID; VID_LOCK_COLD=900; export VID_LOCK_COLD
sh "$GS" lock-take > "$T/out" 2>&1 || fail 'a second session could not take a freed lock at once'
git --git-dir="$SR" show refs/heads/vid-state/lock:lock | grep -qx 'session: new-b' || fail 'the second session does not hold the lock'
printf 'old-a\n' > .vid/lock-session; CLAUDE_CODE_SESSION_ID=old-a; export CLAUDE_CODE_SESSION_ID
RC=0; sh "$GS" lock-renew > "$T/out" 2>&1 || RC=$?; [ "$RC" = 3 ] || fail "the first session's renew exited $RC, not 3 (lost)"
echo 'lock-free-default: ok'
