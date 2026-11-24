#!/bin/sh
# Purpose: selftest case — the count of what is not yet with the team (GM-1 S8, N8). On the planner's toy in GitHub manual,
# its spec committed as the applied version (ROW-012 and ROW-015 first given a pointer into ViD's records), tickets #1
# (S01), #2 (S02) and #3 (S03) published with all their steps' rows, #2's writing quoting ROW-013 and HOS-001 as the writer
# cuts them (no test path, no proved-red:) and ROW-012 and ROW-015 with "(ViD's records)" for their pointers, #3's quoting
# ROW-006. Then: ROW-002 and ROW-018 out of S04 and on the to-place list, ROW-018 also restated; ROW-006 on the list as of
# another stage, though in #3; ROW-021 added to S04; ROW-019 removed, and the known limit ROW-009 and the later-phase ROW-020
# removed too; ROW-013 and ROW-011 restated; ROW-012's pointer replaced by REQ-002. One row of each kind
# is counted once, under its first kind: to place ROW-002 and ROW-018 (reset, counted only as to place), added ROW-021,
# retired ROW-019, restated ROW-013 and ROW-012 (quoted differently in #2), reset ROW-011, and unpublished HOS-003, DIF-001,
# RULE-004 (S04) and ROW-017 (S05): eleven in all. ROW-006 is not counted and is listed as a stage to correct; ROW-015 and
# HOS-001 are not counted; the known limit ROW-009 and the later-phase ROW-020, retired, and the record DIF-003 are not
# counted (F4). `triggers` changes no file of the project, ViD's records included (F7). GM-3 U6: its planning-analysis line names INVENTORY.md, uncommitted, as differing from HEAD (replan.sh ready). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-count: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"
sed -e 's/^\(ROW-012 .*\)| origin: domain volume$/\1| origin: domain volume, see .vid\/plan\/review/' -e 's/^\(ROW-015 .*\)| origin: REQ-005 cross-cutting$/\1| origin: REQ-005 cross-cutting, see .vid\/plan\/review/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
[ "$(grep -c 'see \.vid/plan/review$' INVENTORY.md)" = 2 ] || fail 'the pointers did not land'
git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/round .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied
srows() { sed -n "s/^step $1 .*rows: \([^|]*\)|.*/\1/p" .vid/RUN-STATE.md | sed 's/RULE-001\.\.RULE-003/RULE-001 RULE-002 RULE-003/' | tr -s ' ' ',' | sed 's/^,//;s/,$//'; }
{ printf 'published 1 kind=skeleton step=S01 rows=%s plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-10T09:00:00Z\n' "$(srows S01)"
  printf 'published 2 kind=step step=S02 rows=%s plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-10T09:00:00Z\n' "$(srows S02)"
  printf 'published 3 kind=step step=S03 rows=%s plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-10T09:00:00Z\n' "$(srows S03)"; } > .vid/tw/log
