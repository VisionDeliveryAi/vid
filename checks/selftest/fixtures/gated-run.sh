# Purpose: selftest fixture — a toy develop run under a 0.9.6 plan, for the
# test-run cases (v0.9.6 spec 3.6–3.10, §7 cases 5–15). Sourced by a case
# after it has made $T (its scratch directory, outside any repository).
# gated_repo <dir> makes a repository there — checks/test.sh and plan.sh,
# a compose file with a harness contract, app/main.py, .vid/ ignored — and
# enters it; gate_on writes RUN-STATE (`plan: required`, `run: active`) and
# a develop stage start. The compose command is a recording stub
# ($T/stub.sh; one line per call in $STUB_LOG: `<folder>|<compose
# project>|<VID_TEST_CONTEXT>|<VID_SELECTOR>|<arguments>`). On `up` it
# writes the runner's report where the run's results mount points (the
# frozen copy's ../results inside the gate, .vid/ledger-results outside),
# after recording `ctx-main=<app/main.py in the tested context>` (the
# report carries ctx="<VID_TEST_CONTEXT>" and one case, status $STUB_CASE,
# default passed); it holds
# while $STUB_HOLD exists (touching $STUB_ENTER when it starts) — with
# $STUB_DOWN_ENDS set, until its own project's `down` too, then it records
# `ended-by-down lease=held|free folder=exists|gone` (the slot and the run
# folder as it ends), writes its report anyway (a late writer, recreating
# the folder if it is gone) and exits 143 — fails
# `down` when $STUB_DOWN_FAIL is set, refuses `config` on an override
# carrying !reset when $STUB_NORESET is set, and exits $STUB_STATUS (default
# 0). It sends TERM to the running checks/test.sh (its pid from the run
# folder's holder inside the gate, the lock's outside) from an `up` whose
# arguments contain $STUB_KILL_ON; it records `lease-at-down=held|free` at
# every `down`; and it answers `ps` with a container only for a compose
# project it brought up and has not brought down (a rendered extractor's
# join). v0.9.7.0.2: with $STUB_REPORT set, `up` writes that file as the
# report instead of its one case; with $STUB_DOWN_SLEEP set, `down` takes
# that many seconds (a slow teardown). v0.9.7.0.10: with $STUB_DOWN_HOLD
# set, `down` waits while that file exists (a blocked teardown); `logs`
# prints `stub-logs <compose project>`. v0.9.7.0.11: `logs` records
# `logs-at results=<n>`, the tickets with a result at that moment; `up`
# records `case-limit=<VID_CASE_LIMIT>` when that is set. v0.9.7.0.12: a gated run's folder is
# found from its override.yml argument (v0.9.8.1: with $STUB_DEPLOYED_STATUS set, an `up` of the deployed profile exits with it; `logs` records `logs-tail=yes|no` and, with $STUB_LOG_LINES set, prints that many numbered lines after its own) (a close batch's chunk runs the batch's export, not
# <run>/ctx). With $STUB_BYSEL set, `up` writes one case per word of VID_SELECTOR, named by
# the word, its status from $STUB_STATUSES (`<word> <status>` lines; default passed) and its seconds
# from $STUB_CASE_TIME (default 0.1), and the
# first `up` whose selection holds the word $STUB_SIGNAL_SEL sends TERM to its run instead (a
# signal; later ones run). v0.9.7.3: with $STUB_BUILD_FAIL set to a status, an `up --build` prints a failed build to standard
# error and exits with that status, writing no report. A TERM to `up` records `ended-by-term lease=held|free folder=exists|gone`
# and exits 143; with $STUB_UP_NOTERM set, `up` ignores TERM (a Compose call that outlives its stop). v0.26.10.4: with
# $STUB_PRINT set, `up` prints that many lines, one a second, before it holds; with $STUB_CHATTY set, it prints a line each
# second while it holds (a runner's output, to standard output); with $STUB_CHATTY_ERR set, a line each second to standard
# error (Compose's own output, as a build's); with $STUB_HOLD_DEPLOYED set, an `up` of the deployed profile holds on that
# file instead of $STUB_HOLD. The host lease lives in a private runtime directory. Env: CHECKS, T.
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
utcnow() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
mkdir -p "$T/run"; export XDG_RUNTIME_DIR="$T/run"
cat > "$T/stub.sh" <<'STUB'
#!/bin/sh
printf '%s|%s|%s|%s|%s\n' "$(basename "$PWD")" "${COMPOSE_PROJECT_NAME:-}" "${VID_TEST_CONTEXT:-}" "${VID_SELECTOR:-}" "$*" >> "$STUB_LOG"
SD=$(dirname "$STUB_LOG"); PJ=${COMPOSE_PROJECT_NAME:-$(basename "$PWD")}
RF=''; for a in "$@"; do case "$a" in */override.yml) RF=${a%/override.yml} ;; esac; done   # a gated run's folder, from its override
tpid() { if [ -n "$RF" ]; then sed -n 's/^pid=//p' "$RF/holder"; else sed -n 1p .vid/ledger.lock/holder; fi; }
case " $* " in
  *' logs '*) echo "logs-at results=$(ls .vid/requests/*/result 2>/dev/null | grep -c . || true)" >> "$STUB_LOG"
    case " $* " in *' --tail '*) echo 'logs-tail=yes' >> "$STUB_LOG" ;; *) echo 'logs-tail=no' >> "$STUB_LOG" ;; esac
    echo "stub-logs $PJ"; [ -n "${STUB_LOG_LINES:-}" ] && awk -v n="$STUB_LOG_LINES" 'BEGIN { for (i = 1; i <= n; i++) printf "2026-01-01T00:00:00.%09dZ line %d of the stack %08x\n", i, i, i * 2654435761 % 4294967296 }'; exit 0 ;;
  *' ps '*) [ -f "$SD/up.$PJ" ] && echo "container-of-$PJ"; exit 0 ;;
  *' config '*)
    if [ -n "${STUB_NORESET:-}" ]; then for a in "$@"; do case "$a" in *override.yml) grep -q '!reset' "$a" && exit 15 ;; esac; done; fi
    exit 0 ;;
  *' down '*)
    if [ -d "$XDG_RUNTIME_DIR/vid-host" ] && ls "$XDG_RUNTIME_DIR/vid-host" | grep -q .; then echo 'lease-at-down=held' >> "$STUB_LOG"; else echo 'lease-at-down=free' >> "$STUB_LOG"; fi
    [ -n "${STUB_DOWN_SLEEP:-}" ] && sleep "$STUB_DOWN_SLEEP"
    while [ -n "${STUB_DOWN_HOLD:-}" ] && [ -f "$STUB_DOWN_HOLD" ]; do sleep 1; done
    [ -n "${STUB_DOWN_FAIL:-}" ] && exit 1; rm -f "$SD/up.$PJ"; exit 0 ;;
  *' up -d '*) : > "$SD/up.$PJ"; exit 0 ;;
  *' up '*)
    if [ -n "${STUB_BUILD_FAIL:-}" ]; then case " $* " in *' --build '*) printf ' => ERROR [tests 2/4] RUN install the runner\ntarget tests: failed to solve: DeadlineExceeded: failed to fetch the base image\n' >&2; exit "$STUB_BUILD_FAIL" ;; esac; fi
    : > "$SD/up.$PJ"
    if [ -n "${STUB_UP_NOTERM:-}" ]; then trap '' TERM
    else trap 'if ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null | grep -q .; then _l=held; else _l=free; fi; if [ -d "${RF:-/nonexistent}" ]; then _d=exists; else _d=gone; fi
      echo "ended-by-term lease=$_l folder=$_d" >> "$STUB_LOG"; exit 143' TERM; fi
    case " $* " in *"${STUB_KILL_ON:-no such arguments}"*) kill -TERM "$(tpid)"; exit 143 ;; esac
    [ -n "${STUB_ENTER:-}" ] && : > "$STUB_ENTER"
    _pn=0; while [ "$_pn" -lt "${STUB_PRINT:-0}" ]; do _pn=$((_pn + 1)); echo "stub runner line $_pn"; sleep 1; done
    _hf=${STUB_HOLD:-}; case " $* " in *' --profile deployed '*) _hf=${STUB_HOLD_DEPLOYED:-$_hf} ;; esac
    while [ -n "$_hf" ] && [ -f "$_hf" ]; do
      [ -n "${STUB_DOWN_ENDS:-}" ] && [ ! -f "$SD/up.$PJ" ] && break
      [ -n "${STUB_CHATTY:-}" ] && echo "stub runner line at $(date +%s)"
      [ -n "${STUB_CHATTY_ERR:-}" ] && echo "stub build step at $(date +%s)" >&2
      sleep 1; done
    if [ -n "$RF" ]; then R="$RF/results"; else R=.vid/ledger-results; fi
    if [ -n "${STUB_DOWN_ENDS:-}" ] && [ ! -f "$SD/up.$PJ" ]; then   # ended by its project's down: what was still held then; then a late write, as a runner may make
      if ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null | grep -q .; then _l=held; else _l=free; fi
      if [ -d "${R%/*}" ]; then _d=exists; else _d=gone; fi
      echo "ended-by-down lease=$_l folder=$_d" >> "$STUB_LOG"; STUB_STATUS=143
    fi
    printf 'ctx-main=%s\n' "$(cat "$VID_TEST_CONTEXT/app/main.py" 2>/dev/null | tr '\n' ' ')" >> "$STUB_LOG"
    [ -z "${VID_CASE_LIMIT+x}" ] || printf 'case-limit=%s\n' "$VID_CASE_LIMIT" >> "$STUB_LOG"
    mkdir -p "$R"
    if [ -n "${STUB_BYSEL:-}" ]; then   # one case per selection word, named by it; its status from $STUB_STATUSES (`<word> <status>`), else passed
      case " $VID_SELECTOR " in *" ${STUB_SIGNAL_SEL:-no such word} "*) [ -f "$SD/sig.done" ] || { : > "$SD/sig.done"; kill -TERM "$(tpid)"; exit 143; } ;; esac
      { printf '<report>\n'; for w in $VID_SELECTOR; do st=$(awk -v w="$w" '$1 == w { print $2 }' "${STUB_STATUSES:-/dev/null}"); printf '<case name="%s" status="%s" time="%s"/>\n' "$w" "${st:-passed}" "${STUB_CASE_TIME:-0.1}"; done; printf '</report>\n'; } > "$R/pending.xml"
    elif [ -n "${STUB_REPORT:-}" ]; then cp "$STUB_REPORT" "$R/pending.xml"
    else printf '<report ctx="%s"><case name="tests/invariants/t.py::a[ROW-001]" status="%s" time="0.1"/></report>\n' "$VID_TEST_CONTEXT" "${STUB_CASE:-passed}" > "$R/pending.xml"; fi
    case " $* " in *' --profile deployed '*) [ -n "${STUB_DEPLOYED_STATUS:-}" ] && exit "$STUB_DEPLOYED_STATUS" ;; esac   # v0.9.8.1: the deployed pass's own status
    exit "${STUB_STATUS:-0}" ;;
