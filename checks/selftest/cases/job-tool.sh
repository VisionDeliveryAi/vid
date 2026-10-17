#!/bin/sh
# Purpose: selftest case — the builders' tool is the owner's setting (v0.9.7.1 spec 3.9, R9). Convicts unless `sh
# checks/job.sh tool` prints `builders: claude` with no setting; `tool codex` without `--by owner` is refused and
# changes nothing; `tool codex --by owner` writes builder-tool=codex and records `builder-tool set=codex by=owner`;
# a Codex job is refused while builders are Claude's; and `tool claude --by owner` switches back. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "job-tool: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks" "$T/p/.vid"; cd "$T/p"; cp "$CHECKS/job.sh" "$CHECKS/event.sh" checks/
[ "$(sh checks/job.sh tool)" = 'builders: claude' ] || fail 'the default is not claude'
if sh checks/job.sh tool codex > "$T/out" 2>&1; then fail 'tool codex without --by owner was taken'; fi
grep -q 'builder-tool' .vid/budget 2>/dev/null && fail 'a refused switch wrote the budget'
sh checks/job.sh tool codex --by owner > "$T/out" 2>&1 || fail 'the owner'"'"'s switch was refused'
grep -qx 'builder-tool=codex' .vid/budget || fail 'builder-tool=codex not written'
grep -q '^builder-tool set=codex by=owner ' .vid/metrics-events || fail 'no builder-tool event'
sh checks/job.sh tool claude --by owner > /dev/null || fail 'switching back failed'
[ "$(sh checks/job.sh tool)" = 'builders: claude' ] && [ "$(grep -c '^builder-tool=' .vid/budget)" = 1 ] || fail 'the switch back is not one line'
cd "$T"; jb_repo "$T/repo"; sh checks/job.sh tool claude --by owner > /dev/null
if sh checks/job.sh start --brief "$B" > "$T/out" 2>&1; then fail 'a Codex job started while builders are Claude'"'"'s'; fi
exit 0
