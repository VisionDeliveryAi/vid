#!/bin/sh
# Purpose: selftest case — the harness-upgrade brief's container states (v0.9.8 R17). With one ticket's
# services.inline.txt written before the rename (`ready-at=`) and one after (`kept-healthy-at=`), the upgrade brief's
# section 13 lists both under kept-healthy-at — the older one's ready-at read under the new name — its heading says
# kept-healthy-at, and no line says ready-at; vid-develop's upgrade question shows the overhead before and after and
# no service's ready time. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "upgrade-brief-states: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
mkdir -p "$CLAUDE_PLUGIN_ROOT/templates"
printf '# toy template\n#\n# Four harness rules (toy):\n#  1. nothing installed at start.\n#  2. ready before use.\n#  3. test-sized data.\n#  4. no case past case-limit.\n#\n' > "$CLAUDE_PLUGIN_ROOT/templates/docker-compose.test.yml"
printf 'x-vid-harness:\n  product: product\nservices:\n  product:\n    build: .\n  tests:\n    image: runner\n' > docker-compose.test.yml
g add -A && g commit -qm 'a harness without the rules'
mkdir -p .vid/requests/20261010T101500Z-ab12 .vid/requests/20261012T101500Z-cd34
printf '# name state exit memory-kill health restarts started-at ready-at finished-at\nvid-s1-x-db-1 state=running exit=0 memory-kill=no health=healthy restarts=0 started-at=2026-10-10T10:15:01Z ready-at=2026-10-10T10:15:09Z finished-at=-\n' > .vid/requests/20261010T101500Z-ab12/services.inline.txt
sleep 1
printf '# name state exit memory-kill health restarts started-at kept-healthy-at finished-at\nvid-s1-x-db-1 state=running exit=0 memory-kill=no health=healthy restarts=0 started-at=2026-10-12T10:15:01Z kept-healthy-at=2026-10-12T10:15:08Z finished-at=-\n' > .vid/requests/20261012T101500Z-cd34/services.inline.txt
bw_write --role builder --slice 2 --step S2 --rows ROW-104 --upgrade || fail 'the upgrade brief was refused'
B=$(bw_out); awk '/^## [0-9]/ { on = ($2 == 13); next } on' "$B" > "$T/s13"
grep -q "container states (started-at, kept-healthy-at), newest first" "$T/s13" || fail 'the heading does not say kept-healthy-at'
grep -q 'kept-healthy-at=2026-10-10T10:15:09Z' "$T/s13" || fail 'the older ticket'"'"'s ready-at is not read as kept-healthy-at'
grep -q 'kept-healthy-at=2026-10-12T10:15:08Z' "$T/s13" || fail 'the newer ticket'"'"'s kept-healthy-at is missing'
grep -q 'ready-at' "$T/s13" && fail 'section 13 still says ready-at'
D="$CHECKS/../skills/vid-develop/SKILL.md"
if [ -f "$D" ]; then
  tr '\n' ' ' < "$D" | tr -s ' ' | grep -qF 'Show the `overhead=` before (the brief'"'"'s last gated passes) and after (the builder'"'"'s re-measured request) and any `difference` row it proposes' || fail 'develop'"'"'s question does not show the overhead before and after'
  grep -q "slowest service's ready" "$D" && fail 'develop'"'"'s question still shows a service'"'"'s ready time'
fi
exit 0
