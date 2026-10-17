#!/bin/sh
# Purpose: selftest case — a stage event from a builder worktree (v0.9.6.2
# spec 3.1, R1; §6 case 5). The home holds RUN-STATE and a run id; a linked
# builder worktree names the home in .vid/home. An event written there
# through checks/event.sh — a stage start and another — lands in the home's
# .vid/metrics-events, the stage line naming the home's run id; the
# builder's own .vid/ holds no events and no run file, and no copy is
# detected (no .vid/run.parent, the id unchanged). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "run-id-builder: $*" >&2; cat "${HOMEP:-.}/.vid/metrics-events" >&2 2>/dev/null || true; exit 1; }
mkdir -p "$T/home/checks" "$T/home/.vid"; cd "$T/home"; git init -q
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
printf '.vid/\n' > .gitignore; g add -A; g commit -qm root
HOMEP=$(pwd -P)
printf 'run: active\nsession: S1\nplan: required\n' > .vid/RUN-STATE.md
sh checks/event.sh 'stage name=develop state=start session=S1 records=4'
ID=$(sed -n 's/^id=//p' .vid/run 2>/dev/null || true)
g worktree add -q "$T/builder" -b builder 2>/dev/null
cd "$T/builder"; mkdir -p .vid; printf '%s\n' "$HOMEP" > .vid/home
sh checks/event.sh 'stage name=develop state=start session=S1 records=4'
sh checks/event.sh 'brief-check path=x result=ok'
[ ! -f .vid/metrics-events ] || fail "the builder's own .vid/ holds events"
[ ! -f .vid/run ] || fail "the builder's own .vid/ holds a run file"
[ "$(grep -c '^stage name=develop state=start' "$HOMEP/.vid/metrics-events")" -eq 2 ] || fail 'the builder'"'"'s stage start is not at the home'
grep -q '^brief-check path=x result=ok ' "$HOMEP/.vid/metrics-events" || fail "the builder's other event is not at the home"
[ -n "$ID" ] || fail 'no run id at the home'
tail -n 2 "$HOMEP/.vid/metrics-events" | head -n 1 | grep -q " run=$ID at=" || fail "the builder's stage line does not carry the home's run id"
[ ! -f "$HOMEP/.vid/run.parent" ] && [ "$(sed -n 's/^id=//p' "$HOMEP/.vid/run")" = "$ID" ] || fail 'the builder worktree was taken for a copy'
exit 0
