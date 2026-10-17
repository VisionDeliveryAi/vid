#!/bin/sh
# Purpose: selftest case — what the project still runs (v0.9.6 spec 3.10,
# R10; §7 case 18). `testenv.sh leftovers` lists, each with its age: a
# container whose compose working directory is this repository, and one
# whose is a dead run's frozen copy; a run folder with no live holder; a
# linked worktree whose branch is merged into the home's branch (v0.9.8.1 R39: its commits beyond its base); a
# declared operation with no `done`. It does not list another folder's
# container, a live run's own container, an unmerged worktree, or any
# volume or image (it never asks for them). At completion under the gate
# each leftover is a strict gap, listed `leftover …`; with the gate off
# completion is unchanged. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "leftovers: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" "$CHECKS/metrics.sh" "$CHECKS/watchdog.sh" checks/
printf '#!/bin/sh\n# Purpose: stub coverage court\necho "REQs: 1 cited 1 gaps: 0 open VID-QUESTION markers: 0"\n' > checks/coverage.sh
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\n```\n' > INVENTORY.md
g add -A && g commit -qm 'the readers'
H=$(pwd -P)
g worktree add -q "$T/merged" -b merged-builder 2>/dev/null
( cd "$T/merged" && printf 'm\n' > app/merged.txt && g add app/merged.txt && g commit -qm 'merged work' ); g merge -q --ff-only merged-builder   # v0.9.8.1 (R39): merged means commits beyond its base, in main
g worktree add -q "$T/open" -b open-builder 2>/dev/null
( cd "$T/open" && printf 'x\n' > app/wip.txt && g add app/wip.txt && g commit -qm 'unmerged work' )
sleep 300 & LP=$!; trap 'kill "$LP" 2>/dev/null; rm -rf "$T"' EXIT
mkdir -p .vid/runs/dead .vid/runs/live
printf 'pid=99999999\nstart=%s\nproject=vid-s2-repo\n' "$(( $(date +%s) - 600 ))" > .vid/runs/dead/holder
printf 'pid=%s\nstart=%s\nproject=vid-s1-repo\n' "$LP" "$(date +%s)" > .vid/runs/live/holder
printf 'repo-dev-1\t%s\tUp 2 hours\t2 hours ago\nvid-s2-repo-product-1\t%s/.vid/runs/dead/ctx\tExited (0) 5 minutes ago\t6 minutes ago\nvid-s1-repo-product-1\t%s/.vid/runs/live/ctx\tUp 1 minute\t1 minute ago\nother-db-1\t/elsewhere/proj\tUp 3 days\t3 days ago\n' "$H" "$H" "$H" > "$T/psa"
sh checks/watchdog.sh declare devserver 3600 'kill -0 4242 # devserver' 4242 > /dev/null
sh checks/testenv.sh leftovers > "$T/out" 2>&1
for want in 'leftover container repo-dev-1 (Up 2 hours, created 2 hours ago' 'leftover container vid-s2-repo-product-1 (Exited (0) 5 minutes ago' 'leftover run-folder .vid/runs/dead (' "leftover worktree $(cd "$T/merged" && pwd -P) (branch merged-builder, merged into " 'leftover operation devserver (declared '; do
  grep -qF "$want" "$T/out" || fail "not listed: $want"
done
grep -q 'other-db-1' "$T/out" && fail "another folder's container was listed"
grep -q 'vid-s1-repo-product-1' "$T/out" && fail "a live run's container was listed"
grep -q 'runs/live' "$T/out" && fail 'a live run folder was listed'
grep -q 'open-builder' "$T/out" && fail 'an unmerged worktree was listed'
grep -qx 'leftovers n=5' "$T/out" || fail 'not five leftovers'
grep -qiE 'volume|image' "$T/docker.log" && fail 'leftovers asked Docker for volumes or images'
sh checks/metrics.sh completion > "$T/out" 2>&1
grep -q '^completion unmet=0 strict-gaps=5$' "$T/out" || fail 'under the gate the leftovers are not strict gaps'
[ "$(grep -c '^leftover ' "$T/out")" -eq 5 ] || fail 'completion does not list the leftovers'
sed '/^plan:/d' .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md
sh checks/metrics.sh completion > "$T/out" 2>&1
grep -q '^completion unmet=0 strict-gaps=0$' "$T/out" && ! grep -q '^leftover ' "$T/out" || fail 'with the gate off completion changed'
exit 0
