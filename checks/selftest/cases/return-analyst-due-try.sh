#!/bin/sh
# Purpose: selftest case — a return lists only its own attempt's analyst-dues (v0.9.7.3 spec 3.9, R9). The
# brief-write fixture with bw_builder and bw_return (the brief's try 1-builder-1). Two open analyst-dues at the home:
# one on a ticket that attempt asked (try=1-builder-1), one on another attempt's. `return` prints the first and not
# the second; `sh checks/test.sh analyst-due` still lists both for the run manager. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "return-analyst-due-try: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
cp "$CHECKS/test.sh" "$CHECKS/plan.sh" checks/
TRY=$(sed -n '1,14s/^.*try:[[:space:]]*\([^ ]*\).*/\1/p' .vid/briefs/1/builder-1.md | head -n 1); [ -n "$TRY" ] || fail 'the brief names no try'
for k in 20990101T000000Z-aaaa 20990101T000001Z-bbbb; do mkdir -p ".vid/requests/$k"; done
printf 'type=iterate\nrole=builder\ntry=%s\n' "$TRY" > .vid/requests/20990101T000000Z-aaaa/request
printf 'type=iterate\nrole=builder\ntry=9-builder-9\n' > .vid/requests/20990101T000001Z-bbbb/request
printf 'analyst-due request=20990101T000000Z-aaaa reason=cap at=2099-01-01T00:00:00Z\nanalyst-due request=20990101T000001Z-bbbb reason=slow rows=ROW-9 at=2099-01-01T00:00:01Z\n' >> .vid/metrics-events
H=$(git rev-parse HEAD); RF=.vid/briefs/1/builder-1.return.md
printf 'brief: .vid/briefs/1/builder-1.md\nbranch: vid/1-builder-1\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$H" "$GREEN" > "$RF"
sh checks/brief.sh return "$RF" --agent a1 > "$T/out" 2>&1 || fail 'the return was refused'
grep -q '^analyst due: request=20990101T000000Z-aaaa reason=cap$' "$T/out" || fail 'its own attempt'"'"'s analyst-due is not printed'
grep -q 'request=20990101T000001Z-bbbb' "$T/out" && fail 'another attempt'"'"'s analyst-due is printed'
sh checks/test.sh analyst-due > "$T/out" 2>&1
grep -q 'request=20990101T000000Z-aaaa' "$T/out" && grep -q 'request=20990101T000001Z-bbbb' "$T/out" || fail 'the run manager'"'"'s list lost one'
exit 0
