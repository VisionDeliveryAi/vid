#!/bin/sh
# Purpose: selftest case — the ticket side's shared helpers, checks/lib.sh (0.26.10.28.4, 9.3 R3, M3). Its plan-block reader is plan.sh's own: on a
# RUN-STATE whose step lines end in spaces and whose prose holds a second fenced vid-plan block, plan_block gives exactly what plan.sh records as the plan,
# and its hash is plan.sh's. rng writes a range out as the plan reads it, at its width, and leaves an id alone. Each ticket script loads lib.sh from beside
# itself and defines none of its helpers again (M10's rule 5, the lock and the run record's writer among them); gh_vid's copy of github.sh has lib.sh beside it. land.sh draft --plan, given a fenced file with no
# heading, keeps its own reader: the draft's plan is the block whole and fence-free. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "lib-shared: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
HERE=$CHECKS; . "$CHECKS/lib.sh"
# plan.sh's form: trailing spaces, and a second fenced block in the prose
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002   ' 'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003..ROW-004	' "shared: $PLANS_SHARED"
printf '\n## Notes\n\nAn old plan, kept for reading:\n\n```vid-plan\nstep S9 | name: old | modules: app/s9 | builds-on: - | rows: ROW-009\n```\n' >> .vid/RUN-STATE.md
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > "$T/out" 2>&1 || fail 'plan.sh change create failed'
PH=$(sed -n 's/^plan-change .* hash=\([0-9a-f]*\) .*/\1/p' .vid/metrics-events | tail -n 1); [ -f ".vid/plans/$PH.plan" ] || fail 'plan.sh recorded no plan'
plan_block > "$T/pb"; cmp -s "$T/pb" ".vid/plans/$PH.plan" || { diff "$T/pb" ".vid/plans/$PH.plan" > "$T/out" || true; fail "plan_block is not plan.sh's block"; }
[ "$(plan_block | { if command -v shasum > /dev/null 2>&1; then shasum -a 256; else sha256sum; fi; } | cut -c1-12)" = "$PH" ] || fail "plan_block's hash is not plan.sh's"
! grep -q 'S9' "$T/pb" && ! grep -q '```' "$T/pb" && ! grep -q ' $' "$T/pb" || fail 'plan_block read the prose block, a fence or a trailing space'
# rng
[ "$(awk "$RNG"' BEGIN { print rng("ROW-008..ROW-011") }')" = 'ROW-008 ROW-009 ROW-010 ROW-011' ] || fail 'rng: a range'
[ "$(awk "$RNG"' BEGIN { print rng("RULE-002") }')" = RULE-002 ] || fail 'rng: an id'
# loaded from beside each script, defined nowhere else
for s in close decide end github grade land planner queue refresh results round walk writer; do F=$CHECKS/$s.sh
  grep -qxF '. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file' "$F" || fail "$s.sh does not load lib.sh"
  for h in put skey twkey plan_block rkey epoch stamp now ev pstamp palive lage lheld lclear lock_take lock_free rs_edit; do ! grep -qE "(^|[;{ ]) *$h\\(\\) *\\{" "$F" || fail "$s.sh defines $h again"; done
  ! grep -qE '^RNG=' "$F" || fail "$s.sh defines RNG again"; done
# FB-2 C3: close.sh's parts share its shell: none loads lib.sh again (its trap would be set again over close.sh's), none defines a helper
for F in "$CHECKS"/close-*.sh; do s=${F##*/}; ! grep -qF '. "$HERE/lib.sh"' "$F" || fail "$s loads lib.sh again"
  for h in put skey twkey plan_block rkey epoch stamp now ev pstamp palive lage lheld lclear lock_take lock_free rs_edit; do ! grep -qE "(^|[;{ ]) *$h\\(\\) *\\{" "$F" || fail "$s defines $h again"; done
  ! grep -qE '^RNG=' "$F" || fail "$s defines RNG again"; done
grep -q 'cp "$CHECKS/github.sh" "$CHECKS/lib.sh"' "$CHECKS/selftest/fixtures/tickets.sh" || fail "gh_vid's copy of github.sh has no lib.sh beside it"
# land.sh draft --plan: a fenced file with no heading, its plan whole and fence-free
printf '```vid-plan\nstep S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002\n```\n' > "$T/fenced"
[ "$(sed -n '/^pblock() {/p' "$CHECKS/land.sh" | grep -c .)" = 1 ] || fail "land.sh's own reader of a plan file is gone"
eval "$(sed -n '/^pblock() {/p' "$CHECKS/land.sh")"; [ "$(pblock "$T/fenced")" = 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' ] || fail "land.sh's reader of a fenced plan file: $(pblock "$T/fenced")"
[ -z "$(plan_block "$T/fenced")" ] || fail 'plan.sh form read a file with no heading'
echo 'lib-shared: ok'
