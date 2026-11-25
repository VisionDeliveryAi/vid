#!/bin/sh
# Purpose: selftest case — the board's readings, one by one (FB-5 A1). On the toy of the board (fixtures/plan-page.sh): a closed ticket
# not accepted is being built and says so; a ticket accepted on the merges' record alone is accepted, its card still showing who has it and its open
# pull requests; a pull request naming a piece is on its ticket's step; a step with a fix ticket too is one card, its step ticket shown, the fix a
# note, and accepted once both are; a withdrawn ticket is on none; a ticket not read at this call is as the read before had it, else taken, and says so;
# a `vid: claimed` comment is taken; who has a step with no piece open is who had its pieces; a step of no ticket is accepted when each of its
# tests is accepted or paid, never held or owed; a step in no stage is in no release; with one lane a step naming none is in it; and a
# plan of no step is counted as 0 steps. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "list-board: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
w_() { pp_write "$T/trig"; [ "$PP_RC" = 0 ] || fail "next-page.sh write failed ($PP_RC)"; }
pp_toy "$T/toy"; pp_scene; mkdir -p .vid/decide/queue; R=.vid/round/read; cp "$R" "$T/read"; cp .vid/tw/log "$T/log"
# closed, not accepted
w_; pj_is "[c('S01')['state'], c('S01')['notes']]" '["building", ["Its ticket is closed; it is not accepted yet"]]' 'closed, not accepted'
# accepted on the merges' record alone; who has it and its open pull request stay on the card
printf 'step-1-abc\t1\tabc\tabc\n' > .vid/decide/merges; sed -i.bak 's/^ticket	1	CLOSED	-/ticket	1	CLOSED	cy/' "$R"; printf 'open\t13\t1\tabd\ttrue\t-\t0\t0\t2026-11-18T09:00:00Z\t-\n' >> "$R"; w_
pj_is "[c('S01')['state'], c('S01')['notes']]" '["accepted", []]' 'accepted on the merges alone'
pj_is "[c('S01')['who'], c('S01')['drafts'], [x['n'] for x in c('S01')['pulls']]]" '["cy", 1, [13]]' "an accepted step's people and open pull request"
# a pull request naming a piece
printf 'open\t14\t7\tabe\ttrue\t-\t0\t0\t2026-11-18T09:00:00Z\t-\n' >> "$R"; w_
pj_is "[[x['n'] for x in c('S02')['pulls']], c('S02')['ready'], c('S02')['drafts']]" '[[11, 14], 1, 1]' 'a pull request naming a piece'
# a step with a fix ticket too: one card; accepted once both are
printf 'published 6 kind=fix step=S02 rows=ROW-005 plan=p1 base=b1 export=e1 parts=1 at=2026-11-14T09:00:00Z words="go"\n' >> .vid/tw/log; printf 'ticket\t6\tOPEN\t-\t2026-11-14T09:00:00Z\n' >> "$R"; w_
pj_is "[[x['id'] for x in cs].count('S02'), c('S02')['ticket'], c('S02')['notes'], c('S02')['tests']]" '[1, 2, ["Also #6, a fix ticket, open"], 3]' 'a step with a fix ticket too'
printf 'step-2-abc 2 abc at=2026-11-15T09:00:00Z\n' > .vid/decide/accepted-at; w_; pj_is "c('S02')['state']" building 'one of two tickets accepted'
printf 'step-6-abc 6 abc at=2026-11-16T09:00:00Z\n' >> .vid/decide/accepted-at; w_; pj_is "c('S02')['state']" accepted 'both tickets accepted'
rm .vid/decide/accepted-at; cp "$T/log" .vid/tw/log; cp "$T/read" "$R"
# a withdrawn ticket is on none
{ printf 'published 8 kind=step step=S04 rows=ROW-002 plan=p1 base=b1 export=e1 parts=1 at=2026-11-14T09:00:00Z words="go"\n'; printf 'withdrawn 8 decision=owner at=2026-11-15T09:00:00Z\n'; } >> .vid/tw/log; printf 'ticket\t8\tCLOSED\t-\t2026-11-14T09:00:00Z\n' >> "$R"; w_
pj_is "[c('S04')['state'], c('S04')['ticket'], len(cs)]" '["unsent", 0, 5]' 'a withdrawn ticket'; cp "$T/log" .vid/tw/log; cp "$T/read" "$R"
# a ticket not read at this call: as the read before had it, else taken
grep -v '^ticket	3	' "$T/read" > "$R"; printf 'ticket\t3\tOPEN\tbo\t2026-11-12T09:00:00Z\nsub\t3\t3\t31\tCLOSED\tbo\tA\nsub\t3\t3\t32\tOPEN\tbo\tB\n' > .vid/round/read.prev; w_
pj_is "[c('S03')[k] for k in ('state','done','pieces','who','notes')]" '["building", 1, 2, "bo", ["#3 was not read at this call: it is as the call before read it"]]' 'not read at this call, as the read before had it'
rm .vid/round/read.prev; w_; pj_is "[c('S03')['state'], c('S03')['notes']]" '["taken", ["#3 was not read at this call"]]' 'not read at this call, nor before'
# an unread ticket beside the step's own is said to be neither open nor closed
printf 'published 6 kind=fix step=S02 rows=ROW-005 plan=p1 base=b1 export=e1 parts=1 at=2026-11-14T09:00:00Z words="go"\n' >> .vid/tw/log; w_
pj_is "c('S02')['notes']" '["#6 was not read at this call", "Also #6, a fix ticket"]' 'an unread fix ticket'; cp "$T/log" .vid/tw/log; cp "$T/read" "$R"
# a claim is taken
w_; pj_is "c('S03')['state']" nobody 'S03, before the claim'; sed -i.bak 's/^issue	3	-	-/issue	3	-	vid: claimed by bo/' "$R"; w_; pj_is "c('S03')['state']" taken 'a vid: claimed comment'; cp "$T/read" "$R"
# no piece open, nobody on the ticket: who had the pieces
sed -i.bak 's/^ticket	2	OPEN	ana/ticket	2	OPEN	-/; s/^sub	2	2	7	OPEN	ana/sub	2	2	7	CLOSED	dee/' "$R"; w_; pj_is "[c('S02')['done'], c('S02')['who']]" '[2, "dee"]' 'no piece open'; cp "$T/read" "$R"
# a step of no ticket whose tests are accepted or paid
for x in accepted:accepted paid:accepted accepted-by-ruling:accepted held:unsent owed:unsent; do printf 'row ROW-017 %s | stand-in: owner\n' "${x%%:*}" > .vid/tw/handed; w_; pj_is "c('S05')['state']" "${x#*:}" "a step of no ticket, its test ${x%%:*}"; done; rm .vid/tw/handed
# a step in no stage
cp .vid/RUN-STATE.md "$T/rs"; pt_rs 's/^\(step S05 .*\)$/\1\
step S06 | name: the send hour | modules: digest | builds-on: S05 | rows: ROW-020 | lane: beta-3/'; w_
pj_is "[where('S06'), [[r['n'], r['name'], len(r['steps'])] for r in d['plan']['releases']][-1]]" '[[["beta", -1, "beta, track 3"]], [-1, "In no release", 1]]' 'a step in no stage'; cp "$T/rs" .vid/RUN-STATE.md
# one lane: a step naming none is in it
cp .vid/tw/settings "$T/set"; { grep -v '^team:' "$T/set"; echo 'team: alpha | the pages | core | 1'; } > .vid/tw/settings; pt_rs 's/^\(step S0.* lane:\) [a-z]*-[0-9]/\1 -/'; grep -q '^step S04 .* lane: -' .vid/RUN-STATE.md || fail 'the lanes were not taken out'; w_
pj_is "[[t['name'] for t in d['teams']], sorted(x['id'] for x in cs), where('S04')]" '[["alpha"], ["S01", "S02", "S03", "S04", "S05"], [["alpha", 1, "alpha"]]]' 'one lane'
# a plan of no step
pt_rs '/^step /d; /^needs /d'; sh "$T/ck/next-page.sh" text "$T/trig" > "$T/pw" 2>&1 || fail 'text failed'; grep -qxF '5. The plan: 0 releases, 0 steps, 1 team' "$T/pw" || fail 'a plan of no step is not counted as 0 steps'
echo 'list-board: ok'
