# Purpose: selftest fixture — the owner's list, .vid/face/list.json (FB-5 A1; the plan page's toy, GM-2 T12). Sourced after
#   planner-toy.sh (Env: CHECKS, T, fail()).
# pp_toy <dir>: the planner's toy there (planner-toy.sh), entered, in GitHub manual: two teams of three tracks each (team alpha,
#   lanes alpha-1 to alpha-3: S01 of stage 0, S02 and S03 of stage 1; team beta, lanes beta-1 to beta-3: S04 of stage 1, S05 of
#   stage 2, so beta's stage 2 comes after alpha's), the spec committed under git with .vid/ ignored and recorded as the applied
#   version, .vid/tw/settings naming the code repository owner/code and the labels vid:, $T/home as the caller's home, and $T/ck, the
#   scripts of checks/ with a stand-in queue.sh whose `sorted` prints $T/sorted (`state none` until a case writes it; none when the
#   case removes it: the read fails) and whose other verbs are the real one's
# pp_scene: the toy's call: #1 (S01) closed, #2 (S02) open, assigned and given two units (#7 open, #8 closed) with pull request
#   #11 open for it, #3 (S03) open and not taken; S04 and S05 not issued, each with its publish move, S04 with a limit warning;
#   .vid/round/read and the log written, the lines file $T/trig made (pp_trig, then the §5 forms a call hands on)
# pp_trig <file>: the real next.sh triggers' count and counted lines (the counts, unchanged since phase 1) into the file
# pp_write <lines file>: sh checks/next-page.sh write with HOME=$T/home; PP_RC its exit, $T/pw its output; $LJ the list
# pj <python expression>: printed, with d the list, cs its cards in order, c(<id>) the card of a step
pp_toy() {
  pt_toy "$1"
  pt_rs 's/^\(step S01 .*lane:\) devagent/\1 alpha-1/; s/^\(step S02 .*lane:\) devagent/\1 alpha-2/; s/^\(step S03 .*lane:\) devagent/\1 alpha-3/; s/^\(step S04 .*lane:\) devagent/\1 beta-1/; s/^\(step S05 .*lane:\) devagent/\1 beta-2/'
  mkdir -p .vid/tw; printf 'repo: owner/code\nspec-repo: owner/code-spec\nstate-repo: owner/vid-state\nlabels-prefix: vid:\nlayout: separate\nsplit: journey\nslack-channels: none\n' >> .vid/tw/settings
  pt_teams 'alpha | the pages | core | 3' 'beta | the feeds | core | 3'
  git init -q; printf '.vid/\n' > .gitignore; git -c user.email=vid@selftest -c user.name=vid add -A; git -c user.email=vid@selftest -c user.name=vid commit -qm 'the spec'
  printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
  mkdir -p .vid/round "$T/home" "$T/ck"; git rev-parse HEAD > .vid/tw/applied
  for x in "$CHECKS"/*; do [ "$x" = "$CHECKS/queue.sh" ] || ln -s "$x" "$T/ck/" ; done
  printf '#!/bin/sh\n[ "${1:-}" != sorted ] || { cat "%s" || exit 1; exit 0; }\nexec sh "%s" "$@"\n' "$T/sorted" "$CHECKS/queue.sh" > "$T/ck/queue.sh"
  echo 'state none' > "$T/sorted"; LJ=.vid/face/list.json
}
pp_trig() { sh "$CHECKS/next.sh" triggers > "$T/trig.raw" 2>&1 || { cat "$T/trig.raw" >&2; fail 'next.sh triggers failed'; }
  grep -E '^(count|counted)	' "$T/trig.raw" > "$1" || fail 'next.sh triggers printed no count'; }
pp_scene() {
  { printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 plan=p1 base=b1 export=e1 parts=1 at=2026-11-10T09:00:00Z words="go"\n'
    printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005,ROW-008 plan=p1 base=b1 export=e1 parts=1 at=2026-11-10T09:00:00Z words="go"\n'
    printf 'published 3 kind=step step=S03 rows=ROW-006,ROW-007 plan=p1 base=b1 export=e1 parts=1 at=2026-11-12T09:00:00Z words="go"\n'; } > .vid/tw/log
  { printf 'issue\t2\t-\t-\t2026-11-18T09:00:00Z\nissue\t3\t-\t-\t2026-11-18T09:00:00Z\n'
    printf 'open\t11\t2\tabc123\tfalse\t-\t0\t0\t2026-11-18T09:00:00Z\t-\n'
    printf 'ticket\t1\tCLOSED\t-\t2026-11-10T09:00:00Z\nticket\t2\tOPEN\tana\t2026-11-10T09:00:00Z\nticket\t3\tOPEN\t-\t2026-11-12T09:00:00Z\n'
    printf 'body\t2\t- ROW-001\nbody\t3\t- ROW-006\n'
    printf 'sub\t2\t2\t7\tOPEN\tana\tUnit one\nsub\t2\t2\t8\tCLOSED\t-\tUnit two\n'; } > .vid/round/read
  pp_trig "$T/trig"
  { printf 'trigger\timportant\tnot-taken\t#3\tcreated 2026-11-12T09:00:00Z, 7 days ago; no vid: claimed comment, assignee or sub-issue\n'
    printf 'tiers\tcritical=0\timportant=1\tunchanged=0\tminor=0\tdeclined=0\n'
    printf 'move\tpublish\tS04\th-s04\tpublish step S04\n'
    printf 'warning\tpublish\tS04\tlimit\t3 open tickets, 4 with this one, over open-tickets: 3\twork spread, the plan fixed early\n'
    printf 'move\tpublish\tS05\th-s05\tpublish step S05\n'; } >> "$T/trig"
}
pp_write() { PP_RC=0; HOME="$T/home" sh "$T/ck/next-page.sh" write "$1" > "$T/pw" 2>&1 || PP_RC=$?; }
pj() { python3 -c "
import json, sys
d = json.load(open('$LJ')); cs = [x for t in d['teams'] for r in t['releases'] for k in r['tracks'] for x in k['cards']]
c = lambda i: [x for x in cs if x['id'] == i][0]
where = lambda i: [(t['name'], r['n'], k['name']) for t in d['teams'] for r in t['releases'] for k in r['tracks'] for x in k['cards'] if x['id'] == i]
v = eval(sys.argv[1]); print(v if isinstance(v, str) else json.dumps(v))" "$1"; }
pj_is() { _v=$(pj "$1" 2>&1) || _v="(no value: $_v)"; [ "$_v" = "$2" ] || fail "$3: $_v, not $2"; }
