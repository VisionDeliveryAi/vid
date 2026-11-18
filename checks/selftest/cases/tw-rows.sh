#!/bin/sh
# Purpose: selftest case — regression and faulted rows, W5 and F12's ticket half (v0.26.10.12.3
# R4). On TW's toy, ROW-012 re-ratified as a row of a bug finding and ROW-030 added to S04. S02's ticket
# faults ROW-005's lowest transition and HOS-001 with its disable: note, never the deploy-owed SEAM-002 or DIF-002. With
# the stand-in's row states for S02, S03's ticket lists exactly the accepted golden-path rows (ROW-003, ROW-004), the
# journey ROW-005, HOS-001 (fault proven) and ROW-012 (a bug finding) as regression rows — never an accepted plain row,
# an accepted-by-ruling plain row, a failing or held row, or a deploy-owed row — and faults exactly HOS-002, HOS-004 and
# HOS-005, each with its disable: note, never ROW-010 (deploy-owed, a multiple of ten) or SEAM-001. After ROW-005 is
# ruled a known limit and S03's shell and reachability rows are accepted, S04's ticket lists ROW-006 and ROW-007 and not
# ROW-005, and faults HOS-003 and ROW-030 (a multiple of ten), never ROW-009, ROW-011 or DIF-001 (deploy-owed). Env:
# CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-rows: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh
sed 's/^\(ROW-012 .*\)| origin: domain volume$/\1| origin: finding bug 2026-11-02/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
awk '{ print } /^ROW-020 / { print "ROW-030 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day, or a day no digest went out. | REQ-001 | owed: spec-only — first stage | origin: REQ-001" }' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
pt_rs 's/^\(step S04 .*rows: .*\)RULE-004 /\1RULE-004 ROW-030 /'; pt_after 'step S05' 'needs ROW-030 | -'
sh "$CHECKS/plan.sh" change rows 'ROW-030 into S04' --trigger scope-change --evidence step:S04 --expect 'S04 holds it' > "$T/out" 2>&1 || fail 'ROW-030 was not recorded'
g commit -qam 'ROW-012 from a bug finding; ROW-030'; tw_ratify 'Yes, with ROW-030' || fail 'the toy was not ratified again'
grep -q '^ROW-012 .*origin: finding bug' INVENTORY.md && grep -q 'ROW-030' .vid/RUN-STATE.md || fail 'the plants did not land'
tw_skel || fail 'the skeleton round failed'
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1" | grep -v '^[[:space:]]*$' || true; }
ids() { sec "$1" "$2" | sed -n 's/^- \([A-Z]*-[0-9T-]*\)[: ].*/\1/p; s/^- \([A-Z]*-[0-9T-]*\)$/\1/p' | paste -sd ' ' -; }
tw_start S02 || fail 'S02 was refused'; tw_post step S02 || fail "S02's ticket was refused"; P2=$TW_F
[ "$(ids "$P2" 'Faulted rows')" = 'ROW-005-T1 HOS-001' ] || fail "S02 faults $(ids "$P2" 'Faulted rows')"
sec "$P2" 'Faulted rows' | grep -qx '> disable: remove the merge by source id from the ingest' || fail "HOS-001's fault does not show its disable: note"
for r in 'ROW-001 accepted' 'ROW-005 accepted' 'ROW-008 accepted-by-ruling' 'ROW-012 accepted' 'ROW-013 accepted' 'HOS-001 accepted fault-proven' 'SEAM-002 owed' 'DIF-002 owed' 'ROW-015 failing' 'ROW-016 held' 'RULE-005 accepted'; do tw_hand "row $r"; done
tw_closed S02 owed; tw_close "$TW_N"; sh "$GS" tw-sync > /dev/null 2>&1
tw_start S03 || fail 'S03 was refused'; tw_post step S03 || fail "S03's ticket was refused"; P3=$TW_F
[ "$(ids "$P3" 'Regression rows')" = 'ROW-003 ROW-004 ROW-005 ROW-012 HOS-001 RULE-005' ]   # v0.26.10.26.4 (R5): the accepted rule row too || fail "S03's regression rows are $(ids "$P3" 'Regression rows')"
[ "$(ids "$P3" 'Faulted rows')" = 'HOS-002 HOS-004 HOS-005' ] || fail "S03 faults $(ids "$P3" 'Faulted rows')"
[ "$(sec "$P3" 'Faulted rows' | grep -c '^> disable: ')" = 3 ] || fail "S03's protection rows do not each show their disable: note"
for r in 'ROW-006 accepted' 'ROW-007 accepted' 'ROW-005 known-limit'; do tw_hand "row $r"; done
tw_closed S03 owed; tw_close "$TW_N"; sh "$GS" tw-sync > /dev/null 2>&1
tw_hand 'row ROW-015 held'   # 0.26.10.29.2 (R9): S04 builds on S02, which waits while its ROW-015 is failing; held, it is settled (and no regression row)
tw_start S04 || fail 'S04 was refused'; tw_post step S04 || fail "S04's ticket was refused"; P4=$TW_F
[ "$(ids "$P4" 'Regression rows')" = 'ROW-003 ROW-004 ROW-006 ROW-007 ROW-012 HOS-001 RULE-005' ] || fail "S04's regression rows are $(ids "$P4" 'Regression rows')"
[ "$(ids "$P4" 'Faulted rows')" = 'ROW-030 HOS-003' ] || fail "S04 faults $(ids "$P4" 'Faulted rows')"
exit 0
