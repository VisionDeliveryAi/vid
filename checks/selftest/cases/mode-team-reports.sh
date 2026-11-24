#!/bin/sh
# Purpose: selftest case — the team is told what to send (FB-3 A3). The switch to GitHub manual writes .vid/plan/TEAM-REPORTS.md, says
# `team-reports <path> new`, and posts nothing for it; the text names the code repository, the branch and its folder, the two lines of
# results.txt, the results files, when a report counts, how a row is read, the ticket line, the ask and the owner-blocked label, and no
# role of DevAgent's, no script and no release. A re-take with nothing changed says `unchanged`, the file as it was; with the label
# prefix changed, `changed`, and the new text. `results.sh team` writes nothing; `team --hand` prints the text and writes the file.
# In GitHub auto it prints that mode's own text. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-team-reports: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; F=.vid/plan/TEAM-REPORTS.md
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2
printf '%s S01\n' "$N1" > "$T/register"; posted() { ls "$FAKEGH/issues/$N1/comments" 2>/dev/null | grep -c . || true; }; c0=$(posted)
mn_switch --applied "$AP" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
grep -qx "team-reports $F new" "$T/mo" || fail 'the switch did not say the text is there, new'; [ -s "$F" ] || fail "the switch wrote no $F"
for x in owner/code 'vid-results/<id>' 'by: ' 'commit: ' '.xml' 'the very same files' 'at least one file' 'ticket: #' 'vid: decide ' 'Decisions: none' 'vid:blocked' 'none left' 'red-<' 'req-<' 'deploy-<' 'covers: '; do grep -qF -e "$x" "$F" || { cat "$F" >&2; fail "the text does not hold: $x"; }; done
! grep -nE '(^|[^A-Za-z])(TA|TM|GR|SR|BU|FX|DM|MR|DP)([^A-Za-z]|$)|DevAgent|checks/|\.sh([^A-Za-z]|$)|[0-9]+\.[0-9]+\.[0-9]+' "$F" >&2 || fail 'the text names a role, a script or a release'
[ "$(posted)" = "$c0" ] || fail 'the switch posted on the ticket'
sh "$CHECKS/results.sh" team > "$T/tm" 2>&1 && cmp -s "$T/tm" "$F" || { cat "$T/tm" >&2; fail 'the text given and the text handed differ'; }
cp "$F" "$T/handed"; mn_switch --words 'yes, the re-take'; [ "$MN_RC" = 0 ] || fail "the re-take exited $MN_RC"
grep -qx "team-reports $F unchanged" "$T/mo" && cmp -s "$T/handed" "$F" || fail 'a re-take with nothing changed did not say unchanged'
sed 's/^labels-prefix:.*/labels-prefix: toy:/' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings
sh "$CHECKS/results.sh" team > "$T/tm" 2>&1; cmp -s "$T/handed" "$F" || fail 'reading the text wrote the file'; grep -qF 'toy:blocked' "$T/tm" || fail 'the text does not follow the label prefix'
mn_switch --words 'yes, again'; [ "$MN_RC" = 0 ] || fail "the second re-take exited $MN_RC"
grep -qx "team-reports $F changed" "$T/mo" && cmp -s "$T/tm" "$F" || fail 'a re-take with the text changed did not say changed'
rm "$F"; sh "$CHECKS/results.sh" team --hand > "$T/th" 2>&1 || { cat "$T/th" >&2; fail 'team --hand failed'; }; cmp -s "$T/th" "$F" && cmp -s "$T/tm" "$F" || fail 'team --hand did not print the text and write it'
if sh "$CHECKS/results.sh" team --else > "$T/th" 2>&1; then fail 'an unknown option was taken'; fi
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-24T09:00:00Z\n' >> .vid/plan/setup
sh "$CHECKS/results.sh" team > "$T/ta" 2>&1 || fail 'GitHub auto has no text'; grep -qF 'pr-<pull request>-<head12>-<k>' "$T/ta" && ! cmp -s "$T/ta" "$F" || fail 'GitHub auto does not print its own ids'
echo 'mode-team-reports: ok'
