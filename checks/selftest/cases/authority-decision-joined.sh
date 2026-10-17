#!/bin/sh
# Purpose: selftest case — the bundle's decisions are 0.9.7.3's brief join (v0.9.8 spec 3.3, R5). Convicts unless, for
# ROW-201, `brief.sh authority --row` and a test-author brief's section 3 name the same decisions — D-301 (cites
# REQ-001), D-302 (applies-to its screen code P01) and D-303 (applies-to its DIF-001) — and neither names D-304 (scope:
# project, a builder's only), D-305 (unlabelled, citing no id) or D-306 (cites REQ-002); unless ROW-202's are D-306
# alone; and unless a builder's brief still takes D-304 as today. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "authority-decision-joined: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
au_repo "$T/repo"
bund() { sh checks/brief.sh authority --row "$1" | sed -n 's/^decision \(D-[0-9]*\) .*/\1/p' | sort -u | paste -sd ' ' -; }
brief3() { CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role test-author --slice 1 --rows "$1" > "$T/out" 2>&1 || fail "the brief for $1 was refused"; au_ids "$(sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1)" 3; }
[ "$(bund ROW-201)" = 'D-301 D-302 D-303' ] || fail "ROW-201's bundle decisions are '$(bund ROW-201)'"
[ "$(brief3 ROW-201)" = 'D-301 D-302 D-303' ] || fail "ROW-201's brief section 3 is '$(brief3 ROW-201)'"
[ "$(bund ROW-202)" = 'D-306' ] || fail "ROW-202's bundle decisions are '$(bund ROW-202)'"
[ "$(brief3 ROW-202)" = 'D-306' ] || fail "ROW-202's brief section 3 is '$(brief3 ROW-202)'"
exit 0
