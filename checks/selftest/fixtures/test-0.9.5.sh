#!/bin/sh
# Purpose: run the ViD ledger (tests/invariants/) — ONLY ever inside the
# container harness via docker-compose.test.yml, so tests physically cannot
# reach anything real. v0.9.2 (3.6: R9 the receipt, R21 one image):
#   sh checks/test.sh                 the certifiable FULL run: HEAD is exported
#                                     (git archive) into a temporary context
#                                     under .vid/, mounted read-only as the tests
#                                     service's /app and used as the product's
#                                     build context; refused on a worktree with
#                                     uncommitted changes ("commit first: a
#                                     receipt names a tree"); the export is
#                                     deleted after the run.
#   sh checks/test.sh -- <selector>   a SCOPED run: the selector is the runner's
#                                     own syntax, opaque here, handed to the
#                                     compose command through VID_SELECTOR; the
#                                     live tree is mounted; never certifiable.
# The receipt: the runner writes its per-case results report to
# .vid/ledger-results/pending.xml (the compose file names the flag); this
# script renames it, only on the runner's own exit, to
# <head-sha>.full.xml (export-backed) or <head-sha>.live.sel-<hash>.xml
# (scoped — an everything-selector through this door, init's red gate, is
# still .live.); an interrupted or killed run leaves no report. One
# `ledger-run seconds=S kind=full|scoped report=<name>` event is appended to
# .vid/metrics-events. The lock: .vid/ledger.lock (mkdir), released on exit;
# a second invocation while it exists is refused naming the holder's pid and
# start time; a stale lock (holder gone) is reported with its age and never
# removed here. VID_COMPOSE overrides the compose command (the selftest
# drives a recording stub in place of the daemon).
# v0.9.3 (3.3, 3.10; R4, R14, R15 — the ungated set, R22: this script reads no
# grammar and changes for every project when checks/ is refreshed):
#   --role builder|fixer|close|grader  names who ran the run; `role=` rides the
#                                     `ledger-run` event (the reader is the wall
#                                     allocation) and RUN-STATE names who ran what.
#   A run that did not run to its end publishes nothing: the compose exit
#   status must be one of the harness contract's `completed:` statuses
#   (x-vid-harness in docker-compose.test.yml — the runner's own "ran to the
#   end" statuses, all passed or some failed); any other status — a signal
#   death, the runner's own interrupt or internal error, a usage error,
#   nothing collected — discards pending.xml whatever it holds, because a
#   runner may have written the cases it got through. A complete report of
#   failing cases is published: red is evidence. Every `ledger-run` event
#   carries `status=<n>`. A compose file without `completed:` keeps the 0.9.2
#   rule (the wrapper's own interrupt flag) and says so on every run.
#   The host lease (3.10, R14): after the repository's lock and before any
#   stack comes up — full or scoped — the wrapper takes one of `stacks` slots
#   (`.vid/budget`, default 1) under ${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/vid-host/
#   (mkdir `stack.<k>`; holder file: pid, repository, compose project, start),
#   across every repository on the host. None free → refused naming each
#   holder. A slot whose holder pid is gone is reported STALE with its age and
#   never removed here (the lock's policy — its containers may still be up).
#   Released on exit. Cleanup stays project-scoped.
#   The deployed shape (3.3, R4): when x-vid-harness declares
#   `deployed-selector:`, a full run is TWO passes on the same export under
#   one lease, each on a fresh stack: (1) the whole ledger as before, inline
#   → <sha>.full.xml; `down --remove-orphans --volumes` (the inline pass's
#   state must not leak; `down` alone keeps named volumes); (2) with
#   VID_INLINE=0 VID_SCHEDULE_FAST=1 and the `deployed` profile, `up -d
#   --build product <the profile's services>` — the product named first so
#   the image is rebuilt before any process starts from it — then the tests
#   with the deployed selector → <sha>.deployed.xml, `ledger-run …
#   kind=deployed`; `down --remove-orphans --volumes`. `--deployed --
#   <selector>` is the scoped deployed run for a builder or fixer chasing a
#   wiring failure: the live tree, the profile, the same order, named
#   <sha>.live.deployed.sel-<hash>.xml, never certifiable. A missing deployed
#   report after a full run is a missing report.
set -eu

