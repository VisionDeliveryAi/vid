#!/bin/sh
# Purpose: selftest case — a request outside the gate publishes at its home (v0.26.10.7 spec R6, F-58; §5
# request-home). Develop paused and the fix stage newest (the gate off): a fixer worktree that ran `plan.sh home
# --brief` makes an iterate request; its ticket, its frozen receipt with .tree and .cases, and its event are at the
# project, nothing under the worktree's own ledger-results; `brief.sh return` at the project credits the row on that
# receipt. A direct `sh checks/test.sh` run outside the gate behaves as today: a live-tree receipt, no .tree, no run
# folder. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "request-home: $*" >&2; cat "$T"/out* >&2 2>/dev/null; exit 1; }
gated_repo "$T/main"
for c in metrics.sh brief.sh evidence.sh event.sh prd.sh; do cp "$CHECKS/$c" checks/; done
mkdir -p checks/extractors tests/invariants
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)".*/case \\1 \\2 0.1/p'"'"' "$1"\n' > checks/extractors/results.sh
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | x | anon | - | x | REQ-001 | tests/invariants/t.py\n```\n' > INVENTORY.md
printf '# ROW-001\n' > tests/invariants/t.py
g add -A && g commit -qm 'a row and a reader'
gate_on 'stopped owner asked to pause'
printf 'stage name=fix state=start session=S2 records=27 at=%s\n' "$(utcnow)" >> .vid/metrics-events
if sh checks/plan.sh gate > "$T/out.g" 2>&1; then fail 'the gate is on with develop paused and the fix stage newest'; fi
Q=$(git rev-parse HEAD)
mkdir -p .vid/briefs/1
printf 'role: fixer    slice: 1\nquoted-at: %s\nskill: vid-build\ntry: 1-fixer-1\nbranch: vid/1-fixer-1\n\n## 1 rows\n\nROW-001 | x\n' "$Q" > .vid/briefs/1/fixer-1.md
g worktree add -q "$T/F" -b vid/1-fixer-1 2>/dev/null
cd "$T/F"
sh checks/plan.sh home --brief "$T/main/.vid/briefs/1/fixer-1.md" > "$T/out.h" 2>&1 || fail 'plan.sh home refused the brief'
printf 'main v2 by the fixer\n' > app/main.py; g commit -qam 'the fix'
sh checks/test.sh request --type iterate --role fixer --try 1-fixer-1 --rows ROW-001 --why 'the fix' -- tests/invariants/t.py > "$T/out.r" 2>&1 || fail 'the request was refused'
K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out.r")
[ -d "$T/main/.vid/requests/$K" ] || fail "the ticket $K is not at the project"
[ ! -d ".vid/requests/$K" ] || fail 'the ticket is in the fixer worktree'
VID_WAIT_MAX=60 sh checks/test.sh wait "$K" > "$T/out.w" 2>&1 || fail 'the request did not run green'
[ ! -e .vid/ledger-results ] || [ -z "$(ls .vid/ledger-results)" ] || fail 'the fixer worktree kept a receipt'
grep -q 'ctx-main=main v2 by the fixer' "$STUB_LOG" || fail "the run did not freeze the fixer's tree"
cd "$T/main"
R=$(kept | grep '\.live\.sel-' || true)
[ "$(printf '%s\n' "$R" | grep -c .)" -eq 1 ] || fail "no one frozen receipt at the project: $R"
[ -f ".vid/ledger-results/$R.tree" ] && [ -f ".vid/ledger-results/$R.cases" ] || fail 'the receipt has no .tree or .cases'
grep -q "^ledger-run .* report=$R .*role=fixer tree=.* run=" .vid/metrics-events || fail "the project's events do not name the receipt with tree= and run="
printf 'brief: .vid/briefs/1/fixer-1.md\nagent: a1\nbranch: vid/1-fixer-1\ncommit: %s\nROW-001 | pass | %s\n' "$(git -C "$T/F" rev-parse HEAD)" "$R" > .vid/briefs/1/fixer-1.return.md
sh checks/brief.sh return .vid/briefs/1/fixer-1.return.md > "$T/out.ret" 2>&1 || fail 'brief.sh return refused the receipt at the project'
grep -q 'rows-passed=1' "$T/out.ret" || fail 'the return did not credit ROW-001'
# a direct run outside the gate: as today
unset VID_REQUEST 2>/dev/null || true
NR0=$(ls .vid/runs 2>/dev/null | grep -c . || true)
sh checks/test.sh --role fixer -- tests/x > "$T/out.d" 2>&1 || fail 'the direct run failed'
L=$(ls .vid/ledger-results | grep -E '\.live\.sel-[0-9]+\.xml$' || true)
[ -n "$L" ] || fail 'the direct run left no live-tree receipt'
[ ! -f ".vid/ledger-results/$L.tree" ] || fail 'the direct run took the frozen path'
grep -q "^ledger-run .* report=$L .*form=legacy" .vid/metrics-events || fail 'the direct run is not recorded as a plain call'
exit 0
