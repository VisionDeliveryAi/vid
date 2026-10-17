#!/bin/sh
# Purpose: selftest case — a proof goes stale when the row's authority changes (v0.9.8 spec 3.2, R13; amendment 3). A
# current proof of ROW-201 stays proven=yes after a relabel (D-302 moved to applies-to: ROW-201) and reads stale,
# naming A-001, after the owner's answer A-001 is restated. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "test-state-stale-on-authority: $*" >&2; exit 1; }
au_repo "$T/repo"; au_stamp; au_ts
printf 'ROW-201\tpass\tr\n' > "$T/states"; VID_EVIDENCE_STATES=$T/states; export VID_EVIDENCE_STATES
au_attest test-proven ROW-201 proven
au_dec '' 'applies-to: ROW-201' > DECISIONS.md; g commit -qam relabel
[ "$(au_state ROW-201)" = 'written=yes passing=yes proven=yes' ] || fail "a relabel staled it: $(au_state ROW-201)"
au_prd 'three days' > PRD.md; g commit -qam 'A-001 restated'
au_state ROW-201 | grep -q '^written=yes passing=yes proven=stale ' || fail "an answer changed left it: $(au_state ROW-201)"
au_state ROW-201 | grep -q 'proof-stale="authority A-001"' || fail "the reason does not name A-001: $(au_state ROW-201)"
exit 0
