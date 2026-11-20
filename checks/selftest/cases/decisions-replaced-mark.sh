#!/bin/sh
# Purpose: selftest case — a replaced decision is marked, and only marked (IR I2). Under the real hook with stub courts,
# HEAD holds a labelled line and an unlabelled legacy line whose enforced: refs check 4b would now refuse (a ledger test
# that is gone), and two later lines. A mark-only commit on the labelled line (`| replaced-by: D-003`, right before
# ` | why:`) passes, the mark stripped with the label; a mark naming a missing D-id, or naming nothing, is refused (by=decisions-label); a
# mark on the legacy line passes when the same commit labels it, and is refused when it does not; once the mark is
# committed, extending it with a second D-id passes, dropping the first id is refused (by=decisions-label), and so is
# deleting the line the mark names, though no other line changed. A mark
# placed after ` | why:` is refused, since a grader is given the line up to ` | why:` alone. The staged file is read:
# a mark and the line it names added in one commit pass, and a named line present only in the unstaged working tree is
# refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"; mkdir -p .vid
fail() { echo "decisions-replaced-mark: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\n```\n' > INVENTORY.md
cat > DECISIONS.md <<'DEC'
# DECISIONS

## Log

- **D-001** sessions last a day | why: load | enforced: tests/invariants/test_gone.py | applies-to: ROW-001
- **D-002** prices are kept in minor units | why: exactness | enforced: tests/invariants/test_cents_gone.py
- **D-003** signed-in sessions last a week | why: fewer sign-ins | enforced: convention | applies-to: ROW-001
- **D-004** a session ends when the password changes | why: safety | enforced: convention | applies-to: ROW-001
DEC
g add -A && g commit -qm 'decisions'
hook() { g add DECISIONS.md; if sh checks/hooks/pre-commit > "$T/.vid/out" 2>&1; then echo pass; else echo refused; fi; }
# hookst: the hook on what is staged now, nothing added
hookst() { if sh checks/hooks/pre-commit > "$T/.vid/out" 2>&1; then echo pass; else echo refused; fi; }
by() { tail -n 1 .vid/hook-times | grep -q " by=$1 " || fail "hook-times does not name $1"; }
cp DECISIONS.md "$T/.vid/dec"
sed 's#^- \*\*D-001\*\* sessions last a day | why:#- **D-001** sessions last a day | replaced-by: D-003 | why:#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = pass ] || fail 'a mark-only change to a labelled line was refused'
sed 's#^- \*\*D-001\*\* sessions last a day | why:#- **D-001** sessions last a day | replaced-by: D-404 | why:#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = refused ] || fail 'a mark naming a missing decision passed'
grep -q 'D-404' "$T/.vid/out" || fail 'the refusal does not name the missing id'; by decisions-label
sed 's#^- \*\*D-001\*\* sessions last a day | why:#- **D-001** sessions last a day | replaced-by: | why:#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = refused ] || fail 'a mark naming nothing passed'
grep -q 'replaced-by: names nothing' "$T/.vid/out" || fail 'the refusal does not say the mark names nothing'; by decisions-label
# the staged file is read, never the working tree: a mark and the line it names added in one commit pass; a named line
# present only in the unstaged working tree is refused
D5='- **D-005** a session ends at midnight | why: one clock | enforced: convention | applies-to: ROW-001'
sed 's#^- \*\*D-001\*\* sessions last a day | why:#- **D-001** sessions last a day | replaced-by: D-005 | why:#' "$T/.vid/dec" > DECISIONS.md
printf '%s\n' "$D5" >> DECISIONS.md
[ "$(hook)" = pass ] || fail 'a mark and the line it names, added in one commit, were refused'
sed 's#^- \*\*D-001\*\* sessions last a day | why:#- **D-001** sessions last a day | replaced-by: D-005 | why:#' "$T/.vid/dec" > DECISIONS.md
g add DECISIONS.md; printf '%s\n' "$D5" >> DECISIONS.md
[ "$(hookst)" = refused ] || fail 'a mark naming a line only in the unstaged working tree passed'
grep -q 'D-005' "$T/.vid/out" || fail 'the refusal does not name the unstaged id'; by decisions-label
sed 's#^\(- \*\*D-001\*\* sessions last a day | why: load | enforced: tests/invariants/test_gone.py | applies-to: ROW-001\)$#\1 | replaced-by: D-003#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = refused ] || fail 'a mark after why: passed'; by decisions-label
sed 's#^\(- \*\*D-002\*\* prices are kept in minor units\) | why: exactness | enforced: tests/invariants/test_cents_gone.py$#\1 | replaced-by: D-004 | why: exactness | enforced: tests/invariants/test_cents_gone.py | scope: project#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = pass ] || fail 'a mark on a legacy line was refused although the same commit labels it'
sed 's#^\(- \*\*D-002\*\* prices are kept in minor units\) | why:#\1 | replaced-by: D-004 | why:#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = refused ] || fail 'a mark on an unlabelled legacy line passed with no label'
grep -q 'no label' "$T/.vid/out" || fail 'the refusal does not say the legacy line has no label'; by decisions-label
sed 's#^- \*\*D-001\*\* sessions last a day | why:#- **D-001** sessions last a day | replaced-by: D-003 | why:#' "$T/.vid/dec" > DECISIONS.md
g add DECISIONS.md && g commit -qm 'D-001 marked' --no-verify
cp DECISIONS.md "$T/.vid/dec"
sed 's#| replaced-by: D-003 |#| replaced-by: D-003, D-004 |#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = pass ] || fail 'extending a mark with a second id was refused'
sed 's#| replaced-by: D-003 |#| replaced-by: D-004 |#' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = refused ] || fail 'a mark that drops an id passed'
grep -q 'D-003' "$T/.vid/out" || fail 'the refusal does not name the dropped id'; by decisions-label
# a commit that deletes the line a mark names, no other line changed, leaves the mark naming nothing there: refused
sed '/^- \*\*D-003\*\*/d' "$T/.vid/dec" > DECISIONS.md
[ "$(hook)" = refused ] || fail 'deleting a line a mark names passed'
grep -q 'D-003' "$T/.vid/out" || fail 'the refusal does not name the deleted id'; by decisions-label
exit 0
