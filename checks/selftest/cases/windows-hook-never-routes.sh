#!/bin/sh
# Purpose: selftest case — outside ticket mode, under a git hook, a court never goes through WSL (0.26.10.29.3, R6;
# FB-7 D1: in ticket mode the whole hook does, and its courts with it: windows-hook-routes). With `wsl: yes`
# recorded, a faked native Windows shell (MINGW64_NT) and a fake `wsl.exe` that logs every call, the PRD court run
# with GIT_INDEX_FILE set (as git sets it for pre-commit, commit-msg and post-commit), or with GIT_DIR set, starts
# no `wsl.exe` at all, and prints and exits as a native run does. A real commit through a pre-commit hook that runs
# the court starts none either. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "windows-hook-never-routes: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
[ -f "$CHECKS/lib/wsl.sh" ] || fail 'checks/lib/wsl.sh is missing'
NPATH=''; _o=$IFS; IFS=:; for d in $PATH; do [ -n "$d" ] && [ ! -e "$d/wsl.exe" ] && NPATH="${NPATH:+$NPATH:}$d"; done; IFS=$_o
mkdir -p "$T/bin" "$T/p"
printf '#!/bin/sh\necho MINGW64_NT-10.0-19045\n' > "$T/bin/uname"
mkdir -p "$T/wslbin"   # what is on the PATH inside the fake WSL: its wslpath
printf '#!/bin/sh\n[ "$1" = -a ] || exit 1; d=$(cd "$(dirname "$2")" && pwd -P) || exit 1; printf "%%s/%%s\\n" "$d" "$(basename "$2")"\n' > "$T/wslbin/wslpath"
cat > "$T/bin/wsl.exe" <<EOF
#!/bin/sh
PATH="$T/wslbin:$NPATH"
case "\$1" in -e|--exec) shift ;; esac
printf '%s\n' "\$*" >> "$T/wsl.log"
case "\$1" in wslpath|sh) exec "\$@" ;; *) exit 1 ;; esac
EOF
chmod +x "$T/bin/uname" "$T/bin/wsl.exe" "$T/wslbin/wslpath"
FPATH="$T/bin:$NPATH"
cd "$T/p"; git init -q; g commit -q --allow-empty -m base
mkdir -p .vid; echo 'wsl: yes' > .vid/windows
cp "$CHECKS/selftest/fixtures/prd-known-bad.md" PRD.md
rn=0; PATH=$NPATH sh "$CHECKS/prd.sh" PRD.md > n.out 2> n.err || rn=$?
for v in "GIT_INDEX_FILE=.git/index" "GIT_DIR=$T/p/.git"; do
  : > "$T/wsl.log"
  rh=0; env "$v" PATH="$FPATH" sh "$CHECKS/prd.sh" PRD.md > h.out 2> h.err || rh=$?
  [ ! -s "$T/wsl.log" ] || fail "with $v the court started wsl.exe: $(tr '\n' ';' < "$T/wsl.log")"
  [ "$rn" = "$rh" ] || fail "with $v the court exited $rh, natively $rn"
  cmp -s n.out h.out && cmp -s n.err h.err || fail "with $v the court's output differs from the native run"
done
# a real commit: the pre-commit hook runs the court, and wsl.exe is never started
mkdir -p hooks
printf '#!/bin/sh\nsh "%s/prd.sh" PRD.md > /dev/null 2>&1 || true\n' "$CHECKS" > hooks/pre-commit; chmod +x hooks/pre-commit
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md; g add PRD.md
: > "$T/wsl.log"
PATH=$FPATH g -c core.hooksPath=hooks commit -q -m prd || fail 'the commit through the hook failed'
[ ! -s "$T/wsl.log" ] || fail "the court under the pre-commit hook started wsl.exe: $(tr '\n' ';' < "$T/wsl.log")"
echo 'windows-hook-never-routes: ok'
