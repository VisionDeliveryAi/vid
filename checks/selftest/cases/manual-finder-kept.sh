#!/bin/sh
# Purpose: selftest case — the finder of team changes against the kept body and the answers (GM-2 T5, T7; §5), outside the
# spec's 29. On the planner's toy in GitHub manual, ticket #2 (S02) quotes ROW-001 and ROW-005; its kept body
# (.vid/tw/body/issue-2) holds ROW-001, ROW-005 and ROW-008, named at an earlier post; ROW-021 is added to the working
# tree's inventory after the applied commit. The body as GitHub holds it names ROW-001, ROW-012, ROW-013, ROW-006 and
# ROW-021. The hand-written .vid/next/team-answers holds a `no` to ROW-013 added with its evidence, a `no` to ROW-012 with
# other evidence, a `yes` to ROW-008 dropped with the body's hash, and a `moved` line for ROW-006. `next.sh changes` prints
# exactly: added ROW-012 (step S02) and ROW-021 (pending-only), each with the hash of the body lines naming it; dropped ROW-005
# with the hash of the whole body. `triggers` names each change's move `team-change #2 <id>` with a hash, ROW-021's reading
# `a yes comes in through planning-analysis and implement-replan; needs no, and your words`. Once the body line naming ROW-013 changes, ROW-013 is printed again. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "manual-finder-kept: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/round .vid/tw/out .vid/tw/body .vid/next; git rev-parse HEAD > .vid/tw/applied
pt_after ROW-020 'ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day, or a day no digest went out. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
grep -q '^ROW-021 ' INVENTORY.md && ! git show HEAD:INVENTORY.md | grep -q '^ROW-021 ' || fail 'ROW-021 is not in the working tree alone'
printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005 plan=p1 base=b1 export=e1 parts=1 at=2026-11-18T09:00:00Z form=f1 words="go"\n' > .vid/tw/log
printf '# Step ticket S02\n\n## Rows\n\n> %s\n> %s\n' "$(grep '^ROW-001 ' INVENTORY.md)" "$(grep '^ROW-005 ' INVENTORY.md)" > .vid/tw/out/issue-2.md
printf 'ROW-001\nROW-005\nROW-008\n' > .vid/tw/body/issue-2
body() { printf '%s\n' '## Tests' '- ROW-001' '- ROW-012, ours' "$1" '- ROW-006, the footer' '- ROW-021, the day shown'; }
read_() { { printf 'ticket\t2\tOPEN\t-\t2026-11-18T09:00:00Z\n'; body "$1" | sed 's/^/body	2	/'; } > .vid/round/read; }
h() { printf '%s\n' "$@" | git hash-object --stdin; }
read_ '- ROW-013, the same feed twice'
HB=$(body '- ROW-013, the same feed twice' | git hash-object --stdin); H12=$(h '- ROW-012, ours'); H13=$(h '- ROW-013, the same feed twice'); H21=$(h '- ROW-021, the day shown')
{ printf '2\tadded\tROW-013\t%s\tno\t2026-11-18T10:00:00Z\tit stays out\n' "$H13"
  printf '2\tadded\tROW-012\t%s\tno\t2026-11-18T10:00:00Z\tan older reading\n' "$(h '- ROW-012, an older line')"
  printf '2\tdropped\tROW-008\t%s\tyes\t2026-11-18T10:00:00Z\tto place it\n' "$HB"
  printf '2\tmoved\tROW-006\t-\t-\t2026-11-18T10:00:00Z\ttaken out by the owner\n'; } > .vid/next/team-answers
sh "$CHECKS/next.sh" changes > "$T/out" 2>&1 || fail 'next.sh changes failed'
printf 'added\t2\tROW-012\tS02\t%s\nadded\t2\tROW-021\tpending-only\t%s\ndropped\t2\tROW-005\tS02\t%s\n' "$H12" "$H21" "$HB" | sort > "$T/want"
sort "$T/out" | cmp -s - "$T/want" || { cat "$T/want" >&2; fail 'the changes are not exactly ROW-012 and ROW-021 (pending-only) added and ROW-005 dropped, each with its evidence'; }
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
for id in ROW-012 ROW-005 ROW-021; do grep -q "^move${TB}team-change${TB}#2 $id${TB}[0-9a-f]\{40\}${TB}" "$T/tr" || { cat "$T/tr" >&2; fail "no team-change move named #2 $id with its hash"; }; done
grep -q "^move${TB}team-change${TB}#2 ROW-021${TB}[0-9a-f]*${TB}.*: a yes comes in through planning-analysis and implement-replan; needs no, and your words\$" "$T/tr" || fail "ROW-021's move does not read: a yes comes in through planning-analysis and implement-replan"
! grep -q "^move${TB}team-change${TB}#2 ROW-012${TB}.*phase 3" "$T/tr" || fail "ROW-012's move is left to phase 3"
! grep -q "^move${TB}team-change${TB}#2 ROW-0\(13\|08\|06\)${TB}" "$T/tr" || fail 'an answered or moved change has a move'
# the body line naming ROW-013 changes: its no no longer covers it
read_ '- ROW-013, read twice, kept once'
sh "$CHECKS/next.sh" changes > "$T/out" 2>&1 || fail 'next.sh changes failed the second time'
grep -q "^added${TB}2${TB}ROW-013${TB}S02${TB}$(h '- ROW-013, read twice, kept once')\$" "$T/out" || fail 'ROW-013 is not offered again once the body line naming it changed'
exit 0
