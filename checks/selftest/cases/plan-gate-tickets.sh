#!/bin/sh
# Purpose: selftest case — the gate under ticket mode (v0.26.10.9 spec R9; §5 plan-gate-tickets). RUN-STATE `mode:
# tickets`, `plan: required`, `run: active`, a toy inventory and plan block: with `stage name=plan` started the gate is
# on and `plan.sh change create` records a plan-change; after the plan stage's end it is off; with `stage
# name=replan` started it is on again, and after its end off. A develop start under mode: tickets reads it off, and
# without mode: tickets a plan start does. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "plan-gate-tickets: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks" "$T/r/.vid"; cd "$T/r"; git init -q; cp "$CHECKS/plan.sh" checks/
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | anonymous | n/a | x | REQ-001 | owed: spec-only — first stage\n```\n' > INVENTORY.md
git -c user.email=vid@selftest -c user.name=vid commit -qm root --allow-empty
printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n\n## The plan\n\n```vid-plan\nstep S1 | name: first | modules: app/a | builds-on: - | rows: ROW-001\nshared: -\n```\n' > .vid/RUN-STATE.md
ev() { printf 'stage name=%s state=%s session=S1 records=29 at=%s\n' "$1" "$2" "$3" >> .vid/metrics-events; }
on() { sh checks/plan.sh gate > "$T/out" 2>&1; }
ev plan start 2026-10-24T10:00:00Z
on || fail 'the gate is off in a plan session under mode: tickets'
sh checks/plan.sh change create 'the whole plan, three levels' --trigger initial --expect 'the skeleton ticket first' > "$T/out" 2>&1 || fail 'plan.sh change was refused in a plan session'
grep -q '^plan-change what=create hash=' .vid/metrics-events || fail 'no plan-change recorded'
ev plan end 2026-10-24T10:30:00Z; if on; then fail 'the gate is on after the plan stage ended'; fi
grep -q 'the plan stage has ended' "$T/out" || fail 'the off reason does not name the ended plan stage'
ev replan start 2026-10-25T09:00:00Z; on || fail 'the gate is off in a replan session'
ev replan end 2026-10-25T09:30:00Z; if on; then fail 'the gate is on after the replan stage ended'; fi
ev develop start 2026-10-25T10:00:00Z; if on; then fail 'a develop start reads the gate on under mode: tickets'; fi
sed '/^mode: tickets$/d' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
ev plan start 2026-10-25T11:00:00Z; if on; then fail 'a plan start reads the gate on without mode: tickets'; fi
exit 0
