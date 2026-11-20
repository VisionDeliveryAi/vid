#!/bin/sh
# Purpose: selftest case — no product code during an incorporation (IR I5), as during an add. Stub courts under the
# real hook, with plan.sh and event.sh, placement app/. Session S1's incorporation started: app/x.py is refused, the
# refusal naming /vid incorporate and the path; PRD.md, DECISIONS.md, ARCHITECTURE.md and tests/t.py pass. Session S2
# passes. The incorporation's end passes; a new one is refused again, and S1's fix start ends it. An add opened after
# an ended incorporation still names /vid add. `mode: tickets` passes. Where the plugin's skills are beside checks/,
# vid-develop's scoped completion grade (between "## Done" and "## Completion report") holds the paragraph that reads an
# incorporation as an add: its `stage name=incorporate` events, its `base=` and its PRD appends (IR I5). Env: CHECKS.
set -eu
unset VID_ROLE
D="$CHECKS/../skills/vid-develop/SKILL.md"
if [ -f "$D" ]; then
  P=$(awk '/^## Done/ { on = 1 } on && /^## Completion report/ { exit } on' "$D" |
    awk '/^An incorporation is read as an add/ { on = 1 } on && /^$/ { exit } on' | tr '\n' ' ' | tr -s ' ')
  [ -n "$P" ] || { echo "incorporate-add-guard: develop's scoped grade has no paragraph reading an incorporation as an add" >&2; exit 1; }
  for _t in '`stage name=incorporate`' '`base=`' 'PRD appends'; do
    printf '%s' "$P" | grep -qF -- "$_t" || { echo "incorporate-add-guard: develop's incorporation paragraph does not name $_t" >&2; exit 1; }
  done
fi
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/home"; cd "$T/home"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "incorporate-add-guard: $*" >&2; cat "$T/out" .vid/metrics-events >&2 2>/dev/null; exit 1; }
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
printf '# Law\n\n```vid-placement\napp/\ntests/\n```\n' > CLAUDE.md
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
passes 'no incorporation has started'
stg incorporate start S1
refused 'S1 started an incorporation'
grep -q 'product code staged during /vid incorporate: app/x.py (and 0 more)' "$T/out" || fail 'the refusal does not name /vid incorporate and the path'
passes 'the PRD append' PRD.md
passes 'a decision line' DECISIONS.md
passes 'the architecture' ARCHITECTURE.md
passes 'a ledger test' tests/t.py
CLAUDE_CODE_SESSION_ID=S2; passes 'another session is not the incorporation'; CLAUDE_CODE_SESSION_ID=S1
stg incorporate end S1
passes "the incorporation's end"
stg incorporate start S1; refused 'a new incorporation'
stg fix start S1
passes "S1's fix start"
stg add start S1; refused 'an add after the incorporation ended'
grep -q 'product code staged during /vid add: app/x.py' "$T/out" || fail 'an add opened after an incorporation does not name /vid add'
stg add end S1; stg incorporate start S1
printf 'run: active\nsession: S1\nmode: tickets\n' > .vid/RUN-STATE.md
passes 'mode: tickets'
exit 0
