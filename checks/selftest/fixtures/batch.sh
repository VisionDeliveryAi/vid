# Purpose: selftest fixture — a toy develop run closing a step as a close batch (v0.9.7.0.12 spec
# 3.2–3.6, R2–R6). Sourced after gated-run.sh and plan-run.sh (Env: CHECKS, T). batch_repo <dir>
# makes the plan repository with S1 (ROW-001, ROW-002) closed on a receipt where both pass and S2
# (ROW-003, ROW-004; builds on S1) started, an empty rows file, and a budget of two proved
# environments at chunk-seconds=1 (each group its own chunk); the compose stub answers each
# selection word with one case named by it (STUB_BYSEL). w <step> <n> is the word for ROW-00<n>'s
# case; groups <file> <n…> writes one group per row; batch <extra request arguments…> asks the
# close batch of S2 (phase files $T/p1 and $T/p2) and sets TK; bwait waits until it ends (exit
# its exit status); chunkdir <n> is a chunk's sub-ticket.
batch_repo() {
  plan_repo "$1"; rows s1 1 2; rows s2 3 4; commit_all rows
  plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' "shared: $PLANS_SHARED"
  sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
  _ph=$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1); _h0=$(git rev-parse --short=12 HEAD)
  for _st in S1 S2; do printf 'step-start step=%s plan=%s base=%s at=%s\n' "$_st" "$_ph" "$_h0" "$(utcnow)" >> .vid/metrics-events; done
  rcpt r1 HEAD inline ROW-001=passed ROW-002=passed
  printf 'step-closed step=S1 report=r1 at=%s\n' "$(utcnow)" >> .vid/metrics-events
  mkdir -p .vid/close; : > .vid/close/1.rows
  printf 'stacks=2\ntestenv=proved harness=%s\nchunk-seconds=1\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
  export STUB_BYSEL=1
}
w() { printf 'tests/invariants/test_s%s.py::test_00%s[ROW-00%s]' "$1" "$2" "$2"; }
groups() { _gf=$1; shift; : > "$_gf"; for _n in "$@"; do _s=2; [ "$_n" -le 2 ] && _s=1; printf 'ROW-00%s | %s |\n' "$_n" "$(w "$_s" "$_n")" >> "$_gf"; done; }
# v0.9.7.3 (R7, found by the full self-test): a toy chunk's estimate is 1 s and its cap 2 s, which a loaded host
# overruns — a capped chunk is retried and counts one run more; the cap is scaled out unless a case sets its own
# (batch-retry sets VID_CAP_SCALE=1 where the cap is what it tests)
batch() { VID_CAP_SCALE=${VID_CAP_SCALE:-100} sh checks/test.sh request --type close --role orchestrator --steps S2 --batch --phase1 "$T/p1" --phase2 "$T/p2" --why 'close S2' "$@" > "$T/req" 2>&1 || return 1
  TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/req"); }
# bwait: the wait repeated until the batch ends — on its state, not a time: v0.9.7.3 (R7) bounds it at 400 tries
# (about 20 minutes), only so a hung batch cannot hang the suite
bwait() { _i=0; while [ "$_i" -lt "${1:-400}" ]; do _rc=0; VID_WAIT_MAX=3 sh checks/test.sh wait "$TK" > "$T/wait" 2>&1 || _rc=$?; [ "$_rc" -eq 75 ] || return "$_rc"; _i=$((_i + 1)); done; return 75; }
chunkdir() { printf '.vid/requests/%s/chunks/%s\n' "$TK" "$1"; }
