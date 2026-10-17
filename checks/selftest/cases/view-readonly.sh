#!/bin/sh
# Purpose: selftest case — read only (v0.9.7.4 spec 3.1, R2). The viewer fixture. Convicts unless a full run,
# a second run and a run with --at leave every file of the project — .git and .vid/ included — byte for byte as
# it was and add none; and unless an --out inside the project is refused, writing nothing. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-readonly: $*" >&2; exit 1; }
view_project "$T/repo"
snap() { (cd "$T/repo" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s\n' "$(git hash-object "$f")" "$f"; done) > "$1"; }
snap "$T/before"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the second run failed"
vview . --out "$T/out" --at "$C_S1" > "$T/r" 2>&1 || fail "the --at run failed"
snap "$T/after"
cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" >&2; fail 'the project changed'; }
if vview . --out "$T/repo/view" > "$T/r" 2>&1; then fail 'an --out inside the project was accepted'; fi
[ ! -e "$T/repo/view" ] || fail 'the refused run wrote into the project'
exit 0
