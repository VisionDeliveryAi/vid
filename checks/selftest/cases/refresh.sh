#!/bin/sh
# Purpose: selftest case — the one refresh (v0.26.10.26.7, R1, W-1), checks/refresh.sh. A folder with no checks/ is refreshed and its
# commit holds checks/ alone; a second run says current. A committed checks/ whose records version is this one's but whose files differ
# is not current, and is refreshed. A local edit committed since the last refresh is listed and waits for the yes (exit 3, nothing
# copied); --yes copies. A project's own added case is never compared, listed or removed. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "refresh: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
export GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@b GIT_COMMITTER_NAME=a GIT_COMMITTER_EMAIL=a@b
RF=$CHECKS/refresh.sh; [ -f "$RF" ] || fail 'no checks/refresh.sh'
rf() { RC=0; sh "$RF" "$@" > "$T/out" 2>&1 || RC=$?; }
same() { ( cd "$CHECKS" && find . -type f ) | while IFS= read -r f; do cmp -s "$CHECKS/$f" "checks/$f" || { echo "$f"; break; }; done; }
# no checks/ at all
mkdir "$T/p1"; cd "$T/p1"; git init -q; echo x > PRD.md; git add PRD.md; git commit -qm init
mkdir -p "$T/hk"; cp "$CHECKS/hooks/commit-msg" "$T/hk/commit-msg"; chmod +x "$T/hk/commit-msg"; git config core.hooksPath "$T/hk"   # ViD's commit-msg court, as in a project
rf; [ "$RC" = 0 ] || fail "no checks/: exit $RC"; grep -q '^refresh: refreshed ' "$T/out" || fail 'no checks/: not refreshed'
[ -z "$(same)" ] || fail "no checks/: $(same) differs after the refresh"
git log -1 --format=%s | grep -q '^Refresh checks/ to VID ' || fail "the subject: $(git log -1 --format=%s)"
[ -z "$(git show --name-only --format= HEAD | grep -v '^checks/')" ] || fail 'the refresh commit holds more than checks/'
[ -f checks/planner.sh ] && [ -f checks/records-version ] || fail 'the planner is not there to plan with'
rf; [ "$RC" = 0 ] && grep -qx 'refresh: current' "$T/out" || fail 'a refreshed checks/ is not current'
# a stale checks/ at the same records version
mkdir "$T/p2"; cd "$T/p2"; git init -q; mkdir checks; ( cd "$CHECKS" && tar cf - . ) | ( cd checks && tar xf - )
printf '#!/bin/sh\necho "ViD land: unknown"; exit 2\n' > checks/land.sh; git add -A; git commit -qm init
[ "$(grep '^records: ' checks/records-version)" = "$(grep '^records: ' "$CHECKS/records-version")" ] || fail 'the stale copy is not at the plugin records version'
rf; [ "$RC" = 0 ] || fail "stale: exit $RC"; grep -qx 'stale land.sh' "$T/out" || fail 'stale: land.sh not named'
grep -q '^refresh: refreshed ' "$T/out" || fail 'stale: not refreshed'; cmp -s checks/land.sh "$CHECKS/land.sh" || fail 'stale: land.sh not copied'
mkdir -p .vid; printf 'mode: tickets\n' > .vid/RUN-STATE.md; : > INVENTORY.md; RC=0; sh checks/land.sh draft --review "$T/none" > "$T/out" 2>&1 || RC=$?   # the refreshed land.sh knows --review (R5)
grep -q 'unknown' "$T/out" && fail 'the refreshed land.sh does not know --review'; grep -q -- "--review $T/none: no review output there" "$T/out" || fail "land.sh draft --review: $(cat "$T/out")"; rm -rf .vid INVENTORY.md
# a local edit since the last refresh, and the project's own case
mkdir -p checks/selftest/cases; echo 'echo own' > checks/selftest/cases/zz-own-case.sh; echo '# local' >> checks/queue.sh
git add -A; git commit -qm 'a local edit'; H=$(git rev-parse HEAD)
rf; [ "$RC" = 3 ] || fail "a local edit: exit $RC, not 3"; grep -q "^refresh: waits for the owner's yes" "$T/out" || fail 'a local edit: no wait'
grep -q '^commit [0-9a-f]* a local edit$' "$T/out" || fail 'a local edit: not listed'; grep -q 'zz-own-case' "$T/out" && fail 'the own case is compared'
[ "$(git rev-parse HEAD)" = "$H" ] && tail -n 1 checks/queue.sh | grep -qx '# local' || fail 'a local edit: copied before the yes'
rf --yes; [ "$RC" = 0 ] && grep -q '^refresh: refreshed ' "$T/out" || fail "--yes: not refreshed ($RC)"
cmp -s checks/queue.sh "$CHECKS/queue.sh" || fail '--yes: queue.sh not copied'; [ -f checks/selftest/cases/zz-own-case.sh ] || fail 'the own case was removed'
rf; grep -qx 'refresh: current' "$T/out" || fail 'with the own case kept, not current'
# a refused commit: the copy is left uncommitted and unstaged, and the next run still sees it as not committed (8.1b's real test)
mkdir "$T/p3"; cd "$T/p3"; git init -q; echo x > PRD.md; git add PRD.md; git commit -qm init
mkdir -p "$T/hk3"; printf '#!/bin/sh\necho "a stub court refuses" >&2; exit 1\n' > "$T/hk3/commit-msg"; chmod +x "$T/hk3/commit-msg"; git config core.hooksPath "$T/hk3"
rf; [ "$RC" = 4 ] && grep -q '^refresh: the commit was refused' "$T/out" || fail "a refused commit: exit $RC"; [ -z "$(git diff --cached --name-only)" ] && [ ! -e checks ] && [ -z "$(git status --porcelain)" ] || fail 'the refused copy was left in the tree'
git config core.hooksPath "$T/hk"; rf; [ "$RC" = 0 ] && grep -q '^refresh: refreshed ' "$T/out" || fail "after a refused commit, the next run: $(tail -n 1 "$T/out") ($RC)"
git log -1 --format=%B | grep -qx 'REQs: none' && git log -1 --format=%B | grep -qx 'Seams: none' && git log -1 --format=%B | grep -q '^Decisions: none' || fail "the refresh commit's template: $(git log -1 --format=%B)"
echo 'refresh: ok'
