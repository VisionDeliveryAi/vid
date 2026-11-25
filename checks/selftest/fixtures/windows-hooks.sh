# Purpose: selftest fixture — a commit's hooks on a faked native Windows shell (FB-7 D1). Sourced by the windows-hook-* cases once
# `fail` is defined and $T made (Env: CHECKS, T, resolved); enters $T/p: the stub courts with the real hooks and checks/lib/wsl.sh,
# core.hooksPath set, core.autocrlf input, ticket mode, `wsl: yes`. $WPATH: a uname that says MINGW64_NT, a fake `wsl.exe` and this
# PATH, $NPATH. The fake logs its arguments in $T/wsl.log, drops git's own variables as WSL does, and runs what it is given here, in a
# home of its own, $T/wslhome; while $T/dead is there it fails, while $T/nogit no git answers in it, while $T/old its git is one before
# 2.31, which reads no GIT_CONFIG_COUNT. Helpers: try <PATH> <command…> (its output $T/o, its exit RC), ok (it passes), quiet <scene>
# (wsl.exe not started), hooked (a hook was run through wsl.exe); $M a passing message. HOME is $T/home.
unset GIT_INDEX_FILE GIT_DIR GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM XDG_CONFIG_HOME
HOME=$T/home; export HOME; mkdir -p "$HOME" "$T/wslhome" "$T/bin" "$T/win" "$T/wslbin" "$T/nogitbin" "$T/oldbin" "$T/p"
NPATH=''; _o=$IFS; IFS=:; for d in $PATH; do [ -n "$d" ] && [ ! -e "$d/wsl.exe" ] && NPATH="${NPATH:+$NPATH:}$d"; done; IFS=$_o
printf '#!/bin/sh\necho MINGW64_NT-10.0-19045\n' > "$T/win/uname"
printf '#!/bin/sh\n[ "$1" = -a ] || exit 1; d=$(cd "$(dirname "$2")" && pwd -P) || exit 1; printf "%%s/%%s\\n" "$d" "$(basename "$2")"\n' > "$T/wslbin/wslpath"
printf '#!/bin/sh\nexit 127\n' > "$T/nogitbin/git"
printf '#!/bin/sh\nunset GIT_CONFIG_COUNT\nPATH="%s"; export PATH; exec git "$@"\n' "$NPATH" > "$T/oldbin/git"
cat > "$T/bin/wsl.exe" <<EOF
#!/bin/sh
PATH="$T/wslbin:$NPATH"; HOME="$T/wslhome"; export HOME
[ ! -e "$T/nogit" ] || PATH="$T/nogitbin:\$PATH"
[ ! -e "$T/old" ] || PATH="$T/oldbin:\$PATH"
for v in \$(env | sed -n 's/^\(GIT_[A-Z_0-9]*\)=.*/\1/p'); do unset "\$v"; done
case "\$1" in -e|--exec) shift ;; esac
printf '%s\n' "\$*" >> "$T/wsl.log"
[ ! -e "$T/dead" ] || exit 1
exec "\$@"
EOF
chmod +x "$T/bin/wsl.exe" "$T/win/uname" "$T/wslbin/wslpath" "$T/nogitbin/git" "$T/oldbin/git"
WPATH="$T/win:$T/bin:$NPATH"   # the faked Windows shell; T/bin alone: wsl.exe on another shell's PATH
cd "$T/p"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
cp "$CHECKS/hooks/commit-msg" "$CHECKS/hooks/post-commit" checks/hooks/; chmod +x checks/hooks/*
mkdir -p checks/lib; cp "$CHECKS/lib/wsl.sh" checks/lib/
g add -A; g commit -qm courts
git config user.email vid@selftest; git config user.name vid; git config core.hooksPath checks/hooks; git config core.autocrlf input
mkdir -p .vid; printf 'run: active\nmode: tickets\n' > .vid/RUN-STATE.md; echo 'wsl: yes' > .vid/windows
try() { P=$1; shift; : > "$T/wsl.log"; RC=0; PATH=$P "$@" > "$T/o" 2>&1 || RC=$?; }
ok() { try "$@"; [ "$RC" = 0 ] || fail "the commit failed ($RC): $*"; }
quiet() { [ ! -s "$T/wsl.log" ] || fail "$1: wsl.exe was started"; }
hooked() { grep -q 'sh [^ ]*/checks/hooks/[a-z]' "$T/wsl.log"; }
M='x

Decisions: none — nothing surprising'
