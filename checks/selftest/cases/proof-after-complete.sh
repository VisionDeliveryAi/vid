#!/bin/sh
# Purpose: selftest case — a fault proof after completion lands at the run's home (FIX-BATCH-T1 §3, B-3). The proof
# fixture, the run then `run: complete` (the gate off everywhere, no live run to discover). As vid-verify's fault proof
# says: a proof worktree at the brief's quoted-at, its home recorded (`plan.sh home --brief <the grader brief>`), the
# baseline and the faulted run requested from it with --purpose proof → each ticket and proof receipt (.tree, .cases) at
# the home, none in the worktree, and `metrics.sh proof` at the home reads `result=proven`. Without the home step (the
# control) the ticket stays in the worktree: the fault. And, where the skills are, vid-verify's step 1 names the home
# step. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; cd /; git -C "$T/repo" worktree remove --force "$T/repo/.vid/proofs/ROW-001" 2>/dev/null; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
. "$CHECKS/selftest/fixtures/proof.sh"
fail() { echo "proof-after-complete: $*" >&2; cat "$T/ask" "$T/res" "$T/out" >&2 2>/dev/null; exit 1; }
pf_repo "$T/repo"; HM=$(pwd -P)
mkdir -p .vid/briefs/1; cp "$T/grader.md" .vid/briefs/1/grader-1.md; GB=$HM/.vid/briefs/1/grader-1.md
pf_fault > /dev/null
sed 's/^run:.*/run: complete/' .vid/RUN-STATE.md > "$T/rs" && cp "$T/rs" .vid/RUN-STATE.md
if sh checks/plan.sh gate > "$T/out" 2>&1; then fail 'the gate is on after run: complete'; fi
report "$T/clean" "$TGT=passed:1" "$CTL=passed:1"
report "$T/red" "$TGT=failed:1" "$CTL=passed:1"
# the control: no home step — the ticket stays in the throwaway worktree
git worktree add -q --detach .vid/proofs/ROW-001 "$Q"
cd .vid/proofs/ROW-001
K0=$(ask "$T/clean" --type prove-red --role orchestrator --purpose proof --rows ROW-001 --why 'the baseline, no home' -- "$TGT" "$CTL") || fail 'the control request was refused'
[ -d ".vid/requests/$K0" ] && [ ! -d "$HM/.vid/requests/$K0" ] || fail 'without the home step the ticket did not stay in the worktree (the cause is not shown)'
cd "$HM"; git worktree remove --force .vid/proofs/ROW-001
# as vid-verify says: the worktree, its home recorded, the two runs
git worktree add -q --detach .vid/proofs/ROW-001 "$Q"
cd .vid/proofs/ROW-001
sh checks/plan.sh home --brief "$GB" > "$T/out" 2>&1 || fail 'plan.sh home refused the grader brief after run: complete'
K1=$(ask "$T/clean" --type prove-red --role orchestrator --purpose proof --rows ROW-001 --why 'the baseline' -- "$TGT" "$CTL") || fail 'the baseline was refused'
git apply "$T/fault.patch" || fail 'the patch did not apply'
K2=$(ask "$T/red" --type prove-red --role orchestrator --purpose proof --rows ROW-001 --why 'the faulted run' -- "$TGT" "$CTL") || fail 'the faulted run was refused'
for k in "$K1" "$K2"; do [ -d "$HM/.vid/requests/$k" ] && [ ! -d ".vid/requests/$k" ] || fail "the ticket $k is not at the home"; done
[ ! -d .vid/ledger-results ] || [ -z "$(ls .vid/ledger-results)" ] || fail 'the proof worktree kept a receipt'
cd "$HM"
C=$(ls .vid/ledger-results | grep -E '\.proof\..*\.xml$' | head -n 1); R=$(ls .vid/ledger-results | grep -E '\.proof\..*\.xml$' | sed -n 2p)
[ -n "$C" ] && [ -n "$R" ] || fail "the two proof receipts are not at the home: $(ls .vid/ledger-results 2>/dev/null | tr '\n' ' ')"
for r in "$C" "$R"; do [ -f ".vid/ledger-results/$r.tree" ] && [ -f ".vid/ledger-results/$r.cases" ] || fail "$r has no .tree or .cases at the home"; done
git worktree remove --force .vid/proofs/ROW-001
pf_proof "$C" "$R" > "$T/out"
[ "$(pf_last)" = 'result=proven why=-' ] || fail "metrics.sh proof at the home: $(pf_last)"
# the skill's step
V=$CHECKS/../skills/vid-verify/SKILL.md
if [ -f "$V" ]; then awk '/^## The fault proof/ { on = 1 } on && /^It is conclusive/ { exit } on' "$V" | tr '\n' ' ' | tr -s ' ' | grep -qF 'sh checks/plan.sh home --brief' || fail 'vid-verify'"'"'s fault proof does not record the home before its first request'; fi
exit 0
