#!/bin/sh
# Purpose: selftest case — census subjects without whitespace, for new
# rows (v0.9.7.0.11 spec 3.10, R10). An exception row whose subject holds
# a space, already in HEAD's INVENTORY.md, is a note on the census line
# and the census passes. A new one — an exception or a suppression — is
# refused, naming it (--report still exits 0); so is the existing one
# changed. A new exception with a one-word subject passes. With no rule
# row and no extractor (the census otherwise inactive), a new `seam`
# exception with a space is still refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; git init -q; mkdir -p tests/invariants; touch tests/invariants/test_r.py
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "census-subject-space: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
inv() { { printf '# toy\n```vid-inventory\n'; for _l in "$@"; do printf '%s\n' "$_l"; done; printf '```\n'; } > INVENTORY.md; }
R='rule | RULE-901 | every site guarded | printf '"'"'a\n'"'"' :: printf '"'"'a\n'"'"' | T1 | tests/invariants/test_r.py'
OLD='exception | EXC-001 | two words | RULE-901 | a row from before'
inv "$R" "$OLD"; g add -A; g commit -qm root
census() { sh "$CHECKS/census.sh" "$@" > "$T/out" 2>&1; }
census || fail 'an existing exception with a space in its subject blocked the census'
grep -q "^census: .* · note: exception EXC-001's subject has whitespace" "$T/out" || fail 'the existing row is not a note on the census line'
inv "$R" "$OLD" 'exception | EXC-002 | a new one | RULE-901 | new'
if census; then fail 'a new exception with a space in its subject passed'; fi
grep -q "rejected — exception EXC-002's subject has whitespace, which no orphan's subject can carry" "$T/out" || fail 'the refusal does not name EXC-002'
census --report || fail '--report did not exit 0'
inv "$R" "$OLD" 'suppression | SUP-001 | a new one | RULE-901 | gap | later'
if census; then fail 'a new suppression with a space in its subject passed'; fi
grep -q "suppression SUP-001's subject" "$T/out" || fail 'the refusal does not name SUP-001'
inv "$R" 'exception | EXC-001 | two words | RULE-901 | a row from before, reworded'
if census; then fail 'the existing exception, changed, passed'; fi
inv "$R" "$OLD" 'exception | EXC-003 | oneword | RULE-901 | new'
census || fail 'a new exception with a one-word subject was refused'
inv 'exception | EXC-004 | cdn example.org | seam | a content link'
if census; then fail 'a new seam exception with a space passed while the census is otherwise inactive'; fi
exit 0
