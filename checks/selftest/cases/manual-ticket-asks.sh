#!/bin/sh
# Purpose: selftest case — a ticket's roles and asks in GitHub manual (FB-3 A1.7), on TW's toy: the skeleton's, a step's, a fix ticket's and a
# reached one's name no grader, no second reviewer and no rule about them, no T5 and no DevAgent; a red run and a break are read if the team makes one, the
# tests pass in the team's own results at the commit of main it asks about, and nothing is said of a pull request's head; the asks keep the
# Questions and the Decisions paragraphs and the results format, and name ViD's own review, `vid: decide` on the issue, and the page
# on reports. Each passes writer.sh check in GitHub manual, and a ticket written in GitHub auto is refused there for its roles. In GitHub
# auto the roles and the asks are those of 0.26.11.1.7, byte for byte (their checksums), the setup line of FB-4 A5 apart, which the skeleton's and the
# step's hold once and the other two never. The hash an amendment is owed on is the same in both modes, so a ticket published with the older
# words owes none. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "manual-ticket-asks: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
W=$CHECKS/writer.sh; SU='Set up the data its modules own, as their rows above say, where no earlier ticket has\.'; sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
mode() { printf 'setup-answered key=github-mode value="%s" words="the toy" at=2026-11-24T09:00:00Z\n' "$1" >> .vid/plan/setup; }
# pair <name> <write args…>: the ticket written in GitHub auto, $T/<name>.auto, and in GitHub manual, $T/<name>.manual
pair() { n=$1; shift; for m in auto manual; do mode $m; F=$(sh "$W" write "$@" 2> "$T/werr") || fail "the $n ticket was not written in GitHub $m"; cp "$F" "$T/$n.$m"; cp "${F%.md}.meta" "$T/$n.$m.meta"; sh "$W" check "$F" > "$T/out" 2>&1 || fail "the $n ticket fails the check in GitHub $m"; done
  q1=$(sed -n '1s/.* qhash=\([^ ]*\).*/\1/p' "$T/$n.auto.meta"); [ -n "$q1" ] && [ "$q1" = "$(sed -n '1s/.* qhash=\([^ ]*\).*/\1/p' "$T/$n.manual.meta")" ] || fail "the $n ticket would owe an amendment for its words alone"
  if sh "$W" check "$T/$n.auto" > "$T/out" 2>&1; then fail "in GitHub manual the $n ticket in auto's words passes the check"; fi; mode auto
  { sec "$T/$n.auto" Roles; sec "$T/$n.auto" Asks; } | sed "/^- $SU$/d" | cksum | cut -d' ' -f1 >> "$T/sums"
  { sec "$T/$n.manual" Roles; sec "$T/$n.manual" Asks; } > "$T/m"; cp "$T/m" "$T/out"
  ! grep -nE '(^|[^A-Za-z])(GR|SR)s?([^A-Za-z]|$)|T5|DevAgent|pull request.s head|head report|second reviewer' "$T/m" >&2 || fail "the $n ticket in GitHub manual names a grader, a T5, DevAgent or a head"
  for x in 'in your own results at the commit of main you ask about' 'vid: decide' 'Questions: a product question' 'Decisions: the pull request' 'ViD results format 1' 'the page on reports' "ticket: #"; do grep -qF "$x" "$T/m" || fail "the $n ticket in GitHub manual does not hold: $x"; done
  if grep -qF 'ViD makes its own review' "$T/m"; then [ "$n" != reached ]; else [ "$n" = reached ]; fi || fail "the $n ticket in GitHub manual says the wrong thing of ViD's own review, which a reached ticket has not"; }
tw_toy "$T/toy"; mkdir -p .vid/plan; git rev-parse HEAD > .vid/tw/applied; : > "$T/sums"
sh "$CHECKS/github.sh" spec-setup > "$T/out" 2>&1 && sh "$CHECKS/github.sh" tw-sync >> "$T/out" 2>&1 && tw_start S01 || fail 'the skeleton could not start'
pair skeleton skeleton; grep -qF 'declares the engines' "$T/skeleton.manual" && ! grep -q '^- T2 ' "$T/skeleton.manual" || fail 'the skeleton in GitHub manual lacks its engines, or asks a T2'
tw_post skeleton || fail 'the skeleton was not posted'; for x in 'engines chromium firefox' 'row ROW-003 accepted' 'row ROW-004 accepted' 'closed S01' 'candidate 0' 'staged 0'; do tw_hand "$x"; done; tw_close "$TW_N"; sh "$CHECKS/github.sh" tw-sync > "$T/out" 2>&1
tw_start S02 || fail 'S02 was refused'; pair step step S02; for t in T2 T4; do grep -E "^- $t " "$T/step.manual" | grep -qF 'if you make one, it is read' || fail "the step's $t in GitHub manual is not read if made"; done
tw_post step S02 || fail 'S02 was not posted'; tw_hand 'fix ROW-003 | the saved state lost its line in the close run | close run 4300'; pair fix fix ROW-003
tw_hand 'reached ROW-004 REQ-001'; pair reached reached
for x in skeleton:1 step:1 fix:0 reached:0; do [ "$(grep -c "^- $SU$" "$T/${x%:*}.auto" || true)" = "${x#*:}" ] || fail "the ${x%:*} ticket's setup line"; done
[ "$(paste -sd ' ' "$T/sums")" = '260785559 3201005954 3546900606 940271543' ] || { cp "$T/sums" "$T/out"; fail "GitHub auto's roles or asks changed"; }
echo 'manual-ticket-asks: ok'
