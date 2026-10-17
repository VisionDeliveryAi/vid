#!/bin/sh
# Purpose: selftest case — prd.sh join 17, honest labels (v0.9.4 spec §3.4,
# §7 case 6), gated on `grammar: 0.9.4`. Source entries match by prefix.
# From the 0.9.4 known-good fixture, each of these convicts: an
# authoritative item citing `A-005 (AM-15)` where A-005 is a ViD decision
# (model_proposed); an entry exactly `proposal`; a provisional
# owner-decision item citing only `seed`. Each of these acquits: an
# authoritative item citing `SRC-vendor-proposal` (an entry match, not the
# 0.9.3 substring that convicted it); a provisional owner-decision item
# citing `SRC-x`; a provisional measurement item citing the answer that
# deferred its values (measurement is not traced). Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-labels: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
gaps() { printf '%s\n' "$OUT" | grep '^GAP' || true; }
convicts() { # file, wanted GAP substring — one run: default mode prints the gaps and the report line
  run "$1"; [ "$RC" -ne 0 ] || fail "$1 acquitted, expected a conviction ($2)"
  gaps | grep -qF "$2" || { gaps | head -3 >&2; fail "$1 convicted but not for '$2'"; }
}
acquits() { run "$1" ${2:-}; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail "$1 convicted, expected an acquittal"; }; }
cp "$FIXTURES/prd-094-good.md" G.md
acquits G.md
# --- convictions
sed 's/^\(REQ-011 .*\)| source: thesis |/\1| source: thesis, A-005 (AM-15) |/' G.md > AUTHVID.md
grep -q '^REQ-011 .*source: thesis, A-005 (AM-15) |' AUTHVID.md || fail 'the AUTHVID mutation did not apply'
convicts AUTHVID.md 'GAP  join 17 (REQ-011): authoritative but cites A-005 — a ViD decision (model_proposed) grounds at most provisional'
sed 's/^\(REQ-011 .*\)| source: thesis |/\1| source: thesis, proposal |/' G.md > PROP.md
convicts PROP.md "GAP  join 17 (REQ-011): source entry 'proposal' — retired"
sed 's/^\(REQ-006 .*\)| source: A-005 |/\1| source: seed |/' G.md > SEEDONLY.md
grep -q '^REQ-006 .*confirms_via: owner-decision/no | source: seed |' SEEDONLY.md || fail 'the SEEDONLY mutation did not apply'
convicts SEEDONLY.md 'GAP  join 17 (REQ-006): provisional on an owner decision but cites neither a ViD decision (a model_proposed A-NNN) nor a source document (SRC-)'
# --- acquittals
sed 's/^\(REQ-011 .*\)| source: thesis |/\1| source: thesis, SRC-vendor-proposal |/' G.md > VENDOR.md
acquits VENDOR.md
sed 's/^\(REQ-006 .*\)| source: A-005 |/\1| source: SRC-x |/' G.md > SRCX.md
acquits SRCX.md
# MET-001 deferred: provisional on measurement, citing the answer that deferred its thresholds;
# its statement keeps values no cited text states — measurement is not traced.
sed -e 's/^\(MET-001 .*\)| authority: authoritative | source: A-008 |/\1| authority: provisional | confirms_via: measurement\/no | source: A-008 |/' \
    -e 's/^\(A-008 | human | [^|]*| Q: [^|]*| \)A: [^|]*|/\1A: deferred — the thresholds are set at the pilot review |/' G.md > DEFER.md
grep -q '^MET-001 .*confirms_via: measurement/no | source: A-008' DEFER.md && grep -q '^A-008 .*A: deferred — ' DEFER.md || fail 'the DEFER mutation did not apply'
acquits DEFER.md
# the grammar gate: under 0.9.1 the join-17 convictions do not exist (the 0.9.1 join-5 rule still reads authoritative sources)
sed 's/^grammar: 0\.9\.4$/grammar: 0.9.1/' SEEDONLY.md > SEEDONLY091.md
acquits SEEDONLY091.md
sed 's/^grammar: 0\.9\.4$/grammar: 0.9.1/' VENDOR.md > VENDOR091.md
convicts VENDOR091.md 'GAP  join 5 (REQ-011): source: proposal is never authoritative.'
exit 0
