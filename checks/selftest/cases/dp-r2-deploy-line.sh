#!/bin/sh
# Purpose: selftest case — a deploy's decisions recorded from its report (0.26.10.29.5, DP-1 R2). Stage 1's D1 okay #11 has a passed
# report, deploy-11-1, whose report.txt holds two `decision: <what> | why: <why>` lines; stage 2's okay #12 a passed one,
# deploy-12-1, holding `decisions: none`. After the reader (`results.sh deploy`) reads both, `decisions.sh record` appends deploy-11-1's
# two lines, each `| enforced: deploy deploy-11-1 | scope: project | origin: dev-side`, in one commit of DECISIONS.md alone, and
# records `decisions-recorded deploy=deploy-11-1 n=2` and `decisions-recorded deploy=deploy-12-1 n=none`. Run again: nothing is
# recorded twice. Where devagent/ is there: DevAgent's deployer writes the record's `decision:` lines into report.txt, or
# `decisions: none` when it has none. 0.26.11.1.1 (R3, R6): each hand-built passed D1 carries its seed: line and duties.txt,
# so it is read as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-deploy-line: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
git init -q --bare .vid/code; git init -q "$T/w"; echo a > "$T/w/a"; git -C "$T/w" add a; g -C "$T/w" commit -qm a; C=$(git -C "$T/w" rev-parse HEAD); git -C "$T/w" push -q "$T/v/.vid/code" HEAD:refs/heads/main
rep() { rm -rf "$T/x"; mkdir -p "$T/x/$1"; printf '%s\n' "$2" > "$T/x/$1/report.txt"; printf '<testsuite name="deploy"><testcase name="checkout"/></testsuite>\n' > "$T/x/$1/deploy.xml"
  printf 'staging: http://127.0.0.1:47100\ndiffers: none\nseed: synthetic\n' > "$T/x/$1/staging.txt"; for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done > "$T/x/$1/duties.txt"; git init -q "$T/x"; git -C "$T/x" add -A; g -C "$T/x" commit -qm "$1"; git -C "$T/x" push -q -f "$T/v/.vid/code" "HEAD:refs/heads/vid-results/$1"; }
ok_() { mkdir -p ".vid/decide/stage/$1/1/d1"; printf 'issue\t%s\ncommit\t%s\n' "$2" "$C" > ".vid/decide/stage/$1/1/ask"; printf 'issue\t%s\ncommit\t%s\n' "$2" "$C" > ".vid/decide/stage/$1/1/d1/ask"; }
ok_ 1 11; ok_ 2 12
rep deploy-11-1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecision: the staging seed is the synthetic set | why: no customer data on staging\ndecision: sessions live in the data store | why: one store | one backup' "$C")"
rep deploy-12-1 "$(printf 'by: DP\ncommit: %s\noutcome: passed\ndecisions: none' "$C")"
sh checks/results.sh deploy --stage 1 > "$T/out" 2>&1 || fail 'the reader failed on deploy-11-1'; grep -q '^d1	passed	1$' "$T/out" || fail "deploy-11-1 was not read passed: $(cat "$T/out")"
sh checks/results.sh deploy --stage 2 > "$T/out" 2>&1 || fail 'the reader failed on deploy-12-1'; grep -q '^d1	passed	1$' "$T/out" || fail "deploy-12-1 was not read passed: $(cat "$T/out")"
H0=$(git rev-parse HEAD); dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
grep -qxF -- '- **D-002** the staging seed is the synthetic set | why: no customer data on staging | enforced: deploy deploy-11-1 | scope: project | origin: dev-side' DECISIONS.md || fail "the first deploy line is not recorded as it should be: $(grep D-002 DECISIONS.md || echo none)"
grep -qxF -- '- **D-003** sessions live in the data store | why: one store / one backup | enforced: deploy deploy-11-1 | scope: project | origin: dev-side' DECISIONS.md || fail "the second deploy line is not recorded as it should be: $(grep D-003 DECISIONS.md || echo none)"
[ "$(git rev-list --count "$H0..HEAD")" = 1 ] && [ "$(git diff --name-only "$H0" HEAD)" = DECISIONS.md ] || fail 'not one commit of DECISIONS.md alone'
grep -q '^decisions-recorded deploy=deploy-11-1 n=2 at=' .vid/metrics-events || fail 'no event decisions-recorded deploy=deploy-11-1 n=2'
grep -q '^decisions-recorded deploy=deploy-12-1 n=none at=' .vid/metrics-events || fail 'no event decisions-recorded deploy=deploy-12-1 n=none'
H1=$(git rev-parse HEAD); dpr_rec; [ "$RC" = 0 ] || fail "a second record exited $RC"
[ "$(git rev-parse HEAD)" = "$H1" ] && [ "$(grep -c 'enforced: deploy ' DECISIONS.md)" = 2 ] || fail 'a deploy line was recorded twice'
[ "$(grep -c '^decisions-recorded deploy=' .vid/metrics-events)" = 2 ] || fail 'a deploy report was recorded again'
# DevAgent's deployer: the record's decision: lines in report.txt, or decisions: none (the labelled plant, which deploys nothing)
DP=$CHECKS/../devagent/deployer/deploy.sh; [ -f "$DP" ] || exit 0
cd "$T"; . "$CHECKS/selftest/fixtures/devagent-project.sh"; sp_project; S=$T/work/dev-setup.txt; grep -q '^repo:' "$S" || printf 'repo: %s\n' "$T/origin.git" >> "$S"
SC=$(git --git-dir="$T/origin.git" rev-parse main); printf 'decision: the staging seed is the synthetic set | why: no customer data\n' >> "$S"
RC=0; sh "$DP" deploy --setup "$S" --ask deploy-5 --commit "$SC" --fail-step migrate --product-change no > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the deployer's plant exited $RC"
git --git-dir="$T/origin.git" show refs/heads/vid-results/deploy-5-1:deploy-5-1/report.txt > "$T/rp" || fail 'no report pushed'
grep -qx 'decision: the staging seed is the synthetic set | why: no customer data' "$T/rp" || fail "the deployer did not write the record's decision: line: $(cat "$T/rp")"
grep -q '^decisions: none' "$T/rp" && fail 'decisions: none beside a decision: line'
grep -v '^decision:' "$S" > "$T/s2"; cat "$T/s2" > "$S"
RC=0; sh "$DP" deploy --setup "$S" --ask deploy-5 --commit "$SC" --fail-step migrate --product-change no > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the deployer's second plant exited $RC"
git --git-dir="$T/origin.git" show refs/heads/vid-results/deploy-5-2:deploy-5-2/report.txt > "$T/rp" || fail 'no second report pushed'
grep -qx 'decisions: none' "$T/rp" || fail "a report with no decision: line lacks decisions: none: $(cat "$T/rp")"
exit 0