SEL=''; ROLE=''; DEPLOYED=no
usage() { echo "ViD test: usage — sh checks/test.sh [--role builder|fixer|close|grader] [--deployed] [-- <selector>]" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --role) [ $# -ge 2 ] || usage; ROLE=$2; case "$ROLE" in builder|fixer|close|grader) ;; *) usage ;; esac; shift 2 ;;
    --deployed) DEPLOYED=yes; shift ;;
    --) shift; SEL="$*"; break ;;
    *) usage ;;
  esac
done
[ "$DEPLOYED" = yes ] && [ -z "$SEL" ] && { echo 'ViD test: --deployed is a scoped run: sh checks/test.sh --deployed -- <selector>. A full run pays the deployed pass itself when the harness declares deployed-selector:.' >&2; exit 2; }

COMPOSE=${VID_COMPOSE:-}
if [ -z "$COMPOSE" ]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo 'ViD test: Docker is not installed (or not on PATH).' >&2
    echo 'The ledger only runs inside the test container so it can never touch' >&2
    echo 'real credentials or live services. Install Docker Desktop, start it,' >&2
    echo 'then run: sh checks/test.sh' >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo 'ViD test: Docker is installed but the daemon is not running — start Docker Desktop and retry.' >&2
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo 'ViD test: the "docker compose" (v2) plugin is missing. Update Docker and retry.' >&2
    exit 1
  fi
  COMPOSE='docker compose'
fi
[ -f docker-compose.test.yml ] || { echo 'ViD test: docker-compose.test.yml missing — failing closed.' >&2; exit 1; }

mkdir -p .vid/ledger-results
HEAD=$(git rev-parse --short=12 HEAD 2>/dev/null || echo nohead)

# --- the lock -----------------------------------------------------------------
LOCK=.vid/ledger.lock
if ! mkdir "$LOCK" 2>/dev/null; then
  HPID=''; HSTART=''
  [ -f "$LOCK/holder" ] && { HPID=$(sed -n '1p' "$LOCK/holder"); HSTART=$(sed -n '2p' "$LOCK/holder"); }
  if [ -n "$HPID" ] && kill -0 "$HPID" 2>/dev/null; then
    echo "ViD test: refused — a ledger run is in progress (pid $HPID, started $HSTART; $LOCK). One run at a time: two stacks on one host is the recorded incident class." >&2
  else
    AGE='unknown age'
    if [ -f "$LOCK/holder" ]; then
      NOW=$(date +%s); THEN=$(sed -n '3p' "$LOCK/holder"); [ -n "$THEN" ] && AGE="$((NOW - THEN)) s old"
    fi
    echo "ViD test: refused — $LOCK exists and its holder (pid ${HPID:-unknown}, started ${HSTART:-unknown}) is gone: a STALE lock, $AGE. This script never removes it; look at what died, then remove the directory yourself." >&2
  fi
  exit 1
fi
printf '%s\n%s\n%s\n' "$$" "$(date '+%Y-%m-%d %H:%M:%S')" "$(date +%s)" > "$LOCK/holder"

# --- the host lease (v0.9.3 3.10) --------------------------------------------------
HOSTD="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"; HOSTD="${HOSTD%/}/vid-host"
STACKS=1
if [ -f .vid/budget ]; then
  B=$(sed -n 's/^stacks=\([0-9][0-9]*\).*/\1/p' .vid/budget | head -n 1)
  [ -n "$B" ] && [ "$B" -ge 1 ] && STACKS=$B
fi
mkdir -p "$HOSTD"
LEASE=''
k=1
while [ "$k" -le "$STACKS" ]; do
  if mkdir "$HOSTD/stack.$k" 2>/dev/null; then LEASE="$HOSTD/stack.$k"; break; fi
  k=$((k + 1))
