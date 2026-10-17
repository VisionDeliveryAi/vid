#!/bin/sh
# Purpose: a builder run on Codex, as a supervised job (v0.9.7.1 spec 3.9, R9). The builder's tool is an owner
# setting: `.vid/budget builder-tool=claude|codex|paused` (missing: claude), with `codex-model=` and
# `codex-effort=`, read at each spawn. The brief, the rules, the courts and the evidence are the same for either
# tool; this script only starts, watches, stops and cleans a Codex builder.
#   tool [claude|codex --by owner]   with no value prints `builders: <tool>`; with one, writes builder-tool= and
#     records `builder-tool set=<tool> by=owner`. Refused without `--by owner`: only the owner switches it.
#   start --brief <file>   writes the job record .vid/jobs/<try> (run, step, try, brief and its hash, the worktree,
#     the plugin root and version, model, effort, the return path) and its worktree — a `git worktree` of the
#     project at the brief's quoted-at, detached, whose .vid/home names the run's home. Refused while builders are
#     paused or set to Claude, for a try already started (a try is never launched twice), and for a brief that is
#     no checked builder brief with a try. Records `job-start try= step=`.
#   run <try>   the supervisor, run by the run manager with the host's background facility. Refused when a stop
#     intent is in the record, when the job was launched before, when the installed plugin's version differs from
#     the run's (the run manager's session's vid=), and unless `sh checks/plan.sh home-of`, run from the worktree
#     with the environment Codex gets, prints the run's home (one shared test ledger). It starts `codex exec` in
#     its own process group (-C the worktree, the sandbox, --json to .vid/jobs/<try>.events, -o <try>.final,
#     stdin from /dev/null, the bootstrap), records the group and its start time, checks the stop intent every
#     second while it waits (TERM to the group, 30 s, KILL), reaps the child, publishes `exit=` (and `stopped=yes`)
#     and prints `job <try> exit=<n> return=<path|missing>`. Codex's own failure records naming a usage or rate
#     limit — v0.9.7.3 (R9): only when the run failed, only its top-level error and turn.failed events and stderr —
#     make the exit `job-exit reason=codex-limit`: the unfinished work is saved (brief.sh save), the try's tickets
#     cancelled (test.sh cancel), and builder-tool becomes `paused` with `builder-tool paused reason=codex-limit
#     reset=<time|unknown>`; no spawn on either tool until the owner's word.
#   status [<try>]   the process (alive, by group and start time), the return (present or missing), collected
#     (an `agent-returned … try=` event) and cleaned; and every ticket carrying the try outside the run's home
#     `.vid/requests/` — a `coordination fault`, recorded as an incident.
#   stop <try>   writes the stop intent; waits up to 200 s (exit 75: call again) for the supervisor to publish its
#     exit; then saves the work (brief.sh save --worktree), cancels the try's tickets and records `job-stop`. A
#     dead supervisor: the work is saved only when the record holds the group and its start time and, after
#     TERM and KILL, no process of the group remains; otherwise the worktree is kept, nothing saved, and
#     `job-recovery-required try= reason=` recorded, with one line for the owner. A job never launched: the
#     intent, `exit=not-launched`, and `job-stop … reason=not-launched`.
#   clean <try>   cancels the try's tickets; records `job-cleaned` only once every cancelled ticket is terminal
#     (exit 75 until then). The worktree is kept until the return is merged or superseded.
#   open   one line per job not yet cleaned after its return was collected or after a stop (the re-entry page,
#     the observer).
# Run at the run's home. Writes only .vid/jobs/, .vid/budget's builder-tool line and events.
set -u
IFS='
'
usage() { echo 'ViD job: usage — sh checks/job.sh tool [claude|codex --by owner] | start --brief <file> | run <try> | status [<try>] | stop <try> | clean <try> | open' >&2; exit 2; }
die() { echo "ViD job: refused — $*" >&2; exit 1; }
ev() { sh checks/event.sh "$1" >/dev/null 2>&1 || printf '%s at=%s\n' "$1" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; }
jk() { sed -n "s/^$1=//p" "$2" 2>/dev/null | tail -n 1; }
jput() { printf '%s=%s\n' "$2" "$3" >> "$1"; }
tool_now() { _t=$(sed -n 's/^builder-tool=//p' .vid/budget 2>/dev/null | tail -n 1); echo "${_t:-claude}"; }
set_tool() { mkdir -p .vid; { grep -v '^builder-tool=' .vid/budget 2>/dev/null || true; echo "builder-tool=$1"; } > .vid/budget.tmp.$$ && mv .vid/budget.tmp.$$ .vid/budget; }
lstart() { ps -o lstart= -p "$1" 2>/dev/null | sed 's/^ *//'; }
# group_alive <pgid>: a process of the group remains
group_alive() { [ -n "$1" ] && ps -A -o pgid= 2>/dev/null | awk -v g="$1" '$1 == g { f = 1 } END { exit f ? 0 : 1 }'; }
# ident_ok <record>: the group leader is the process the record names (start time)
ident_ok() { _p=$(jk pgid "$1"); _s=$(jk pid-start "$1"); [ -n "$_p" ] && [ -n "$_s" ] && [ "$(lstart "$_p")" = "$_s" ]; }
[ -d .vid ] || die 'no .vid/ here — run at the run'"'"'s home'
mkdir -p .vid/jobs
CMD=${1:-}; [ $# -gt 0 ] && shift
case "$CMD" in
  tool)
    [ $# -eq 0 ] && { echo "builders: $(tool_now)"; exit 0; }
    T_=$1; shift; [ "${1:-}" = --by ] && [ "${2:-}" = owner ] || die "the builders' tool is the owner's to set: sh checks/job.sh tool $T_ --by owner, on the owner's word only"
    case "$T_" in claude|codex) ;; *) usage ;; esac
    set_tool "$T_"; ev "builder-tool set=$T_ by=owner"; echo "builders: $T_ (from the next spawn)"; exit 0 ;;
  start)
    [ "${1:-}" = --brief ] && [ -n "${2:-}" ] || usage
    B=$2; [ -f "$B" ] || die "no brief $B"
    case "$(tool_now)" in codex) ;; paused) die 'builders are paused (Codex ran out of allowance): no builder is spawned on either tool until the owner says which' ;; *) die "builders are set to $(tool_now): a Codex job starts only after the owner's word (sh checks/job.sh tool codex --by owner)" ;; esac
    hv() { sed -n "1,14s/^.*$1:[[:space:]]*//p" "$B" | head -n 1 | sed 's/[[:space:]]\{2,\}[a-z -]*:.*$//;s/[[:space:]]*$//'; }
    [ "$(hv role)" = builder ] || die 'a Codex job builds a builder brief (fixers stay on Claude in this release)'
    TRY=$(hv try); Q=$(hv quoted-at); STEP=$(hv step); RET=$(hv return)
    [ -n "$TRY" ] && [ -n "$Q" ] && [ -n "$RET" ] || die 'the brief has no try:, quoted-at: or return: — write it with sh checks/brief.sh write'
    awk -v b="path=$B" '$1 == "brief-check" { ok = 0; for (i = 2; i <= NF; i++) if ($i == b) ok = 1; if (ok) r = $0 } END { exit (r ~ / result=ok/) ? 0 : 1 }' .vid/metrics-events 2>/dev/null || die "the brief $B was not checked ok (sh checks/brief.sh $B)"
    J=.vid/jobs/$TRY; [ ! -e "$J" ] || die "the try $TRY was started before ($J): a try is never launched twice — write a new brief"
    H=$(pwd -P); WT=$H/.vid/jobs/$TRY.wt
    git worktree add -q --detach "$WT" "$Q" 2>/dev/null || die "git worktree add at $Q failed"
    mkdir -p "$WT/.vid"; printf '%s\n' "$H" > "$WT/.vid/home"
    PR=${CLAUDE_PLUGIN_ROOT:-}; [ -n "$PR" ] && [ -f "$PR/skills/vid-build/SKILL.md" ] || PR=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
    PV=$(sed -n 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$PR/.claude-plugin/plugin.json" 2>/dev/null | head -n 1)
    MD=$(sed -n 's/^codex-model=//p' .vid/budget 2>/dev/null | tail -n 1); EF=$(sed -n 's/^codex-effort=//p' .vid/budget 2>/dev/null | tail -n 1)
    { printf 'run=%s\nstep=%s\ntry=%s\nbrief=%s\nbrief-hash=%s\nquoted-at=%s\nworktree=%s\nplugin=%s\nversion=%s\nmodel=%s\neffort=%s\nreturn=%s\nstarted=%s\n' \
        "$H" "${STEP:--}" "$TRY" "$B" "$(git hash-object "$B")" "$Q" "$WT" "$PR" "${PV:-unknown}" "${MD:-default}" "${EF:-default}" "$RET" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; } > "$J.tmp.$$" && mv "$J.tmp.$$" "$J"
    ev "job-start try=$TRY step=${STEP:--}"
    echo "ViD job: started $TRY — worktree $WT; next: sh checks/job.sh run $TRY (in the background)"; exit 0 ;;
  run)
    TRY=${1:-}; J=.vid/jobs/$TRY; [ -n "$TRY" ] && [ -f "$J" ] || die "no job $TRY"
    [ -z "$(jk stop "$J")" ] || die "a stop intent is in the job record: $TRY is not launched"
    [ -z "$(jk pgid "$J")" ] || die "$TRY was launched before: a try is never launched twice"
    WT=$(jk worktree "$J"); PR=$(jk plugin "$J"); B=$(jk brief "$J"); RET=$(jk return "$J")
    # the installed plugin at the run's version — the run manager's session's vid=
    SID=$(sed -n 's/^session:[[:space:]]*//p' .vid/RUN-STATE.md 2>/dev/null | head -n 1 | awk '{ print $1 }')
    RV=$(awk -v s="id=$SID" '$1 == "session" { h = 0; for (i = 2; i <= NF; i++) if ($i == s) h = 1; if (!h) next; for (i = 2; i <= NF; i++) if (index($i, "vid=") == 1) v = substr($i, 5) } END { print v }' .vid/metrics-events 2>/dev/null)
    IV=$(sed -n 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$PR/.claude-plugin/plugin.json" 2>/dev/null | head -n 1)
    [ -n "$RV" ] && [ "$RV" != - ] && [ "$RV" != "$IV" ] && die "the installed plugin is $IV and the run is on $RV: a Codex builder reads the run's rules"
    # one shared test ledger: from the worktree, with Codex's environment, the run's home
    HM=$(cd "$WT" && env -u VID_HOME sh checks/plan.sh home-of 2>/dev/null | tail -n 1)
    [ "$HM" = "$(pwd -P)" ] || die "from the worktree, sh checks/plan.sh home-of prints '${HM:-nothing}', not the run's home $(pwd -P): its test requests would miss the shared ledger"
    VK=$(sed -n '1,14s/^.*skill:[[:space:]]*//p' "$B" | head -n 1); [ -n "$VK" ] || VK=vid-build
    BOOT=$(printf '%s\n' "You are a ViD builder, working on one plan step in this git worktree: $WT." \
      "Before any work, read these files in full, in this order:" \
      "1. $WT/CLAUDE.md — the project's law." \
      "2. $PR/skills/vid-build/SKILL.md — the rules for building a step. Skip its section \"Claude host\": it is for another host." \
      "3. $(pwd -P)/$B — your brief." \
      "Then follow vid-build's order from your first command." \
      "Commits: run git commit in the foreground and wait for it; its hooks are the courts." \
      "Your hand-back: write your return file at $RET — write $RET.tmp, then rename it into place. Its brief line is, verbatim: brief: $B" \
      "One receipt per row line: a pass names the one receipt where every required case and shape passed; a row that needs two passes and passed in only one is not. When one request publishes an inline and a deployed receipt, name the one that credits the row: the deployed one for a row only a deployed run credits (a journey or a (process) row), else the inline one. The field holds one receipt file name; notes go in the report." \
      "After any compaction, read the same three files in full again before you continue.")
    EVF=.vid/jobs/$TRY.events; FIN=.vid/jobs/$TRY.final; ERR=.vid/jobs/$TRY.err
    # the protected set (checks/brief.sh protected), refused by ViD's own Codex hook — the owner's Codex config and
    # plugins are left out (--ignore-user-config): the brief and the bootstrap govern a ViD builder
    sh checks/brief.sh protected > ".vid/jobs/$TRY.protected" 2>/dev/null; [ -s ".vid/jobs/$TRY.protected" ] || die 'the protected set could not be read (sh checks/brief.sh protected)'
    PH="sh \"$PR/hooks/codex-protect.sh\" \"$(pwd -P)/.vid/jobs/$TRY.protected\""
    PHK="hooks.PreToolUse=[{matcher=\"^(Bash|apply_patch|Edit|Write)\$\", hooks=[{type=\"command\", command='$PH'}]}]"
    set -- codex exec --json --ignore-user-config --dangerously-bypass-hook-trust -c "$PHK" -C "$WT" -s workspace-write -c 'sandbox_workspace_write.network_access=true' \
      --add-dir "$(git rev-parse --git-common-dir | sed "s#^\([^/]\)#$(pwd -P)/\1#")" --add-dir "$(cd "$WT" && git rev-parse --absolute-git-dir)" --add-dir "$(pwd -P)/.vid" \
      --add-dir "${DOCKER_CONFIG:-$HOME/.docker}" -o "$FIN"
    [ "$(jk model "$J")" = default ] || set -- "$@" -m "$(jk model "$J")"
    [ "$(jk effort "$J")" = default ] || set -- "$@" -c "model_reasoning_effort=\"$(jk effort "$J")\""
    [ -z "${VID_CODEX_EXTRA:-}" ] || set -- "$@" $VID_CODEX_EXTRA
    set -- "$@" "$BOOT"
    [ -n "${VID_CODEX:-}" ] && set -- $VID_CODEX "$@"   # the self-test's fake Codex, one word per line
    perl -e 'use POSIX (); POSIX::setsid(); exec @ARGV or exit 127' "$@" < /dev/null > "$EVF" 2> "$ERR" &
    CP=$!; sleep 0; jput "$J" pgid "$CP"; jput "$J" pid-start "$(lstart "$CP")"; jput "$J" supervisor "$$"; jput "$J" supervisor-start "$(lstart $$)"
    [ -n "${VID_TASK_ID:-}" ] && jput "$J" task "$VID_TASK_ID"
    STOPPED=no
    while kill -0 "$CP" 2>/dev/null; do
      if [ -n "$(jk stop "$J")" ] && [ "$STOPPED" = no ]; then
        STOPPED=yes; kill -TERM -- "-$CP" 2>/dev/null || kill -TERM "$CP" 2>/dev/null
        _w=0; while group_alive "$CP" && [ "$_w" -lt 30 ]; do sleep 1; _w=$((_w + 1)); done
        group_alive "$CP" && kill -KILL -- "-$CP" 2>/dev/null
      fi
      sleep 1
    done
    RC=0; wait "$CP" || RC=$?
    REASON=exit; [ "$STOPPED" = yes ] && REASON=stopped
    # Codex's own records: a usage or rate limit, and its reset time when it gives one — v0.9.7.3 (3.9, R9): read
    # only when the run failed (a non-zero exit or a turn.failed event) and only from Codex's failure records — the
    # top-level `error` and `turn.failed` events and stderr — never from command output or agent messages
    FAILREC=''
    if [ "$STOPPED" = no ] && { [ "$RC" -ne 0 ] || grep -qE '^[[:space:]]*\{[[:space:]]*"type"[[:space:]]*:[[:space:]]*"turn\.failed"' "$EVF" 2>/dev/null; }; then
      FAILREC=$( { grep -E '^[[:space:]]*\{[[:space:]]*"type"[[:space:]]*:[[:space:]]*"(error|turn\.failed)"' "$EVF" 2>/dev/null; cat "$ERR" 2>/dev/null; } || true)
    fi
    if [ -n "$FAILREC" ] && printf '%s\n' "$FAILREC" | grep -qiE 'usage limit|rate limit|rate_limit|insufficient_quota|quota exceeded'; then
      REASON=codex-limit
      RS=$(printf '%s\n' "$FAILREC" | grep -oiE '(try again|resets?) (at|in) [^".]*' | head -n 1 | sed -E 's/^[A-Za-z ]* (at|in) //' | tr ' ' '_')
    fi
    jput "$J" exit "$RC"; [ "$STOPPED" = yes ] && jput "$J" stopped yes; jput "$J" ended "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    ev "job-exit try=$TRY exit=$RC reason=$REASON"
    if [ "$REASON" = codex-limit ]; then
      sh checks/brief.sh save "$B" --worktree "$WT" > /dev/null 2>&1 || echo "ViD job: the save of $TRY failed — the worktree $WT is kept"
      sh checks/test.sh cancel --try "$TRY" --by job.sh > /dev/null 2>&1 || true
      set_tool paused; ev "builder-tool paused reason=codex-limit reset=${RS:-unknown}"
      echo "ViD job: Codex has run out of allowance (resets ${RS:-unknown}). Builders are paused. Ask the owner: 'use Claude for builders' to continue on Claude, or 'wait for Codex' to resume when it resets."
    fi
    if [ -f "$RET" ]; then echo "job $TRY exit=$RC return=$RET"; else echo "job $TRY exit=$RC return=missing"; fi
    exit 0 ;;
  status|open)
    [ "$CMD" = status ] && [ -n "${1:-}" ] && L=".vid/jobs/$1" || L=$(ls .vid/jobs/ 2>/dev/null | grep -v '\.' | sed 's#^#.vid/jobs/#')
    for J in $L; do
      [ -f "$J" ] || { echo "ViD job: no job ${J#.vid/jobs/}"; continue; }
      TRY=$(jk try "$J")
      if [ -n "$(jk exit "$J")" ]; then P="exited $(jk exit "$J")$([ "$(jk stopped "$J")" = yes ] && echo ' (stopped)')"
      elif [ -z "$(jk pgid "$J")" ]; then P='not launched'
      elif ident_ok "$J"; then P=alive
      else P='dead, no exit published'; fi
      R=missing; [ -f "$(jk return "$J")" ] && R=present
      C=no; grep -q "^agent-returned .* try=$TRY " .vid/metrics-events 2>/dev/null && C=yes
      K=no; grep -q "^job-cleaned try=$TRY " .vid/metrics-events 2>/dev/null && K=yes
      # open: a job cleaned after its return was collected, or after a stop (its work is a continuation package)
      [ "$CMD" = open ] && [ "$K" = yes ] && { [ "$C" = yes ] || [ "$(jk stopped "$J")" = yes ]; } && continue
      echo "job $TRY: process $P · return $R · collected $C · cleaned $K"
      if [ "$CMD" = status ]; then
        # one shared test ledger: a ticket carrying the try anywhere but the run's home is a coordination fault
        WT=$(jk worktree "$J")
        for r in "$WT"/.vid/requests/*/request; do
          [ -f "$r" ] && grep -qx "try=$TRY" "$r" || continue
          echo "coordination fault: $TRY's ticket $(basename "$(dirname "$r")") is at $WT/.vid/requests/, not the run's home"
          grep -q "^incident .*coordination-fault .*$(basename "$(dirname "$r")")" .vid/metrics-events 2>/dev/null || ev "incident slice=- coordination-fault try=$TRY ticket=$(basename "$(dirname "$r")") ledger=$WT/.vid/requests"
        done
      fi
    done
    exit 0 ;;
  stop)
    TRY=${1:-}; J=.vid/jobs/$TRY; [ -n "$TRY" ] && [ -f "$J" ] || die "no job $TRY"
    [ -n "$(jk stop "$J")" ] || jput "$J" stop "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    WT=$(jk worktree "$J"); B=$(jk brief "$J")
    grep -q "^job-stop try=$TRY " .vid/metrics-events 2>/dev/null && { echo "ViD job: $TRY is stopped already"; exit 0; }
    if [ -z "$(jk pgid "$J")" ] && [ -z "$(jk exit "$J")" ]; then jput "$J" exit not-launched; jput "$J" stopped yes; ev "job-stop try=$TRY saved=no reason=not-launched"; echo "ViD job: $TRY was never launched; the stop intent keeps it so"; exit 0; fi
    SV=$(jk supervisor "$J"); SS=$(jk supervisor-start "$J")
    if [ -z "$(jk exit "$J")" ] && [ -n "$SV" ] && [ -n "$SS" ] && [ "$(lstart "$SV")" = "$SS" ]; then
      _w=0; while [ -z "$(jk exit "$J")" ] && [ "$_w" -lt "${VID_WAIT_MAX:-200}" ]; do sleep 1; _w=$((_w + 1)); done
      [ -n "$(jk exit "$J")" ] || { echo "ViD job: $TRY's supervisor has not published its exit yet — call sh checks/job.sh stop $TRY again"; exit 75; }
    elif [ -z "$(jk exit "$J")" ]; then
      # recovery: the supervisor is dead — save only with a full identity and the group gone
      if ident_ok "$J" || group_alive "$(jk pgid "$J")"; then
        if [ -n "$(jk pid-start "$J")" ]; then
          kill -TERM -- "-$(jk pgid "$J")" 2>/dev/null; _w=0; while group_alive "$(jk pgid "$J")" && [ "$_w" -lt 30 ]; do sleep 1; _w=$((_w + 1)); done
          group_alive "$(jk pgid "$J")" && kill -KILL -- "-$(jk pgid "$J")" 2>/dev/null; sleep 1
        fi
      fi
      if [ -z "$(jk pid-start "$J")" ] || group_alive "$(jk pgid "$J")"; then
        _why=group-remains; [ -n "$(jk pid-start "$J")" ] || _why=no-identity
        ev "job-recovery-required try=$TRY reason=$_why"
        echo "ViD job: $TRY needs you: its supervisor died and its Codex process can't be confirmed gone ($_why). Its worktree $WT is kept; nothing was saved."; exit 1
      fi
      jput "$J" exit recovered; jput "$J" stopped yes
    fi
    SVD=yes; sh checks/brief.sh save "$B" --worktree "$WT" > .vid/jobs/$TRY.save 2>&1 || { SVD=no; echo "ViD job: the save of $TRY failed: $(tail -n 3 .vid/jobs/$TRY.save)"; }
    sh checks/test.sh cancel --try "$TRY" --by job.sh 2>/dev/null || true
    ev "job-stop try=$TRY saved=$SVD"
    echo "ViD job: $TRY stopped; work saved: $SVD; its tickets cancelled — confirm each with sh checks/test.sh wait <ticket>"; exit 0 ;;
  clean)
    TRY=${1:-}; J=.vid/jobs/$TRY; [ -n "$TRY" ] && [ -f "$J" ] || die "no job $TRY"
    [ -n "$(jk exit "$J")" ] || die "$TRY is still running: stop it or wait for its exit first"
    grep -q "^job-cleaned try=$TRY " .vid/metrics-events 2>/dev/null && { echo "ViD job: $TRY is cleaned already"; exit 0; }
    sh checks/test.sh cancel --try "$TRY" --by job.sh > /dev/null 2>&1 || true
    OPENT=''
    for r in .vid/requests/*/request; do
      [ -f "$r" ] && grep -qx "try=$TRY" "$r" || continue
      case "$(cat "$(dirname "$r")/state" 2>/dev/null)" in done|capped|failed-to-start|stopped|cancelled) ;; *) OPENT="$OPENT $(basename "$(dirname "$r")")" ;; esac
    done
    [ -z "$OPENT" ] || { echo "ViD job: $TRY's tickets not yet terminal:$OPENT — sh checks/test.sh wait <ticket>, then clean again"; exit 75; }
    ev "job-cleaned try=$TRY"; echo "ViD job: $TRY cleaned; its worktree $(jk worktree "$J") is kept until its return is merged or superseded"; exit 0 ;;
  *) usage ;;
esac
