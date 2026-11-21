#!/bin/sh
# Purpose: selftest case — DevAgent's role file puts the decide ask on the pull request (low-1, R7): devagent/agents/dev-manager.md has a
# line naming `gh pr comment` for `vid: decide`, and a line saying it never goes on the ticket's issue. Skips where devagent/ is absent. Env: CHECKS.
set -eu
RT=$(cd "$CHECKS/.." && pwd -P); [ -d "$RT/devagent" ] || { echo 'needs devagent/'; exit 77; }
F=$RT/devagent/agents/dev-manager.md
grep -F 'vid: decide' "$F" | grep -qF 'gh pr comment <p> -R <repo> --body-file <f>' || { echo 'devagent-decide-place: no line names gh pr comment for vid: decide' >&2; exit 1; }
grep -F 'vid: decide' "$F" | grep -qi "never on the ticket's issue" || { echo "devagent-decide-place: no line says vid: decide never goes on the ticket's issue" >&2; exit 1; }
echo 'devagent-decide-place: ok'