done
if [ -z "$LEASE" ]; then
  echo "ViD test: refused — the host budget allows $STACKS test stack(s) at once and every slot is held (.vid/budget stacks=$STACKS; the recorded incident was three stacks on one machine):" >&2
  for sl in "$HOSTD"/stack.*; do
    [ -d "$sl" ] || continue
    LP=$(sed -n '1p' "$sl/holder" 2>/dev/null || true); LR=$(sed -n '2p' "$sl/holder" 2>/dev/null || true)
    LC=$(sed -n '3p' "$sl/holder" 2>/dev/null || true); LT=$(sed -n '4p' "$sl/holder" 2>/dev/null || true)
    if [ -n "$LP" ] && kill -0 "$LP" 2>/dev/null; then
      echo "    ${sl##*/}: held by pid $LP — repository $LR, compose project $LC, for $(( $(date +%s) - ${LT:-0} )) s" >&2
    else
      echo "    ${sl##*/}: STALE — pid ${LP:-unknown} is gone (repository ${LR:-unknown}, compose project ${LC:-unknown}), $(( $(date +%s) - ${LT:-0} )) s old. Never removed here: inspect that project's containers, stop them, then remove $sl yourself." >&2
    fi
  done
  rm -rf "$LOCK"
  exit 1
fi
printf '%s\n%s\n%s\n%s\n' "$$" "$PWD" "${COMPOSE_PROJECT_NAME:-$(basename "$PWD")}" "$(date +%s)" > "$LEASE/holder"

EXPORT=''
INTERRUPTED=0
cleanup() {
  [ -n "$EXPORT" ] && rm -rf "$EXPORT"
  [ -n "$LEASE" ] && rm -rf "$LEASE"
  rm -rf "$LOCK"
}
on_signal() { INTERRUPTED=1; rm -f .vid/ledger-results/pending.xml; cleanup; echo 'ViD test: interrupted — no report written (a receipt names a run that completed).' >&2; exit 130; }
trap cleanup EXIT
trap on_signal INT TERM HUP

# --- what runs: an export of HEAD, or the live tree -----------------------------
if [ -z "$SEL" ]; then
  KIND=full
  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo 'ViD test: refused — no commit to export; a full run is export-backed (commit first: a receipt names a tree). Before the initial commit, run the whole ledger through the live path with the everything-selector: sh checks/test.sh -- <selector>.' >&2
    exit 1
  fi
  DIRTY=$(git status --porcelain -- . ':(exclude).vid' 2>/dev/null || true)
  if [ -n "$DIRTY" ]; then
    echo 'ViD test: refused — the worktree carries uncommitted changes; commit first: a receipt names a tree.' >&2
    printf '%s\n' "$DIRTY" | head -n 5 | sed 's/^/    /' >&2
    echo 'A scoped run (sh checks/test.sh -- <selector>) uses the live tree and is never certifiable.' >&2
    exit 1
  fi
  EXPORT=$(mktemp -d "$PWD/.vid/export.XXXXXX")
  git archive --format=tar HEAD | tar -xf - -C "$EXPORT"
  VID_TEST_CONTEXT=$EXPORT
  NAME="$HEAD.full.xml"
else
  KIND=scoped
  VID_TEST_CONTEXT=.
  HASH=$(printf '%s' "$SEL" | cksum | cut -d' ' -f1)
  NAME="$HEAD.live.sel-$HASH.xml"
fi
export VID_TEST_CONTEXT
VID_SELECTOR=$SEL; export VID_SELECTOR

