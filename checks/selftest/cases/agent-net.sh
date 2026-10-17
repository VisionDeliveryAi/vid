#!/bin/sh
# Purpose: selftest case — the context net (v0.9.7.0.7 spec 3.7, R11; §6 E-3). Needs the plugin's
# hooks/ beside checks/. The reread fixture. Convicts unless hooks.json registers hooks/net.sh for
# every PostToolUse; a builder whose latest context (5000) is under .vid/budget
# builder-context-tokens=6000 gets nothing; at 6000 it gets the reminder once, as additionalContext
# in the documented PostToolUse output, naming 6000, and <home>/.vid/net.a77 is written; a second
# call gets nothing; a grader agent over the budget, the main session and an agent with no
# transcript get nothing; with no budget line the default 400000 applies (5000: nothing). Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=agent-net
. "$CHECKS/selftest/fixtures/reread-lib.sh"
tr -d ' \n' < "$HD/hooks.json" | grep -q '{"hooks":\[{"type":"command","command":"sh\\"${CLAUDE_PLUGIN_ROOT}/hooks/net.sh\\""' || fail 'hooks.json does not register net.sh'
told() { grep -q '"hookEventName":"PostToolUse","additionalContext":"Your context is past' "$T/net.out"; }
ag_setup a77 .vid/briefs/2/builder-1.md 5000
net a77; [ ! -s "$T/net.out" ] || fail 'the default budget fired at 5000'
printf 'stacks=1\nbuilder-context-tokens=6000\n' > "$H/.vid/budget"
net a77; [ ! -s "$T/net.out" ] || fail 'the net fired under the budget'
ag_setup a77 .vid/briefs/2/builder-1.md 6000
net a77; told || fail 'the net did not fire at the budget'
grep -qF 'Your context is past 6000 tokens. Finish at your next legal commit point — a green iterate run and the gates passing — write your hand-back block, and stop. Do not start new work.' "$T/net.out" || fail 'the reminder is not the text'
[ -e "$H/.vid/net.a77" ] || fail 'no marker written'
net a77; [ ! -s "$T/net.out" ] || fail 'the net fired twice'
ag_setup a88 .vid/briefs/2/grader-1.md 9000; net a88; [ ! -s "$T/net.out" ] || fail 'a grader was told'
net ''; [ ! -s "$T/net.out" ] || fail 'the main session was told'
net a99; [ ! -s "$T/net.out" ] || fail 'an agent with no transcript was told'
exit 0
