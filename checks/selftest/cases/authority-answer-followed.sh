#!/bin/sh
# Purpose: selftest case — the bundle follows the PRD's source: to the owner's answers (v0.9.8 spec 3.3, R5). Convicts
# unless ROW-201's bundle and brief carry A-001 (its item's source:) as its latest, amended row and not A-002, and
# ROW-202's carry A-002; and unless, when the working tree amends REQ-001 to cite a new answer A-003 (the fix's
# append), a test-author brief quotes A-003 and the amended item from the working tree and lists both
# pending-append:, and the check passes it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "authority-answer-followed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
au_repo "$T/repo"
ans() { sh checks/brief.sh authority --row "$1" | sed -n 's/^answer \(A-[0-9]*\) .*/\1/p' | paste -sd ' ' -; }
[ "$(ans ROW-201)" = 'A-001' ] || fail "ROW-201's answers are '$(ans ROW-201)'"
[ "$(ans ROW-202)" = 'A-002' ] || fail "ROW-202's answers are '$(ans ROW-202)'"
w() { CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role test-author --slice 1 --rows "$1" > "$T/out" 2>&1 || fail "the brief for $1 was refused"; sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1; }
[ "$(au_ids "$(w ROW-201)" 15)" = 'A-001' ] || fail 'ROW-201'"'"'s brief does not carry A-001 alone'
# the working tree amends REQ-001 to cite a new answer A-003
printf '\n### Append 2026-10-09 (owner answer)\n\n```vid-prd\nREQ-001 AMENDED | functional | T1 | A link lasts three days. | fail-if: a link works after three days | serves: a stated lifetime | authority: authoritative | source: A-001, A-003 | phase: pilot | plain: a link lasts three days\n```\n\n```vid-prd-answers\nA-003 | human | 2026-10-09 | Q: shorter? | A: three days | settles: REQ-001\n```\n' >> PRD.md
B=$(w ROW-201)
grep -qx 'pending-append: REQ-001 A-003' "$B" || fail "the new answer and the amended item are not listed pending-append: ($(grep '^pending-append' "$B"))"
grep -qx 'A-003 | human | 2026-10-09 | Q: shorter? | A: three days | settles: REQ-001' "$B" || fail 'the new answer is not quoted from the working tree'
sh checks/brief.sh "$B" > "$T/out" 2>&1 || fail 'the check refused the working tree'"'"'s answer listed pending-append:'
exit 0
