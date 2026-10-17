#!/bin/sh
# Purpose: selftest case — a slot holder that can't be signalled is alive (v0.9.7.1, found in rehearsal R-6). A run
# started inside an agent's sandbox (a Codex builder's request) can't signal other processes: kill -0 says
# "Operation not permitted", which 0.9.7.0.8's reclaim read as gone. One toy repository, the compose stub, a
# docker stub answering no container. A slot is held by pid 1 (it exists; a user can't signal it) and has no
# container yet — as between a run taking its slot and starting its stack. Convicts unless a run with stacks=1
# is refused, the slot kept and not reported STALE, and no slot-reclaimed event written; and a slot whose pid is
# gone (No such process) is still reclaimed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/run"; export XDG_RUNTIME_DIR="$T/run"
printf '#!/bin/sh\ncase "$*" in *" up "*) case "${VID_TEST_CONTEXT:-}" in */ctx) R="${VID_TEST_CONTEXT%%/ctx}/results" ;; *) R=.vid/ledger-results ;; esac\n  printf "<report><case name=\\"tests/invariants/t.py::a[ROW-001]\\" status=\\"passed\\" time=\\"0.1\\"/></report>\\n" > "$R/pending.xml" ;; esac\nexit 0\n' > "$T/stub.sh"; chmod +x "$T/stub.sh"
printf '#!/bin/sh\nexit 0\n' > "$T/docker.sh"; chmod +x "$T/docker.sh"
export VID_COMPOSE="$T/stub.sh" VID_DOCKER="$T/docker.sh"
fail() { echo "slot-unsignalled: $*" >&2; cat "$T/b.out" >&2 2>/dev/null || true; exit 1; }
mkdir -p "$T/r/checks" "$T/r/.vid"; cd "$T/r"; git init -q; cp "$CHECKS/test.sh" checks/
printf 'x-vid-harness:\n  product: product\n  completed: [0, 1]\nservices:\n  product:\n    build: .\n' > docker-compose.test.yml
printf '.vid/\n' > .gitignore; git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
kill -0 1 2>/dev/null && exit 0   # run as root: pid 1 can be signalled, nothing to prove here
mkdir -p "$T/run/vid-host/stack.1"; printf '1\n/elsewhere/sandboxed\nsandboxed\n%s\n' "$(date +%s)" > "$T/run/vid-host/stack.1/holder"
if sh checks/test.sh > "$T/b.out" 2>&1; then fail 'a run was admitted past a live holder it cannot signal'; fi
[ -d "$T/run/vid-host/stack.1" ] || fail 'the slot of a live holder was reclaimed'
grep -q 'STALE' "$T/b.out" && fail 'a live holder it cannot signal was reported STALE'
grep -q 'slot-reclaimed' .vid/metrics-events 2>/dev/null && fail 'a slot-reclaimed event was written'
printf '99999999\n/elsewhere/gone\ngone\n%s\n' "$(date +%s)" > "$T/run/vid-host/stack.1/holder"
sh checks/test.sh > "$T/b.out" 2>&1 || fail 'a slot whose holder is gone was not reclaimed'
grep -q 'reclaimed stack.1' "$T/b.out" || fail 'the gone holder'"'"'s slot was not reclaimed'
exit 0
