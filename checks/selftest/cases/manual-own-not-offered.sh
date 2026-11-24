#!/bin/sh
# Purpose: selftest case — an own proposal that cannot be made is not offered (FB-3 C5 e, f). On the form fixture's toy in GitHub
# manual, S02 posted as #N2, ROW-012 reworded and committed; a line out of form then on the handed record, so `replan.sh own` refuses. Named,
# implement-replan is refused with the first refusal line, nothing applied, and nothing left behind; from then on no call, page or
# queue line offers it, no call asks for it, and planning-analysis says why; a call that changes nothing keeps it so. The line gone,
# it is offered and asked again. And `decline team-no-lane <team>` declines that team's trigger. Env: CHECKS.
# selftest-limit: 1800 s
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "manual-own-not-offered: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N2=$FM_N
sed 's/at the stated size of 10,000 active jobs/at the stated size of 20,000 active jobs/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; g commit -qam 'ROW-012 reworded'
pt_teams 'devagent | the whole product | core | 1' 'beta | team: the far side | core | 1'
CLAUDE_CODE_SESSION_ID=own-not-case; export CLAUDE_CODE_SESSION_ID; HOME=$T/home; export HOME; mkdir -p "$HOME"
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
A0=$(cat .vid/tw/applied)
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the call exited $RC"; sh "$CHECKS/next.sh" triggers > "$T/L" 2>/dev/null || fail 'next.sh triggers failed'; }
ir() { grep -c "^move${TB}implement-replan${TB}" "$T/L" || :; }
off() { [ "$(ir)" = 0 ] || fail "$1: implement-replan is listed"; ! grep -q '^proposal due' "$T/out" || fail "$1: the call asks to make it"
  ! sh "$CHECKS/queue.sh" list 2>/dev/null | grep -q "${TB}move:implement-replan:" || fail "$1: the queue offers it"
  P=$(sed -n 's/^page //p' "$T/out"); [ -f "$P" ] && ! grep -q 'vid next implement-replan' "$P" || fail "$1: the page offers it"
  grep "^move${TB}planning-analysis${TB}" "$T/L" | grep -q 'implement-replan is not listed, its own proposal could not be made: ViD writer: refused — \.vid/tw/handed' || { cp "$T/L" "$T/out"; fail "$1: planning-analysis does not say why"; }; }
call; [ "$(ir)" = 1 ] && grep -q '^proposal due' "$T/out" || { cat "$T/L" >> "$T/out"; fail 'implement-replan is not offered and asked'; }
# f: the team with no lane, declined by its name
grep -q "^trigger${TB}important${TB}team-no-lane${TB}beta${TB}" "$T/L" || grep -q "^quiet${TB}important${TB}team-no-lane${TB}beta${TB}" "$T/L" || { cp "$T/L" "$T/out"; fail 'the toy raises no team-no-lane trigger'; }
call decline team-no-lane beta 'it starts next year'
grep -q '^done decline team-no-lane beta: 1 declined' "$T/out" || fail 'decline team-no-lane beta declined nothing'
grep -q "^quiet${TB}important${TB}team-no-lane${TB}beta${TB}.*${TB}declined\$" "$T/L" || { cp "$T/L" "$T/out"; fail 'the declined trigger is raised still'; }
# e: what own reads, broken (a record the writer refuses to read)
cp .vid/tw/handed "$T/kept"; printf 'row ROW-001 nonsense\n' >> .vid/tw/handed
call; call implement-replan 'Yes, make it'
grep -q "^refused implement-replan -.*the apply's own proposal could not be made: ViD writer: refused — \.vid/tw/handed" "$T/out" || fail 'named, it is not refused with the first refusal line'
[ "$(cat .vid/tw/applied)" = "$A0" ] && [ ! -d .vid/next/proposal ] && [ -z "$(ls -d .vid/next/.proposal.* 2>/dev/null)" ] || fail 'the refused making applied something or left something behind'
off 'the call it was refused in'
call; off 'the next call'
cp "$T/kept" .vid/tw/handed; call
[ "$(ir)" = 1 ] && grep -q '^proposal due' "$T/out" || { cat "$T/L" >> "$T/out"; fail 'with the reason gone it is not offered and asked again'; }
echo 'manual-own-not-offered: ok'
