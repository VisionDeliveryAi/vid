#!/bin/sh
# Purpose: selftest case — the writer's gate in GitHub manual (GM-2 T1). On the ticket writer's toy (fixtures/tw-toy.sh),
# its issue form committed, switched to manual with its applied version HEAD: an uncommitted edit to INVENTORY.md, then to
# PRD.md, DECISIONS.md and a golden set, leaves the gate open, as does no publish-approved event (each publish carries the
# owner's own words instead); an uncommitted edit to PLAN.md or to the issue form shuts it, each named. In GitHub auto the same
# uncommitted INVENTORY.md edit shuts the gate, named, and so does no publish-approved event. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "manual-writer-gate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gate() { RC=0; sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || RC=$?; }
open_() { gate; [ "$RC" = 0 ] || fail "the gate is shut in $MODE with $1"; }
shut() { gate; [ "$RC" = 1 ] || fail "the gate is open in $MODE with $2"; grep -qF "writer: gate — $1" "$T/out" || fail "not named in $MODE: $1"; }
tw_toy "$T/toy"
printf 'state-repo: owner/vid-state\nissue-form: forms/issue.md\n' >> .vid/tw/settings
mkdir -p forms; printf '# {name}\n\n{full-ticket}\n\n{tests}\n\n{blocked-by}\n{not-yet-ticketed}\n{fakes}\n' > forms/issue.md; g add forms; g commit -qm 'the issue form'
inv() { sed 's/one digest a day, holding only jobs/one digest each day, holding only jobs/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; }
cp .vid/metrics-events "$T/ev"; cp .vid/plan/setup "$T/setup"
# GitHub auto: the uncommitted edit shuts the gate, and so does no publish-approved event
MODE=auto; printf 'setup-answered key=github-mode value="auto" words="DevAgent" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
open_ 'nothing changed'
inv; shut 'INVENTORY.md has an uncommitted change' 'an uncommitted INVENTORY.md'; git checkout -q INVENTORY.md
grep -v '^publish-approved ' "$T/ev" > .vid/metrics-events; shut 'no publish-approved event' 'no publish-approved event'; cp "$T/ev" .vid/metrics-events
# GitHub manual, its applied version HEAD
MODE=manual; cp "$T/setup" .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=github-mode value="manual" words="by hand" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
open_ 'nothing changed'
inv; open_ 'an uncommitted INVENTORY.md'
printf '\nA line in progress.\n' >> PRD.md; printf '\nA decision in progress.\n' >> DECISIONS.md; printf 'x\n' >> tests/invariants/golden/synonyms.golden
open_ 'uncommitted edits to INVENTORY.md, PRD.md, DECISIONS.md and a golden set'
grep -v '^publish-approved ' "$T/ev" > .vid/metrics-events; open_ 'no publish-approved event'
if grep -q 'publish-approved' "$T/out"; then fail 'in manual the gate still names the publish-approved event'; fi
printf '\n' >> PLAN.md; shut 'PLAN.md has an uncommitted change' 'an uncommitted PLAN.md'; git checkout -q PLAN.md
printf 'A line in progress.\n' >> forms/issue.md; shut 'forms/issue.md has an uncommitted change' 'an uncommitted issue form'; git checkout -q forms/issue.md
open_ 'only the spec files changed'
exit 0
