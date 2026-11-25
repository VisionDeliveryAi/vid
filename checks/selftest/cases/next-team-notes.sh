#!/bin/sh
# Purpose: selftest case — three notes of the call's lines (FB-3 A2, A3, A4), on the planner's toy in GitHub manual. Each report branch
# left out (.vid/round/reports-skipped) is one `context report <id> <words>`, its ticket's number named when its id holds one, and one
# of the counts of the owner's list (FB-5 A1); the text for the team (`results.sh team`, here a stand-in script beside the real ones) is one `context
# team-reports <why>` while none was handed over or it changed since, and nothing once handed as it stands or where results.sh has no
# such verb; and a row accepted by ruling in no published ticket is not counted as not yet with the team, nor raised as to place, until the spec rewords it (reset). In
# GitHub auto there is neither note. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-team-notes: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t'); HOME=$T/home; export HOME; mkdir -p "$HOME" "$T/ck"
for e in "$CHECKS"/*; do case ${e##*/} in selftest) ;; *) cp -R "$e" "$T/ck/" ;; esac; done
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/round .vid/tw/out .vid/next .vid/decide; git rev-parse HEAD > .vid/tw/applied; : > .vid/tw/handed; : > .vid/tw/settings   # FB-5 A1: the list is a ticket-mode project's, which has one
printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-10T09:00:00Z\n' > .vid/tw/log
printf '# Step ticket S02\n\n## Rows\n\n> %s\n' "$(grep '^ROW-001 ' INVENTORY.md)" > .vid/tw/out/issue-2.md
printf 'ticket\t2\tOPEN\t-\t2026-11-10T09:00:00Z\n' > .vid/round/read
team() { printf '#!/bin/sh\n[ "${1:-}" = team ] || exit 2\n%s\n' "$1" > "$T/ck/results.sh"; }
tr_() { sh "$T/ck/next.sh" triggers > "$T/L" 2> "$T/out" || fail "next.sh triggers failed ($1)"; cp "$T/L" "$T/out"; }
# A3: the text for the team
team 'exit 2'; tr_ 'no verb'; grep -q "^context${TB}team-reports" "$T/L" && fail 'with no such verb a note was said'
team 'echo "what your reports hold"'; tr_ 'never handed'; [ "$(grep -c "^context${TB}team-reports${TB}.*never handed" "$T/L")" = 1 ] || fail 'a text never handed over is not said once'
grep "^context${TB}team-reports" "$T/L" | grep -q '/vid:vid-accept-step reports' || fail 'the note does not name the command that hands it'
echo 'what your reports hold' > .vid/plan/TEAM-REPORTS.md; tr_ 'handed'; grep -q "^context${TB}team-reports" "$T/L" && fail 'a text handed over as it stands is said again'
echo 'an older text' > .vid/plan/TEAM-REPORTS.md; tr_ 'changed'; grep -q "^context${TB}team-reports${TB}.*changed" "$T/L" || fail 'a text changed since it was handed is not said'
# A2: the report branches left out
C=0123456789abcdef0123456789abcdef01234567; grep -q "^context${TB}report${TB}" "$T/L" && fail 'a report is said left out with none'
{ printf 'step-2-%s-1\t%s\tAna\t2026-11-20\tno folder of its name\n' "$(printf %.12s $C)" $C; printf 'stopped-a\t%s\tBo\t2026-11-21\ta file of its name\n' $C; } > .vid/round/reports-skipped
tr_ 'left out'; W="the branch vid-results/step-2-$(printf %.12s $C)-1 (its newest commit $(printf %.12s $C) by Ana, 2026-11-20) reports on #2: no folder of its name. Put the report's files in a folder named step-2-$(printf %.12s $C)-1 on that branch and push it again; whatever else the branch holds is not read."
grep -qxF "context${TB}report${TB}step-2-$(printf %.12s $C)-1${TB}$W" "$T/L" || fail 'a report branch left out is not said, with its ticket, its commit, author and date and what to do'
grep "^context${TB}report${TB}stopped-a${TB}" "$T/L" | grep -q 'by Bo, 2026-11-21): a file of its name' || fail 'a branch whose id holds no number names one'
sh "$T/ck/queue.sh" raise "$T/L" > "$T/out" 2>&1 || fail 'queue.sh raise failed'; sh "$T/ck/next-page.sh" write "$T/L" > "$T/out" 2>&1 || fail 'the list was not written'
P=.vid/face/list.json; grep -q 'report branches left out' "$P" && grep -q 'vid-results/stopped-a' "$P" || fail 'the list counts no report left out'
rm -f .vid/round/reports-skipped; tr_ 'none left'; sh "$T/ck/next-page.sh" write "$T/L" > "$T/out" 2>&1 || fail 'the list was not written'; grep -q 'report branches left out' "$P" && fail 'the count stays with none left out'
# A4: accepted by ruling, in no ticket
for r in ROW-017 ROW-018; do grep -q "^counted${TB}unpublished${TB}$r${TB}" "$T/L" || fail "$r is not counted before"; done; N0=$(sed -n "s/^count${TB}total${TB}//p" "$T/L")
printf 'row ROW-017 accepted-by-ruling | stand-in: owner at 2026-11-24T09:00:00Z, words "accepted before"\n' > .vid/tw/handed; printf 'ROW-018\taccepted by ruling\t-\t-\n' > .vid/decide/state
printf 'ROW-018\tno-step\t2026-11-19T09:00:00Z\tyes, later\n' > .vid/tw/to-place; tr_ 'accepted'
grep -q "^counted${TB}[a-z-]*${TB}ROW-01[78]${TB}" "$T/L" && fail 'a row accepted by ruling is counted as not yet with the team'
[ "$(sed -n "s/^count${TB}total${TB}//p" "$T/L")" = $((N0 - 2)) ] || fail 'the total does not fall by the two rows'
grep -q "to-place-active${TB}ROW-018" "$T/L" && fail 'a row accepted by ruling is raised as to place'
# one of them reworded at HEAD since the applied commit: a spec change, counted as reset
sed '/^ROW-017 /s/other common names/other everyday names/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; grep -q '^ROW-017 .*other everyday names' INVENTORY.md || fail 'ROW-017 was not reworded'; g commit -qam 'ROW-017 reworded'; tr_ 'reworded'
grep -q "^counted${TB}reset${TB}ROW-017${TB}pending reset\$" "$T/L" && [ "$(sed -n "s/^count${TB}total${TB}//p" "$T/L")" = $((N0 - 1)) ] || fail 'a row accepted by ruling, reworded since, is not counted as reset'
# GitHub auto: neither note
: > .vid/tw/to-place; printf 'x-1\t%s\tAna\t2026-11-20\tno folder\n' $C > .vid/round/reports-skipped
printf 'setup-answered key=github-mode value="auto" words="the toy, auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup; tr_ 'auto'
grep -q "^context${TB}\(report\|team-reports\)${TB}" "$T/L" && fail 'GitHub auto has one of the notes'
echo 'next-team-notes: ok'
