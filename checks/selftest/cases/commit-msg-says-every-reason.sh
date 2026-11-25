#!/bin/sh
# Purpose: selftest case — a refused message says every reason at once (FB-4 C2). The commit-msg hook in a scratch
# repository: a staged stage cut, a human answer and a ledger file under a message with none of the four lines are
# refused once, each reason said, one event by=decisions,stages,owner,tests-by. With VID_NEEDS=1 (pre-commit's call, for
# what the message will need) it says the same and writes no event. Run on a draft file it checks the draft, and a
# message holding all four passes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/p/checks/hooks" "$T/p/tests/invariants"; cd "$T/p"; git init -q
fail() { echo "commit-msg-says-every-reason: $*" >&2; cat "$T/out" .vid/metrics-events >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
cp "$CHECKS/hooks/commit-msg" checks/hooks/; cp "$CHECKS/plan.sh" "$CHECKS/event.sh" "$CHECKS/stages.sh" checks/; [ ! -f "$CHECKS/run.sh" ] || cp "$CHECKS/run.sh" checks/
[ ! -d "$CHECKS/lib" ] || cp -R "$CHECKS/lib" checks/
[ ! -f "$CHECKS/lib.sh" ] || cp "$CHECKS/lib.sh" checks/
cp "$CHECKS/selftest/fixtures/prd-known-good.md" PRD.md
g add -A && g commit -qm root --no-verify
printf '\n### 2026-09-30 (owner answer)\n\n```vid-prd-answers\nA-107 | human | 2026-09-30 | Q: may a subscriber pause digests? | A: yes, for a while | settles: REQ-001\n```\n' >> PRD.md
printf '# Stages\n\n```vid-stages\nSTAGE-1 | FEAT-01\n```\n' > STAGES.md
printf '# Purpose: t\n' > tests/invariants/test_a.py; g add -A
says() { for m in 'no "Decisions:" line' 'creates STAGES.md' 'the owner'"'"'s ruling(s) A-107' 'no valid "Tests-by:" trailer'; do grep -qF "$m" "$T/out" || fail "$1: not said: $m"; done; }
printf 'a change\n' > "$T/m"
if sh checks/hooks/commit-msg "$T/m" > "$T/out" 2>&1; then fail 'a message with none of the four lines was accepted'; fi
says 'one attempt'
[ "$(grep -c '^refused ' .vid/metrics-events)" = 1 ] || fail 'not one refused event'
grep -q '^refused phase=commit-msg by=decisions,stages,owner,tests-by attempt=' .vid/metrics-events || fail 'the event does not name the four'
if VID_NEEDS=1 sh checks/hooks/commit-msg "$T/m" > "$T/out" 2>&1; then fail 'VID_NEEDS=1 accepted the message'; fi
says 'VID_NEEDS=1'
[ "$(grep -c '^refused ' .vid/metrics-events)" = 1 ] || fail 'VID_NEEDS=1 wrote an event'
printf 'a change\n\nDecisions: none — nothing surprising\nStages: A-107\nOwner: "yes, for a while"\nTests-by: test-author 2026-09-30 b1\n' > "$T/m"
sh checks/hooks/commit-msg "$T/m" > "$T/out" 2>&1 || fail 'a draft with the four lines was refused'
[ ! -s "$T/out" ] || fail 'a passing message printed something'
[ "$(grep -c '^refused ' .vid/metrics-events)" = 1 ] || fail 'a passing message wrote an event'
exit 0
