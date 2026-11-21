#!/bin/sh
# Purpose: selftest case — the take-stock reads the folder's stamp (GM-4 K13: a publish into the code repository's folder, ViD's or
# one by hand, read as a hand publish is). On GitHub manual's toy (fixtures/manual.sh) with `layout: one`, `spec-path:
# upstream/vid` and `spec-stamp: STAMP`, no applied version recorded, no published ticket and no --applied: the team's main
# holds upstream/vid/STAMP naming the export X, whose push .vid/tw/log records from the spec's commit. `/vid mode manual` finds
# the applied version from the stamp, `found applied <that commit> — … the stamp upstream/vid/STAMP …`, and asks no --applied;
# the stamp read through github.sh spec-stamp, which prints X. With no stamp file on main it asks --applied, as before. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-spec-stamp: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"
sed 's/^layout: separate$/layout: one/' .vid/tw/settings > "$T/st"; printf 'spec-path: upstream/vid\nspec-stamp: STAMP\n' >> "$T/st"; cp "$T/st" .vid/tw/settings
: > "$T/register"; X=0123456789abcdef0123456789abcdef01234567
printf 'export %s from=%s state=pushed at=2026-11-20T09:00:00Z\n' "$X" "$AP" >> .vid/tw/log
# no stamp on main: --applied asked, as before
mn_switch; [ "$MN_RC" = 5 ] && grep -q '^need --applied' "$T/mo" || fail "with no stamp on main the switch exited $MN_RC, or did not ask --applied"
# the stamp on the team's main, as a publish leaves it
tk_dev 'the spec published into upstream/vid' upstream/vid/STAMP "$X"
RC=0; sh "$CHECKS/github.sh" spec-stamp > "$T/mo" 2>&1 || RC=$?
[ "$RC" = 0 ] && [ "$(cat "$T/mo")" = "$X" ] || fail "github.sh spec-stamp did not print the stamp's export ($RC)"
mn_switch
grep -q "^found applied $AP — .*the stamp upstream/vid/STAMP" "$T/mo" || fail 'the applied version was not found from the folder'"'"'s stamp, named with where it came from'
! grep -q '^need --applied' "$T/mo" || fail 'the switch still asked --applied with the stamp on main'
echo 'mode-spec-stamp: ok'
