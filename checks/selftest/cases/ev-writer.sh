#!/bin/sh
# Purpose: selftest case — one writer for events on the ticket side (0.26.10.28.4, 9.3 R1, M1). lib.sh's ev writes through the event.sh beside it, at the
# run's home, even from a folder below it; when event.sh fails, ev says so and writes nothing past it. land.sh's publish-approved and end.sh's run
# state=complete go through ev, and no ticket script appends to .vid/metrics-events itself. github.sh and job.sh call the event.sh beside themselves,
# job.sh keeping its fallback. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "ev-writer: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# through event.sh, at the run's home, from a folder below it
mkdir -p "$T/p/checks" "$T/p/sub" "$T/p/.vid"; cd "$T/p"; git init -q; cp "$CHECKS/event.sh" "$CHECKS/lib.sh" checks/; : > .vid/RUN-STATE.md
cd sub; ( HERE=$T/p/checks; . "$HERE/lib.sh"; ev 'round-error step=x count=1' ) 2> "$T/out" || fail 'ev failed'; cd ..
grep -q '^round-error step=x count=1 at=' .vid/metrics-events || fail "ev did not write at the run's home"; [ ! -e sub/.vid ] || fail 'ev wrote in the working folder, not the home'
# a failing event.sh: said, nothing written past it
mkdir -p "$T/f/checks" "$T/f/.vid"; cd "$T/f"; printf '#!/bin/sh\nexit 1\n' > checks/event.sh; cp "$CHECKS/lib.sh" checks/
( HERE=$T/f/checks; . "$HERE/lib.sh"; ev 'round-error step=y count=1' ) 2> "$T/out" || fail 'ev stopped its caller'
grep -q 'the event was not recorded, event.sh failed: round-error step=y count=1' "$T/out" || fail 'a failing event.sh was not said'; [ ! -s .vid/metrics-events ] || fail 'ev wrote past a failing event.sh'
# no ticket script appends to the events itself; land's and end's lines go through ev
for s in close decide end github grade land lib planner queue refresh results round walk writer; do ! grep -n 'metrics-events' "$CHECKS/$s.sh" | grep -v '^[0-9]*: *#' | grep -q '>>' || fail "$s.sh appends to .vid/metrics-events itself"; done
grep -qF 'ev "publish-approved words=\"$WORDS\""' "$CHECKS/land.sh" && grep -qF "ev 'run state=complete'" "$CHECKS/end.sh" || fail "land.sh's or end.sh's line does not go through ev"
# beside themselves: github.sh through lib.sh's ev; job.sh by its own path, its fallback kept
! grep -q 'sh checks/event.sh' "$CHECKS/github.sh" "$CHECKS/job.sh" || fail 'github.sh or job.sh still calls checks/event.sh from the working folder'
grep -qF 'ev() { sh "$(cd "$(dirname "$0")" && pwd)/event.sh" "$1" >/dev/null 2>&1 ||' "$CHECKS/job.sh" || fail "job.sh does not call the event.sh beside itself"
echo 'ev-writer: ok'
