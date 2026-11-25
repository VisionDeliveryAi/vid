#!/bin/sh
# Purpose: selftest case — the sort in GitHub auto (FB-5 A1, S1, S5). On the writer's toy in GitHub auto the round's sync raises a line:
# it is not sorted; a sort of it is taken, its number and `next:` as in GitHub manual, and the list is written; the answer's sync takes
# the line away at once and the list is written again. `queue.sh backlog` asks next-page.sh for no plan there and says no count of a call. The run skill loads
# vid-sort at its start, invokes it after a step that raised or changed an item, where it waits on the owner and where it stops; the
# skill is for both modes, and its rules name no mode but where the modes differ. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/tw-toy.sh"; . "$CHECKS/selftest/fixtures/sort.sh"
fail() { echo "sort-auto: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/sorted >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; B=.vid/decide/queue/backlog; SO=.vid/decide/queue/sorted; TB=$(printf '\t')
printf 'setup-answered key=github-mode value="auto" words="ViD builds it" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
grep -v '^context-window ' .vid/metrics-events > "$T/m" || true; cat "$T/m" > .vid/metrics-events
mkdir "$T/c"; cp "$CHECKS"/*.sh "$T/c/"; printf '#!/bin/sh\necho "$*" >> "%s/calls"\n[ "$1" = write ] || echo "the plan as text"\n' "$T" > "$T/c/next-page.sh"; QS=$T/c/queue.sh; : > "$T/calls"
so_ok sync; Q1=$(awk -F'\t' '$2 == "context:window" { print $1 }' "$B"); [ -n "$Q1" ] && grep -qx write "$T/calls" || fail 'the sync raised no line, or wrote no list'
so_now; grep -qx 'state none' "$T/now" && grep -qx "unsorted $Q1" "$T/now" || fail 'a raised line is sorted before its sort'
so_todo "$Q1" 'Let the session stay small' > "$T/s"; : > "$T/calls"; so_ok sort "$T/s"; tail -n 1 "$T/out" | grep -qx '1 thing for you; first: Let the session stay small' && grep -qx write "$T/calls" || fail 'the sort is not taken in GitHub auto, or wrote no list'
mkdir -p .vid/next; printf 'count\ttotal\t5\ncount\tadded\t5\n' > .vid/next/lines; so_ok backlog; ! grep -q 'not yet with the team' "$T/out" || fail 'GitHub auto says GitHub manual'"'"'s counts'; grep -q '^next: 1\.1 · Let the session stay small' "$T/out" && ! grep -q 'the plan as text' "$T/out" || fail 'the backlog in GitHub auto has no next line, or a plan'
so_ok ask own 'Which colour is the footer?'; so_now; grep -qx 'state stale' "$T/now" || fail 'an item raised while the run goes on counts as sorted'
: > "$T/calls"; so_ok answer "$Q1" no 'leave it'; so_ok sync; so_now; ! grep -q "$Q1" "$T/now" && grep -qx write "$T/calls" || fail 'a closed item'"'"'s line did not go, or the list was not written'
K=$CHECKS/../skills; [ -d "$K/vid-run" ] || { echo 'sort-auto: ok (a project layout: no skills)'; exit 0; }
R=$K/vid-run/SKILL.md; V=$K/vid-sort/SKILL.md; : > "$T/out"; [ -f "$V" ] || fail 'there is no vid-sort skill'
grep '^\*\*The skills\.\*\*' "$R" | grep -q '`vid-sort`' || fail 'the run skill does not load vid-sort at its start'
L=$(awk '/^## The loop/ { on = 1; next } /^## / { on = 0 } on' "$R"); printf '%s\n' "$L" | grep 'raised or changed' | grep -qF 'Invoke the `vid-sort` skill' || fail 'the run skill does not invoke vid-sort after a step that raised or changed an item'
awk '/^## The loop/ { on = 1; next } /^## The only stops/ { exit } on' "$R" | grep 'waits on the owner' | grep -q '`vid-sort`' || fail 'the run skill does not sort where it waits on the owner'
awk '/^## The only stops/ { on = 1; next } /^## / { on = 0 } on' "$R" | grep -q '`vid-sort`' || fail 'the run skill does not sort where it stops'
grep -q '^description: .*both GitHub modes' "$V" && grep -qF '/vid:vid-sort' "$V" || fail 'vid-sort is not for both modes, or not the owner'"'"'s command'
for x in 'sh checks/queue.sh open' 'sh checks/queue.sh sort' 'three working days' 'My to do' 'Waiting' 'Changed' 'what ViD would choose' 'ready to send' 'never asked' 'placed' 'backlog add' 'not sorted' 'one at a time' 'nothing is new, changed or moved' 'queue.sh sorted --line'; do tr '\n' ' ' < "$V" | tr -s ' ' | grep -qF -- "$x" || fail "vid-sort does not say: $x"; done
echo 'sort-auto: ok'
