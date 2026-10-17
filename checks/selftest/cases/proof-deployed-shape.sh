#!/bin/sh
# Purpose: selftest case — a deployed-shape row is proven on deployed passes (v0.9.8 spec 3.4, R4). With a harness that
# declares deployed-selector:, the orchestrator may request a deployed pass with --purpose proof (without it, a
# deployed request is a builder's or fixer's), and it publishes a .proof. deployed receipt; a journey row proven on
# inline receipts is inconclusive (shape), and on deployed ones proven. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/proof.sh"
fail() { echo "proof-deployed-shape: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
pf_repo "$T/repo"
sed 's/^\(ROW-001 | \)behavior\( | .*\)$/\1journey\2/' INVENTORY.md > i && mv i INVENTORY.md
awk '/^  completed:/ { print; print "  deployed-selector: -m deployed"; next } { print }' docker-compose.test.yml > d && mv d docker-compose.test.yml
printf '  worker:\n    image: toy:test\n    profiles: [deployed]\n' >> docker-compose.test.yml
commit_all 'a journey row, the deployed shape'
Q=$(git rev-parse HEAD); sed "s/^quoted-at: .*/quoted-at: $Q/" "$T/grader.md" > g && mv g "$T/grader.md"
FT=$(pf_fault); H=$(git rev-parse --short=12 HEAD)
if sh checks/test.sh request --type deployed --role orchestrator --rows ROW-001 --why x -- "$F" > "$T/out" 2>&1; then fail 'an ordinary deployed request was accepted from the orchestrator'; fi
sh checks/test.sh request --type deployed --role orchestrator --purpose proof --rows ROW-001 --why 'the deployed baseline' -- "$F" > "$T/out" 2>&1 || fail 'a deployed proof request was refused'
K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); VID_WAIT_MAX=60 sh checks/test.sh wait "$K" > /dev/null 2>&1 || true
ls .vid/ledger-results | grep -qE '\.proof\.deployed\.sel-[0-9]+\.run-.*\.xml$' || fail "no .proof. deployed receipt: $(ls .vid/ledger-results | tr '\n' ' ')"
pf_rcpt "$H.proof.sel-1.run-ci.xml" HEAD inline ROW-001=passed ROW-002=passed
pf_rcpt "$H.proof.sel-2.run-ri.xml" "$FT" inline ROW-001=failed ROW-002=passed
pf_proof "$H.proof.sel-1.run-ci.xml" "$H.proof.sel-2.run-ri.xml" > "$T/out"
[ "$(pf_last)" = 'result=inconclusive why=shape' ] || fail "a journey row on inline receipts: $(pf_last)"
pf_rcpt "$H.proof.deployed.sel-1.run-cd.xml" HEAD deployed ROW-001=passed ROW-002=passed
pf_rcpt "$H.proof.deployed.sel-2.run-rd.xml" "$FT" deployed ROW-001=failed ROW-002=passed
pf_proof "$H.proof.deployed.sel-1.run-cd.xml" "$H.proof.deployed.sel-2.run-rd.xml" > "$T/out"
[ "$(pf_last)" = 'result=proven why=-' ] || fail "a journey row on deployed receipts: $(pf_last)"
exit 0
