#!/bin/sh
# Purpose: vid-connect's steps (GitHub manual, GM-1 S5; GM M16 steps 1 and 7, M17; GM-4 F2): the start and the end of a call, for every
# caller in every ticket mode (/vid run, /vid next, /vid mode and every direct call), and the run's start for /vid run alone. Run as
# the plugin's own copy, sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh", from the project's top level, as refresh.sh is: every step
# before the refresh runs the plugin's own scripts, so nothing is committed before the lock is held (GM-4 F2's order: the mode, the
# repositories, the restore, the lock, the refresh). Slack is the skill's (a connector's tools, not a script).
#   start [--yes] [--run] [--state <owner/name>]   the connect, one line each, in order: with --run in GitHub manual, refused
#                   first, naming /vid next, nothing restored, refreshed or written (GM-1 S1); with --state (an empty folder), the
#                   records restored from that state repository first (the plugin's github.sh state-restore <repo>); the mode: a
#                   project not in ticket mode, or planned by the old ticket mode, or recorded in the retired GitHub team (FB-1 C1) but
#                   in /vid mode's own call, refused, and in GitHub manual (GM M15) a project
#                   whose .vid/tw/settings names no state-repo: refused, naming it, so the lock and the saved records never go to the
#                   spec repository; with --run in GitHub manual refused, naming /vid next (GM-1 S1); the repositories (FB-2 A1): each
#                   of repo:, spec-repo: (both layouts, GM-4 J5; not with layout: one in GitHub manual, FB-3 B2) and state-repo: the settings name, with no `<key> <name> ` line in
#                   .vid/tw/log for the name they hold now, made private and empty or checked (github.sh code-setup, spec-setup
#                   --make-only, GM-2 T10, and state-setup), one `connect <key>:` line each; access checks the spec repository is
#                   private at every call; the records restored; the lock taken; the read the call
#                   before ended with, .vid/round/read, copied once to .vid/round/read.prev (GM-4 F3), before any read of the call;
#                   the refresh (refresh.sh beside this file; --yes passes the owner's yes to the local edits it lists); the notices
#                   (lib/wsl.sh notice, its line as it prints it); the commit checks (hooks, below, FB-1 A1); github.sh access; then the stage, once (GM-4 F2, I4):
#                   without --run the call's, `stage name=replan state=start session=<s> records=29`, unless a stage holds plan.sh's
#                   gate on already (its session kept in .vid/connect-stage, so the end ends it; one a call that died left is ended
#                   first); with --run the run's start in its place (below). Each script the call runs finds the gate on, and opens
#                   none of its own. The refresh waiting on the owner (its exit 3) ends the call, the lock freed, exit 3; a no the
#                   owner gave (refresh-no) ends every start until a start with --yes, exit 3. A line not ready ends the call, the
#                   lock freed, exit 1. Ready: `connect: ready`, exit 0, the lock held
#     --run         the run's start, /vid run's alone, after access: the run's stage, `stage name=run state=start session=<s>
#                   records=29`; the run state (RUN-STATE's run: active, unless a pause is recorded or a hold whose stage has closed,
#                   its stage-closed line in .vid/tw/handed; session: <s>; plan: required; and `run state=active` recorded when
#                   active); the watcher (checks/observe.sh start, then alive; not alive: `run: stopped the watcher is not running`,
#                   the records saved and the lock freed, exit 1); the context line and the plugins (checks/brief.sh context,
#                   plugins); the dev side's start (devagent-start.sh beside this file), each printed as it prints it. The skills the
#                   run invokes are the skill's. <s> is $CLAUDE_CODE_SESSION_ID
#   hooks           (FB-1 A1) the commit checks, run by start right after the refresh and the notices: with core.hooksPath set
#                   (ViD's or another tool's), nothing; unset, the project's courts present in checks/ run on the tree, in the
#                   hook's order (its line-endings check, eol.sh check, then placement, conformance, imports, seams, stages,
#                   inventory, census, design-cite, prd, harness);
#                   all passing, `git config core.hooksPath checks/hooks` and `connect hooks: the commit checks are on; …`; else
#                   one `connect hooks: the commit checks are off — refused by <court>: <its first line>` line per court that
#                   refuses (its first line of standard error, else of standard output), then `connect hooks: close these and the
#                   next call switches them on`. It never ends the call: exit 0. A refusal is kept in .vid/next/hooks-off, a key
#                   line (`key <HEAD> <cksum of git status --porcelain, git diff HEAD, git diff --cached and each untracked, not ignored file's
#                   cksum, .vid left out>`) then its lines; while
#                   the key is the same the kept lines are printed and no court runs; a pass removes the file
#   refresh-no "<the owner's words>"   the owner's no to the refresh, recorded in .vid/next/refresh-no: the one record of it
#   FB-3 D2, the call's progress beside the chat (lib.sh prog): once the lock is held, start names the call's parts, but /vid run's
#                   start, which clears an earlier call's, and /vid mode's own call, whose parts mode.sh names; a start that ends after
#                   it leaves the part stopped, with what it needs; end clears them, a stop apart
#   end             the call's stage ended (when the start opened it), the records saved and the lock freed, one line each; the lock
#                   is freed even when the save fails (exit 1)
# Usage: sh connect.sh start [--yes] [--run] [--state <owner/name>] | hooks | refresh-no "<words>" | end
# serves: tickets
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
gh_() { sh checks/github.sh "$@"; }
say() { echo "connect $1: $(tail -n 1 "$W/o")"; }
SN=${CLAUDE_CODE_SESSION_ID:-connect-$$-$(date +%s)}; CS=.vid/connect-stage
# stend: the call's stage, when a connect opened it, ended
stend() { [ -s "$CS" ] || { rm -f "$CS"; return 0; }; _s=$(head -n 1 "$CS"); sh checks/event.sh "stage name=replan state=end session=$_s" > /dev/null 2>&1 || return 1; rm -f "$CS"; }
# FB-3 D2: MC, /vid mode's own call; OWN, this start named the parts; pstop [<what it needs>], the running part stopped, once
MC=''; case ${VID_CALLER:-} in mode|mode-auto) MC=1 ;; esac; OWN=''
pstop() { [ -z "$OWN" ] || prog stop "${1:-a look at the chat, which says why it stopped}"; OWN=''; }
pcall() { [ -z "$MC" ] || return 0; if [ -n "$RUN" ]; then [ ! -f .vid/face/wait ] || prog 'done'; return 0; fi
  set -- 'Connecting and checking the project'; [ "$(sh "$HERE/next.sh" own-work 2>/dev/null)" != on ] || set -- "$@" "ViD's own work"
  prog parts "$@" 'Reading GitHub' 'Working out what changed' 'Your list and the plan page' 'Saving the records'; OWN=1; prog on 'Connecting and checking the project'; }
