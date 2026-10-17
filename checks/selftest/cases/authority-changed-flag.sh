#!/bin/sh
# Purpose: selftest case — authority changes raise a flag, never a wipe (v0.9.8 spec 3.3, R6). On rows proved red at
# the fixture's commit, `inventory.sh --report` lists nothing (`authority: changed=0`); after an owner answer's text
# changes (A-001 restated), it lists ROW-201 `what=A-001` and not ROW-202; after REQ-001 is amended to cite a new
# answer A-003, `what=` names REQ-001 and A-003; after an amendment that an item's fail-if caused (`amended …
# by=fail-if`) the flag stands. The report writes no event and changes no verdict: the events file is the same
# before and after. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "authority-changed-flag: $*" >&2; VID_COURT_EVENT=off sh checks/inventory.sh --report 2>&1 | tail -n 5 >&2; exit 1; }
au_repo "$T/repo"; cp "$CHECKS/inventory.sh" checks/; g add -A && g commit -qm inventory; au_stamp
[ -z "$(au_flags)" ] || fail "a fresh row is flagged: $(au_flags)"
VID_COURT_EVENT=off sh checks/inventory.sh --report 2>/dev/null | grep -qx 'authority: changed=0' || fail 'no zero count'
au_prd 'three days, counted from creation' > PRD.md; g commit -qam 'A-001 restated'
[ "$(au_flags)" = 'ROW-201 A-001' ] || fail "the restated answer flags '$(au_flags)', not ROW-201 A-001"
mkdir -p .vid; printf 'verdict slice=1 row=ROW-201 result=KEPT class=product brief=b quoted-at=x at=2026-10-01T00:00:00Z\n' >> .vid/metrics-events
cp .vid/metrics-events "$T/ev"; VID_COURT_EVENT=off sh checks/inventory.sh --report > /dev/null 2>&1
cmp -s .vid/metrics-events "$T/ev" || fail 'the report wrote to the events'
printf '\n### Append 2026-10-09 (owner answer)\n\n```vid-prd\nREQ-001 AMENDED | functional | T1 | A link lasts three days. | fail-if: a link works after three days | serves: a stated lifetime | authority: authoritative | source: A-001, A-003 | phase: pilot | plain: a link lasts three days\n```\n\n```vid-prd-answers\nA-003 | human | 2026-10-09 | Q: shorter? | A: three days | settles: REQ-001\n```\n' >> PRD.md
g commit -qam 'REQ-001 amended, A-003'
[ "$(au_flags)" = 'ROW-201 REQ-001,A-001,A-003' ] || fail "the amended item flags '$(au_flags)'"
printf 'amended row=ROW-201 sha=%s by=fail-if at=2026-10-09T00:00:00Z\n' "$(git rev-parse --short=12 HEAD)" >> .vid/metrics-events
[ "$(au_flags)" = 'ROW-201 REQ-001,A-001,A-003' ] || fail "an amendment an item's fail-if caused cleared the flag: '$(au_flags)'"
exit 0
