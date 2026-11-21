#!/bin/sh
# Purpose: selftest case — the team's changes to a ticket's tests (GM-1 S7). On the planner's toy in GitHub manual, three
# published tickets, their recorded writing and the read's bodies written by hand: #2 in the project's own form, its body
# naming ROW-012, which its writing does not, and no longer ROW-005, one of its rows; #3 posted in ViD's form, its body
# part 1 of its writing as writer.sh parts packs it, naming its regression rows and a record; #4 in the project's form,
# its body naming exactly its rows; #5 posted in ViD's form, holding ROW-019, which was removed from the inventory before
# the applied commit, so neither inventory holds it, and naming ROW-014, removed the same way, only in its regression rows,
# and quoting REQ-012 under its requirements; its body part 1 less the lines of ROW-019, ROW-014 and REQ-012.
# `next.sh changes` prints exactly `added 2 ROW-012 S02`, `dropped 2 ROW-005 S02`, `dropped 5 ROW-014
# S03` and `dropped 5 ROW-019 S03`, nothing about REQ-012, and nothing for #3 or #4; GM-2 §5: each line's fifth field its
# evidence hash. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-changes: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
pt_toy "$T/toy"; L19=$(grep '^ROW-019 ' INVENTORY.md); pt_del ROW-019; pt_del ROW-014; [ -n "$L19" ] && ! grep -q -e '^ROW-019 ' -e '^ROW-014 ' INVENTORY.md || fail 'ROW-019 and ROW-014 were not removed'
git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/round .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied
q() { for r; do printf '> %s\n- %s marks: none\n' "$(grep "^$r " INVENTORY.md)" "$r"; done; }
{ printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005,ROW-008 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-10T09:00:00Z\n'
  printf 'published 3 kind=step step=S03 rows=ROW-006,ROW-007 plan=p1 base=b1 export=e1 parts=1 taken-over=body at=2026-11-10T09:00:00Z\n'
  printf 'published 4 kind=step step=S04 rows=ROW-002,ROW-011 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-10T09:00:00Z\n'
  printf 'published 5 kind=step step=S03 rows=ROW-012,ROW-019 plan=p1 base=b1 export=e1 parts=1 taken-over=body at=2026-11-10T09:00:00Z\n'; } > .vid/tw/log
{ printf '# Step ticket S02\n\n## Header\n\n- rows: ROW-001 ROW-005 ROW-008\n\n## Rows\n\n'; q ROW-001 ROW-005 ROW-008; printf '\n## Regression rows\n\n- ROW-003: accepted\n'; } > .vid/tw/out/issue-2.md
{ printf '# Step ticket S03\n\n## Header\n\n- rows: ROW-006 ROW-007\n\n## Rows\n\n'; q ROW-006 ROW-007; printf '\n## Regression rows\n\n- ROW-003: accepted\n- ROW-004: accepted\n\n## Grading checklist and records\n\nThe records, deliberately not tested:\n\n> %s\n' "$(grep '^difference | DIF-003 ' INVENTORY.md)"; } > .vid/tw/out/issue-3.md
{ printf '# Step ticket S04\n\n## Header\n\n- rows: ROW-002 ROW-011\n\n## Rows\n\n'; q ROW-002 ROW-011; } > .vid/tw/out/issue-4.md
{ printf '# Step ticket S03\n\n## Header\n\n- rows: ROW-012 ROW-019\n\n## Rows\n\n'; q ROW-012; printf '> %s\n- ROW-019 marks: none\n\n## Requirements\n\n> %s\n\n## Regression rows\n\n- ROW-014: accepted\n' "$L19" "$(grep '^REQ-012 ' PRD.md)"; } > .vid/tw/out/issue-5.md
grep -q '^> REQ-012 |' .vid/tw/out/issue-5.md || fail "#5's writing does not quote REQ-012"
sh "$CHECKS/writer.sh" parts .vid/tw/out/issue-3.md 3 "$T/p3" > /dev/null || fail "#3's writing could not be packed"
sh "$CHECKS/writer.sh" parts .vid/tw/out/issue-5.md 5 "$T/p5" > /dev/null && grep -q 'ROW-019' "$T/p5/part-1.md" || fail "#5's writing could not be packed"
grep -q '^Ticket #3, part 1 of 1, writing ' "$T/p3/part-1.md" || fail "#3's part 1 does not open with its part line"
{ printf 'ticket\t2\tOPEN\t-\t2026-11-10T09:00:00Z\n'; printf 'body\t2\t%s\n' '## What to build' 'New jobs only, each listed once.' '## Tests' '- ROW-001' '- ROW-008' '- ROW-012, added by us'
  printf 'ticket\t3\tOPEN\t-\t2026-11-10T09:00:00Z\n'; while IFS= read -r l; do printf 'body\t3\t%s\n' "$l"; done < "$T/p3/part-1.md"
  printf 'ticket\t4\tOPEN\t-\t2026-11-10T09:00:00Z\n'; printf 'body\t4\t%s\n' '## Tests' '- ROW-002 and ROW-011'
  printf 'ticket\t5\tOPEN\t-\t2026-11-10T09:00:00Z\n'; grep -v -e 'ROW-019' -e 'ROW-014' -e 'REQ-012' "$T/p5/part-1.md" | while IFS= read -r l; do printf 'body\t5\t%s\n' "$l"; done; } > .vid/round/read
sh "$CHECKS/next.sh" changes > "$T/out" 2>&1 || fail 'next.sh changes failed'
printf 'added\t2\tROW-012\tS02\ndropped\t2\tROW-005\tS02\ndropped\t5\tROW-014\tS03\ndropped\t5\tROW-019\tS03\n' > "$T/want"
cut -f1-4 "$T/out" | sort | cmp -s - "$T/want" || fail "the changes are not exactly ROW-012 added to #2, ROW-005 dropped from it, and ROW-014 and ROW-019 dropped from #5"
awk -F'\t' 'NF != 5 || $5 !~ /^[0-9a-f]{40}$/ { f = 1 } END { exit f }' "$T/out" || fail 'a change has no evidence hash as its fifth field'
exit 0