# stop_ <line>: a start ended once the lock is held: the line, the records saved, the lock freed, exit 1
stop_() { echo "$1"; pstop; trap 'rm -rf "$W"' EXIT; gh_ state-save > /dev/null 2>&1 || echo 'connect records: not saved'; gh_ lock-free > /dev/null 2>&1 || echo 'connect lock: could not be freed'; exit 1; }
# hooks_ (FB-1 A1): the commit checks switched on once the project's courts pass on the tree, or what refuses while they do not
HO=.vid/next/hooks-off
# hkey: the tree's key, HEAD and a cksum of the status, the diff from HEAD, the staged diff and each untracked, not ignored file's own cksum, .vid
# left out; read with no optional lock, so no index write
hkey() { printf 'key %s %s\n' "$(git rev-parse -q --verify HEAD 2>/dev/null || echo none)" \
  "$({ git --no-optional-locks status --porcelain -- . ':(exclude).vid'; git --no-optional-locks diff HEAD -- . ':(exclude).vid'
    git --no-optional-locks diff --cached -- . ':(exclude).vid'
    git ls-files --others --exclude-standard -- . ':(exclude).vid' | while IFS= read -r _hu; do [ ! -f "$_hu" ] || printf '%s %s\n' "$(cksum < "$_hu")" "$_hu"; done; } 2>/dev/null | cksum | tr -d ' ')"; }
