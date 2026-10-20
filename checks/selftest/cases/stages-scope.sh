#!/bin/sh
# Purpose: selftest case — one reader gives every stage-aware reader its scope (v0.26.10.5 spec R3, R4; §5
# stages-scope). On the toy two-stage product (fixtures/stages.sh): `scope --upto 1` is exactly ROW-001 ROW-002
# RULE-001 HOS-002; `scope --upto 2` adds ROW-003 (split: moved REQ-003 to stage 2), ROW-004, ROW-006 (row: placed the
# mixed row in stage 2) and HOS-001 (it protects REQ-004, stage 2) — a census row is in stage 1 and a HOS row follows
# what it protects; ROW-005 (phase: later) is in neither; `--reqs` adds the requirements of the stages, never
# REQ-005; `stage-of` says the same, `later` for ROW-005; with no --upto, RUN-STATE's `stage:`; and with no
# STAGES.md every row not later is stage 1. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stages-scope: $*" >&2; exit 1; }
mkdir -p "$T/r/checks"; cd "$T/r"; git init -q
cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
st_files
one() { sh checks/stages.sh scope "$@" | tr '\n' ' ' | sed 's/ $//'; }
[ "$(one --upto 1)" = 'ROW-001 ROW-002 RULE-001 HOS-002' ] || fail "scope --upto 1 is '$(one --upto 1)'"
[ "$(one --upto 2)" = 'ROW-001 ROW-002 ROW-003 ROW-004 ROW-006 RULE-001 HOS-001 HOS-002' ] || fail "scope --upto 2 is '$(one --upto 2)'"
[ "$(one --upto 2 --reqs)" = 'ROW-001 ROW-002 ROW-003 ROW-004 ROW-006 RULE-001 HOS-001 HOS-002 REQ-001 REQ-002 REQ-003 REQ-004' ] || fail "scope --upto 2 --reqs is '$(one --upto 2 --reqs)'"
for p in ROW-003:2 ROW-006:2 RULE-001:1 HOS-001:2 HOS-002:1 ROW-005:later REQ-003:2 REQ-005:later; do
  [ "$(sh checks/stages.sh stage-of "${p%%:*}")" = "${p#*:}" ] || fail "stage-of ${p%%:*} is not ${p#*:}"
done
if sh checks/stages.sh stage-of ROW-999 > /dev/null 2>&1; then fail 'stage-of an unknown id exited 0'; fi
mkdir -p .vid; printf 'run: active\nstage: 2\n' > .vid/RUN-STATE.md
[ "$(one)" = "$(one --upto 2)" ] || fail 'scope with no --upto does not read RUN-STATE stage: 2'
rm STAGES.md
[ "$(one --upto 1)" = 'ROW-001 ROW-002 ROW-003 ROW-004 ROW-006 RULE-001 HOS-001 HOS-002' ] || fail "without STAGES.md, scope --upto 1 is '$(one --upto 1)', not every row but the later one"
exit 0
