#!/bin/sh
# Purpose: selftest case — a test-author brief written for a fix
# (v0.9.7.0.5 spec 3.3, 3.4; §6 W-4). The brief-write fixture. Convicts
# unless `sh checks/brief.sh write --role test-author`: puts in section 7
# only each row's latest class=test block of its attempt record; quotes a
# row born after HEAD from the working tree, listed pending-birth:; quotes
# a new and an amended item from the working tree's effective set, listed
# pending-append: — as enriched rows, and again as legacy `### REQ-`
# blocks; lists in section 6 the role's request form with its rows filled
# in; and the check says ok. The same legacy blocks without the
# pending-append: listing (an unstamped copy) are refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-write-test-author: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"
mkdir -p .vid/verdicts
cat > .vid/verdicts/ROW-102.md <<'AR'
# ROW-102 — attempt record

## slice 5 · brief .vid/briefs/5/grader-1.md

BREACHED class=product: ftp:// accepted and stored (app/links.sh:12)

## slice 5 · brief .vid/briefs/5/grader-2.md

BREACHED class=test: the old test asserts the refusal message only

## slice 6 · brief .vid/briefs/6/grader-1.md

BREACHED class=test: the test never looks for a stored file after a refusal

## slice 6 · brief .vid/briefs/6/grader-2.md

BREACHED class=product: a mixed-case scheme slips through (app/links.sh:14)
AR
# the working tree: a row born after HEAD, a new item it derives from, and an amended item
awk '/^```$/ && !d { print "ROW-109 | behavior | REQ-030 | anonymous | n/a | a deletion answers within a second | REQ-030 | owed: prerequisite — paid at slice 9"; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md
printf '\n```vid-prd\nREQ-002 AMENDED | functional | T0 | Only web addresses are accepted as targets, in any letter case. | fail-if: a target whose scheme is not http or https, in any case, is accepted | serves: trust — a short link never hides a script or a local file | phase: pilot\nREQ-030 | functional | T1 | Deletion answers within a second. | fail-if: a deletion takes longer | serves: trust | phase: pilot\n```\n' >> PRD.md
eff() { sh checks/prd.sh --effective PRD.md | grep "^$1 "; }
bw_write --role test-author --slice fix-2026-10-02 --rows ROW-102,ROW-109 || fail 'the writer refused a well-formed test-author brief'
A=$(bw_out)
grep -qx 'pending-birth: ROW-109' "$A" || fail 'the row born after HEAD is not listed pending-birth:'
grep -qxF -- "$(grep '^ROW-109 ' INVENTORY.md)" "$A" || fail 'the row born after HEAD is not quoted from the working tree'
grep -qx 'pending-append: REQ-002 REQ-030' "$A" || fail 'the new and the amended item are not listed pending-append:'
for r in REQ-002 REQ-030; do grep -qxF -- "$(eff $r)" "$A" || fail "item $r is not quoted from the working tree's effective set"; done
sed -n '/^## 7/,/^## 8/p' "$A" > "$T/s7"
grep -qF 'the test never looks for a stored file' "$T/s7" || fail 'section 7 lacks the latest class=test block'
grep -qF 'the old test asserts' "$T/s7" && fail 'section 7 carries an older class=test block'
grep -qF 'class=product' "$T/s7" && fail 'section 7 carries a product block'
grep -qx 'sh checks/test.sh request --type prove-red --role test-author --rows ROW-102,ROW-109 --why "<one line>" -- <selection>' "$A" || fail 'section 6 is not the request form with the rows filled in'
grep -qxF -- "$HDR" "$A" || fail 'no independence paragraph'
grep -qF '*A promise is proved at the' "$A" || fail 'section 8 lacks the boundary rule'
git checkout -q -- PRD.md INVENTORY.md
# legacy blocks: a committed legacy PRD; in the working tree REQ-003 amended and REQ-030 new
printf '# Linkling\n\n### REQ-002 (T0) — web targets only\nOnly web addresses are accepted.\n**Fail-if:** a target whose scheme is not http or https is accepted.\n\n### REQ-003 (T1) — expiry\nThirty days.\n**Fail-if:** an old link redirects.\n\n## Appends\n' > PRD.md
awk '/^```$/ && !d { print "ROW-112 | behavior | REQ-030 | anonymous | n/a | a deletion answers within a second | REQ-030 | owed: prerequisite — paid at slice 9"; d = 1 } { print }' INVENTORY.md > i && mv i INVENTORY.md
g commit -qam 'legacy PRD, ROW-112'
printf '\n### REQ-003 (T1) — expiry, to the second\nThirty days to the second.\n**Fail-if:** an old link redirects, or expiry drifts at a boundary.\n\n### REQ-030 (T1) — deletion speed\nDeletion answers within a second.\n**Fail-if:** a deletion takes longer.\n' >> PRD.md
bw_write --role test-author --slice fix-2026-10-02 --rows ROW-103,ROW-112 || fail 'the writer refused a test-author brief with legacy blocks'
L=$(bw_out)
grep -qx 'pending-append: REQ-003 REQ-030' "$L" || fail 'the legacy blocks are not listed pending-append:'
grep -qx '### REQ-003 (T1) — expiry, to the second' "$L" && grep -qx '\*\*Fail-if:\*\* an old link redirects, or expiry drifts at a boundary\.' "$L" || fail 'the amended legacy block is not quoted from the working tree'
grep -qx '### REQ-030 (T1) — deletion speed' "$L" || fail 'the new legacy block is not quoted'
# the same blocks without the listing (an unstamped copy) are refused
grep -v -e '^pending-append:' -e '^written: ' "$L" > "$T/unlisted.md"
if sh checks/brief.sh "$T/unlisted.md" > "$T/out" 2>&1; then fail 'legacy working-tree blocks without pending-append: were accepted'; fi
grep -qF "item block '### REQ-003 (T1) — expiry, to the second'" "$T/out" && grep -qF 'list it pending-append:' "$T/out" || { cat "$T/out" >&2; fail 'the refusal does not name the block and the listing'; }
grep -qF "item block '### REQ-030" "$T/out" || fail 'the new block is not named'
exit 0
