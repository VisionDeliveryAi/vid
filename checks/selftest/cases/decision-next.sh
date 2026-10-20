#!/bin/sh
# Purpose: selftest case — D-numbers are reserved at the home (v0.26.10.4 spec R13, F-48; §5 decision-next). A toy
# home with a live run (RUN-STATE, a develop stage start) whose DECISIONS.md reaches D-010 at its HEAD, and two
# worktrees naming it in .vid/home: w1 branched when DECISIONS.md held only D-001 (it lags the home), w2 at the
# home's HEAD. `next --try` from w1 gives D-011 — above the home's D-010, not D-002 — and from w2 D-012; the run
# manager's `next` at the home gives D-013; each is one line `D-NNN<TAB><try|manager><TAB><UTC>` in the home's
# .vid/decision-ids, and the lock is gone after. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'cd /; git -C "$T/home" worktree prune 2>/dev/null; rm -rf "$T"' EXIT
fail() { echo "decision-next: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
dl() { printf -- '- **%s** a toy choice | why: toy | enforced: convention | scope: project\n' "$1"; }
mkdir -p "$T/home/checks" "$T/home/.vid"; cd "$T/home"; git init -q
cp "$CHECKS/decisions.sh" "$CHECKS/plan.sh" checks/
printf '.vid/\n' > .gitignore; { echo '# Decisions'; dl D-001; } > DECISIONS.md
g add -A && g commit -qm 'D-001'
g branch b1
{ dl D-002; dl D-003; } >> DECISIONS.md; g commit -qam 'D-002, D-003'
g branch b2
dl D-010 >> DECISIONS.md; g commit -qam 'D-010'
printf 'run: active\nsession: S1\nplan: required\nquestions: -\nslice: 1 open\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=24 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > .vid/metrics-events
H=$(pwd -P)
for w in 1 2; do g worktree add -q "$T/w$w" "b$w"; mkdir -p "$T/w$w/.vid"; echo "$H" > "$T/w$w/.vid/home"; done
cd "$T/w1"; sh checks/decisions.sh next --try 1-fixer-1 > "$T/out" 2>&1 || fail 'next was refused in w1'
[ "$(cat "$T/out")" = D-011 ] || fail "w1, lagging the home, got $(cat "$T/out"), not D-011"
cd "$T/w2"; sh checks/decisions.sh next --try 1-fixer-2 > "$T/out" 2>&1 || fail 'next was refused in w2'
[ "$(cat "$T/out")" = D-012 ] || fail "w2 got $(cat "$T/out"), not D-012 — the two worktrees share a number"
cd "$H"; sh checks/decisions.sh next > "$T/out" 2>&1 || fail 'next was refused at the home'
[ "$(cat "$T/out")" = D-013 ] || fail "the run manager got $(cat "$T/out"), not D-013"
TAB=$(printf '\t')
[ "$(grep -c . .vid/decision-ids)" -eq 3 ] || fail 'not three reservations at the home'
grep -qE "^D-011${TAB}1-fixer-1${TAB}[0-9-]+T[0-9:]+Z\$" .vid/decision-ids && grep -qE "^D-012${TAB}1-fixer-2${TAB}" .vid/decision-ids && grep -qE "^D-013${TAB}manager${TAB}" .vid/decision-ids || fail "the reservations are not D-NNN<TAB><try|manager><TAB><UTC>: $(cat .vid/decision-ids)"
[ ! -e .vid/decision-ids.lock ] || fail 'the lock was left'
[ ! -f "$T/w1/.vid/decision-ids" ] && [ ! -f "$T/w2/.vid/decision-ids" ] || fail 'a reservation was written in a worktree, not at the home'
exit 0
