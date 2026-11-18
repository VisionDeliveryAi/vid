#!/bin/sh
# Purpose: selftest case — ViD's face R20 and R26 (0.26.10.29): the panel reads the three files (usability P4: the
# sitting, the standing and its conversation's run file), keeps unsent marks in the store Claude Code gives it, and
# sends the person's words; it writes no file and runs no program. Convicts unless the panel reads
# .vid/face/run.<its session id>; unless Claude Code's validator (claude plugin validate) passes the plugin and lists,
# among the panel module's calls, $.fs.read and $.store.set and none of $.fs.write, $.fs.remove, $.process (run or
# spawn) or $.http, but the recorder's one write; unless that write is the recorder's (hooks/face/recorder.ts, P4:
# $.fs.write via recordStop alone, the engine loading one module a plugin) and the recorder draws, prompts, runs and
# fetches nothing; and unless
# every word the panel draws takes a theme's named colour (no Text colour given as a raw value). Gated on hooks/face/
# beside checks/ and, for the validator, on a claude on PATH. Env: CHECKS.
set -eu
P=$(cd "$CHECKS/.." && pwd -P); R="$P/hooks/face/register.tsx"
[ -f "$R" ] || { echo 'needs the plugin'"'"'s hooks/face/'; exit 77; }
fail() { echo "face-r20-calls: $*" >&2; exit 1; }
# R26: a Text's colour is a theme name, never a raw value
grep -nE '<Text[^>]*color=("#|\{["'"'"']#|\{(LINE|FILL|TINT|INK))' "$R" && fail 'a Text takes a raw colour'
grep -q "color=\"subtle\"" "$R" || fail 'the panel draws no word in a theme colour (the check reads nothing)'
grep -q 'run\.\${' "$R" || fail "the panel does not read its conversation's run file"
# usability (P11): the hover that shows a done stop's line sits on the visible piece, which shares its scope with the
# hidden line (the kit hands back no hover prop, so this reads the source)
grep -qE 'key=\{`stop-\$\{x\.n\}`\}[^>]*hover=\{\{ scope: `vid-stop-\$\{x\.n\}` \}\}' "$R" || fail "a stop's visible piece carries no hover scope"
grep -qE "display=\"none\" hover=\{\{ scope: \`vid-stop-\\\$\{x\.n\}\`, display: 'flex' \}\}" "$R" || fail "a stop's hidden line is not revealed by its piece's scope"
REC="$P/hooks/face/recorder.ts"; [ -f "$REC" ] || fail 'no recorder'
grep -q 'ui.render' "$REC" && fail 'the recorder draws'
command -v claude >/dev/null 2>&1 || { echo 'needs claude on PATH for its validator'; exit 77; }
set +e; OUT=$(claude plugin validate "$P" 2>&1 < /dev/null); RC=$?; set -e
[ "$RC" = 0 ] || fail "the validator refused the plugin: $(printf '%s\n' "$OUT" | tail -3)"
CALLS=$(printf '%s\n' "$OUT" | grep 'face/register.tsx calls:' || true)
[ -n "$CALLS" ] || fail 'the validator lists no calls for the panel module'
for c in '\$.fs.read' '\$.store.set'; do printf '%s\n' "$CALLS" | grep -q "$c" || fail "the panel's calls lack $c"; done
printf '%s\n' "$CALLS" | grep -q '\$\.fs\.write (via recordStop)' || fail "the validator lists no write by the recorder: $CALLS"
printf '%s\n' "$CALLS" | sed 's/\$\.fs\.write (via recordStop)//' | grep -qE '\$\.(fs\.(write|remove|mkdir|rename|copy)|process\.|http\.)' && fail "the panel writes a file, runs a program or fetches: $CALLS"
grep -qE '\$\.(ui|prompt|process|http|store|state)\.' "$REC" && fail 'the recorder does more than its one write'
exit 0
