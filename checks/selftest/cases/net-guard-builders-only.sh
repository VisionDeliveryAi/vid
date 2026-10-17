#!/bin/sh
# Purpose: selftest case — the context net still reaches builders and fixers only (v0.9.8.1 R14). Needs the plugin's
# hooks/ beside checks/. The reread fixture, .vid/budget builder-context-tokens=6000: over the budget, a grader, a
# test-author and an analyst — each with its brief recorded — get no reminder; a builder and a fixer get it. Env: CHECKS.
set -eu
[ -f "$CHECKS/../hooks/stop-failure.sh" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=net-guard-builders-only
. "$CHECKS/selftest/fixtures/reread-lib.sh"
told() { grep -q '"hookEventName":"PostToolUse","additionalContext":"Your context is past' "$T/net.out"; }
printf 'stacks=1\nbuilder-context-tokens=6000\n' > "$H/.vid/budget"
for r in grader test-author test-analyst; do
  ag_setup "x-$r" ".vid/briefs/2/$r-1.md" 9000; net "x-$r"
  told && fail "a $r was told"
  grep -q "^agent-brief agent=x-$r brief=.vid/briefs/2/$r-1.md " "$H/.vid/metrics-events" || fail "the $r's brief is not recorded"
done
ag_setup y-b .vid/briefs/2/builder-1.md 9000; net y-b; told || fail 'a builder was not told'
ag_setup y-f .vid/briefs/2/fixer-1.md 9000; net y-f; told || fail 'a fixer was not told'
exit 0
