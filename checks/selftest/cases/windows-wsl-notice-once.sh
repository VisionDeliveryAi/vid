#!/bin/sh
# Purpose: selftest case — FB-1 D2: the WSL notice prints once. On a faked native Windows shell (MINGW64_NT) with a fake
# `wsl.exe` whose probe (`sh -c true`) takes two seconds and is logged: two `notice` calls started together probe once and print
# one line between them (the one that claims `.vid/windows.claim` first; the other exits silently); a claim 3 minutes old with no
# answer is a call stopped during its probe, so `notice` probes and prints; two notices started together beside one such claim
# (a fake `rm` that waits a second widens the window) take it over once: one probe, one line; and with the answer written after `notice`'s first
# read and before its claim (a fake `mkdir`, the step between the two, writes it as another session would), `notice` neither
# probes nor prints, and leaves no claim behind. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "windows-wsl-notice-once: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
LIB="$CHECKS/lib/wsl.sh"; [ -f "$LIB" ] || fail 'checks/lib/wsl.sh is missing'
NPATH=''; _o=$IFS; IFS=:; for d in $PATH; do [ -n "$d" ] && [ ! -e "$d/wsl.exe" ] && NPATH="${NPATH:+$NPATH:}$d"; done; IFS=$_o
mkdir -p "$T/bin" "$T/mk" "$T/p"
printf '#!/bin/sh\necho MINGW64_NT-10.0-19045\n' > "$T/bin/uname"
cat > "$T/bin/wsl.exe" <<EOF2
#!/bin/sh
case "\$1" in -e|--exec) shift ;; esac
printf '%s\n' "\$*" >> "$T/wsl.log"
[ "\$*" != 'sh -c true' ] || sleep 2
case "\$1" in sh) exec "\$@" ;; *) exit 1 ;; esac
EOF2
chmod +x "$T/bin/uname" "$T/bin/wsl.exe"
FPATH="$T/bin:$NPATH"
cd "$T/p"; git init -q; g commit -q --allow-empty -m base
F="$(git rev-parse --show-toplevel)/.vid/windows"
probes() { grep -cx 'sh -c true' "$T/wsl.log" 2>/dev/null || true; }
# two calls started together
: > "$T/wsl.log"
PATH=$FPATH sh "$LIB" notice > "$T/o1" 2>&1 & P1=$!
PATH=$FPATH sh "$LIB" notice > "$T/o2" 2>&1 & P2=$!
wait "$P1" || fail 'the first notice exited non-zero'; wait "$P2" || fail 'the second notice exited non-zero'
[ "$(probes)" = 1 ] || fail "two notices started together ran the probe $(probes) times"
[ "$(cat "$T/o1" "$T/o2" | grep -c .)" = 1 ] || fail "two notices started together printed: $(cat "$T/o1" "$T/o2" | tr '\n' ';')"
grep -qx 'wsl: yes' "$F" || fail 'the answer was not recorded'
[ ! -e "$F.claim" ] || fail 'the claim was left behind'
# a claim 3 minutes old and no answer: probed and printed
rm -f "$F"; : > "$F.claim"; touch -t "$(date -v-3M +%Y%m%d%H%M.%S 2>/dev/null || date -d '3 minutes ago' +%Y%m%d%H%M.%S)" "$F.claim"; : > "$T/wsl.log"
N=$(PATH=$FPATH sh "$LIB" notice 2>&1) || fail 'notice exited non-zero beside an old claim'
[ "$(probes)" = 1 ] && [ -n "$N" ] && grep -qx 'wsl: yes' "$F" || fail "beside a claim 3 minutes old notice did not probe and print ($(probes) probes, '$N')"
[ ! -e "$F.claim" ] || fail 'the claim was left behind after an old one was taken over'
# two notices beside one old claim: one takes it over (a rename only one wins), one probe, one line
mkdir -p "$T/rm"; printf '#!/bin/sh\nsleep 1\nexec /bin/rm "$@"\n' > "$T/rm/rm"; chmod +x "$T/rm/rm"
rm -f "$F"; : > "$F.claim"; touch -t "$(date -v-3M +%Y%m%d%H%M.%S 2>/dev/null || date -d '3 minutes ago' +%Y%m%d%H%M.%S)" "$F.claim"; : > "$T/wsl.log"
PATH="$T/rm:$FPATH" sh "$LIB" notice > "$T/o1" 2>&1 & P1=$!
PATH="$T/rm:$FPATH" sh "$LIB" notice > "$T/o2" 2>&1 & P2=$!
wait "$P1" || fail 'beside an old claim the first notice exited non-zero'; wait "$P2" || fail 'beside an old claim the second notice exited non-zero'
[ "$(probes)" = 1 ] || fail "two notices beside an old claim ran the probe $(probes) times"
[ "$(cat "$T/o1" "$T/o2" | grep -c .)" = 1 ] || fail "two notices beside an old claim printed: $(cat "$T/o1" "$T/o2" | tr '\n' ';')"
[ -z "$(ls -a "${F%/*}" | grep '\.claim')" ] || fail "a claim was left behind: $(ls -a "${F%/*}" | tr '\n' ' ')"
# the answer written between the first read and the claim: no probe, nothing printed
rm -f "$F"; : > "$T/wsl.log"
cat > "$T/mk/mkdir" <<EOF2
#!/bin/sh
PATH="$NPATH" mkdir "\$@" || exit 1
printf 'wsl: no\n' > "$F"
EOF2
chmod +x "$T/mk/mkdir"
N=$(PATH="$T/mk:$FPATH" sh "$LIB" notice 2>&1) || fail 'notice exited non-zero'
[ "$(probes)" = 0 ] || fail 'with the answer written before its claim notice probed'
[ -z "$N" ] || fail "with the answer written before its claim notice printed: $N"
grep -qx 'wsl: no' "$F" || fail 'the answer the other session wrote was changed'
[ ! -e "$F.claim" ] || fail 'the claim was left behind'
echo 'windows-wsl-notice-once: ok'
