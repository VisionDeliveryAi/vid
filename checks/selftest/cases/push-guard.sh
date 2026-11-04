#!/bin/sh
# Purpose: selftest case — pushes, only the stand-in's and only branches (v0.26.10.9 spec R22, R24; §5 push-guard). A
# stand-in's clone of an empty code repository (a local bare one, through the fake gh): `github.sh push main` makes
# and pushes the one empty root commit (`Initial commit`, `Stand-in: worker-1`) while the remote has no commit; then
# `push main` is refused, and so are HEAD:main, a `+` refspec, --force (alone and after a branch), and any name but
# vid/<n>; `push vid/1` is accepted. Nothing refused reaches the remote. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "push-guard: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main
gh_fake; gh_worker "$T/w" || fail 'the clone of the empty repository failed'
cd "$T/w"
sh "$CHECKS/github.sh" push main --worker 1 > "$T/out" 2>&1 || fail 'the root commit was refused on an empty repository'
R=$(git -C "$T/code.git" rev-parse refs/heads/main)
[ "$(git -C "$T/code.git" rev-list --count main)" = 1 ] && git -C "$T/code.git" log -1 --format=%B main | grep -qx 'Stand-in: worker-1' && git -C "$T/code.git" log -1 --format=%s main | grep -qx 'Initial commit' || fail 'main is not one root commit with its trailer'
[ "$(git -C "$T/code.git" rev-parse 'main^{tree}')" = "$(git hash-object -t tree /dev/null)" ] || fail 'the root commit is not empty'
no() { if sh "$CHECKS/github.sh" push "$@" > "$T/out" 2>&1; then fail "push $* was accepted"; fi; }
git checkout -q -b vid/1 main; printf 'x\n' > a.txt; git add a.txt; git commit -qm 'work'
git checkout -q main; printf 'y\n' > b.txt; git add b.txt; git commit -qm 'a second commit on main'
no main; grep -q 'the remote has commits already' "$T/out" || fail 'the second push of main does not say why'
no HEAD:main; no +vid/1; no --force; no vid/1 --force; no other; no vid/x; no refs/heads/vid/1
[ "$(git -C "$T/code.git" rev-parse refs/heads/main)" = "$R" ] || fail 'a refused push moved main'
git -C "$T/code.git" rev-parse -q --verify refs/heads/vid/1 > /dev/null && fail 'a refused push created vid/1'
git checkout -q vid/1
sh "$CHECKS/github.sh" push vid/1 > "$T/out" 2>&1 || fail 'push vid/1 was refused'
[ "$(git -C "$T/code.git" rev-parse refs/heads/vid/1)" = "$(git rev-parse vid/1)" ] || fail 'vid/1 did not reach the remote'
exit 0
