#!/bin/sh
# Purpose: selftest case — a decision whose "not yet" names the pull request's missing Decisions section calls for the dev
# manager's work (0.26.10.29.5, DP-1 R1, with R8's line). On the fake gh: a claimed ticket whose decision for its head reads
# ticket: not yet and the line decisions missing, alone or beside a held row, makes dm.sh next print not-yet for it, not wait.
# Skips where devagent/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
DM=$CHECKS/../devagent/dev-manager/dm.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "dp-r1-dm-route: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W=$T/work; mkdir -p "$W/tickets"; DM_WORK=$W; export DM_WORK
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 600\nagent-time-limit: 600\nagent-turn-limit: 40\n' "$W" > "$W/note.txt"; cp "$W/note.txt" "$W/dm-note.txt"
g() { gh "$@" > /dev/null; }
g issue create -R owner/code --title t1 --body x --label ticket; g issue comment 1 -R owner/code --body 'vid: claimed'
git -C "$T/s" checkout -q -b t-1; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m t-1; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/t-1; H=$(git -C "$T/s" rev-parse HEAD)
g pr create -R owner/code --head t-1 --base main --title x --body 'ticket: #1'; P=2
L="decisions missing — the pull request's description has no Decisions section, nor Decisions: none"
for x in '' 'ROW-1 held — failing, a weak test'; do
  printf 'vid: decide %s\nby: MR\n' "$H" > "$T/b"; g pr comment $P -R owner/code --body-file "$T/b"
  { printf 'vid: decision %s\nticket: not yet\n' "$H"; [ -z "$x" ] || printf '%s\n' "$x"; printf '%s\n' "$L"; } > "$T/b"; g pr comment $P -R owner/code --body-file "$T/b"
  sh "$DM" next > "$T/out" 2>&1 || fail 'next failed'; grep -qx 'not-yet 1' "$T/out" || fail "decisions missing${x:+ beside a held row} calls for no work"; done
echo 'dp-r1-dm-route: ok'
