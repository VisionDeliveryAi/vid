#!/bin/sh
# Purpose: selftest case — the run record's one writer on the ticket side (0.26.10.28.4, 9.3 R2, M2), lib.sh's rs_edit. Ten writers at once, each a
# moment inside its change, each get their line in, and none is lost. A change that fails, or prints nothing, writes nothing. A landing rolled back after
# another writer's update keeps that update: land.sh restores its plan block alone, through the same writer, never the whole record. The ticket side's
# writers of RUN-STATE.md go through it (round, queue, close, end, land). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "rs-writer: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
HERE=$CHECKS; . "$CHECKS/lib.sh"; mkdir -p "$T/p/.vid"; cd "$T/p"
printf '# RUN-STATE\n\nrun: active\nstage: 1\n\n## The plan\n\n```vid-plan\nstep S1 | name: one | modules: a | builds-on: - | rows: ROW-001\n```\n' > .vid/RUN-STATE.md
# ten at once
add() { cat; sleep 1; echo "line $1"; }; Q=''
for i in 1 2 3 4 5 6 7 8 9 10; do ( HERE=$CHECKS; . "$CHECKS/lib.sh"; rs_edit add "$i" ) & Q="$Q $!"; done; for q in $Q; do wait "$q" || fail 'a writer was refused'; done
for i in 1 2 3 4 5 6 7 8 9 10; do grep -qx "line $i" .vid/RUN-STATE.md || fail "line $i was lost"; done; [ ! -e .vid/run-state.lock ] || fail 'the lock was left'
grep -qx 'run: active' .vid/RUN-STATE.md && grep -q '^step S1 ' .vid/RUN-STATE.md || fail 'the record lost its own lines'
# a failed change, or an empty one, writes nothing
cp .vid/RUN-STATE.md "$T/before"; RC=0; rs_edit false || RC=$?; [ "$RC" = 1 ] && cmp -s .vid/RUN-STATE.md "$T/before" || fail 'a failed change wrote'
nothing() { cat > /dev/null; }; RC=0; rs_edit nothing || RC=$?; [ "$RC" = 1 ] && cmp -s .vid/RUN-STATE.md "$T/before" || fail 'an empty change wrote'
# the landing's roll-back, with land.sh's own text: its plan block alone
eval "$(sed -n "/^PCX='/p" "$CHECKS/land.sh")"; [ -n "${PCX:-}" ] || fail "land.sh has no PCX"
printf '\n## Notes\n\n```vid-plan\nstep S9 | name: old | modules: z | builds-on: - | rows: ROW-009\n```\n' >> .vid/RUN-STATE.md   # a prose fence, no plan
eval "$(sed -n "/^  awk '\/^## \/ { t = /p" "$CHECKS/land.sh" | sed 's/^  //; s/ || exit 1$//; s|\$T/bk-planblk|$T/bk-planblk|')"
printf 'step S1 | name: one | modules: a | builds-on: - | rows: ROW-001 ROW-021\n' > "$T/newplan"; rs_edit awk -v P="$T/newplan" "$PCX" || fail 'the plan change failed'
grep -q 'ROW-021' .vid/RUN-STATE.md || fail 'the plan change did not land'
rs_edit sed 's/^run:.*/run: stopped owner asked to pause/' || fail "another writer's update failed"
rs_edit awk -v P="$T/bk-planblk" "$PCX" || fail 'the roll-back failed'
! grep -q 'ROW-021' .vid/RUN-STATE.md && grep -qx 'run: stopped owner asked to pause' .vid/RUN-STATE.md && grep -q '^step S9 ' .vid/RUN-STATE.md && grep -q '^step S1 ' .vid/RUN-STATE.md || fail "the roll-back lost another writer's update, or kept the landing's: $(grep -E '^run:|ROW-021' .vid/RUN-STATE.md | tr '\n' ' ')"
grep -qF 'for f in "$HAND" "$LOG" .vid/metrics-events; do put "$f" < "$T/bk-$(basename "$f")"' "$CHECKS/land.sh" && grep -qF 'rs_edit awk -v P="$T/bk-planblk" "$PCX"' "$CHECKS/land.sh" || fail 'land.sh still restores the whole record'
# the ticket side's writers go through rs_edit, none writes RUN-STATE.md itself; FB-2 C3: close.sh's writes are checked across it and
# its parts, its rs_edit in close-end.sh, the part that holds the stage close
CP=$(for f in "$CHECKS"/close-*.sh; do b=${f##*/}; printf '%s ' "${b%.sh}"; done)
for s in round queue close $CP end land; do ! grep -nE 'put (\.vid/RUN-STATE\.md|"\$RS")|> (\.vid/RUN-STATE\.md|"\$RS")( |$)' "$CHECKS/$s.sh" | grep -v '^[0-9]*: *#' > "$T/out" || fail "$s.sh writes RUN-STATE.md itself"; done
for s in round queue close-end end land; do grep -q 'rs_edit ' "$CHECKS/$s.sh" || fail "$s.sh does not use rs_edit"; done
echo 'rs-writer: ok'
