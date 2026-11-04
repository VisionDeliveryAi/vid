#!/bin/sh
# Purpose: selftest case — the plan block and its changes in ticket mode, P10 and P11 (v0.26.10.12.2.2
# R1, R2). Under `mode: tickets` in a plan session plan.sh check accepts a block with the lane
# devagent, the kind skeleton, ids of every inventory kind (RULE-, HOS-, SEAM-, DIF-) and a range of one prefix in
# rows: and protected:, and still develop's own values; it refuses an id no inventory line has and a range of two
# prefixes. Outside ticket mode (a develop session) each ticket-mode value is refused as before. `plan.sh change
# create … --trigger initial --expect …` records the plan (a plan-change event, the decision kept, the plan kept); a
# change with no trigger, no expectation, a trigger needing evidence and none, or evidence that does not resolve is
# refused, kept as a refused decision, and the recorded hash stays; one naming step:<id> of the plan is accepted.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "plan-tickets: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks" "$T/r/.vid"; cd "$T/r"; git init -q; cp "$CHECKS/plan.sh" checks/
cat > INVENTORY.md <<'EOF'
# Inventory

```vid-inventory
grammar: 0.9.3
ROW-001 | behavior | REQ-001 | anonymous | n/a | x | REQ-001 | owed: spec-only — first stage
ROW-002 | behavior | REQ-001 | anonymous | n/a | y | REQ-001 | owed: spec-only — first stage
rule | RULE-001 | a rule | sites: every page | 1 | owed: spec-only — ticket
rule | RULE-002 | another rule | sites: every page | 1 | owed: spec-only — ticket
rule | RULE-003 | a third rule | sites: every page | 1 | owed: spec-only — ticket
hostility | HOS-001 | try it | protects: REQ-001 | disable: the guard | owed: spec-only — ticket
difference | DIF-001 | a knob | a | b | why | paying-step: staging
```

