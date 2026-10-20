#!/bin/sh
# Purpose: selftest case — the timeline's bands (v0.26.10.6 spec R7). The viewer fixture (init started and ended,
# develop started, slice 1 closed, S1 started and closed, S2 started) with a stage `fix` started twice and
# ended once, slice 1's open (the fixture holds only its close) and slice 2 opened. Convicts unless each band is as recorded: a stage ended by the next end of its name
# (both of fix's starts end at its one end), develop open; a slice from slice-open to slice-close, slice 2 open; a
# step from its first step-start to its last step-closed, named from the plan, S2 open. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-bands: $*" >&2; exit 1; }
view_project "$T/repo"
vev 11:00 'stage name=fix state=start session=S2 records=26'; vev 11:05 'stage name=fix state=start session=S2 records=26'; vev 11:10 'stage name=fix state=end session=S2'
vev 10:15 'slice-open slice=1 sha=abc'; vev 10:55 'slice-open slice=2 sha=abc'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
B=$(vel "$T/out/now.html" '"bands":[')
for b in '{"kind":"stage","id":"init","name":"init","start":"2026-01-01T09:00:00Z","end":"2026-01-01T10:00:00Z"}' \
  '{"kind":"stage","id":"develop","name":"develop","start":"2026-01-01T10:10:00Z","end":null}' \
  '{"kind":"stage","id":"fix","name":"fix","start":"2026-01-01T11:00:00Z","end":"2026-01-01T11:10:00Z"}' \
  '{"kind":"stage","id":"fix","name":"fix","start":"2026-01-01T11:05:00Z","end":"2026-01-01T11:10:00Z"}' \
  '{"kind":"slice","id":"1","name":null,"start":"2026-01-01T10:15:00Z","end":"2026-01-01T10:50:00Z"}' '{"kind":"slice","id":"2","name":null,"start":"2026-01-01T10:55:00Z","end":null}' \
  '{"kind":"step","id":"S1","name":"Shoppers find things","start":"2026-01-01T10:20:00Z","end":"2026-01-01T10:40:00Z"}' \
  '{"kind":"step","id":"S2","name":"Owners restock","start":"2026-01-01T11:00:00Z","end":null}'; do
  printf '%s' "$B" | grep -qF "$b" || fail "no band $b: $B"
done
exit 0
