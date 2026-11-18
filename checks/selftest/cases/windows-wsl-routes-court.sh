#!/bin/sh
# Purpose: selftest case — with `wsl: yes`, a court run directly goes through WSL (0.26.10.29.3, R6). On a faked
# native Windows shell (MINGW64_NT) with a fake `wsl.exe` (it logs its arguments, its `wslpath -a <file>` gives the
# file's absolute path, and it runs `sh …` natively), the PRD court started as `sh checks/prd.sh PRD.md
# --report` runs as `wsl.exe sh <court, translated> <PRD.md, translated> --report`, the flag untouched, and its
# standard output and exit code are those of a native run, on a passing and on a failing PRD. A builder worktree of
# the checkout follows the main checkout's answer. Each routed court sources checks/lib/wsl.sh at its top.
# Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "windows-wsl-routes-court: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'cd /; git -C "$T/p" worktree prune 2>/dev/null; rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
[ -f "$CHECKS/lib/wsl.sh" ] || fail 'checks/lib/wsl.sh is missing'
for c in prd inventory design-join imports seams stages; do
  grep -q '^_vidwsl=.*lib/wsl\.sh' "$CHECKS/$c.sh" || fail "$c.sh does not source checks/lib/wsl.sh"
done
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
abs() { printf '%s/%s\n' "$(cd "$(dirname "$1")" && pwd -P)" "$(basename "$1")"; }
same() { # fixture, label: the routed run matches the native one, and went through wsl.exe with its arguments translated
  cp "$CHECKS/selftest/fixtures/$1" PRD.md
  rn=0; PATH=$NPATH sh "$CHECKS/prd.sh" PRD.md --report > n.out 2>/dev/null || rn=$?
  : > "$T/wsl.log"
  rw=0; PATH=$FPATH sh "$CHECKS/prd.sh" PRD.md --report > w.out 2>/dev/null || rw=$?
  grep -qxF "sh $(abs "$CHECKS/prd.sh") $(abs PRD.md) --report" "$T/wsl.log" \
    || fail "$2: the court did not run as wsl.exe sh <court> <PRD.md>, both translated, --report as given; wsl.exe saw: $(cat "$T/wsl.log" | tr '\n' ';')"
  [ "$rn" = "$rw" ] || fail "$2: through WSL the court exited $rw, natively $rn"
  cmp -s n.out w.out || fail "$2: through WSL the court's standard output differs from the native run"
}
same prd-known-good.md 'a passing PRD'
same prd-known-bad.md 'a failing PRD'
# exit code without --report: the failing PRD exits 1 both ways
rn=0; PATH=$NPATH sh "$CHECKS/prd.sh" PRD.md > /dev/null 2>&1 || rn=$?
rw=0; PATH=$FPATH sh "$CHECKS/prd.sh" PRD.md > /dev/null 2>&1 || rw=$?
[ "$rn" = 1 ] && [ "$rw" = 1 ] || fail "the failing PRD exits $rw through WSL and $rn natively, not 1 and 1"
# a builder worktree reads the main checkout's answer
g worktree add -q "$T/wt" 2>/dev/null; cd "$T/wt"; [ ! -e .vid/windows ] || fail 'the worktree has its own .vid/windows'
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md; : > "$T/wsl.log"
PATH=$FPATH sh "$CHECKS/prd.sh" PRD.md > /dev/null 2>&1 || fail 'the passing PRD fails in the worktree'
grep -q "^sh $(abs "$CHECKS/prd.sh") " "$T/wsl.log" || fail "in a builder worktree the court did not go through wsl.exe — the main checkout's wsl: yes is not read"
echo 'windows-wsl-routes-court: ok'
