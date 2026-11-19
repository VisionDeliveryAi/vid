#!/bin/sh
# Purpose: selftest case — without a working WSL, nothing is asked, `wsl: no` is recorded once and ViD carries on
# natively (0.26.10.29.3, R6; 0.26.11.1.3, R2). On a faked native Windows shell (MINGW64_NT) with a `wsl.exe` that cannot
# run `sh -c true`, `sh checks/lib/wsl.sh notice` records `wsl: no` with a `# WSL did not start <UTC>` line and prints
# the one no line, naming the file; the PRD court run after it never calls `wsl.exe`. With no `wsl.exe` on the PATH at
# all, the same answer and line. On a shell that is not native Windows (a faked Linux), `notice` prints nothing,
# records nothing and never starts `wsl.exe`. With no WSL, even a recorded `wsl: yes` leaves the PRD court native: the
# same output and exit code as a plain run. Env: CHECKS.
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
F="$(git rev-parse --show-toplevel)/.vid/windows"
WANT="WSL did not start on this PC, so ViD runs its checks natively, more slowly. Once WSL works, delete \`$F\` and ViD will check again."
no_answer() { # $1 the label: the file says wsl: no, with the dated line, and nothing else
  [ -f "$F" ] || fail "$1: notice recorded nothing"
  grep -qx 'wsl: no' "$F" || fail "$1: notice did not record 'wsl: no': $(cat "$F")"
  grep -qE '^# WSL did not start [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' "$F" || fail "$1: no '# WSL did not start <UTC>' line: $(cat "$F")"
  [ "$(grep -c . "$F")" = 2 ] || fail "$1: the file holds more than the answer and its line: $(cat "$F")"
}
# a wsl.exe that fails: wsl: no, the no line, and a court then never calls wsl.exe
: > "$T/wsl.log"
N=$(PATH="$T/bad:$NPATH" sh "$LIB" notice 2> "$T/err") || fail "notice exited non-zero (the script is missing or broken): $(cat "$T/err")"
no_answer 'with a wsl.exe that fails'
[ "$N" = "$WANT" ] || fail "with a wsl.exe that fails, notice printed '$N', not the one no line"
cp "$CHECKS/selftest/fixtures/prd-known-bad.md" PRD.md; : > "$T/wsl.log"
rc=0; PATH=$NPATH sh "$CHECKS/prd.sh" PRD.md > native.out 2> native.err || rc=$?
rw=0; PATH="$T/bad:$NPATH" sh "$CHECKS/prd.sh" PRD.md > win.out 2> win.err || rw=$?
[ ! -s "$T/wsl.log" ] || fail "after wsl: no was recorded, the court called wsl.exe: $(tr '\n' ';' < "$T/wsl.log")"
[ "$rc" = "$rw" ] && cmp -s native.out win.out && cmp -s native.err win.err || fail 'after wsl: no was recorded, the court did not run as natively'
# no wsl.exe at all: the same
rm -f "$F"
N=$(PATH="$T/win:$NPATH" sh "$LIB" notice) || fail 'notice exited non-zero with no wsl.exe'
no_answer 'with no wsl.exe'
[ "$N" = "$WANT" ] || fail "with no wsl.exe, notice printed '$N', not the one no line"
# not native Windows: nothing printed, recorded or started
rm -f "$F"; : > "$T/wsl.log"
N=$(PATH="$T/lin:$NPATH" sh "$LIB" notice); [ -z "$N" ] || fail "on a shell that is not native Windows, notice printed '$N'"
[ ! -e "$F" ] || fail 'on a shell that is not native Windows, notice recorded an answer'
[ ! -s "$T/wsl.log" ] || fail 'on a shell that is not native Windows, notice started wsl.exe'
N=$(PATH="$NPATH" sh "$LIB" notice); [ -z "$N" ] && [ ! -e "$F" ] || fail "on this machine's own shell, notice printed '$N' or recorded an answer"
# a recorded yes with no wsl.exe: the court runs natively
mkdir -p .vid; echo 'wsl: yes' > .vid/windows
rw=0; PATH="$T/win:$NPATH" sh "$CHECKS/prd.sh" PRD.md > win.out 2> win.err || rw=$?
[ "$rc" = "$rw" ] || fail "with no wsl.exe the court exited $rw, natively $rc"
cmp -s native.out win.out || fail 'with no wsl.exe the court printed something other than the native run'
cmp -s native.err win.err || fail 'with no wsl.exe the court wrote something other than the native run to standard error'
echo 'windows-no-wsl-no-question: ok'
