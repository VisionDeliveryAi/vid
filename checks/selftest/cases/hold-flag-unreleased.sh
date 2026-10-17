#!/bin/sh
# Purpose: selftest case — a hold whose answer came and was never released is flagged (v0.9.8.1 R30, F-19). The
# hold-flags fixture: question 7 gating ROW-001 asked, then answered, and nothing after: closure prints `hold FLAG
# unreleased row=ROW-001 q=7` (not also unqueued). The quiet control: a `reissued row=ROW-001` after the answer
# flags nothing; nor does an answered question gating `all`, which names no row. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; . "$CHECKS/selftest/fixtures/hold-flags.sh"
fail() { echo "hold-flag-unreleased: $*" >&2; sh checks/metrics.sh closure >&2 2>/dev/null; exit 1; }
hf_repo
hf_ev 'question n=7 state=asked gates=ROW-001,app/main.py at=2026-10-02T09:03:00Z'; hf_ev 'question n=7 state=answered at=2026-10-02T09:04:00Z'
[ "$(flags)" = 'hold FLAG unreleased row=ROW-001 q=7' ] || fail "an unreleased hold is not flagged once, as unreleased: $(flags)"
hf_ev 'reissued row=ROW-001 why=A-7 rounds=1 at=2026-10-02T09:05:00Z'
flags | grep -q 'unreleased' && fail 'a hold reissued after its answer is still flagged unreleased'
# held again after its release (two more breaches): a new hold — unqueued, never unreleased by the old answer
S=$(git rev-parse --short=12 HEAD)
hf_ev "verdict slice=3 row=ROW-001 result=BREACHED class=product brief=.vid/briefs/3.md quoted-at=$S at=2026-10-02T09:06:00Z"
hf_ev 'reissued row=ROW-001 why=A-7 rounds=1 at=2026-10-02T09:07:00Z'
hf_ev "verdict slice=4 row=ROW-001 result=BREACHED class=product brief=.vid/briefs/4.md quoted-at=$S at=2026-10-02T09:08:00Z"
[ "$(sh checks/metrics.sh row-state --table | awk -F'\t' '$1 == "ROW-001" { print $5 }')" != - ] || fail 'the fixture row is not held again'
[ "$(flags)" = "hold FLAG unqueued row=ROW-001 reason=$(sh checks/metrics.sh row-state --table | awk -F'\t' '$1 == "ROW-001" { print $5 }')" ] || fail "a hold after its release is not unqueued: $(flags)"
# a question gating all names no row: never "unreleased"
mkdir "$T/b"; cd "$T/b"; hf_repo
hf_ev 'question n=8 state=asked gates=all at=2026-10-02T09:03:00Z'; hf_ev 'question n=8 state=answered at=2026-10-02T09:04:00Z'
flags | grep -q 'unreleased' && fail 'an answered question gating all made a row unreleased'
exit 0
