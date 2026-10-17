#!/bin/sh
# Purpose: ViD watchdog — long-run supervision (§8). Every long-running
# operation (ledger run, spawned agent, corpus build) declares an expected
# envelope and a MECHANICAL probe of the underlying system (active-query
# age, container state, agent liveness). Exceeding the envelope triggers
# the probe — never a re-estimate, never a longer wait — and a progress
# claim resolves to an observation or declares itself unverified (§8.2):
# elapsed time is not evidence of progress. Heartbeat trail in
# .vid/HEARTBEAT.md (§8.3): what is running, since when, on what evidence,
# what session defaults were decided — a morning review reconstructs the
# night from records, not from the session's memory of itself. Fails
# closed: an exceeded envelope with no declared probe, and an unevidenced
# claim, are rejections, never warnings. Envelopes are declared per
# operation and adjustable — but only by an explicit re-declare, which the
# heartbeat records; there is no silent snooze.
# v0.9.3 (3.9, R13 — the ungated set, R22: this script reads no grammar and
# changes for every project when checks/ is refreshed):
#   The probe is a PREDICATE about the named operation: it exits 0 only when
#   it observes that operation itself alive or progressed (a process by its
#   id, a query by its age, a container by its name and state) and non-zero
#   otherwise. `declare` takes the operation's identifier as its fourth
#   argument and refuses a missing probe, a missing identifier, and a probe
#   that does not name the identifier — a command that lists status and
#   exits 0 whether or not the operation exists is not a probe.
#   `check` runs the probe in the background and stops it after
#   VID_PROBE_BOUND seconds (default 60): exit 2 when the probe returned
#   zero (the system answered — reported), exit 3 when it returned non-zero
#   or did not return (`probe timeout` — the system itself is the finding);
#   it stamps `checked=<time>` in the operation's file. Under VID_OBSERVER=1
#   (checks/observe.sh) every heartbeat line it writes is prefixed
#   `observe:` and no `stall` event is appended — the observer never
#   refreshes the session's clock nor counts its own ticks as stalls.
#   Done requires check: `done` on an operation past its envelope with no
#   `checked=` after the expiry is refused — an overdue operation closes on
#   an observation, never on elapsed time. Re-declare keeps `start=` and
#   changes only the envelope, and is refused on an operation already past
#   its envelope with no check after the expiry. `report` prints
#   `EXCEEDED (unprobed)` for such an operation. `claim run --evidence …`
#   answers the observer's nudge: it removes .vid/NUDGE and is session
#   activity.
# v0.9.5 (3.3, R3): `declare` and a re-declare refuse an envelope that is not
#   whole seconds (`90m`, `the fix pass`); the observer compares it as a
#   number, and a declared operation inside its envelope holds the owner's
#   quiet notice back for at most 2 h after its start.
# Usage:
#   sh checks/watchdog.sh declare <op> <envelope-seconds> '<probe-cmd>' <operation-id>
#   sh checks/watchdog.sh check <op>     exit 0 within · 2 exceeded, probe answered · 3 exceeded, probe failed or timed out · 1 law violation
#   sh checks/watchdog.sh claim <op> (--evidence '<observation>' | --unverified) <text>
#   sh checks/watchdog.sh done <op> · note <text> · report
set -eu

DIR=.vid/watchdog
HB=.vid/HEARTBEAT.md
EVENTS=.vid/metrics-events
PFX=''; [ "${VID_OBSERVER:-}" = 1 ] && PFX='observe: '

hb() { # append one heartbeat record, newest last
  mkdir -p .vid
  [ -f "$HB" ] || printf '# Heartbeat — appended by checks/watchdog.sh (§8.3); newest last\n' > "$HB"
  printf -- '- %s | %s%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$PFX" "$1" >> "$HB"
}
key() { sed -n "s/^$2=//p" "$1" | tail -n 1; }
# overdue_unchecked <file>: 0 when past the envelope with no check after the expiry
overdue_unchecked() {
  _s=$(key "$1" start); _e=$(key "$1" envelope); _c=$(key "$1" checked)
  _n=$(date +%s)
  [ $((_n - _s)) -gt "$_e" ] || return 1
  if [ -n "$_c" ] && [ "$_c" -ge $((_s + _e)) ]; then return 1; fi
  return 0
}

