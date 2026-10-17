#!/bin/sh
# Purpose: selftest case — the computed hold, its releases, the amendment
# wipe and the fix re-grade's population (v0.9.3 spec 3.6, 3.7, 3.13; R9,
# R10; §7 case 4). A toy repository under `grammar: 0.9.3`, real commits,
# verdict events only. Convicts unless: a twice-breached row is held — its
# test field unchanged, the headline counting it `breached`, the claim
# naming it `held row=ID` and omitting it; `reissued` → claimed, not held,
# attempts still 2; one more product round → not held, attempts 3; another
# → held again, attempts 4; `amended` → verdicts wiped, attempts 0, claimed
# `unverdicted`; a grader quoted before the amendment returning KEPT after
# it → recorded, ineligible, the row still unverdicted and claimed; a fix
# re-grade KEPT on a held row → released, `kept`; `fix-population` reaches a
# row whose REQ is cited in a changed module's declared dependent and not
# one cited only elsewhere, a row whose ledger test the fix changed, and a
# harness-held row when the fix touched only the harness client — released
# on its KEPT; an errored case whose grader proved a product defect keeps
# class product (attempt 1), a broken fixture's is harness (no attempt); a
# legacy `reverted` still wipes, a legacy `attempts` still counts, and
# `legacy-reverted=` counts. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/extractors tests/invariants app/alerts app/web app/billing .vid/ledger-results
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
cat > ARCHITECTURE.md <<'AR'
# toy
Import court: enforce

