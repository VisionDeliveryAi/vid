#!/bin/sh
# Purpose: selftest case — a test-author brief names a rule row (FIX-BATCH-T1 §2, B-2). The brief-write fixture with three
# rule rows (RULE-001 from REQ-004). Convicts unless `sh checks/brief.sh write --role test-author`: given ROW-101 and
# RULE-001, quotes ROW-101 in section 1 and RULE-001's line verbatim in section 11 (never section 1), quotes RULE-001's
# origin item REQ-004 in section 2 and lists both ids in section 6's request, and the check says ok; given RULE-001 alone,
# writes a brief the check passes; given a rule row born in the working tree, quotes it from there, listed pending-birth:.
# The brief with its `written:` stamp removed passes the check, and the same copy with its section 11 line changed by one
# character is refused, naming section 11. A grader brief naming RULE-001 is refused. And in a gated run, a prove-red
# request for RULE-001 alone is accepted, its rows file holding RULE-001. FIX-BATCH-T1 §15: a hostility row (HOS-001,
# protecting REQ-004) takes the same path — section 11, its protects: item, section 6, the check, an altered line refused naming
# section 11, a grader refused, a prove-red request for it alone accepted. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-write-rule-row: $*" >&2; cat "$T/wout" "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"
R1='rule | RULE-001 | a deletion never succeeds without the token | checks/extractors/invariant.token.sh | 0 | owed: census-armed — armed with the first deletion site | origin: REQ-004'
R2='rule | RULE-002 | every store write is atomic | checks/extractors/invariant.atomic.sh | 0 | owed: census-armed — armed with the first write | origin: REQ-001'
awk -v r="$R1" '/^```$/ && !d { print r; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md
g commit -qam 'a rule row'
sect() { awk -v n="$1" '/^## [0-9]/ { on = ($2 == n); next } on' "$2"; }
REQ4=$(sh checks/prd.sh --effective PRD.md | grep '^REQ-004 ')
# a row and a rule row
bw_write --role test-author --slice 1 --rows ROW-101,RULE-001 || fail 'the writer refused a test-author brief naming a rule row'
A=$(bw_out)
sect 1 "$A" | grep -q '^ROW-101 |' || fail 'section 1 lacks ROW-101'
sect 1 "$A" | grep -q 'RULE-001' && fail 'the rule row is quoted in section 1'
sect 11 "$A" | grep -qxF -- "$R1" || fail 'section 11 does not quote RULE-001 verbatim'
sect 2 "$A" | grep -qxF -- "$REQ4" || fail "section 2 lacks RULE-001's origin item REQ-004"
grep -qx 'sh checks/test.sh request --type prove-red --role test-author --rows ROW-101,RULE-001 --why "<one line>" -- <selection>' "$A" || fail 'section 6 does not list both ids'
sh checks/brief.sh "$A" > "$T/out" 2>&1 || fail 'the check refused the written brief'
# the rule row alone
bw_write --role test-author --slice 1 --rows RULE-001 || fail 'the writer refused a brief naming a rule row alone'
B=$(bw_out)
sect 11 "$B" | grep -qxF -- "$R1" || fail 'a rule row alone: section 11 does not quote it'
sh checks/brief.sh "$B" > "$T/out" 2>&1 || fail 'the check refused a brief naming a rule row alone'
# stamp removed: passes; one character changed in section 11: refused, naming section 11
grep -v '^written: ' "$B" > "$T/nostamp.md"
sh checks/brief.sh "$T/nostamp.md" > "$T/out" 2>&1 || fail 'the unstamped copy was refused'
sed 's/^rule | RULE-001 | a deletion never succeeds/rule | RULE-001 | a deletion never succeedz/' "$T/nostamp.md" > "$T/altered.md"
cmp -s "$T/nostamp.md" "$T/altered.md" && fail 'the alteration did not change the brief'
if sh checks/brief.sh "$T/altered.md" > "$T/out" 2>&1; then fail 'an altered section 11 line passed the check'; fi
grep -q 'section 11' "$T/out" || fail 'the refusal does not name section 11'
# a rule row born in the working tree
awk -v r="$R2" '/^```$/ && !d { print r; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md
bw_write --role test-author --slice 1 --rows RULE-002 || fail 'the writer refused a rule row born in the working tree'
C=$(bw_out)
grep -qx 'pending-birth: RULE-002' "$C" || fail 'the working-tree rule row is not listed pending-birth:'
sect 11 "$C" | grep -qxF -- "$R2" || fail 'the working-tree rule row is not quoted from the working tree'
sh checks/brief.sh "$C" > "$T/out" 2>&1 || fail 'the check refused the pending-birth rule row'
git checkout -q -- INVENTORY.md
# an indented rule line, as inventory.sh reads it: quoted verbatim, the check ok
sed 's/^rule | RULE-001 |/  rule | RULE-001 |/' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'the rule row indented'
bw_write --role test-author --slice 1 --rows RULE-001 || fail 'the writer refused an indented rule row'
E=$(bw_out); sect 11 "$E" | grep -qxF -- "  $R1" || fail 'the indented rule row is not quoted verbatim'
sh checks/brief.sh "$E" > "$T/out" 2>&1 || fail 'the check refused an indented rule row'
# a hostility row (FIX-BATCH-T1 §15): the same path — section 11 verbatim, its protects: item in section 2, the check
H1='hostility | HOS-001 | Delete with a wrong token; expect the refusal and the link kept | protects: REQ-004 | disable: skip the token check in delete | owed: guard-first — paid with the deletion slice'
awk -v r="$H1" '/^```$/ && !d { print r; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'a hostility row'
bw_write --role test-author --slice 1 --rows HOS-001 || fail 'the writer refused a test-author brief naming a hostility row'
P=$(bw_out)
sect 11 "$P" | grep -qxF -- "$H1" || fail 'section 11 does not quote HOS-001 verbatim'
sect 1 "$P" | grep -q 'HOS-001' && fail 'the hostility row is quoted in section 1'
sect 2 "$P" | grep -qxF -- "$REQ4" || fail "section 2 lacks HOS-001's protects: item REQ-004"
grep -qx 'sh checks/test.sh request --type prove-red --role test-author --rows HOS-001 --why "<one line>" -- <selection>' "$P" || fail 'section 6 does not list HOS-001'
sh checks/brief.sh "$P" > "$T/out" 2>&1 || fail 'the check refused the hostility brief'
grep -v '^written: ' "$P" > "$T/hnostamp.md"
sh checks/brief.sh "$T/hnostamp.md" > "$T/out" 2>&1 || fail 'the unstamped hostility brief was refused'
sed 's/expect the refusal and the link kept/expect the refusal and the link gone/' "$T/hnostamp.md" > "$T/haltered.md"
cmp -s "$T/hnostamp.md" "$T/haltered.md" && fail 'the hostility alteration did not change the brief'
if sh checks/brief.sh "$T/haltered.md" > "$T/out" 2>&1; then fail 'an altered section 11 hostility line passed the check'; fi
grep -q 'section 11' "$T/out" || fail 'the hostility refusal does not name section 11'
# another role: refused as today
mkdir -p .vid/ledger-results; S=$(git rev-parse --short=12 HEAD); printf '<report/>\n' > ".vid/ledger-results/$S.full.xml"
bw_write --role grader --slice 1 --rows ROW-101 --receipt "$S.full.xml" || fail 'the control: the writer refused a grader brief on a row'
if bw_write --role grader --slice 1 --rows RULE-001 --receipt "$S.full.xml"; then fail 'a grader brief took a rule row'; fi
grep -q 'RULE-001 is a rule row' "$T/wout" || fail 'the grader refusal does not name RULE-001 as a rule row'
if bw_write --role grader --slice 1 --rows HOS-001 --receipt "$S.full.xml"; then fail 'a grader brief took a hostility row'; fi
grep -q 'HOS-001 is a hostility row' "$T/wout" || fail 'the grader refusal does not name HOS-001 as a hostility row'
# a prove-red request for a rule row alone, in a gated run
. "$CHECKS/selftest/fixtures/gated-run.sh"; . "$CHECKS/selftest/fixtures/plan-run.sh"
plan_repo "$T/g"; rows s1 1 1
awk -v r="$R1" '/^```$/ && !d { print r; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md
printf 'def test_rule(): pass  # RULE-001\n' >> tests/invariants/test_s1.py; commit_all 'a rule row'
sh checks/test.sh request --type prove-red --role test-author --rows RULE-001 --why 'the rule test' -- tests/invariants/test_s1.py > "$T/out" 2>&1 || fail 'a prove-red request for a rule row alone was refused'
K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
grep -qx 'RULE-001' ".vid/requests/$K/rows" || fail "the request's rows do not hold RULE-001"
VID_WAIT_MAX=60 sh checks/test.sh wait "$K" > "$T/out" 2>&1 || true
sh checks/test.sh request --type prove-red --role test-author --rows HOS-001 --why 'the probe' -- tests/invariants/test_s1.py > "$T/out" 2>&1 || fail 'a prove-red request for a hostility row alone was refused'
K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
grep -qx 'HOS-001' ".vid/requests/$K/rows" || fail "the request's rows do not hold HOS-001"
VID_WAIT_MAX=60 sh checks/test.sh wait "$K" > "$T/out" 2>&1 || true
exit 0
