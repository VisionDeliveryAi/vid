#!/bin/sh
# Purpose: selftest case — a ready close is recorded, tagged and reported (v0.26.10.5 spec R9, R10; §5
# stage-tag-report). On the toy two-stage product (fixtures/stages.sh), stage 1 ready with a pull-forward recorded:
# `stage-close --stage 1 --record` writes `stage-closed n=1 sha=<HEAD> ready rows=2 debt=0 stages-blob=<HEAD's
# STAGES.md blob>`, tags vid/stage-1 (annotated) at HEAD, appends a `## stage 1 <UTC>` section to SLICE-REPORTS with
# its counts, the pull-forward and what stage 2 holds, and sets RUN-STATE's `stage: 2`. Recording again is refused
# (the tag never moves). v0.26.10.8 (R9): the final stage's close is recorded and tagged too, setting no next stage
# (stage-close-final has the rest). A commit after the newest tag is listed by metrics.sh under "since stage 2's
# close". Unmet, --record writes nothing. 0.26.11.1.2 (R11): the section says `- passing ahead: <n> rows of later stages (<ids>)`, the
# rows of stage 2 whose every case passed in the receipt (ROW-004 failing and ROW-005 with no case left out; ROW-006's case named by its REQ-004
# in its cited file, as the close's own row reader maps it, counted), and 0 at the final stage. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stage-tag-report: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
st_close_repo "$T/r"
st_rcpt ROW-004=failed ROW-005=-; st_keep ROW-001
for f in .vid/ledger-results/*.full.xml; do sed 's/test_f\.py::t\[ROW-006\]/test_f.py::t[REQ-004]/' "$f" > "$T/rx" && cat "$T/rx" > "$f"; done   # ROW-006's case by its REQ
sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1 || true
grep -q '^stage-close 1 unmet=' "$T/out" || fail 'with ROW-002 unverdicted the close was not unmet'
! grep -q '^stage-closed ' .vid/metrics-events && ! git rev-parse -q --verify refs/tags/vid/stage-1 > /dev/null && [ ! -f .vid/SLICE-REPORTS.md ] || fail 'an unmet close recorded something'
st_keep ROW-002
printf 'pull-forward step=S1 decision=D-004 at=2026-10-20T00:00:03Z\n' >> .vid/metrics-events
H=$(git rev-parse --short=12 HEAD); B=$(git rev-parse HEAD:STAGES.md)
sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1 || fail 'the record exited non-zero'
grep -qE "^stage-closed n=1 sha=$H ready rows=2 debt=0 stages-blob=$B at=" .vid/metrics-events || fail 'no stage-closed event with the sha, counts and blob'
[ "$(git cat-file -t vid/stage-1)" = tag ] || fail 'vid/stage-1 is not an annotated tag'
[ "$(git rev-parse --short=12 'vid/stage-1^{commit}')" = "$H" ] || fail 'vid/stage-1 is not at HEAD'
S=$(awk '/^## stage 1 [0-9T:-]+Z$/ { on = 1 } on' .vid/SLICE-REPORTS.md)
[ -n "$S" ] || fail 'no ## stage 1 <UTC> section'
printf '%s\n' "$S" | grep -q -- '- holds (stage 1): 2 requirements, 2 rows, 1 hostility probes, 1 rule rows' || fail 'the section does not say what stage 1 holds'
printf '%s\n' "$S" | grep -q -- '- the full run, stages 1 to 1: .* cases=4 passed=4 failed=0' || fail 'the full run is not counted over stages 1 to 1 only'
# R11: the rows of later stages whose every case passed, from the same receipt
sh checks/stages.sh scope --upto 1 > "$T/s1"; AH=$(sh checks/stages.sh scope --upto 2 | grep '^ROW-' | grep -vxF -f "$T/s1" | grep -vx -e ROW-004 -e ROW-005 | sort | paste -sd ' ' -)
printf ' %s ' "$AH" | grep -q ' ROW-006 ' || fail "the toy gives no later row passing: $AH"
printf '%s\n' "$S" | grep -qxF -- "- passing ahead: $(echo $AH | wc -w | tr -d ' ') rows of later stages ($(echo $AH | sed 's/ /, /g'))" || fail "the section's passing ahead line, not $AH: $(printf '%s\n' "$S" | grep 'passing ahead' || echo none)"
printf '%s\n' "$S" | grep -q -- '- pull-forwards: 1' && printf '%s\n' "$S" | grep -q 'step=S1 decision=D-004' || fail 'the pull-forward is not listed'
printf '%s\n' "$S" | grep -q -- '- next: stage 2, sharing — 2 requirements, 3 rows' || fail 'the section does not say what stage 2 holds'
grep -qx 'stage: 2' .vid/RUN-STATE.md || fail 'RUN-STATE is not at stage: 2'
sh checks/metrics.sh stage-close --stage 1 --record > "$T/out" 2>&1 || true
grep -q 'not recorded — the tag vid/stage-1 already exists' "$T/out" || fail 'a second record of stage 1 was not refused'
[ "$(grep -c '^stage-closed ' .vid/metrics-events)" -eq 1 ] || fail 'a second stage-closed was written'
st_rcpt; st_keep ROW-003 ROW-004 ROW-006
sh checks/metrics.sh stage-close --stage 2 --record > "$T/out" 2>&1 || true
grep -q '^stage-close 2 ready' "$T/out" && grep -q '^recorded: stage-closed n=2 .*no next stage — the final stage' "$T/out" || fail 'the final stage was not recorded (R9)'
git rev-parse -q --verify refs/tags/vid/stage-2 > /dev/null || fail 'the final stage was not tagged (R9)'
awk '/^## stage 2 [0-9T:-]+Z$/ { on = 1 } on' .vid/SLICE-REPORTS.md | grep -qx -- '- passing ahead: 0 rows of later stages' || fail 'the final stage does not say passing ahead: 0'
printf '# Purpose: toy app — REQ-001 REQ-002 REQ-003 REQ-004 REQ-005 — corrected\n' > app/main.py; g commit -qam 'a correction after the final close'
sh checks/metrics.sh > "$T/out" 2>&1 || true
grep -qx "since stage 2's close: 1 commits" "$T/out" && grep -q 'a correction after the final close' "$T/out" || fail 'the commit since the tag is not listed'
exit 0
