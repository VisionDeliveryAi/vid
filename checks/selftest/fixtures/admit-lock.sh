# Purpose: selftest fixture — the admission lock (v0.9.8 R16). Sourced after gated-run.sh, plan-run.sh and analyst.sh
# (Env: CHECKS, T). al_repo <dir>: a gated run with ROW-001 and its test. AL is the host's admission lock. al_req: a
# request for ROW-001, its ticket in $K. al_state: the ticket's state now. al_end: waits for the ticket's result.
al_repo() { plan_repo "$1"; rows s1 1 1; commit_all rows; AL="$XDG_RUNTIME_DIR/vid-host/admit.lock"; mkdir -p "$XDG_RUNTIME_DIR/vid-host"; }
al_req() { sh checks/test.sh request --type iterate --role test-author --rows ROW-001 --expect 60 --why 'the lock' -- tests/invariants/test_s1.py > "$T/ask" 2>&1 || { cat "$T/ask" >&2; return 1; }; K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/ask"); }
al_state() { cat ".vid/requests/$K/state" 2>/dev/null; }
al_end() { VID_WAIT_MAX=90 sh checks/test.sh wait "$K" > "$T/res" 2>&1 || true; }
