#!/bin/sh
# Purpose: selftest case — the rules a team already works to, as the owner says they were handed (FB-5 B1.7), on GitHub manual's toy
# (fixtures/manual.sh). `planner.sh setup team-rules <a path or a link> --words "<words>"` keeps it with its words and date; a value of
# several words, or no words, is refused. While it is set the switch and a re-take write and show no text and say no `team-reports`,
# the call's lines say none, whatever the text has become, and `results.sh team --hand` prints the text and writes nothing. `none` takes
# it away, and the call says the text was never handed over. No take-stock asks it. In GitHub auto `--hand` writes as before. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "team-rules: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); mn_project "$T/p"; F=.vid/plan/TEAM-REPORTS.md
set_() { sh "$CHECKS/planner.sh" setup team-rules "$@" > "$T/mo" 2>&1; }
set_ team/rules.md --words 'they work to their own rules' || fail 'the rules as handed could not be recorded'
grep -qx 'team-rules: team/rules.md' .vid/tw/settings && grep -q '^setup-answered key=team-rules value="team/rules.md" words="they work to their own rules" at=2' .vid/plan/setup || fail 'the answer is not kept with its words and date'
if set_ 'a text of several words' --words 'x'; then fail 'a value of several words was taken'; fi; if set_ team/other.md; then fail 'it was taken without the owner'"'"'s words'; fi
grep -qx 'team-rules: team/rules.md' .vid/tw/settings || fail 'a refused value changed the setting'
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
! grep -q 'team-reports' "$T/mo" && [ ! -f "$F" ] || fail 'the switch said or wrote the text'
mn_switch --words 'yes, the re-take'; [ "$MN_RC" = 0 ] || fail "the re-take exited $MN_RC"; ! grep -q 'team-reports' "$T/mo" && [ ! -f "$F" ] || fail 'the re-take said or wrote the text'
lines() { sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/mo" || fail 'next.sh triggers failed'; }
lines; ! grep -q "^context${TB}team-reports" "$T/L" || fail 'the call says the text'
sh "$CHECKS/results.sh" team --hand > "$T/th" 2>&1 && grep -qF 'vid-results/<id>' "$T/th" && [ ! -f "$F" ] || { cp "$T/th" "$T/mo"; fail 'team --hand did not print the text alone'; }
# an older text handed before, and the text changed since: still nothing
echo 'an older text' > "$F"; lines; ! grep -q "^context${TB}team-reports" "$T/L" || fail 'a changed text brought the line back'
mn_switch --words 'yes, again'; [ "$MN_RC" = 0 ] && ! grep -q 'team-reports' "$T/mo" && [ "$(cat "$F")" = 'an older text' ] || fail 'a re-take wrote the text over the older one'; rm "$F"
set_ 'https://example.invalid/rules?v=2' --words 'the link now' && grep -qx 'team-rules: https://example.invalid/rules?v=2' .vid/tw/settings && [ "$(grep -c '^team-rules:' .vid/tw/settings)" = 1 ] || fail 'a link was not taken in its place'
set_ none --words 'they take ours' && ! grep -q '^team-rules:' .vid/tw/settings && grep -q '^setup-answered key=team-rules value="none"' .vid/plan/setup || fail 'none did not take it away'
lines; grep -q "^context${TB}team-reports${TB}.*never handed over" "$T/L" || fail 'with none the call does not say the text'
set_ team/rules.md --words 'theirs again' || fail 'it could not be set again'
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-24T09:00:00Z\n' >> .vid/plan/setup
sh "$CHECKS/results.sh" team --hand > "$T/th" 2>&1 && cmp -s "$T/th" "$F" || fail 'in GitHub auto team --hand did not write as before'
echo 'team-rules: ok'
