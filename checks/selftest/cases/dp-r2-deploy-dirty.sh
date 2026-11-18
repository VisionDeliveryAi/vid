#!/bin/sh
# Purpose: selftest case — a deploy line is held only by DECISIONS.md at HEAD (0.26.10.29.5, DP-1 R2). With the words of a
# report's decision: line written in the working tree's DECISIONS.md alone, uncommitted, `record` takes the report as unread
# (no event, tried again), never as held; once the tree is as HEAD has it, the next record writes the line, n=1. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-deploy-dirty: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
git init -q --bare .vid/code; git init -q "$T/w"; echo a > "$T/w/a"; git -C "$T/w" add a; g -C "$T/w" commit -qm a; C=$(git -C "$T/w" rev-parse HEAD); git -C "$T/w" push -q "$T/v/.vid/code" HEAD:refs/heads/main
mkdir -p "$T/x/deploy-11-1"; printf 'by: DP\ncommit: %s\ndecision: the staging seed is the synthetic set | why: no customer data on staging\noutcome: passed\n' "$C" > "$T/x/deploy-11-1/report.txt"
printf '<testsuite name="deploy"><testcase name="checkout"/></testsuite>\n' > "$T/x/deploy-11-1/deploy.xml"; printf 'staging: http://127.0.0.1:47100\ndiffers: none\nseed: synthetic\n' > "$T/x/deploy-11-1/staging.txt"
for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done > "$T/x/deploy-11-1/duties.txt"   # 0.26.11.1.1 (R3, R6): read as before
git init -q "$T/x"; git -C "$T/x" add -A; g -C "$T/x" commit -qm r; git -C "$T/x" push -q -f "$T/v/.vid/code" HEAD:refs/heads/vid-results/deploy-11-1
mkdir -p .vid/decide/stage/1/1/d1; printf 'issue\t11\ncommit\t%s\n' "$C" > .vid/decide/stage/1/1/ask; printf 'issue\t11\ncommit\t%s\n' "$C" > .vid/decide/stage/1/1/d1/ask
sh checks/results.sh deploy --stage 1 > "$T/out" 2>&1 || fail 'the reader failed'
printf -- '- **D-009** the staging seed is the synthetic set | why: no customer data on staging | enforced: deploy deploy-11-1 | scope: project | origin: dev-side\n' >> DECISIONS.md
dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -q 'decisions-recorded deploy=deploy-11-1' .vid/metrics-events 2>/dev/null && fail "a line only in the working tree held the report's decision: $(grep decisions-recorded .vid/metrics-events)"
git checkout -q HEAD -- DECISIONS.md; dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC the second time"
grep -q '^- \*\*D-[0-9]*\*\* the staging seed is the synthetic set | why: no customer data on staging | enforced: deploy deploy-11-1 | scope: project | origin: dev-side$' DECISIONS.md || fail "the decision was not recorded once the tree was clean: $(grep 'enforced: deploy' DECISIONS.md)"
grep -q '^decisions-recorded deploy=deploy-11-1 n=1 at=' .vid/metrics-events || fail "the events: $(grep decisions-recorded .vid/metrics-events)"
exit 0
