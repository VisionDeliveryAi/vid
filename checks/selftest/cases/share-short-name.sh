#!/bin/sh
# Purpose: selftest case — the share redacts a Windows short user folder name (FIX-BATCH-T2 §1, B-12). A made-up user, $HOME
# under Users/<two words>, $USERNAME the first word of a short name; a record, a log and a transcript hold the long name and
# the short forms after a Users or home folder: one, two and four backslashes, slashes, Git Bash's and the WSL mount's, lower
# case, a hashed one, another user's with an extension, and one holding - whose start is the known name. Convicts unless each
# short form is [REDACTED:user-name] whole in every file, none is left in the bundle, the summary or the build's output, the scan
# is clean, a short form planted after the build is found by the scan, the summary's not-caught line names Claude's folder
# names, and these stay as they are: HEAD~1, C:\PROGRA~1\ (no user folder before it), C:\Users\Public\, a deeper folder under
# home (home/x/notes~1). And on a line long enough to be cut (8192 characters), a short name holding a false \r escape
# (C:\Users\richar~1). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-short-name: $*" >&2; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 VID_SHARE_HOST=box-q1 USERNAME=JEAN
U=Users; export HOME="$T/h/$U/Wren Halloway"; mkdir -p "$HOME"; export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR/projects"
P=$T/p; mkdir -p "$P/checks" "$P/.vid/notes" "$T/dev"; cp "$CHECKS/share.sh" "$P/checks/"; cd "$P"; git init -q
printf 'run: active\n' > .vid/RUN-STATE.md
forms() {
  printf 'long C:\\Users\\Wren Halloway\\x\n'
  printf 'one C:\\Users\\WRENHA~1\\AppData\\Local\\Temp\\x two C:\\\\Users\\\\WRENHA~1\\\\x four C:\\\\\\\\Users\\\\\\\\WRENHA~1\\\\\\\\x\n'
  printf 'slash C:/%s/WRENHA~1/x bash /c/%s/WRENHA~1/x wsl /mnt/c/%s/WRENHA~1/x lower c:\\users\\wrenha~1\\x\n' $U $U $U
  printf 'hash C:\\Users\\WR1A2B~1\\x other C:\\Users\\JODOES~2.SMI\\x dash C:\\Users\\JEAN-L~1\\AppData\n'
  printf 'stay HEAD~1 and C:\\PROGRA~1\\Tool and C:\\Users\\Public\\x and /%s/x/notes~1/y\n' home
}
forms > .vid/notes/t.txt; forms > "$T/dev/t.txt"
# a long line (over 8192 characters, so the identity stage cuts it), whose short name holds a false \r escape
awk 'BEGIN { for (i = 0; i < 4500; i++) printf "x"; printf " C:\\Users\\richar~1\\Temp "; for (i = 0; i < 4500; i++) printf "x"; print "" }' > .vid/notes/long.txt
WD="$CLAUDE_CONFIG_DIR/projects/-p"; mkdir -p "$WD"; forms | awk '{ gsub(/\\/, "\\\\"); printf "{\"type\":\"user\",\"message\":{\"content\":\"%s\"}}\n", $0 }' > "$WD/S-1.jsonl"
printf 'session id=S-1 source=startup transcript="%s/S-1.jsonl" at=2026-11-27T10:00:00Z\n' "$WD" > .vid/metrics-events
sh checks/share.sh build --run 2026-11-s --logs "$T/dev" > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the build failed'; }
B=.vid/shares/2026-11-s
ES=$(printf 'slash C:/%s/[REDACTED:user-name]/x bash /c/%s/[REDACTED:user-name]/x wsl /mnt/c/%s/[REDACTED:user-name]/x lower c:\\users\\[REDACTED:user-name]\\x' $U $U $U)
EY=$(printf 'stay HEAD~1 and C:\\PROGRA~1\\Tool and C:\\Users\\Public\\x and /%s/x/notes~1/y' home)
for f in records/.vid/notes/t.txt logs/t.txt conversations/S-1/S-1.jsonl.gz; do
  [ -f "$B/$f" ] || fail "$f is not in the bundle"
  case $f in *.gz) gzip -dc "$B/$f" | sed 's/\\\\/\\/g' ;; *) cat "$B/$f" ;; esac > "$T/f"
  grep -qF 'one C:\Users\[REDACTED:user-name]\AppData' "$T/f" || fail "$f: the short form is not replaced: $(grep '^one' "$T/f")"
  grep -qF "$ES" "$T/f" || fail "$f: a slash or lower-case form is left: $(grep '^slash' "$T/f")"
  grep -qF 'hash C:\Users\[REDACTED:user-name]\x other C:\Users\[REDACTED:user-name]\x dash C:\Users\[REDACTED:user-name]\AppData' "$T/f" || fail "$f: a hashed, another user's or a dashed short form is left: $(grep '^hash' "$T/f")"
  grep -qF "$EY" "$T/f" || fail "$f: a value that stays was changed: $(grep '^stay' "$T/f")"
done
( cd "$B" && find . -type f | while IFS= read -r f; do case "$f" in *.gz) gzip -dc "$f" ;; *) cat "$f" ;; esac; done ) > "$T/all"; cat "$B.summary" "$T/out" >> "$T/all"
grep -qF ' C:\Users\[REDACTED:user-name]\Temp ' "$B/records/.vid/notes/long.txt" || fail 'a short name on a long line is left'
for x in WRENHA wrenha WR1A2B JODOES -L~1 richar~1; do n=$(grep -cF -- "$x" "$T/all" || true); [ "$n" = 0 ] || fail "$x is left on $n lines"; done
grep -qx 'scan	clean' "$B.summary" || fail 'the scan is not clean'
grep -i "^not-caught	.*Claude's folder names" "$B.summary" > /dev/null || fail "the summary's not-caught line does not name Claude's folder names"
printf 'planted C:\\Users\\ZQXWVU~3\\x\n' >> "$B/records/.vid/notes/t.txt"
if sh checks/share.sh scan "$B" > "$T/sc" 2>&1; then fail 'the scan found nothing after a short name was planted'; fi
grep -q 'records/.vid/notes/t.txt	user-name	1' "$T/sc" || fail "the scan does not name the planted short name: $(cat "$T/sc")"
echo 'share-short-name: ok'