esac
exit 0
STUB
chmod +x "$T/stub.sh"
export VID_COMPOSE="$T/stub.sh" STUB_LOG="$T/stub.log"
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
    ports:
      - "8000:8000"
  tests:
    image: runner
    container_name: toy-tests
    volumes:
      - ${VID_TEST_CONTEXT:-.}:/app:ro
      - ./.vid/ledger-results:/vid-results
'
gated_repo() {
  mkdir -p "$1/checks" "$1/app" "$1/.vid"; cd "$1"; git init -q
  cp "$CHECKS/test.sh" "$CHECKS/plan.sh" checks/
  printf '%s' "$COMPOSEFILE" > docker-compose.test.yml
  printf 'main v1\n' > app/main.py
  printf '.vid/\n' > .gitignore
  g add -A && g commit -qm root
}
gate_on() { # [run value]
  printf 'run: %s\nsession: S1\nplan: required\nquestions: - · next Q1\nslice: 1 open    since: x    commit: x\n' "${1:-active}" > .vid/RUN-STATE.md
  printf 'stage name=develop state=start session=S1 records=2 at=%s\n' "$(utcnow)" >> .vid/metrics-events
}
# the kept receipts and the run folders
kept() { ls .vid/ledger-results 2>/dev/null | grep -E '\.run-[0-9TZ]+-[0-9]+\.' | grep -vE '\.(tree|cases|rows)$' || true; }
nruns() { ls .vid/runs 2>/dev/null | grep -c . || true; }
# v0.9.8.1 (R2): the default bound is 120 s, not 20 — it only lengthens a case already failing, and a loaded host took longer
waitfor() { _i=0; while [ ! -e "$1" ] && [ "$_i" -lt "${2:-120}" ]; do sleep 1; _i=$((_i + 1)); done; [ -e "$1" ]; }
