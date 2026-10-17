#!/bin/sh
# Purpose: selftest case — a candidate block that does not parse (v0.9.6.2
# spec 3.3, R3; §6 case 11). Under the gate, a block with a line that does
# not parse, recorded with full decision arguments, is refused: a
# result=refused record is written with candidate= the hash of the raw
# block (taken before validation), refusal= naming the block, and the raw
# block kept whole as <id>.plan; no plan-change event, the hash kept.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-decision-unparsed: $*" >&2; cat "$T/out" >&2 2>/dev/null; for f in $(recs); do echo "== $f" >&2; cat "$f" >&2; done; exit 1; }
bhash() { sed -n "/^## The plan/,\$p" .vid/RUN-STATE.md | sed -n "/^\`\`\`vid-plan/,/^\`\`\`\$/p" | sed "1d;\$d" | sed "s/[[:space:]]*\$//" | { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; } | cut -c1-12; }
recs() { ls .vid/plans/decisions/*.why 2>/dev/null || true; }
nrec() { recs | grep -c . || true; }
fld() { sed -n "s/^$1=//p" "$2" | head -n 1; }
lasthash() { grep "^plan-change " .vid/metrics-events | tail -n 1 | sed "s/.* hash=\([0-9a-f]*\) .*/\1/"; }
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 | lane: orchestrator (one configuration line)'
S2='step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004 | lane: builder'
SH="shared: $PLANS_SHARED"
OK="--expect"
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
plan "$S1" "$SH"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'S1 builds first' > "$T/out" 2>&1 || fail 'the first plan was refused'
H1=$(lasthash); NE=$(grep -c . .vid/metrics-events)
plan "$S1" 'this line is not a step' "$SH"; HB=$(bhash)
if sh checks/plan.sh change other 'a note' --trigger unknown --expect 'nothing moves' > "$T/out" 2>&1; then fail 'a block that does not parse was accepted'; fi
F=$(grep -l '^result=refused' $(recs))
[ -n "$F" ] || fail 'no refused record'
[ "$(fld candidate "$F")" = "$HB" ] || fail 'candidate= is not the raw block'"'"'s hash'
fld refusal "$F" | grep -q 'does not hold' || fail 'refusal= does not name the block'
grep -qx 'this line is not a step' "${F%.why}.plan" || fail 'the raw block was not kept'
case "$(basename "$F")" in *-"$HB".why) ;; *) fail 'the decision id does not end in the candidate hash' ;; esac
[ "$(lasthash)" = "$H1" ] && [ "$(grep -c . .vid/metrics-events)" -eq "$NE" ] || fail 'the refusal moved the hash or wrote an event'
exit 0
