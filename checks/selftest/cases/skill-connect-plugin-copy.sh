#!/bin/sh
# Purpose: selftest case — every skill's connect start goes through the plugin's own copy (the GM-4 proof's D1). The start
# refreshes ./checks/ first, so a skill that runs the project's copy (`sh checks/connect.sh start`) runs an older connect that
# refreshes nothing, and the entries after it run on old scripts. No skill gives `sh checks/connect.sh start` or
# `sh checks/connect.sh refresh-no` (the no of a refresh that waited, when ./checks/ is the old copy); each skill that names the
# start gives it as `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start`. Reads skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-connect" ] || { echo 'skill-connect-plugin-copy: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "skill-connect-plugin-copy: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# each skill joined into one line, so a call broken across two lines is read whole
for f in "$S"/*/SKILL.md; do n=$(basename "$(dirname "$f")"); tr '\n' ' ' < "$f" | tr -s ' ' > "$T/$n"; done
grep -l 'sh checks/connect\.sh \(start\|refresh-no\)' "$T"/* > "$T/bad" 2>/dev/null || :
[ ! -s "$T/bad" ] || fail "these skills run the project's own connect.sh start or refresh-no, not the plugin's: $(sed 's#.*/##' "$T/bad" | paste -sd ' ' -)"
grep -l 'connect\.sh[" ]* start' "$T"/* > "$T/named" || fail 'no skill names the connect start'
for f in $(cat "$T/named"); do grep -qF 'sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start' "$f" || fail "$(basename "$f") names the connect start but not through the plugin's copy"; done
echo 'skill-connect-plugin-copy: ok'
