#!/bin/sh
# Purpose: selftest case — on a native Windows shell, ViD checks once that WSL starts, records the answer and says so in
# one line, with no question (0.26.11.1.3, R2). On a faked native Windows shell (MINGW64_NT) with a working fake `wsl.exe`
# (it logs its calls, its `wslpath -a` gives the file's absolute path, and it runs `sh …` natively) and no
# .vid/windows, `sh checks/lib/wsl.sh notice` records `wsl: yes` at the main checkout and prints the one yes line,
# naming that file; the PRD court run after it goes through `wsl.exe`. With ViD's skills beside checks/: init and
# create-prd ask no WSL question and run `notice`; vid-run (after its refresh), vid-plan (after its refresh, before its
# courts) and vid-develop run it in their start; RECORDS.md's `.vid/windows` row names `notice` as its writer; and
# vid-run's loop paragraph holds the pinned sentence on running the round itself (0.26.11.1.3, R4). Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
fail() { echo "windows-wsl-notice: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
LIB="$CHECKS/lib/wsl.sh"
[ -f "$LIB" ] || fail 'checks/lib/wsl.sh is missing'
NPATH=''; _o=$IFS; IFS=:; for d in $PATH; do [ -n "$d" ] && [ ! -e "$d/wsl.exe" ] && NPATH="${NPATH:+$NPATH:}$d"; done; IFS=$_o
mkdir -p "$T/bin" "$T/wslbin" "$T/p"
printf '#!/bin/sh\necho MINGW64_NT-10.0-19045\n' > "$T/bin/uname"
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
F="$(git rev-parse --show-toplevel)/.vid/windows"
: > "$T/wsl.log"
N=$(PATH=$FPATH sh "$LIB" notice 2> "$T/err") || fail "notice exited non-zero: $(cat "$T/err")"
[ -f "$F" ] && grep -qx 'wsl: yes' "$F" || fail "with WSL working, notice did not record 'wsl: yes' in $F"
grep -qx 'sh -c true' "$T/wsl.log" || fail "notice did not probe WSL (wsl.exe -e sh -c true): $(tr '\n' ';' < "$T/wsl.log")"
WANT="ViD runs its checks through WSL on this PC, which is much faster. To stop it, change \`wsl: yes\` to \`wsl: no\` in \`$F\`."
[ "$N" = "$WANT" ] || fail "with WSL working, notice printed '$N', not the one yes line"
[ ! -s "$T/err" ] || fail "notice wrote to standard error: $(cat "$T/err")"
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md; : > "$T/wsl.log"
PATH=$FPATH sh "$CHECKS/prd.sh" PRD.md > /dev/null 2>&1 || fail 'the passing PRD failed after the notice'
grep -q "^sh .*/prd\.sh " "$T/wsl.log" || fail "after the notice recorded yes, the court did not go through wsl.exe: $(tr '\n' ';' < "$T/wsl.log")"
# the skills, RECORDS.md and vid-run's loop sentence
S=$CHECKS/../skills
[ -d "$S" ] && [ -f "$CHECKS/../RECORDS.md" ] || { echo 'needs skills/ and RECORDS.md beside checks/'; exit 77; }
for k in vid-init vid-create-prd vid-run vid-plan vid-develop; do
  tr '\n' ' ' < "$S/$k/SKILL.md" | tr -s ' ' | grep -qF 'checks/lib/wsl.sh" notice' || fail "$k does not run checks/lib/wsl.sh notice"
done
for k in "$S"/*/SKILL.md; do
  tr '\n' ' ' < "$k" | tr -s ' ' > "$T/flat"
  ! grep -qE 'wsl\.sh" (ask|record)' "$T/flat" || fail "${k#"$S"/} still runs wsl.sh ask or record"
  ! grep -qi 'WSL question' "$T/flat" || fail "${k#"$S"/} still names the WSL question"
done
at() { grep -n -F -- "$2" "$1" | head -1 | cut -d: -f1; }
VR=$S/vid-run/SKILL.md; n=$(at "$VR" 'checks/lib/wsl.sh" notice')
[ "$n" -gt "$(at "$VR" 'checks/refresh.sh"')" ] && [ "$n" -lt "$(at "$VR" '## The loop')" ] || fail "vid-run does not run the notice after its refresh, before the loop"
VP=$S/vid-plan/SKILL.md; n=$(at "$VP" 'checks/lib/wsl.sh" notice')
[ "$n" -gt "$(at "$VP" 'checks/refresh.sh"')" ] && [ "$n" -lt "$(at "$VP" 'checks/prd.sh PRD.md')" ] || fail "vid-plan does not run the notice after its refresh, before its courts"
VD=$S/vid-develop/SKILL.md; n=$(at "$VD" 'checks/lib/wsl.sh" notice')
[ "$n" -gt "$(at "$VD" '## Before any work')" ] && [ "$n" -lt "$(at "$VD" '## The run loop')" ] || fail "vid-develop does not run the notice in its start"
grep '^| `\.vid/windows`' "$CHECKS/../RECORDS.md" > "$T/row" || fail "RECORDS.md has no .vid/windows row"
grep -qF 'wsl.sh notice' "$T/row" && ! grep -qF 'record yes' "$T/row" || fail "RECORDS.md's .vid/windows row does not name notice as its writer"
awk '/^## The loop/ { on = 1; next } on && NF { p = 1; print; next } on && p { exit }' "$VR" | tr '\n' ' ' > "$T/loop"
grep -qF 'Run `round.sh wait` and `round.sh step` yourself, in the foreground, in this turn; never from a script of your own, nor in the background.' "$T/loop" \
  || fail "vid-run's loop paragraph lacks the pinned sentence: $(cat "$T/loop")"
echo 'windows-wsl-notice: ok'
