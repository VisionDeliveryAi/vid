#!/bin/sh
# Purpose: selftest case — unrelated plugins named, a notice only (v0.9.7.1 spec 3.12, R12). Convicts unless `sh
# checks/brief.sh plugins` reads the user, project and local settings files (the later scope wins): with a@m on
# at user scope and off at local scope, b@m off, vid@v on and c@x on at project scope, it lists c@x (project
# scope) only — never ViD, never a plugin turned off — and gives the project setting's form and the note that a
# local setting or the organisation can override it; exits 0; and with none it says `plugins: none`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "plugins-notice: $*" >&2; cat "$T/out" >&2; exit 1; }
mkdir -p "$T/home/.claude" "$T/p/.claude" "$T/p/checks"; cd "$T/p"; cp "$CHECKS/brief.sh" checks/
HOME=$T/home sh checks/brief.sh plugins > "$T/out" 2>&1 || fail 'plugins failed with no settings'
grep -qx 'plugins: none enabled beside ViD' "$T/out" || fail 'no settings does not say none'
printf '{\n  "model": "x",\n  "enabledPlugins": {\n    "a@m": true,\n    "b@m": false,\n    "vid@v": true\n  }\n}\n' > "$T/home/.claude/settings.json"
printf '{ "enabledPlugins": { "c@x": true } }\n' > .claude/settings.json
printf '{ "enabledPlugins": { "a@m": false } }\n' > .claude/settings.local.json
HOME=$T/home sh checks/brief.sh plugins > "$T/out" 2>&1 || fail 'plugins failed'
grep -qx '    c@x (enabled at project scope)' "$T/out" || fail 'c@x is not listed at project scope'
grep -q 'a@m\|b@m\|vid@v' "$T/out" && fail 'a plugin turned off, or ViD, is listed'
grep -qF '"enabledPlugins": {"<name>@<marketplace>": false}' "$T/out" || fail 'the project setting'"'"'s form is not given'
grep -qF 'the organisation can override it' "$T/out" || fail 'the override note is missing'
exit 0
