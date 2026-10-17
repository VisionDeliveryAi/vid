#!/bin/sh
# Purpose: selftest case — a new trial in the same folder (v0.9.6.2 spec
# 3.1, R1; §6 case 4). `sh checks/run.sh new` writes a new id with parent=
# the old one, keeping the old file as .vid/run.parent; the next stage start
# names the new id. `run.sh label team=<t> series=<s>` sets both, and a
# label with a space or another key is refused and changes nothing.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "run-new: $*" >&2; cat .vid/metrics-events .vid/run >&2 2>/dev/null || true; exit 1; }
mkdir -p "$T/p/checks"; cd "$T/p"; git init -q
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] || fail 'no checks/run.sh'; cp "$CHECKS/run.sh" checks/
sh checks/event.sh 'stage name=develop state=start session=S1 records=4'
OID=$(sed -n 's/^id=//p' .vid/run)
sleep 1
sh checks/run.sh new > /dev/null || fail 'run.sh new failed'
NID=$(sed -n 's/^id=//p' .vid/run)
[ -n "$NID" ] && [ "$NID" != "$OID" ] || fail 'no new id'
[ "$(sed -n 's/^parent=//p' .vid/run)" = "$OID" ] || fail 'parent= is not the old id'
[ "$(sed -n 's/^id=//p' .vid/run.parent)" = "$OID" ] || fail 'the old file was not kept'
sh checks/event.sh 'stage name=develop state=start session=S2 records=4'
tail -n 1 .vid/metrics-events | grep -q " run=$NID at=" || fail 'the next start does not name the new id'
sh checks/run.sh label team=north series=s-3 > /dev/null || fail 'the label was refused'
grep -qx 'team=north' .vid/run && grep -qx 'series=s-3' .vid/run || fail 'the label was not written'
[ "$(sed -n 's/^id=//p' .vid/run)" = "$NID" ] || fail 'the label changed the id'
cp .vid/run "$T/r"
if sh checks/run.sh label 'team=two words' 2>/dev/null; then fail 'a label with a space was accepted'; fi
if sh checks/run.sh label owner=x 2>/dev/null; then fail 'another key was accepted'; fi
cmp -s .vid/run "$T/r" || fail 'a refused label changed .vid/run'
exit 0
