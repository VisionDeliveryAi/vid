#!/bin/sh
# Purpose: selftest case — a gated run publishes to the run's home (v0.9.6
# spec 3.6, 3.7.4, R6, R7; §7 case 10), for both kinds of home. The
# orchestrator runs in a LINKED worktree W (its RUN-STATE there, Git's main
# checkout holding none): its full run's kept receipt, the commit-named
# copy, the event and the run folder all land in W, the unchanged row
# engine there (`metrics.sh receipt`) finds the copy, and nothing is
# written to the main checkout's .vid/. A builder worktree B that ran
# `plan.sh home --brief <its brief in W>` publishes its scoped run into
# W's .vid/ as well, its run folder at W, nothing under B's own
# ledger-results. `plan.sh home` refuses a brief whose worktree holds no
# run. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "publish-home: $*" >&2; cat "$T"/out* >&2 2>/dev/null; exit 1; }
gated_repo "$T/main"
cp "$CHECKS/metrics.sh" checks/
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)".*/case \\1 \\2 0.1/p'"'"' "$1"\n' > checks/extractors/results.sh
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | x | anon | - | x | REQ-001 | tests/invariants/t.py\n```\n' > INVENTORY.md
mkdir -p tests/invariants && printf '# ROW-001\n' > tests/invariants/t.py
g add -A && g commit -qm 'a row and a reader'
g worktree add -q "$T/W" -b orch 2>/dev/null
g worktree add -q "$T/B" -b builder 2>/dev/null
cd "$T/W"; mkdir -p .vid; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
SHA=$(git rev-parse --short=12 HEAD)
sh checks/test.sh --role close > "$T/out.w" 2>&1 || fail 'the orchestrator full run failed'
R=$(kept); printf '%s\n' "$R" | grep -qE "^$SHA\.run-.*\.full\.xml\$" || fail "no kept full receipt in W: $R"
[ -f ".vid/ledger-results/$SHA.full.xml" ] || fail 'no commit-named copy in W'
grep -q "^ledger-run .* report=$R " .vid/metrics-events || fail "W's event does not name its receipt"
[ "$(sh checks/metrics.sh receipt)" = "receipt=.vid/ledger-results/$SHA.full.xml deployed=none-declared" ] || { sh checks/metrics.sh receipt >&2; fail 'the row engine in W does not find the copy'; }
[ ! -e "$T/main/.vid/ledger-results" ] || [ -z "$(ls "$T/main/.vid/ledger-results")" ] || fail 'the main checkout received a receipt'
[ ! -e "$T/main/.vid/runs" ] || fail 'the main checkout received a run folder'
[ ! -e "$T/main/.vid/metrics-events" ] || fail 'the main checkout received an event'
# the builder worktree
mkdir -p .vid/briefs/1; printf 'role: builder    slice: 1\n' > .vid/briefs/1/builder-1.md
cd "$T/B"
if sh checks/plan.sh home --brief "$T/main/checks/test.sh" > "$T/out.h" 2>&1; then fail 'a brief outside any run was accepted as a home'; fi
sh checks/plan.sh home --brief "$T/W/.vid/briefs/1/builder-1.md" > "$T/out.h" 2>&1 || fail 'plan.sh home refused the brief'
[ "$(cat .vid/home)" = "$(cd "$T/W" && git rev-parse --show-toplevel)" ] || fail ".vid/home does not name W: $(cat .vid/home)"
[ "$(sh checks/plan.sh gate | cut -d' ' -f1)" = on ] || fail 'the gate is off in the builder worktree'
printf 'main v2 by the builder\n' > app/main.py
sh checks/test.sh --role builder -- 'tests/x' > "$T/out.b" 2>&1 || fail 'the builder scoped run failed'
cd "$T/W"
N=$(kept | grep -c '\.live\.sel-'); [ "$N" -eq 1 ] || fail "the builder's receipt is not in W ($N)"
grep -q '^ledger-run .* kind=scoped .* role=builder ' .vid/metrics-events || fail "the builder's event is not in W"
grep 'up --build' "$STUB_LOG" | grep -q "^B|vid-s1-b|$(cd "$T/W" && git rev-parse --show-toplevel)/.vid/runs/" || fail "the builder's run folder is not at W"
grep -q 'ctx-main=main v2 by the builder' "$STUB_LOG" || fail "the builder's run did not freeze the builder's tree"
[ ! -e "$T/B/.vid/ledger-results" ] || [ -z "$(ls "$T/B/.vid/ledger-results")" ] || fail 'the builder worktree kept a receipt'
exit 0
