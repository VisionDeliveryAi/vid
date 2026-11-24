#!/bin/sh
# Purpose: selftest case — the review's `test it` lines are asked of the team once (FB-3 A1.4), through round.sh accept on GitHub manual's
# toy and the fake gh (fixtures/accept.sh): in the ticket's first decision after the review, one `request <row> — <its words>` line each
# and `requests open`, the decision `not yet` and posted once, the commit kept in .vid/decide/requested-step-<n>; a `note it` and a
# `drop it` line are no request. The owner's call at the same commit, no ask since, posts nothing and accepts nothing; the team's next
# ask, at that commit or a later one, is accepted, the requests not asked again. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-review-requests: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
for how in same later; do
  [ "$how" = same ] || { AC_N=$(gh_issue 'Step S03'); { mn_ticket "$AC_N" S03 step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"; printf 'published %s kind=step step=S03 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$AC_N" >> .vid/tw/log; tk_dev "for $how"; AC_C=$(git -C "$T/dev" rev-parse HEAD); }
  c12=$(printf %s "$AC_C" | cut -c1-12); ac_report "unit-$how" 'A. Person' "$AC_C" 'u.xml=ROW-001=pass ROW-012=pass'; ac_ask "$AC_C"; c0=$(ac_comments)
  ac_grade "$AC_C" 'ROW-001 breached test — it checks nothing' 'ROW-012 unclear — which page?'; ac_sort "$AC_C" 'ROW-001 test it — add a test that a second digest is refused, as in mail.txt' 'ROW-012 drop it — a drop — ROW-012 unclear'
  ac_round accept "$AC_N"; grep -qx "decided #$AC_N $c12 ticket: not yet" "$T/out" || fail "$how: the requests did not hold the decision"; ac_last > "$T/out"
  grep -qx 'request ROW-001 — add a test that a second digest is refused, as in mail.txt' "$T/out" && [ "$(grep -c '^request ' "$T/out")" = 1 ] && grep -q '^requests open — ' "$T/out" && grep -qx 'ROW-001 accepted' "$T/out" || fail "$how: the decision does not ask the one request"
  [ "$(ac_comments)" = $((c0 + 1)) ] && [ "$(cat ".vid/decide/requested-step-$AC_N")" = "$c12" ] || fail "$how: the request is not posted once, or not on record"
  ac_round accept "$AC_N" "$AC_C"; [ "$(ac_comments)" = $((c0 + 1)) ] && ! grep -q '^accepted' "$T/out" || fail "$how: the same commit with no ask since was accepted, or posted again"
  [ "$how" = same ] || { tk_dev 'with the test'; AC_C=$(git -C "$T/dev" rev-parse HEAD); c12=$(printf %s "$AC_C" | cut -c1-12); ac_report "unit-$how-2" 'A. Person' "$AC_C" 'u.xml=ROW-001=pass ROW-001-second=pass ROW-012=pass'; }
  ac_ask "$AC_C"; ac_round accept "$AC_N"; grep -qx "accepted #$AC_N $c12" "$T/out" && ! { ac_last | grep -q '^request'; } || fail "$how: a later ask is held by the requests, or asked them again"; done
exit 0
