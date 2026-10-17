#!/bin/sh
# Purpose: selftest case — a relabel is judged by the label rule alone (v0.9.7.3 spec 3.1, R1). HEAD carries a
# legacy line whose enforced: ref checks 4b would now refuse (a ledger test that does not exist) and one followed by
# origin:. Adding a label to each, the rest unchanged, passes — the field compared stripped by name, wherever it
# sits; a relabel naming an unknown id is refused by 4c; a line whose text also changed is judged in full (refused
# by 4b). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"; mkdir -p .vid
fail() { echo "decision-label-relabel: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\n```\n' > INVENTORY.md
printf '# DECISIONS\n\n## Log\n\n- **D-001** sessions last a day | why: load | enforced: tests/invariants/test_gone.py\n- **D-002** prices in minor units | why: exactness | enforced: convention | origin: proposal\n' > DECISIONS.md
g add -A && g commit -qm 'legacy decisions'
hook() { g add DECISIONS.md; if sh checks/hooks/pre-commit > "$T/.vid/out" 2>&1; then echo pass; else echo refused; fi; }
cp DECISIONS.md "$T/.vid/dec"
sed 's#test_gone.py$#test_gone.py | applies-to: ROW-001#; s#| enforced: convention | origin: proposal#| enforced: convention | scope: project | origin: proposal#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = pass ] || fail 'a relabel was refused for old content'
sed 's#test_gone.py$#test_gone.py | applies-to: ROW-404#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = refused ] || fail 'a relabel naming an unknown id passed'; grep -q 'ROW-404' "$T/.vid/out" || fail 'the unknown id is not named'
sed 's#sessions last a day | why: load | enforced: tests/invariants/test_gone.py$#sessions last a week | why: load | enforced: tests/invariants/test_gone.py | applies-to: ROW-001#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = refused ] || fail 'a changed line with a label was not judged in full'
tail -n 1 .vid/hook-times | grep -q ' by=decisions-promissory ' || fail 'the changed line was not refused by 4b'
exit 0
