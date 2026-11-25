#!/bin/sh
# Purpose: selftest case — the plan and the teams as text, where there is no panel (FB-5 A1, S5). On the toy of the board
# (fixtures/plan-page.sh), `next-page.sh text` prints section 5, a line a release with how many are accepted and who builds, then what
# holds the rest up, then a section a team, numbered from 6, a step a line with what its card says. It writes nothing, and holds
# nothing of sections 1 to 4. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "list-text: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
pp_toy "$T/toy"; pp_scene; mkdir -p .vid/decide/queue
printf 'Q1\tk1\tto do\tyou\tthe first item\tanswer\t-\t2026-11-18T09:00:00Z\t-\n' > .vid/decide/queue/backlog
printf 'step-1-abc 1 abc at=2026-11-12T09:00:00Z\n' > .vid/decide/accepted-at
printf 'sorted 2026-11-19T09:00:00Z\nstate sorted\nline todo 1.1 Q1\ntitle A title\ndo Say\nwhat It\nask Which?\nchoice Yes\nthen Next\nrelease 1 It waits on the feeds\nname ana Ana B.\n' > "$T/sorted"
find . -type f -exec cksum {} + | sort > "$T/b4"
sh "$T/ck/next-page.sh" text "$T/trig" > "$T/pw" 2>&1 || fail 'next-page.sh text failed'
find . -type f -exec cksum {} + | sort > "$T/aft"; cmp -s "$T/b4" "$T/aft" || fail 'text wrote something'
sed 's/, [0-9][0-9]* days* ago/, N days ago/; s/sent \([0-9]* [A-Z][a-z]*\) [0-9][0-9]*,/sent \1,/' "$T/pw" > "$T/got"
cat > "$T/want" <<'W'
5. The plan: 3 releases, 5 steps, 2 teams
Release 0 · The walking skeleton: 1 of 1 step accepted.
Release 1 · The daily digest: 0 of 3 steps accepted. 1 being built, by Ana B.; 1 not sent yet. 1 sent and nobody has it; b waits on nothing. It waits on the feeds
Release 2 · Synonym-aware search: 0 of 1 step accepted. None sent yet.
What holds the rest up: 2 steps; 4 steps not accepted, and 2 of the other 2 build on them.
a. new jobs only, each listed once (S02): Ana B., 1 of 2 pieces done; 2 build on it
W
head -n 6 "$T/got" | diff - "$T/want" > "$T/d" || { cat "$T/d" >&2; fail 'section 5 is not as it should be'; }
grep -qE '^b\. the footer, unsubscribe and the mail provider \(S03\): nobody has it, [0-9]+ days; 1 build on it$' "$T/got" || fail 'S03 is not under what holds the rest up'
cat > "$T/want" <<'W'
6. Team alpha: 3 steps: 1 accepted, 1 being built, 1 nobody has
  Release 0 · The walking skeleton: 1 step: 1 accepted
S01 · save a search and read the first digest · Accepted · #1 · sent 10 Nov, N days ago · 2 tests
  Release 1 · The daily digest: 2 steps: 1 being built, 1 nobody has
S02 · new jobs only, each listed once · Being built · #2 · 1 of 2 pieces done · Ana B. · pull requests 1 ready, 0 drafts: #11 · sent 10 Nov, N days ago · builds on nothing that is not accepted · holds up 2 later steps · 3 tests
S03 · the footer, unsubscribe and the mail provider · Nobody has it · #3 · sent 12 Nov, N days ago · builds on nothing that is not accepted · holds up 1 later step · 2 tests
7. Team beta: 2 steps: 2 not sent yet
  Release 1 · The daily digest: 1 step: 1 not sent yet
S04 · limits, backups, failures and the data move · Not sent yet · builds on new jobs only, each listed once; the footer, unsubscribe and the mail provider · 7 tests
  Release 2 · Synonym-aware search: 1 step: 1 not sent yet
S05 · synonym-aware search · Not sent yet · builds on new jobs only, each listed once · 1 test
W
sed -n '/^6\. /,$p' "$T/got" | diff - "$T/want" > "$T/d" || { cat "$T/d" >&2; fail 'the teams are not as they should be'; }
! grep -q 'A title\|the first item' "$T/pw" || fail 'the text holds a line of sections 1 to 4'
echo 'list-text: ok'
