#!/bin/sh
# Purpose: selftest case — the lock on an empty state repository (the GM-4 proof's D2). GitHub makes the first branch pushed to an
# empty repository its default branch, and refuses to delete the default branch. On the GitHub manual toy (fixtures/manual.sh),
# its state repository made empty, with a hook that acts as GitHub does: the first lock-take leaves a branch other than
# vid-state/lock as the default, so lock-free frees the lock (exit 0, the branch gone) and a second take and free work too. When
# GitHub refuses the free, lock-free's refusal carries GitHub's own reason, and the lock is kept. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "state-lock-empty-repo: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
gh repo create owner/vid-state --private > /dev/null
SR=$(mn_state); [ -d "$SR" ] && [ -z "$(git --git-dir="$SR" for-each-ref refs/heads)" ] || fail 'the state repository is not empty: the scene is wrong'
# GitHub's rules, as a hook: the first branch pushed to an empty repository is its default (kept in default-branch); deleting the
# default branch is refused with GitHub's words; and, while refuse-lock-free exists, deleting the lock is refused too
cat > "$SR/hooks/pre-receive" <<'HOOK'
#!/bin/sh
D=$(git rev-parse --git-dir)/default-branch; fresh=''; [ -n "$(git for-each-ref refs/heads)" ] || fresh=1
while read -r o n r; do
  [ -z "$fresh" ] || [ -s "$D" ] || printf '%s\n' "$r" > "$D"
  case $n in *[!0]*) ;; *) if [ "$r" = "$(cat "$D" 2>/dev/null)" ]; then echo "error: refusing to delete the current branch: $r (Cannot delete the default branch)" >&2; exit 1; fi
    if [ -f "$(git rev-parse --git-dir)/refuse-lock-free" ]; then echo 'error: the free was refused for the self-test (HTTP 503)' >&2; exit 1; fi ;; esac
done; exit 0
HOOK
chmod +x "$SR/hooks/pre-receive"; rm -f "$SR/default-branch"
CLAUDE_CODE_SESSION_ID=empty-a; export CLAUDE_CODE_SESSION_ID
sh "$GS" lock-take > "$T/out" 2>&1 || fail 'the first lock-take on an empty state repository failed'
[ -n "$(mn_lock)" ] || fail 'the lock is not on the state repository after the take'
DB=$(cat "$SR/default-branch" 2>/dev/null || true); [ "$DB" != refs/heads/vid-state/lock ] || fail 'the lock became the default branch of the empty state repository'
RC=0; sh "$GS" lock-free > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "lock-free exited $RC on the repository whose first push the lock was"
[ -z "$(mn_lock)" ] || fail 'the lock is still there after lock-free'
sh "$GS" lock-take > "$T/out" 2>&1 || fail 'the second lock-take failed'; sh "$GS" lock-free > "$T/out" 2>&1 || fail 'the second lock-free failed'
[ "$(cat "$SR/default-branch" 2>/dev/null || true)" = "$DB" ] || fail 'the default branch moved on the second take'
# GitHub refuses the free: its reason in the refusal line, the lock kept
sh "$GS" lock-take > "$T/out" 2>&1 || fail 'the third lock-take failed'; : > "$SR/refuse-lock-free"
RC=0; sh "$GS" lock-free > "$T/out" 2>&1 || RC=$?; rm -f "$SR/refuse-lock-free"
[ "$RC" = 1 ] || fail "a refused free exited $RC, not 1"
tail -n 1 "$T/out" | grep -q 'the lock could not be freed.*HTTP 503' || fail "the refusal's line does not carry GitHub's reason"
[ -n "$(mn_lock)" ] || fail 'a refused free removed the lock'
echo 'state-lock-empty-repo: ok'
