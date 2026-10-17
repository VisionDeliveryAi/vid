#!/bin/sh
# Purpose: selftest case — a copied project gets a new run id (v0.9.6.2
# spec 3.1, R1; §6 case 3). A project with a run, copied whole to another
# folder and given a commit there: its next stage start writes a new id,
# with parent= the old id, parent-start= the old start=, copied-at= HEAD of
# the copy, path= the copy; the old file is kept as .vid/run.parent, and
# the stage line names the new id. The original keeps its own. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "run-id-copy: $*" >&2; cat .vid/metrics-events .vid/run .vid/run.parent >&2 2>/dev/null || true; exit 1; }
mkdir -p "$T/a/checks"; cd "$T/a"; git init -q
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
printf '.vid/\n' > .gitignore; g add -A; g commit -qm root
sh checks/event.sh 'stage name=init state=start session=S0 records=1'
[ -f .vid/run ] || fail 'no .vid/run in the original'
OID=$(sed -n 's/^id=//p' .vid/run); OST=$(sed -n 's/^start=//p' .vid/run)
cp .vid/run "$T/orig.run"
sleep 1
cp -R "$T/a" "$T/b"; cd "$T/b"
printf 'x\n' > x; g add x; g commit -qm 'work in the copy'
sh checks/event.sh 'stage name=develop state=start session=S1 records=4'
NID=$(sed -n 's/^id=//p' .vid/run)
[ -n "$NID" ] && [ "$NID" != "$OID" ] || fail 'the copy kept its parent'"'"'s id'
[ "$(sed -n 's/^parent=//p' .vid/run)" = "$OID" ] || fail 'parent= is not the old id'
[ "$(sed -n 's/^parent-start=//p' .vid/run)" = "$OST" ] || fail 'parent-start= is not the old start='
[ "$(sed -n 's/^copied-at=//p' .vid/run)" = "$(git rev-parse --short=12 HEAD)" ] || fail 'copied-at= is not HEAD of the copy'
[ "$(sed -n 's/^path=//p' .vid/run)" = "$(pwd -P)" ] || fail 'path= is not the copy'
cmp -s .vid/run.parent "$T/orig.run" || fail 'the old file was not kept as .vid/run.parent'
tail -n 1 .vid/metrics-events | grep -q " run=$NID at=" || fail 'the stage line does not name the new id'
cd "$T/a"; sh checks/event.sh 'stage name=develop state=start session=S9 records=4'
cmp -s .vid/run "$T/orig.run" || fail 'the original lost its id'
exit 0
