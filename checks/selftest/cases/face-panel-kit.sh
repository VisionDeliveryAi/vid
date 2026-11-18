#!/bin/sh
# Purpose: selftest case — ViD's face, the panel (0.26.10.29, R8 to R27 as the test kit can see them): runs the panel's
# own tests, hooks/face/register.test.tsx, with Claude Code's test kit (claude plugin test), drawing as the desktop
# app does. Gated on the plugin's hooks/face/ beside checks/ (a project keeps no copy) and on a claude on PATH.
# Convicts unless the kit reports every test passed and none failed. Env: CHECKS.
set -eu
P=$(cd "$CHECKS/.." && pwd -P)
[ -f "$P/hooks/face/register.test.tsx" ] || { echo 'needs the plugin'"'"'s hooks/face/'; exit 77; }
command -v claude >/dev/null 2>&1 || { echo 'needs claude on PATH for its test kit'; exit 77; }
fail() { echo "face-panel-kit: $*" >&2; exit 1; }
set +e; OUT=$(cd "$P" && claude plugin test "$P" 2>&1 < /dev/null); RC=$?; set -e
p=$(printf '%s\n' "$OUT" | sed -n 's/^ *\([0-9][0-9]*\) pass$/\1/p' | tail -1)
f=$(printf '%s\n' "$OUT" | sed -n 's/^ *\([0-9][0-9]*\) fail$/\1/p' | tail -1)
[ "$RC" = 0 ] && [ "${f:-x}" = 0 ] && [ "${p:-0}" -ge 20 ] || { printf '%s\n' "$OUT" | grep -E '^\(fail\)|^  ' | head -12 >&2; fail "the kit: exit $RC, ${p:-?} passed, ${f:-?} failed"; }
echo "face-panel-kit: $p passed"