hooks_() { [ -z "$(git config --get core.hooksPath 2>/dev/null)" ] || return 0; _hf=''; _hk=$(hkey)
  if [ -s "$HO" ] && [ "$(head -n 1 "$HO")" = "$_hk" ]; then sed 1d "$HO"; return 0; fi   # nothing changed since the refusal: no court runs
  : > "$W/h.lines"
  # the pre-commit's line-endings check first (pre-commit:101), then its ten courts
  for _c in line-endings placement conformance imports seams stages inventory census design-cite prd harness; do
    _hs=checks/$_c.sh; _ha=''; [ "$_c" != line-endings ] || { _hs=checks/eol.sh; _ha=check; }; [ -f "$_hs" ] || continue
    _hr=0; sh "$_hs" $_ha > "$W/h.out" 2> "$W/h.err" < /dev/null || _hr=$?; [ "$_hr" != 0 ] || continue
    _hl=$(sed -n '/[^[:space:]]/{p;q;}' "$W/h.err"); [ -n "$_hl" ] || _hl=$(sed -n '/[^[:space:]]/{p;q;}' "$W/h.out"); [ -n "$_hl" ] || _hl="exit $_hr"
    echo "connect hooks: the commit checks are off — refused by $_c: $_hl" >> "$W/h.lines"; _hf=1; done
  if [ -n "$_hf" ]; then echo 'connect hooks: close these and the next call switches them on' >> "$W/h.lines"; cat "$W/h.lines"
    mkdir -p .vid/next && { echo "$_hk"; cat "$W/h.lines"; } | put "$HO" || :; return 0; fi
  rm -f "$HO"
  if git config core.hooksPath checks/hooks; then echo 'connect hooks: the commit checks are on; a commit made by hand now needs the message lines REQs:, Decisions: and Seams:'
  else echo 'connect hooks: the commit checks pass, but core.hooksPath could not be set; the next call tries again'; fi; }
