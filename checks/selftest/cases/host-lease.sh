#!/bin/sh
# Purpose: selftest case — the host lease (v0.9.3 spec 3.10, R14; §7 case
# 10). Two toy repositories under one runtime directory, the ledger wrapper
# driven through a recording compose stub that holds the stack while a
# marker file exists. Convicts unless: with `stacks=1` a second run — full
# or scoped — is refused while the first holds the slot, naming the first's
# repository and pid; `stacks=2` admits it; a slot whose holder pid is gone
# is reported STALE with its age and kept while a container of its compose
# project is left (v0.9.7.0.8 T2.2; never removed before); the lease is released
# when the run ends; and one repository's run brings down only its own
# compose project (cleanup is project-scoped). v0.9.6 (3.7.5, 3.9; §7 case
# 13), gated: inside a develop run under a 0.9.6 plan no lock is taken and
# a second run in the same folder gets its own run folder and slot, but
# only once .vid/budget carries testenv=proved beside stacks=2 — stacks=2
# alone keeps one slot. v0.9.7.0.8: a request queued behind a stale slot
# counts it stale on its queue line and `wait` prints the holders while it
# is queued (T2.1); with a stubbed `docker ps` that answers empty the stale
# slot is reclaimed once — one slot-reclaimed event — and the run proceeds
# (T2.2). Docker itself never runs: VID_DOCKER names a stub. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -f "$T/hold"; rm -rf "$T"' EXIT
mkdir -p "$T/run"; export XDG_RUNTIME_DIR="$T/run"
cat > "$T/stub.sh" <<'STUB'
#!/bin/sh
printf '%s %s project=%s\n' "$(basename "$PWD")" "$*" "${COMPOSE_PROJECT_NAME:-}" >> "$STUB_LOG"
case "$*" in *' up '*)
  while [ -f "$STUB_HOLD" ]; do sleep 1; done
  case "${VID_TEST_CONTEXT:-}" in */ctx) R="${VID_TEST_CONTEXT%/ctx}/results" ;; *) R=.vid/ledger-results ;; esac
  printf '<report><case name="tests/invariants/t.py::a[ROW-001]" status="passed" time="0.1"/></report>\n' > "$R/pending.xml" ;;
