#!/bin/sh
# Purpose: selftest case — where everything is (v0.26.10.2 spec R14). The viewer fixture with view_arch and files
# app/s1/deep/x.py (a nested module), web/src/pages/home.js (a /src/ layout) and notes/plan.txt (no module's). Convicts
# unless each module's files are the paths the import court gives it: app/s1 keeps main.py only, app/s1/deep has
# x.py, web has home.js through its src segment, and no module has README.md or notes/plan.txt. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-files: $*" >&2; exit 1; }
view_project "$T/repo"; mkdir -p app/s1/deep web/src/pages notes
printf 'x\n' > app/s1/deep/x.py; printf 'x\n' > web/src/pages/home.js; printf 'x\n' > notes/plan.txt; view_arch 11:40
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
vmod "$N" app/s1 | grep -qF '"files":["app/s1/main.py"]' || fail "app/s1's files are not its own: $(vmod "$N" app/s1)"
vmod "$N" app/s1/deep | grep -qF '"files":["app/s1/deep/x.py"]' || fail "the nested module's file is not its own: $(vmod "$N" app/s1/deep)"
vmod "$N" web | grep -qF '"files":["web/src/pages/home.js"]' || fail "the /src/ layout is not web's: $(vmod "$N" web)"
varch "$N" | grep -q 'README.md\|notes/plan.txt' && fail 'a file no module owns is given to one'
exit 0
