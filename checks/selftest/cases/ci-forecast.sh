#!/bin/sh
# Purpose: selftest case — the CI minutes forecast (v0.26.10.12 spec R7, R9). The planner's toy (fixtures/tickets.sh
# gh_vid: steps A and B in stage 1, C in stage 2). With no CI run imported, `ticket.sh forecast --stage 1` reads
# `scoped unknown min × 2 tickets + full unknown min × 1 runs ≈ unknown min (unknown until the skeleton's first run)`,
# and `plan-md` puts each stage's line on the plan page and prints it. Measured: two pull-request receipts (60 s and
# 120 s of cases) and one of main (pr=-, 600 s), a fix ticket of step A and two run-full started events in the current
# stage give `scoped 1.5 min × 3 tickets + full 10.0 min × 2 runs ≈ 24.5 min (measured: …)`; stage 2 keeps 1 full run.
# vid-replan names the forecast (in the plugin repository). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "ci-forecast: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
sh checks/ticket.sh forecast --stage 1 > "$T/out" 2>&1 || fail 'forecast failed'
grep -qx "ci-minutes forecast stage=1: scoped unknown min × 2 tickets + full unknown min × 1 runs ≈ unknown min (unknown until the skeleton's first run)" "$T/out" || fail 'the unknown forecast is wrong'
sh checks/ticket.sh plan-md > "$T/out" 2>&1 || fail 'plan-md failed'
grep -q '^ci-minutes forecast stage=1: ' .vid/tickets/PLAN.md && grep -q '^ci-minutes forecast stage=2: scoped unknown min × 1 tickets' .vid/tickets/PLAN.md || fail 'the plan page lacks a stage'"'"'s forecast'
grep -q '^ci-minutes forecast stage=2: ' "$T/out" || fail 'plan-md does not print the forecast'
# measured
mkdir -p .vid/ledger-results
rc() { _n=$1; shift; : > ".vid/ledger-results/$_n.cases"; for _s in "$@"; do printf 'case tests/x.py::t%s passed %s\n' "$_s" "$_s" >> ".vid/ledger-results/$_n.cases"; done; }
rc aaa.ci-1-1.xml 20 40; rc bbb.ci-2-1.xml 120; rc ccc.ci-3-1.xml 600
for l in 'aaa.ci-1-1.xml run=1 pr=5' 'bbb.ci-2-1.xml run=2 pr=6' 'ccc.ci-3-1.xml run=3 pr=-'; do set -- $(printf '%s' "$l" | tr ' ' '\n'); printf 'ledger-run type=ci report=%s repo=owner/code workflow=CI %s attempt=1 commit=abc %s status=0 at=2026-10-25T00:00:00Z\n' "$1" "$2" "$3" >> .vid/metrics-events; done
printf 'ticket number=40 step=A kind=fix brief=x parts=1 hash=x\n' >> .vid/tickets/map 2>/dev/null || { mkdir -p .vid/tickets; printf 'ticket number=40 step=A kind=fix brief=x parts=1 hash=x\n' > .vid/tickets/map; }
printf 'run-full started run=901 attempt=1 sha=abc at=x\nrun-full started run=902 attempt=1 sha=abd at=x\n' >> .vid/metrics-events
sh checks/ticket.sh forecast > "$T/out" 2>&1 || fail 'forecast failed'
grep -qx 'ci-minutes forecast stage=1: scoped 1.5 min × 3 tickets + full 10.0 min × 2 runs ≈ 24.5 min (measured: the mean test time in the reports of 2 pull-request and 1 full runs)' "$T/out" || fail 'the measured forecast is wrong'
grep -qx 'ci-minutes forecast stage=2: scoped 1.5 min × 1 tickets + full 10.0 min × 1 runs ≈ 11.5 min (measured: the mean test time in the reports of 2 pull-request and 1 full runs)' "$T/out" || fail "stage 2's forecast is wrong"
# the skill — only in the plugin repository (a project has checks/ alone); vid-plan no longer names it (0.26.10.12.2)
[ -d "$CHECKS/../skills/vid-replan" ] || exit 0
R=$(tr '\n' ' ' < "$CHECKS/../skills/vid-replan/SKILL.md" | tr -s ' ')
printf '%s' "$R" | grep -qF 'ci-minutes forecast' || fail 'vid-replan does not name the forecast'
exit 0
