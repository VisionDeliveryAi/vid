#!/bin/sh
# Purpose: selftest case — without WSL, nothing is asked and ViD carries on natively (0.26.10.29.3, R6). On a faked
# native Windows shell (MINGW64_NT) with no `wsl.exe` on the PATH, `sh checks/lib/wsl.sh ask` prints nothing and
# records nothing; with a `wsl.exe` that cannot run `sh -c true`, the same; on a shell that is not native Windows
# (a faked Linux), `ask` prints nothing and never starts `wsl.exe`. With no WSL, even a recorded `wsl: yes` leaves
# the PRD court native: the same output and exit code as a plain run. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "windows-no-wsl-no-question: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
LIB="$CHECKS/lib/wsl.sh"
NPATH=''; _o=$IFS; IFS=:; for d in $PATH; do [ -n "$d" ] && [ ! -e "$d/wsl.exe" ] && NPATH="${NPATH:+$NPATH:}$d"; done; IFS=$_o
mkdir -p "$T/win" "$T/bad" "$T/lin" "$T/p"
printf '#!/bin/sh\necho MINGW64_NT-10.0-19045\n' > "$T/win/uname"
cp "$T/win/uname" "$T/bad/uname"; printf '#!/bin/sh\necho Linux\n' > "$T/lin/uname"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/wsl.log"\necho "WSL is not installed" >&2\nexit 1\n' "$T" > "$T/bad/wsl.exe"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/wsl.log"\nexit 0\n' "$T" > "$T/lin/wsl.exe"
chmod +x "$T"/win/* "$T"/bad/* "$T"/lin/*
cd "$T/p"; git init -q; g commit -q --allow-empty -m base
Q=$(PATH="$T/win:$NPATH" sh "$LIB" ask) || fail 'ask exited non-zero (the script is missing or broken)'
[ -z "$Q" ] || fail "with no wsl.exe on the PATH, ask printed '$Q'"
[ ! -e .vid/windows ] || fail 'with no wsl.exe, ask recorded an answer'
Q=$(PATH="$T/bad:$NPATH" sh "$LIB" ask); [ -z "$Q" ] || fail "with a wsl.exe that fails, ask printed '$Q'"
[ ! -e .vid/windows ] || fail 'with a failing wsl.exe, ask recorded an answer'
: > "$T/wsl.log"
Q=$(PATH="$T/lin:$NPATH" sh "$LIB" ask); [ -z "$Q" ] || fail "on a shell that is not native Windows, ask printed '$Q'"
[ ! -s "$T/wsl.log" ] || fail 'on a shell that is not native Windows, ask started wsl.exe'
# a recorded yes with no wsl.exe: the court runs natively
cp "$CHECKS/selftest/fixtures/prd-known-bad.md" PRD.md
mkdir -p .vid; echo 'wsl: yes' > .vid/windows
rc=0; PATH=$NPATH sh "$CHECKS/prd.sh" PRD.md > native.out 2> native.err || rc=$?
rw=0; PATH="$T/win:$NPATH" sh "$CHECKS/prd.sh" PRD.md > win.out 2> win.err || rw=$?
[ "$rc" = "$rw" ] || fail "with no wsl.exe the court exited $rw, natively $rc"
cmp -s native.out win.out || fail 'with no wsl.exe the court printed something other than the native run'
cmp -s native.err win.err || fail 'with no wsl.exe the court wrote something other than the native run to standard error'
echo 'windows-no-wsl-no-question: ok'
