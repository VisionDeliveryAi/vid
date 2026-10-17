#!/bin/sh
# Purpose: selftest case — the rows headline and the slice claim (v0.9.2 spec
# 3.6, 3.8; R9, R10; §7.9b). A toy repository under the 0.9.2 inventory
# grammar with a fixture results reader, two export-backed reports (slice
# start, slice close = HEAD) and per-row verdict events. Headline: a passed
# row with no verdict is `unverdicted`, never `kept`; a reverted row's
# earlier KEPT is invalidated; KEPT then a later BREACHED counts `breached`;
# a row whose only case is skipped counts `red`; a standalone fix's row with
# an export-backed pass and a KEPT re-grade counts `kept` with no develop
# slice; a journey is kept only when every transition's latest is KEPT;
# without an export-backed receipt for HEAD the line prints `receipt: none`
# and no kept count. Claim --from --to: a mid-slice birth (absent at start,
# passed at close), an unchanged row error→passed, a kept row that regressed
# and passes again, a re-paid reverted row, a breached-and-passing row are
# in the claim; a kept row passing at both ends and a skipped row are not;
# a .live. report is refused as --to. Per-class seconds are read from the
# report the last ledger-run event names. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks/extractors tests/invariants app .vid/ledger-results
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
cat > INVENTORY.md <<'INV'
# toy
```vid-inventory
grammar: 0.9.2
ROW-K | surface | / | anonymous | P01/default | kept and green | REQ-001 | tests/invariants/test_surfaces.py
ROW-X | behavior | REQ-001 | n/a | n/a | a mid-slice birth | REQ-001 | tests/invariants/test_req001.py
ROW-W | behavior | REQ-001 | n/a | n/a | error at start, passed at close | REQ-001 | tests/invariants/test_req001.py
ROW-V | behavior | REQ-001 | n/a | n/a | kept, regressed, repaired | REQ-001 | tests/invariants/test_req001.py
ROW-F | behavior | REQ-002 | n/a | n/a | materialised by a standalone fix | REQ-002 | tests/invariants/test_fix.py
ROW-Y | behavior | REQ-002 | n/a | n/a | reverted last slice, re-paid | REQ-002 | tests/invariants/test_req002.py
ROW-Z | behavior | REQ-002 | n/a | n/a | kept then breached, still passing | REQ-002 | tests/invariants/test_req002.py
ROW-S | behavior | REQ-002 | n/a | n/a | its only case is skipped | REQ-002 | tests/invariants/test_req002.py
ROW-J | journey | apply | candidate | n/a | four transitions | REQ-003 | tests/invariants/test_journeys.py
ROW-O | behavior | REQ-003 | n/a | n/a | owed | REQ-003 | owed: prerequisite — a capture; paid at slice 3
ROW-D | behavior | REQ-003 | n/a | n/a | the deployed worker | REQ-003 | owed: paid by /vid deploy gate 2 — the worker consumes the schedule
```
INV
printf '# Purpose: toy\n' > app/main.py
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
SHA=$(git rev-parse --short=12 HEAD)
report() { printf '<report>\n%s</report>\n' "$1" > "$2"; }
C() { printf '<case name="tests/invariants/%s" status="%s" time="%s"/>\n' "$1" "$2" "$3"; }
# slice start (another tree) and slice close (HEAD)
report "$(C 'test_surfaces.py::test_surface[ROW-K-engine-a]' passed 2.5; C 'test_surfaces.py::test_surface[ROW-K-engine-b]' passed 2.0; C 'test_req001.py::test_w[ROW-W]' error 0.1; C 'test_req001.py::test_v[ROW-V]' failed 0.4; C 'test_req002.py::test_y[ROW-Y]' passed 0.3; C 'test_req002.py::test_z[ROW-Z]' passed 0.3; C 'test_req002.py::test_s[ROW-S]' skipped 0.0; C 'test_journeys.py::test_apply[ROW-J]' passed 10.5)" .vid/ledger-results/aaaaaaaaaaaa.full.xml
report "$(C 'test_surfaces.py::test_surface[ROW-K-engine-a]' passed 2.5; C 'test_surfaces.py::test_surface[ROW-K-engine-b]' passed 2.0; C 'test_req001.py::test_x[ROW-X]' passed 0.2; C 'test_req001.py::test_w[ROW-W]' passed 0.1; C 'test_req001.py::test_v[ROW-V]' passed 0.4; C 'test_fix.py::test_f[ROW-F]' passed 0.2; C 'test_req002.py::test_y[ROW-Y]' passed 0.3; C 'test_req002.py::test_z[ROW-Z]' passed 0.3; C 'test_req002.py::test_s[ROW-S]' skipped 0.0; C 'test_journeys.py::test_apply[ROW-J]' passed 10.5)" ".vid/ledger-results/$SHA.full.xml"
cp ".vid/ledger-results/$SHA.full.xml" ".vid/ledger-results/$SHA.live.sel-1.xml"
cat > .vid/metrics-events <<'EV'
verdict slice=1 row=ROW-K result=KEPT
verdict slice=1 row=ROW-V result=KEPT
verdict slice=1 row=ROW-Y result=KEPT
verdict slice=1 row=ROW-Z result=KEPT
verdict slice=1 claimed=4 breached=0
reverted row=ROW-Y
verdict slice=2 row=ROW-Z result=BREACHED
verdict slice=fix-2026-09-21 row=ROW-F result=KEPT
verdict slice=2 row=ROW-J result=KEPT transition=1/4
verdict slice=2 row=ROW-J result=KEPT transition=2/4
verdict slice=2 row=ROW-J result=BREACHED transition=3/4
verdict slice=2 row=ROW-J result=KEPT transition=4/4
EV
printf 'ledger-run seconds=50 kind=full report=%s.full.xml\n' "$SHA" >> .vid/metrics-events

