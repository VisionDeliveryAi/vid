#!/bin/sh
# Purpose: selftest case — older projects (v0.9.7.4 spec R11). The viewer fixture with its checks/records-version at
# 9, then with none. Convicts unless both runs succeed and make every page, each passing the check, and each page's
# data says the panels its records predate are not recorded: delegated and built at 9 (below 19 and 10), the same
# with no version; and unless a records-19 project says none. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-old-records: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/o19" > "$T/r" 2>&1 || fail "the run at 19 failed: $(cat "$T/r")"
vdata "$T/o19/now.html" | grep -q '"notRecorded":\[\]' || fail 'a records-19 project reports panels not recorded'
printf 'records: 9\n' > checks/records-version; g add -A; vcommit 11:40 'an older checks/'
vview . --out "$T/o9" > "$T/r" 2>&1 || fail "the run at 9 failed: $(cat "$T/r")"
g rm -q checks/records-version; vcommit 11:41 'no records version'
vview . --out "$T/o0" > "$T/r" 2>&1 || fail "the run with no version failed: $(cat "$T/r")"
for o in o9 o0; do
  [ "$(ls "$T/$o" | grep -c '\.html$')" = 9 ] || fail "$o: not every page was made"
  for f in "$T/$o"/*.html; do sh "$VIEWER_SH" --check "$f" > "$T/c" 2>&1 || fail "$o/$(basename "$f") fails the check: $(cat "$T/c")"
    vdata "$f" | grep -q '"notRecorded":\["delegated","built"\]' || fail "$o/$(basename "$f") does not say delegated and built are not recorded"; done
done
vdata "$T/o0/now.html" | grep -q '"records":null' || fail 'a project with no version does not read records as null'
exit 0
