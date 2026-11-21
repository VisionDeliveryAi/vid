#!/bin/sh
# Purpose: selftest case — GitHub manual's pending changes (GM-1 S3). On the planner's toy in GitHub manual, its spec
# committed and that commit recorded as the applied version, then, after it: ROW-001's obligation restated, ROW-021
# added, REQ-011's fail-if changed (reaching ROW-018, which derives from it) and ROW-019 removed. `next.sh pending`
# prints exactly one line each: reset ROW-001, added ROW-021, reached ROW-018 and retired ROW-019, as
# `inventory.sh impact --base <applied> --tickets` sorts the first three; and (GM-3 U1, lane A's review) `spec PRD.md 2 lines`,
# REQ-011's changed line, since a PRD change shows among the spec lines too. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "manual-pending: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw; git rev-parse HEAD > .vid/tw/applied
sed 's/^\(ROW-001 .*\)holding only jobs it has not sent before\./\1holding only jobs it has not sent before, newest first./' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
pt_after ROW-020 'ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day, or a day no digest went out. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
sed 's/fail-if: a day of failed sends leaves no operator-visible trace/fail-if: a day of failed sends leaves no operator-visible trace within the hour/' PRD.md > "$T/p" && cat "$T/p" > PRD.md
pt_del ROW-019
grep -q 'newest first' INVENTORY.md && grep -q '^ROW-021 ' INVENTORY.md && ! grep -q '^ROW-019 ' INVENTORY.md && grep -q 'within the hour' PRD.md || fail 'the changes did not land'
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || fail 'next.sh pending failed'
printf 'pending\tadded\tROW-021\npending\treached\tROW-018\npending\treset\tROW-001\npending\tretired\tROW-019\nspec\tPRD.md\t2 lines\n' > "$T/want"
sort "$T/out" | cmp -s - "$T/want" || fail "the pending changes are not one each of reset ROW-001, added ROW-021, reached ROW-018 and retired ROW-019, then spec PRD.md 2 lines"
exit 0