| Module | Responsibility | Owned tables/data | Public surface | Dependents |
|---|---|---|---|---|
| app/alerts | alerts | alert | `app.alerts` — send | app/web |
| app/web | pages | none | `app.web` — views | none |
| app/billing | billing | invoice | `app.billing` — charge | none |
AR
cat > INVENTORY.md <<'INV'
# toy
```vid-inventory
grammar: 0.9.3
ROW-A | behavior | REQ-001 | n/a | n/a | the bound and the reissue | REQ-001 | tests/invariants/a.py
ROW-M | behavior | REQ-002 | n/a | n/a | amended mid-flight | REQ-002 | tests/invariants/m.py
ROW-W | behavior | REQ-010 | n/a | n/a | cited in a dependent of the changed module | REQ-010 | tests/invariants/w.py
ROW-B | behavior | REQ-011 | n/a | n/a | cited only in an unrelated module | REQ-011 | tests/invariants/w.py
ROW-X | behavior | REQ-012 | n/a | n/a | held on the harness | REQ-012 | tests/invariants/x.py
ROW-E | behavior | REQ-013 | n/a | n/a | errored: sign-in defect | REQ-013 | tests/invariants/e.py
ROW-F | behavior | REQ-013 | n/a | n/a | errored: broken fixture | REQ-013 | tests/invariants/e.py
ROW-L | behavior | REQ-014 | n/a | n/a | legacy history | REQ-014 | tests/invariants/l.py
```
INV
printf '# Purpose: alerts\n' > app/alerts/send.py
printf '# Purpose: pages — REQ-010\n' > app/web/view.py
printf '# Purpose: billing — REQ-011\n' > app/billing/charge.py
for f in a m w x e l harness; do printf '# Purpose: ledger (fixture) %s\n' "$f" > "tests/invariants/$f.py"; done
g add -A && g commit -qm root; S0=$(git rev-parse --short=12 HEAD)
C() { printf '<case name="tests/invariants/%s" status="%s" time="0.1"/>\n' "$1" "${2:-passed}"; }
receipt() { S=$(git rev-parse --short=12 HEAD); { echo '<r>'; C 'a.py::a[ROW-A]'; C 'm.py::m[ROW-M]'; C 'w.py::w[ROW-W]'; C 'w.py::b[ROW-B]'; C 'x.py::x[ROW-X]'; C 'e.py::e[ROW-E]' error; C 'e.py::f[ROW-F]' error; C 'l.py::l[ROW-L]'; echo '</r>'; } > ".vid/ledger-results/$S.full.xml"; }
receipt
V() { printf 'verdict slice=%s row=%s result=%s class=%s brief=%s quoted-at=%s\n' "$@" >> .vid/metrics-events; }
col() { sh checks/metrics.sh row-state --table | awk -F'\t' -v id="$1" -v c="$2" '$1==id { print $c }'; }
fail() { echo "held: $*" >&2; sh checks/metrics.sh row-state --table >&2; exit 1; }
claim() { sh checks/metrics.sh claim --to ".vid/ledger-results/$(git rev-parse --short=12 HEAD).full.xml"; }
: > .vid/metrics-events
# the bound: two product rounds
V 1 ROW-A BREACHED product b1 "$S0"; V 2 ROW-A BREACHED product b2 "$S0"
[ "$(col ROW-A 5)" = bound ] && [ "$(col ROW-A 7)" = 2 ] || fail 'two product rounds are not held'
grep -q '^ROW-A .*| tests/invariants/a.py$' INVENTORY.md || fail 'the held row lost its test field'
sh checks/metrics.sh | sed -n 2p | grep -q 'breached 1 .*held 1' || fail 'the headline does not count the held row breached'
claim | grep -qx 'held row=ROW-A reason=bound' || fail 'the claim does not name the held row'
claim | grep -q 'claim row=ROW-A' && fail 'the claim includes the held row'
# reissued: claimed, not held, attempts still 2; then 3 unheld; then 4 held
printf 'reissued row=ROW-A why=A-031\n' >> .vid/metrics-events
[ "$(col ROW-A 5)" = - ] && [ "$(col ROW-A 7)" = 2 ] || fail 'a reissued row is still held, or its history was lowered'
claim | grep -qx 'claim row=ROW-A why=breached' || fail 'a reissued row is not claimed'
V 3 ROW-A BREACHED product b3 "$S0"
[ "$(col ROW-A 5)" = - ] && [ "$(col ROW-A 7)" = 3 ] || fail 'one breach after the reissue held the row, or attempts are not 3'
V 4 ROW-A BREACHED product b4 "$S0"
[ "$(col ROW-A 5)" = bound ] && [ "$(col ROW-A 7)" = 4 ] || fail 'a second breach after the reissue did not hold it again at attempts 4'
# a fix re-grade KEPT on the held row releases it
V fix-2026-09-23 ROW-A KEPT product .vid/briefs/fix-2026-09-23/grader-1.md "$S0"
[ "$(col ROW-A 2)" = kept ] && [ "$(col ROW-A 5)" = - ] && [ "$(col ROW-A 7)" = 0 ] || fail 'a fix re-grade KEPT did not release the held row'
# amended: wiped, attempts 0, claimed unverdicted; a grader quoted before it is ineligible
V 1 ROW-M BREACHED product b1 "$S0"
printf '# Purpose: ledger (fixture) m — unrelated commit\n' > tests/invariants/m.py; g commit -qam 'between'; S1=$(git rev-parse --short=12 HEAD)
printf 'amended row=ROW-M sha=%s\n' "$S1" >> .vid/metrics-events
receipt
[ "$(col ROW-M 3)" = NONE ] && [ "$(col ROW-M 7)" = 0 ] && [ "$(col ROW-M 2)" = unverdicted ] || fail 'an amended row is not unverdicted with attempts 0'
claim | grep -qx 'claim row=ROW-M why=unverdicted' || fail 'an amended row is not claimed'
V 2 ROW-M KEPT product b-stale "$S0"
[ "$(col ROW-M 2)" = unverdicted ] || fail 'a KEPT quoted before the amendment satisfied the row'
grep -q "row=ROW-M result=KEPT .*quoted-at=$S0" .vid/metrics-events || fail 'the ineligible verdict was not kept on record'
claim | grep -qx 'claim row=ROW-M why=unverdicted' || fail 'the ineligible KEPT took the row out of the claim'
V 2 ROW-M KEPT product b-fresh "$S1"
[ "$(col ROW-M 2)" = kept ] || fail 'a KEPT quoted at the amendment was not eligible'
# errored cases: the grader's demonstrated cause decides the class
V 1 ROW-E BREACHED product b1 "$S0"; V 1 ROW-F BREACHED harness b1 "$S0"
[ "$(col ROW-E 4)" = product ] && [ "$(col ROW-E 7)" = 1 ] && [ "$(col ROW-E 2)" = red ] || fail 'an errored case with a product counterexample is not class product, attempt 1'
[ "$(col ROW-F 4)" = harness ] && [ "$(col ROW-F 7)" = 0 ] || fail 'a broken fixture is not class harness with no attempt'
# legacy events: reverted wipes, attempts counts, legacy-reverted= counts
printf 'verdict slice=1 row=ROW-L result=KEPT\nattempts row=ROW-L n=2\nreverted row=ROW-L\n' >> .vid/metrics-events
[ "$(col ROW-L 3)" = NONE ] || fail 'a legacy reverted did not wipe'
OUT=$(sh checks/metrics.sh)
printf '%s\n' "$OUT" | grep -q 'honesty attempts-to-KEPT one=0 two=1' || fail 'a legacy attempts event is not counted'
printf '%s\n' "$OUT" | grep -q 'honesty legacy-reverted=1 ' || fail 'legacy-reverted= does not count'
printf '%s\n' "$OUT" | grep -q 'rows-reverted-to-owed' && fail 'the 0.9.2 reversion line printed under 0.9.3'
# the fix re-grade's population: a standalone fix from S2
S2=$(git rev-parse --short=12 HEAD)
V 1 ROW-W BREACHED product b1 "$S0"; V 1 ROW-B BREACHED product b1 "$S0"
V 1 ROW-X BREACHED harness b1 "$S0"; V 2 ROW-X BREACHED harness b2 "$S2"
[ "$(col ROW-X 5)" = harness ] || fail 'two harness rounds with nothing repaired between are not held'
printf '# Purpose: alerts — the fix\n' > app/alerts/send.py
printf '# Purpose: ledger (fixture) l — strengthened by a test-author pass\n' > tests/invariants/l.py
printf '# Purpose: harness client (fixture), repaired\n' > tests/invariants/harness.py
g commit -qam 'the fix'; S3=$(git rev-parse --short=12 HEAD); receipt
POP=$(sh checks/metrics.sh fix-population --base "$S2")
printf '%s\n' "$POP" | grep -qx 'regrade row=ROW-W why=cited-in-radius' || fail "a row cited in a changed module's dependent is not in the re-grade: $POP"
printf '%s\n' "$POP" | grep -q 'row=ROW-B ' && fail 'a row cited only in an unrelated module is in the re-grade'
printf '%s\n' "$POP" | grep -qx 'regrade row=ROW-L why=test-changed' || fail "a row whose ledger test the fix changed is not in the re-grade: $POP"
printf '%s\n' "$POP" | grep -qx 'regrade row=ROW-X why=harness-held' || fail "a harness-held row is not in the re-grade when the fix touched the harness: $POP"
printf '%s\n' "$POP" | grep -q "^regrade rows=3 base=$S2 radius=app/alerts app/web$" || fail "the population summary is wrong: $POP"
V fix-2026-09-23 ROW-X KEPT product .vid/briefs/fix-2026-09-23/grader-1.md "$S3"
[ "$(col ROW-X 2)" = kept ] && [ "$(col ROW-X 5)" = - ] || fail 'the harness-held row was not released by its KEPT'
exit 0
