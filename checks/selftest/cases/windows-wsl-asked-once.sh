#!/bin/sh
# Purpose: selftest case — on a native Windows shell with WSL, ViD checks and says it once per machine, and asks
# nothing (0.26.10.29.3, R6; 0.26.11.1.3, R2: the question is cut, the case keeps its name). With a faked `uname -s`
# (MINGW64_NT) and a working fake `wsl.exe` on the PATH, the first `sh checks/lib/wsl.sh notice` probes WSL once,
# writes `wsl: yes` to .vid/windows at the main checkout and prints one line; a second `notice` prints nothing and
# starts no `wsl.exe`; in a builder worktree of that checkout `notice` prints nothing and writes nothing there, since
# the answer is read from the main checkout (the parent of `git rev-parse --git-common-dir`); an answer the owner
# edited to `wsl: no` stands. The question's words, `ask` and `record`, are gone. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "windows-wsl-asked-once: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'cd /; git -C "$T/p" worktree prune 2>/dev/null; rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
LIB="$CHECKS/lib/wsl.sh"
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
: > "$T/wsl.log"
N=$(PATH=$FPATH sh "$LIB" notice) || fail 'notice exited non-zero (the script is missing or broken)'
[ "$(printf '%s\n' "$N" | grep -c .)" = 1 ] || fail "the first notice did not print one line: '$N'"
[ -f .vid/windows ] && [ "$(cat .vid/windows)" = 'wsl: yes' ] || fail ".vid/windows does not hold 'wsl: yes' after the first notice"
[ "$(grep -cx 'sh -c true' "$T/wsl.log")" = 1 ] || fail "the first notice did not probe WSL once: $(tr '\n' ';' < "$T/wsl.log")"
: > "$T/wsl.log"
N=$(PATH=$FPATH sh "$LIB" notice); [ -z "$N" ] || fail "a second notice, after the answer was recorded, printed '$N'"
[ ! -s "$T/wsl.log" ] || fail 'a second notice started wsl.exe again'
g worktree add -q "$T/wt" 2>/dev/null; cd "$T/wt"
N=$(PATH=$FPATH sh "$LIB" notice); [ -z "$N" ] || fail "in a builder worktree, notice printed '$N' — it does not read the main checkout's answer"
[ ! -e "$T/wt/.vid/windows" ] || fail 'notice wrote .vid/windows in the builder worktree'
cd "$T/p"; echo 'wsl: no' > .vid/windows
N=$(PATH=$FPATH sh "$LIB" notice); [ -z "$N" ] && [ "$(cat .vid/windows)" = 'wsl: no' ] || fail "the owner's 'wsl: no' did not stand: notice printed '$N', the file holds '$(cat .vid/windows)'"
for w in ask 'record yes'; do
  # shellcheck disable=SC2086
  if PATH=$FPATH sh "$LIB" $w > "$T/out" 2>&1; then fail "'$w' still runs — the question is cut"; fi
done
! grep -q 'May ViD run them there' "$LIB" || fail 'the question is still in checks/lib/wsl.sh'
echo 'windows-wsl-asked-once: ok'
