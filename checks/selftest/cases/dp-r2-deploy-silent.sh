#!/bin/sh
# Purpose: selftest case — a deploy report that states nothing is refused (0.26.10.29.5, DP-1 R2). Stage 1's D1 okay #11 has a
# passed report, deploy-11-1, whose report.txt holds no `decision:` line and no `decisions: none`: the reader (`results.sh deploy`)
# refuses it as it refuses a rehearsal with no drops: line, `d1 refused 1 report.txt has no decision: line, nor decisions: none`,
# whatever its outcome; a failed rehearsal's report the same. `decisions.sh record` reads neither: no line, no commit, no event.
# 0.26.11.1.1 (R3, R6): each passed D1 carries its seed: line and duties.txt, so it is read as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/dp-record.sh"
fail() { echo "dp-r2-deploy-silent: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
git init -q --bare .vid/code; git init -q "$T/w"; echo a > "$T/w/a"; git -C "$T/w" add a; g -C "$T/w" commit -qm a; C=$(git -C "$T/w" rev-parse HEAD); git -C "$T/w" push -q "$T/v/.vid/code" HEAD:refs/heads/main
rep() { rm -rf "$T/x"; mkdir -p "$T/x/$1"; printf '%s\n' "$2" > "$T/x/$1/report.txt"; printf '<testsuite name="deploy"><testcase name="checkout"/></testsuite>\n' > "$T/x/$1/deploy.xml"
  printf 'staging: http://127.0.0.1:47100\ndiffers: none\nseed: synthetic\n' > "$T/x/$1/staging.txt"; for d in log-in environments outside-services sending-domain deploy-notes captures; do printf '%s: done — on the host\n' "$d"; done > "$T/x/$1/duties.txt"; printf 'migrates: no\ndrops: none\nservices: none\n' > "$T/x/$1/change.txt"; git init -q "$T/x"; git -C "$T/x" add -A; g -C "$T/x" commit -qm "$1"; git -C "$T/x" push -q -f "$T/v/.vid/code" "HEAD:refs/heads/vid-results/$1"; }
mkdir -p .vid/decide/stage/1/1/d1 .vid/decide/stage/1/1/rh; printf 'issue\t11\ncommit\t%s\n' "$C" > .vid/decide/stage/1/1/ask; printf 'issue\t11\ncommit\t%s\n' "$C" > .vid/decide/stage/1/1/d1/ask; printf 'issue\t13\ncommit\t%s\n' "$C" > .vid/decide/stage/1/1/rh/ask
rep deploy-11-1 "$(printf 'by: DP\ncommit: %s\noutcome: passed' "$C")"
rep deploy-13-1 "$(printf 'by: DP\ncommit: %s\noutcome: failed migrate\nproduct change: no' "$C")"
sh checks/results.sh deploy --stage 1 > "$T/out" 2>&1 || fail 'the reader failed'
grep -qx 'd1	refused	1	report.txt has no decision: line, nor decisions: none' "$T/out" || fail "a D1 report stating no decisions was not refused: $(cat "$T/out")"
sh checks/results.sh deploy --stage 1 --kind rh --candidate 1 > "$T/out" 2>&1 || fail 'the reader failed on the rehearsal'
grep -qx 'rh	refused	1	report.txt has no decision: line, nor decisions: none' "$T/out" || fail "a failed rehearsal's report stating no decisions was not refused: $(cat "$T/out")"
H0=$(git rev-parse HEAD); cp DECISIONS.md "$T/d0"; dpr_rec; [ "$RC" = 0 ] || fail "record exited $RC"
[ "$(git rev-parse HEAD)" = "$H0" ] && cmp -s DECISIONS.md "$T/d0" || fail 'a refused deploy report was recorded'
grep -q '^decisions-recorded ' .vid/metrics-events 2>/dev/null && fail 'an event for a refused deploy report'
exit 0
