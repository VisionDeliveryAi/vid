#!/bin/sh
# Purpose: selftest case — the machine's test environments (v0.26.10.28.2, R1, X-1), counted across every agent's work folder in one slots folder
# (DEVAGENT_ENVIRONMENTS). With max-environments: 2, three runs started at the same instant from three work folders: two hold environments, the third
# waits, and starts once one ends. A run waiting past its silent-seconds is not read as lost, and a dead holder's slot is freed. With no max-environments:
# line the cap is 3; a word or 0 is refused. A live staging stand-in counts: with it and one run up, the next run waits, a staging run's chunk (--against)
# does not, and a staging redeploy goes through on that staging's own slot. A run gone with no result whose supervisor file holds a fork failure is
# reported lost to the host's process limit; one with none names no cause. A dead holder's lock cleared by one waiter at a time, eight takes at
# once never past the cap nor refused; a replacement counted with its predecessor; an instance its live file names counted with no member alive; a failed
# stop:'s kept environment holding its slot until stop-failed goes. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
command -v nc > /dev/null 2>&1 || { echo 'devagent-env-cap: no nc, skipped' >&2; exit 0; }
R=$CHECKS/../devagent/test-manager/run.sh; DP=$CHECKS/../devagent/deployer/deploy.sh
T=$(mktemp -d)
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-env-cap: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
DEVAGENT_ENVIRONMENTS=$T/envs; export DEVAGENT_ENVIRONMENTS
sp_project; cd "$T"
Z=''; down() { for p in $Z; do kill "$p" 2>/dev/null || true; done; rm -f "$T"/hold*; a=$(sed 's/-[0-9]*$//' "$T/w0/staging/live" 2>/dev/null) && sh "$DP" stop --setup "$T/w0/dev-setup.txt" --ask "$a" > /dev/null 2>&1 || true
  for d in "$T"/w*/runs/*/; do [ -f "$d/exit" ] || sh "$R" stop "${d%/}" > /dev/null 2>&1 || true; done; }
trap 'down; sleep 1; rm -rf "$T"' EXIT
# four cases, each held while its file stands
for i in 1 2 3 4; do printf 'while [ -f "$SP_T/hold%s" ]; do sleep 1; done\nexit 0\n' "$i" > "$T/dev/tests/cases/ROW-01$i-hold.sh"; done
( cd "$T/dev" && git add -A && sp_git commit -qm 'held cases' && git push -q origin main ); C=$(git -C "$T/dev" rev-parse HEAD); H=$(printf %.12s "$C")
rec() { mkdir -p "$T/$1"; sed -e 's/^case-limit: .*/case-limit: 120/' "$T/work/dev-setup.txt" > "$T/$1/dev-setup.txt"; [ -z "${2:-}" ] || printf '%s\n' "$2" >> "$T/$1/dev-setup.txt"; }
for w in w1 w2 w3; do rec "$w" 'max-environments: 2'; done
up() { grep -l '^== alpha' "$T"/w[123]/runs/*/log 2>/dev/null | grep -c . || true; }
waiting() { grep -l '^waiting for a test environment: 2 are up on this machine' "$T"/w[123]/runs/*/log 2>/dev/null | grep -c . || true; }
ends() { i=0; until [ -f "$1/exit" ] || [ "$i" -ge 60 ]; do sleep 1; i=$((i + 1)); done; [ "$(cat "$1/exit" 2>/dev/null)" = 0 ]; }
# three at the same instant, from three work folders
touch "$T/hold1" "$T/hold2" "$T/hold3"
for i in 1 2 3; do sh "$R" start --setup "$T/w$i/dev-setup.txt" --ask "pr-$i-$H" --commit "$C" --select "ROW-01$i" --engines alpha --no-product > "$T/start$i" 2>&1 & done; wait
i=0; until [ "$(up)" = 2 ] && [ "$(waiting)" = 1 ] || [ "$i" -ge 40 ]; do sleep 1; i=$((i + 1)); done
[ "$(up)" = 2 ] || fail "with max-environments: 2, $(up) runs hold an environment"; [ "$(waiting)" = 1 ] || fail "with max-environments: 2, $(waiting) runs wait"
sleep 3; [ "$(up)" = 2 ] || fail "a third run came up past the cap: $(up)"
WD=$(dirname "$(grep -l '^waiting for a test environment' "$T"/w[123]/runs/*/log)"); [ ! -f "$WD/exit" ] && kill -0 "$(cat "$WD/pid")" 2>/dev/null || fail 'the waiting run is gone'
# the waiting one starts once one ends: one of the two up released
U=$(dirname "$(grep -l '^== alpha' "$T"/w[123]/runs/*/log | head -n 1)"); k=$(sed -n 's|.*/w\([123]\)/runs/.*|\1|p' <<X
$U
X
); rm -f "$T/hold$k"; ends "$U" || fail "the released run did not end well: $(cat "$U/result" 2>/dev/null)"
i=0; until grep -q '^== alpha' "$WD/log" || [ "$i" -ge 30 ]; do sleep 1; i=$((i + 1)); done; grep -q '^== alpha' "$WD/log" || fail 'the waiting run did not start once one ended'
rm -f "$T"/hold*; for d in "$T"/w[123]/runs/*/; do ends "${d%/}" || fail "a run did not end well: $(cat "$d/result" 2>/dev/null)"; done
# a run waiting past its silent-seconds is not lost (w3's record says 2); a dead holder's slot is freed
holder() { mkdir -p "$1"; sleep 300 & p=$!; Z="$Z $p"; echo "$p" > "$1/pid"; sh "$R" stamp "$p" > "$1/lstart"; }
printf 'silent-seconds: 2\n' >> "$T/w3/dev-setup.txt"; holder "$T/fake/a"; holder "$T/fake/b"; sh "$R" slot take "$T/w1/dev-setup.txt" fa run "$T/fake/a" && sh "$R" slot take "$T/w1/dev-setup.txt" fb run "$T/fake/b" || fail 'two live holders could not take two slots'
D=$(sh "$R" start --setup "$T/w3/dev-setup.txt" --ask "pr-4-$H" --commit "$C" --select ROW-014 --engines alpha --no-product)
sleep 6; grep -q '^waiting for a test environment' "$D/log" && [ ! -f "$D/exit" ] && kill -0 "$(cat "$D/pid")" 2>/dev/null || fail "a run waiting past its silent-seconds was stopped: $(cat "$D/result" 2>/dev/null)"
kill "$(cat "$T/fake/a/pid")"; ends "$D" || fail "a holder's death did not free its slot: $(cat "$D/result" 2>/dev/null)"
# the default is 3; a word or 0 is refused
rec w5; holder "$T/fake/c"; holder "$T/fake/d"; holder "$T/fake/a"; rm -rf "$DEVAGENT_ENVIRONMENTS"
for x in a b c; do sh "$R" slot take "$T/w5/dev-setup.txt" "f$x" run "$T/fake/$x" || fail "with no max-environments: line, slot $x of 3 was refused"; done
RC=0; sh "$R" slot take "$T/w5/dev-setup.txt" fd run "$T/fake/d" || RC=$?; [ "$RC" = 1 ] || fail "with no max-environments: line, a fourth slot: exit $RC"
for v in two 0; do rec "w6$v" "max-environments: $v"; RC=0; sh "$R" slot take "$T/w6$v/dev-setup.txt" fx run "$T/fake/d" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'whole number' "$T/out" || fail "max-environments: $v was not refused"
  RC=0; sh "$R" run --setup "$T/w6$v/dev-setup.txt" --ask "pr-5-$H" --commit "$C" --select ROW-001 --engines alpha > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'whole number' "$T/out" || fail "a run under max-environments: $v was not refused"; done
# a lock whose holder died is cleared by one waiter at a time: eight takes at once under max-environments: 1, no live slot, five times over, each
# with a dead holder's lock: one taken, seven none free, none refused or past the cap
rec w7 'max-environments: 1'; sh -c 'exit 0' & dp=$!; wait "$dp" || true
for t in 1 2 3 4 5; do rm -rf "$DEVAGENT_ENVIRONMENTS"; mkdir -p "$DEVAGENT_ENVIRONMENTS/.lock"; echo "$dp" > "$DEVAGENT_ENVIRONMENTS/.lock/pid"; echo 'a start long gone' > "$DEVAGENT_ENVIRONMENTS/.lock/at"
  for x in 1 2 3 4 5 6 7 8; do holder "$T/fake/r$t$x"; done; Q=''
  for x in 1 2 3 4 5 6 7 8; do ( rc=0; sh "$R" slot take "$T/w7/dev-setup.txt" "r$x" run "$T/fake/r$t$x" > /dev/null 2>&1 || rc=$?; echo "$rc" > "$T/rc$t$x" ) & Q="$Q $!"; done; for q in $Q; do wait "$q" || true; done
  [ "$(cat "$T"/rc$t? | grep -cx 0)" = 1 ] && [ "$(cat "$T"/rc$t? | grep -cx 1)" = 7 ] || fail "round $t of eight at once under a dead lock: $(cat "$T"/rc$t? | tr '\n' ' ')"
  [ "$(ls "$DEVAGENT_ENVIRONMENTS" | grep -c .)" = 1 ] || fail "round $t: $(ls "$DEVAGENT_ENVIRONMENTS" | grep -c .) slots"; done
# a replacement counts its predecessor until it is down; an instance named by its target's live file counts with no member alive
mk() { mkdir -p "$T/inst/$1/checkout"; }; mk staging/old; mk staging/new; echo old > "$T/inst/staging/live"; rm -rf "$DEVAGENT_ENVIRONMENTS"
sh "$R" slot take "$T/w7/dev-setup.txt" dp-x.staging instance "$T/inst/staging/new" "$T/inst/staging/old" || fail 'the replacement could not take its slot'
RC=0; sh "$R" slot take "$T/w7/dev-setup.txt" other run "$T/fake/c" || RC=$?; [ "$RC" = 1 ] || fail "a replacement killed before its predecessor went down freed the slot: exit $RC"
rm -rf "$T/inst/staging/old/checkout"; RC=0; sh "$R" slot take "$T/w7/dev-setup.txt" other run "$T/fake/c" || RC=$?; [ "$RC" = 0 ] || fail "both down, the slot stayed held: exit $RC"
rm -rf "$DEVAGENT_ENVIRONMENTS"; echo new > "$T/inst/staging/live"; sh "$R" slot take "$T/w7/dev-setup.txt" dp-x.staging instance "$T/inst/staging/new" || fail 'the live instance could not take its slot'
RC=0; sh "$R" slot take "$T/w7/dev-setup.txt" other run "$T/fake/c" || RC=$?; [ "$RC" = 1 ] || fail "an instance its live file names, with no member alive, was read as down: exit $RC"
# an instance whose deploy died before its live file, its product answering on its port, counts; the port shut, it is down
rm -rf "$DEVAGENT_ENVIRONMENTS"; echo old > "$T/inst/staging/live"; nc -lk 127.0.0.1 47690 > /dev/null 2>&1 & np=$!; Z="$Z $np"; echo 47690 > "$T/inst/staging/new/port"; sleep 1
sh "$R" slot take "$T/w7/dev-setup.txt" dp-x.staging instance "$T/inst/staging/new" || fail 'the instance could not take its slot'
RC=0; sh "$R" slot take "$T/w7/dev-setup.txt" other run "$T/fake/c" || RC=$?; [ "$RC" = 1 ] || fail "an instance whose product answers was read as down: exit $RC"
kill "$np" 2>/dev/null || true; wait "$np" 2>/dev/null || true; RC=0; sh "$R" slot take "$T/w7/dev-setup.txt" other run "$T/fake/c" || RC=$?; [ "$RC" = 0 ] || fail "an instance with nothing up held its slot: exit $RC"
# a lock whose holder's pid another process took is no holder's: a live pid with a stamp not its own is cleared
rm -rf "$DEVAGENT_ENVIRONMENTS"; mkdir -p "$DEVAGENT_ENVIRONMENTS/.lock"; echo "$(cat "$T/fake/c/pid")" > "$DEVAGENT_ENVIRONMENTS/.lock/pid"; echo 'another start' > "$DEVAGENT_ENVIRONMENTS/.lock/at"
RC=0; sh "$R" slot take "$T/w7/dev-setup.txt" reused run "$T/fake/c" || RC=$?; [ "$RC" = 0 ] || fail "a lock on a reused pid was not cleared: exit $RC"
for p in $Z; do kill "$p" 2>/dev/null || true; done; Z=''; rm -rf "$DEVAGENT_ENVIRONMENTS"
# a failed stop: keeps its environment, and its slot, until the setup pass removes stop-failed
rec w8 'max-environments: 1'; sed -i.b 's/^stop: .*/stop: exit 1/' "$T/w8/dev-setup.txt"
RC=0; sh "$R" run --setup "$T/w8/dev-setup.txt" --ask "pr-8-$H" --commit "$C" --select ROW-001 --engines alpha --no-product > "$T/out" 2>&1 || RC=$?; [ "$RC" = 3 ] && [ -f "$T/w8/stop-failed" ] || fail "a failed stop: exit $RC"
holder "$T/fake/e"; RC=0; sh "$R" slot take "$T/w8/dev-setup.txt" after-stop run "$T/fake/e" || RC=$?; [ "$RC" = 1 ] || fail "a kept environment's slot was freed: exit $RC"
rm -f "$T/w8/stop-failed"; RC=0; sh "$R" slot take "$T/w8/dev-setup.txt" after-stop run "$T/fake/e" || RC=$?; [ "$RC" = 0 ] || fail "stop-failed removed, the slot stayed held: exit $RC"
for p in $Z; do kill "$p" 2>/dev/null || true; done; Z=''; rm -rf "$DEVAGENT_ENVIRONMENTS"
# a live staging counts; --against does not; a redeploy keeps its own slot
mkdir -p "$T/w0"; cat > "$T/w0/dev-setup.txt" <<X
repo: $T/origin.git
engines: alpha beta
environments: 1
case-limit: 120
ready-seconds: 5
max-environments: 2
start: [ -z "\${PORT:-}" ] || { nc -lk 127.0.0.1 "\$PORT" > /dev/null 2>&1 & }
stop: :
run: sh tests/runner.sh
X
DP_PORT=47640; export DP_PORT
sh "$DP" deploy --setup "$T/w0/dev-setup.txt" --ask deploy-7 --commit "$C" > "$T/out" 2>&1 || fail 'the staging deploy failed'; ls "$DEVAGENT_ENVIRONMENTS" | grep -q '^dp-.*\.staging$' || fail 'the staging holds no slot'
touch "$T/hold1" "$T/hold2"; D1=$(sh "$R" start --setup "$T/w1/dev-setup.txt" --ask "pr-6-$H" --commit "$C" --select ROW-011 --engines alpha --no-product)
i=0; until grep -q '^== alpha' "$D1/log" 2>/dev/null || [ "$i" -ge 30 ]; do sleep 1; i=$((i + 1)); done; grep -q '^== alpha' "$D1/log" || fail 'with a staging up, the first run did not come up'
D2=$(sh "$R" start --setup "$T/w2/dev-setup.txt" --ask "pr-7-$H" --commit "$C" --select ROW-012 --engines alpha --no-product)
i=0; until grep -q '^waiting for a test environment' "$D2/log" 2>/dev/null || [ "$i" -ge 30 ]; do sleep 1; i=$((i + 1)); done; grep -q '^waiting for a test environment' "$D2/log" && ! grep -q '^== alpha' "$D2/log" || fail 'with a staging and a run up, the next run did not wait'
P=$(cat "$T/w0/staging/$(cat "$T/w0/staging/live")/port"); RC=0; sh "$R" run --setup "$T/w2/dev-setup.txt" --ask req-9-p1c1 --commit "$C" --against "http://127.0.0.1:$P" --select ROW-001 --engines alpha > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "a staging run's chunk waited for, or was refused, an environment: exit $RC"
RC=0; sh "$DP" deploy --setup "$T/w0/dev-setup.txt" --ask deploy-7 --commit "$C" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] && ! grep -q 'waiting' "$T/out" || fail "a staging redeploy at the cap did not go through on its own slot: exit $RC"
[ "$(ls "$DEVAGENT_ENVIRONMENTS" | grep -c '^dp-')" = 1 ] || fail 'the redeploy took a second slot'
grep -q '^waiting for a test environment' "$D2/log" && ! grep -q '^== alpha' "$D2/log" || fail 'the redeploy let the waiting run up'
a=$(sed 's/-[0-9]*$//' "$T/w0/staging/live"); sh "$DP" stop --setup "$T/w0/dev-setup.txt" --ask "$a" > /dev/null 2>&1 || fail 'the staging did not stop'
i=0; until grep -q '^== alpha' "$D2/log" || [ "$i" -ge 30 ]; do sleep 1; i=$((i + 1)); done; grep -q '^== alpha' "$D2/log" || fail 'the staging stopped and the waiting run did not start'
rm -f "$T"/hold*; ends "$D1" && ends "$D2" || fail 'a run under the staging did not end well'
# a run lost to the host's process limit, said; one with no fork failure names no cause
mkdir -p "$T/lost1" "$T/lost2"; sh -c 'exit 0' & p=$!; wait "$p" || true; for d in lost1 lost2; do echo "$p" > "$T/$d/pid"; : > "$T/$d/log"; done
printf 'run.sh: line 270: fork: retry: Resource temporarily unavailable\nrun.sh: line 270: fork: Resource temporarily unavailable\n' > "$T/lost1/supervisor"; printf 'nothing\n' > "$T/lost2/supervisor"
RC=0; sh "$R" wait "$T/lost1" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 3 ] && grep -qF "is gone, with no result: lost to the host's process limit (run.sh: line 270: fork: retry: Resource temporarily unavailable)" "$T/out" || fail "a run lost to a fork failure: exit $RC"
RC=0; sh "$R" wait "$T/lost2" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 3 ] && grep -qxF "stopped: the run at $T/lost2 is gone, with no result" "$T/out" || fail "a run lost with no fork failure: exit $RC"
echo 'devagent-env-cap: ok'
