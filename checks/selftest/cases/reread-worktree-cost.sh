#!/bin/sh
# Purpose: selftest case — the re-read hook in a worktree costs next to nothing and still holds a debt (0.26.11.1.3, R1).
# The home is a ViD project with checks/ and .vid/RUN-STATE.md; a linked worktree's .vid/home names it. Every
# external command hooks/reread.sh starts is counted through a shim on the PATH. Convicts unless a main-session
# PreToolUse call with no re-read owed starts four or fewer, none of them git or sh, from the worktree and from a
# folder inside it; unless, once the home owes a re-read for the session, the same call from the worktree is denied
# (the control half: it held before R1); and unless, with the worktree's .vid/home naming a folder with no
# RUN-STATE.md, the full resolver still runs (a git is started). Gated on the plugin's hooks/. Env: CHECKS.
set -eu
unset GIT_INDEX_FILE GIT_DIR
HD=$CHECKS/../hooks
[ -f "$HD/reread.sh" ] || { echo 'needs the plugin'"'"'s hooks/reread.sh'; exit 77; }
HD=$(cd "$HD" && pwd -P)
fail() { echo "reread-worktree-cost: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; T=$(cd "$T" && pwd -P)
SH=$(command -v sh)
mkdir -p "$T/shim"
for c in awk sed grep cut tr head tail sort uniq dirname basename cat wc date mktemp rm mv cp mkdir find env git ls \
  printf echo test sh bash dash pwd; do
  p=$(command -v "$c" 2>/dev/null || true); case "$p" in /*) ;; *) continue ;; esac
  printf '#!%s\nprintf "%%s\\n" %s >> "$SHIMLOG"\nexec "%s" "$@"\n' "$SH" "$c" "$p" > "$T/shim/$c"; chmod +x "$T/shim/$c"
done
# pre <cwd>: a main-session PreToolUse Bash call from <cwd>; the external commands counted, their names in $T/log
pre() {
  : > "$T/log"
  printf '{"session_id":"S1","transcript_path":"/t/S1.jsonl","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"ls"},"tool_use_id":"t1"}' "$1" \
    | ( cd "$T" && env -u CLAUDE_PROJECT_DIR SHIMLOG="$T/log" PATH="$T/shim:$PATH" "$SH" "$HD/reread.sh" ) > "$T/out" 2>&1 || true
  grep -c . "$T/log" || true
}
P="$T/home"; mkdir -p "$P/.vid"; mkdir -p "$P/checks"; cp "$CHECKS/plan.sh" "$P/checks/"; mkdir -p "$P/src"; : > "$P/src/keep"
( cd "$P" && git init -q && printf '.vid/\n' > .gitignore && git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root )
printf 'run: active\nsession: S1\n' > "$P/.vid/RUN-STATE.md"
printf 'stage name=develop state=start session=S1 records=8 at=2026-10-02T10:00:00Z\n' > "$P/.vid/metrics-events"
( cd "$P" && git worktree add -q "$T/W" -b w ) || fail 'no worktree'
mkdir -p "$T/W/.vid"; printf '%s\n' "$P" > "$T/W/.vid/home"
for c in "$T/W" "$T/W/src"; do
  n=$(pre "$c")
  [ "$n" -le 4 ] || fail "in a worktree naming a plain home, with no debt, reread.sh started $n external commands (over 4) from $c: $(tr '\n' ' ' < "$T/log")"
  grep -qxE 'git|sh|bash|dash' "$T/log" && fail "in a worktree naming a plain home, with no debt, reread.sh ran git or sh from $c: $(tr '\n' ' ' < "$T/log")"
  [ ! -s "$T/out" ] || fail "with no debt reread.sh printed something from $c: $(cat "$T/out")"
done
# the control half: a debt at the home holds the worktree's call
printf 'since 2026-10-02T10:00:00Z\nfile %s\n' "$P/checks/plan.sh" > "$P/.vid/reread-owed.S1"
pre "$T/W" > /dev/null
grep -q '"permissionDecision":"deny"' "$T/out" || fail "a debt at the home did not hold the worktree's call: $(cat "$T/out")"
rm -f "$P/.vid/reread-owed.S1"
# a stale pointer: the full resolver runs, as before R1
printf '%s\n' "$T/gone" > "$T/W/.vid/home"
pre "$T/W" > /dev/null
grep -qx git "$T/log" || fail "with .vid/home naming a folder with no RUN-STATE.md the full resolver did not run: $(tr '\n' ' ' < "$T/log")"
echo 'reread-worktree-cost: ok'
exit 0
