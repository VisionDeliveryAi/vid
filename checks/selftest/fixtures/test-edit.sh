# Purpose: selftest fixture — a test file of three row tests, for the
# amendment-5 cases (v0.9.6.1 spec 3.4, revision 11). Sourced after
# gated-run.sh and plan-run.sh (Env: CHECKS, T). edit_repo <dir> makes a
# gated plan repository whose step S1 holds ROW-001..ROW-003, all cited to
# tests/invariants/test_g.py — an import, then test_001, test_002 and
# test_003, four lines each, naming no row — and publishes a receipt r1
# passing all three at that commit. line <n> <text> rewrites line n of
# the file; rcpt_raw <name> <tree-ish> <case id=status …> publishes a
# receipt with the case ids given.
G4FILE=tests/invariants/test_g.py
edit_repo() {
  plan_repo "$1"; rows g 1 3
  { printf 'import os\n'; for _n in 001 002 003; do printf '\ndef test_%s():\n    a = 1\n    b = 2\n    assert a + b\n' "$_n"; done; } > "$G4FILE"
  commit_all rows
  plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-003' "shared: $PLANS_SHARED"
  sh checks/plan.sh change create 'one step' --trigger initial --expect 'the steps build in order' > /dev/null
  rcpt r1 HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed
}
line() { awk -v n="$1" -v t="$2" 'NR == n { print t; next } { print }' "$G4FILE" > "$G4FILE.x" && mv "$G4FILE.x" "$G4FILE"; }
rcpt_raw() {
  _n=$1; _t=$2; shift 2
  mkdir -p .vid/ledger-results
  { printf '<report>\n'; for _kv in "$@"; do printf '<case name="%s" status="%s" time="0.1"/>\n' "${_kv%=*}" "${_kv##*=}"; done; printf '</report>\n'; } > ".vid/ledger-results/$_n"
  sh checks/extractors/results.sh ".vid/ledger-results/$_n" > ".vid/ledger-results/$_n.cases"
  printf 'tree=%s\nbase=%s\nfrozen-at=%s\nshape=inline\n' "$(git rev-parse "$_t^{tree}")" "$(git rev-parse --short=12 "$_t^{commit}")" "$(utcnow)" > ".vid/ledger-results/$_n.tree"
  printf 'ledger-run seconds=1 kind=scoped report=%s status=0 tree=x run=%s at=%s\n' "$_n" "$_n" "$(utcnow)" >> .vid/metrics-events
  sleep 1
}
