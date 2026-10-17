#!/bin/sh
# Purpose: selftest case — every exit path runs the `down` of the pass in
# progress (v0.9.6 spec 3.10, R10; §7 case 11). Four shapes — a full run
# with a deployed selector, a full run without one, a scoped run, a scoped
# `--deployed` run — each inside and outside the gate. The normal end runs
# each pass's own `down`: the inline pass `--remove-orphans --volumes` when
# a deployed pass follows, `--remove-orphans` otherwise, the deployed pass
# `--profile deployed … --remove-orphans --volumes`. A TERM arriving during
# a pass runs exactly that pass's `down` once more, and nothing after; inside
# the gate every `down` happens with the slot still held, and the slot and
# the run folder are gone afterwards. Outside the gate the normal ends are
# byte-identical to 0.9.5's checks/test.sh (fixtures/test-0.9.5.sh): the
# same Compose calls, output, receipts and events — but for v0.9.7.0.1's
# added `role=-` on a roleless run's event and v0.9.7.0.2's `form=legacy`
# on every one (and inside the gate a scoped run names --role builder and
# calls it directly, with VID_REQUEST set). The EXIT trap shares the
# signal path's teardown (the trap calls it; a pass cannot end early
# otherwise). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "teardown-paths: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat "$STUB_LOG" >&2 2>/dev/null; exit 1; }
OLD="$CHECKS/selftest/fixtures/test-0.9.5.sh"
DFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-dep
  processes: [worker]
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  worker:
    image: toy:test
    profiles: [deployed]
  tests:
    image: runner
'
COMPOSEFILE=$DFILE; gated_repo "$T/d"
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  tests:
    image: runner
'
gated_repo "$T/n"
IN='down --remove-orphans'; INV='down --remove-orphans --volumes'; DEP='--profile deployed down --remove-orphans --volumes'
downs() { grep -E ' down ' "$STUB_LOG" | sed 's/.*|//' | awk '{ i = index($0, "--profile deployed down"); if (i) print substr($0, i); else print substr($0, index($0, " down ") + 1) }'; }
held() { grep '^lease-at-down=' "$STUB_LOG" | sort -u; }
# run <repo> <in|out> <expected downs, ;-separated> [kill pattern] -- <test.sh args>
run() {
  cd "$T/$1"; rm -f "$STUB_LOG"; rm -rf .vid/ledger-results .vid/metrics-events .vid/RUN-STATE.md
  [ "$2" = in ] && gate_on
  _rq=''; [ "$2" = in ] && _rq=selftest-direct   # v0.9.7.0.2: inside the gate a direct call, as the test manager makes
  _x=$3; _k=$4; shift 5
  if [ -n "$_k" ]; then STUB_KILL_ON=$_k VID_REQUEST=$_rq sh checks/test.sh "$@" > "$T/out" 2>&1 && fail "$1: the killed run exited 0"; else VID_REQUEST=$_rq sh checks/test.sh "$@" > "$T/out" 2>&1 || true; fi
  _got=$(downs | tr '\n' ';' | sed 's/;$//')
  [ "$_got" = "$_x" ] || fail "$* ($2, kill ${_k:-none}): downs [$_got], expected [$_x]"
  if [ "$2" = in ]; then
    [ "$(held)" = 'lease-at-down=held' ] || fail "$* (in): a down ran after the slot was released"
    [ -z "$(ls "$T/run/vid-host" 2>/dev/null)" ] || fail "$* (in): the slot outlived the run"
    [ "$(nruns)" -eq 0 ] || fail "$* (in): the run folder outlived the run"
  fi
  return 0
}
KI=' up --build --exit-code-from tests tests'; KD='--profile deployed up --exit-code-from'
for G in in out; do
  RB=''; [ "$G" = in ] && RB='--role builder'   # v0.9.7.0.1: a gated run names its role; the ungated runs stay roleless
  run d "$G" "$INV;$DEP" '' -- --role close
  run d "$G" "$INV" "$KI" -- --role close
  run d "$G" "$INV;$DEP" "$KD" -- --role close
  run n "$G" "$IN" '' -- --role close
  run n "$G" "$IN" "$KI" -- --role close
  run n "$G" "$IN" '' -- $RB -- 'tests/x'
  run n "$G" "$IN" "$KI" -- $RB -- 'tests/x'
  run d "$G" "$DEP" '' -- $RB --deployed -- 'tests/x'
  run d "$G" "$DEP" "$KD" -- $RB --deployed -- 'tests/x'
done
# outside the gate, normal ends are 0.9.5's, byte for byte
norm() { sed -E 's#\.vid/export\.[A-Za-z0-9]+#.vid/export.X#g; s/seconds=[0-9]+/seconds=S/; s/ at=[0-9TZ:-]+$//' "$1"; }
for shape in 'd|--role close' 'n|--role close' 'n|-- tests/x' 'd|--deployed -- tests/x'; do
  r=${shape%%|*}; a=${shape#*|}
  for v in old new; do
    cd "$T/$r"; rm -f "$STUB_LOG"; rm -rf .vid/ledger-results .vid/metrics-events .vid/RUN-STATE.md
    if [ "$v" = old ]; then S="$OLD"; else S=checks/test.sh; fi
    # shellcheck disable=SC2086
    sh "$S" $a > "$T/$v.out" 2>&1 || true
    norm "$STUB_LOG" > "$T/$v.log"; norm "$T/$v.out" > "$T/$v.o"; norm .vid/metrics-events > "$T/$v.ev"; ls .vid/ledger-results > "$T/$v.ls"
  done
  # v0.9.7.0.2 (3.4, R5): every plain call outside a run adds form=legacy to its event, last, and nothing else
  [ -s "$T/new.ev" ] && [ -z "$(grep -v ' form=legacy$' "$T/new.ev")" ] || fail "outside the gate, '$a' in $r: an event does not carry form=legacy"
  sed 's/ form=legacy$//' "$T/new.ev" > "$T/new.ev.x" && mv "$T/new.ev.x" "$T/new.ev"
  # v0.9.7.0.1 (3.2, R5): a roleless ungated event adds role=- and nothing else
  case "$a" in --role*) ;; *) grep -q ' role=-$' "$T/new.ev" || fail "outside the gate, '$a' in $r: the event does not carry role=-"
    sed 's/ role=-$//' "$T/new.ev" > "$T/new.ev.x" && mv "$T/new.ev.x" "$T/new.ev" ;; esac
  for f in log o ev ls; do cmp -s "$T/old.$f" "$T/new.$f" || { diff "$T/old.$f" "$T/new.$f" >&2 || true; fail "outside the gate, '$a' in $r differs from 0.9.5 ($f)"; }; done
done
exit 0
