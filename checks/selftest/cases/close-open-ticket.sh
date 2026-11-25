#!/bin/sh
# Purpose: selftest case — a step's close and a row in another open ticket (FB-7 A2), checks/close.sh on the writer's toy and the fake gh.
# A row an open ticket of any kind holds, whose merge the close's commit does not hold, is left out of the ask; one published after the ask
# and red at it waits for its ticket: no failing row, no fix line, its ticket merged while the run was out or not, and no red set that did
# not shrink. The close is owed again once the ticket merged, at a commit that holds that merge, its row asked; and once it was withdrawn. Env: CHECKS.
set -eu
HOME=$(mktemp -d); export HOME; unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T" "$HOME"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
. "$CHECKS/selftest/fixtures/closes.sh"
fail() { echo "close-open-ticket: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
CL_NOASK=1; cl_toy; : > .vid/tw/handed; tw_hand 'engines alpha beta'
# ask <k>: S02's close asked as its k-th ask: $N, $X, its rows in $ROWS. rep [<row=state>…]: its two reports, all passed but those named, decided
ask() { fetch; cs owed; ok '^close S02$'; cs ask S02; ok '^asked [0-9]* close S02$'; N=$(sed -n 's/^asked \([0-9]*\) close S02$/\1/p' "$T/out"); K=.vid/decide/close/S02/$1; [ -f $K/ask ] || fail "no ask $1"; X=$(sed -n "s/^commit$TAB//p" $K/ask); ROWS=$(awk -F'\t' '$1 == "chunk" && $2 == "p1c1" { print $4 }' $K/ask); }
rep() { rq p1c1-1 "$X" alpha $(allof pass "$@"); rq p2c1-1 "$X" beta $(allof pass "$@"); fetch; cs decide S02; [ "$RC" = 0 ] || fail "decide failed ($RC)"; }
nt step S02 ROW-005,ROW-008,ROW-012; mg 40 "$TN"; nt step S05 ROW-005; F0=$TN
ask 1; for r in ROW-001 ROW-003 ROW-008 ROW-012; do case " $ROWS " in *" $r "*) ;; *) fail "the close leaves out $r: $ROWS" ;; esac; done; case " $ROWS " in *' ROW-005 '*) fail "a row of an open ticket is asked: $ROWS" ;; esac
# red, held: the one by an open ticket, the other by a ticket that merged while the run was out; ROW-001 its own fix line
nt step S03 ROW-008; F1=$TN; nt fix S03 ROW-012; F2=$TN; mg 41 "$F2"; rep ROW-001=fail:a ROW-008=fail:b ROW-012=fail:c
ok '^close-waits S02 ROW-008$'; ok '^close-waits S02 ROW-012$'; ok '^failing ROW-001$'; ok '^close-fix S02 ROW-001$'; no '^failing ROW-008$'; no '^failing ROW-012$'
[ "$(grep -c '^fix ' .vid/tw/handed)" = 1 ] || fail "fix lines: $(grep '^fix ' .vid/tw/handed)"
FL=$(sed -n 's/^\(fix ROW-001 .*\) | stand-in: RM$/\1/p' .vid/tw/handed); KF=$(printf '%s' "$FL" | cksum | cut -d' ' -f1); nt fix S02 ROW-001; sed "s/^\(published $TN .*\) at=/\1 fix=$KF at=/" .vid/tw/log > "$T/l"; cat "$T/l" > .vid/tw/log; mg 42 "$TN"
fetch; cs owed; no '^close S02$'; mg 43 "$F1"
# owed again once the ticket merged, at a commit that holds it, the row asked; ROW-005 asked too, its ticket merged
mg 44 "$F0"; ask 2; git --git-dir=.vid/code merge-base --is-ancestor "$(awk -F'\t' '$1 == 43 { print $4 }' .vid/decide/merges)" "$X" || fail 'the close was asked again at a commit that does not hold the ticket it waited for'
for r in ROW-008 ROW-012; do case " $ROWS " in *" $r "*) ;; *) fail "the second ask leaves out $r: $ROWS" ;; esac; done
# red on a held row alone: it waits, and the red set is not one that did not shrink; its ticket withdrawn, the close is owed again
nt step S04 ROW-003; F3=$TN; rep ROW-003=fail:d; ok '^close-waits S02 ROW-003$'; no '^close-shrink'; no '^close-fix'; ! grep -q '^shrink ' $K/items || fail "a shrink item: $(cat $K/items)"
fetch; cs owed; no '^close S02$'; printf 'withdrawn %s decision=plan-change\n' "$F3" >> .vid/tw/log; ask 3; rep; ok '^closed S02$'
exit 0
