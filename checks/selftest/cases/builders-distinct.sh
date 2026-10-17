#!/bin/sh
# Purpose: selftest case — builders counted by distinct id (v0.9.7.3 spec 3.9, R9). A resumed background builder
# records a second agent-start, which the observer's episodes need: in progress's By builder tool line the Claude
# builders a1 (started twice) and a2 count 2, the Codex job 1-builder-3 (started twice) counts 1; Builders at once
# counts each open agent once. v0.9.8.1 (R7): the line may go on to say its hand-backs were not found. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "builders-distinct: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; cp "$CHECKS/plan.sh" checks/; rows s1 1 2; commit_all rows
plan 'step S1 | name: one | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one' --trigger initial --expect x > /dev/null
E=.vid/metrics-events; mkdir -p .vid/briefs/1
for a in a1 a1 a2; do printf 'agent-start agent=%s type=vid:builder transcript=- at=%s\n' "$a" "$(utcnow)" >> $E; done
for k in 1 2; do printf 'job-start try=1-builder-3 at=%s\n' "$(utcnow)" >> $E; done
bc() { printf 'build-cost role=builder slice=1 step=S1 brief=%s rows=1 rows-passed=0 peak=1 total=1 before-change=unknown tool=%s model=m effort=e brief-bytes=9 at=%s\n' "$1" "$2" "$(utcnow)" >> $E; }
bc .vid/briefs/1/builder-1.md claude; bc .vid/briefs/1/builder-3.md codex
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep '^| By builder tool ' "$T/out" | grep -qE 'claude: .* · builders 2( · [^;]*)?; codex: .* · builders 1( · [^|]*)? \|' || fail "builders are not counted once each: $(grep '^| By builder tool' "$T/out")"
grep -q '^| Builders at once | 3 open ' "$T/out" || fail "Builders at once does not count each open agent once: $(grep '^| Builders at once' "$T/out")"
exit 0
