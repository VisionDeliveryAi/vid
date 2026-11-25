#!/bin/sh
# Purpose: selftest case — what the acceptance at a pull request's head puts on record, and when (FB-5 B1.4), in GitHub manual on the fake gh
# (fixtures/ask-pull.sh). A recorded failing row that passes at the head stays failing on the handed record while the pull request is open,
# and is accepted at its merge. A test landed between the decision and the merge stays off the record, the others on it. An ask on a merged pull
# request, owed no answer yet, is owed and listed still once the read's list of merged ones no longer shows it, its closed ticket not told as closed
# early; answered, it is accepted and recorded at that merge. A ticket closed by hand while its own pull request, accepted, is open, is told: a closed
# ticket is never silent. An ask whose merge is first seen by a call that records
# other tickets accepted outside ViD is owed still. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; TAB=$(printf '\t')
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/ask-pull.sh"
fail() { echo "ask-on-pull-record: $*" >&2; cat "$T/out" .vid/tw/handed >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
body() { printf 'ticket: #%s\n\n%sDecisions: none' "$AC_N" "${1:-}"; }
nstep() { ac_round step; [ "$RC" = 0 ] || fail "$1: the step exited $RC"; }
acc() { ac_round accept "$@"; [ "$RC" = 0 ] || fail "accept $* exited $RC"; }
row() { sed -n "s/^row $1 \([^ |]*\).*/\1/p" .vid/tw/handed 2>/dev/null; }
merges() { cat .vid/decide/merges 2>/dev/null | grep -c "^step-$AC_N-" || true; }
tkt() { AC_N=$(gh_issue "Step $1"); { mn_ticket "$AC_N" "$1" step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"; printf 'published %s kind=step step=%s rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$AC_N" "$1" >> .vid/tw/log; }
own() { ap_pull "$1" "$(body "${2:-}")"; ap_rep "$AP_P" "$AP_H"; ac_grade "$AP_H"; ap_ask "$AP_P" "$AP_H"; }
# a recorded failing row, accepted at the head; then a landing before the merge
nstep first; mkdir -p .vid/tw; printf 'row ROW-001 failing | stand-in: decision\nrow ROW-012 failing | stand-in: decision\n' >> .vid/tw/handed; printf 'ROW-001\nROW-012\n' >> .vid/decide/record
own one; nstep asked; acc "$AC_N" "$AP_H"; grep -q "^decided #$AC_N $AP_h ticket: accepted" "$T/out" || fail 'it was not accepted at the head'
[ "$(row ROW-001)" = failing ] && [ "$(row ROW-012)" = failing ] || fail 'the decision at the unmerged head changed the handed record'
printf 'ROW-012\t1\t2099-01-01T00:00:00Z\n' >> .vid/decide/landed; ap_squash "$AP_P"; nstep merged; [ "$(merges)" = 1 ] || fail 'the acceptance is not recorded at its merge'
[ "$(row ROW-001)" = accepted ] || fail 'the row accepted at the head is not on record at the merge'; [ "$(row ROW-012)" = failing ] || fail 'a test landed since its decision is recorded accepted from the older results'
rm .vid/decide/landed
# closed by hand while its own pull request, accepted, is open
tkt S03; own two; nstep 'two asked'; acc "$AC_N" "$AP_H"; grep -q "^decided #$AC_N $AP_h ticket: accepted" "$T/out" || fail 'the second was not accepted at its head'; echo CLOSED > "$FAKEGH/issues/$AC_N/state"
nstep 'two closed'; sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; cp "$T/L" "$T/out"; grep -q "^context.closed.#$AC_N.closed on GitHub, not accepted — /vid:vid-accept-step $AC_N decides it, or records its acceptance" "$T/out" || fail 'a ticket closed by hand with its pull request open is told by nothing'; ap_squash "$AP_P"; nstep 'two merged'; [ "$(merges)" = 1 ] && ! grep -q "^closed #$AC_N" "$T/out" || fail 'it is not recorded at its merge, or still told'
# an ask on a pull request merged before any call, and the first call to see the merge records another ticket accepted outside ViD: owed still
tkt S05; own four; P=$AP_P; H=$AP_H; ap_squash "$P"; O=$AC_N; tkt S06; ac_round accept --tickets "$AC_N@$AC_C" --outside 'accepted before'; [ "$RC" = 0 ] && grep -q "^accepted #$AC_N .* outside ViD" "$T/out" || fail 'the other ticket was not recorded'
cut -f1 .vid/decide/unit-merges | grep -qx "$P" || fail 'the toy: that call did not see the merge'; nstep 'four'; grep -qx "decide #$O $H" "$T/out" || fail 'the ask whose merge that call saw first is not owed'
# an ask on a merged pull request the read's list no longer shows
tkt S04; own three "Closes #$AC_N
"; P=$AP_P; H=$AP_H; h=$AP_h; ap_merge "$P"; M=$AP_M; nstep 'three merged'; grep -qx "decide #$AC_N $H" "$T/out" || fail 'the ask merged before the call is not owed'
i=900; while [ $i -lt 922 ]; do d=$FAKEGH/prs/$i; mkdir -p "$d/comments"; printf 'no ticket' > "$d/body"; echo MERGED > "$d/state"; echo false > "$d/draft"; echo main > "$d/base"; echo "x$i" > "$d/head"; echo "$AC_OFF" > "$d/headoid"; echo "$AC_C" > "$d/merge"; i=$((i + 1)); done
nstep 'the others'; nstep 'out of the list'; ! grep -q "^merged$TAB$P$TAB" .vid/round/read || fail 'the toy still shows the pull request in the read'
grep -qx "decide #$AC_N $H" "$T/out" && ! grep -q "^closed #$AC_N" "$T/out" || fail 'the ask the read no longer shows is not owed, or its ticket is told as closed'
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; grep -qx "context${TAB}ask${TAB}#$AC_N${TAB}$h${TAB}/vid:vid-accept-step $AC_N $h" "$T/L" || { grep '^context' "$T/L" > "$T/out"; fail 'the call does not list it'; }
acc "$AC_N" "$h"; grep -q "^accepted #$AC_N $(printf %.12s "$M")" "$T/out" && [ "$(ap_replies "$P")" = 1 ] && [ "$(merges)" = 1 ] || fail 'it was not decided, answered once and recorded at its merge'
nstep after; ! grep -q "^decide #$AC_N\|^undecided #$AC_N\|^closed #$AC_N" "$T/out" && [ "$(ap_replies "$P")" = 1 ] && ! grep -q "^$P$TAB" .vid/decide/pr-asks || fail 'it is still said, or still stands'
echo 'ask-on-pull-record: ok'
