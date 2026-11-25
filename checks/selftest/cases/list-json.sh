#!/bin/sh
# Purpose: selftest case — the panel's list, whole (FB-5 A1). On the toy of the board (fixtures/plan-page.sh), S01 accepted, a
# stand-in queue.sh printing the sort as it stands: each section holds its lines, whole and in order, every field set; each open item
# of the backlog is in what ViD holds once, with the section it is in (1.1, Waiting, Changed, The rest, The plan) or not sorted yet;
# a person, and a team, is called by the sort's name, and by the login, or
# the setup's name, where the name is gone. The plan's numbers are the toy's own: a release a
# row, a box a step, filled by the pieces done; what holds the rest up is the steps not accepted that build on none and on which
# others build, with how many build on each; a card names only what no other of those it builds on builds on; each step is on one
# card. A test reset by a landing since makes its step not accepted; a step of no ticket whose tests are all accepted is. With no
# sort, the sections of the sort are empty and the rest whole; in GitHub auto there is no plan and no team. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "list-json: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
w_() { pp_write "$T/trig"; [ "$PP_RC" = 0 ] || fail "next-page.sh write failed ($PP_RC)"; }
pp_toy "$T/toy"; pp_scene; mkdir -p .vid/decide/queue
printf 'step-1-abc 1 abc at=2026-11-12T09:00:00Z\n' > .vid/decide/accepted-at
it() { printf '%s\t%s\t%s\tyou\t%s\tan action\t-\t2026-11-18T09:00:00Z\t-\n' "$1" "k$1" "$2" "$3"; }
{ it Q1 'to do' 'the first'; it B2 'to do' 'the second'; it Q3 waiting 'the third'; it Q4 'to do' 'the fourth'; it Q5 'to do' 'the fifth'
  it B6 aside 'the sixth'; it Q7 'to do' 'the seventh'; it Q8 'done' 'the eighth'; it Q9 'to do' 'the ninth'; } > .vid/decide/queue/backlog
cat > "$T/sorted" <<'S'
sorted 2026-11-19T09:00:00Z
state stale
unsorted Q7

line todo 1.1 Q1,B2
title Choose the limit
do Say ten or twenty
new Ana, 10:00
what The limit of saved searches: two proposals
ask Which limit?
about Ten is the one drawn
choice Ten
choice Twenty
choose 2 it is what the team measured
ask Who says it?
message Ana, the limit is twenty.
then The ticket is written again
details Q1, B2

line waiting - Q3
who Ana B.
what the review of the spec
since 18 Nov
details #2

line changed - Q9
what The sign-in step was accepted

