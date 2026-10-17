#!/bin/sh
# Purpose: selftest case — metrics.sh test-state, derived and read-only (v0.9.8 spec 3.2, R13; amendment 3: no review
# column). With no attestation ROW-201 reads written=yes passing=yes proven=no; with a current proof, proven=yes; an
# inconclusive proof reads inconclusive, and a later `verdict … class=test proof=` failed; the summary counts each state's yes; test-state writes nothing (the
# progress table's line is pinned by progress-table). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "test-state-derived: $*" >&2; sh checks/metrics.sh test-state >&2 2>&1 || true; exit 1; }
au_repo "$T/repo"; au_stamp; au_ts
printf 'ROW-201\tpass\tr\nROW-202\tred\tx\n' > "$T/states"; VID_EVIDENCE_STATES=$T/states; export VID_EVIDENCE_STATES
[ "$(au_state ROW-201)" = 'written=yes passing=yes proven=no' ] || fail "with nothing attested: $(au_state ROW-201)"
au_attest test-proven ROW-201 proven
[ "$(au_state ROW-201)" = 'written=yes passing=yes proven=yes' ] || fail "a current proof: $(au_state ROW-201)"
au_attest test-proven ROW-202 inconclusive
[ "$(au_state ROW-202)" = 'written=yes passing=red proven=inconclusive' ] || fail "an inconclusive proof: $(au_state ROW-202)"
sh checks/metrics.sh test-state | tail -n 1 | grep -qx 'test-state rows=2 written=2 passing=1 proven=1' || fail "the summary: $(sh checks/metrics.sh test-state | tail -n 1)"
printf 'verdict slice=1 row=ROW-201 result=BREACHED class=test proof=x.proof.sel-1.run-p.xml brief=b quoted-at=x at=2026-10-12T00:00:02Z\n' >> .vid/metrics-events
[ "$(au_state ROW-201)" = 'written=yes passing=yes proven=failed' ] || fail "a failed proof: $(au_state ROW-201)"
cp .vid/metrics-events "$T/ev"; sh checks/metrics.sh test-state > /dev/null; cmp -s .vid/metrics-events "$T/ev" || fail 'test-state wrote to the events'
exit 0
