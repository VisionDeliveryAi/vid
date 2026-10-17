#!/bin/sh
# Purpose: §7 case 12's real-container half (v0.9.3 3.3) — run by the builder
# where a container engine is up, never by the suite. The toy harness in
# tree/ (a product image built from the export, a worker process on the same
# image in the deployed profile, named volumes for the inbox, the transport
# and the store) is committed into a scratch repository and run through the
# plugin's checks/test.sh: (1) wired — pass 1 inline writes a sentinel into the
# store and the transport; pass 2, a fresh stack in the profile, finds neither,
# and the (process) row is green in both; (2) the consumer absent — the same
# product with no process declared: the (process) row is green inline and RED
# in the deployed report, and the readers take the deployed report as its
# receipt. Prints the reports and the readers' lines. Usage: sh run-real.sh
set -eu
F=$(cd "$(dirname "$0")" && pwd)
CHECKS=${CHECKS:-$(cd "$F/../../.." && pwd)}
T=$(mktemp -d); RD=$(mktemp -d); export XDG_RUNTIME_DIR="$RD"
cd "$T"; git init -q; cp -R "$F/tree/." .
cp "$CHECKS/test.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '.vid/\n' > .gitignore
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm 'toy, wired'
echo '=== (1) wired: the worker declared'
sh checks/test.sh --role close || true
for r in .vid/ledger-results/*.xml; do echo "--- $r"; cat "$r"; done
sh checks/metrics.sh 2>/dev/null | sed -n 2p
sh checks/metrics.sh row-state ROW-P01 ROW-S01 2>/dev/null
grep '^ledger-run' .vid/metrics-events
echo '=== (2) the consumer absent: no process declared'
sed -e 's/^  processes: \[worker\]$/  processes: []/' -e '/^  worker:$/,/^    volumes: \[transport:\/transport, db:\/db\]$/d' docker-compose.test.yml > c && mv c docker-compose.test.yml
git -c user.email=vid@selftest -c user.name=vid commit -qam 'toy, no consumer'
rm -f .vid/ledger-results/*.xml
sh checks/test.sh --role close || true
for r in .vid/ledger-results/*.xml; do echo "--- $r"; cat "$r"; done
sh checks/metrics.sh 2>/dev/null | sed -n 2p
sh checks/metrics.sh row-state ROW-P01 2>/dev/null
cd /; rm -rf "$T" "$RD"
