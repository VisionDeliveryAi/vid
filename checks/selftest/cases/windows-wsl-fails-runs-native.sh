#!/bin/sh
# Purpose: selftest case — with `wsl: no`, or with `wsl.exe` failing, a court runs natively (0.26.10.29.3, R6). On a
# faked native Windows shell (MINGW64_NT): with `wsl: no` recorded, the PRD court starts no `wsl.exe` and prints,
# writes to standard error and exits exactly as a native run; with `wsl: yes` and a `wsl.exe` that fails every call,
# the court's standard output and exit code are the native run's, and its standard error is the native run's plus
# exactly one line saying the check runs natively; the same when `wsl.exe` works and translates the paths but the court
# is not readable at its translated path (the project on a drive WSL does not mount): the court is never started there.
# A court never fails because WSL did. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "windows-wsl-fails-runs-native: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
[ -f "$CHECKS/lib/wsl.sh" ] || fail 'checks/lib/wsl.sh is missing'
NPATH=''; _o=$IFS; IFS=:; for d in $PATH; do [ -n "$d" ] && [ ! -e "$d/wsl.exe" ] && NPATH="${NPATH:+$NPATH:}$d"; done; IFS=$_o
mkdir -p "$T/ok" "$T/bad" "$T/p"
printf '#!/bin/sh\necho MINGW64_NT-10.0-19045\n' > "$T/ok/uname"; cp "$T/ok/uname" "$T/bad/uname"
# what is on the PATH inside each fake WSL: a wslpath that gives the file's own absolute path (ok), and one that
# gives a path on a drive WSL does not mount (far), where nothing is readable
mkdir -p "$T/far" "$T/okbin" "$T/farbin"; cp "$T/ok/uname" "$T/far/uname"
printf '#!/bin/sh\n[ "$1" = -a ] || exit 1; d=$(cd "$(dirname "$2")" && pwd -P) || exit 1; printf "%%s/%%s\\n" "$d" "$(basename "$2")"\n' > "$T/okbin/wslpath"
printf '#!/bin/sh\n[ "$1" = -a ] || exit 1; printf "/mnt/z/not-mounted/%%s\\n" "$(basename "$2")"\n' > "$T/farbin/wslpath"
for k in ok far; do cat > "$T/$k/wsl.exe" <<EOF
#!/bin/sh
PATH="$T/${k}bin:$NPATH"
case "\$1" in -e|--exec) shift ;; esac
printf '%s\n' "\$*" >> "$T/wsl.log"
case "\$1" in wslpath|sh) exec "\$@" ;; *) exit 1 ;; esac
EOF
done
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/wsl.log"\necho "There is no distribution installed." >&2\nexit 1\n' "$T" > "$T/bad/wsl.exe"
chmod +x "$T"/ok/* "$T"/bad/* "$T"/far/* "$T"/okbin/* "$T"/farbin/*
cd "$T/p"; git init -q; g commit -q --allow-empty -m base; mkdir -p .vid
for fx in prd-known-good.md prd-known-bad.md; do
  cp "$CHECKS/selftest/fixtures/$fx" PRD.md
  rn=0; PATH=$NPATH sh "$CHECKS/prd.sh" PRD.md > n.out 2> n.err || rn=$?
  # wsl: no — never routed
  echo 'wsl: no' > .vid/windows; : > "$T/wsl.log"
  r=0; PATH="$T/ok:$NPATH" sh "$CHECKS/prd.sh" PRD.md > o.out 2> o.err || r=$?
  [ ! -s "$T/wsl.log" ] || fail "$fx: with wsl: no the court started wsl.exe"
  [ "$r" = "$rn" ] && cmp -s n.out o.out && cmp -s n.err o.err || fail "$fx: with wsl: no the court did not run as natively"
  # wsl: yes, wsl.exe failing — native, one line on standard error
  echo 'wsl: yes' > .vid/windows; : > "$T/wsl.log"
  r=0; PATH="$T/bad:$NPATH" sh "$CHECKS/prd.sh" PRD.md > f.out 2> f.err || r=$?
  [ -s "$T/wsl.log" ] || fail "$fx: with wsl: yes the court never tried wsl.exe"
  [ "$r" = "$rn" ] || fail "$fx: with wsl.exe failing the court exited $r, natively $rn"
  cmp -s n.out f.out || fail "$fx: with wsl.exe failing the court's standard output differs from the native run"
  [ "$(grep -c . f.err)" = "$(($(grep -c . n.err || true) + 1))" ] || fail "$fx: with wsl.exe failing, standard error does not carry exactly one line more than natively: $(cat f.err)"
  if [ -s n.err ]; then grep -v -x -F -f n.err f.err > extra.err || true; else cp f.err extra.err; fi
  [ "$(grep -c . extra.err)" = 1 ] && grep -q 'WSL' extra.err && grep -q 'natively' extra.err \
    || fail "$fx: the one added line does not say WSL failed and the check runs natively: $(cat extra.err)"
  ! grep -q 'no distribution' f.err || fail "$fx: wsl.exe's own error text reached standard error"
  # wsl: yes, the translation works but the court is not readable inside WSL (a drive WSL does not mount) — native, one line
  : > "$T/wsl.log"
  r=0; PATH="$T/far:$NPATH" sh "$CHECKS/prd.sh" PRD.md > z.out 2> z.err || r=$?
  [ -s "$T/wsl.log" ] || fail "$fx: with the court unreadable inside WSL, the court never tried wsl.exe"
  ! grep -q '^sh /mnt/z/' "$T/wsl.log" || fail "$fx: the court was started inside WSL at a path that is not readable there: $(grep '^sh /mnt/z/' "$T/wsl.log")"
  [ "$r" = "$rn" ] || fail "$fx: with the court unreadable inside WSL the court exited $r, natively $rn — it failed because WSL did"
  cmp -s n.out z.out || fail "$fx: with the court unreadable inside WSL the court's standard output differs from the native run"
  if [ -s n.err ]; then grep -v -x -F -f n.err z.err > extra.err || true; else cp z.err extra.err; fi
  [ "$(grep -c . z.err)" = "$(($(grep -c . n.err || true) + 1))" ] && [ "$(grep -c . extra.err)" = 1 ] && grep -q 'WSL' extra.err && grep -q 'natively' extra.err \
    || fail "$fx: with the court unreadable inside WSL, standard error is not the native run's plus the one line: $(cat z.err)"
done
echo 'windows-wsl-fails-runs-native: ok'
