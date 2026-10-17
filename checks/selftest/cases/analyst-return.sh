#!/bin/sh
# Purpose: selftest case — the test analyst's return format can be checked
# (v0.9.7.0.3 spec 3.3, R4; §6 B-2). A small checker (below) accepts a
# fixture return for each outcome — setup, hang, limit, none — and refuses
# one carrying an extra line kind, one whose `limit:` line lacks its
# `paying-step:`, one with a line its outcome does not need, and one over
# 20 lines. v0.9.7.0.11 (3.12, R12): a limit with `prod: n/a` (a setting
# only the test has) carries `paying-step: none` and `question: none` and
# is accepted; `question: none` with a production value is refused, and so
# is a question with `prod: n/a`. The format is the one skills/vid-test-manager/passes/test-analyst.md
# states (checks/selftest/cases/passes.sh pins it word for word). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "analyst-return: $*" >&2; exit 1; }
# check <file>: exit 0 when the return parses, else 1 naming the line
check() {
  awk 'function no(m) { print "line " NR ": " m; bad = 1 }
    NR == 1 { if ($0 !~ /^analyst request=[^ ]+ reason=(cap|setup|slow) outcome=(setup|hang|limit|none)$/) no("not the analyst line"); o = $0; sub(/.*outcome=/, "", o); next }
    NR == 2 { if ($0 !~ /^finding: ./) no("not the finding line"); next }
    /^setup-cause: / { n = split(substr($0, 14), f, / \| /); if (n != 4 || f[2] !~ /^cases=[0-9]+$/ || f[3] !~ /^cause: ./ || f[4] !~ /^repair: ./) no("a setup-cause line out of form"); k["setup"]++; next }
    /^hang-cause: / { n = split(substr($0, 13), f, / \| /); if (n != 2 || f[2] !~ /^action: (incident|harness fix|owner question)$/) no("a hang-cause line out of form"); k["hang"]++; next }
    /^limit: / { n = split(substr($0, 8), f, / \| /)
      if (n != 8 || f[1] !~ /^ROW-[0-9A-Za-z-]+$/ || f[2] !~ /^cases: ./ || f[3] !~ /^setting: ./ || f[4] !~ /^test: ./ || f[5] !~ /^prod: ./ || f[6] !~ /^holds-because: ./ || f[7] !~ /^paying-step: ./ || f[8] !~ /^question: (".+"|none)$/) no("a limit line out of form")
      else if ((f[5] == "prod: n/a") != (f[8] == "question: none") || (f[5] == "prod: n/a") != (f[7] == "paying-step: none")) no("a test-only limit (prod: n/a) carries no paying step and no question, and only it")
      k["limit"]++; next }
    { no("a line kind the format does not have") }
    END { if (NR < 2) no("no finding line"); if (NR > 20) no("more than 20 lines")
      for (x in k) if (x != o) no("a " x " line in an outcome=" o " return")
      if (o != "none" && !(o in k)) no("outcome=" o " without its lines")
      exit bad }' "$1"
}
R='analyst request=20261002T101500Z-ab12'
printf '%s reason=setup outcome=setup\nfinding: five red cases wait on one missing prerequisite\nsetup-cause: no email reached the spare host within 60 s | cases=5 | cause: the harness starts no mail sink (tests/invariants/harness.py:41) | repair: start the mail sink the cases expect before the suite\n' "$R" > "$T/setup"
printf '%s reason=cap outcome=hang\nfinding: the run stopped at its cap while an image was still downloading\nhang-cause: the image download had no timeout (log line 182) | action: harness fix\n' "$R" > "$T/hang"
printf '%s reason=slow outcome=limit\nfinding: one case replays the production fetch timeout with its retries\nlimit: ROW-256 | cases: tests/invariants/test_fetch.py::test_timeout | setting: FETCH_TIMEOUT_SECONDS | test: 2 | prod: 60 | holds-because: the row promises a retry after a timeout, not its length | paying-step: staging — the fetch runs against the real host | question: "May tests wait 2 seconds for a fetch instead of 60?"\n' "$R" > "$T/limit"
printf '%s reason=slow outcome=none\nfinding: cause: not found — needs the product log of the slow case, which the run did not keep\n' "$R" > "$T/none"
for o in setup hang limit none; do check "$T/$o" > "$T/out" || { cat "$T/out" >&2; fail "the $o return was refused"; }; done
{ cat "$T/limit"; printf 'note: also consider a faster disk\n'; } > "$T/extra"
check "$T/extra" > "$T/out" && fail 'a return with an extra line kind was accepted'
grep -q 'a line kind the format does not have' "$T/out" || fail 'the extra line kind is not named'
sed 's/ | paying-step: [^|]*//' "$T/limit" > "$T/nopay"
check "$T/nopay" > "$T/out" && fail 'a limit line without its paying-step was accepted'
grep -q 'a limit line out of form' "$T/out" || fail 'the missing paying-step is not named'
{ cat "$T/setup"; sed -n 3p "$T/hang"; } > "$T/mixed"
check "$T/mixed" > "$T/out" && fail 'a hang-cause line in a setup return was accepted'
{ cat "$T/setup"; i=0; while [ "$i" -lt 18 ]; do sed -n 3p "$T/setup"; i=$((i + 1)); done; } > "$T/long"
check "$T/long" > "$T/out" && fail 'a return of 21 lines was accepted'
# v0.9.7.0.11 (R12): a test-only limit
printf '%s reason=slow outcome=limit\nfinding: the case polls its own fake every 30 s\nlimit: ROW-257 | cases: tests/invariants/test_poll.py::test_wait | setting: the test'"'"'s POLL_SECONDS | test: 1 | prod: n/a | holds-because: nothing the product reads changes | paying-step: none | question: none\n' "$R" > "$T/na"
check "$T/na" > "$T/out" || { cat "$T/out" >&2; fail 'a test-only limit was refused'; }
sed 's/ | question: none$/ | question: "May the test poll every second?"/' "$T/na" > "$T/naq"
check "$T/naq" > "$T/out" && fail 'a test-only limit with an owner question was accepted'
sed 's/ | question: "[^"]*"$/ | question: none/' "$T/limit" > "$T/noq"
check "$T/noq" > "$T/out" && fail 'a limit with a production value and no question was accepted'
grep -q 'a test-only limit (prod: n/a)' "$T/out" || fail 'the missing question is not named'
exit 0
