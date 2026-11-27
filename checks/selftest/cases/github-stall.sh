#!/bin/sh
# Purpose: selftest case — a git call to GitHub that moves nothing ends, and a read is tried once more (FIX-BATCH-T2 §8, OW-1).
# On the GitHub manual toy, its state repository holding the lock: (a) with the repository's URL on a local server that accepts
# and sends nothing (python3; without it the scene is skipped and the case says so), lock-renew under GIT_HTTP_LOW_SPEED_TIME=2
# and github.sh's own limit ends refused, the lock "could not be read", within 20 seconds (stopped by the case at 30 when it does
# not). A stand-in git first on PATH that logs each ls-remote's environment: (b) github.sh's calls carry GIT_HTTP_LOW_SPEED_LIMIT=1,
# GIT_HTTP_LOW_SPEED_TIME=60 and an ssh command with ConnectTimeout and both keep-alives when none is set; the case's own time
# when it sets one; neither http variable under a global http.lowSpeedLimit and http.lowSpeedTime; no time under a
# GitHub-specific http.https://github.com.lowSpeedTime; no ssh command under core.sshCommand. (c) An ls-remote failing once with
# 128: the take passes, two tries; failing with 2: one try, refused. (d) Every ls-remote and fetch of github.sh is a gn call, and
# each DevAgent script sets all three. VID_NET_WAIT=0. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID GIT_HTTP_LOW_SPEED_LIMIT GIT_HTTP_LOW_SPEED_TIME GIT_SSH_COMMAND GIT_SSH 2>/dev/null || true
T=$(mktemp -d); SP=''; trap '[ -z "$SP" ] || kill "$SP" 2>/dev/null || :; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "github-stall: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; VID_NET_WAIT=0; export VID_NET_WAIT
# (d) first: the reads and the DevAgent scripts, by reading
B=$(awk '!/^[ \t]*#/' "$GS" | grep -nE '(^|[^A-Za-z0-9_./-])(git|G|cg)(( -C "[^"]*"| -C [^ ]+| -c [^ ]+| --git-dir="[^"]*")*) (ls-remote|fetch)([^)A-Za-z]|$)' | grep -vE 'gn (git|G|cg)[^|;]*(ls-remote|fetch)' || true)
[ -z "$B" ] || fail "(d) a read of github.sh not through gn: $(printf '%s' "$B" | head -n 2)"
for f in devagent/dev-manager/dm.sh devagent/test-manager/run.sh devagent/deployer/deploy.sh; do [ -f "$CHECKS/../$f" ] || continue
  for v in GIT_HTTP_LOW_SPEED_LIMIT GIT_HTTP_LOW_SPEED_TIME 'GIT_SSH_COMMAND=.ssh -o ConnectTimeout'; do grep -q "$v" "$CHECKS/../$f" || fail "(d) $f does not set $v"; done; done