line vid - Q4
what Finds out why a test changed
line later - B6
then when the spec is sent
what the two large steps
line team - -
what Four reworded tests, with the next sending
line suggested - -
what Send the next two steps
line left-out - -
what A split nobody asked for
line plan - Q5
what nobody has the third step
release 1 The daily digest waits on the feeds
name ana Ana B.
S
w_
pj_is "[d['format'], d['state'], d['sortedAt'], d['unsorted'], d['title']]" '[1, "stale", "2026-11-19T09:00:00Z", 1, "JobDigest"]' 'the head'
pj_is "d['todo']" '[{"n": "1.1", "ids": ["Q1", "B2"], "title": "Choose the limit", "do": "Say ten or twenty", "isNew": true, "new": "Ana, 10:00", "what": "The limit of saved searches: two proposals", "asks": [{"ask": "Which limit?", "about": "Ten is the one drawn", "choose": 2, "why": "it is what the team measured", "choices": ["Ten", "Twenty"], "message": ""}, {"ask": "Who says it?", "about": "", "choose": 0, "why": "", "choices": [], "message": "Ana, the limit is twenty."}], "then": "The ticket is written again", "details": "Q1, B2"}]' 'My to do'
pj_is "d['waiting']" '[{"who": "Ana B.", "what": "the review of the spec", "since": "18 Nov", "details": "#2"}]' 'Waiting'
pj_is "d['changed']" '["The sign-in step was accepted"]' 'Changed'
pj_is "[d['rest'][k] for k in ('vid','later','team','suggested','leftOut')]" '[["Finds out why a test changed"], [{"when": "when the spec is sent", "what": "the two large steps"}], ["Four reworded tests, with the next sending"], ["Send the next two steps"], ["A split nobody asked for"]]' 'The rest'
pj_is "[[x['id'], x['where']] for x in d['rest']['holds']]" '[["Q1", "1.1"], ["B2", "1.1"], ["Q3", "Waiting"], ["Q4", "The rest"], ["Q5", "The plan"], ["B6", "The rest"], ["Q7", "not sorted yet"], ["Q9", "Changed"]]' 'what ViD holds'
pj_is "d['rest']['holds'][0]['words']" 'the first' "ViD's own words"
# the plan: S01 accepted, S02 and S03 build on nothing not accepted, S04 on both, S05 on S02
pj_is "[[r['n'], r['name'], r['accepted'], r['words']] for r in d['plan']['releases']]" '[[0, "The walking skeleton", 1, ""], [1, "The daily digest", 0, "The daily digest waits on the feeds"], [2, "Synonym-aware search", 0, ""]]' 'the releases'
pj_is "[[s['id'], s['state'], s['fill'], s['flag']] for r in d['plan']['releases'] for s in r['steps']]" '[["S01", "accepted", 100, ""], ["S02", "building", 50, "a"], ["S03", "nobody", 0, "b"], ["S04", "unsent", 0, ""], ["S05", "unsent", 0, ""]]' 'the boxes'
pj_is "[r['say'] for r in d['plan']['releases']]" '["All accepted.", "1 being built, by Ana B.; 1 not sent yet.", "None sent yet."]' 'who builds'
pj_is "[r['stuck'] for r in d['plan']['releases']]" '["", "1 sent and nobody has it; b waits on nothing.", ""]' 'what is stuck'
pj_is "[d['plan']['hold'][k] for k in ('open','others','built')]" '[4, 2, 2]' 'what holds the rest up, counted'
pj_is "[[x['flag'], x['id'], x['who'], x['done'], x['pieces'], x['state'], x['by']] for x in d['plan']['hold']['rows']]" '[["a", "S02", "Ana B.", 1, 2, "building", 2], ["b", "S03", "", 0, 0, "nobody", 1]]' 'what holds the rest up'
pj_is "[[t['name'], t['area'], t['words']] for t in d['teams']]" '[["alpha", "the pages", "3 steps: 1 accepted, 1 being built, 1 nobody has"], ["beta", "the feeds", "2 steps: 2 not sent yet"]]' 'the teams'
pj_is "sorted(x['id'] for x in cs)" '["S01", "S02", "S03", "S04", "S05"]' 'each step is on one card'
pj_is "[[x['id'], x['holdsUp'], x['flag'], x['tests']] for x in cs]" '[["S01", 0, "", 2], ["S02", 2, "a", 3], ["S03", 1, "b", 2], ["S04", 0, "", 7], ["S05", 0, "", 1]]' 'the cards, counted'
pj_is "c('S04')['buildsOn']" '["new jobs only, each listed once", "the footer, unsubscribe and the mail provider"]' 'what S04 builds on'
pj_is "[c('S05')['buildsOn'], c('S02')['buildsOn']]" '[["new jobs only, each listed once"], []]' 'what S05 and S02 build on'
pj_is "[c('S02')['sent'][:6], c('S02')['days'] > 0, c('S02')['testIds']]" '["10 Nov", true, ["ROW-001", "ROW-005", "ROW-008"]]' "S02's sending and tests"
# a direct link to a step that a nearer one builds on is not named again
pt_rs 's/^\(step S05 .*builds-on:\) S02/\1 S02 S04/'; w_
pj_is "[c('S05')['buildsOn'], c('S03')['holdsUp'], c('S02')['holdsUp']]" '[["limits, backups, failures and the data move"], 2, 2]' 'S05 names S04 alone'
pt_rs 's/^\(step S05 .*builds-on:\) S02 S04/\1 S02/'
# the author of an open pull request (C2, the last column) has the step too; a name gone is the login
printf 'open\t12\t3\tabd\ttrue\t-\t0\t0\t2026-11-18T09:00:00Z\t-\tbo\n' >> .vid/round/read; sed -i.bak '/^name /d' "$T/sorted"; w_
pj_is "[[x['state'], x['who'], x['ready'], x['drafts']] for x in (c('S02'), c('S03'))]" '[["building", "ana", 1, 0], ["building", "bo", 0, 1]]' 'the logins, and a draft pull request'
# a team is called by the sort's name for it too, its tracks with it; with none, as the setup has it
echo 'name beta The Feeds' >> "$T/sorted"; w_
pj_is "[[t['name'], t['releases'][0]['tracks'][0]['name']] for t in d['teams']]" '[["alpha", "alpha, track 1"], ["The Feeds", "The Feeds, track 1"]]' "the teams' names"
# the team's blocked label; tests reworded and retired, by the call's counted lines
sed -i.bak 's/^issue	3	-/issue	3	vid:blocked/' .vid/round/read; printf 'counted\trestated\tROW-006\ta\ncounted\tretired\tROW-007\tb\n' >> "$T/trig"; w_
pj_is "c('S03')['notes']" '["The team marked #3 blocked", "1 of its tests was reworded; its ticket holds the older words", "1 of its tests is retired; its ticket still holds it"]' "S03's notes"
pj_is "d['plan']['releases'][1]['stuck']" 'Blocked: the footer, unsubscribe and the mail provider.' 'a blocked step is stuck'
# a landing reset a test of S01's: not accepted, until it is accepted again; S05's one test accepted with no ticket
printf '2026-11-13T09:00:00Z\tROW-003\treset\tlanded at abc\tSP\n' > .vid/decide/rulings; printf 'row ROW-017 accepted-by-ruling | stand-in: owner\n' > .vid/tw/handed; w_
pj_is "[c('S01')['state'], c('S01')['notes'][0], c('S05')['state'], d['plan']['hold']['rows'][0]['id'], d['plan']['hold']['open']]" '["building", "1 test changed after the step was accepted", "accepted", "S01", 4]' 'reset, and accepted with no ticket'
printf 'row ROW-003 accepted | stand-in: owner\n' >> .vid/tw/handed; w_
pj_is "c('S01')['state']" accepted 'S01, accepted again'
# what could not be read, and the report branches left out, are among the counts
printf 'unread\tsub\t2\tthe network\ncontext\treport\tx-1\tits branch holds no report\n' >> "$T/trig"; w_
pj_is "[x['words'] for x in d['rest']['counts']][-2:]" '["part could not be read at the last call, and nothing is counted from it: sub 2: the network", "of the team'"'"'s report branches left out, and nothing of them counted: its branch holds no report"]' 'what could not be read'
# no sort yet
printf 'state none\nunsorted Q1\nunsorted B2\n' > "$T/sorted"; w_
pj_is "[d['state'], d['sortedAt'], d['unsorted'], d['todo'], d['waiting'], d['changed'], d['rest']['vid']]" '["none", "", 2, [], [], [], []]' 'no sort'
pj_is "[len(d['rest']['holds']), d['rest']['holds'][0]['where'], len(cs)]" '[8, "not sorted yet", 5]' 'no sort, the rest whole'
# the default lines file; none kept is no lines
rm -rf .vid/next; HOME="$T/home" sh "$T/ck/next-page.sh" write > "$T/pw" 2>&1 || fail 'write with no lines kept failed'
pj_is "d['rest']['counts']" '[]' 'no lines kept'
mkdir -p .vid/next; cp "$T/trig" .vid/next/lines; HOME="$T/home" sh "$T/ck/next-page.sh" write > "$T/pw" 2>&1 || fail 'write from .vid/next/lines failed'
[ "$(pj "len(d['rest']['counts']) > 2")" = true ] || fail 'the kept lines were not read'
# GitHub auto
sed -i.bak '/github-mode/d' .vid/plan/setup; printf 'sorted 2026-11-19T09:00:00Z\nstate sorted\nline todo 1.1 Q1\ntitle One\ndo Two\nwhat Three\nask Four?\nchoice Five\nthen Six\n' > "$T/sorted"; w_
pj_is "[d['teams'], d['plan'], [x['n'] for x in d['todo']]]" '[[], {"releases": [], "hold": {"open": 0, "others": 0, "built": 0, "rows": []}}, ["1.1"]]' 'GitHub auto'
echo 'list-json: ok'
