#!/bin/sh
# Purpose: selftest case — the slice summary's tripwires (v0.9.5 spec 3.12,
# R12; §7 case 18). A toy repository with two timed slices and one untimed
# (a pre-0.9.5 slice). Convicts unless `metrics.sh` prints `summary FLAG
# went-back` for "Went back: nothing" beside a recorded regression,
# `summary FLAG undisclosed` for a DECISIONS.md D-NNN and a model_proposed
# PRD answer added during the slice and not named under "Decided for you"
# (and none for one that is named), `summary FLAG missing` for a timed slice
# with no section, and nothing for the untimed slice. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks .vid
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '.vid/\n' > .gitignore
printf '# Decisions\n' > DECISIONS.md
printf '# PRD\n\n```vid-prd-answers\nA-001 | human | 2026-09-01 | Q: x | A: y | settles: REQ-001\n```\n' > PRD.md
g add -A && g commit -qm root; S0=$(git rev-parse --short=12 HEAD)
printf -- '- **D-001** stored amounts in minor units | why: exactness | enforced: convention\n- **D-002** retries back off | why: load | enforced: convention\n' >> DECISIONS.md
sed 's/^```$/A-002 | model_proposed | 2026-09-02 | Q: - | A: seven days | settles: REQ-002\n```/' PRD.md > p && mv p PRD.md
g commit -qam 'slice 1 work'; S1=$(git rev-parse --short=12 HEAD)
cat > .vid/metrics-events <<EV
slice-open slice=1 sha=$S0 at=2026-09-25T10:00:00Z
regressions slice=1 n=2 at=2026-09-25T11:00:00Z
slice-close slice=1 sha=$S1 at=2026-09-25T11:05:00Z
slice-open slice=2 sha=$S1 at=2026-09-25T11:10:00Z
slice-close slice=2 sha=$S1 at=2026-09-25T12:00:00Z
slice-open slice=0 sha=$S0
slice-close slice=0 sha=$S0
EV
cat > .vid/SUMMARY.md <<'SM'
# Slice summaries

## 2026-09-25T11:05:00Z — slice 1

- **Working now:** signing up and the first digest
- **Went back:** nothing
- **Decided for you:**
  - amounts are kept exact to the cent (D-001)
SM
OUT=$(sh checks/metrics.sh 2>/dev/null)
fail() { echo "summary-tripwires: $*" >&2; printf '%s\n' "$OUT" | grep 'summary' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^summary FLAG went-back slice=1 ' || fail 'went-back not flagged'
printf '%s\n' "$OUT" | grep -q '^summary FLAG undisclosed slice=1 id=D-002 ' || fail 'the unnamed D-002 not flagged'
printf '%s\n' "$OUT" | grep -q '^summary FLAG undisclosed slice=1 id=A-002 ' || fail 'the unnamed model_proposed A-002 not flagged'
printf '%s\n' "$OUT" | grep -q 'undisclosed slice=1 id=D-001' && fail 'the named D-001 was flagged'
printf '%s\n' "$OUT" | grep -q 'id=A-001' && fail 'a human answer was flagged'
printf '%s\n' "$OUT" | grep -q '^summary FLAG missing slice=2 ' || fail 'the missing section not flagged'
printf '%s\n' "$OUT" | grep -q 'slice=0' && fail 'an untimed (pre-0.9.5) slice was judged'
[ "$(printf '%s\n' "$OUT" | grep -c '^summary FLAG')" -eq 4 ] || fail 'not exactly four summary FLAGs'
exit 0
