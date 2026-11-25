#!/bin/sh
# Purpose: selftest case — the planner is run for the panel's list only when what it reads changed (FB-5 A1). On the toy of the board
# (fixtures/plan-page.sh), with a stand-in planner.sh that counts its runs and calls the real one: the first write runs `planner.sh
# teams` and `steps` once each and keeps the two in .vid/face/plan.cache under a key; a write with nothing changed, one with the read
# or the backlog changed, one with the working tree's INVENTORY.md changed (the planner reads the applied commit's there) and `text` run
# neither, and the list is the same but for its time. A change of each input is seen: the plan block, the setup's teams, the setup's
# answers, the log, a published ticket's stage in its recorded writing, the applied commit's INVENTORY.md and STAGES.md, HEAD's
# PLAN.md, and a script the two read by. A cache that is cut or another's is not read; a run that fails keeps none and is tried
# again. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "list-plan-cache: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
pp_toy "$T/toy"; pp_scene; mkdir -p .vid/decide/queue .vid/tw/out
rm "$T/ck/planner.sh"; printf '#!/bin/sh\necho "$1" >> "%s"\n[ ! -f "%s" ] || exit 1\nexec sh "%s" "$@"\n' "$T/runs" "$T/broken" "$CHECKS/planner.sh" > "$T/ck/planner.sh"
# w <what> <n>: a write, its runs of the planner n
w() { : > "$T/runs"; pp_write "$T/trig"; [ "$PP_RC" = 0 ] || fail "the write failed ($PP_RC): $1"; n=$(grep -c . "$T/runs" || :); [ "$n" = "$2" ] || fail "$1: the planner was run $n times ($(paste -sd ' ' - < "$T/runs")), not $2"; }
body() { sed 's/"written":"[^"]*"//' "$LJ"; }
cm() { git -c user.email=vid@selftest -c user.name=vid commit -qam "$1"; }
w 'the first write' 2; [ "$(sort "$T/runs" | paste -sd ' ' -)" = 'steps teams' ] || fail "it ran $(paste -sd ' ' - < "$T/runs"), not steps and teams"
body > "$T/l1"; [ -s .vid/face/plan.cache ] || fail 'nothing is kept'
w 'nothing changed' 0; body > "$T/l2"; cmp -s "$T/l1" "$T/l2" || fail 'the list from what is kept is another list'
printf 'Q1\tk1\tto do\tyou\tthe first\tanswer\t-\t2026-11-18T09:00:00Z\t-\n' > .vid/decide/queue/backlog; printf 'issue\t9\t-\t-\t2026-11-18T09:00:00Z\n' >> .vid/round/read; w 'the read and the backlog' 0
cp INVENTORY.md "$T/inv"; echo '<!-- a note -->' >> INVENTORY.md; w 'the working tree'"'"'s INVENTORY.md' 0; cp "$T/inv" INVENTORY.md
: > "$T/runs"; sh "$T/ck/next-page.sh" text "$T/trig" > "$T/pw" 2>&1 || fail 'text failed'; [ ! -s "$T/runs" ] || fail 'text ran the planner'
# each input
pt_rs 's/^\(step S05 | name:\) synonym-aware search/\1 synonym search/'; w 'the plan block' 2; pj_is "c('S05')['name']" 'synonym search' 'the plan block'
w 'the plan block, again' 0
sed -i.bak 's/^team: beta | the feeds/team: beta | the feeds and the mail/' .vid/tw/settings; w 'the teams' 2; pj_is "d['teams'][1]['area']" 'the feeds and the mail' 'the teams'
printf 'setup-answered key=split value="unit" words="x" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup; w "the setup's answers" 2
printf 'published 4 kind=step step=S04 rows=ROW-002 plan=p1 base=b1 export=e1 parts=1 at=2026-11-12T09:00:00Z words="go"\n' >> .vid/tw/log; w 'the log' 2
printf '# Step ticket S04\n\n## Header\n\n- stage: 2, the second\n' > .vid/tw/out/issue-4.md; w "a published ticket's stage" 2; pj_is "where('S04')[0][1]" 2 "a published ticket's stage"
sed -i.bak 's/\(^ROW-017 .*\)$/\1 | origin-note: x/' INVENTORY.md; rm -f INVENTORY.md.bak; cm inventory; w 'a commit not applied yet' 0; git rev-parse HEAD > .vid/tw/applied; w "the applied commit's INVENTORY.md" 2
sed -i.bak 's/^STAGE-2 | Synonym-aware search/STAGE-2 | Synonyms/' STAGES.md; rm -f STAGES.md.bak; cm stages; git rev-parse HEAD > .vid/tw/applied; w "the applied commit's STAGES.md" 2
echo '<!-- a note -->' >> PLAN.md; cm plan; w "HEAD's PLAN.md" 2
echo '# a newer planner' >> "$T/ck/planner.sh"; w 'the planner itself' 2; w 'nothing changed, at the end' 0
# a cache cut, or another's
body > "$T/l1"; head -n 2 .vid/face/plan.cache > "$T/c"; cp "$T/c" .vid/face/plan.cache; w 'a cache cut' 2; body > "$T/l2"; cmp -s "$T/l1" "$T/l2" || fail 'a cut cache was read'
sed -i.bak '1s/.*/key 1/' .vid/face/plan.cache; rm -f .vid/face/plan.cache.bak; w "another's cache" 2
# a run that fails is not kept
touch "$T/broken"; pt_rs 's/^\(step S05 | name:\) synonym search/\1 the search/'; : > "$T/runs"; pp_write "$T/trig"; [ "$PP_RC" = 1 ] || fail "a planner that fails exits $PP_RC"
rm "$T/broken"; w 'after a failure' 2; pj_is "c('S05')['name']" 'the search' 'after a failure'
echo 'list-plan-cache: ok'
