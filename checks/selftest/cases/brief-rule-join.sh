#!/bin/sh
# Purpose: selftest case — the RULE join (v0.9.7.1 spec 3.2e, R2). The brief-write fixture with bw_builder (rules
# RULE-001 origin REQ-004, RULE-002 origin REQ-0041, RULE-003 no origin) and three decisions citing only a rule:
# D-301 RULE-001, D-302 RULE-003, D-303 RULE-002. Convicts unless a builder brief for S2 (ROW-104, REQ-004)
# quotes D-301 (its rule applies), not D-302 (unrelated; before 0.9.7.1 the safe rule kept it for citing no
# ROW or REQ id), and D-303 when named by --decisions. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-rule-join: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
printf -- '- **D-301** deletion tokens are compared in constant time (RULE-001) | why: timing | enforced: convention\n- **D-302** atomic writes use a rename (RULE-003) | why: crash safety | enforced: convention\n- **D-303** limits count code points (RULE-002) | why: one count | enforced: convention\n' >> DECISIONS.md
g add -A && g commit -qm rules
sec3() { awk '/^## [0-9]/ { on = ($2 == 3); next } on' "$1"; }
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the builder brief was refused'
B=$(bw_out)
sec3 "$B" | grep -q 'D-301' || fail 'the relevant RULE-only decision is not quoted'
sec3 "$B" | grep -q 'D-302' && fail 'an unrelated RULE-only decision is quoted'
sec3 "$B" | grep -q 'D-303' && fail 'a RULE-only decision of another item is quoted unnamed'
bw_write --role builder --slice 2 --step S2 --rows ROW-104 --decisions D-303 || fail 'the brief naming D-303 was refused'
sec3 "$(bw_out)" | grep -q 'D-303' || fail 'a RULE-only decision named by --decisions is not quoted'
exit 0
