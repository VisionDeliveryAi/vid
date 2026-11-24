#!/bin/sh
# Purpose: selftest case — the writer with no engines line recorded (GM-4 F16), in GitHub manual on the step end's toy
# (fixtures/accept.sh) and the fake gh. Ticket #1 (S02) is open, its own commit older than the applied one, and .vid/tw/handed holds
# no `engines` line: `writer.sh due --why`, which writes the ticket again at its own commit only to compare its hash, needs none
# (FB-3 C5): exit 0, the same lines as with one recorded, never a shell error (an unbound variable). A real writing still ends in the writer's
# own refusal, naming the engines move (tw-form).
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "writer-no-engines: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail 'the plan could not be recorded'
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 || fail 'spec-export failed'
# the applied commit moves on: the ticket's own commit (applied.log's line at its publish) is the older one
O=$(cat .vid/tw/applied); printf '\nA later line.\n' >> PRD.md; git add PRD.md; git commit -qm 'a later spec'; git rev-parse HEAD > .vid/tw/applied
printf '%s\t2026-11-17T00:00:00Z\tapply\n%s\t2026-11-19T00:00:00Z\tapply\n' "$O" "$(git rev-parse HEAD)" > .vid/tw/applied.log
! grep -q '^engines' .vid/tw/handed 2>/dev/null || fail 'the toy already records an engines line'
RC=0; sh "$CHECKS/writer.sh" due --why > "$T/out" 2>&1 || RC=$?
! grep -qE 'unbound variable|parameter not set|line [0-9]+: ' "$T/out" || fail "a missing engines line gave a shell error: $(grep -E 'unbound variable|parameter not set|line [0-9]+: ' "$T/out" | head -n 1)"
[ "$RC" = 0 ] || fail "with no engines line, due --why exited $RC"; cp "$T/out" "$T/none"
# with an engines line, the same call goes through
printf 'engines alpha | stand-in: results reader\n' >> .vid/tw/handed
RC=0; sh "$CHECKS/writer.sh" due --why > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "with an engines line recorded, due --why exited $RC"
cmp -s "$T/none" "$T/out" || { cat "$T/none" >> "$T/out"; fail 'due --why says another thing with no engines line than with one'; }
exit 0
