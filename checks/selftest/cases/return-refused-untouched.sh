#!/bin/sh
# Purpose: selftest case — a refused return writes nothing (v0.26.10.4 spec R10, F-39; §5 return-refused-untouched).
# The brief-write fixture with bw_builder and bw_return. A return the agent wrote without `agent:` whose `not` reason
# points at a report that is not there is refused under `return <file> --agent a1`, and the file is unchanged byte
# for byte — no `agent:` line; once the report is there the same call accepts it and the file gains `agent: a1`
# after its `brief:` line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "return-refused-untouched: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
H=$(git rev-parse HEAD); RF=.vid/briefs/1/builder-1.return.md
printf 'brief: .vid/briefs/1/builder-1.md\nbranch: vid/1-builder-1\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | blocked — see the report for the cause\n' "$H" "$GREEN" > "$RF"
C0=$(cksum < "$RF")
if sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1; then fail 'a return pointing at a missing report was accepted'; fi
[ "$(cksum < "$RF")" = "$C0" ] || fail "the refused return file was changed: $(head -n 3 "$RF")"
grep -q '^agent:' "$RF" && fail 'the refused return gained an agent: line'
printf 'the cause, in detail\n' > .vid/briefs/1/builder-1.report.md
sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1 || fail 'the return was refused with its report present'
sed -n 2p "$RF" | grep -qx 'agent: a1' && [ "$(grep -c '^agent:' "$RF")" = 1 ] || fail "the accepted return did not gain its agent: line — $(head -n 3 "$RF")"
exit 0