case ${1:-} in
  start) shift; Y=''; RUN=''; SR=''
    while [ $# -gt 0 ]; do case $1 in --yes) Y=--yes ;; --run) RUN=1 ;; --state) [ $# -ge 2 ] || { sed -n 's/^# Usage: /usage: /p' "$0" >&2; exit 2; }; SR=$2; shift ;; *) sed -n 's/^# Usage: /usage: /p' "$0" >&2; exit 2 ;; esac; shift; done
    # GM-1 S1, GM-4 F2: the run's start in GitHub manual refused first, before anything is restored, refreshed or written (a --state
    # folder, empty, has its mode only once restored: the mode step below refuses it there)
    if [ -n "$RUN" ] && manual; then echo 'connect mode: this project is in GitHub manual: call /vid next; nothing refreshed or written, no lock is held'; exit 1; fi
    if [ -n "$SR" ]; then sh "$HERE/github.sh" state-restore "$SR" > "$W/o" 2>&1 || { sed 's/^/    /' "$W/o" >&2; echo "connect records: not restored from $SR; no lock is held"; exit 1; }; say records; fi
    # GM-4 F2's order: the mode, the repositories, the restore and the lock, each through the plugin's own copy, and only then the
    # refresh, so a start refused at any of them, or behind the saved records, or under another session's lock, commits nothing
    # the mode: ticket mode only; GM M15 in GitHub manual; the run's start not in GitHub manual (GM-1 S1)
    grep -q '^mode:[[:space:]]*tickets[[:space:]]*$' .vid/RUN-STATE.md 2>/dev/null || { echo 'connect mode: this project is not in ticket mode; no lock is held'; exit 1; }
    if [ -d .vid/tickets ] && [ ! -f .vid/tw/settings ]; then echo 'connect mode: This project was planned by the old ticket mode; re-plan it with /vid plan. No lock is held'; exit 1; fi
    # FB-1 C1: the old team mode is retired; only /vid mode's own call (VID_CALLER=mode) passes, to move the project over
    if [ "$(ghmode)" = team ] && [ "${VID_CALLER:-}" != mode ]; then echo 'connect mode: this project is recorded in GitHub team, which is retired: /vid mode manual moves it to GitHub manual; no lock is held'; exit 1; fi
    if manual; then
      [ -z "$RUN" ] || { echo 'connect mode: this project is in GitHub manual: call /vid next; no lock is held'; exit 1; }
      [ -n "$(skey state-repo)" ] || { echo "connect mode: GitHub manual keeps ViD's lock and records in its own state repository (GM M15), and .vid/tw/settings names no state-repo: — answer it (sh checks/planner.sh setup state-repo <owner/name> --words \"<their words>\"); nothing restored, taken or saved"; exit 1; }
    fi
    # GM-2 T10, GM-4 F2; FB-2 A1: each repository the settings name and the log has no line for under the name they hold now (a renamed
    # one made too), made private and empty or checked: the code repository, the spec repository (both layouts, GM-4 J5; none with one repository in GitHub manual, FB-3 B2), the state repository
    for k in repo spec-repo state-repo; do n=$(skey "$k"); [ -n "$n" ] || continue
      [ "$k" != spec-repo ] || [ "$(skey layout)" != one ] || ! manual || continue   # FB-3 B2: kept in the project
      ! awk -v k="$k" -v n="$n" '$1 == k && $2 == n { f = 1 } END { exit !f }' .vid/tw/log 2>/dev/null || continue
      case $k in repo) a=code-setup ;; spec-repo) a='spec-setup --make-only' ;; *) a=state-setup ;; esac
      sh "$HERE/github.sh" $a > "$W/o" 2>&1 || { sed 's/^/    /' "$W/o" >&2; echo "connect $k: not ready; no lock is held"; exit 1; }; say "$k"; done
    [ -z "$MC" ] || prog now 'bringing the records up to date'   # before the lock only /vid mode's own call has parts of its own
    sh "$HERE/github.sh" state-restore > "$W/o" 2>&1 || { sed 's/^/    /' "$W/o" >&2; echo 'connect records: not restored; no lock is held'; exit 1; }; say records
    # from before the take, any end but the ready one frees the lock (lock-free frees this session's lock alone)
    trap 'pstop; sh "$HERE/github.sh" lock-free > /dev/null 2>&1; rm -rf "$W"' EXIT; trap 'exit 1' INT TERM
    [ -z "$MC" ] || prog now 'taking the turn'
    sh "$HERE/github.sh" lock-take > "$W/o" 2>&1 || { sed 's/^/    /' "$W/o" >&2; echo "connect lock: not taken ($(tail -n 1 "$W/o")); the call ends"; exit 1; }; say lock
    pcall
    # GM-4 F3 (I2): the read the call before ended with, once, before any read of this call
    if [ -f .vid/round/read ]; then put .vid/round/read.prev < .vid/round/read || { echo 'connect read: .vid/round/read.prev could not be written; the lock freed'; exit 1; }; fi
    # the refresh, under the lock: its no or its wait ends the call, the lock freed
    if [ -z "$Y" ] && [ -f .vid/next/refresh-no ]; then echo "connect refresh: the owner said no to the refresh ($(cat .vid/next/refresh-no)): checks/ needs it, so every call ends here until the owner's yes; the lock freed"; pstop "your yes to update the project's checks"; exit 3; fi
    prog now "checking the project's rules"
    rc=0; sh "$HERE/refresh.sh" $Y > "$W/o" 2>&1 || rc=$?
    if [ "$rc" = 3 ]; then sed 's/^/    /' "$W/o"; echo "connect refresh: waits for the owner's yes to the local edits listed above; the lock freed"; pstop "your yes to update the project's checks"; exit 3; fi
    [ "$rc" = 0 ] || { sed 's/^/    /' "$W/o" >&2; echo "connect refresh: failed (exit $rc); the lock freed"; exit 1; }
    rm -f .vid/next/refresh-no; say refresh
    [ ! -f "$HERE/lib/wsl.sh" ] || sh "$HERE/lib/wsl.sh" notice 2>&1 || :
    hooks_   # FB-1 A1: the commit checks, on once they pass; it never ends the call
    prog now 'checking GitHub access'
    gh_ access > "$W/a" 2>&1; sed 's/^/connect /' "$W/a"
    if ! grep -qx 'access: ok' "$W/a"; then pstop "GitHub ready: the chat says what is missing"; trap 'rm -rf "$W"' EXIT; gh_ lock-free > "$W/o" 2>&1 || { echo "connect lock: could not be freed: $(tail -n 1 "$W/o")"; exit 1; }; echo 'connect: GitHub is not ready; the lock freed, the call ends'; exit 1; fi
    if [ -z "$RUN" ]; then
      # GM-4 F2 (I4): the call's stage, once, unless a stage holds the gate on; one a call that died left open is ended first
      stend || stop_ 'connect stage: the stage an earlier call left open could not be ended (checks/event.sh); the call ends'
      if sh checks/plan.sh gate > /dev/null 2>&1; then echo 'connect stage: a stage holds the gate on already; none opened'
      else sh checks/event.sh "stage name=replan state=start session=$SN records=29" > /dev/null 2>&1 || stop_ "connect stage: the call's stage could not be opened (checks/event.sh); the call ends"
        printf '%s\n' "$SN" | put "$CS" || stop_ "connect stage: $CS could not be written; the call ends"; echo "connect stage: the call's stage opened (session $SN)"; fi
    else
      # the run's start, /vid run's alone
      sh checks/event.sh "stage name=run state=start session=$SN records=29" > /dev/null 2>&1 || stop_ "connect run: the run's stage could not be opened (checks/event.sh); the run ends"
      echo "connect stage: the run's stage opened (session $SN)"
      HS=$(sed -n 's/^run:[[:space:]]*stopped owner asked to hold after stage \([0-9][0-9]*\).*/\1/p' .vid/RUN-STATE.md | head -n 1)
      KEEP=''; grep -q '^run:[[:space:]]*stopped owner asked to pause' .vid/RUN-STATE.md && KEEP=1
      [ -z "$HS" ] || ! grep -q "^stage-closed $HS " .vid/tw/handed 2>/dev/null || KEEP=1
      rs_edit awk -v k="$KEEP" -v s="$SN" 'function put_(key, v) { if (!(key in d)) print key ": " v; d[key] = 1 }
        /^run:/ { if (k) print; else print "run: active"; d["run"] = 1; next } /^session:/ { put_("session", s); next } /^plan:/ { put_("plan", "required"); next }
        /^## / && !e { if (!("run" in d)) { print "run: active"; d["run"] = 1 } put_("session", s); put_("plan", "required"); e = 1 } { print }
        END { if (!e) { if (!("run" in d)) print "run: active"; put_("session", s); put_("plan", "required") } }' || stop_ 'connect run: RUN-STATE.md could not be written; the run ends'
      if [ -z "$KEEP" ]; then ev 'run state=active'; fi
      echo "connect run: $(sed -n 's/^run:[[:space:]]*//p' .vid/RUN-STATE.md | head -n 1), session $SN"
      sh checks/observe.sh start > "$W/o" 2>&1; sed 's/^/connect watcher: /' "$W/o"
      if ! sh checks/observe.sh alive > "$W/o" 2>&1; then sed 's/^/connect watcher: /' "$W/o"
        rs_edit sed 's/^run:.*/run: stopped the watcher is not running/' || :; stop_ 'connect watcher: not running: run: stopped the watcher is not running; the records saved, the lock freed'; fi
      sh checks/brief.sh context 2>&1 || :; sh checks/brief.sh plugins 2>&1 || :
      sh "$HERE/devagent-start.sh" 2>&1 || :
    fi
    trap 'rm -rf "$W"' EXIT; trap - INT TERM; echo 'connect: ready'; exit 0 ;;
  hooks) hooks_; exit 0 ;;
  refresh-no) [ -n "${2:-}" ] || { echo 'usage: sh connect.sh refresh-no "<the owner'"'"'s words>"' >&2; exit 2; }
    mkdir -p .vid/next; printf '%s at=%s\n' "$2" "$(now)" > "$W/n"; put .vid/next/refresh-no < "$W/n"; echo 'connect refresh: the owner said no; recorded'; exit 0 ;;
  end) rc=0; [ -n "$MC" ] || prog on 'Saving the records'; if [ -s "$CS" ]; then if stend; then echo "connect stage: the call's stage ended"; else echo "connect stage: the end of the call's stage was not recorded"; rc=1; fi; fi
    gh_ state-save > "$W/o" 2>&1 || { sed 's/^/    /' "$W/o" >&2; rc=1; }; say records
    gh_ lock-free > "$W/o" 2>&1 || rc=1; say lock
    # FB-3 D2: no parts left, a stop apart
    if [ -z "$MC" ] && [ -f .vid/face/wait ] && ! grep -q "^stop$(printf '\t')" .vid/face/wait; then if [ "$rc" = 0 ]; then prog 'done'; else prog stop 'a look at the chat: the records were not saved, or the lock not freed'; fi; fi; exit "$rc" ;;
  *) sed -n 's/^# Usage: /usage: /p' "$0" >&2; exit 2 ;;
esac
