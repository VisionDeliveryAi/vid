#!/bin/sh
# Purpose: selftest case — no product code during an add (v0.26.10.24 R3). Stub courts under the real hook, with
# plan.sh and event.sh, placement app/. Session S1's add started: app/x.py is refused, named, with a `refused
# phase=pre-commit by=no-plan-step` event; app/README.md, tests/t.py and PRD.md pass; S1's test-inventory stage leaves it
# refused. Session S2 passes, until it records the add's start itself (a takeover). A merge passes what one parent holds
# and refuses an edit in the resolution. A builder's checkout, the add's end, a fix start of S1, `mode: tickets`, no
# placement block and a hook with no plan.sh each pass. Env: CHECKS.
set -eu
unset VID_ROLE
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/home"; cd "$T/home"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "guard-add: $*" >&2; cat "$T/out" .vid/metrics-events >&2 2>/dev/null; exit 1; }
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
LAW='# Law

```vid-placement
app/
tests/
```
'
printf '%s' "$LAW" > CLAUDE.md
g add -A; g commit -qm 'the helpers and the law' --no-verify
mkdir -p .vid
utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
stg() { printf 'stage name=%s state=%s session=%s at=%s\n' "$1" "$2" "$3" "$(utc)" >> .vid/metrics-events; }
hook() { rm -rf "$(git rev-parse --git-path vid-memo)"; R=0; sh checks/hooks/pre-commit > "$T/out" 2>&1 || R=$?; }
# try <path>: a new file staged, the hook run, the file gone again; R its exit
try() { mkdir -p "$(dirname "$1")"; printf '# Purpose: x\n' > "$1"; g add "$1"; hook; g rm -q --cached "$1"; rm -f "$1"; }
refused() { try app/x.py; [ "$R" -eq 1 ] || fail "app/x.py was not refused: $1"; }
passes() { try "${2:-app/x.py}"; [ "$R" -eq 0 ] || fail "${2:-app/x.py} was refused: $1"; }
export CLAUDE_CODE_SESSION_ID=S1
passes 'no add has started'
stg add start S1
refused 'S1 started the add'
grep -q 'product code staged during /vid add: app/x.py (and 0 more)' "$T/out" || fail 'the refusal does not name the path'
grep -q '^refused phase=pre-commit by=no-plan-step ' .vid/metrics-events || fail 'no refused event by=no-plan-step'
tail -n 1 .vid/hook-times | grep -q ' by=no-plan-step ' || fail 'hook-times does not carry by=no-plan-step'
mkdir -p app/two; printf '# Purpose: x\n' > app/x.py; printf '# Purpose: x\n' > app/two/y.py; printf 'd\n' > app/d.md; g add app; hook
[ "$R" -eq 1 ] && grep -q '(and 1 more)' "$T/out" || fail 'two product paths are not counted, the .md apart'
g reset -q; rm -rf app/two app/x.py app/d.md
passes 'a spec file under the map' app/README.md
passes 'a ledger test' tests/t.py
passes 'the spec' PRD.md
stg test-inventory start S1; stg test-inventory end S1
refused "the inventory's stage does not end the add"
CLAUDE_CODE_SESSION_ID=S2; passes 'another session is not the add'
stg add start S2; refused 'S2 took the add over'
stg add end S2; CLAUDE_CODE_SESSION_ID=S1
# a merge: what one parent holds passes, an edit in the resolution does not
BR=$(git rev-parse --abbrev-ref HEAD)
g checkout -q -b side; printf '# Purpose: x\n' > app/x.py; g add app/x.py; g commit -qm side --no-verify
g checkout -q "$BR"; printf 'other\n' >> app/x.txt; g add app/x.txt; g commit -qm other --no-verify
g merge -q --no-commit --no-ff side > /dev/null 2>&1 || true
hook; [ "$R" -eq 0 ] || fail "a merge of one parent's app/x.py was refused"
printf '# edited\n' >> app/x.py; g add app/x.py
hook; [ "$R" -eq 1 ] || fail 'a merge with app/x.py edited in the resolution passed'
g merge --abort
# the home holds a run's state from here: a builder's checkout is not the home
printf 'run: active\nsession: S1\n' > .vid/RUN-STATE.md
refused 'at the home'
g worktree add -q "$T/wt" -b builder
( cd "$T/wt"; mkdir -p .ran .fail .vid; printf '%s\n' "$T/home" > .vid/home
  printf '# Purpose: x\n' > app/x.py; g add app/x.py; sh checks/hooks/pre-commit > "$T/out" 2>&1 ) || fail "a builder's checkout was refused"
stg add end S1
passes "the add's end"
stg add start S1; refused 'a new add'
stg fix start S1
passes "S1's fix start"
stg add start S1; refused 'another add'
printf 'run: active\nsession: S1\nmode: tickets\n' > .vid/RUN-STATE.md
passes 'mode: tickets'
printf 'run: active\nsession: S1\n' > .vid/RUN-STATE.md
refused 'mode: tickets gone'
printf '# Law\n' > CLAUDE.md
passes 'no placement block'
printf '%s' "$LAW" > CLAUDE.md
refused 'the placement block back'
g rm -q checks/plan.sh; g commit -qm 'no plan.sh' --no-verify
passes 'a hook with no plan.sh'
exit 0
