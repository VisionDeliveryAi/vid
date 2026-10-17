#!/bin/sh
# Purpose: selftest case — the return file is the agent's, the agent id the run manager's (v0.9.7.1 spec 3.1,
# 3.4a; R1, R4). The brief-write fixture with bw_builder and bw_return. Convicts unless `return` refuses a `.tmp`
# file (the agent renames it into place when whole); `return <file> --agent a1` writes `agent: a1` into a file
# the agent wrote without it and says ok, and `--agent codex:1-builder-1` writes that; a `not` reason pointing at
# a report ("see the report") is refused while no builder-<n>.report.md is beside the return and accepted once it
# is; a commit that does not descend from the brief's quoted-at is refused, naming quoted-at; and a `wrong base`
# return (every row `not | none | wrong base: …`) is accepted from any commit and said as `wrong base: every row
# — <the error> — …`, with no merge probe (rehearsal R-1). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "return-agent-written: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
H=$(git rev-parse HEAD); RF=.vid/briefs/1/builder-1.return.md
blk() { printf 'brief: .vid/briefs/1/builder-1.md\nbranch: vid/1-builder-1\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | %s\n' "$1" "$GREEN" "$2"; }
blk "$H" 'not built' > "$RF.tmp"
if sh checks/brief.sh return "$RF.tmp" --agent a1 > "$T/out" 2>&1; then fail 'a .tmp return was read'; fi
mv "$RF.tmp" "$RF"
sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1 || fail 'an agent-written return with --agent was refused'
sed -n 2p "$RF" | grep -qx 'agent: a1' || fail "agent: a1 was not written in after brief: — $(head -n 3 "$RF")"
[ "$(grep -c '^agent:' "$RF")" = 1 ] || fail 'not exactly one agent: line'
sh checks/brief.sh return "$RF" --agent codex:1-builder-1 > "$T/out" 2>&1 || fail 'the codex agent id was refused'
grep -qx 'agent: codex:1-builder-1' "$RF" && [ "$(grep -c '^agent:' "$RF")" = 1 ] || fail 'agent: codex:<try> was not written'
blk "$H" 'blocked — see the report for the cause' > "$RF"
if sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1; then fail 'a reason pointing at a missing report was accepted'; fi
grep -qF 'builder-1.report.md' "$T/out" || fail 'the refusal does not name the report'
printf 'the cause, in detail\n' > .vid/briefs/1/builder-1.report.md
sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1 || fail 'the reason was refused with its report present'
# a commit that does not descend from quoted-at
B0=$(git symbolic-ref --short HEAD); g checkout -q --orphan stray; g commit -qm stray --allow-empty; S=$(git rev-parse HEAD); g checkout -q -f "$B0"; g branch -q -D stray
printf 'brief: .vid/briefs/1/builder-1.md\nbranch: vid/1-builder-1\ncommit: %s\nROW-101 | not | none | not built\nROW-102 | not | none | not built\n' "$S" > "$RF"
if sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1; then fail 'a commit off quoted-at was accepted'; fi
grep -qF 'does not descend from the brief' "$T/out" || fail 'the refusal does not name the descent'
printf 'brief: .vid/briefs/1/builder-1.md\nbranch: vid/1-builder-1\ncommit: %s\nROW-101 | not | none | wrong base: fatal: a branch named vid/1-builder-1 already exists\nROW-102 | not | none | wrong base: fatal: a branch named vid/1-builder-1 already exists\n' "$S" > "$RF"
sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1 || fail 'a wrong base return was refused'
grep -qx 'wrong base: every row — fatal: a branch named vid/1-builder-1 already exists — nothing was built: write a new brief and spawn again' "$T/out" || fail 'the wrong base is not said plainly'
grep -q '^merge probe' "$T/out" && fail 'a wrong base was merge-probed'
exit 0
