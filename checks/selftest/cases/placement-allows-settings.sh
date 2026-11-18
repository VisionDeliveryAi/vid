#!/bin/sh
# Purpose: selftest case — the compaction setting the owner approved can be committed (0.26.10.29.3, R8, F33). With a
# placement map of app/ alone, checks/placement.sh lets a staged .claude/settings.json through (the one file under
# .claude/ init writes, on the owner's yes); any other new file under .claude/ is still refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "placement-allows-settings: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
git init -q
printf '# project\n\n```vid-placement\napp/\n```\n' > CLAUDE.md
g add -A; g commit -qm root
mkdir -p .claude/agents
printf '{ "autoCompactWindow": 300000 }\n' > .claude/settings.json; g add -f .claude/settings.json
RC=0; sh "$CHECKS/placement.sh" > "$T/out" 2>&1 || RC=$?
[ "$RC" = 0 ] || fail "the spec commit staging .claude/settings.json was refused ($RC)"
for f in .claude/settings.local.json .claude/agents/helper.md; do
  printf 'x\n' > "$f"; g add -f "$f"
  RC=0; sh "$CHECKS/placement.sh" > "$T/out" 2>&1 || RC=$?
  [ "$RC" = 1 ] && grep -q "'$f' is outside the placement map" "$T/out" || fail "$f was let through ($RC)"
  g reset -q "$f"
done
echo 'placement-allows-settings: ok'
