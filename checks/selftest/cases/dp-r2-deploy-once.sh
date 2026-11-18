#!/bin/sh
# Purpose: selftest case — a deploy's decision recorded once, whatever deploy states it again (0.26.10.29.5, DP-1 R2). DevAgent's
# deployer copies its standing record's decision: lines into every report, so the same words come in each: stage 1's D1 report
# deploy-11-1 (passed) holds A and B, recorded D-002 and D-003, `decisions-recorded deploy=deploy-11-1 n=2`; stage 2's deploy-12-1
# (passed, the same record) holds A and B again: no line, no commit, `n=0`; stage 3's deploy-14-1, `outcome: failed migrate`,
# not refused, holds A, B and a new C: C alone recorded, D-004, `n=1`, as a failed deploy's report is read like any other the
# reader did not refuse. 0.26.11.1.1 (R3, R6): each passed D1
# carries its seed: line and duties.txt, so it is read as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-deploy-once: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
git init -q --bare .vid/code; git init -q "$T/w"; echo a > "$T/w/a"; git -C "$T/w" add a; g -C "$T/w" commit -qm a; C=$(git -C "$T/w" rev-parse HEAD); git -C "$T/w" push -q "$T/v/.vid/code" HEAD:refs/heads/main
rep() { rm -rf "$T/x"; mkdir -p "$T/x/$1"; printf '%s\n' "$2" > "$T/x/$1/report.txt"; printf '<testsuite name="deploy"><testcase name="checkout"/></testsuite>\n' > "$T/x/$1/deploy.xml"
  printf 'staging: http://127.0.0.1:47100\ndiffers: none\nseed: synthetic\n' > "$T/x/$1/staging.txt"; for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done > "$T/x/$1/duties.txt"; git init -q "$T/x"; git -C "$T/x" add -A; g -C "$T/x" commit -qm "$1"; git -C "$T/x" push -q -f "$T/v/.vid/code" "HEAD:refs/heads/vid-results/$1"; }
ok_() { mkdir -p ".vid/decide/stage/$1/1/d1"; printf 'issue\t%s\ncommit\t%s\n' "$2" "$C" > ".vid/decide/stage/$1/1/ask"; printf 'issue\t%s\ncommit\t%s\n' "$2" "$C" > ".vid/decide/stage/$1/1/d1/ask"; }
ok_ 1 11; ok_ 2 12; ok_ 3 14
A='decision: the staging seed is the synthetic set | why: no customer data on staging'; B='decision: sessions live in the data store | why: one store | one backup'
rep deploy-11-1 "$(printf 'by: DP\ncommit: %s\n%s\n%s\noutcome: passed' "$C" "$A" "$B")"
rep deploy-12-1 "$(printf 'by: DP\ncommit: %s\n%s\n%s\noutcome: passed' "$C" "$A" "$B")"
rep deploy-14-1 "$(printf 'by: DP\ncommit: %s\n%s\n%s\ndecision: the migration runs before the start | why: the old code reads the new columns\noutcome: failed migrate\nproduct change: no' "$C" "$A" "$B")"
for s in 1 2 3; do sh checks/results.sh deploy --stage $s > "$T/out" 2>&1 || fail "the reader failed on stage $s"; grep -q '^d1	refused' "$T/out" && fail "the reader refused stage $s's report"; done
H0=$(git rev-parse HEAD); dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
[ "$(grep -c 'the staging seed is the synthetic set' DECISIONS.md)" = 1 ] && [ "$(grep -c 'sessions live in the data store' DECISIONS.md)" = 1 ] || fail "a deploy's decision was recorded twice: $(grep 'enforced: deploy' DECISIONS.md)"
grep -qxF -- '- **D-004** the migration runs before the start | why: the old code reads the new columns | enforced: deploy deploy-14-1 | scope: project | origin: dev-side' DECISIONS.md || fail "a failed, not refused, report's new line was not recorded: $(grep 'enforced: deploy' DECISIONS.md)"
grep -q '^decisions-recorded deploy=deploy-11-1 n=2 at=' .vid/metrics-events && grep -q '^decisions-recorded deploy=deploy-12-1 n=0 at=' .vid/metrics-events && grep -q '^decisions-recorded deploy=deploy-14-1 n=1 at=' .vid/metrics-events || fail "the events: $(grep decisions-recorded .vid/metrics-events)"
[ "$(git rev-list --count "$H0..HEAD")" = 2 ] || fail "not one commit for each report with a new line: $(git rev-list --count "$H0..HEAD")"
exit 0
