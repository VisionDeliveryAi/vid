#!/bin/sh
# Purpose: selftest case — an agent's brief is recorded once (v0.9.8.1 R14). Needs the plugin's hooks/ beside checks/.
# The reread fixture: three PostToolUse calls of one agent, two of them at once, record one `agent-brief`, and the
# marker <home>/.vid/agents/<id>.brief stands. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=agent-brief-once
. "$CHECKS/selftest/fixtures/reread-lib.sh"
ag_setup b2 .vid/briefs/2/builder-2.md 10
net b2
cp "$T/net.out" "$T/n0" 2>/dev/null || true
( net b2 ) & P=$!; net b2; wait "$P" || true
[ "$(grep -c '^agent-brief agent=b2 ' "$H/.vid/metrics-events")" -eq 1 ] || fail "not one agent-brief: $(grep '^agent-brief' "$H/.vid/metrics-events")"
[ -f "$H/.vid/agents/b2.brief" ] || fail 'no marker'
exit 0
