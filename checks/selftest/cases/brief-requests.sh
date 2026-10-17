#!/bin/sh
# Purpose: selftest case — a brief's section 6 lists test requests
# (v0.9.7.0.2 spec 3.6, R11; §6 D-1; replaces brief-run-role.sh). In every
# role's brief, a `## 6` line running checks/test.sh directly — `sh
# checks/test.sh -- x`, or with a role — is refused by the brief check,
# naming the line; `sh checks/test.sh request …` and `sh checks/test.sh
# wait <ticket>` pass. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "brief-requests: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
plan 'step S1 | name: base | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
n=0
for spec in 'builder S1' 'fixer S1' 'test-author -' 'grader -'; do
  ro=${spec% *}; st=${spec#* }; n=$((n + 1))
  if [ "$ro" = grader ]; then   # the fixture's test-author brief carries the independence paragraph a grader's needs
    brief "$T/g.md" test-author - ROW-001
    { sed 's/^role: test-author/role: grader/' "$T/g.md"; printf '\nDo not read under `.vid/` beyond the receipt named above.\n'; } > ".vid/briefs/1/$ro-$n.md"
  else brief ".vid/briefs/1/$ro-$n.md" "$ro" "$st" ROW-001; fi
  grep -q '^sh checks/test.sh request --type ' ".vid/briefs/1/$ro-$n.md" && grep -qx 'sh checks/test.sh wait <ticket>' ".vid/briefs/1/$ro-$n.md" || fail "the fixture's $ro brief does not list a request and a wait"
  sh checks/brief.sh ".vid/briefs/1/$ro-$n.md" > "$T/out" 2>&1 || fail "a $ro brief with a request and a wait was refused"
  for direct in 'sh checks/test.sh -- x' "sh checks/test.sh --role $ro -- tests/invariants"; do
    awk -v d="$direct" '{ print } /^## 6/ { print ""; print d }' ".vid/briefs/1/$ro-$n.md" > ".vid/briefs/1/$ro-$n-x.md"
    if sh checks/brief.sh ".vid/briefs/1/$ro-$n-x.md" > "$T/out" 2>&1; then fail "a $ro brief running '$direct' was accepted"; fi
    grep -qF 'section 6 runs checks/test.sh directly' "$T/out" && grep -qF -- "$direct" "$T/out" || fail "the $ro refusal does not name the line '$direct'"
  done
done
exit 0
