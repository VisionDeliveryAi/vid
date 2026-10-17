#!/bin/sh
# Purpose: selftest case — the census's extractors side by side give the
# serial run's bytes (v0.9.6 spec 3.14, R14; §7 case 3). Twelve stub
# extractors — sleeps that finish out of order, orphans, standard-error
# lines, a silent-empty one, an `inactive` one, one non-zero exit — and rule
# rows citing extractors (one a state-machine row refused before its
# extractor runs, one citing a missing extractor, one a plain enumeration):
# standard output, standard error and the exit status are byte-identical
# between VID_COURT_JOBS=1 (the serial run) and 4, 8 and the default. Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p checks/extractors
x() { printf '#!/bin/sh\n# Purpose: stub extractor\n%s\n' "$2" > "checks/extractors/$1.sh"; }
x dead-path.a   'sleep 2; echo "ok a1"; echo "orphan a2 unreachable"'
x dead-path.b   'echo "ok b1"; echo "ok b2"'
x invariant.c   'sleep 1; echo "orphan c1 unguarded"; echo "population 3"'
x invariant.d   'echo "d says this on stderr" >&2; echo "ok d1"'
x invariant.e   ':'
x invariant.f   'echo "inactive no substrate here"'
x invariant.g   'echo "ok g1"; exit 3'
x invariant.h   'sleep 1; echo "ok h1"'
x vacuity.i     'echo "orphan i1 asserts-nothing"'
x rendered.j    'echo "orphan j1 cited=a computed=b"'
x strength.k    'echo "ok k1"; echo "orphan k2 existence-only"'
x state-machine.status 'echo "site1 new>open"; echo "site2 open>shut"; echo "site3 open"'
printf '```vid-inventory\nrule | RULE-001 | every c is guarded | checks/extractors/invariant.c.sh | 0 | tests/invariants/t.py\nrule | RULE-002 | state-machine status: new>open open>closed | checks/extractors/state-machine.status.sh | 0 | tests/invariants/t.py\nrule | RULE-003 | state-machine status | checks/extractors/state-machine.status.sh | 0 | tests/invariants/t.py\nrule | RULE-004 | missing | checks/extractors/invariant.nope.sh | 0 | tests/invariants/t.py\nrule | RULE-005 | plain | printf "s1\\\\ns2\\\\n" | 0 | tests/invariants/t.py\nrule | RULE-006 | the h rule | checks/extractors/invariant.h.sh | 0 | owed: later\n```\n' > INVENTORY.md
run() { ST=0; VID_COURT_JOBS=$1 sh "$CHECKS/census.sh" > "$T/$2.out" 2> "$T/$2.err" || ST=$?; echo "$ST" > "$T/$2.st"; }
run 1 serial
[ "$(cat "$T/serial.st")" = 1 ] || { echo 'census-parallel: the fixture did not fail the serial census' >&2; exit 1; }
grep -q 'extractor exited 3' "$T/serial.err" && grep -q 'silent-empty' "$T/serial.err" && grep -q 'census RULE-002' "$T/serial.out" || { echo 'census-parallel: the fixture lost a shape' >&2; cat "$T/serial.out" "$T/serial.err" >&2; exit 1; }
for n in 4 8 ''; do
  run "$n" "p$n"
  for f in out err st; do
    cmp -s "$T/serial.$f" "$T/p$n.$f" || { echo "census-parallel: VID_COURT_JOBS=${n:-default} differs from the serial run on std$f" >&2; diff "$T/serial.$f" "$T/p$n.$f" >&2 || true; exit 1; }
  done
done
exit 0
