# Purpose: selftest fixture — the fault proof (v0.9.8 spec 3.4, R4). Sourced after gated-run.sh and plan-run.sh (Env:
# CHECKS, T). pf_repo <dir>: a gated run with rows ROW-001 and ROW-002 in step S1 (tests/invariants/test_s1.py), their
# arguments' cases: lines, a plan whose protected: line names ROW-001, and Q, the commit a grader brief quotes
# ($T/grader.md: role grader, slice 1, quoted-at Q). pf_fault writes $T/fault.patch (app/s1/main.py changed, against Q)
# and prints the tree Q plus that patch makes. pf_rcpt <name> <tree-ish> <shape> <ROW=status …> publishes a proof
# receipt (rcpt). The cases: TGT and CTL, ROW-001's target and control.
pf_repo() {
  plan_repo "$1"; rows s1 1 2
  F=tests/invariants/test_s1.py; TGT="$F::test_001[ROW-001]"; CTL="$F::test_002[ROW-002]"
  printf '# cases: ROW-001 target=%s control=%s\n' "$TGT" "$CTL" >> "$F"; commit_all rows
  plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' 'protected: ROW-001' "shared: $PLANS_SHARED"
  sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
  printf 'step-start step=S1 plan=%s base=%s at=%s\n' "$(sed -n 's/.* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1)" "$(git rev-parse --short=12 HEAD)" "$(utcnow)" >> .vid/metrics-events
  Q=$(git rev-parse HEAD)
  printf 'role: grader    slice: 1\nquoted-at: %s\nreceives: the rows    must not receive: item 7\n' "$Q" > "$T/grader.md"
}
pf_fault() {
  printf '# Purpose: toy module s1\nlimit = None  # the fault: the guard removed\n' > app/s1/main.py
  git diff > "$T/fault.patch"; git checkout -q -- app/s1/main.py
  GIT_INDEX_FILE=$T/fidx git read-tree "$Q" && GIT_INDEX_FILE=$T/fidx git apply --cached "$T/fault.patch" && GIT_INDEX_FILE=$T/fidx git write-tree
}
pf_rcpt() { rcpt "$@"; }
# pf_proof <clean> <red> [<target>]: metrics.sh proof for ROW-001 with the fixture's fault; prints its output
pf_proof() { sh checks/metrics.sh proof --row ROW-001 --brief "$T/grader.md" --fault "$T/fault.patch" --target "${3:-$TGT}" --control "$CTL" --clean "$1" --red "$2" 2>&1; }
# pf_last: ROW-001's latest test-proven result and why
pf_last() { awk '$1 == "test-proven" && $2 == "row=ROW-001" { r = $3 " " $4 } END { print r }' .vid/metrics-events; }
