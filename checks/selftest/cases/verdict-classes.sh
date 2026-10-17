#!/bin/sh
# Purpose: selftest case — a breach is classified and the bound is computed
# (v0.9.3 spec 3.6, R8; §7 case 3). A toy repository under `grammar: 0.9.3`
# with a fixture results reader and a current receipt; verdict events only,
# never a session-written count. Convicts unless: a `harness` breach adds no
# attempt and leaves the row `unverdicted` (the incident line is the
# session's, counted as friction); a second harness round with no commit
# touching the harness between the two briefs' quoted-at commits holds the
# row `reason=harness`, and one with such a commit between does not; a
# `test` breach adds no attempt and leaves the row `unverdicted`; two test
# rounds hold it `reason=test` and the claim omits it, naming it held; a
# `product` breach is attempt 1; a journey breaching two transitions in ONE
# brief is attempt 1 and no hold; a second product round holds it
# `reason=bound`; a journey with one `test` and one `product` transition
# has row class `product` and lands in closure bucket (3). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
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
grammar: 0.9.3
ROW-H1 | behavior | REQ-001 | n/a | n/a | harness twice, nothing repaired between | REQ-001 | tests/invariants/t.py
ROW-H2 | behavior | REQ-001 | n/a | n/a | harness twice, the harness repaired between | REQ-001 | tests/invariants/t.py
ROW-T1 | behavior | REQ-001 | n/a | n/a | test once | REQ-001 | tests/invariants/t.py
ROW-T2 | behavior | REQ-001 | n/a | n/a | test twice | REQ-001 | tests/invariants/t.py
ROW-P1 | behavior | REQ-002 | n/a | n/a | product once | REQ-002 | tests/invariants/t.py
ROW-P2 | behavior | REQ-002 | n/a | n/a | product twice | REQ-002 | tests/invariants/t.py
ROW-J1 | journey | apply | candidate | n/a | two transitions breached in one brief | REQ-003 | tests/invariants/j.py
ROW-J2 | journey | apply | candidate | n/a | one test, one product transition | REQ-003 | tests/invariants/j.py
```
INV
printf '# Purpose: toy\n' > app/main.py
printf '# Purpose: harness client (fixture)\n' > tests/invariants/harness.py
g add -A && g commit -qm root; C1=$(git rev-parse --short=12 HEAD)
printf '# Purpose: harness client (fixture), repaired\n' > tests/invariants/harness.py
g commit -qam 'repair the harness'; C2=$(git rev-parse --short=12 HEAD)
printf '# Purpose: toy, again\n' > app/main.py
g commit -qam 'product work'; C3=$(git rev-parse --short=12 HEAD)
C() { printf '<case name="tests/invariants/%s" status="passed" time="0.1"/>\n' "$1"; }
{ echo '<report>'; for r in H1 H2 T1 T2 P1 P2; do C "t.py::t[ROW-$r]"; done; C 'j.py::j[ROW-J1]'; C 'j.py::j[ROW-J2]'; echo '</report>'; } > ".vid/ledger-results/$C3.full.xml"
cat > .vid/metrics-events <<EV
verdict slice=1 claimed=8 breached=8
verdict slice=1 row=ROW-H1 result=BREACHED class=harness brief=.vid/briefs/1/grader-1.md quoted-at=$C2
incident slice=1 harness row=ROW-H1 the fixture's order leaked a record between cases
verdict slice=1 row=ROW-H2 result=BREACHED class=harness brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-T1 result=BREACHED class=test brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-T2 result=BREACHED class=test brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-P1 result=BREACHED class=product brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-P2 result=BREACHED class=product brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-J1 result=KEPT class=product transition=1/3 brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-J1 result=BREACHED class=product transition=2/3 brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-J1 result=BREACHED class=product transition=3/3 brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-J2 result=BREACHED class=test transition=1/2 brief=.vid/briefs/1/grader-1.md quoted-at=$C1
verdict slice=1 row=ROW-J2 result=BREACHED class=product transition=2/2 brief=.vid/briefs/1/grader-1.md quoted-at=$C1
EV
col() { sh checks/metrics.sh row-state --table | awk -F'\t' -v id="$1" -v c="$2" '$1==id { print $c }'; }   # 2 bucket 3 latest 4 class 5 held 7 attempts
fail() { echo "verdict-classes: $*" >&2; sh checks/metrics.sh row-state --table >&2; exit 1; }
# one round each
[ "$(col ROW-H1 2)" = unverdicted ] && [ "$(col ROW-H1 7)" = 0 ] && [ "$(col ROW-H1 5)" = - ] || fail 'a harness breach is not unverdicted with no attempt'
[ "$(col ROW-T1 2)" = unverdicted ] && [ "$(col ROW-T1 7)" = 0 ] || fail 'a test breach is not unverdicted with no attempt'
[ "$(col ROW-P1 2)" = breached ] && [ "$(col ROW-P1 7)" = 1 ] || fail 'a product breach is not attempt 1'
[ "$(col ROW-J1 7)" = 1 ] && [ "$(col ROW-J1 5)" = - ] || fail 'two transitions breached in one brief are not one attempt'
[ "$(col ROW-J2 4)" = product ] && [ "$(col ROW-J2 2)" = breached ] || fail 'a journey with a test and a product transition is not class product'
sh checks/metrics.sh closure | grep -q '^closure unfinished-implementation n=.* ROW-J2' || fail 'the mixed journey is not in closure bucket (3)'
sh checks/metrics.sh | grep -q '^friction incidents=1 ' || fail 'the harness incident is not counted'
# the second round
cat >> .vid/metrics-events <<EV
verdict slice=2 claimed=6 breached=6
verdict slice=2 row=ROW-H1 result=BREACHED class=harness brief=.vid/briefs/2/grader-1.md quoted-at=$C3
verdict slice=2 row=ROW-H2 result=BREACHED class=harness brief=.vid/briefs/2/grader-1.md quoted-at=$C3
verdict slice=2 row=ROW-T2 result=BREACHED class=test brief=.vid/briefs/2/grader-1.md quoted-at=$C3
verdict slice=2 row=ROW-P2 result=BREACHED class=product brief=.vid/briefs/2/grader-1.md quoted-at=$C3
EV
[ "$(col ROW-H1 5)" = harness ] && [ "$(col ROW-H1 7)" = 0 ] || fail 'two harness rounds with nothing repaired between are not held reason=harness'
[ "$(col ROW-H2 5)" = - ] || fail 'two harness rounds with a harness commit between were held'
[ "$(col ROW-T2 5)" = test ] && [ "$(col ROW-T2 7)" = 0 ] || fail 'two test rounds are not held reason=test'
[ "$(col ROW-P2 5)" = bound ] && [ "$(col ROW-P2 7)" = 2 ] && [ "$(col ROW-P2 2)" = breached ] || fail 'two product rounds are not held reason=bound'
CL=$(sh checks/metrics.sh claim --to ".vid/ledger-results/$C3.full.xml")
printf '%s\n' "$CL" | grep -qx 'held row=ROW-T2 reason=test' || fail 'the claim does not name the test-held row'
printf '%s\n' "$CL" | grep -q 'claim row=ROW-T2' && fail 'the claim includes a held row'
printf '%s\n' "$CL" | grep -q 'claim row=ROW-P2' && fail 'the claim includes a held row'
printf '%s\n' "$CL" | grep -qx 'claim row=ROW-T1 why=breached' || fail 'an unheld test breach is not claimed again'
sh checks/metrics.sh | grep -q 'honesty slice=2 row-verdicts kept=0 breached=4 transition-verdicts kept=0 breached=0 classes product=1 test=1 harness=2' || fail 'the row-verdicts line does not carry the classes'
# gated: the same events under a 0.9.2 block print none of it
sed 's/^grammar: 0.9.3$/grammar: 0.9.2/' INVENTORY.md > i && mv i INVENTORY.md
sh checks/metrics.sh | grep -q 'classes ' && fail 'the classes rode a 0.9.2 block'
sh checks/metrics.sh row-state ROW-P2 | grep -q 'grammar: 0.9.3' || fail 'row-state answered a 0.9.2 block'
exit 0
