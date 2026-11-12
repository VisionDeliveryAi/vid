#!/bin/sh
# Purpose: selftest case — develop's publish lock really held (0.26.10.28.3,
# R6, M16). Inside a develop run under two proved slots, with a toy results
# reader that holds while a file stands (it runs inside the lock, after the
# report is placed) and a `ps` on the PATH that records each call and holds
# a call on one watched pid while that call's hold file stands: (1) two
# publishers at once — the first holds the lock, its own pid and start time
# in the lock's `pid`; the second waits and publishes after it, its event
# second and the commit-named copy its receipt; (2) a dead holder's lock (a
# reaped pid) is reclaimed, and so is a folder with no `pid` older than
# 30 s; (3) two reclaimers and a new holder in a controlled race: both judge
# the same dead holder (a live pid whose start time is another's), the first
# takes the reclaim folder, judges again, removes the lock and takes it; the
# second, released after, judges again under the reclaim folder, finds the
# new holder live and leaves its lock, then publishes after it; (4) a TERM
# while a publisher holds the reclaim folder leaves no reclaim folder, and
# the dead lock it had not yet removed stands; (5) a TERM while a publisher
# holds the lock: cleanup removes it, the teardown goes on and the run
# folder goes. No lock or reclaim folder is left after a run that ends.
# Env: CHECKS.
set -eu
T=$(mktemp -d)
DP=''   # the live stand-in holder this case started, while it runs
trap 'set +e; [ -z "$DP" ] || kill "$DP" 2>/dev/null; rm -f "$T"/hold* "$T"/ps/*.hold; sleep 1; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "publish-lock: $*" >&2; for f in "$T"/out.*; do [ -f "$f" ] && { echo "== $f"; cat "$f"; }; done >&2; ls -la .vid/ledger-results >&2 2>/dev/null; exit 1; }
REALPS=$(command -v ps)
mkdir -p "$T/bin" "$T/ps"
cat > "$T/bin/ps" <<'PS'
#!/bin/sh
# the case's ps: records each call as "<RUNNAME> <arguments>"; a call naming the watched pid $PSW holds while its hold file stands
printf '%s %s\n' "${RUNNAME:--}" "$*" >> "$PSD/log"
if [ -n "${PSW:-}" ] && [ -n "${RUNNAME:-}" ]; then
  case " $* " in *" -p $PSW "*)
    n=$(( $(cat "$PSD/n.$RUNNAME" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$PSD/n.$RUNNAME"
    : > "$PSD/$RUNNAME.$n.in"
    while [ -f "$PSD/$RUNNAME.$n.hold" ]; do sleep 0.2; done ;;
  esac
fi
exec "$REALPS" "$@"
PS
chmod +x "$T/bin/ps"
export PATH="$T/bin:$PATH" PSD="$T/ps" REALPS
export VID_REQUEST=selftest-direct   # the runner's own test calls it directly, as the test manager does
L=.vid/ledger-results/.publish.lock; RC=.vid/ledger-results/.publish.reclaim
toy() { # $1=the repository: a gated toy with a holding results reader and two proved slots
  gated_repo "$1"
  mkdir -p checks/extractors
  cat > checks/extractors/results.sh <<'RS'
#!/bin/sh
# Purpose: toy results reader; while $RS_HOLD stands it holds, after touching $RS_ENTER
if [ -n "${RS_HOLD:-}" ]; then [ -z "${RS_ENTER:-}" ] || : > "$RS_ENTER"; while [ -f "$RS_HOLD" ]; do sleep 0.2; done; fi
sed -n 's/.*case name="\([^"]*\)" status="\([^"]*\)".*/case \1 \2 0.1/p' "$1"
RS
  g add -A && g commit -qm 'a reader'
  gate_on
  printf 'stacks=2\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
  mkdir -p .vid/ledger-results
  SHA=$(git rev-parse --short=12 HEAD)
}
# reps: the ledger-run events' report= values, in order
reps() { sed -n 's/^ledger-run .* report=\([^ ]*\) .*/\1/p' .vid/metrics-events; }
pidof_lock() { cut -d' ' -f1 "$L/pid" 2>/dev/null || true; }
clean_end() { # $1=label: no lock, no reclaim folder, no run folder
  [ ! -e "$L" ] || fail "$1: the publish lock outlived the runs"
  [ ! -e "$RC" ] || fail "$1: a reclaim folder outlived the runs"
  _i=0; while [ "$(nruns)" -ne 0 ] && [ "$_i" -lt 20 ]; do sleep 1; _i=$((_i + 1)); done
  [ "$(nruns)" -eq 0 ] || fail "$1: run folders outlived their runs"
}
start() { # $1=name, then env assignments; the run's pid in P_<name>
  _n=$1; shift
  env RUNNAME="$_n" "$@" sh checks/test.sh --role close > "$T/out.$_n" 2>&1 &
  eval "P_$_n=\$!"
}

# 1. two publishers at once
toy "$T/r1"
: > "$T/hold.a"
start a RS_HOLD="$T/hold.a" RS_ENTER="$T/in.a"
waitfor "$T/in.a" 60 || fail '1: the first publisher never reached its report reader'
[ "$(pidof_lock)" = "$P_a" ] || fail "1: the lock is not held by the first publisher while it publishes (pid: $(cat "$L/pid" 2>/dev/null))"
[ "$(cat "$L/pid")" = "$P_a $($REALPS -o lstart= -p "$P_a" | sed 's/^ *//; s/ *$//')" ] || fail "1: the lock's pid is not the holder's pid and start time: $(cat "$L/pid")"
start b STUB_ENTER="$T/in.b"
waitfor "$T/in.b" 60 || fail '1: the second publisher did not start'
_i=0; while ! grep -q "^b -o lstart= -p $P_a\$" "$PSD/log" && [ "$_i" -lt 30 ]; do sleep 1; _i=$((_i + 1)); done
grep -q "^b -o lstart= -p $P_a\$" "$PSD/log" || fail '1: the second publisher never judged the holder'
sleep 2
[ "$(pidof_lock)" = "$P_a" ] || fail '1: the lock changed hands while its holder published'
reps | grep -q . && fail "1: an event was written while the first publisher held the lock: $(reps)"
rm -f "$T/hold.a"
wait "$P_a" || fail '1: the first publisher failed'; wait "$P_b" || fail '1: the second publisher failed'
[ "$(reps | grep -c .)" -eq 2 ] || fail "1: not two events: $(reps)"
RA=$(reps | sed -n 1p); RB=$(reps | sed -n 2p)
[ "$RA" != "$RB" ] && [ -f ".vid/ledger-results/$RA" ] && [ -f ".vid/ledger-results/$RB" ] || fail '1: the two receipts are not both kept'
grep -q 'ViD test: report ' "$T/out.a" && grep -q 'ViD test: report ' "$T/out.b" || fail '1: a publisher did not publish'
cmp -s ".vid/ledger-results/$SHA.full.xml" ".vid/ledger-results/$RB" || fail '1: the commit-named copy is not the newest event'"'"'s receipt'
# the first event is the first publisher's: its out names its receipt
grep -q "report .*/$RA " "$T/out.a" || fail "1: the first event ($RA) is not the first publisher's"
clean_end 1

# 2. a dead holder (a reaped pid), then a folder with no pid older than 30 s
toy "$T/r2"
sleep 0 & D=$!; wait "$D" || true
mkdir "$L"; printf '%s Thu Jan  1 00:00:00 1970\n' "$D" > "$L/pid"
start c
wait "$P_c" || fail '2: the publisher failed with a dead holder'
grep -q 'ViD test: report ' "$T/out.c" || fail '2: the dead holder'"'"'s lock was not reclaimed'
reps | grep -q '\.full\.xml$' || fail '2: no event names the receipt'
clean_end '2 (dead pid)'
mkdir "$L"; touch -t 202601010000 "$L"
start d
wait "$P_d" || fail '2: the publisher failed with an old folder holding no pid'
[ "$(reps | grep -c '\.full\.xml$')" -eq 2 ] || fail '2: the old folder with no pid was not reclaimed'
clean_end '2 (no pid)'

# 3. two reclaimers and a new holder, in a controlled race
toy "$T/r3"
sleep 600 & D=$!; DP=$D
mkdir "$L"; printf '%s Thu Jan  1 00:00:00 1970\n' "$D" > "$L/pid"   # a live pid whose start time is another's: dead
: > "$PSD/e.1.hold"; : > "$PSD/e.2.hold"; : > "$PSD/f.1.hold"; : > "$T/hold.e"
start e PSW="$D" RS_HOLD="$T/hold.e" RS_ENTER="$T/in.e"
start f PSW="$D"
waitfor "$PSD/e.1.in" 60 && waitfor "$PSD/f.1.in" 60 || fail '3: the two publishers did not both judge the dead holder'
rm -f "$PSD/e.1.hold"
waitfor "$PSD/e.2.in" 30 || fail '3: the first reclaimer did not judge again'
[ -d "$RC" ] || fail '3: the first reclaimer judges again without the reclaim folder'
rm -f "$PSD/e.2.hold"
waitfor "$T/in.e" 30 || fail '3: the first reclaimer did not take the lock'
[ "$(pidof_lock)" = "$P_e" ] || fail "3: the lock is not the new holder's: $(cat "$L/pid" 2>/dev/null)"
[ ! -e "$RC" ] || fail '3: the reclaim folder stands after the first reclaim'
E0=$(cat "$L/pid")
rm -f "$PSD/f.1.hold"
_i=0; while ! grep -q "^f -o lstart= -p $P_e\$" "$PSD/log" && [ "$_i" -lt 30 ]; do sleep 1; _i=$((_i + 1)); done
grep -q "^f -o lstart= -p $P_e\$" "$PSD/log" || fail '3: the second reclaimer never judged the new holder'
sleep 2
[ "$(cat "$L/pid" 2>/dev/null)" = "$E0" ] || fail '3: the second reclaimer removed the new holder'"'"'s lock'
[ "$(cat "$PSD/n.f")" -eq 1 ] || fail '3: the second reclaimer judged the dead holder again after it was gone'
reps | grep -q . && fail '3: an event while the new holder held the lock'
rm -f "$T/hold.e"
wait "$P_e" || fail '3: the new holder failed'; wait "$P_f" || fail '3: the second reclaimer failed'
[ "$(reps | grep -c .)" -eq 2 ] || fail "3: not two events: $(reps)"
grep -q "report .*/$(reps | sed -n 1p) " "$T/out.e" || fail '3: the new holder did not publish first'
grep -q 'ViD test: report ' "$T/out.f" || fail '3: the second reclaimer did not publish after the new holder'
clean_end 3
kill "$D" 2>/dev/null || true; wait "$D" 2>/dev/null || true; DP=''

# 4. a TERM while a publisher holds the reclaim folder
toy "$T/r4"
sleep 600 & D=$!; DP=$D
mkdir "$L"; printf '%s Thu Jan  1 00:00:00 1970\n' "$D" > "$L/pid"; L0=$(cat "$L/pid")
: > "$PSD/g.2.hold"
start g PSW="$D"
waitfor "$PSD/g.2.in" 60 || fail '4: the publisher did not judge again under the reclaim folder'
[ -d "$RC" ] || fail '4: the reclaim folder is not held'
kill -TERM "$P_g"; sleep 1; rm -f "$PSD/g.2.hold"
_rc=0; wait "$P_g" || _rc=$?
[ "$_rc" -ne 0 ] || fail '4: the interrupted publisher exited 0'
[ ! -e "$RC" ] || fail '4: a TERM during a reclaim left the reclaim folder'
[ "$(cat "$L/pid" 2>/dev/null)" = "$L0" ] || fail '4: the dead lock was changed by an interrupted reclaim'
rm -rf "$L"; kill "$D" 2>/dev/null || true; wait "$D" 2>/dev/null || true; DP=''
clean_end 4

# 5. a TERM while a publisher holds the lock: cleanup removes it, the teardown goes on
toy "$T/r5"
: > "$T/hold.h"; : > "$STUB_LOG"
start h RS_HOLD="$T/hold.h" RS_ENTER="$T/in.h"
waitfor "$T/in.h" 60 || fail '5: the publisher never reached its report reader'
[ "$(pidof_lock)" = "$P_h" ] || fail '5: the lock is not held while the report is read'
kill -TERM "$P_h"; sleep 1; rm -f "$T/hold.h"
_rc=0; wait "$P_h" || _rc=$?
[ "$_rc" -eq 130 ] || fail "5: the interrupted run exited $_rc, not 130"
[ ! -e "$L" ] || fail '5: cleanup left the lock it held'
grep -q ' down ' "$STUB_LOG" || fail '5: no teardown after the lock was released'
clean_end 5
exit 0
