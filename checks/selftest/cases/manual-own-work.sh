#!/bin/sh
# Purpose: selftest case — /vid next's step 2, ViD's own work, behind the owner's switch (GM-4 K11 with E5; GM §6: the phase's first
# write is one the owner names), its script part, on GitHub manual's toy and the fake gh (fixtures/accept.sh), a step ticket asked at
# a commit of main with its reports. A call before `own-work on`: next.sh own-work reads off, so step 2 runs nothing; the call's lines
# say it is off, listing the move, and list the ask, `context ask #<n> <c12>` with the command that decides it; nothing is written to
# the code repository and nothing decided. The move own-work on, in the owner's words, is a setup line. The next call's step 2:
# round.sh step's `decide` line, round.sh accept posting the decision on the ticket, round.sh asks asking the step's close, each row's run time from the ticket's head report (close.sh's secs); nothing
# exported to the spec repository; the lock freed at the call's end. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-own-work: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail "the plan could not be recorded"; sh "$CHECKS/github.sh" lock-free > /dev/null 2>&1 || fail 'the lock could not be freed'
printf 'engines alpha | stand-in: results reader\n' >> .vid/tw/handed; ac_good "$AC_C"; ac_ask "$AC_C"; h=$(printf %s "$AC_C" | cut -c1-12); c0=$(ac_comments)
start() { sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || fail 'the connect did not start'; }
end_() { sh "$CHECKS/connect.sh" end > "$T/out" 2>&1 || fail 'the connect did not end'; [ -z "$(mn_lock)" ] || fail 'the lock is held after the call'; }
# step 2 as the call runs it: nothing until own work is on, then vid-accept-step, each decide line, and the asks
step2() { : > "$T/s2"; [ "$(sh "$CHECKS/next.sh" own-work)" = on ] || return 0
  ac_round step; cat "$T/out" >> "$T/s2"; [ "$RC" = 0 ] || fail "round.sh step exited $RC"
  sed -n 's/^decide #\([0-9]*\) \([0-9a-f]*\)$/\1 \2/p' "$T/out" > "$T/dl"; while read -r n c; do ac_round accept "$n" "$c"; cat "$T/out" >> "$T/s2"; done < "$T/dl"
  ac_round asks; cat "$T/out" >> "$T/s2"; [ "$RC" = 0 ] || fail "round.sh asks exited $RC"; }
# a call with own work off
start; gh_wclear; step2; [ ! -s "$T/s2" ] || fail 'step 2 ran with own work off'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'the read failed'; sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q '^context	own-work	off	own-work on ' "$T/L" || { cp "$T/L" "$T/out"; fail 'the lines do not say own work is off, listing its move'; }
grep -q "^context	ask	#$AC_N	$h	/vid:vid-accept-step $AC_N $h\$" "$T/L" || { cp "$T/L" "$T/out"; fail 'the unanswered ask is not listed with its command'; }
! grep -q '^owner/code ' "$FAKEGH/writes" && [ "$(ac_comments)" = "$c0" ] && [ ! -s .vid/decide/state ] || fail 'a call with own work off wrote'
sh "$CHECKS/next-move.sh" call own-work on 'Yes, do your own work now' > "$T/out" 2>&1 || true; grep -q '^done own-work on' "$T/out" || fail 'the move own-work on was not done'
grep -q '^setup-answered key=own-work value="on" words="Yes, do your own work now" at=' .vid/plan/setup || fail 'the switch is no setup line in the owner words'
end_
# the next call: own work on
start; gh_wclear; step2; cp "$T/s2" "$T/out"
grep -qx "decide #$AC_N $AC_C" "$T/s2" || fail 'step 2 listed no decide line'; grep -qx "accepted #$AC_N $h" "$T/s2" || fail 'step 2 did not accept the ticket'
[ "$(ac_comments)" = $((c0 + 1)) ] && ac_last | grep -qx 'ticket: accepted' || fail 'the decision was not posted on the ticket'
grep -q '^asked [0-9]* close S02$' "$T/s2" || fail "the step's close was not asked"
k=$(ls .vid/decide/close/S02 | grep -E '^[0-9]+$' | sort -n | tail -n 1); grep -qx 'ROW-001 1' ".vid/decide/close/S02/$k/rows" || { cp ".vid/decide/close/S02/$k/rows" "$T/out"; fail "the close's run time of ROW-001 is not its ticket report's, 1 s"; }
! grep -q '^owner/code-spec push' "$FAKEGH/writes" || fail 'step 2 exported to the spec repository'
end_
exit 0
