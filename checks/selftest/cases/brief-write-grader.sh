#!/bin/sh
# Purpose: selftest case — a grader brief written from a saved claim
# (v0.9.7.0.5 spec 3.3, R3, R6; §6 W-1). The brief-write fixture. Convicts
# unless `sh checks/brief.sh write --role grader --claim <file>`: quotes
# the claimed rows verbatim and leaves the held row out; lists the
# provisional rows; carries no "why=" although the claim has a
# `why=breached` line; quotes the grader's pass whole (its independence
# paragraph first) and the read exclusion; has no section 7 and no
# .vid/verdicts/ path; carries the owed sibling sharing a derived-from id,
# the owed hostility row whose `protects:` names a briefed row, and the
# legacy reversion in the withheld form (its reason absent), and not an
# unrelated owed row; carries the receipt's cases of the briefed rows, its
# deployed twin's included, and not another row's; quotes each joined
# decision's rule only; ends its header with the stamp; and the check
# says ok. A grader brief without --receipt is refused, writing nothing.
# v0.9.7.0.12 (3.5, R5): --receipt naming a close batch's ticket lists its
# two constituent receipts and the exclusion 'beyond the receipts named
# above', and a row's cases come only from the constituents crediting it
# (ROW-102's case in the receipt whose .rows leaves it out stays out); the
# check says ok. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-write-grader: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"
# owed siblings: ROW-110 shares REQ-002 with ROW-102; ROW-111, a legacy reversion, shares REQ-003; HOS-001 protects ROW-102; HOS-002 protects nothing briefed
awk '/^```$/ && !d { print "ROW-110 | behavior | REQ-002 | anonymous | n/a | a data: target is refused | REQ-002 | owed: prerequisite — paid at slice 9"
  print "ROW-111 | behavior | REQ-003 | anonymous | n/a | expiry holds across a restart | REQ-003 | owed: reverted — \"the resolver answered 302 after expiry\""
  print "hostility | HOS-001 | submit a file: target through the API; expect refusal and no file | protects: ROW-102 | disable: drop the scheme check | owed: guard-first — paid in slice 9"
  print "hostility | HOS-002 | resolve a deleted code; expect 404 | protects: REQ-009 | disable: skip the deletion mark | owed: guard-first — paid in slice 9"; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md