CMD=${1:-report}
case "$CMD" in
  declare)
    OP=${2:?op name}; ENVL=${3:?envelope seconds}; PROBE=${4:-}; OPID=${5:-}
    # v0.9.5 (3.3): the envelope is whole seconds, for a declaration and a
    # re-declare alike — the observer compares it as a number.
    case "$ENVL" in ''|*[!0-9]*)
      echo "ViD watchdog: refused — the envelope for '$OP' is '$ENVL', not whole seconds. Declare it as a number of seconds (5400, never '90m' or prose): the observer compares it as a number (v0.9.5 3.3)." >&2
      exit 1 ;;
    esac
    mkdir -p "$DIR"
    if [ -f "$DIR/$OP" ]; then
      if overdue_unchecked "$DIR/$OP"; then
        echo "ViD watchdog: refused — '$OP' is already past its envelope and has not been checked since; run check first: an overdue operation closes on an observation, never on elapsed time, and enlarging its envelope is no observation." >&2
        exit 1
      fi
      OLD=$(key "$DIR/$OP" envelope)
      sed "s/^envelope=.*/envelope=$ENVL/" "$DIR/$OP" > "$DIR/.$OP.tmp" && mv "$DIR/.$OP.tmp" "$DIR/$OP"
      hb "watchdog $OP re-declared (envelope ${OLD}s → ${ENVL}s; start unchanged) — explicit and recorded, never an implicit snooze"
      echo "watchdog: $OP re-declared (envelope ${ENVL}s, start unchanged)"
      exit 0
    fi
    if [ -z "$PROBE" ]; then
      echo "ViD watchdog: refused — '$OP' declared with no probe. Declare the predicate that observes this operation alive or progressed, decided now, not improvised when it stalls (§8.1)." >&2
      exit 1
    fi
    if [ -z "$OPID" ]; then
      echo "ViD watchdog: refused — '$OP' declared with no operation identifier. The fourth argument names the operation (its pid, its container name, its query tag) and the probe must observe exactly it." >&2
      exit 1
    fi
    case "$PROBE" in *"$OPID"*) ;; *)
      echo "ViD watchdog: refused — the probe for '$OP' does not name its operation identifier '$OPID'. A command that lists status and exits 0 whether or not the operation exists is not a probe; name the operation (v0.9.3 3.9)." >&2
      exit 1 ;;
    esac
    printf 'start=%s\nenvelope=%s\nprobe=%s\nid=%s\n' "$(date +%s)" "$ENVL" "$PROBE" "$OPID" > "$DIR/$OP"
    hb "watchdog $OP declared: envelope ${ENVL}s, operation $OPID, probe: $PROBE"
    echo "watchdog: $OP declared (envelope ${ENVL}s)"
    ;;
  check)
    OP=${2:?op name}
    [ -f "$DIR/$OP" ] || { echo "ViD watchdog: unknown operation '$OP' — declare the envelope before the operation runs." >&2; exit 1; }
    start=$(key "$DIR/$OP" start); envl=$(key "$DIR/$OP" envelope)
    probe=$(key "$DIR/$OP" probe)
    now=$(date +%s); elapsed=$((now - start))
    if [ "$elapsed" -le "$envl" ]; then
      echo "ok $OP elapsed ${elapsed}s of ${envl}s"
      exit 0
    fi
    if [ -z "$probe" ]; then
      echo "ViD watchdog: $OP exceeded its envelope (${elapsed}s > ${envl}s) with NO mechanical probe declared." >&2
      echo 'A narrative from elapsed time is not evidence (§8.1). Declare a probe of the underlying system — active-query age, container state, agent liveness — and re-check; never re-estimate, never wait longer.' >&2
      hb "watchdog $OP EXCEEDED (${elapsed}s > ${envl}s) — no probe declared: unverifiable"
      exit 1
    fi
    echo "EXCEEDED $OP (${elapsed}s > ${envl}s) — probing the underlying system, never waiting longer:"
    BOUND=${VID_PROBE_BOUND:-60}
    OUTF=$(mktemp)
    sh -c "$probe" > "$OUTF" 2>&1 &
    PRB=$!
    waited=0; TIMEOUT=no
    while kill -0 "$PRB" 2>/dev/null; do
      if [ "$waited" -ge "$BOUND" ]; then
        TIMEOUT=yes
        pkill -P "$PRB" 2>/dev/null || true
        kill "$PRB" 2>/dev/null || true
        break
      fi
      sleep 1; waited=$((waited + 1))
    done
    PRC=0; wait "$PRB" 2>/dev/null || PRC=$?
    POUT=$(cat "$OUTF"); rm -f "$OUTF"
    now=$(date +%s)
    if grep -q '^checked=' "$DIR/$OP"; then
      sed "s/^checked=.*/checked=$now/" "$DIR/$OP" > "$DIR/.$OP.tmp" && mv "$DIR/.$OP.tmp" "$DIR/$OP"
    else
      printf 'checked=%s\n' "$now" >> "$DIR/$OP"
    fi
    if [ "$TIMEOUT" = yes ]; then
      POUT="probe timeout — the probe did not return within ${BOUND}s (the system itself is the finding)"
      RC=3
    elif [ "$PRC" -ne 0 ]; then
      POUT="$POUT
