#!/bin/sh
# Purpose: selftest case — probes per clause (0.26.10.29.4, phase 3 R3, F11). A Tier-0 demand item protected by fewer
# hostility rows than its fail-if has arms makes checks/inventory.sh print `NOTE  REQ-012 — 3 arms, 1 probe …` and
# count it on the `inventory notes:` line (`arm-probes=<n>`, after `control-siblings=<n>` when both are printed). The
# arms are counted as checks/prd.sh splits them (a top-level " or ", "; or ", ", or "; an "or" inside parentheses is no
# split); the probes by 2d's reading (named, or through a protected rule's origin: or a protected ROW's derived-from).
# Three probes clear it; a one-arm item with one probe and a Tier-0 invariant print none. The NOTE is never OWED: the
# default run and --strict exit the same with it and without it. A literal tab inside an arm is part of the fail-if
# (0.26.10.29.4 phase 3 R3, review fix). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/p"; cd "$T/p"
GIT_CEILING_DIRECTORIES=$T; export GIT_CEILING_DIRECTORIES
fail() { echo "inventory-note-tier0-arm-probes: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
printf '```vid-placement\napp/\ntests/\n```\n' > CLAUDE.md
mkdir -p tests; for t in a b c r h1 h2 h3 h4 h9; do printf 'ROW RULE REQ INV HOS\n' > "tests/test_$t.py"; done
printf '# PRD\n\n```vid-prd\nREQ-012 | functional | T0 | consent mail | fail-if: a mail is sent with consent off, or the mail reaches another user (once or more); or the send is recorded twice\nREQ-013 | functional | T0 | one export | fail-if: the export holds another user'"'"'s rows\nINV-001 | invariant | T0 | erasures stay erased, or are never restored, or never exported\n```\n' > PRD.md
inv() { # $1: the extra lines
  printf '# Inventory\n\n```vid-inventory\nROW-001 | behavior | send | user | n/a | consent off: no mail is sent | REQ-012 | tests/test_a.py | proved-red: abc1234\nROW-002 | behavior | export | user | n/a | the export holds the user'"'"'s rows only | REQ-013 | tests/test_b.py | proved-red: abc1234\nROW-003 | behavior | erase | user | n/a | an erased record stays erased | INV-001 | tests/test_c.py | proved-red: abc1234\nrule | RULE-001 | every send reads consent | echo site-a | 1 | tests/test_r.py | proved-red: abc1234 | origin: REQ-012\nhostility | HOS-001 | send with consent off through the send form | protects: REQ-012 | disable: the consent check | tests/test_h1.py | proved-red: abc1234\nhostility | HOS-004 | export another user'"'"'s rows through the export link | protects: REQ-013 | disable: the owner filter | tests/test_h4.py | proved-red: abc1234\nhostility | HOS-009 | restore an erased record through the import | protects: INV-001 | disable: the erasure check | tests/test_h9.py | proved-red: abc1234\n%b```\n' "$1" > INVENTORY.md
}
run() { RC=0; sh "$CHECKS/inventory.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
NOTE='NOTE  REQ-012 — 3 arms, 1 probe'
# 1. three arms, one probe: the NOTE and its count
inv ''
run; D1=$RC
grep -q "^$NOTE" "$T/out" || fail "the default run printed no '$NOTE' NOTE"
[ "$(grep -c '^NOTE  ' "$T/out")" = 1 ] || fail 'not exactly one NOTE (REQ-013 has one arm and one probe; INV-001 is an invariant)'
grep -qx 'inventory notes: arm-probes=1' "$T/out" || fail 'the NOTE is not counted as arm-probes=1 on the notes line'
grep -q '^OWED  REQ-012' "$T/out" && fail 'the NOTE was made OWED'
run --strict; S1=$RC; grep -q "^$NOTE" "$T/out" || fail '--strict printed no NOTE'
run --report; grep -q "^$NOTE" "$T/out" || fail '--report printed no NOTE'
# 2. beside a control-sibling NOTE: one notes line, control-siblings first
inv 'hostility | HOS-005 | send to a stranger through the send form | protects: ROW-002 | disable: the owner filter | tests/test_h2.py | proved-red: abc1234\n'
run; grep -qx 'inventory notes: control-siblings=1 arm-probes=1' "$T/out" || fail 'the two counts are not one notes line, control-siblings first'
# 3. three probes, by name, through a rule's origin: and through a ROW's derived-from: no NOTE, no count
inv 'hostility | HOS-002 | send through the batch job to another user | protects: RULE-001 | disable: the consent check | tests/test_h2.py | proved-red: abc1234\nhostility | HOS-003 | resend through the retry link | protects: ROW-001 | disable: the send record | tests/test_h3.py | proved-red: abc1234\nROW-004 | behavior | send | user | n/a | control of ROW-001: consent on: exactly one mail is sent | REQ-012 | tests/test_a.py | proved-red: abc1234\n'
run; D2=$RC
grep -q '^NOTE  ' "$T/out" && fail 'a NOTE stayed with three probes for three arms'
grep -q '^inventory notes:' "$T/out" && fail 'the notes line stayed with nothing to count'
run --strict; S2=$RC
[ "$D1" = "$D2" ] || fail "the default run exits $D1 with the NOTE and $D2 without it"
[ "$S1" = "$S2" ] || fail "--strict exits $S1 with the NOTE and $S2 without it"
[ "$S1" = 0 ] || fail "--strict refused a fixture whose only finding is the NOTE ($S1)"
# 4. a literal tab inside an arm is part of the fail-if: still three arms, one probe, the NOTE
printf '# PRD\n\n```vid-prd\nREQ-012 | functional | T0 | consent mail | fail-if: a mail\tis sent with consent off, or the mail reaches another user; or the send is recorded twice\nREQ-013 | functional | T0 | one export | fail-if: the export holds another rows\n```\n' > PRD.md
inv ''
run; grep -q "^$NOTE" "$T/out" || fail 'a tab inside an arm cut the fail-if: no NOTE for three arms and one probe'
echo 'inventory-note-tier0-arm-probes: ok'
