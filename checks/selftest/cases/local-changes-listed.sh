#!/bin/sh
# Purpose: selftest case — a refresh lists the project's local changes first (v0.9.8.1 R5). A toy project: checks/
# installed, two refresh commits, the last `Refresh checks/ to VID 0.9.7.0.7`, then a local commit under checks/, a commit
# elsewhere, an unstaged edit, a staged one and an untracked file under checks/. local-changes.sh, run from a
# subfolder, lists the refresh it counts from, the local commit only, and the three uncommitted changes; an earlier
# commit under checks/ is not listed; with no refresh commit it counts from the commit that first carried checks/.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "local-changes-listed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p "$T/p/checks" "$T/p/app"; cd "$T/p"; git init -q
printf 'a\n' > checks/a.sh; printf 'b\n' > checks/b.sh; printf 'c\n' > checks/c.sh; printf 'x\n' > app/x
g add -A; g commit -qm 'Install the law'
printf 'a0\n' >> checks/a.sh; g commit -qam 'Refresh checks/ to VID 0.9.7.0.5'
printf 'a1\n' >> checks/a.sh; g commit -qam 'a local fix before the refresh'
printf 'a2\n' >> checks/a.sh; g commit -qam 'Refresh checks/ to VID 0.9.7.0.7'
R=$(git rev-parse --short HEAD)
printf 'b1\n' >> checks/b.sh; g commit -qam 'a local fix (A-272)'; L=$(git rev-parse --short HEAD)
printf 'x1\n' >> app/x; g commit -qam 'product work'
printf 'a3\n' >> checks/a.sh; printf 'c1\n' >> checks/c.sh; g add checks/c.sh; printf 'n\n' > checks/new.sh
cd app; sh "$CHECKS/local-changes.sh" > "$T/out" 2>&1 || fail 'it failed'; cd ..
grep -qx "since $R Refresh checks/ to VID 0.9.7.0.7" "$T/out" || fail 'it does not count from the last refresh'
grep -qx "commit $L a local fix (A-272)" "$T/out" || fail 'the local commit is not listed'
grep -q 'product work' "$T/out" && fail 'a commit outside checks/ is listed'
grep -q 'before the refresh' "$T/out" && fail 'a commit before the refresh is listed'
grep -qx 'uncommitted .M checks/a.sh' "$T/out" && grep -qx 'uncommitted M. checks/c.sh' "$T/out" && grep -qx 'uncommitted ?? checks/new.sh' "$T/out" || fail 'the uncommitted changes are not all listed'
grep -q '^local-changes: 1 commit(s) and 3 uncommitted change(s)' "$T/out" || fail 'the counts are wrong'
# no refresh commit: from the commit that first carried checks/
mkdir -p "$T/q/checks"; cd "$T/q"; git init -q; printf 'a\n' > checks/a.sh; g add -A; g commit -qm 'Install the law'; I=$(git rev-parse --short HEAD)
printf 'a1\n' >> checks/a.sh; g commit -qam 'a local fix'
sh "$CHECKS/local-changes.sh" > "$T/out" 2>&1 || fail 'it failed with no refresh'
grep -qx "since $I Install the law" "$T/out" && grep -q '^commit .* a local fix$' "$T/out" || fail 'with no refresh it does not count from the install'
exit 0
