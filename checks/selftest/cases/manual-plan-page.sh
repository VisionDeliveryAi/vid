#!/bin/sh
# Purpose: selftest case — the board, every step and ticket on it (GM-2 T12; FB-5 A1: in the owner's list, the page gone). On the
# planner's toy in GitHub manual with two teams of three tracks each, beta's stage 2 after alpha's (fixtures/plan-page.sh): #1 (S01)
# closed, #2 (S02) open, assigned, with two units, one closed, and pull request #11; #3 (S03) open, not taken; S04 and S05 not
# issued, S04 with a limit warning. `next-page.sh write` with the call's lines (next.sh triggers' real count lines, then the §5 forms
# a call hands on) prints `list .vid/face/list.json`; every step is on one card, in its own team, release and track, each issued one
# with its ticket's link, state and pieces, no warning on a card; each count is next.sh triggers' own, and the write changes no file
# of the project but the panel's own, in .vid/face. A second write, with #4 published for a step the plan no longer holds (S99), #5 published for S05 and
# not in the read, and S04's lane one no team of the setup gives (gamma-1): #4 is under the tickets of no step, S05's card says #5
# was not read, and S04 is under the lanes no team holds. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "manual-plan-page: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
pp_toy "$T/toy"; pp_scene
sums() { find . -type f ! -path './.vid/face/*' -exec cksum {} + | sort; }   # .git too
sums > "$T/before"
pp_write "$T/trig"
[ "$PP_RC" = 0 ] || fail "next-page.sh write failed ($PP_RC)"
grep -qxF "list $LJ" "$T/pw" || fail "it did not print the list's path ($LJ)"
[ -s "$LJ" ] || fail 'no list was written'
sums > "$T/after"; cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" >&2 || true; fail 'the list changed a file of the project'; }
pj_is "sorted(x['id'] for x in cs)" '["S01", "S02", "S03", "S04", "S05"]' 'each step is on one card, once'
pj_is "[c(i)['ticket'] for i in ('S01','S02','S03','S04','S05')]" '[1, 2, 3, 0, 0]' 'the tickets'
pj_is "[c(i)['state'] for i in ('S01','S02','S03','S04','S05')]" '["building", "building", "nobody", "unsent", "unsent"]' 'the states (closed is not accepted)'
pj_is "[c('S02')['done'], c('S02')['pieces'], c('S02')['who']]" '[1, 2, "ana"]' "S02's pieces and who has it"
pj_is "c('S02')['url']" 'https://github.com/owner/code/issues/2' "S02's link"
pj_is "c('S02')['pulls']" '[{"n": 11, "url": "https://github.com/owner/code/pull/11", "draft": false}]' "S02's pull requests"
pj_is "[c('S02')['ready'], c('S02')['drafts']]" '[1, 0]' "S02's pull requests, counted"
! grep -q 'over open-tickets' "$LJ" || fail "S04's limit warning is in the list"
# the teams are sections of their own, each with its three tracks; each step in its team, release and track
pj_is "[t['name'] for t in d['teams']]" '["alpha", "beta"]' 'the teams'
pj_is "[k['name'] for k in d['teams'][0]['releases'][1]['tracks']]" '["alpha, track 1", "alpha, track 2", "alpha, track 3"]' "alpha's tracks"
for x in 'S01|alpha|0|1' 'S02|alpha|1|2' 'S03|alpha|1|3' 'S04|beta|1|1' 'S05|beta|2|2'; do IFS='|' read -r s t r k <<X
$x
X
  pj_is "where('$s')" "[[\"$t\", $r, \"$t, track $k\"]]" "$s's place"; done
# every count is next.sh triggers' own
grep -q '^count	' "$T/trig" || fail 'the call printed no count line'
awk -F'\t' '$1 == "count" && ($2 == "total" || $3 + 0) { print $3 }' "$T/trig" | paste -sd ' ' - > "$T/want"; printf '1\n' >> "$T/want"
[ "$(pj "' '.join(str(x['n']) for x in d['rest']['counts'])")" = "$(paste -sd ' ' - < "$T/want")" ] || fail "the counts are not the call's, then important=1: $(pj "d['rest']['counts']")"
# a ticket of no step, a ticket not read, a step in no team's lane: each still on the board
{ printf 'published 4 kind=step step=S99 rows=ROW-017 plan=p1 base=b1 export=e1 parts=1 at=2026-11-12T09:00:00Z words="go"\n'
  printf 'published 5 kind=step step=S05 rows=ROW-017 plan=p1 base=b1 export=e1 parts=1 at=2026-11-12T09:00:00Z words="go"\n'; } >> .vid/tw/log
printf 'ticket\t4\tOPEN\t-\t2026-11-12T09:00:00Z\n' >> .vid/round/read
pt_rs 's/^\(step S04 .*lane:\) beta-1/\1 gamma-1/'; grep -q '^step S04 .*lane: gamma-1' .vid/RUN-STATE.md || fail "S04's lane was not changed"
pp_write "$T/trig"; [ "$PP_RC" = 0 ] || fail "the second write failed ($PP_RC)"
pj_is "[t['name'] for t in d['teams']]" '["alpha", "beta", "Lanes no team of the setup holds", "Tickets of no step in the plan"]' 'the sections after the teams'
pj_is "[x['id'] for x in cs]" '["S01", "S02", "S03", "S05", "S04", "S99"]' 'each step once, and the ticket of no step'
pj_is "c('S99')['ticket']" 4 '#4'
pj_is "[c('S05')['ticket'], c('S05')['notes']]" '[5, ["#5 was not read at this call"]]' '#5, not in the read'
pj_is "where('S04')[0][0]" 'Lanes no team of the setup holds' 'S04, in a lane no team holds'
echo 'manual-plan-page: ok'
