#!/bin/sh
# Purpose: selftest case — on a native Windows shell with WSL, the question is asked once (0.26.10.29.3, R6). With a
# faked `uname -s` (MINGW64_NT) and a working fake `wsl.exe` on the PATH, `sh checks/lib/wsl.sh ask` prints the one
# question and nothing else; `record yes` writes `wsl: yes` to .vid/windows at the main checkout; a second `ask` prints
# nothing; in a builder worktree of that checkout `ask` prints nothing too and writes nothing there, since the answer
# is read from the main checkout (the parent of `git rev-parse --git-common-dir`). Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "windows-wsl-asked-once: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'cd /; git -C "$T/p" worktree prune 2>/dev/null; rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
LIB="$CHECKS/lib/wsl.sh"
WANT="ViD's checks run much faster through WSL on this PC. May ViD run them there?"
# the PATH without any real wsl.exe, then the fakes in front of it
NPATH=''; _o=$IFS; IFS=:; for d in $PATH; do [ -n "$d" ] && [ ! -e "$d/wsl.exe" ] && NPATH="${NPATH:+$NPATH:}$d"; done; IFS=$_o
mkdir -p "$T/bin" "$T/p"
printf '#!/bin/sh\necho MINGW64_NT-10.0-19045\n' > "$T/bin/uname"
cat > "$T/bin/wsl.exe" <<EOF
#!/bin/sh
case "\$1" in -e|--exec) shift ;; esac
printf '%s\n' "\$*" >> "$T/wsl.log"
case "\$1" in sh) shift; PATH="$NPATH" exec sh "\$@" ;; *) exit 1 ;; esac
EOF
chmod +x "$T/bin/uname" "$T/bin/wsl.exe"
FPATH="$T/bin:$NPATH"
cd "$T/p"; git init -q; g commit -q --allow-empty -m base
Q=$(PATH=$FPATH sh "$LIB" ask) || fail "ask exited non-zero (the script is missing or broken)"
[ "$Q" = "$WANT" ] || fail "with WSL present, ask printed '$Q', not the one question"
PATH=$FPATH sh "$LIB" record yes > /dev/null || fail 'record yes exited non-zero'
[ -f .vid/windows ] && [ "$(cat .vid/windows)" = 'wsl: yes' ] || fail ".vid/windows does not hold 'wsl: yes' after record yes"
Q=$(PATH=$FPATH sh "$LIB" ask); [ -z "$Q" ] || fail "a second ask, after the answer was recorded, printed '$Q'"
g worktree add -q "$T/wt" 2>/dev/null; cd "$T/wt"
Q=$(PATH=$FPATH sh "$LIB" ask); [ -z "$Q" ] || fail "in a builder worktree, ask printed '$Q' — it does not read the main checkout's answer"
[ ! -e "$T/wt/.vid/windows" ] || fail 'ask wrote .vid/windows in the builder worktree'
if PATH=$FPATH sh "$LIB" record maybe > /dev/null 2>&1; then fail "record took 'maybe' — the answers are yes and no"; fi
echo 'windows-wsl-asked-once: ok'
