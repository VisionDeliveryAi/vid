#!/bin/sh
# Purpose: selftest case — M10's rule 2, counted (0.26.10.28.4, 9.3 R8): no line appends to .vid/metrics-events outside event.sh, but in the files named
# here: develop's own (brief, test, metrics), the shared ones that wait for event.sh to take a home (the commit hooks, plan, the court timing traps of
# census, coverage and inventory, decisions, job, progress, testenv, watchdog, and the plugin's hooks net, record and stop-failure), and the viewer's
# own snapshot. No ticket script, lib.sh among them, is one. The search finds a planted append. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "rule-events: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
OK=' checks/brief.sh checks/test.sh checks/metrics.sh checks/hooks/commit-msg checks/hooks/pre-commit checks/hooks/post-commit checks/plan.sh checks/census.sh checks/coverage.sh checks/inventory.sh checks/decisions.sh checks/job.sh checks/progress.sh checks/testenv.sh checks/watchdog.sh hooks/net.sh hooks/record.sh hooks/stop-failure.sh viewer/view.sh '
R=$CHECKS/..; ap() { grep -n '>>' "$1" | grep 'metrics-events' | grep -v '^[0-9]*: *#' || true; }
: > "$T/out"; for f in "$CHECKS"/*.sh "$CHECKS"/hooks/commit-msg "$CHECKS"/hooks/pre-commit "$CHECKS"/hooks/post-commit "$R"/hooks/*.sh "$R"/viewer/*.sh; do [ -f "$f" ] || continue
  r=checks/${f#"$CHECKS"/}; case $f in "$R"/hooks/*|"$R"/viewer/*) r=${f#"$R"/} ;; esac; [ "$r" != checks/event.sh ] || continue
  case $OK in *" $r "*) continue ;; esac; ap "$f" | sed "s|^|$r:|" >> "$T/out"; done
[ ! -s "$T/out" ] || fail 'an append to .vid/metrics-events outside event.sh and the named files:'
# FB-2 C3: close.sh's parts, by glob, with it
CP=$(for f in "$CHECKS"/close-*.sh; do b=${f##*/}; printf '%s ' "${b%.sh}"; done)
for s in close $CP decide end github grade land lib planner queue refresh results round walk writer; do case $OK in *" checks/$s.sh "*) fail "the ticket script $s.sh is named an exception" ;; esac; done
printf 'printf "x at=y\\n" >> .vid/metrics-events\n' > "$T/plant.sh"; [ -n "$(ap "$T/plant.sh")" ] || fail 'the search does not find a planted append'
echo 'rule-events: ok'
