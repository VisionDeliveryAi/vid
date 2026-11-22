#!/bin/sh
# Purpose: selftest case — ViD makes every repository the setup names (FB-2 A1). On the GitHub manual toy (fixtures/manual.sh), in
# GitHub auto, with the fake gh holding none of the three (the code repository marked not made, $FAKEGH/no-code, its remote not
# there yet) and .vid/tw/settings naming repo:, spec-repo: and state-repo:: connect.sh start makes each, `--private`, before the
# records' restore and the lock, one `connect <key>:` line each and one `<key> <name> created` line of .vid/tw/log each; the code
# and spec repositories are left empty, and the state repository holds no file on main (the lock's take pushes an empty main to it). A second start makes none and prints none of those
# lines. After the setup renames the state repository, the next start makes the new one. The code repository there and public, with
# no repo line in the log, is used as it is: a connect repo: line, `repo owner/code exists`, none made. Read: `repo create` passes the allow list
# only for the one name mkrepo was given, --private, four arguments, and that switch is set in mkrepo alone and never taken from the
# environment. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "repo-setup-make: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
C() { RC=0; sh "$CHECKS/connect.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
made() { grep -c '^gh repo create ' "$T/gh/log" || true; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="auto" words="DevAgent works them" at=2026-11-03T10:00:00Z\n' >> .vid/plan/setup
rm -rf "$T/gh/repos"; touch "$T/gh/no-code"; echo "$T/empty-code.git" > "$T/gh/remote"; : > "$T/gh/log"
gh repo view owner/code > /dev/null 2>&1 && fail 'the fake gh still serves the code repository marked not made'
# the first start: all three made, private, each with its line, before the restore and the lock
C start; [ "$RC" = 0 ] || fail "the first start exited $RC"
for k in repo spec-repo state-repo; do [ "$(grep -c "^connect $k: " "$T/out")" = 1 ] || fail "the first start has not one connect $k: line"; done
for l in 'repo owner/code' 'spec-repo owner/code-spec' 'state-repo owner/vid-state'; do grep -q "^$l created at=" .vid/tw/log || fail "no log line: $l created"; done
[ "$(made)" = 3 ] || fail "the first start made $(made) repositories, not 3"
for n in owner/code owner/code-spec owner/vid-state; do grep -qx "gh repo create $n --private" "$T/gh/log" || fail "$n was not made with --private, alone"; done
[ "$(gh repo view owner/code --json isPrivate --jq .isPrivate)" = true ] || fail 'the code repository is not private'
for n in owner/code-spec owner/vid-state; do [ "$(gh repo view "$n" --json isPrivate --jq .isPrivate)" = true ] || fail "$n is not private"; done
[ -z "$(git --git-dir="$T/empty-code.git" for-each-ref)" ] || fail 'the code repository holds a branch'
[ -z "$(git --git-dir="$(gh repo view owner/code-spec --json url --jq .url)" for-each-ref)" ] || fail 'the spec repository holds a branch'
SG=$(gh repo view owner/vid-state --json url --jq .url); [ -z "$(git --git-dir="$SG" ls-tree -r refs/heads/main 2>/dev/null)" ] || fail 'the state repository holds a file on main'   # the lock's take pushes an empty main first (GM-4 proof D2)
a=$(grep -n '^connect state-repo: ' "$T/out" | cut -d: -f1); b=$(grep -n '^connect records: ' "$T/out" | cut -d: -f1); c=$(grep -n '^connect lock: ' "$T/out" | cut -d: -f1)
[ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ] || fail "the repositories are not made before the restore and the lock ($a, $b, $c)"
C end; [ "$RC" = 0 ] || fail "the end exited $RC"
# the second start: none made again
C start; [ "$RC" = 0 ] || fail "the second start exited $RC"
[ "$(made)" = 3 ] || fail 'the second start made a repository again'
grep -q '^connect \(repo\|spec-repo\|state-repo\): ' "$T/out" && fail 'the second start printed a repository line'
C end
# the state repository renamed: the next start makes the new one
sed 's|^state-repo:.*|state-repo: owner/vid-state-two|' .vid/tw/settings > "$T/s"; cat "$T/s" > .vid/tw/settings
C start; [ "$RC" = 0 ] || fail "the start after the rename exited $RC"
grep -qx 'gh repo create owner/vid-state-two --private' "$T/gh/log" && grep -q '^state-repo owner/vid-state-two created at=' .vid/tw/log || fail 'the renamed state repository was not made'
[ "$(made)" = 4 ] || fail "after the rename $(made) repositories were made, not 4"
C end
# FB-2 A1: the code repository there and public, no repo line in the log: used as it is, `repo owner/code exists`, none made
grep -v '^repo ' .vid/tw/log > "$T/l" || true; cat "$T/l" > .vid/tw/log; echo false > "$T/gh/code-private"
C start; [ "$RC" = 0 ] || fail "the start with the code repository public exited $RC"; grep -q '^connect repo: ' "$T/out" || fail 'the start with the code repository public printed no connect repo: line'
grep -q '^repo owner/code exists at=' .vid/tw/log || fail 'no log line: repo owner/code exists'; [ "$(grep -c '^gh repo create owner/code ' "$T/gh/log")" = 1 ] || fail 'the public code repository was made again'
C end
# read: the allow list's repo create, one name, --private, four arguments; its switch set in mkrepo alone, empty first
G=$CHECKS/github.sh; RB=$(awk "/^    'repo create'\\)/ { on = 1 } on { print } on && / ;;\$/ { exit }" "$G")
for p in '"${3:-}" = "$MKREPO"' '"${4:-}" = --private' '$# -eq 4'; do printf '%s\n' "$RB" | grep -F -- "$p" | grep -q MKREPO || fail "the allow list's repo create does not hold $p for MKREPO"; done
printf '%s\n' "$RB" | grep -q 'SPECSETUP\|STATESETUP' && fail 'the allow list keeps a switch of its own for the spec or the state repository'
MK=$(awk '/^mkrepo\(\) / { on = 1 } on { print } on && /; }$/ { exit }' "$G")
[ "$(grep -c 'MKREPO=\$' "$G")" = 1 ] && printf '%s\n' "$MK" | grep -q 'MKREPO=\$2 ghc repo create "\$2" --private' || fail 'MKREPO is not set in mkrepo alone, for its one repo create'
grep -q "^REPO=''.* MKREPO=''" "$G" || fail 'MKREPO is not emptied first, so the environment could set it'
echo 'repo-setup-make: ok'