mn_project "$T/p" > /dev/null 2>&1; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
gh repo create owner/vid-state --private > /dev/null; RF=$FAKEGH/repos/owner%vid-state/remote; U0=$(cat "$RF")
CLAUDE_CODE_SESSION_ID=st-a; export CLAUDE_CODE_SESSION_ID; GIT_CONFIG_GLOBAL=$T/gc; export GIT_CONFIG_GLOBAL; : > "$T/gc"
sh "$GS" lock-take > "$T/out" 2>&1 || fail 'the first lock-take failed'
# (b), (c): the stand-in
RG=$(command -v git); mkdir -p "$T/sbin"; GLOG=$T/glog; GFAIL=$T/gfail; export GLOG GFAIL
printf '#!/bin/sh\nfor a; do case $a in ls-remote) printf "L=%%s T=%%s S=%%s\\n" "${GIT_HTTP_LOW_SPEED_LIMIT:-}" "${GIT_HTTP_LOW_SPEED_TIME:-}" "${GIT_SSH_COMMAND:-}" >> "$GLOG"\n  if [ -s "$GFAIL" ]; then c=$(cat "$GFAIL"); : > "$GFAIL"; echo "fatal: the remote end hung up unexpectedly" >&2; exit "$c"; fi; break ;; esac; done\nexec "%s" "$@"\n' "$RG" > "$T/sbin/git"; chmod +x "$T/sbin/git"
st() { : > "$GLOG"; RC=0; env PATH="$T/sbin:$PATH" "$@" sh "$GS" lock-renew > "$T/out" 2>&1 || RC=$?; }
st; [ "$RC" = 0 ] || fail "(b) lock-renew failed ($RC)"
grep -qx 'L=1 T=60 S=ssh -o ConnectTimeout=60 -o ServerAliveInterval=15 -o ServerAliveCountMax=4' "$GLOG" || fail "(b) the defaults are not set: $(head -n 1 "$GLOG")"
st GIT_HTTP_LOW_SPEED_TIME=7; grep -q '^L=1 T=7 ' "$GLOG" || fail "(b) the environment's own time was overridden: $(head -n 1 "$GLOG")"
printf '[http]\n\tlowSpeedLimit = 5\n\tlowSpeedTime = 9\n' > "$T/gc"; st; grep -q '^L= T= ' "$GLOG" || fail "(b) a global http.lowSpeed setting was overridden: $(head -n 1 "$GLOG")"
printf '[http "https://github.com"]\n\tlowSpeedTime = 300\n' > "$T/gc"; st; grep -q '^L=1 T= ' "$GLOG" || fail "(b) a GitHub-specific http.lowSpeedTime was overridden: $(head -n 1 "$GLOG")"
printf '[core]\n\tsshCommand = ssh\n' > "$T/gc"; st; grep -q 'S=$' "$GLOG" || fail "(b) core.sshCommand was overridden: $(head -n 1 "$GLOG")"
: > "$T/gc"; echo 128 > "$GFAIL"; st; [ "$RC" = 0 ] || fail "(c) one ls-remote failing with 128 failed the renew ($RC)"
[ "$(grep -c . "$GLOG")" -ge 2 ] || fail '(c) a read that failed with 128 was not tried again'
echo 2 > "$GFAIL"; st; [ "$RC" != 0 ] || fail '(c) an ls-remote failing with 2 passed'
[ "$(grep -c . "$GLOG")" = 1 ] || fail "(c) a read that failed with 2 was tried again ($(grep -c . "$GLOG") tries)"
# (a) a server that accepts and sends nothing
if command -v python3 > /dev/null 2>&1; then
  python3 -c 'import socket, sys, time
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(("127.0.0.1", 0)); s.listen(8)
print(s.getsockname()[1]); sys.stdout.flush(); c = []
while True: c.append(s.accept())' > "$T/port" 2> /dev/null &
  SP=$!; n=0; until [ -s "$T/port" ] || [ "$n" -ge 50 ]; do sleep 0.1; n=$((n + 1)); done; [ -s "$T/port" ] || fail '(a) the stall server did not start'
  echo "http://127.0.0.1:$(cat "$T/port")/owner/vid-state.git" > "$RF"
  GIT_HTTP_LOW_SPEED_TIME=2 sh "$GS" lock-renew > "$T/out" 2>&1 &
  LP=$!; n=0; while kill -0 "$LP" 2> /dev/null && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$LP" 2> /dev/null; then kill "$LP" 2> /dev/null || :; fail '(a) a git call to a server that sends nothing was still waiting after 30 seconds'; fi
  RC=0; wait "$LP" || RC=$?; [ "$RC" != 0 ] || fail '(a) lock-renew passed against a silent server'
  [ "$n" -le 200 ] || fail "(a) the stalled call took $((n / 10)) seconds"
  grep -q 'the lock could not be read' "$T/out" || fail '(a) the refusal does not say the lock could not be read'
  echo "$U0" > "$RF"; kill "$SP" 2> /dev/null || :; SP=''
else echo 'github-stall: no python3 here: the stalled server scene (a) is skipped'; fi
echo 'github-stall: ok'
