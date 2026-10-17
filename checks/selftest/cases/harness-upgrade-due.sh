#!/bin/sh
# Purpose: selftest case — the upgrade step's states (v0.9.7.0.10 spec
# 3.6, R13; Codex 5). `sh checks/harness.sh rules` on a harness with no
# `rules:` line exits 1 and prints `harness-upgrade harness=<cksum>
# state=none`; it writes nothing. Each state the run manager records for
# that hash (due, dispatched, asked — through checks/event.sh) is the one
# printed next, the latest winning, still exit 1, so a resumed run goes on
# from it and asks nothing again; from a builder's worktree it reads the
# home's events. `declined` exits 0 for that hash; an edit to the harness
# is a new hash, due again (state=none). `applied` exits 0; so does a
# harness declaring `rules: 2`, whatever the events, and no harness at
# all. v0.9.7.0.11 (3.2, R2): every line says `target=2`, the target the
# plugin brings, and states are keyed by hash AND target — an event with
# no target= targets 1. A target-1 `asked` (or `dispatched`) for the hash
# keeps its scope (`target=1 state=asked`, exit 1); once applied, target 2
# is due on the new harness, now at `rules: 1`. A target-1 `declined` does
# not suppress target 2; a target-1 `due` only is superseded. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "harness-upgrade-due: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p "$T/home/checks" "$T/home/.vid"; cd "$T/home"; git init -q
cp "$CHECKS/harness.sh" "$CHECKS/event.sh" "$CHECKS/plan.sh" checks/
printf 'x-vid-harness:\n  product: product\n  completed: [0, 1]\nservices:\n  product:\n    build: .\n  tests:\n    image: runner\n' > docker-compose.test.yml
printf '.vid/\n' > .gitignore; g add -A && g commit -qm root
printf 'run: active\nsession: S1\nplan: required\nquestions: - · next Q1\nslice: -\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=13 at=2026-10-10T00:00:00Z\n' >> .vid/metrics-events
H1=$(cksum < docker-compose.test.yml | cut -d' ' -f1)
rules() { RC=0; sh checks/harness.sh rules > "$T/out" 2>&1 || RC=$?; }
N0=$(wc -l < .vid/metrics-events)
rules; [ "$RC" -eq 1 ] && [ "$(cat "$T/out")" = "harness-upgrade harness=$H1 target=2 state=none" ] || fail "no rules: line is not due with state=none (exit $RC)"
[ "$(wc -l < .vid/metrics-events)" -eq "$N0" ] || fail 'the check wrote an event'
for s in due dispatched asked; do
  sh checks/event.sh "harness-upgrade state=$s harness=$H1 target=2"
  rules; [ "$RC" -eq 1 ] && grep -qx "harness-upgrade harness=$H1 target=2 state=$s" "$T/out" || fail "after state=$s: not still due at $s (exit $RC)"
done
# a builder's worktree reads the home's events
g worktree add -q "$T/wt" -b wt
( cd "$T/wt" && sh checks/harness.sh rules ) > "$T/out" 2>&1 && fail 'the worktree saw nothing due'
grep -qx "harness-upgrade harness=$H1 target=2 state=asked" "$T/out" || fail 'the worktree did not read the home'"'"'s state'
# another hash's state is not this one's
sh checks/event.sh 'harness-upgrade state=applied harness=999'
rules; grep -qx "harness-upgrade harness=$H1 target=2 state=asked" "$T/out" || fail 'another hash'"'"'s state was read'
sh checks/event.sh "harness-upgrade state=declined harness=$H1 target=2"
rules; [ "$RC" -eq 0 ] && grep -qx "harness-upgrade harness=$H1 target=2 state=declined" "$T/out" || fail "declined is not done for its hash (exit $RC)"
printf '# an edit\n' >> docker-compose.test.yml
H2=$(cksum < docker-compose.test.yml | cut -d' ' -f1)
rules; [ "$RC" -eq 1 ] && grep -qx "harness-upgrade harness=$H2 target=2 state=none" "$T/out" || fail 'an edited harness is not due again'
sh checks/event.sh "harness-upgrade state=applied harness=$H2 target=2"
rules; [ "$RC" -eq 0 ] || fail 'applied is not done'
# v0.9.7.0.11 (R2): the targets. A fresh harness H3; events with no target= target 1
printf '# a third\n' >> docker-compose.test.yml; H3=$(cksum < docker-compose.test.yml | cut -d' ' -f1)
sh checks/event.sh "harness-upgrade state=due harness=$H3"
rules; [ "$RC" -eq 1 ] && grep -qx "harness-upgrade harness=$H3 target=2 state=none" "$T/out" || fail 'a target-1 due was not superseded by target 2'
sh checks/event.sh "harness-upgrade state=asked harness=$H3"
rules; [ "$RC" -eq 1 ] && grep -qx "harness-upgrade harness=$H3 target=1 state=asked" "$T/out" || fail 'a target-1 asked did not keep its scope'
sh checks/event.sh "harness-upgrade state=declined harness=$H3 target=1"
rules; [ "$RC" -eq 1 ] && grep -qx "harness-upgrade harness=$H3 target=2 state=none" "$T/out" || fail 'a target-1 decline suppressed target 2'
sh checks/event.sh "harness-upgrade state=applied harness=$H3"
awk '{ print } $0 == "  product: product" { print "  rules: 1" }' docker-compose.test.yml > c && mv c docker-compose.test.yml
H4=$(cksum < docker-compose.test.yml | cut -d' ' -f1)
rules; [ "$RC" -eq 1 ] && grep -qx "harness-upgrade harness=$H4 target=2 state=none" "$T/out" || fail 'a harness at rules: 1 is not due for target 2'
sed 's/^  rules: 1$/  rules: 2/' docker-compose.test.yml > c && mv c docker-compose.test.yml
rules; [ "$RC" -eq 0 ] && grep -q 'declares rules: 2' "$T/out" || fail 'a harness declaring rules: 2 is due'
rm docker-compose.test.yml; rules; [ "$RC" -eq 0 ] || fail 'no harness is due'
exit 0