(probe exited $PRC — the system itself is the finding)"
      RC=3
    else
      RC=2
    fi
    printf '%s\n' "$POUT" | sed 's/^/    /'
    hb "watchdog $OP EXCEEDED (${elapsed}s > ${envl}s); probe observed: $(printf '%s\n' "$POUT" | grep -v '^$' | head -n 1)"
    [ -n "$PFX" ] || printf 'stall op=%s elapsed=%s envelope=%s at=%s\n' "$OP" "$elapsed" "$envl" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EVENTS"
    exit "$RC"
    ;;
  claim)
    OP=${2:?op name}; shift 2
    EV=''; UNV=no
    case "${1:-}" in
      --evidence) EV=${2:?observation}; shift 2 ;;
      --unverified) UNV=yes; shift ;;
    esac
    TEXT=${*:-}
    if [ -z "$EV" ] && [ "$UNV" = no ]; then
      echo "ViD watchdog: rejected — a progress claim resolves to an observation (--evidence '<last test id / commit sha / query age>') or declares itself --unverified (§8.2)." >&2
      echo 'Elapsed time is not evidence of progress.' >&2
      exit 1
    fi
    if [ "$UNV" = yes ]; then
      hb "claim $OP UNVERIFIED: $TEXT"
      echo "claim recorded (unverified): $OP — $TEXT"
    else
      hb "claim $OP: $TEXT | evidence: $EV"
      echo "claim recorded: $OP — $TEXT (evidence: $EV)"
    fi
    if [ "$OP" = run ] && [ -n "$EV" ] && [ -f .vid/NUDGE ]; then
      rm -f .vid/NUDGE
      hb "nudge answered with an observation: $EV"
    fi
    ;;
  done)
    OP=${2:?op name}
    if [ -f "$DIR/$OP" ]; then
      if overdue_unchecked "$DIR/$OP"; then
        echo "ViD watchdog: refused — '$OP' is past its envelope and has not been checked since; run check first: an overdue operation closes on an observation, never on elapsed time (v0.9.3 3.9)." >&2
        exit 1
      fi
      start=$(key "$DIR/$OP" start); now=$(date +%s)
      hb "watchdog $OP done after $((now - start))s"
      rm -f "$DIR/$OP"
    else
      echo "ViD watchdog: '$OP' was never declared — done recorded as a supervision gap." >&2
      hb "watchdog $OP done (never declared — supervision gap)"
    fi
    ;;
  note)
    shift
    hb "note: $*"
    ;;
  report)
    if [ -d "$DIR" ]; then
      now=$(date +%s)
      for f in "$DIR"/*; do
        [ -f "$f" ] || continue
        op=${f##*/}; start=$(key "$f" start); envl=$(key "$f" envelope)
        el=$((now - start))
        st=ok
        if [ "$el" -gt "$envl" ]; then
          if overdue_unchecked "$f"; then st='EXCEEDED (unprobed)'; else st="EXCEEDED (probed $(( now - $(key "$f" checked) ))s ago)"; fi
        fi
        echo "$st $op elapsed ${el}s of ${envl}s"
      done
    fi
    [ -f "$HB" ] && cat "$HB"
    exit 0
    ;;
  *)
    echo "ViD watchdog: unknown command '$CMD' (declare|check|claim|done|note|report)." >&2
    exit 1
    ;;
esac
exit 0