```vid-inventory
seam | SEAM-001 | the mail provider | delivery | chosen: D-001 | credentials: not-yet | probe: owed | evidence: owed | quirks: none yet
```
EOF
git -c user.email=vid@selftest -c user.name=vid commit -qm root --allow-empty
rs() { printf 'run: active\nsession: S1\n%bplan: required\nstage: 0\n\n## The plan\n\n```vid-plan\n%s\n```\n' "$1" "$2" > .vid/RUN-STATE.md; }
GOOD='step S01 | name: the skeleton | modules: web | builds-on: - | rows: ROW-001 | lane: devagent | kind: skeleton
step S02 | name: the rules | modules: web | builds-on: S01 | rows: ROW-002 RULE-001..RULE-003 HOS-001 | lane: devagent
step S03 | name: the outside | modules: mail | rows: SEAM-001 DIF-001 | lane: builder | kind: hardening
protected: HOS-001 RULE-001..RULE-002
shared: -'
printf 'stage name=plan state=start session=S1 records=29 at=2026-11-03T10:00:00Z\n' > .vid/metrics-events
chk() { RC=0; sh checks/plan.sh check > "$T/out" 2>&1 || RC=$?; }
rs 'mode: tickets\n' "$GOOD"; chk; [ "$RC" = 0 ] && grep -q '^ViD plan: ok' "$T/out" || fail 'a good ticket-mode block is refused in ticket mode'
grep -q ' 3 steps, 8 rows' "$T/out" || fail "the block's steps and rows are not counted as given: $(cat "$T/out")"
rs 'mode: tickets\n' "$(printf '%s\n' "$GOOD" | sed 's/RULE-001\.\.RULE-003/RULE-001..RULE-009/')"; chk
[ "$RC" != 0 ] && grep -q 'RULE-004 (step S02) is not a row of INVENTORY.md' "$T/out" || fail 'an id no inventory line has is not refused'
rs 'mode: tickets\n' "$(printf '%s\n' "$GOOD" | sed 's/RULE-001\.\.RULE-003/RULE-001..HOS-003/')"; chk
[ "$RC" != 0 ] && grep -q 'the range RULE-001..HOS-003 is of two prefixes' "$T/out" || fail 'a range of two prefixes is not refused'
# v0.26.10.12.3.1 (R2, R10): a setup lane, a dashed link and a needs line, accepted in ticket mode
rs 'mode: tickets\n' "$(printf '%s\nneeds ROW-002 RULE-001..RULE-003 | S01\n' "$GOOD" | sed 's/^\(step S02 .*\)lane: devagent$/\1lane: india-1 | fakes: S03/')"; chk
[ "$RC" = 0 ] && grep -q '^ViD plan: ok' "$T/out" || fail 'a setup lane, a fakes: field or a needs line is refused in ticket mode'
# outside ticket mode, a develop session: each ticket-mode value refused as before
printf 'stage name=develop state=start session=S1 records=29 at=2026-11-03T11:00:00Z\n' >> .vid/metrics-events
off() { rs '' "$1"; chk; [ "$RC" != 0 ] && grep -q "$2" "$T/out" || fail "outside ticket mode, $3 is not refused"; }
D='step S01 | name: a | modules: web | builds-on: - | rows: ROW-001
shared: harness'
off "$(printf '%s\n' "$D" | sed 's/rows: ROW-001$/rows: ROW-001 | lane: devagent/')" "lane 'devagent' is neither builder" 'the lane devagent'
off "$(printf '%s\n' "$D" | sed 's/rows: ROW-001$/rows: ROW-001 | kind: skeleton/')" "kind is hardening, or absent" 'the kind skeleton'
off "$(printf '%s\n' "$D" | sed 's/rows: ROW-001$/rows: ROW-001 | lane: india-1/')" "lane 'india-1' is neither builder" 'a setup lane'
off "$(printf '%s\n' "$D" | sed 's/rows: ROW-001$/rows: ROW-001 | fakes: S02/')" "unknown field 'fakes: S02'" 'a fakes: field'
off "$(printf '%s\nneeds ROW-001 | -\n' "$D")" 'does not parse' 'a needs line'
off "$(printf '%s\n' "$D" | sed 's/rows: ROW-001$/rows: ROW-001 RULE-001/')" "'RULE-001' is neither a ROW id nor a range" 'a rule id'
rs '' "$D"; chk; [ "$RC" = 0 ] || fail 'a develop block is refused outside ticket mode'
# ticket mode again, in a plan session: the changes
printf 'stage name=plan state=start session=S1 records=29 at=2026-11-03T12:00:00Z\n' >> .vid/metrics-events
rs 'mode: tickets\n' "$GOOD"
ch() { RC=0; sh checks/plan.sh change "$@" > "$T/out" 2>&1 || RC=$?; }
ch create 'the first plan' --trigger initial --expect 'the skeleton ticket first'; [ "$RC" = 0 ] || fail 'change create was refused'
H1=$(sed -n 's/^plan-change what=create hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events); [ -n "$H1" ] || fail 'no plan-change recorded'
[ -f ".vid/plans/$H1.plan" ] && [ "$(ls .vid/plans/decisions/*.why | wc -l | tr -d ' ')" = 1 ] && grep -q '^result=accepted$' .vid/plans/decisions/*.why || fail 'the plan or its decision is not kept'
rs 'mode: tickets\n' "$(printf '%s\n' "$GOOD" | sed 's/^step S03 .*/step S03 | name: the mail | modules: mail | rows: SEAM-001 | lane: devagent\
step S04 | name: the knob | modules: mail | rows: DIF-001 | lane: devagent/')"
refused() { ch split 'split the outside step' "$@"; [ "$RC" != 0 ] || fail "a change was accepted: $*"; }
refused --expect 'two steps'; grep -q 'name its trigger and its expected effect' "$T/out" || fail 'a change with no trigger is not refused so'
refused --trigger discovered-dependency; grep -q 'name its trigger and its expected effect' "$T/out" || fail 'a change with no expectation is not refused so'
refused --trigger discovered-dependency --expect 'two steps'; grep -q 'needs at least one evidence reference' "$T/out" || fail 'a change with no evidence is not refused so'
refused --trigger discovered-dependency --evidence step:S09 --expect 'two steps'; grep -q "'step:S09' does not resolve" "$T/out" || fail 'unresolved evidence is not refused so'
[ "$(cat .vid/plans/decisions/*.why | grep -c '^result=refused$')" = 4 ] || fail 'the refused changes are not kept as refused decisions'
[ "$(grep -c '^plan-change ' .vid/metrics-events)" = 1 ] || fail 'a refused change moved the recorded hash'
ch split 'split the outside step' --trigger discovered-dependency --evidence step:S03 --expect 'two steps'; [ "$RC" = 0 ] || fail 'a change with resolving evidence was refused'
H2=$(grep '^plan-change ' .vid/metrics-events | tail -n 1 | sed 's/.* hash=\([0-9a-f]*\) .*/\1/'); [ "$H2" != "$H1" ] && [ -f ".vid/plans/$H1.plan" ] && [ -f ".vid/plans/$H2.plan" ] || fail 'both plans are not kept'
exit 0
