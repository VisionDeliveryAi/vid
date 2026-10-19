#!/bin/sh
# Purpose: selftest case — the system picture's arrangement (v0.26.10.2 spec R3). The viewer fixture with its own
# module table: a (none may use it), b (a and c may use it), c (b), d (itself and e), e (d), f (all). Convicts unless
# a is at level 0, b at 1, c at 2 (the shortest way down through the b–c cycle), f in the band open to every module,
# and d and e unplaced (reached from no level, d's own name ignored, so d is not at level 0). Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-placement: $*" >&2; exit 1; }
view_project "$T/repo"
printf '# Architecture\n\n| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| a | top | none | none | none |\n| b | middle | none | `b` | a, c |\n| c | lower | none | `c` | b |\n| d | loop | none | `d` | d, e |\n| e | loop | none | `e` | d |\n| f | kernel | none | `f` | all |\n' > ARCHITECTURE.md
g add -A; vcommit 11:40 'the module table'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
pl() { vmod "$N" "$1" | grep -qF "\"placement\":\"$2\",\"level\":$3," || fail "$1 is not $2 $3: $(vmod "$N" "$1")"; }
pl a level 0; pl b level 1; pl c level 2; pl f open-to-all null; pl d unplaced null; pl e unplaced null
exit 0
