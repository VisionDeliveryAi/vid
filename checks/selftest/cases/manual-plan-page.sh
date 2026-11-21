#!/bin/sh
# Purpose: selftest case — the plan page, every step and ticket on it (GM-2 T12). On the planner's toy in GitHub manual with two
# teams of three tracks each, beta's stage 2 after alpha's (fixtures/plan-page.sh): #1 (S01) closed, #2 (S02) open, assigned,
# with two units, one closed, and pull request #11; #3 (S03) open, not taken; S04 and S05 not issued, each publishable, S04 with
# its limit warning. `next-page.sh write` with the call's lines (next.sh triggers' real count lines, then the §5 forms a call
# hands it) prints `page <path>`, the page in the viewer's folder; every step is on it in its own team's section, its stage and
# its lane, each issued one with its ticket's link, state, taken and units, the not-issued ones publishable with S04's warning;
# each count on it is next.sh triggers' own, and the page writes nothing into the project but the to-do log. A second write, with
# #4 published for a step the plan no longer holds (S99), #5 published for S05 and not in the read, and S04's lane one no team of
# the setup gives (gamma-1): #4 is on the page under the tickets of no step, #5 as not read at this call, and S04 under the lanes
# no team holds. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "manual-plan-page: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
pp_toy "$T/toy"; pp_scene
sums() { find . -type f ! -path ./.vid/next/todo -exec cksum {} + | sort; }   # .git too
sums > "$T/before"
pp_write "$T/trig"
[ "$PP_RC" = 0 ] || fail "next-page.sh write failed ($PP_RC)"
grep -qxF "page $PG" "$T/pw" || fail "it did not print the page's path ($PG)"
[ -s "$PG" ] || fail 'no page was written in the viewer'"'"'s folder'
sums > "$T/after"; cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" >&2 || true; fail 'the page changed a file of the project'; }
card() { grep "data-step=\"$1\"" "$PG" || fail "step $1 is not on the page"; }
for s in S01 S02 S03 S04 S05; do card "$s" > /dev/null; done
for n in 1 2 3; do grep -q "data-ticket=\"$n\"" "$PG" || fail "the published ticket #$n is not on the page"; done
card S01 | grep -q 'data-ticket="1" data-state="closed"' || fail 'S01 does not read issued as #1, closed'
card S02 | grep -q 'data-ticket="2" data-state="open" data-taken="yes" data-units="1/2"' || fail 'S02 does not read #2 open, taken, one unit of two closed'
card S02 | grep -q '<span>1 of 2 closed</span>' || fail "#2's card does not say 1 of 2 units closed"
card S02 | grep -q 'href="https://github.com/owner/code/issues/2"' || fail "#2's card holds no link to the ticket"
card S02 | grep -q 'href="https://github.com/owner/code/pull/11"' || fail "#2's card does not name its open pull request #11"
card S02 | grep -q 'class="card open taken"' || fail "#2, taken, has no background of its own"
card S03 | grep -q 'data-ticket="3" data-state="open" data-taken="no"' || fail 'S03 does not read #3 open, not taken'
for s in S04 S05; do card "$s" | grep -q 'data-state="not-issued".*Publishable' || fail "$s does not read not issued and publishable"; done
card S04 | grep -q '3 open tickets, 4 with this one, over open-tickets: 3' || fail "S04's limit warning is not on its card"
card S05 | grep -q 'open-tickets' && fail "S04's warning is on S05's card"
# the teams are sections of their own, each with its three tracks; each step in its team, stage and lane
[ "$(grep -o 'data-team="[a-z-]*"' "$PG" | paste -sd ' ' -)" = 'data-team="alpha" data-team="beta"' ] || fail "the teams' sections are not alpha then beta, alone"
for l in alpha-1 alpha-2 alpha-3 beta-1 beta-2 beta-3; do grep -q "data-lane=\"$l\"" "$PG" || fail "the track $l is not on the page"; done
for x in 'alpha S01' 'alpha S02' 'alpha S03' 'beta S04' 'beta S05'; do pp_in team "${x% *}" "${x#* }" || fail "${x#* } is not in team ${x% *}'s section"; done
for x in '0 S01' '1 S02' '1 S03' '1 S04' '2 S05'; do pp_in stage "${x% *}" "${x#* }" || fail "${x#* } is not under stage ${x% *}"; done
awk '/data-lane="alpha-2"/ { on = 1 } /data-lane="alpha-3"/ { on = 0 } on && /data-step="S02"/ { f = 1 } END { exit !f }' "$PG" || fail "S02 is not in its track alpha-2"
pp_in stage 1 S04 && awk '/data-team="beta"/ { b = 1 } b && /data-stage="1"/ { s = 1 } s && /data-step="S04"/ { f = 1 } END { exit !f }' "$PG" || fail "S04 is not under beta's own stage 1"
# every count is next.sh triggers' own
grep -q '^count	' "$T/trig" || fail 'the call printed no count line'
awk -F'\t' '$1 == "count" { print $2 "\t" $3 }' "$T/trig" | while IFS="$(printf '\t')" read -r k v; do
  grep -q "data-count=\"$k\"><span class=\"v\">$v</span>" "$PG" || fail "the page's $k count is not next.sh triggers' $v"; done
grep -q 'data-tier="important">1 important<' "$PG" || fail "the tiers line's important=1 is not on the page"
# a ticket of no step, a ticket not read, a step in no team's lane: each still on the page
{ printf 'published 4 kind=step step=S99 rows=ROW-017 plan=p1 base=b1 export=e1 parts=1 at=2026-11-12T09:00:00Z words="go"\n'
  printf 'published 5 kind=step step=S05 rows=ROW-017 plan=p1 base=b1 export=e1 parts=1 at=2026-11-12T09:00:00Z words="go"\n'; } >> .vid/tw/log
printf 'ticket\t4\tOPEN\t-\t2026-11-12T09:00:00Z\n' >> .vid/round/read
pt_rs 's/^\(step S04 .*lane:\) beta-1/\1 gamma-1/'; grep -q '^step S04 .*lane: gamma-1' .vid/RUN-STATE.md || fail "S04's lane was not changed"
pp_write "$T/trig"; [ "$PP_RC" = 0 ] || fail "the second write failed ($PP_RC)"
grep -q 'data-ticket="4"' "$PG" && pp_in team no-step S99 || fail '#4, of a step the plan no longer holds, is not on the page under the tickets of no step'
grep -q 'data-ticket="5" data-state="unread"' "$PG" || fail '#5, not in the read, is not on the page as not read'
pp_in team - S04 || fail "S04, in a lane no team holds, is not on the page under the lanes no team holds"
exit 0
