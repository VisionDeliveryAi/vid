#!/bin/sh
# Purpose: selftest case — the one ordinary-receipt rule in checks/plan.sh's red stamps (v0.9.8 spec 3.4, R15).
# Inside a develop run, a newly staged `proved-red:` stamp whose `red-observed` event names a proof receipt (its name
# carries .proof.; published, present, the case failed on its check) is refused by the pre-commit hook as a proof
# receipt; the control — the same failed case on an ordinary receipt — passes. Env: CHECKS.
set -eu
T=$(mktemp -d); O=$(mktemp -d); trap 'set +e; rm -rf "$T" "$O" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "proof-receipt-ineligible-plan: $*" >&2; cat "$O/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; commit_all rows
mkdir -p checks/hooks; cp "$CHECKS/hooks/pre-commit" checks/hooks/
for c in placement conformance; do printf '#!/bin/sh\n# Purpose: stub court\nexit 0\n' > "checks/$c.sh"; done
printf '# stub lawfiles\n' > checks/lawfiles
commit_all 'the hook and stub courts'
H=$(git rev-parse --short=12 HEAD); P="$H.proof.sel-5.run-p.xml"
rcpt "$P" HEAD inline ROW-001=failed
rcpt "$H.live.sel-5.run-o.xml" HEAD inline ROW-001=failed
sed "s/^\\(ROW-001 | .*\\)\$/\\1 | proved-red: $H/" INVENTORY.md > x && mv x INVENTORY.md; g add INVENTORY.md
hook() { rm -rf "$(git rev-parse --git-path vid-memo)"; if sh checks/hooks/pre-commit > "$O/out" 2>&1; then echo pass; else echo refused; fi; }
sh checks/event.sh "red-observed row=ROW-001 report=$P case=tests/invariants/test_s1.py::test_001[ROW-001] assertion=\"the total is 12\""
[ "$(hook)" = refused ] || fail 'a stamp observed red on a proof receipt passed'
grep -q 'is a proof receipt' "$O/out" || fail 'the refusal does not say proof receipt'
sh checks/event.sh "red-observed row=ROW-001 report=$H.live.sel-5.run-o.xml case=tests/invariants/test_s1.py::test_001[ROW-001] assertion=\"the total is 12\""
[ "$(hook)" = pass ] || fail 'the control: a stamp observed red on an ordinary receipt was refused'
exit 0