esac
exit 0
STUB
chmod +x "$T/stub.sh"
export VID_COMPOSE="$T/stub.sh" STUB_LOG="$T/stub.log" STUB_HOLD="$T/never-held"   # only alpha's run holds its stack
# the docker command for the reclaim's check: prints $DOCKER_LEFT (the containers left), exits $DOCKER_RC
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$DOCKER_LOG"\n[ -n "${DOCKER_LEFT:-}" ] && echo "$DOCKER_LEFT"\nexit "${DOCKER_RC:-0}"\n' > "$T/docker.sh"
chmod +x "$T/docker.sh"; export DOCKER_LOG="$T/docker.log"
repo() {
  mkdir -p "$T/$1/checks" "$T/$1/.vid"; cd "$T/$1"; git init -q
  cp "$CHECKS/test.sh" checks/
  printf 'x-vid-harness:\n  product: product\n  completed: [0, 1]\nservices:\n  product:\n    build: .\n' > docker-compose.test.yml
  printf '.vid/\n' > .gitignore
  git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
}
fail() { echo "host-lease: $*" >&2; cat "$T/b.out" >&2 2>/dev/null || true; exit 1; }
repo alpha; repo beta
# alpha holds the one slot
touch "$T/hold"
( cd "$T/alpha" && STUB_HOLD="$T/hold" sh checks/test.sh --role close > "$T/a.out" 2>&1 ) &
APID=$!
i=0; while [ ! -d "$T/run/vid-host/stack.1" ] && [ $i -lt 20 ]; do sleep 1; i=$((i + 1)); done
[ -d "$T/run/vid-host/stack.1" ] || fail 'the first run took no slot'
HP=$(sed -n '1p' "$T/run/vid-host/stack.1/holder")
cd "$T/beta"
if sh checks/test.sh > "$T/b.out" 2>&1; then fail 'a second full run was admitted under stacks=1'; fi
grep -q "refused — the host budget allows 1 test stack" "$T/b.out" || fail 'the refusal does not state the budget'
grep -q "held by pid $HP — repository $T/alpha" "$T/b.out" || fail "the refusal does not name the holder's pid and repository"
if sh checks/test.sh -- 'tests/invariants' > "$T/b.out" 2>&1; then fail 'a scoped run was admitted under stacks=1'; fi
grep -q "repository $T/alpha" "$T/b.out" || fail 'the scoped refusal does not name the holder'
# stacks=2 admits it
printf 'stacks=2\n' > .vid/budget
sh checks/test.sh -- 'tests/invariants' > "$T/b.out" 2>&1 || fail 'stacks=2 refused the second stack'
[ -d "$T/run/vid-host/stack.2" ] && fail 'the second slot was not released'
rm -f .vid/budget
# release: alpha finishes, its slot goes
rm -f "$T/hold"; wait "$APID" || true
[ ! -d "$T/run/vid-host/stack.1" ] || fail 'the slot was not released when the run ended'
# cleanup is project-scoped: every down beta ran was in beta
grep ' down ' "$T/stub.log" | grep -v '^alpha ' | grep -qv '^beta ' && fail 'a down ran outside its own project'
[ "$(grep -c '^alpha .* down ' "$T/stub.log")" -eq 1 ] || fail "alpha's stack was brought down other than once, by itself"
# a stale slot: reported with its age, kept while a container of its project is left
mkdir -p "$T/run/vid-host/stack.1"; printf '99999999\n/elsewhere/gone\ngone\n%s\n' "$(( $(date +%s) - 7200 ))" > "$T/run/vid-host/stack.1/holder"
if VID_DOCKER="$T/docker.sh" DOCKER_LEFT=c0ffee sh checks/test.sh > "$T/b.out" 2>&1; then fail 'a run was admitted past a stale slot whose container is left'; fi
grep -q 'stack.1: STALE — pid 99999999 is gone (repository /elsewhere/gone' "$T/b.out" || fail 'the stale slot is not reported'
grep -qE '720[0-9] s old' "$T/b.out" || fail 'the stale slot is reported without its age'
grep -q 'Kept: 1 container(s) of compose project gone are left' "$T/b.out" || fail 'the kept stale slot does not say why'
grep -qx 'ps -a -q --filter label=com.docker.compose.project=gone' "$T/docker.log" || fail 'the container check did not ask for the holder project'"'"'s label'
[ -d "$T/run/vid-host/stack.1" ] || fail 'the script removed a stale slot whose container is left'
if VID_DOCKER="$T/docker.sh" DOCKER_RC=1 sh checks/test.sh > "$T/b.out" 2>&1; then fail 'a run was admitted past a stale slot while Docker does not answer'; fi
grep -q 'Kept: Docker does not answer' "$T/b.out" && [ -d "$T/run/vid-host/stack.1" ] || fail 'a stale slot was not kept while Docker does not answer'
[ ! -d .vid/ledger.lock ] || fail 'the refused run kept the repository lock'
# v0.9.7.0.8 (T2.1): a request queued behind the stale slot says why
VID_REQUEST_QUEUE=4 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'behind a stale slot' -- tests/x > "$T/b.out" 2>&1 || fail 'the request was refused'
grep -qx 'queue: 0 slot(s) held live and 1 stale on this host, 0 request(s) queued before this one' "$T/b.out" || fail 'the queue line does not split live and stale slots'
TK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/b.out")
i=0; while [ ! -s ".vid/requests/$TK/holders" ] && [ $i -lt 20 ]; do sleep 1; i=$((i + 1)); done
RC=0; VID_WAIT_MAX=1 sh checks/test.sh wait "$TK" > "$T/b.out" 2>&1 || RC=$?
[ "$RC" -eq 75 ] && sed -n 1p "$T/b.out" | grep -qE '^queued [0-9]+s of estimate' || fail 'wait did not report the request queued'
grep -q 'stack.1: STALE — pid 99999999 is gone (repository /elsewhere/gone' "$T/b.out" || fail 'wait does not print the holders while queued'
i=0; while [ "$(cat ".vid/requests/$TK/state")" = queued ] && [ $i -lt 20 ]; do sleep 1; i=$((i + 1)); done
[ "$(cat ".vid/requests/$TK/state")" = failed-to-start ] || fail 'the request past its queue bound did not end failed-to-start'
# v0.9.7.0.8 (T2.2): no container left and Docker answering — the stale slot is reclaimed once, the run proceeds
[ -d "$T/run/vid-host/stack.1" ] || fail 'the stale slot was gone before the reclaim'
VID_DOCKER="$T/docker.sh" sh checks/test.sh > "$T/b.out" 2>&1 || fail 'the run did not proceed past a reclaimable stale slot'
grep -q 'reclaimed stack.1' "$T/b.out" || fail 'the run did not say it reclaimed the slot'
[ "$(grep -c '^slot-reclaimed ' .vid/metrics-events)" -eq 1 ] || fail 'the stale slot was not reclaimed exactly once'
grep -qE '^slot-reclaimed slot=1 project=gone holder-pid=99999999 age=72[0-9][0-9] at=' .vid/metrics-events || fail 'the slot-reclaimed event does not carry its fields'
grep -q 'ViD test: report' "$T/b.out" || fail 'the run past the reclaim wrote no report'
[ -z "$(ls "$T/run/vid-host")" ] || fail 'a slot or a reclaimed folder outlived the run'
# v0.9.6, gated: the second slot needs the proof
rm -rf "$T/run/vid-host"; cp "$CHECKS/plan.sh" checks/
printf 'run: active\nsession: S\nplan: required\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S records=2 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
touch "$T/hold"
( STUB_HOLD="$T/hold" VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- 'tests/a' > "$T/g.out" 2>&1 ) & GP=$!
i=0; while [ ! -d "$T/run/vid-host/stack.1" ] && [ $i -lt 20 ]; do sleep 1; i=$((i + 1)); done
[ -d "$T/run/vid-host/stack.1" ] || fail 'the gated run took no slot'
[ ! -d .vid/ledger.lock ] || fail 'a gated run took the lock'
[ "$(ls .vid/runs | grep -c .)" -eq 1 ] || fail 'the gated run has no run folder'
printf 'stacks=2\n' > .vid/budget
if VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- 'tests/b' > "$T/b.out" 2>&1; then fail 'stacks=2 without testenv=proved admitted a second gated stack'; fi
grep -q 'allows 1 test stack' "$T/b.out" || fail 'the unproved refusal does not state one slot'
printf 'stacks=2\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- 'tests/c' > "$T/b.out" 2>&1 || fail 'a proved stacks=2 refused a second gated stack in the same folder'
grep -q 'project=vid-s2-beta$' "$STUB_LOG" || fail 'the second gated run did not run on slot 2'
rm -f "$T/hold"; wait "$GP" || true
[ -z "$(ls "$T/run/vid-host")" ] && [ -z "$(ls .vid/runs)" ] || fail 'a gated slot or run folder outlived its run'
exit 0
