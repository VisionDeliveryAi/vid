#!/bin/sh
# Purpose: selftest case — DevAgent's loop never stops with nothing said, and never for idleness (v0.26.10.28.6, R3), devagent/dev-manager/dm.sh
# on the fake gh and a fake claude, on short times. Red first at 5b39465: with nothing to do past its idle time the loop stays and picks up an
# ask that comes later; at its time limit with nothing open it pushes its stopped report, vid-results/stopped-<k>, one folder, results.txt by DM
# with the stop's words; with work open it also comments `vid: stopped <why>` on each issue it holds work for, and on no other; a second stop
# pushes stopped-<k+1>. Skips where devagent/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
DM=$CHECKS/../devagent/dev-manager/dm.sh; FC_MODEL0=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM"); export FC_MODEL0
T=$(mktemp -d); LP=''; trap '[ -z "$LP" ] || kill "$LP" 2>/dev/null || true; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "devagent-stopped: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat "$W/dm-report.txt" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W=$T/work; mkdir -p "$W/tickets"; DM_WORK=$W; export DM_WORK
note() { printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: %s\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" "$1" > "$W/note.txt"; }
cat > "$T/bin/claude" <<'C'
#!/bin/sh
printf '%s\n' "$*" >> "$FC_LOG"; printf '{"type":"system","subtype":"init","model":"%s"}\n' "$FC_MODEL0"
printf '{"type":"result","subtype":"success","is_error":false,"duration_ms":1000,"num_turns":1,"result":"done"}\n'
C
chmod +x "$T/bin/claude"; FC_LOG=$T/fc; export FC_LOG; : > "$FC_LOG"
g() { gh "$@" > /dev/null; }
DM_TICK=1; DM_IDLE=3; DM_IDLE_TICK=2; DM_FIRST=5; export DM_TICK DM_IDLE DM_IDLE_TICK DM_FIRST
st() { git -C "$T/code.git" for-each-ref --format='%(refname:lstrip=3)' 'refs/heads/vid-results/' | grep -c '^stopped-' || true; }
# red first: idle past DM_IDLE, it stays; an ask that comes later is picked up (a claim, so a dev manager starts)
g issue create -R owner/code --title t1 --body x --label ticket; g issue edit 1 -R owner/code --add-label blocked; note 120
sh "$DM" loop "$W/note.txt" > "$T/out" 2>&1 & LP=$!
sleep 9; kill -0 "$LP" 2>/dev/null || fail 'the loop stopped for idleness'
! grep -q 'nothing to do or to wait for' "$W/dm-report.txt" 2>/dev/null || fail 'the loop wrote an idle stop'
g issue edit 1 -R owner/code --remove-label blocked; n=0; while ! grep -q 'devagent/agents/dev-manager.md' "$FC_LOG" && [ "$n" -lt 20 ]; do sleep 1; n=$((n + 1)); done
grep -q 'devagent/agents/dev-manager.md' "$FC_LOG" || fail 'an ask after the idle time was not picked up'
echo 'enough' > "$W/dm-stop"; wait "$LP" || true; LP=''; rm -f "$W/dm-stop"
# red first: the stop just made is said in a stopped report, one folder, by DM, with the stop's words; the issue it never claimed gets no comment
[ "$(st)" = 1 ] || fail "no stopped report: $(st)"; git -C "$T/code.git" ls-tree --name-only refs/heads/vid-results/stopped-1 | grep -qx 'stopped-1' && [ "$(git -C "$T/code.git" ls-tree --name-only refs/heads/vid-results/stopped-1 | wc -l | tr -d ' ')" = 1 ] || fail 'the stopped report is not one folder'
git -C "$T/code.git" show refs/heads/vid-results/stopped-1:stopped-1/results.txt > "$T/r1"; head -n 1 "$T/r1" | grep -qx 'by: DM' && grep -qx 'stopped: the stop file: enough' "$T/r1" || fail "the stopped report's words: $(cat "$T/r1")"
! ls "$T/gh/issues/1/comments" 2>/dev/null | while read -r c; do awk 'NR == 1' "$T/gh/issues/1/comments/$c"; done | grep -q '^vid: stopped' || fail 'a stop was said on an issue the dev side never claimed'
heads() { ls "$T/gh/issues/$1/comments" 2>/dev/null | while read -r c; do awk 'NR == 1' "$T/gh/issues/$1/comments/$c"; done; }
# red first: at its time limit with nothing open at all, the stop is said in a second report
g issue close 1 -R owner/code; note 4; sh "$DM" loop "$W/note.txt" > "$T/out" 2>&1 || true
[ "$(grep -c 'the loop stopped: the time limit: 4s' "$W/dm-report.txt")" = 1 ] || fail 'no stop at the time limit with nothing open'
[ "$(st)" = 2 ] && git -C "$T/code.git" show refs/heads/vid-results/stopped-2:stopped-2/results.txt | grep -qx 'stopped: the time limit: 4s' || fail "the time limit's stop was not said in stopped-2: $(st)"
! heads 1 | grep -q '^vid: stopped' || fail 'a stop was said on a closed issue'
# red first: with work held, the stop is said on that issue and on no other
g issue create -R owner/code --title t2 --body x --label ticket; g issue comment 2 -R owner/code --body 'vid: claimed'; g issue create -R owner/code --title t3 --body x --label ticket
g issue edit 2 -R owner/code --add-label blocked; g issue edit 3 -R owner/code --add-label blocked; note 4; sh "$DM" loop "$W/note.txt" > "$T/out" 2>&1 || true
[ "$(st)" = 3 ] || fail "the second time limit's stop was not said in stopped-3: $(st)"
c2=$(heads 2 | grep -c '^vid: stopped the time limit: 4s$' || true); [ "$c2" = 1 ] || fail "the held issue got $c2 stop comments: $(heads 2 | tr '\n' '|')"
! heads 3 | grep -q '^vid: stopped' || fail 'a stop was said on an issue the dev side holds no work for'
exit 0
