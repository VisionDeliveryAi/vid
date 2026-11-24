#!/bin/sh
# Purpose: selftest case — the progress of a long call, its verbs (FB-3 D2), the same in a develop project's folder and in a
# ticket-mode one's. `face.sh wait on "<part>"` makes the part of that name now, those before it done, by its words; `wait now
# "<words>"` sets the sentence alone; `wait stop "<what it needs>"` makes the running part stopped and is kept through any on and
# now until the next parts or done, with or without parts; on and now where no parts are named, and on with no part of that name,
# do nothing and write nothing under .vid/face, exit 0; parts, at and done stand as they were. No words, two, or words of spaces
# are refused, the file as it was. lib.sh's `prog` runs them, prints nothing and never fails the call: with a face.sh that fails,
# or none, the script that sourced it goes on under `set -e`. /vid mode auto says the same parts as /vid mode manual, in order, on
# GitHub manual's toy (fixtures/manual.sh): a refusal leaves the part stopped with what it needs, the switch clears them. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "progress-shared: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
w() { python3 -c "import json; d=json.load(open('.vid/face/standing.json'))['wait']; print([(p['name'], p['state']) for p in d['parts']], d['now'], '|', d['stop'])" | sed 's/ *$//'; }
fw() { RC=0; sh "$CHECKS/face.sh" wait "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "wait $* exited $RC"; }
no() { RC=0; sh "$CHECKS/face.sh" wait "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail "wait $* was taken"; cmp -s "$T/was" .vid/face/wait || fail "a refused wait $* changed the file"; }
for kind in develop tickets; do
  mkdir "$T/$kind"; cd "$T/$kind"; git init -q .; mkdir .vid; printf 'mode: %s\nrun: active\n' "$kind" > .vid/RUN-STATE.md
  [ "$kind" = develop ] || { mkdir .vid/tw; printf 'repo: owner/code\n' > .vid/tw/settings; }
  fw on 'Reading GitHub'; fw now 'ticket 1 of 3'; [ ! -e .vid/face ] || fail "$kind: on and now with no parts wrote .vid/face"
  fw parts 'Connecting' 'Reading GitHub' 'Saving'; fw on 'Reading GitHub'
  [ "$(w)" = "[('Connecting', 'done'), ('Reading GitHub', 'now'), ('Saving', 'to come')]  |" ] || fail "$kind: on gives $(w)"
  fw now 'ticket 7 of 21, 1 new so far'
  [ "$(w)" = "[('Connecting', 'done'), ('Reading GitHub', 'now'), ('Saving', 'to come')] ticket 7 of 21, 1 new so far |" ] || fail "$kind: now gives $(w)"
  cp .vid/face/wait "$T/was"; fw on 'A part of another call'; cmp -s "$T/was" .vid/face/wait || fail "$kind: on with no part of that name changed the file"
  for a in on now stop; do no "$a"; no "$a" ''; no "$a" '  '; no "$a" x y; done
  no on at 2; no frob
  fw on 'Saving'; [ "$(w)" = "[('Connecting', 'done'), ('Reading GitHub', 'done'), ('Saving', 'now')]  |" ] || fail "$kind: on a later part gives $(w)"
  fw stop 'your yes to the plan'
  [ "$(w)" = "[('Connecting', 'done'), ('Reading GitHub', 'done'), ('Saving', 'stopped')] your yes to the plan | your yes to the plan" ] || fail "$kind: stop gives $(w)"
  cp .vid/face/wait "$T/was"; fw on 'Connecting'; fw now 'more'; cmp -s "$T/was" .vid/face/wait || fail "$kind: on or now after a stop changed it"
  fw parts 'One' 'Two'; [ "$(w)" = "[('One', 'to come'), ('Two', 'to come')]  |" ] || fail "$kind: the next parts did not end the stop: $(w)"
  fw stop 'your answers to the setup'; fw 'done'; [ ! -e .vid/face/wait ] && [ "$(w)" = '[]  |' ] || fail "$kind: done left the wait"
  fw stop 'your answers to the setup'; [ "$(w)" = '[] your answers to the setup | your answers to the setup' ] || fail "$kind: a stop with no parts gives $(w)"
  fw 'done'
  python3 -c "import json,sys; d=json.load(open('.vid/face/standing.json'))['wait']; sys.exit(d['written'] != '')" || fail "$kind: no wait, yet written"
  fw parts A B; python3 -c "import json,sys; d=json.load(open('.vid/face/standing.json'))['wait']; sys.exit(d['written'][:2] != '20')" || fail "$kind: the parts do not say when they were written"
done
# prog
mkdir "$T/c" "$T/n"; cp "$CHECKS/lib.sh" "$T/c/"; cp "$CHECKS/lib.sh" "$T/n/"; printf 'echo called "$@" >> "%s/calls"; echo loud; exit 1\n' "$T" > "$T/c/face.sh"
for d in c n; do ( set -eu; HERE=$T/$d; cd "$T/tickets"; . "$HERE/lib.sh"; prog on 'Reading GitHub'; echo went on ) > "$T/out" 2>&1 || fail "prog with a failing or missing face.sh ($d) failed its script"
  [ "$(cat "$T/out")" = 'went on' ] || fail "prog printed something ($d)"; done
[ "$(cat "$T/calls")" = 'called wait on Reading GitHub' ] || fail "prog runs face.sh with: $(cat "$T/calls" 2>/dev/null)"
# /vid mode auto: the same parts
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true; rm -rf "$T/dev"
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
mn_project "$T/p"; mkdir checks "$T/nohooks"; ( cd "$CHECKS" && tar cf - --exclude ./selftest . ) | ( cd checks && tar xf - ); mv checks/face.sh checks/face-real.sh
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/calls"\nexec sh "${0%%/*}/face-real.sh" "$@"\n' "$T" > checks/face.sh
git config core.hooksPath "$T/nohooks"; git add -A; git commit -qm 'checks'; CHECKS=$PWD/checks
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; cp "$T/mo" "$T/out"; [ "$MN_RC" = 0 ] || fail "the switch to manual exited $MN_RC"
auto_() { : > "$T/calls"; MN_RC=0; sh checks/mode.sh auto --register "$T/register" --review "$T/review" "$@" > "$T/out" 2>&1 || MN_RC=$?; grep '^wait ' "$T/calls" | sed 's/^wait //' > "$T/w" || :; }
auto_; [ "$MN_RC" = 1 ] && [ "$(tail -n 1 "$T/w")" = 'stop your yes to the plan' ] || { cat "$T/w" >> "$T/out"; fail "the switch to auto with no yes exited $MN_RC, or does not say it needs the yes"; }
auto_ --words 'yes, auto'; [ "$MN_RC" = 0 ] || fail "the switch to auto exited $MN_RC"
grep -qxF "parts Connecting and checking the project Finding the published tickets Reading each ticket Comparing their tests with the spec Writing the plan down Checking the plan Recording your approval Saving the records" "$T/w" && [ "$(tail -n 1 "$T/w")" = 'done' ] && [ ! -e .vid/face/wait ] || { cat "$T/w" >> "$T/out"; fail 'the switch to auto does not name the same parts, or leaves them'; }
[ "$(sed -n 's/^on //p' "$T/w" | grep -vx -e 'Reading GitHub' -e 'Working out what changed' | paste -sd '|' -)" = 'Connecting and checking the project|Finding the published tickets|Reading each ticket|Comparing their tests with the spec|Writing the plan down|Checking the plan|Recording your approval|Saving the records' ] || { cat "$T/w" >> "$T/out"; fail 'the parts of the switch to auto do not run each once, in order'; }
exit 0
