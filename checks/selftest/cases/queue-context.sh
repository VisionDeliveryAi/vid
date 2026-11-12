#!/bin/sh
# Purpose: selftest case — the compaction question is a Q line (v0.26.10.26.7, R13, W-15), checks/queue.sh on the writer's toy. With no
# autoCompactWindow in .claude/settings.json and no context-window event, sync makes context:window a Q line and announces it once;
# yes writes the setting (a fresh file, and into one with other keys) and the event, and the line goes; no writes the event alone; with
# the setting there, or the event, there is no line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "queue-context: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; QS=$CHECKS/queue.sh; qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
noev() { grep -v '^context-window ' .vid/metrics-events > "$T/m" || true; cat "$T/m" > .vid/metrics-events; }
qs sync; ! grep -q 'compaction point' .vid/RUN-STATE.md || fail 'a Q line with the question answered'
noev; mkdir -p .vid/decide/queue; qs sync; ok '^context-window Q[0-9][0-9]*$'; QC=$(sed -n 's/^context-window \(Q[0-9]*\)$/\1/p' "$T/out")
grep -q "^- $QC · asked .* · gates nothing · may ViD set this project's compaction point to 300,000 tokens, so this session compacts before its context grows costly? · answer yes or no$" .vid/RUN-STATE.md || fail "no Q line: $(grep '^- Q' .vid/RUN-STATE.md)"
qs sync; ! grep -q '^context-window' "$T/out" || fail 'announced twice'
qs answer "$QC" maybe; [ "$RC" != 0 ] || fail 'a third answer was taken'
qs answer "$QC" yes 'yes, set it'; [ "$RC" = 0 ] || fail "yes failed ($RC)"; grep -q '"autoCompactWindow": 300000' .claude/settings.json || fail 'no setting written'
grep -q '^context-window requested=300000 ' .vid/metrics-events || fail 'no event on yes'; qs sync; ! grep -q 'compaction point' .vid/RUN-STATE.md || fail 'the Q line stayed after yes'
# into a settings file with other keys; and no
noev; printf '{\n  "permissions": { "allow": [] }\n}\n' > .claude/settings.json; rm -f .vid/decide/queue/seen; sh "$QS" sync > /dev/null 2>&1; QC=$(sed -n 's/^- \(Q[0-9]*\) · .*compaction point.*/\1/p' .vid/RUN-STATE.md); [ -n "$QC" ] || fail 'no Q line with a settings file lacking the setting'
qs answer "$QC" yes 'yes'; [ "$(sed -n 2p .claude/settings.json)" = '  "autoCompactWindow": 300000,' ] && grep -q '"permissions"' .claude/settings.json || fail "the setting into a file with keys: $(cat .claude/settings.json)"
noev; rm -f .claude/settings.json; sh "$QS" sync > /dev/null 2>&1; QC=$(sed -n 's/^- \(Q[0-9]*\) · .*compaction point.*/\1/p' .vid/RUN-STATE.md); qs answer "$QC" no 'no thanks'; [ "$RC" = 0 ] || fail "no failed ($RC)"
[ ! -f .claude/settings.json ] && grep -q '^context-window requested=declined ' .vid/metrics-events || fail 'no wrote a setting, or no event'
echo 'queue-context: ok'
