#!/bin/sh
# Purpose: selftest case — milestones, found from records and git (v0.9.7.4 spec 3.3, R5). The viewer fixture, plus
# a second step closed at S1's moment (one close of two steps) and a repeated slice-close line. Convicts unless the
# index lists exactly the fixture's moments, oldest first — two ratifications at their own commits, setup done and
# building started at the documents commit (the last first-parent commit by then), "Steps S1, S2 closed" as one
# snapshot at the S1 commit, slice 1 closed once, checkpoint 1 at the S2 commit, then now at HEAD. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-milestones: $*" >&2; exit 1; }
view_project "$T/repo"
printf 'step-closed step=S2 report=r1 at=%s\nslice-close slice=1 sha=x at=%s\n' "$(vt 10:40)" "$(vt 10:50)" >> .vid/metrics-events
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
s7() { git rev-parse --short=7 "$1"; }
vdata "$T/out/index.html" | sed -n 's/.*"snapshots":\[\(.*\)\]},$/\1/p' | awk '{ gsub(/\},\{"label"/, "}\n{\"label\""); print }' | sed 's/^{"label":"\([^"]*\)","moment":{"commit":"\([^"]*\)","time":"\([^"]*\)"},"milestones":\[[^]]*\],"file":"\([^"]*\)".*/\1|\2|\3|\4/' > "$T/got"
cat > "$T/want" <<W
PRD ratified (thesis+contract)|$(s7 "$C_R1")|2026-01-01T09:10:00Z|20260101T091000Z-prd-ratified.html
PRD ratified (final)|$(s7 "$C_R2")|2026-01-01T09:20:00Z|20260101T092000Z-prd-ratified.html
Setup done|$(s7 "$C_DOCS")|2026-01-01T10:00:00Z|20260101T100000Z-setup-done.html
Building started|$(s7 "$C_DOCS")|2026-01-01T10:10:00Z|20260101T101000Z-building-started.html
Steps S1, S2 closed|$(s7 "$C_S1")|2026-01-01T10:40:00Z|20260101T104000Z-step-closed.html
Slice 1 closed|$(s7 "$C_S1")|2026-01-01T10:50:00Z|20260101T105000Z-slice-closed.html
Checkpoint 1|$(s7 "$C_LATE")|2026-01-01T11:20:00Z|20260101T112000Z-checkpoint.html
W
head -n 7 "$T/got" | cmp -s - "$T/want" || { diff "$T/want" "$T/got" >&2; fail 'the snapshots differ'; }
sed -n 8p "$T/got" | grep -q "^Now|$(s7 "$C_HEAD")|.*|now.html$" || fail "now is not last at HEAD: $(sed -n 8p "$T/got")"
[ "$(grep -c . "$T/got")" = 8 ] || fail "$(grep -c . "$T/got") snapshots, not 8"
exit 0
