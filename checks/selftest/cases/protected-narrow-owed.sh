#!/bin/sh
# Purpose: selftest case — done's owed probes on the narrowed routes (v0.9.7.3 spec 3.11, R11). S1 is closed and every
# row KEPT. A probe naming a rule row whose origin: is a lower-tier item, and a probe naming a lower-tier requirement,
# hold no step's done, and `inventory.sh --strict` still reports them; a tier-0 rule row with no probe, tied only to a
# lower-tier item, puts no owed line on any row. An unpaid probe naming ROW-002 by its ROW id holds S1 until it is
# paid; so does a probe naming the Tier-0 requirement ROW-003 derives from, and a probe naming only a rule row whose
# origin: is the Tier-0 invariant ROW-004 derives from. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "protected-narrow-owed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# pay <HOS id> <REQ/ROW the probe names>: the probe materialised and proved red
pay() {
  printf '# Purpose: the probe %s\ndef test_%s(): pass  # %s %s\n' "$1" "$1" "$1" "$2" | sed 's/test_HOS-/test_h/' > "tests/invariants/test_$1.py"
  awk -v h="$1" -v t="tests/invariants/test_$1.py" -F'|' 'BEGIN { OFS = "|" } { id = $2; gsub(/^[ \t]+|[ \t]+$/, "", id) } $1 ~ /^hostility/ && id == h { $NF = " " t } { print }' INVENTORY.md > x && mv x INVENTORY.md
  commit_all "the probe $1"
  _pr=$(git rev-parse --short=12 HEAD)
  awk -v h="$1" -v p="$_pr" -F'|' '{ id = $2; gsub(/^[ \t]+|[ \t]+$/, "", id) } $1 ~ /^hostility/ && id == h { $0 = $0 " | proved-red: " p } { print }' INVENTORY.md > x && mv x INVENTORY.md
  commit_all "$1 proved red"
}
bf_repo "$T/repo"
printf '# PRD\n\n```vid-prd\nREQ-001 | functional | T1 | the toy works\nREQ-002 | functional | T0 | the toy never leaks\nREQ-003 | functional | T1 | audit\nINV-001 | invariant | T0 | erasures stay erased\n```\n' > PRD.md
derive ROW-001 REQ-003; derive ROW-002 REQ-001; derive ROW-003 REQ-002; derive ROW-004 INV-001
awk '/^```$/ && !d { print "rule | RULE-001 | audits never lost | grep x | 0 | owed: census-armed — later | origin: REQ-003"; print "rule | RULE-002 | audits ordered | grep y | 1 | owed: census-armed — later | origin: REQ-003"; print "rule | RULE-003 | erasures re-applied | grep z | 0 | owed: census-armed — later | origin: INV-001"; d = 1 } { print }' INVENTORY.md > x && mv x INVENTORY.md
hostile HOS-001 RULE-002 'owed: prerequisite — not yet'; hostile HOS-002 REQ-003 'owed: prerequisite — not yet'
hostile HOS-004 REQ-002 'owed: prerequisite — not yet'; hostile HOS-005 RULE-003 'owed: prerequisite — not yet'
printf '# CLAUDE.md\n\n```vid-placement\napp/\ntests/\n```\n' > CLAUDE.md
commit_all 'the narrow routes'
sh checks/inventory.sh protected > "$T/out" 2>&1
grep -q '^owed ROW-001 ' "$T/out" && fail 'a probe of a rule row or a lower-tier requirement, or an unprobed tier-0 rule tied to one, owes on ROW-001'
grep -q 'by=RULE-001' "$T/out" && fail 'a tier-0 rule row with no probe, tied only to a lower-tier item, put an owed line on a row'
grep -q '^owed ROW-003 by=HOS-004$' "$T/out" || fail 'the probe naming the Tier-0 requirement owes nothing on its row'
grep -q '^owed ROW-004 by=HOS-005$' "$T/out" || fail 'the probe naming a rule row whose origin: is the Tier-0 invariant owes nothing on its row'
if sh checks/inventory.sh --strict > "$T/out" 2>&1; then fail '--strict passed with owed probes'; fi
grep -q '^OWED  HOS-001 ' "$T/out" && grep -q '^OWED  HOS-002 ' "$T/out" && grep -q '^OWED  RULE-001 ' "$T/out" || fail '--strict no longer reports the obligations outside the routes'
bf_on > /dev/null; bf_plan "$S1L" "$S2L" > /dev/null
sh checks/plan.sh start S1 > /dev/null; close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null; keepall ROW-001 ROW-002 ROW-003 ROW-004
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* done=no ' "$T/out" || fail 'S1 is done with HOS-004 and HOS-005 unpaid'
grep -q '^owed-hostility step=S1 row=ROW-003 by=HOS-004' "$T/out" || fail 'HOS-004 does not hold ROW-003'
grep -q '^owed-hostility step=S1 row=ROW-004 by=HOS-005' "$T/out" || fail 'HOS-005 does not hold ROW-004'
grep -q 'row=ROW-001 \|row=ROW-002 ' "$T/out" && fail 'ROW-001 or ROW-002 is held'
pay HOS-004 REQ-002; pay HOS-005 RULE-003
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* done=yes ' "$T/out" || fail 'S1 is not done with only probes outside the routes unpaid'
hostile HOS-003 ROW-002 'owed: prerequisite — not yet'; commit_all 'a probe naming ROW-002'
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* done=no ' "$T/out" || fail 'S1 is done with the probe naming ROW-002 unpaid'
grep -q '^owed-hostility step=S1 row=ROW-002 by=HOS-003' "$T/out" || fail 'the probe naming ROW-002 by its ROW id does not hold it'
pay HOS-003 ROW-002
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* done=yes ' "$T/out" || fail 'S1 is not done once the probe naming ROW-002 is paid'
exit 0