OUT=$(sh checks/metrics.sh)
printf '%s\n' "$OUT" | sed -n '2p' | grep -q '^rows: kept 3 · unverdicted 3 · breached 2 · red 1 · owed 1 · deploy-owed 1 (unmet 7; rows 11;' || { echo 'metrics-claim: the headline is wrong' >&2; printf '%s\n' "$OUT" | sed -n '2p' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'honesty slice=2 row-verdicts kept=0 breached=1 transition-verdicts kept=3 breached=1' || exit 1
printf '%s\n' "$OUT" | grep -q "cost ledger-run seconds=50 browser=15 behavior=2 setup=34 kind=full report=$SHA.full.xml" || { printf '%s\n' "$OUT" | grep 'cost ledger-run' >&2; exit 1; }
# the journey's breached transition re-verdicted KEPT → the row is kept; a per-transition KEPT never outranks the latest BREACHED of another transition
printf 'verdict slice=2 row=ROW-J result=KEPT transition=3/4\n' >> .vid/metrics-events
sh checks/metrics.sh | sed -n '2p' | grep -q '^rows: kept 4 · unverdicted 3 · breached 1 · red 1' || exit 1
# a later BREACHED on a kept row outranks its KEPT; a later KEPT on Z re-keeps it
printf 'verdict slice=3 row=ROW-K result=BREACHED\nverdict slice=3 row=ROW-Z result=KEPT\n' >> .vid/metrics-events
sh checks/metrics.sh | sed -n '2p' | grep -q '^rows: kept 4 · unverdicted 3 · breached 1 · red 1' || exit 1

# the claim from slice start to close
CL=$(sh checks/metrics.sh claim --from .vid/ledger-results/aaaaaaaaaaaa.full.xml --to ".vid/ledger-results/$SHA.full.xml")
for want in 'claim row=ROW-X why=unverdicted' 'claim row=ROW-W why=unverdicted' 'claim row=ROW-V why=re-paid' 'claim row=ROW-F why=re-paid' 'claim row=ROW-Y why=unverdicted' 'claim row=ROW-K why=breached'; do
  printf '%s\n' "$CL" | grep -qxF "$want" || { echo "metrics-claim: missing '$want'" >&2; printf '%s\n' "$CL" >&2; exit 1; }
done
printf '%s\n' "$CL" | grep -q 'row=ROW-Z' && { echo 'metrics-claim: Z (KEPT, passing at both ends) is in the claim' >&2; exit 1; }
printf '%s\n' "$CL" | grep -q 'row=ROW-S' && exit 1
printf '%s\n' "$CL" | grep -q 'row=ROW-J' && exit 1        # kept, passing at both ends
printf '%s\n' "$CL" | grep -q '^claim rows=6 ' || { printf '%s\n' "$CL" | tail -1 >&2; exit 1; }
if sh checks/metrics.sh claim --to ".vid/ledger-results/$SHA.live.sel-1.xml" >/dev/null 2>&1; then echo 'metrics-claim: a .live. report was accepted as --to' >&2; exit 1; fi

# no export-backed receipt for HEAD → receipt: none, no kept count
rm ".vid/ledger-results/$SHA.full.xml"
sh checks/metrics.sh | sed -n '2p' | grep -q '^rows: receipt: none — materialised rows unverified · materialised 9 · owed 1 · deploy-owed 1' || { sh checks/metrics.sh | sed -n '2p' >&2; exit 1; }
sh checks/metrics.sh | sed -n '2p' | grep -q 'kept' && exit 1
exit 0
