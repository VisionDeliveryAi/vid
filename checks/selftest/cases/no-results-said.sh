#!/bin/sh
# Purpose: selftest case — an ask at a commit of main with no result there (FB-6 A2.2), on GitHub manual's toy and the fake gh (fixtures/ask-pull.sh).
# The ticket's unanswered ask is answered once on the ticket: `ticket: not yet`, `no results at this commit — …`, the pull request whose last commit holds
# the same files named when there is one, and the report branches left out; no row moves and nothing is on record; asked again with the report at that
# pull request's last commit, it is decided from it. A report there that cannot be read is not said to be none. A direct call with no ask, and an ask at a
# pull request's head, post nothing and say the same words. With the team's own rules on record the left-out lines stay with the owner. The words of a commit no branch holds. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/ask-pull.sh"
fail() { echo "no-results-said: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TAB=$(printf '\t'); W='no result report that can be read is at'
ac_project "$T/p" || fail 'the toy could not be made'; ac_grade "$AC_C"; c0=$(ac_comments)
# a direct call, no ask
ac_round accept "$AC_N" "$AC_C"; c12=$(printf %.12s "$AC_C"); grep -qxF "refused #$AC_N no results at $c12; accepted outside ViD: /vid:vid-accept-step $AC_N $c12 accepted \"<your words>\"" "$T/out" && grep -qx "missing #$AC_N $c12 — $W $c12, or at a commit with its very files" "$T/out" && [ "$(ac_comments)" = "$c0" ] || fail 'a direct call posted, or does not say what is missing'
# a piece merged by squash: its last commit holds main's very files; a report of older code, one left out, and one no branch holds
ap_pull unit "$(printf 'ticket: #%s\n\nDecisions: none' "$AC_N")"; P=$AP_P; H=$AP_H; h=$AP_h; ap_squash "$P"; M=$AP_M; m12=$(printf %.12s "$M"); [ "$(git -C "$T/dev" rev-parse "$M^{tree}")" = "$(git -C "$T/dev" rev-parse "$H^{tree}")" ] || fail 'the fixture: the squash holds other files'
x=$(git -C "$T/dev" rev-parse "$M~1"); printf '%s\t%s\t%s\t%s\n' 90 - "$x" "$M" > .vid/decide/unit-merges; printf '%s\t%s\t%s\t%s\n' "$P" "$AC_N" "$H" "$M" >> .vid/decide/unit-merges   # two entries at one merge, the first with other files
ac_report old-1 'A. Person' "$AC_C" 'u.xml=ROW-001=pass ROW-012=pass'; rr_put "pr-$P-x" results.txt 'by: A. Person'; rr_put "pr-$P-x" u.xml "$(rr_cases ROW-001=pass)"; ac_send "pr-$P-x"
Z=0123456789abcdef0123456789abcdef01234567; ac_report "pr-$P-gone" 'A. Person' "$Z" 'u.xml=ROW-001=pass'
ac_ask "$M"; c0=$(ac_comments); ac_round step; grep -qx "decide #$AC_N $M" "$T/out" || fail 'the ask is not owed'
s0=$(cksum < .vid/decide/state 2>/dev/null || echo none); ac_round accept "$AC_N" "$M"; grep -qx "decided #$AC_N $m12 ticket: not yet — no results" "$T/out" && [ "$(ac_comments)" = $((c0 + 1)) ] || fail 'the ask with no results was not answered once'
grep -q "^missing #$AC_N $m12 — " "$T/out" && grep -qx "report left out — vid-results/pr-$P-x: results.txt names no commit" "$T/out" || fail 'the owner is not told what is missing'
ac_last > "$T/out"; [ "$(head -n 2 "$T/out" | paste -sd '|' -)" = "vid: decision $M|ticket: not yet" ] && grep -qx "no results at this commit — $W $m12, or at a commit with its very files — pull request #$P's last commit, $h, holds the same files: a report at it counts" "$T/out" || fail 'the answer does not say what is missing, and which commit would count'
grep -qx "report left out — vid-results/pr-$P-x: results.txt names no commit" "$T/out" && grep -qx "report left out — vid-results/pr-$P-gone: no branch of the code repository holds the commit $Z" "$T/out" && ! grep -q 'old-1' "$T/out" || fail 'the left-out reports are not in the answer, or another report is'
[ "$(cksum < .vid/decide/state 2>/dev/null || echo none)" = "$s0" ] && [ ! -f ".vid/decide/last-step-$AC_N" ] && ! grep -q '^step-' .vid/decide/merges 2>/dev/null || fail 'the answer moved a row or recorded something'
ac_round step; ! grep -q "^decide #$AC_N " "$T/out" || fail 'the answered ask is still owed'
# the team's own rules on record: the left-out lines stay with the owner; a report at the commit that cannot be read is not said to be none there
sh "$CHECKS/planner.sh" setup team-rules https://example.invalid/rules --words 'their own' > "$T/out" 2>&1 || fail 'the rules could not be put on record'
rr_put cut-1 results.txt "$(printf 'by: A. Person\ncommit: %s' "$M")"; rr_put cut-1 u.xml '<testsuite><testcase name="ROW-001"/>'; ac_send cut-1
ac_ask "$M"; ac_round accept "$AC_N" "$M"; [ "$(ac_comments)" = $((c0 + 3)) ] && grep -q '^report left out — vid-results/cut-1: ' "$T/out" || fail 'the owner is not told of the report that cannot be read'
ac_last > "$T/out"; ! grep -q '^report left out' "$T/out" && grep -q "^no results at this commit — $W $m12" "$T/out" || fail 'with the team'"'"'s own rules the answer holds the left-out lines'
# the report at the pull request's last commit counts
ap_rep "$P" "$H" 1; ac_ask "$M"; ac_round accept "$AC_N" "$M"; grep -qx "accepted #$AC_N $m12" "$T/out" || fail 'the report the answer named does not count'
# an ask at a step's own pull request: nothing posted
AC_N=$(gh_issue 'Step S03'); { mn_ticket "$AC_N" S03 step ROW-006; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"; printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\n' "$AC_N" >> .vid/tw/log
ap_pull own "$(printf 'ticket: #%s\n\nDecisions: none' "$AC_N")"; ap_ask "$AP_P" "$AP_H"; ac_round accept "$AC_N" "$AP_H"; grep -qx "refused #$AC_N no results at $AP_h, the head of pull request #$AP_P" "$T/out" && grep -q "^missing #$AC_N $AP_h — $W $AP_h" "$T/out" && [ "$(ap_replies "$AP_P")" = 0 ] && [ "$(ac_comments)" = 0 ] || fail 'an ask at a pull request with no results posted'
exit 0
