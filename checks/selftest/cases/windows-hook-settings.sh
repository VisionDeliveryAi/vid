#!/bin/sh
# Purpose: selftest case — a routed hook judges with this side's git settings, or runs natively (FB-7 D1; fixtures/windows-hooks.sh). What
# this side ignores (core.excludesFile, or its default git/ignore) the routed hook ignores, and WSL's own ignore file is not read: the
# same commits pass and are refused, in the same words. With any of GIT_CONFIG_COUNT, GIT_CONFIG_PARAMETERS (`git -c`),
# GIT_CONFIG_GLOBAL and GIT_CONFIG_SYSTEM set the hooks run natively, wsl.exe never started: a ledger test renamed with diff.renames
# off is refused for its Tests-by as natively. With a git in WSL that does not take the settings (one before 2.31), or none that
# answers, the commit's checks run natively, and one line says which. Every scene that fails is named. Env: CHECKS.
set -eu
fail() { echo "windows-hook-settings: $*" >&2; exit 1; }
T=$(mktemp -d); T=$(cd "$T" && pwd -P); trap 'cd /; rm -rf "${T:?}"' EXIT
. "$CHECKS/selftest/fixtures/windows-hooks.sh"
B=''; bad() { echo "windows-hook-settings: $*" >&2; B=1; }
same() { # <scene> <native's answer, pass or refused>: one commit native, one routed: the same exit and words, the hook run through wsl.exe
  stage "$1"; try "$NPATH" git commit -qm "$M"; rn=$RC; cp "$T/o" "$T/n"; case $2$rn in pass0|refused[1-9]*) ;; *) fail "the scene is wrong: $1: the native hook exits $rn" ;; esac
  stage "$1 again"; try "$WPATH" git commit -qm "$M"
  if [ "$RC" != "$rn" ]; then bad "$1: the commit exits $RC through wsl.exe, natively $rn"; elif ! cmp -s "$T/n" "$T/o"; then bad "$1: the words differ from the native hook's: $(diff "$T/n" "$T/o" | paste -sd ' ' -)"; fi
  hooked || bad "$1: the hook did not run through wsl.exe"; git reset -q; git checkout -q HEAD -- app; }
stage warm; ok "$NPATH" git commit -qm "$M"   # the first commit alone runs the PRD court: the next ones hold its memo
mkdir design; echo x > design/Thumbs.db; echo Thumbs.db > "$T/ig"
git config --global core.excludesFile "$T/ig"; same "this side's ignore file" pass
git config --global --unset core.excludesFile; mkdir -p "$HOME/.config/git"; mv "$T/ig" "$HOME/.config/git/ignore"; same "this side's default ignore file" pass
: > "$HOME/.config/git/ignore"; rm design/Thumbs.db
mkdir -p "$T/wslhome/.config/git"; echo '*.orig' > "$T/wslhome/.config/git/ignore"; echo x > checks/x.sh.orig; same "WSL's own ignore file" refused
: > "$T/wslhome/.config/git/ignore"; rm checks/x.sh.orig
# a setting given to one commit
mkdir -p tests/invariants; printf 'a ledger test\nof three\nlines\n' > tests/invariants/a.txt; git add tests; git commit -qm ledger --no-verify
git mv tests/invariants/a.txt tests/invariants/b.txt; H0=$(git rev-parse HEAD)
try "$WPATH" env VID_ROLE=fix GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=diff.renames GIT_CONFIG_VALUE_0=false git commit -qm "$M"
if [ "$RC" = 0 ]; then bad 'GIT_CONFIG_COUNT: a commit the native hook refuses, a renamed ledger test with diff.renames off, was let through'
else grep -q 'Tests-by' "$T/o" || bad 'GIT_CONFIG_COUNT: the renamed ledger test is not refused for its Tests-by'; fi
git reset -q --hard "$H0"; [ ! -s "$T/wsl.log" ] || bad 'with GIT_CONFIG_COUNT set wsl.exe was started'
for v in GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "GIT_CONFIG_PARAMETERS='diff.renames=false'"; do stage "$v"; ok "$WPATH" env "$v" git commit -qm "$M"; [ ! -s "$T/wsl.log" ] || bad "with ${v%%=*} set wsl.exe was started"; done
stage gc; ok "$WPATH" git -c diff.renames=false commit -qm "$M"; [ ! -s "$T/wsl.log" ] || bad 'with git -c wsl.exe was started'
# a git there that does not take the settings, and none
for w in old nogit; do : > "$T/$w"; case $w in old) W="WSL's git does not take this side's settings" ;; nogit) W='git does not answer in WSL' ;; esac
  stage "$w"; ok "$WPATH" git commit -qm "$M"; ! hooked || bad "$w: a hook was run through wsl.exe"
  grep -qxF "ViD: $W, so this check runs natively (slower)." "$T/o" || bad "$w: no line 'ViD: $W, so this check runs natively (slower).'"; rm "${T:?}/${w:?}"; done
[ -z "$B" ] || exit 1
echo 'windows-hook-settings: ok'
