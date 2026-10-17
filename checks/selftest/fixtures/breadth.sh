# Purpose: selftest fixture — a breadth-first develop run (v0.9.7.2 spec 3.1–3.11), for the breadth cases. Sourced
# after gated-run.sh and plan-run.sh (Env: CHECKS, T). bf_repo <dir> makes the plan fixture's repository, with
# checks/inventory.sh beside its readers, and rows
# ROW-001..ROW-012 (ROW-001..004 cited to test_s1.py, ROW-005..008 to test_s2.py, ROW-009..012 to test_h.py) and a
# PRD.md whose REQ-001 is Tier 1 and REQ-002 Tier 0. derive <row> <REQ…> rewrites a row's derived-from; hostile <HOS id>
# <protects> <test field> adds a hostility row; bf_on sets breadth first in the owner's words; bf_plan <lines…> writes
# the plan block (with the shared line) and records it (create); close <steps> <ROW=status …> publishes a close receipt
# at HEAD and claims it for the steps (`.vid/close/1.rows` empty); verdict <row> <KEPT|BREACHED> [class] [transition]
# records a grader's verdict quoted at HEAD.
bf_repo() {
  plan_repo "$1"
  cp "$CHECKS/inventory.sh" checks/   # the protected rows (plan.sh, metrics.sh read `inventory.sh protected`)
  rows s1 1 4; rows s2 5 8; rows h 9 12
  printf '# PRD\n\n```vid-prd\nREQ-001 | functional | T1 | the toy works\nREQ-002 | functional | T0 | the toy never leaks\n```\n' > PRD.md
  commit_all 'breadth rows'
}
derive() { _r=$1; shift; awk -F'|' -v r="$_r" -v d=" $* " 'BEGIN { OFS = "|" } { id = $1; gsub(/^[ \t]+|[ \t]+$/, "", id) } id == r { $7 = d } { print }' INVENTORY.md > INVENTORY.md.x && mv INVENTORY.md.x INVENTORY.md; }
hostile() { awk -v l="hostility | $1 | attempt | protects: $2 | disable: the toggle | $3" '/^```$/ && !d { print l; d = 1 } { print }' INVENTORY.md > INVENTORY.md.x && mv INVENTORY.md.x INVENTORY.md; }
bf_on() { sh checks/plan.sh strategy breadth-first --by owner --words "${1:-breadth first, core rows first}"; }
bf_plan() { plan "$@" "shared: $PLANS_SHARED"; sh checks/plan.sh change create 'the plan' --trigger initial --expect 'the steps build in order'; }
CLOSEN=0
close() {
  _cs=$1; shift; CLOSEN=$((CLOSEN + 1)); mkdir -p .vid/close; : > .vid/close/1.rows
  _k="$(git rev-parse --short=12 HEAD).run-20260101T0000${CLOSEN}0Z-$CLOSEN.close.xml"
  RCPT_KIND=close rcpt "$_k" HEAD inline "$@"
  sh checks/metrics.sh claim --to ".vid/ledger-results/$_k" --steps "$_cs"
}
verdict() { printf 'verdict slice=1 row=%s result=%s%s%s brief=.vid/briefs/1/grader-1.md quoted-at=%s at=%s\n' "$1" "$2" "${3:+ class=$3}" "${4:+ transition=$4}" "$(git rev-parse HEAD)" "$(utcnow)" >> .vid/metrics-events; }
# the usual three steps: S1 (ROW-001..004), S2 building on S1 (ROW-005..008), H1 a hardening step building on S1 (ROW-009..012)
S1L='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004'
S2L='step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005..ROW-008'
H1L='step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-009..ROW-012 | kind: hardening'
# chg <what> <why> [more arguments]: a plan change with its decision arguments; replan <lines…>: the block rewritten
chg() { _w=$1; _y=$2; shift 2; sh checks/plan.sh change "$_w" "$_y" --trigger unknown --expect 'the plan holds' "$@"; }
replan() { plan "$@" "shared: $PLANS_SHARED"; }
# ss <steps>: the steps' state; keepall <rows…>: a KEPT verdict on each
ss() { sh checks/metrics.sh step-state "$1"; }
keepall() { for _r in "$@"; do verdict "$_r" KEPT; done; }
