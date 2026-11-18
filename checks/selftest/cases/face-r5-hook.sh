#!/bin/sh
# Purpose: selftest case — ViD's face R5 after the PRD (0.26.10.29): the standing follows stops 6 to 9,
# which no sitting writes. The plugin's hook hooks/face-standing.sh, after a tool call, recomputes the standing where
# .vid/face/standing.json is there, and does nothing elsewhere. Convicts unless hooks.json runs it after Bash, Write
# and Edit; unless, after pause 3 ended, BASELINE.md and ARCHITECTURE.md written and the hook run, the standing says
# stop 7; unless at the end of a turn (Stop, usability P4) it recomputes the standing too, design/ then giving stop 8;
# and unless in a folder with no standing it writes nothing and exits 0. Gated on the plugin's hooks/.
# Env: CHECKS.
set -eu
H=$CHECKS/../hooks
[ -f "$H/face-standing.sh" ] || { echo 'needs the plugin'"'"'s hooks/face-standing.sh'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-r5-hook: $*" >&2; exit 1; }
grep -q 'hooks/face-standing.sh' "$H/hooks.json" || fail 'hooks.json does not run face-standing.sh'
python3 -c "import json,sys; d=json.load(open('$H/hooks.json')); m=[x.get('matcher','') for x in d['hooks'].get('PostToolUse',[]) if any('face-standing.sh' in h.get('command','') for h in x['hooks'])]; sys.exit(0 if m and all(t in m[0].split('|') for t in ('Bash','Write','Edit')) else 1)" || fail 'face-standing.sh does not run after Bash, Write and Edit'
mkdir empty; (cd empty && git init -q && printf '{"tool_name":"Bash"}' | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh") || fail 'the hook fails where nothing is written'
[ ! -d empty/.vid ] || fail 'the hook wrote in a folder with no standing'
. "$CHECKS/selftest/fixtures/face.sh"
printf '%s\n' '- 2026-11-12 — thesis+contract — a' '- 2026-11-12 — gap answers — b' '- 2026-11-12 — final — c' > R
# the final wording is written before its ratification, as the skill does; a write after it is at a passed stop (0.26.10.29.6, S1)
fc_run write pause-3 lines.pause-3
awk '{ print } /^## Ratifications/ { while ((getline l < "R") > 0) print l }' PRD.md > X && mv X PRD.md
fc_run end pause-3
[ "$(fc_stand "d['current']")" = 6 ] || fail "after pause 3 the standing is not stop 6: $(fc_stand "d['current']")"
: > BASELINE.md; : > ARCHITECTURE.md
printf '{"tool_name":"Write"}' | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh" || fail 'the hook failed'
[ "$(fc_stand "d['current']")" = 7 ] || fail "the hook did not move the standing to stop 7: $(fc_stand "d['current']")"
mkdir design
printf '{"hook_event_name":"Stop","session_id":"s1"}' | CLAUDE_PLUGIN_ROOT="$CHECKS/.." sh "$H/face-standing.sh" || fail 'the hook failed at Stop'
[ "$(fc_stand "d['current']")" = 8 ] || fail "the hook at Stop did not move the standing to stop 8: $(fc_stand "d['current']")"
exit 0
