#!/bin/sh
# Purpose: selftest case — the dev side's start printed in GitHub auto (v0.26.10.28.8, R3, R4, R10), on TW's toy, from a copy of the plugin
# whose folder holds a space. The toy's own answer ("the toy"), a `github-mode: auto` written by hand and an old GitHub team answer
# (FB-1 C1: the setup refuses team now; a project may still hold one) each print nothing; the owner's GitHub auto answer, given through planner.sh setup, prints the job note with the toy's repo: and
# labels-prefix:, a work: outside the toy and outside ViD's records, the three limits (agent-time-limit: at least 7200, with the line on an
# agent stopped twice), model: as dm.sh's MODEL0; in order (R12) the work folder's mkdir, the note, /vid:vid-devagent '<note>' in a new conversation in the work folder, then the background up line, the plugin's real folder single-quoted;
# and check, list, used and down the same way; agents: left to /vid:vid-devagent's question, and the closing sentence for each way (0.26.11.1.3, R5). Saved as printed where it says, with the folder step run, dm.sh check reads `ready` on
# fakes (where the dev side is beside checks/; checks/ alone runs on a stub dm.sh holding MODEL0 and skips that part). Nothing outside
# .vid/ changes and no folder is made. check flags github-mode before the first ratify, not after. vid-run's read-access line is
# conditioned on the GitHub mode, its start paragraph names the call. Env: CHECKS.
set -eu
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "devagent-start: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
[ -f "$CHECKS/devagent-start.sh" ] || fail 'no checks/devagent-start.sh: nothing prints the dev side'"'"'s start'
# the plugin's copy, a space in its folder: checks/ and the dev side as devagent/, or a stub dm.sh
PL="$T/the plugin"; mkdir -p "$PL/devagent/dev-manager"; cp -R "$CHECKS" "$PL/checks"; SIDE=''
for d in "$CHECKS/../devagent"; do [ -f "$d/dev-manager/dm.sh" ] || continue; cp -R "$d/." "$PL/devagent/"; SIDE=$d; break; done
[ -n "$SIDE" ] || printf '#!/bin/sh\nMODEL0=claude-opus-5-5   # a stub: the dev side is not beside checks/\necho "stub dm.sh $*"\n' > "$PL/devagent/dev-manager/dm.sh"
DM="$PL/devagent/dev-manager/dm.sh"; M0=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); [ -n "$M0" ] || fail 'no MODEL0 in the dev side'"'"'s dm.sh'
pr() { RC=0; sh "$PL/checks/devagent-start.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
snap() { find . -path ./.vid -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done; }
tw_toy "$T/p"; snap > "$T/s0"
# nothing outside GitHub auto, an old team answer among them, or with no answer
pr; [ "$RC" = 0 ] && [ ! -s "$T/out" ] || fail "the toy's own answer printed ($RC)"
pr mode; [ "$(cat "$T/out")" = none ] || fail "mode with no answer: $(cat "$T/out")"
echo 'github-mode: auto' >> .vid/tw/settings; pr; [ ! -s "$T/out" ] || fail 'a github-mode: written by hand printed the start'
RC=0; sh "$CHECKS/planner.sh" setup github-mode team --words 'our own team works them' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'setup github-mode team was taken (FB-1 C1: it is retired)'
printf 'setup-answered key=github-mode value="team" words="our own team works them" at=2026-11-03T09:30:00Z\n' >> .vid/plan/setup   # an old project's answer
pr; [ ! -s "$T/out" ] || fail 'an old GitHub team answer printed the start'; pr mode; [ "$(cat "$T/out")" = team ] || fail "mode after an old team answer: $(cat "$T/out")"
# GitHub auto
sh "$CHECKS/planner.sh" setup github-mode auto --words 'your own DevAgent, please' > /dev/null 2>&1 || fail 'setup github-mode auto'
pr mode; [ "$(cat "$T/out")" = auto ] || fail "mode after auto: $(cat "$T/out")"
pr; [ "$RC" = 0 ] && [ -s "$T/out" ] || fail "GitHub auto printed nothing ($RC)"; cp "$T/out" "$T/print"
awk '/^```$/ { n++; next } n == 1' "$T/print" > "$T/note"
key() { sed -n "s/^$1:[[:space:]]*//p" "$T/note" | head -n 1; }
[ "$(key repo)" = owner/code ] || fail "repo: $(key repo)"; grep -qx 'labels-prefix:' "$T/note" || fail "labels-prefix: $(grep '^labels-prefix' "$T/note")"
WK=$(key work); case $WK in "$T/p"|"$T/p"/*|'') fail "work: inside the toy, or none: $WK" ;; /*) ;; *) fail "work: not a full path: $WK" ;; esac
d=$(dirname "$WK"); while :; do [ ! -e "$d/.vid" ] || fail "work: $WK lies in $d, a folder of ViD's records"; [ "$d" != / ] || break; d=$(dirname "$d"); done
[ "$(key model)" = "$M0" ] || fail "model: $(key model), not MODEL0 $M0"
for k in time-limit agent-time-limit agent-turn-limit; do case $(key $k) in ''|*[!0-9]*) fail "$k: not a whole number: $(key $k)" ;; esac; done
[ "$(key agent-time-limit)" -ge 7200 ] || fail "agent-time-limit: $(key agent-time-limit), below 7200"
[ "$(grep -c . "$T/note")" = 7 ] || fail "the note holds $(grep -c . "$T/note") lines, not 7"
grep -q 'stopped twice at its limit leaves its ticket until the owner reopens it' "$T/print" || fail 'no line on an agent stopped twice'   # FB-2 A3: no longer for good
for k in time-limit agent-time-limit agent-turn-limit; do grep -q "^- $k: [0-9]* is a default you may change" "$T/print" || fail "no default line for $k"; done
grep -q '^- model: must be written in exactly this form' "$T/print" || fail 'no line on the model'"'"'s form'
NT=$(sed -n 's/^2\. Save this job note, exactly as it is, to \(.*\) (a folder that already exists, .*/\1/p' "$T/print"); [ -n "$NT" ] && [ -d "$(dirname "$NT")" ] || fail "no folder said for the note: $NT"
case $NT in "$T/p"/*|"$WK"/*) fail "the note goes inside the toy or the work folder: $NT" ;; esac
# 0.26.10.28.8 (R12): the folder first, the note, then the conversation of its own (the first way), then the background line
Q="'$DM'"; L=$(grep "^mkdir -p '" "$T/print" || true); [ "$L" = "mkdir -p '$WK'" ] || fail "the folder step: $L"
ln() { grep -nxF -- "$1" "$T/print" | head -n 1 | cut -d: -f1; }
a=$(ln "$L"); b=$(grep -n '^2\. Save this job note' "$T/print" | cut -d: -f1); c=$(ln "/vid:vid-devagent '$NT'"); d=$(ln "sh $Q up '$NT'")
[ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ -n "$d" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ] && [ "$c" -lt "$d" ] || fail "not folder, note, /vid:vid-devagent, then the background line: $a $b $c $d"
grep -q "open a new Claude Code conversation in the work folder" "$T/print" || fail 'the conversation is not said to open in the work folder'
# 0.26.11.1.3 (R5): the note leaves agents: to the conversation's one question; what closing the conversation does is said for each way
grep -q '^- agents: is left out: /vid:vid-devagent asks once' "$T/print" || fail 'no line on the agents: question'
grep -qF 'With agents: command, closing that conversation ends only the view: DevAgent runs on.' "$T/print" && grep -qF 'With agents: conversation, that conversation is DevAgent: closing it stops DevAgent until the conversation is opened again' "$T/print" || fail 'the closing sentence does not name each way'
grep -qF 'Or, with agents: command, for a run with no conversation to watch it' "$T/print" || fail 'the background line is not said to be for agents: command'
grep -qxF -- "- What it needs, starting nothing: sh $Q check '$NT'" "$T/print" || fail 'no check line'
grep -qxF -- "- What is alive, in its work folder: cd '$WK' && sh $Q list" "$T/print" || fail 'no list line'
grep -qxF -- "- The time and turns used so far: cd '$WK' && sh $Q used" "$T/print" || fail 'no used line'
grep -qxF -- "- Stop it: sh $Q down '$NT'" "$T/print" || fail 'no down line'
# it wrote nothing outside .vid/, made no folder
snap > "$T/s1"; cmp -s "$T/s0" "$T/s1" || fail "the print changed files: $(diff "$T/s0" "$T/s1" | head -n 4)"; [ ! -e "$WK" ] && [ ! -e "$NT" ] || fail 'the print made the work folder or the note'
# saved as printed, the line's mkdir run: check reads ready (on the real dev side, faked tools)
if [ -n "$SIDE" ]; then
  cat > "$T/bin/claude" <<'C'
#!/bin/sh
case "$1 ${2:-}" in 'auth --help') printf 'Commands:\n  status [options]  Show authentication status\n'; exit 0 ;; 'auth status') echo '{"loggedIn": true}'; exit 0 ;; esac; exit 1
C
  printf '#!/bin/sh\necho stub\n' > "$T/bin/docker"; chmod +x "$T/bin/claude" "$T/bin/docker"
  cp "$T/note" "$NT"; sh -c "$L" || fail 'the folder step failed'
  C=$(sed -n 's/^- What it needs, starting nothing: //p' "$T/print"); RC=0; sh -c "$C" > "$T/out" 2>&1 || RC=$?
  [ "$RC" = 0 ] && [ "$(tail -n 1 "$T/out")" = ready ] && ! grep -q '^missing:' "$T/out" || fail "dm.sh check on the note as printed ($RC)"
  rm -rf "$WK" "$NT"
else echo 'devagent-start: the dev side is not beside checks/: dm.sh check on the note is skipped'; fi
# a work folder already there that holds .vid is not given; the note's folder moves to $HOME
mkdir -p "$WK/.vid" "$T/home"; RC=0; HOME=$T/home sh "$PL/checks/devagent-start.sh" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "with the work folder in ViD's records ($RC)"
[ "$(sed -n 's/^work: *//p' "$T/out" | head -n 1)" = "$T/home/p-devagent" ] || fail "work: $(grep '^work:' "$T/out"), not under \$HOME"; rm -rf "$WK"
# the key: flagged before the first ratify, never after
grep -v '^setup-answered key=github-mode ' .vid/plan/setup > "$T/st" || true; cat "$T/st" > .vid/plan/setup
sh "$CHECKS/planner.sh" check > "$T/out" 2>&1 || true; ! grep -q '^setup github-mode' "$T/out" || fail 'a ratified plan is flagged for github-mode'
cd /; pt_toy "$T/q"; grep -v '^setup-answered key=github-mode ' .vid/plan/setup > "$T/st" || true; cat "$T/st" > .vid/plan/setup
sh "$CHECKS/planner.sh" check > "$T/out" 2>&1 || true; grep -q "^setup github-mode — no answer of the owner's is recorded" "$T/out" || fail 'github-mode unanswered is not flagged before the first ratify'
# the run's start (vid-connect's since GM-4 F2 and K10): it names the call; the read-access line only outside GitHub auto (R10)
S=$CHECKS/../skills/vid-connect/SKILL.md
if [ -f "$S" ]; then
  grep -q 'sh "${CLAUDE_PLUGIN_ROOT}/checks/devagent-start.sh"' "$S" && grep -q 'devagent-start.sh.*as it is' "$S" || fail 'vid-connect does not name the call, or to show its output as it is'
  grep 'read access' "$S" | grep -q 'devagent-start.sh" mode` prints `auto`' || fail 'vid-connect'"'"'s read-access line is not conditioned on the GitHub mode'
fi
echo 'devagent-start: ok'
