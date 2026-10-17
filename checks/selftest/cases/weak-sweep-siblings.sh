#!/bin/sh
# Purpose: selftest case — a weak test is repaired with its siblings (v0.9.8 spec 3.5, R8; amendment 3). ROW-201's
# latest verdict is a grader's BREACHED class=test; a test-author brief for it carries `## 18 siblings`: ROW-203 (an
# item it derives from, REQ-001), never ROW-202 (only its test file shared), ROW-204 or ROW-205 (nothing shared) nor
# ROW-201 itself; the check passes it. A brief for ROW-202, whose latest verdict is no test breach, carries none; nor does
# ROW-201's once an amendment wipes its verdicts. A conclusive proof that failed (its verdict carries proof=) sweeps
# the same way: ROW-203's brief then names ROW-201. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "weak-sweep-siblings: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
au_repo "$T/repo"; au_more; au_stamp
mkdir -p .vid
printf 'verdict slice=1 row=ROW-201 result=BREACHED class=test brief=b quoted-at=x at=2026-10-12T00:00:01Z\n' >> .vid/metrics-events
w() { CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role test-author --slice 1 --rows "$1" > "$T/out" 2>&1 || fail "the brief for $1 was refused"; sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1; }
B=$(w ROW-201)
awk '/^## [0-9]/ { on = ($2 == 18); next } on' "$B" | grep '^ROW-' > "$T/s18" || fail 'no section 18'
grep -qx 'ROW-203 by=rule REQ-001 (of ROW-201)' "$T/s18" || fail 'ROW-203 (the same item) is not a sibling'
grep -q '^ROW-202\|^ROW-204\|^ROW-205\|^ROW-201' "$T/s18" && fail 'a row sharing only the file, an unrelated row or the row itself is a sibling'
sh checks/brief.sh "$B" > "$T/out" 2>&1 || fail 'the check refused the siblings'
grep -qx '## 18 siblings' "$(w ROW-202)" && fail 'a brief with no weak test carries siblings'
printf 'amended row=ROW-201 sha=x by=obligation at=2026-10-12T00:00:02Z\n' >> .vid/metrics-events
grep -qx '## 18 siblings' "$(w ROW-201)" && fail 'an amended row'"'"'s old weak verdict still sweeps'
printf 'verdict slice=1 row=ROW-203 result=BREACHED class=test proof=p.proof.xml brief=b quoted-at=x at=2026-10-12T00:00:03Z\n' >> .vid/metrics-events
B=$(w ROW-203); awk '/^## [0-9]/ { on = ($2 == 18); next } on' "$B" | grep -qx 'ROW-201 by=rule REQ-001 (of ROW-203)' || fail 'a failed proof does not sweep its siblings'
exit 0