# --- the harness contract ----------------------------------------------------------
hkey() { awk -v k="$1:" '/^x-vid-harness:/{inx=1; next} inx && /^[^ #]/{inx=0} inx && $1==k { v=$0; sub(/^[^:]*:[ \t]*/,"",v); sub(/[ \t]*#.*$/,"",v); print v; exit }' docker-compose.test.yml; }
COMPLETED=$(hkey completed | tr '[],' '   ' | tr -s ' ' | sed 's/^ //;s/ $//')
DSEL=$(hkey deployed-selector)
PROFSVCS=$(awk '
  /^services:/ { ins=1; next } ins && /^[^ ]/ { ins=0 }
  ins && /^  [A-Za-z0-9_.-]+:/ { name=$1; sub(/:$/,"",name); inprof=0; next }
  ins && name != "" && /^    profiles:/ { v=$0; sub(/^[^:]*:/,"",v); if (v ~ /deployed/) p[name]=1; inprof=1; next }
  ins && name != "" && inprof && /^      - / { if ($0 ~ /deployed/) p[name]=1; next }
  ins && name != "" && /^    [a-z]/ { inprof=0 }
  END { for (s in p) print s }' docker-compose.test.yml | sort | tr '\n' ' ' | sed 's/ $//')
if [ "$DEPLOYED" = yes ] && [ -z "$DSEL" ]; then
  echo 'ViD test: refused — --deployed needs the harness contract to declare deployed-selector: and the deployed profile (docker-compose.test.yml x-vid-harness); this product declares no process beside the web process.' >&2
  exit 1
fi
if [ -z "$COMPLETED" ]; then
  echo "ViD test: note — docker-compose.test.yml's x-vid-harness declares no completed: statuses; a partial report after a runner interrupt cannot be told from a complete one (v0.9.3 3.3). Add the runner's ran-to-the-end statuses." >&2
fi
ROLEF=''; [ -n "$ROLE" ] && ROLEF=" role=$ROLE"
FINAL=0

# publish <name> <kind> <status> <seconds>: renamed only when the run ran to its end
publish() {
  RAN_TO_END=yes; WHY=''
  if [ -n "$COMPLETED" ]; then
    case " $COMPLETED " in *" $3 "*) ;; *) RAN_TO_END=no; WHY="compose exit $3 is outside the harness contract's completed: [$COMPLETED] — the run did not run to its end" ;; esac
  fi
  if [ "$INTERRUPTED" -eq 0 ] && [ "$RAN_TO_END" = yes ] && [ -f .vid/ledger-results/pending.xml ]; then
    mv .vid/ledger-results/pending.xml ".vid/ledger-results/$1"
    echo "ViD test: report .vid/ledger-results/$1 ($2 run, tree $HEAD, exit $3)"
    printf 'ledger-run seconds=%s kind=%s report=%s status=%s%s at=%s\n' "$4" "$2" "$1" "$3" "$ROLEF" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
  else
    rm -f .vid/ledger-results/pending.xml
    if [ "$RAN_TO_END" = no ]; then
      echo "ViD test: no report — $WHY; whatever the runner wrote is discarded (a receipt names a run that completed)." >&2
    else
      echo "ViD test: no report — the runner did not write one (exit $3); nothing is green that did not run." >&2
    fi
    printf 'ledger-run seconds=%s kind=%s report=none status=%s%s at=%s\n' "$4" "$2" "$3" "$ROLEF" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
  fi
  [ "$FINAL" -ne 0 ] || FINAL=$3
}
# inline_pass <name> <kind> <down-args>
inline_pass() {
  rm -f .vid/ledger-results/pending.xml
  START=$(date +%s); STATUS=0
  $COMPOSE -f docker-compose.test.yml up --build --exit-code-from tests tests || STATUS=$?
  $COMPOSE -f docker-compose.test.yml down $3 >/dev/null 2>&1 || true
  publish "$1" "$2" "$STATUS" "$(( $(date +%s) - START ))"
}
# deployed_pass <name> <kind> <selector>: a fresh stack in the profile, nothing inline
deployed_pass() {
  rm -f .vid/ledger-results/pending.xml
  START=$(date +%s); STATUS=0
  VID_SELECTOR=$3; export VID_SELECTOR
  if VID_INLINE=0 VID_SCHEDULE_FAST=1 $COMPOSE -f docker-compose.test.yml --profile deployed up -d --build product $PROFSVCS; then
    VID_INLINE=0 VID_SCHEDULE_FAST=1 $COMPOSE -f docker-compose.test.yml --profile deployed up --exit-code-from tests tests || STATUS=$?
  else
    STATUS=$?; echo "ViD test: the deployed shape did not come up (product and $PROFSVCS) — no deployed report." >&2
  fi
  $COMPOSE -f docker-compose.test.yml --profile deployed down --remove-orphans --volumes >/dev/null 2>&1 || true
  publish "$1" "$2" "$STATUS" "$(( $(date +%s) - START ))"
}

# --- the run --------------------------------------------------------------------
if [ "$KIND" = full ] && [ -n "$DSEL" ]; then
  inline_pass "$NAME" full '--remove-orphans --volumes'
  deployed_pass "$HEAD.deployed.xml" deployed "$DSEL"
elif [ "$DEPLOYED" = yes ]; then
  deployed_pass "$HEAD.live.deployed.sel-$HASH.xml" scoped "$SEL"
else
  inline_pass "$NAME" "$KIND" '--remove-orphans'
fi
exit $FINAL
