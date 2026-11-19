#!/bin/sh
# Purpose: vid-connect's steps (GitHub manual, GM-1 S5; GM M16 steps 1 and 7, M17): the start and the end of a call, in every
# ticket mode, written so /vid run can call it too (it does not yet, until phase 5). Run as the plugin's own copy,
# sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh", from the project's top level, as refresh.sh is: the refresh comes first, before
# anything is restored or locked. Slack is the skill's (a connector's tools, not a script).
#   start [--yes]   one line each, in order: the refresh (refresh.sh beside this file; --yes passes the owner's yes to the local
#                   edits it lists); the records restored, the lock taken and github.sh access, each through the project's
#                   checks/, now the plugin's. The refresh waiting on the owner (its exit 3) ends the call holding no lock,
#                   exit 3; a no the owner gave (refresh-no) ends every start until a start with --yes, exit 3. A GitHub
#                   line not ready ends the call, the lock freed, exit 1. Ready: `connect: ready`, exit 0, the lock held
#   refresh-no "<the owner's words>"   the owner's no to the refresh, recorded in .vid/next/refresh-no
#   end             the records saved and the lock freed, one line each; the lock is freed even when the save fails (exit 1)
# Usage: sh connect.sh start [--yes] | refresh-no "<words>" | end
# serves: tickets
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
gh_() { sh checks/github.sh "$@"; }
say() { echo "connect $1: $(tail -n 1 "$W/o")"; }
case ${1:-} in
  start) Y=''; [ "${2:-}" != --yes ] || Y=--yes
    if [ -z "$Y" ] && [ -f .vid/next/refresh-no ]; then echo "connect refresh: the owner said no to the refresh ($(cat .vid/next/refresh-no)): checks/ needs it, so every call ends here until the owner's yes"; exit 3; fi
    rc=0; sh "$HERE/refresh.sh" $Y > "$W/o" 2>&1 || rc=$?
    if [ "$rc" = 3 ]; then sed 's/^/    /' "$W/o"; echo "connect refresh: waits for the owner's yes to the local edits listed above; no lock is held"; exit 3; fi
    [ "$rc" = 0 ] || { sed 's/^/    /' "$W/o" >&2; echo "connect refresh: failed (exit $rc); no lock is held"; exit 1; }
    rm -f .vid/next/refresh-no; say refresh
    gh_ state-restore > "$W/o" 2>&1 || { sed 's/^/    /' "$W/o" >&2; echo 'connect records: not restored; no lock is held'; exit 1; }; say records
    # from before the take, any end but the ready one frees the lock (lock-free frees this session's lock alone)
    trap 'gh_ lock-free > /dev/null 2>&1; rm -rf "$W"' EXIT; trap 'exit 1' INT TERM
    gh_ lock-take > "$W/o" 2>&1 || { sed 's/^/    /' "$W/o" >&2; echo "connect lock: not taken ($(tail -n 1 "$W/o")); the call ends"; exit 1; }; say lock
    gh_ access > "$W/a" 2>&1; sed 's/^/connect /' "$W/a"
    if ! grep -qx 'access: ok' "$W/a"; then trap 'rm -rf "$W"' EXIT; gh_ lock-free > "$W/o" 2>&1 || { echo "connect lock: could not be freed: $(tail -n 1 "$W/o")"; exit 1; }; echo 'connect: GitHub is not ready; the lock freed, the call ends'; exit 1; fi
    trap 'rm -rf "$W"' EXIT; trap - INT TERM; echo 'connect: ready'; exit 0 ;;
  refresh-no) [ -n "${2:-}" ] || { echo 'usage: sh connect.sh refresh-no "<the owner'"'"'s words>"' >&2; exit 2; }
    mkdir -p .vid/next; printf '%s at=%s\n' "$2" "$(now)" > "$W/n"; put .vid/next/refresh-no < "$W/n"; echo 'connect refresh: the owner said no; recorded'; exit 0 ;;
  end) rc=0; gh_ state-save > "$W/o" 2>&1 || { sed 's/^/    /' "$W/o" >&2; rc=1; }; say records
    gh_ lock-free > "$W/o" 2>&1 || rc=1; say lock; exit "$rc" ;;
  *) sed -n 's/^# Usage: /usage: /p' "$0" >&2; exit 2 ;;
esac
