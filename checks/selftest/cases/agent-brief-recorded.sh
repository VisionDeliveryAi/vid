#!/bin/sh
# Purpose: selftest case — every agent's brief is recorded at its first tool call (v0.9.8.1 R14). Needs the plugin's
# hooks/ beside checks/. The reread fixture: on a PostToolUse call, net.sh records `agent-brief agent=<id> brief=<path
# relative to the home>` for a builder, for a grader and for a test-author (every role), also when the context net's
# own marker already stands (before its early exits); an agent whose transcript names no brief, and one with no
# transcript, are recorded `brief=unavailable`; the main session records nothing. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=agent-brief-recorded
. "$CHECKS/selftest/fixtures/reread-lib.sh"
ab() { grep "^agent-brief agent=$1 " "$H/.vid/metrics-events" || true; }
ag_setup b1 .vid/briefs/2/builder-1.md 10; net b1
ab b1 | grep -q '^agent-brief agent=b1 brief=.vid/briefs/2/builder-1.md at=' || fail "the builder's brief is not recorded: $(ab b1)"
ag_setup g1 .vid/briefs/2/grader-4.md 10; net g1
ab g1 | grep -q '^agent-brief agent=g1 brief=.vid/briefs/2/grader-4.md at=' || fail "a grader's brief is not recorded: $(ab g1)"
ag_setup t1 .vid/briefs/2/test-author-7.md 10; : > "$H/.vid/net.t1"; net t1
ab t1 | grep -q '^agent-brief agent=t1 brief=.vid/briefs/2/test-author-7.md at=' || fail "a test-author's brief, beside the net's marker, is not recorded: $(ab t1)"
ag_setup n1 'no brief here' 10; net n1
ab n1 | grep -q '^agent-brief agent=n1 brief=unavailable at=' || fail "an agent naming no brief is not recorded unavailable: $(ab n1)"
net z9
ab z9 | grep -q '^agent-brief agent=z9 brief=unavailable at=' || fail "an agent with no transcript is not recorded unavailable: $(ab z9)"
N=$(grep -c '^agent-brief ' "$H/.vid/metrics-events"); net ''
[ "$(grep -c '^agent-brief ' "$H/.vid/metrics-events")" -eq "$N" ] || fail 'the main session recorded an agent-brief'
exit 0
