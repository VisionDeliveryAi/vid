#!/bin/sh
# Purpose: selftest case — in ticket mode, at the main checkout, a commit's hooks go through WSL (FB-7 D1). With `wsl: yes` recorded,
# a faked native Windows shell (MINGW64_NT) and a fake `wsl.exe` (it logs its arguments, drops git's own variables as WSL does, and
# runs what it is given here; fixtures/windows-hooks.sh), a commit's pre-commit, commit-msg and post-commit each run as `wsl.exe -e env`
# with this side's core.autocrlf and core.excludesFile (windows-hook-settings), the index's name (as it is when relative, translated
# when absolute), and `sh` with the hook and its arguments translated.
# A partial commit's own index is the one checked, and what it leaves out stays out; a court's refusal and a message's refusal are the
# native hook's, words and exit code; a file left unstaged is not committed. Native, and wsl.exe never asked to run a hook: with
# `wsl: no`, with no answer, on a shell that is not Windows', in a linked worktree (a commit, and commit-msg run by hand), outside
# ticket mode. With WSL not starting, or no git answering in it, the commit's checks run natively, and one line says so. Env: CHECKS.
set -eu
fail() { echo "windows-hook-routes: $*" >&2; sed "s|$T|T|g;s/^/    /" "$T/wsl.log" "$T/o" >&2 2>/dev/null; exit 1; }
T=$(mktemp -d); T=$(cd "$T" && pwd -P); trap 'cd /; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/windows-hooks.sh"
H="$T/p/checks/hooks"; CF='GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=input GIT_CONFIG_KEY_1=core.excludesFile GIT_CONFIG_VALUE_1=/dev/null'
routed() { grep -qxF -- "$1" "$T/wsl.log" || fail "$2: no wsl.exe call '$(printf %s "$1" | sed "s|$T|T|g")'"; }
# a plain commit: the three hooks, the index by its relative name, an unstaged edit left out
stage one; echo unstaged > app/u.txt; echo '# later' >> .gitignore
ok "$WPATH" git commit -qm "$M"
routed "env $CF GIT_INDEX_FILE=.git/index sh $H/pre-commit" 'a plain commit'
routed "env $CF GIT_INDEX_FILE=.git/index sh $H/commit-msg $T/p/.git/COMMIT_EDITMSG" 'a plain commit'
grep -q "^env $CF .*sh $H/post-commit\$" "$T/wsl.log" || fail 'a plain commit: the post-commit hook did not go through wsl.exe'
grep -q "^env $CF sh -c .*git rev-parse --git-dir" "$T/wsl.log" || fail 'a plain commit: no probe of the git there, with the same settings'
[ -e .ran/seams ] || fail 'the courts did not run under the routed hook'
[ "$(git show --name-only --format= HEAD)" = app/x.txt ] || fail "the commit holds $(git show --name-only --format= HEAD | paste -sd ' ' -), not app/x.txt alone"
git checkout -q HEAD -- .gitignore; rm -f app/u.txt
# a partial commit: git's own temporary index, an absolute name, translated; what it leaves out stays out
echo two >> app/x.txt; echo d > app/d.txt; git add app/d.txt
ok "$WPATH" git commit -qm "$M" -- app/x.txt
grep -q "^env $CF GIT_INDEX_FILE=$T/p/\.git/next-index-[0-9]*\.lock sh $H/pre-commit\$" "$T/wsl.log" || fail 'a partial commit: the hook was not given its own index, translated'
[ "$(git show --name-only --format= HEAD)" = app/x.txt ] || fail 'a partial commit took the other staged file'
[ "$(git diff --cached --name-only)" = app/d.txt ] || fail 'a partial commit lost the other staged file'
ok "$WPATH" git commit -qm "$M"
# the hook judges the index it is given: a decision the partial commit does not carry is not in what its hook sees
printf '#!/bin/sh\n# Purpose: stub court seams\ngit diff --cached --name-only > .seen\necho ok\n' > checks/seams.sh; VID_ROLE=fix git add checks/seams.sh; printf '.seen\n' >> .gitignore; git add .gitignore; git commit -qm courts --no-verify
echo three >> app/x.txt; echo e > app/e.txt; git add app/e.txt
ok "$WPATH" git commit -qm "$M" -- app/x.txt
[ "$(cat .seen)" = app/x.txt ] || fail "the partial commit's hook saw $(paste -sd ' ' .seen), not app/x.txt alone"
git reset -q; rm -f app/e.txt
# a court's refusal, a message's refusal: the native hook's, words and exit code
: > .fail/imports; stage four; N0=$(git rev-parse HEAD)
try "$NPATH" git commit -qm "$M"; rn=$RC; cp "$T/o" "$T/n"
try "$WPATH" git commit -qm "$M"; cp "$T/o" "$T/w"
[ "$rn" != 0 ] || fail 'the native hook let a refused court through'
routed "env $CF GIT_INDEX_FILE=.git/index sh $H/pre-commit" 'a refused court'
[ "$RC" = "$rn" ] || fail "a refused court exits $RC through wsl.exe, natively $rn"
cmp -s "$T/n" "$T/w" || fail "a refused court's words differ from the native hook's: $(diff "$T/n" "$T/w" | head -n 4)"
[ "$(git rev-parse HEAD)" = "$N0" ] || fail 'a refused commit was made'
rm -f .fail/imports
try "$NPATH" git commit -qm 'no such line'; rn=$RC; cp "$T/o" "$T/n"
try "$WPATH" git commit -qm 'no such line'
[ "$rn" != 0 ] && [ "$RC" = "$rn" ] || fail "a message with no Decisions: line exits $RC through wsl.exe, natively $rn"
cmp -s "$T/n" "$T/o" || fail 'a refused message'"'"'s words differ from the native hook'"'"'s'
[ "$(git rev-parse HEAD)" = "$N0" ] || fail 'a commit whose message is refused was made'
# VID_ settings cross: a protected path is refused without VID_ROLE=fix and passes with it
echo '# one more line' >> checks/lawfiles; git reset -q; git add checks/lawfiles; git checkout -q HEAD -- app
try "$WPATH" git commit -qm "$M"; [ "$RC" != 0 ] || fail 'a protected path went through'
ok "$WPATH" env VID_ROLE=fix git commit -qm "$M"; grep -q '^env ' "$T/wsl.log" || fail 'the law commit was not routed'
# native: wsl: no, no answer, another shell, outside ticket mode, a linked worktree
echo 'wsl: no' > .vid/windows; stage five; ok "$WPATH" git commit -qm "$M"; quiet 'with wsl: no'
rm .vid/windows; stage six; ok "$WPATH" git commit -qm "$M"; quiet 'with no answer recorded'
echo 'wsl: yes' > .vid/windows
stage seven; ok "$T/bin:$NPATH" git commit -qm "$M"; quiet 'on a shell that is not Windows'"'"''
printf 'run: active\n' > .vid/RUN-STATE.md; stage eight; ok "$WPATH" git commit -qm "$M"; quiet 'outside ticket mode'
printf 'run: active\nmode: manual\n' > .vid/RUN-STATE.md; stage nine; ok "$WPATH" git commit -qm "$M"; quiet 'with another mode'
printf 'run: active\nmode: tickets\n' > .vid/RUN-STATE.md
git worktree add -q "$T/wt" -b wt 2>/dev/null; cd "$T/wt"; mkdir -p .ran .fail .vid; printf 'mode: tickets\n' > .vid/RUN-STATE.md
echo ten >> app/x.txt; ok "$WPATH" git commit -qam "$M"; quiet 'in a linked worktree'
printf '%s\n' "$M" > "$T/draft"; ok "$WPATH" sh checks/hooks/commit-msg "$T/draft"; quiet 'commit-msg by hand in a linked worktree'
cd "$T/p"
# a route that cannot start: natively, said, and nothing let through
for w in dead nogit; do
  : > "$T/$w"; stage "$w"; ok "$WPATH" git commit -qm "$M"
  if hooked; then fail "with WSL $w a hook was run through wsl.exe"; fi
  grep -q '^ViD: .*, so this check runs natively (slower)\.$' "$T/o" || fail "with WSL $w nothing said the checks ran natively"
  : > .fail/imports; stage again; try "$WPATH" git commit -qm "$M"; [ "$RC" != 0 ] || fail "with WSL $w a refused court was let through"
  rm -f .fail/imports "$T/$w"; git reset -q; git checkout -q HEAD -- app
done
echo 'windows-hook-routes: ok'
