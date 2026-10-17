#!/bin/sh
# Purpose: selftest case — one evidence reader (v0.9.7.4 spec 3.2, R4). The viewer fixture, its run active. Convicts
# unless every promise's state and detail at now equal what `sh checks/evidence.sh rows --at HEAD` prints when run in
# the project with the same map (every INVENTORY row, its step from the plan, no paths). Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-parity: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
sh checks/plan.sh parse .vid/plans/$(sed -n 's/^plan-change .*hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1).plan | awk -F'\t' '$1 == "row" { print $2 "\t" $3 "\t" }' > "$T/map"
sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md | awk -F'|' '$1 ~ /ROW-/ { id = $1; gsub(/[ \t]/, "", id); print id }' | while IFS= read -r r; do grep -q "^$r	" "$T/map" || printf '%s\t-\t\n' "$r" >> "$T/map"; done
sh checks/evidence.sh rows --at HEAD --map "$T/map" | LC_ALL=C sort > "$T/project"
[ "$(grep -c . "$T/project")" = 7 ] || fail "the project's reader read $(grep -c . "$T/project") rows, not 7"
vdata "$T/out/now.html" | sed -n 's/^\("promises":\[\)\{0,1\}{"id":"\(ROW-[0-9]*\)",.*"state":"\([^"]*\)","stateDetail":"\([^"]*\)".*/\2	\3	\4/p' | LC_ALL=C sort > "$T/viewer"
cmp -s "$T/project" "$T/viewer" || { diff "$T/project" "$T/viewer" >&2; fail 'the viewer'"'"'s states differ from the project'"'"'s reader'; }
exit 0
