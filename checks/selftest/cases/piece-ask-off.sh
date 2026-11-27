#!/bin/sh
# Purpose: selftest case — a piece's ask is said with own work off (FIX-BATCH-T2 §18, F-34), on the fake gh (fixtures/ask-pull.sh).
# In GitHub manual with own work off, `next.sh triggers` prints one `context unit-ask #<p> <its line's number or -> <h12> <words>`
# for each piece (a pull request whose ticket line names no published ticket) asking `vid: decide` at its head, unanswered. Convicts
# unless: (a) a piece of the ticket's sub-issue has its one line, naming the ticket and its command, beside the ticket's own
# `context ask` line; (b) a piece naming no ticket has the no-ticket words; (c) the team's rules on record are named, else ViD's
# reports command; (d) a piece pushed past its ask, and one answered by hand, have no line; (e) no comment is added on any piece and
# the call writes nothing under .vid/decide or .vid/tw; (f) with own work on the call prints no such line; (g) nor in GitHub auto.
# Made-up data only. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
B=$(mktemp -d); trap 'rm -rf "$B"' EXIT; TAB=$(printf '\t')
HOME=$B/home; export HOME; mkdir -p "$HOME"
T=$B/t; mkdir -p "$T"
fail() { echo "piece-ask-off: $*" >&2; cat "$T/L" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/ask-pull.sh"; ac_project "$T/p" || fail 'the toy could not be made'
body() { printf 'ticket: #%s\n\n%s' "$1" "${2:-Decisions: none}"; }
# w0: every file under .vid/decide and .vid/tw. lines: the read, then the call's lines in $T/L (it must succeed and write neither
# folder: (e) at every call), its context unit-ask lines in $T/U
w0() { find .vid/decide .vid/tw -type f -exec cksum {} + 2>/dev/null | sort | cksum; }
lines() { sh "$CHECKS/next.sh" read > "$T/o" 2>&1 || { cat "$T/o" >&2; fail "$1: the read failed"; }
  _w=$(w0); sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/o" || { cat "$T/o" >&2; fail "$1: next.sh triggers failed"; }
  [ "$(w0)" = "$_w" ] || fail "(e) $1: the call wrote under .vid/decide or .vid/tw"
  grep "^context${TAB}unit-ask${TAB}" "$T/L" > "$T/U" || :; }
cm() { _n=0; for _p in "$@"; do _n=$((_n + $(ls "$(ap_dir "$_p")/comments" 2>/dev/null | grep -c . || true))); done; echo "$_n"; }
[ "$(sh "$CHECKS/next.sh" own-work)" = off ] || fail 'own work is not off in the toy'

# (a), (b): a piece of the ticket's sub-issue, and one naming no ticket, each asking at its head; the ticket asked on its own pull request
K=$(ap_child "$AC_N"); ap_pull piece "$(body "$K")"; Q=$AP_P; QH=$AP_H; qh=$AP_h; ap_ask "$Q" "$QH"
ap_pull loose 'no ticket line here'; R=$AP_P; RH=$AP_H; rh=$AP_h; ap_ask "$R" "$RH"
ap_pull own "$(body "$AC_N")"; P=$AP_P; ap_ask "$P" "$AP_H"
c0=$(cm "$Q" "$R"); lines first
[ "$(grep -c . "$T/U")" = 2 ] || fail "not one line for each piece: $(grep -c . "$T/U")"
grep -q "^context${TAB}unit-ask${TAB}#$Q${TAB}$K${TAB}$qh${TAB}a piece of ticket #$AC_N: .*posts nothing on #$Q.*/vid:vid-accept-step $AC_N " "$T/U" || fail "(a) the piece's line does not name ticket #$AC_N and its command"
grep -q "^context${TAB}ask${TAB}#$AC_N${TAB}" "$T/L" || fail "(a) the ticket's own context ask line is gone"
grep -q "^context${TAB}unit-ask${TAB}#$R${TAB}-${TAB}$rh${TAB}its line names no published ticket: nothing of ViD's decides it, and nothing is posted on #$R" "$T/U" || fail '(b) the no-ticket words'
# (c) the team's rules: ViD's reports command, then their place once on record
grep -q "#$Q.*what ViD sends the team and asks of it: /vid:vid-accept-step reports" "$T/U" || fail '(c) no reports command without team rules'
sh "$CHECKS/planner.sh" setup team-rules team/rules.md --words 'their own rules' > "$T/o" 2>&1 || fail 'the rules could not be recorded'
lines rules; grep -q "#$Q.*what the team's rules ask of ViD in return: team/rules.md" "$T/U" || fail "(c) the team's rules are not named"
# (e) nothing posted, nothing recorded
[ "$(cm "$Q" "$R")" = "$c0" ] || fail '(e) a comment was added on a piece'
# (d) pushed past its ask, and answered by hand: no line
ap_push piece; printf 'vid: decision %s\nanswered by hand\n' "$RH" > "$T/d"; gh pr comment "$R" -R owner/code --body-file "$T/d" > /dev/null
c1=$(cm "$Q" "$R"); lines later; [ ! -s "$T/U" ] || fail '(d) a piece pushed past its ask, or answered, still has a line'
[ "$(cm "$Q" "$R")" = "$c1" ] || fail '(e) a comment was added on a piece, later'
# (f) own work on: no line from the call; (g) GitHub auto: none
ap_ask "$Q" "$AP_H"; lines again; [ "$(grep -c . "$T/U")" = 1 ] || fail 'asked again at its new head, the piece has not its one line'
printf 'setup-answered key=own-work value="on" words="the toy, on" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
lines on; [ ! -s "$T/U" ] || fail '(f) with own work on the call prints a unit-ask line'
printf 'setup-answered key=own-work value="off" words="the toy, off" at=2026-11-20T09:01:00Z\nsetup-answered key=github-mode value="auto" words="the toy, auto" at=2026-11-20T09:02:00Z\n' >> .vid/plan/setup
lines auto; [ ! -s "$T/U" ] || fail '(g) GitHub auto prints a unit-ask line'
echo 'piece-ask-off: ok'
