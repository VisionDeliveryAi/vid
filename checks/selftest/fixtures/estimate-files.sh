# Purpose: selftest fixture — kept receipts with case seconds for the whole-file estimate cases (v0.9.8.1 R26).
# Sourced after gated-run.sh, in the gated repository (Env: T). ef_hist <receipt> <shape> <event seconds>
# <case id>=<seconds> …: a kept receipt's .cases (every case passed), its .tree carrying shape=, and its ledger-run
# event. ef_req <why> <request arguments…>: an iterate request for ROW-001, its output in $T/out (refusal fails).
ef_hist() { _n=$1; _sh=$2; _s=$3; shift 3; mkdir -p .vid/ledger-results
  for _kv in "$@"; do printf 'case %s passed %s\n' "${_kv%=*}" "${_kv##*=}"; done > ".vid/ledger-results/$_n.cases"
  printf 'tree=x\nbase=x\nfrozen-at=x\nshape=%s\n' "$_sh" > ".vid/ledger-results/$_n.tree"
  printf 'ledger-run seconds=%s kind=scoped report=%s status=0 role=builder at=%s\n' "$_s" "$_n" "$(utcnow)" >> .vid/metrics-events; }
ef_req() { _w=$1; shift; sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "$_w" "$@" > "$T/out" 2>&1 || fail "the request '$_w' was refused"; }
