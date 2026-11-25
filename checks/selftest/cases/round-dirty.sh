#!/bin/sh
# Purpose: selftest case — a ticket refused because a spec file is being changed is tried again (FB-7 D2, GitHub auto), checks/round.sh
# on the writer's toy and the fake gh. With a draft of INVENTORY.md in the folder `next` says `refused new skeleton: … INVENTORY.md has an
# uncommitted change` and publishes nothing; the step says `idle` while the draft stands, and once the file is put back `retry tickets`
# in its place, again at each step until /vid run's next, which publishes the ticket; no step says it after. On the toy with its skeleton
# built: the refusal is said at each `next` and kept nowhere (.vid/decide/refused, no round-refused event), and a true refusal (the
# gate shut with the spec files clean) is kept, said once and not tried again until something changes. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "${TT:-$T}"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-dirty: $*" >&2; sed 's/^/    /' "$T/out" >&2 2>/dev/null; exit 1; }
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $* failed: $RC"; }
TT=$T; T=$TT/a; mkdir "$T"; tw_toy "$T/toy"
sh "$CHECKS/github.sh" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$CHECKS/github.sh" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rt() { grep -qx 'retry tickets' "$T/out"; }
rd step; printf '\n<!-- a draft being written -->\n' >> INVENTORY.md
rd next; grep -q '^refused new skeleton: .*INVENTORY\.md has an uncommitted change$' "$T/out" || fail 'the skeleton is not refused for the draft'; if grep -q '^published' "$T/out"; then fail 'a ticket went out with the draft in the folder'; fi
for n in 1 2; do rd step; if rt; then fail 'a step says retry tickets with the draft in the folder'; fi; done; grep -qx idle "$T/out" || fail 'the step with the draft in the folder is not idle'
git checkout -q HEAD -- INVENTORY.md
for n in 1 2; do rd step; rt || fail "the file put back, step $n does not say retry tickets"; if grep -qxE 'idle|nothing-left' "$T/out"; then fail "step $n says idle or nothing-left beside retry tickets"; fi; done
if rt; then rd next; fi; grep -q '^published ' "$T/out" || fail 'the next the step asked for published nothing'
rd step; if rt; then fail 'a step says retry tickets once the ticket went out'; fi
T=$TT/b; mkdir "$T"; tw_toy "$T/toy"; tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/
kept() { grep -c "^new step $1 " .vid/decide/refused 2>/dev/null || true; }
evs() { grep -c '^round-refused what=new-step-' .vid/metrics-events || true; }
sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$CHECKS/github.sh" lock-take t > "$T/out" 2>&1 || fail 'no lock'
# a true refusal, the spec files clean (no publish-approved event): kept, said once, not tried again; a new handed line tries it again
grep '^publish-approved ' .vid/metrics-events > "$T/pa"; grep -v '^publish-approved ' .vid/metrics-events > "$T/me"; cat "$T/me" > .vid/metrics-events
rd next; grep -q '^refused new step S02: .*no publish-approved event' "$T/out" || fail 'a true refusal of S02 is not said'
[ "$(kept S02)" = 1 ] || fail 'a true refusal is not kept'; grep -q '^round-refused what=new-step-S02' .vid/metrics-events || fail 'a true refusal has no event'
rd next; if grep -q '^refused new step S02' "$T/out"; then fail 'a true refusal was tried again'; fi
cat "$T/pa" >> .vid/metrics-events; tw_hand 'engines chromium firefox'; E0=$(evs); K0=$(kept S02)
# a draft in the folder: said at each step, never kept
printf '\n<!-- a draft being written -->\n' >> INVENTORY.md
for n in 1 2; do rd next; grep -q '^refused new step S02: .*INVENTORY\.md has an uncommitted change$' "$T/out" || fail "next $n: S02's refusal for the draft is not said"
  grep -q '^published ' "$T/out" && fail "next $n: a ticket went out with the draft in the folder"
  [ "$(kept S02)" = "$K0" ] || fail "next $n: the refusal was kept: $(grep '^new step S02 ' .vid/decide/refused)"
  [ "$(evs)" = "$E0" ] || fail "next $n: the refusal was recorded: $(grep '^round-refused ' .vid/metrics-events | tail -n 1)"; done
git checkout -q HEAD -- INVENTORY.md
rd next; grep -q '^published ' "$T/out" || fail 'the file put back, the next step published nothing'
grep -q ' step=S02 ' .vid/tw/log || fail "S02's ticket was not published: $(cat .vid/tw/log)"
if grep -q '^refused new step S02' "$T/out"; then fail 'S02 is still refused'; fi
echo 'round-dirty: ok'
