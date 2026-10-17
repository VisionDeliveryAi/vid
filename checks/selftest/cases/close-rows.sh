#!/bin/sh
# Purpose: selftest case — the rows a slice close must re-run (v0.9.6.1 spec
# 3.2, R2; §6 case 7). A toy develop run closing S2 (builds on S1), with S1,
# S3, S6 and S7 closed, S4 started and not closed, S5 not built. Sets 1–4
# are computed: S2's rows (1), S1's (2), S3's journey row and the
# materialised Tier-0 probe protecting a RULE (3, step=-), S6's red row and
# S7's row whose own test changed (4); set 5 is read from
# .vid/close/1.rows (5) and its note printed. v0.9.7.0.12 (R1): each row
# once with every set it is in (`sets=`, an S1 row also named in the rows
# file is 2,5) and its phase (1 for a row in set 1, 4 or 5, else 2). Never listed: S4's red rows
# (a started, unclosed parallel step), S5's rows (its journey row
# included), an owed row, a held row, a `later` row, an unmaterialised
# probe. Refused: a missing rows file (after printing the closing step's
# base), a row line without a reason, an ineligible row. Outside the gate:
# off, nothing computed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "close-rows: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"
rows s1 1 2; rows s2 3 4; rows s3 5 5 journey; rows s3 6 6; rows s4 7 8; rows s5 9 9 journey; rows s5 10 10
rows s6 11 13; rows s7b 14 14; rows s7 15 17
sed 's#^\(ROW-011 | .*\) | tests/invariants/test_s6.py$#\1 | owed: prerequisite — the export it reads is not built; paid at S9#; s#^\(ROW-017 | .*\) | REQ-001 | \(.*\)$#\1 | REQ-002 | \2#' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
awk '/^```$/ && !d { print "hostility | HOS-001 | request tenant A'"'"'s page on tenant B; expect not-found | protects: RULE-001 | disable: drop the tenant predicate | tests/invariants/test_hos.py | proved-red: abc123"
  print "hostility | HOS-002 | replay a session cookie across tenants | protects: REQ-001 | disable: drop the tenant check | owed: guard-first — the protection does not exist yet; paid in the slice that builds it"; d = 1 } { print }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
printf '# Purpose: the probe\ndef test_hos(): pass  # HOS-001\n' > tests/invariants/test_hos.py
printf '# PRD\n\n```vid-prd\nREQ-001 | functional | the product works | phase: pilot\nREQ-002 | functional | a later thing | phase: later\n```\n' > PRD.md
commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
  'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' \
  'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-005 ROW-006' \
  'step S4 | name: parallel | modules: app/s3 | builds-on: - | rows: ROW-007 ROW-008' \
  'step S5 | name: unbuilt | modules: app/s3 | builds-on: - | rows: ROW-009 ROW-010' \
  'step S6 | name: sixth | modules: app/s1 | builds-on: - | rows: ROW-011..ROW-013' \
  'step S7 | name: seventh | modules: app/s1 | builds-on: - | rows: ROW-014..ROW-017' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'seven steps' --trigger initial --expect 'the steps build in order' > /dev/null
PH=$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1); H0=$(git rev-parse --short=12 HEAD)
for s in S1 S2 S3 S4 S6 S7; do printf 'step-start step=%s plan=%s base=%s at=%s\n' "$s" "$PH" "$H0" "$(utcnow)" >> .vid/metrics-events; done
rcpt r1 HEAD inline ROW-001=passed ROW-002=passed ROW-005=passed ROW-006=passed ROW-007=failed ROW-012=failed ROW-013=passed ROW-014=passed ROW-015=passed ROW-016=failed HOS-001=passed
for s in S1 S3 S6 S7; do printf 'step-closed step=%s report=r1 at=%s\n' "$s" "$(utcnow)" >> .vid/metrics-events; done
printf 'verdict slice=1 row=ROW-016 result=BREACHED class=product brief=b1 quoted-at=%s at=%s\nverdict slice=1 row=ROW-016 result=BREACHED class=product brief=b2 quoted-at=%s at=%s\n' "$H0" "$(utcnow)" "$H0" "$(utcnow)" >> .vid/metrics-events
printf '# a stronger check\n' >> tests/invariants/test_s7b.py; commit_all 'S7b test changed'
# the rows file is missing: the base is printed, then the refusal
if sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1; then fail 'close-rows ran with no rows file'; fi
grep -q "^base step=S2 commit=$H0 from=step-start\$" "$T/out" || fail 'the closing step'"'"'s base was not printed'
grep -q 'no .vid/close/1.rows' "$T/out" || fail 'the refusal does not name the rows file'
mkdir -p .vid/close
printf '# the builder'"'"'s rows\nROW-006 | the label S2 moved is read by this surface\nROW-001 | the S2 change reads its counter\n\nnote | the shared settings change touches only the S2 page size\n' > .vid/close/1.rows
sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1 || fail 'close-rows refused a lawful rows file'
grep '^required ' "$T/out" > "$T/req"
cat > "$T/want" <<'W'
required row=ROW-003 sets=1,4 step=S2 phase=1
required row=ROW-004 sets=1,4 step=S2 phase=1
required row=ROW-001 sets=2,5 step=S1 phase=1
required row=ROW-002 sets=2 step=S1 phase=2
required row=HOS-001 sets=3 step=- phase=2
required row=ROW-005 sets=3 step=S3 phase=2
required row=ROW-012 sets=4 step=S6 phase=1
required row=ROW-014 sets=4 step=S7 phase=1
required row=ROW-006 sets=5 step=S3 phase=1
W
diff "$T/want" "$T/req" > "$T/diff" || { cat "$T/diff" >&2; fail 'the required rows are not sets 1–5 as computed'; }
grep -q '^note the shared settings change touches only the S2 page size$' "$T/out" || fail 'the note of set 5 was not printed'
grep -q '^close-rows steps=S2 required=9$' "$T/out" || fail 'no summary line'
# refusals: a line without a reason; an ineligible row (a started, unclosed step's; an unbuilt step's)
for bad in 'ROW-013 |' 'ROW-013' 'ROW-007 | the parallel step' 'ROW-009 | the unbuilt journey' 'ROW-011 | owed' 'the page | x'; do
  printf '%s\n' "$bad" > .vid/close/1.rows
  if sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1; then fail "the rows line '$bad' was accepted"; fi
  grep -q 'refused — .vid/close/1.rows' "$T/out" || fail "the refusal of '$bad' does not name the file"
done
printf 'ROW-007 | x\n' > .vid/close/1.rows; sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1 || true
grep -q 'ROW-007 is not eligible' "$T/out" || fail 'an unclosed parallel step'"'"'s row is not refused as ineligible'
printf 'ROW-013 |\n' > .vid/close/1.rows; sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1 || true
grep -q 'ROW-013 has no reason' "$T/out" || fail 'a line without a reason is not refused as such'
# outside the gate: off
sed 's/^run: .*/run: stopped paused/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
sh checks/metrics.sh close-rows --steps S2 > "$T/out" 2>&1 || fail 'close-rows outside the gate failed'
grep -q '^metrics close-rows: off' "$T/out" && ! grep -q '^required' "$T/out" || fail 'close-rows computed outside the gate'
exit 0
