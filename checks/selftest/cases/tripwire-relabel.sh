#!/bin/sh
# Purpose: selftest case — the slice tripwire counts only new decisions (v0.9.7.3 spec 3.9, R9). A slice during which
# the legacy D-001 is relabelled (`| applies-to: ROW-001` added — the labelling commit) and D-002 is added and named
# under "Decided for you", and D-003 is added and not named: `metrics.sh` flags D-003 only — never D-001, a D-id
# present at the slice's open commit. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "tripwire-relabel: $*" >&2; printf '%s\n' "$OUT" >&2; exit 1; }
mkdir -p checks .vid
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '.vid/\n' > .gitignore
printf '# Decisions\n- **D-001** stored amounts in minor units | why: exactness | enforced: convention\n' > DECISIONS.md
g add -A && g commit -qm root; S0=$(git rev-parse --short=12 HEAD)
sed 's/| enforced: convention$/| enforced: convention | applies-to: ROW-001/' DECISIONS.md > d && mv d DECISIONS.md
printf -- '- **D-002** retries back off | why: load | enforced: convention | scope: project\n- **D-003** one font | why: brand | enforced: convention | scope: project\n' >> DECISIONS.md
g commit -qam 'slice 1: labels and two decisions'; S1=$(git rev-parse --short=12 HEAD)
printf 'slice-open slice=1 sha=%s at=2026-10-13T10:00:00Z\nslice-close slice=1 sha=%s at=2026-10-13T11:00:00Z\n' "$S0" "$S1" > .vid/metrics-events
printf '# Slice summaries\n\n## 2026-10-13T11:00:00Z — slice 1\n\n- **Working now:** x\n- **Went back:** nothing\n- **Decided for you:** retries back off (D-002)\n' > .vid/SUMMARY.md
OUT=$(sh checks/metrics.sh 2>&1 || true)
printf '%s\n' "$OUT" | grep -q 'summary FLAG undisclosed slice=1 id=D-001' && fail 'the relabelled D-001 was flagged'
printf '%s\n' "$OUT" | grep -q 'summary FLAG undisclosed slice=1 id=D-002' && fail 'the named D-002 was flagged'
printf '%s\n' "$OUT" | grep -q 'summary FLAG undisclosed slice=1 id=D-003' || fail 'the unnamed new D-003 was not flagged'
exit 0