grep -q 'rows=ROW-006,.*,ROW-019,RULE-001,RULE-002,RULE-003,' .vid/tw/log || fail "the log does not hold S03's rows"
printf '# Skeleton ticket S01\n\n## Rows\n\n> %s\n' "$(grep '^ROW-003 ' INVENTORY.md)" > .vid/tw/out/issue-1.md
{ printf '# Step ticket S02\n\n## Rows\n\n'
  printf '> %s\n' "$(grep '^ROW-013 ' INVENTORY.md | sed 's# | tests/invariants/test_feed_repeat.py | proved-red: 1a2b3c4##')"
  printf '> %s\n' "$(grep '^hostility | HOS-001 ' INVENTORY.md | sed 's# | tests/invariants/test_hostility_dupes.py | proved-red: 5e6f7a8$##')"
  printf '> %s\n' "$(grep '^ROW-012 ' INVENTORY.md | sed "s#\.vid/plan/review#(ViD's records)#")"
  printf '> %s\n' "$(grep '^ROW-015 ' INVENTORY.md | sed "s#\.vid/plan/review#(ViD's records)#")"; } > .vid/tw/out/issue-2.md
printf '# Step ticket S03\n\n## Rows\n\n> %s\n' "$(grep '^ROW-006 ' INVENTORY.md)" > .vid/tw/out/issue-3.md
grep -q 'proved-red' .vid/tw/out/issue-2.md && fail "#2's writing still holds proved-red"
grep -q "(ViD's records)" .vid/tw/out/issue-2.md || fail "#2's writing holds no replaced pointer"
pt_rs 's/^\(step S04 .*rows:\) ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 /\1 ROW-009 ROW-011 ROW-021 HOS-003 /'; grep -q '^step S04 .*rows: ROW-009 ROW-011 ROW-021 HOS-003 ' .vid/RUN-STATE.md || fail 'S04 was not changed'
pt_after ROW-020 'ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day, or a day no digest went out. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
pt_del ROW-019; pt_del ROW-009; pt_del ROW-020
sed 's/^\(ROW-012 .*\)see \.vid\/plan\/review$/\1see REQ-002/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
grep -q '^ROW-012 .*see REQ-002$' INVENTORY.md && ! grep -q -e '^ROW-009 ' -e '^ROW-020 ' INVENTORY.md || fail "ROW-012's pointer was not replaced, or ROW-009 and ROW-020 not removed"
sed -e 's/^\(ROW-013 .*\)leaves the listings as one read does/\1leaves the listings exactly as one read does/' -e 's/^\(ROW-011 .*\)are backed up daily/\1are backed up twice a day/' -e 's/^\(ROW-018 .*\)is in the operator.s log/\1is in the operator log within the hour/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
[ "$(grep -c -e 'exactly as one read' -e 'twice a day' -e 'operator log within the hour' INVENTORY.md)" = 3 ] || fail 'the restatements did not land'
printf 'ROW-002 no-step 2026-11-19T09:00:00Z yes, place them later\nROW-018 no-step 2026-11-19T09:00:00Z yes, place them later\nROW-006 other-stage 2026-11-19T09:00:00Z yes, place them later\n' > .vid/tw/to-place
printf 'row ROW-009 known-limit | stand-in: the self-test\n' > .vid/tw/handed
printf 'ticket\t1\tCLOSED\t-\t2026-11-10T09:00:00Z\nticket\t2\tOPEN\t-\t2026-11-10T09:00:00Z\nticket\t3\tOPEN\t-\t2026-11-10T09:00:00Z\n' > .vid/round/read
sums() { find . -type f -exec cksum {} + | sort; }   # .git too
sums > "$T/before"
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
sums > "$T/after"; cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" >&2 || true; fail 'next.sh triggers changed a file of the project'; }
# GM-3 U6: triggers reads replan.sh ready, whose analysis reads HEAD: the working tree's uncommitted INVENTORY.md is named, and
# reading it wrote nothing (above, .git/index included)
grep -q "^move${TB}planning-analysis${TB}.*replan.sh ready refused: refused — the spec files in the working tree differ from HEAD's (INVENTORY.md)" "$T/out" || fail "planning-analysis does not say ready refused, naming INVENTORY.md as differing from HEAD"
awk -F'\t' '$1 == "counted" { print $2, $3 }' "$T/out" | sort > "$T/got"
printf '%s\n' 'added ROW-021' 'reset ROW-011' 'restated ROW-012' 'restated ROW-013' 'retired ROW-019' 'to-place ROW-002' 'to-place ROW-018' 'unpublished DIF-001' 'unpublished HOS-003' 'unpublished ROW-017' 'unpublished RULE-004' > "$T/want"
cmp -s "$T/got" "$T/want" || fail "counted $(paste -sd ' ' "$T/got" | tr ' ' ' '), not one row of each kind as planted"
for l in 'total 11' 'to-place 2' 'added 1' 'retired 1' 'restated 2' 'reset 1' 'unpublished 4'; do grep -q "^count${TB}${l% *}${TB}${l#* }\$" "$T/out" || fail "no count line: $l"; done
grep -q "^quiet${TB}minor${TB}stage-to-correct${TB}ROW-006${TB}" "$T/out" || fail 'ROW-006, to place and in #3, is not counted as a stage to correct (FB-3 C5: minor, the owner accepted it)'
exit 0
