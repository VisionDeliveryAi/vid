#!/bin/sh
# Purpose: selftest case — the watcher records its ticks, and develop's gate
# reads them (v0.9.7.0.6 spec 3.3, R5–R7; v0.9.7.0.9 3.8, R13). A stub
# `osascript` and `notify-send` on PATH record any call, so nothing could
# reach the desktop — and none may be made. Convicts unless: a tick writes
# `tick <epoch> <home>` to .vid/observer.state in the active branch and in
# the idle branch, and no `notifier` line; `alive` exits 0 on a fresh tick
# recorded for this home and writes nothing; it exits 1 with no tick, a
# tick over 30 min old, a tick recorded for another home (a copied state)
# and a tick line with no home, printing `sh checks/observe.sh start`; and a
# tick in the main checkout over a linked worktree records that worktree's
# notice as a heartbeat line there. No stub is ever called. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; CASE=watcher-alive
. "$CHECKS/selftest/fixtures/observer-lib.sh"
mkdir -p "$T/bin"
for n in osascript notify-send; do printf '#!/bin/sh\nfor a in "$@"; do printf "%%s\\n" "$a"; done >> "%s/desktop.log"\n' "$T" > "$T/bin/$n"; chmod +x "$T/bin/$n"; done
PATH="$T/bin:$PATH"; export PATH
D=$(pwd -P)
st() { sed -n "s/^$1 //p" .vid/observer.state | tail -n 1; }
alive() { sh checks/observe.sh alive > "$T/alive.out" 2>&1; }
# the tick's own record, in both branches
reset; rs active; tick
case "$(st tick)" in [0-9]*" $D") ;; *) fail "the active branch did not write tick <epoch> <home>: $(st tick)" ;; esac
reset; rs 'stopped owner asked to pause'; tick
grep -q 'observe: idle' .vid/HEARTBEAT.md || fail 'the stopped run did not take the idle branch'
case "$(st tick)" in [0-9]*" $D") ;; *) fail "the idle branch did not write tick <epoch> <home>: $(st tick)" ;; esac
grep -q '^notifier' .vid/observer.state && fail 'a tick wrote a notifier line'
# alive: 0 on a fresh tick for this home; it writes nothing
B=$(cksum < .vid/observer.state); H=$(cksum < .vid/HEARTBEAT.md)
alive || fail 'alive refused a fresh tick for this home'
grep -qE '^watcher ok — last tick [0-9]+s ago$' "$T/alive.out" || fail 'alive did not say watcher ok'
[ "$(cksum < .vid/observer.state)" = "$B" ] && [ "$(cksum < .vid/HEARTBEAT.md)" = "$H" ] || fail 'alive wrote a file'
refused() { if alive; then fail "alive passed $1"; fi; grep -qxF 'watcher: start it: sh checks/observe.sh start' "$T/alive.out" || fail "alive did not print the start command for $1"; }
# 1 with no tick, an old tick, a copied state, a tick with no home
rm -f .vid/observer.state; refused 'no tick'
printf 'tick %s %s\n' "$(( $(date +%s) - 1900 ))" "$D" > .vid/observer.state; refused 'a tick 1,900 s old'
printf 'tick %s /somewhere/else\n' "$(date +%s)" > .vid/observer.state; refused 'a state copied from another home'
grep -q 'a copied record' "$T/alive.out" || fail 'alive did not say the state is another home'"'"'s'
printf 'tick %s\nnotifier yes\n' "$(date +%s)" > .vid/observer.state; refused 'a tick line with no home'
# a parent tick over a linked worktree records that worktree's notice in its own heartbeat
reset; rs 'stopped owner asked to pause'
git worktree add -q "$T/wt" -b wt
mkdir -p "$T/wt/.vid"; printf 'run: active\nsession: S2\nquestions: - · next Q1\n' > "$T/wt/.vid/RUN-STATE.md"
printf '# Heartbeat\n- 2026-01-01T00:00:00Z | note: old\n' > "$T/wt/.vid/HEARTBEAT.md"
tick
grep -q '| observe: notice — ViD: the build has gone quiet' "$T/wt/.vid/HEARTBEAT.md" || fail "the linked worktree's notice is not a heartbeat line there"
[ ! -f "$T/desktop.log" ] || fail "a desktop notifier was called: $(cat "$T/desktop.log")"
exit 0
