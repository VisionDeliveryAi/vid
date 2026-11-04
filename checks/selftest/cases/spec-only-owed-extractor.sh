#!/bin/sh
# Purpose: selftest case — a spec-only tree whose rule rows name extractors not yet written, and whose design pack draws
# markers no code cites yet, is committed (v0.26.10.9 spec R1, found by the trial: census refused every such rule row as
# promissory). The toy spec-only tree (fixtures/spec-only.sh) gains RULE-002 whose census command is an extractor path and
# one drawn marker: the spec commit passes the real hooks; census reports RULE-002 pending ("extractor owed to the
# skeleton") in pending=, design-cite reports the marker pending, not as a GAP; memory.sh alone changes nothing; once any
# extractor exists, census refuses the missing one as promissory and design-cite's GAP line returns. The spec commit also
# carries a golden set a row names (`golden:`) with no Tests-by: trailer, as the inventory court needs it there (found by
# the same trial: commit-msg refused it); another file under tests/invariants/ on the spec commit, and a golden set added
# by a later commit, still need the trailer (by=tests-by). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/spec-only.sh"
fail() { echo "spec-only-owed-extractor: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
so_tree "$T/r"
awk '/^rule \| RULE-001 /{ print; print "rule | RULE-002 | every route is guarded | checks/extractors/dead-path.routes.sh | 1 | owed: census-armed — extractor owed to the skeleton"; next } { print }' INVENTORY.md > I.t && mv I.t INVENTORY.md
printf '# toy\n\n```vid-placement\napp/\ndesign/\n```\n' > CLAUDE.md
mkdir -p design/screens; printf '<!-- @screen P01 state=default -->\n<main>the notes page</main>\n' > design/screens/P.html
awk '/^ROW-003 /{ print $0 " | golden: tests/invariants/golden/q.golden"; next } { print }' INVENTORY.md > I.t && mv I.t INVENTORY.md
sed 's/^\.py \.sh/.golden .py .sh/' BASELINE.md > B.t && mv B.t BASELINE.md
mkdir -p tests/invariants/golden; printf '# Purpose: the toy golden set\nnotes | N1 | - | -\n' > tests/invariants/golden/q.golden
printf '# Purpose: a ledger test no pass wrote\n' > tests/invariants/test_x.py
if so_commit 'the spec' > "$T/out" 2>&1; then fail 'the spec commit carried a ledger test with no Tests-by: trailer'; fi
tail -n 1 .vid/metrics-events | grep -q 'by=tests-by' || fail 'the ledger test on the spec commit was not refused by tests-by'
rm tests/invariants/test_x.py; git rm -q --cached tests/invariants/test_x.py
so_commit 'the spec' > "$T/out" 2>&1 || fail 'the spec commit was refused with a rule row whose extractor is owed, a drawn marker and a golden set'
[ "$(git log --format=%s | head -n 1)" = 'the spec' ] || fail 'the spec commit did not land'
sh checks/census.sh > "$T/out" 2>&1 || fail 'census refused a spec-only tree with no extractor'
grep -q "^PEND  RULE-002  census command 'checks/extractors/dead-path.routes.sh' — extractor owed to the skeleton" "$T/out" || fail 'census does not report RULE-002 pending'
grep -q '^census: .* pending=1 ' "$T/out" || fail 'the pending extractor is not counted in pending='
sh checks/design-cite.sh > "$T/out" 2>&1 || fail 'design-cite refused'
grep -q '^PEND marker P01/default drawn, cited by nothing yet' "$T/out" || fail 'design-cite does not report the marker pending'
if grep -q '^GAP ' "$T/out"; then fail 'design-cite still prints a GAP line while no extractor exists'; fi
printf '# Purpose: a second golden set\nnotes | N2 | - | -\n' > tests/invariants/golden/r.golden
awk '/^ROW-002 /{ print $0 " | golden: tests/invariants/golden/r.golden"; next } { print }' INVENTORY.md > I.t && mv I.t INVENTORY.md
if so_commit 'a golden set later' > "$T/out" 2>&1; then fail 'a later commit added a golden set with no Tests-by: trailer'; fi
tail -n 1 .vid/metrics-events | grep -q 'by=tests-by' || fail 'the later golden set was not refused by tests-by'
git reset -q; git checkout -q -- INVENTORY.md; rm tests/invariants/golden/r.golden
mkdir -p checks/extractors; printf '#!/bin/sh\necho "free-mb 100"\n' > checks/extractors/memory.sh
sh checks/census.sh > "$T/out" 2>&1 || fail 'memory.sh alone made census refuse'
printf '#!/bin/sh\necho "inactive no code yet"\n' > checks/extractors/dead-path.fields.sh
if sh checks/census.sh > "$T/out" 2>&1; then fail 'census accepted a missing extractor once one exists'; fi
grep -q "FAIL  RULE-002  census command 'checks/extractors/dead-path.routes.sh' does not exist — promissory" "$T/out" || fail 'census does not name RULE-002 as promissory once an extractor exists'
sh checks/design-cite.sh > "$T/out" 2>&1 || true
grep -q '^GAP  marker P01/default drawn but cited by no rule or template' "$T/out" || fail 'the GAP line does not return once an extractor exists'
exit 0