g commit -qam 'owed rows'; Q=$(git rev-parse HEAD); S=$(git rev-parse --short=12 HEAD)
mkdir -p .vid/ledger-results .vid/briefs/7
R=.vid/ledger-results/$S.close.xml
printf '<report/>\n' > "$R"; printf '<report/>\n' > "${R%.close.xml}.close.deployed.xml"
printf 'case tests/invariants/links.sh::test_create[ROW-101] passed 0.1\ncase tests/invariants/links.sh::test_scheme[ROW-102] passed 0.2\ncase tests/invariants/links.sh::test_token[ROW-104] passed 0.1\n' > "$R.cases"
printf 'case tests/invariants/links.sh::test_expiry[ROW-103] passed 0.3\n' > "${R%.close.xml}.close.deployed.xml.cases"
cat > .vid/briefs/7/claim.txt <<CL
claim row=ROW-101 why=unverdicted
claim row=ROW-102 why=breached
held row=ROW-104 reason=bound
claim row=ROW-103 why=re-paid
provisional row=ROW-103
claim rows=3 held=1 provisional=1 from=none to=$S.close.xml steps=S1
CL
bw_write --role grader --slice 7 --claim .vid/briefs/7/claim.txt --receipt "$S.close.xml" || fail 'the writer refused a well-formed grader brief'
B=$(bw_out); [ "$B" = .vid/briefs/7/grader-1.md ] && [ -f "$B" ] || fail "the brief is not .vid/briefs/7/grader-1.md: '$B'"
grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok'
for r in ROW-101 ROW-102 ROW-103; do grep -qxF -- "$(grep "^$r " INVENTORY.md)" "$B" || fail "claimed row $r not quoted verbatim"; done
grep -q 'ROW-104' "$B" && fail 'the held row ROW-104 travels (its row or its cases)'
grep -qx 'provisional: ROW-103' "$B" || fail 'the provisional row is not listed'
grep -qx 'claimed: 3 rows — ROW-101 ROW-102 ROW-103' "$B" || fail 'the claimed ids and their count are not listed'
grep -q 'why=' "$B" && fail 'a claim line reason (why=) travels into the grader brief'
grep -qF 'unverdicted' "$B" && fail "a claim line's reason travels"
tr '\n' '\001' < "$CLAUDE_PLUGIN_ROOT/skills/vid-verify/passes/grader.md" > "$T/gp"; tr '\n' '\001' < "$B" > "$T/bb"
grep -qF -- "$(cat "$T/gp")" "$T/bb" || fail 'the grader pass is not quoted whole'
[ "$(grep -cxF -- "$HDR" "$B")" -ge 1 ] || fail 'no independence paragraph'
grep -qxF -- "$EXCL" "$B" || fail 'no read exclusion'
grep -q '^## 7' "$B" && fail 'a grader brief carries section 7'
grep -v 'must not receive:' "$B" | grep -qF '.vid/verdicts/' && fail 'a grader brief names .vid/verdicts/'
grep -qxF -- "$(grep '^ROW-110 ' INVENTORY.md)" "$B" || fail 'the owed sibling by derived-from is absent'
grep -qxF -- "$(grep '^hostility | HOS-001 ' INVENTORY.md)" "$B" || fail 'the owed hostility row by protects: is absent'
grep -q 'HOS-002' "$B" && fail 'an unrelated owed hostility row travels'
grep -q '^ROW-105 ' "$B" && fail 'an unrelated owed row travels'
grep -qx 'ROW-111 | behavior | REQ-003 | anonymous | n/a | expiry holds across a restart | REQ-003 | owed: reverted — (detail withheld from graders)' "$B" || fail 'the legacy reversion is not in the withheld form'
grep -q 'the resolver answered' "$B" && fail 'the legacy reversion reason travels'
grep -qx 'case tests/invariants/links.sh::test_create\[ROW-101\] passed 0.1' "$B" || fail "the receipt's case of ROW-101 is absent"
grep -qx 'case tests/invariants/links.sh::test_expiry\[ROW-103\] passed 0.3' "$B" || fail "the deployed twin's case of ROW-103 is absent"
grep -qx -- '- A refusal stores nothing.' "$B" || fail 'GRADING-CHECKLIST.md is not quoted'
sed -n '/^## 3/,/^## 4/p' "$B" | grep -qF ' | why:' && fail 'a decision travels with its why'
sed -n '2,8p' "$B" | grep -qE '^written: brief\.sh write [0-9a-f]{40}$' || fail 'no stamp in the header'
grep -qx "quoted-at: $Q" "$B" || fail 'quoted-at is not HEAD'
grep -qx 'Graders request nothing.' "$B" || fail "section 6 does not say 'Graders request nothing.'"
# without --receipt: refused, nothing written
ls .vid/briefs/7 > "$T/before"
if bw_write --role grader --slice 7 --rows ROW-101; then fail 'a grader brief without --receipt was written'; fi
grep -qF 'names its receipt (--receipt)' "$T/wout" || fail 'the refusal does not name --receipt'
ls .vid/briefs/7 | cmp -s - "$T/before" || fail 'a refused brief left a file'
# a close batch's constituents, credited by the evidence reader
cp "$CHECKS/evidence.sh" checks/
BT=20260101T000000Z-ab12; mkdir -p ".vid/requests/$BT"; printf 'id=%s\n' "$BT" > ".vid/requests/$BT/batch"
CA=.vid/ledger-results/$S.run-20260101T000001Z-1.close.xml; CB=.vid/ledger-results/$S.run-20260101T000002Z-2.close.xml
for c in "$CA" "$CB"; do printf '<report/>\n' > "$c"; done
printf 'case tests/invariants/links.sh::test_create[ROW-101] passed 0.4\ncase tests/invariants/links.sh::test_scheme[ROW-102] passed 0.9\n' > "$CA.cases"; echo ROW-101 > "$CA.rows"
printf 'case tests/invariants/links.sh::test_scheme[ROW-102] passed 0.5\ncase tests/invariants/links.sh::test_expiry[ROW-103] passed 0.6\n' > "$CB.cases"; printf 'ROW-102\nROW-103\n' > "$CB.rows"
printf '1\t%s\tinline\n2\t%s\tinline\n' "$PWD/$CA" "$PWD/$CB" > ".vid/requests/$BT/receipts"
bw_write --role grader --slice 7 --claim .vid/briefs/7/claim.txt --receipt "$BT" || fail 'the writer refused a grader brief over a close batch'
B=$(bw_out); grep -q '^ViD brief: ok' "$T/wout" || fail "the check did not say ok on the batch's brief"
grep -qxF "receipts: close batch $BT — $CA · $CB" "$B" || fail 'the constituent receipts are not listed'
grep -qxF -- 'Do not read under `.vid/` beyond the receipts named above.' "$B" || fail "no read exclusion naming the batch's receipts"
grep -qx 'case tests/invariants/links.sh::test_create\[ROW-101\] passed 0.4' "$B" && grep -qx 'case tests/invariants/links.sh::test_scheme\[ROW-102\] passed 0.5' "$B" && grep -qx 'case tests/invariants/links.sh::test_expiry\[ROW-103\] passed 0.6' "$B" || fail "a crediting constituent's case is absent"
grep -q 'passed 0.9$' "$B" && fail 'a case from a constituent not crediting its row travels'
exit 0
