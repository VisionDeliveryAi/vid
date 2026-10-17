#!/bin/sh
# Purpose: selftest case — a plan change without its decision arguments
# (v0.9.6.2 spec 3.3, R3; §6 case 9). Under the gate, with an accepted plan,
# an edited block recorded by `plan.sh change` without --trigger, or without
# --expect, is refused: the accepted hash is kept (the last plan-change
# event names it and admission still sees the edit as unrecorded), no
# plan-change event is written, and each attempt leaves a result=refused
# record in .vid/plans/decisions/ with candidate= the edited block's hash and
# the block kept whole beside it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-decision-args: $*" >&2; cat "$T/out" >&2 2>/dev/null; for f in $(recs); do echo "== $f" >&2; cat "$f" >&2; done; exit 1; }
bhash() { sed -n "/^## The plan/,\$p" .vid/RUN-STATE.md | sed -n "/^\`\`\`vid-plan/,/^\`\`\`\$/p" | sed "1d;\$d" | sed "s/[[:space:]]*\$//" | { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; } | cut -c1-12; }
recs() { ls .vid/plans/decisions/*.why 2>/dev/null || true; }
nrec() { recs | grep -c . || true; }
fld() { sed -n "s/^$1=//p" "$2" | head -n 1; }
lasthash() { grep "^plan-change " .vid/metrics-events | tail -n 1 | sed "s/.* hash=\([0-9a-f]*\) .*/\1/"; }
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 | lane: orchestrator (one configuration line)'
S2='step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004 | lane: builder'
SH="shared: $PLANS_SHARED"
OK="--expect"
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; commit_all rows
plan "$S1" "$SH"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'S1 builds first' > "$T/out" 2>&1 || fail 'the first plan was refused'
H1=$(lasthash); NE=$(grep -c . .vid/metrics-events)
plan "$S1" "$S2" "$SH"; HB=$(bhash)
if sh checks/plan.sh change add 'S2 joins' --expect 'S2 follows S1' > "$T/out" 2>&1; then fail 'a change without --trigger was accepted'; fi
grep -q 'refused' "$T/out" || fail 'the refusal does not say so'
if sh checks/plan.sh change add 'S2 joins' --trigger initial > "$T/out" 2>&1; then fail 'a change without --expect was accepted'; fi
[ "$(lasthash)" = "$H1" ] || fail 'the accepted hash moved'
[ "$(grep -c . .vid/metrics-events)" -eq "$NE" ] || fail 'a refused change wrote an event'
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'admission saw the refused edit as recorded'; fi
grep -q 'without a recorded change' "$T/out" || fail 'admission does not name the unrecorded change'
[ "$(nrec)" -eq 3 ] || fail "not three decision records (one accepted, two refused): $(nrec)"
NR=0
for f in $(recs); do
  [ "$(fld result "$f")" = refused ] || continue; NR=$((NR + 1))
  [ "$(fld candidate "$f")" = "$HB" ] || fail "a refused record's candidate is not the edited block's hash"
  [ "$(fld prev "$f")" = "$H1" ] || fail "a refused record's prev= is not the accepted plan"
  fld refusal "$f" | grep -q . || fail 'a refused record carries no refusal='
  P="${f%.why}.plan"; [ -f "$P" ] && grep -q '^step S2 ' "$P" || fail 'the refused candidate block was not kept whole'
done
[ "$NR" -eq 2 ] || fail "not two refused records ($NR)"
exit 0
