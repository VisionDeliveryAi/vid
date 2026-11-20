#!/bin/sh
# Purpose: selftest case — an amendment in GitHub manual keeps the team's words in a ticket posted in the form (GM-2 T5; its case
# manual-amend-form). On the form fixture's toy (fixtures/form.sh), S02 posted in the form; the team edits two of its body's lines on
# GitHub: the {name} placeholder's line, and a line of the form's own words outside every placeholder. ROW-002 moves from S04 into
# S02 by a recorded plan change, so writer.sh due owes `amend <n>`. Amended on the owner's words; the title stands; both team edits
# stand byte for byte; the {tests} and {tests:row} lines, which the team left as ViD filled them, are refilled with ROW-002 among
# them, and the {requirements} line with the requirement ROW-002 brings; every other line stands; the notice comment names ROW-002 as added and the {name} line as left as the team changed it;
# the form record keeps the {name} line's old filling and holds the new {tests} filling; the log's line is `amended … form=<the
# form's hash> added=ROW-002 words="<the words>"`; the kept body ids gain ROW-002. The team's checklist
# line ends in a carriage return, and keeps it byte for byte; the team copies the old {tests} line into its own words above the
# placeholder's, and only the placeholder's line is refilled. Then S03, posted while S01 (its builds-on) has no ticket, so its
# {blocked-by} and {fakes} lines are both `none`: the team edits its blocked-by line; S01 is posted; S03 gains ROW-011 and is
# amended: the team's blocked-by line stands, the {not-yet-ticketed} line is refilled `none`, the {fakes} line stays `none`, no line
# reads S01's ticket, and the notice names {blocked-by} as left. The team's copy of S03's {tests} line right before
# the original ties with it, so both stand as they were and the notice names {tests} as left too. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-amend-form: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }; N=$FM_N; D=$FAKEGH/issues/$N
cp "$D/title" "$T/title"
OT=$(awk -F'\t' '$1 == "{tests}" { print $2 }' ".vid/tw/form/issue-$N"); OR=$(awk -F'\t' '$1 == "{tests:row}" { print $2 }' ".vid/tw/form/issue-$N")
ON=$(awk -F'\t' '$1 == "{name}" { print $2 }' ".vid/tw/form/issue-$N"); OQ=$(awk -F'\t' '$1 == "{requirements}" { print $2 }' ".vid/tw/form/issue-$N"); [ -n "$OT" ] && [ -n "$OR" ] && [ "$ON" = 'new jobs only, each listed once' ] || fail 'the form record is not as posted'
# the team's two edits
CR=$(printf '\r')
fm_team_edit "$N" 's/^new jobs only, each listed once$/new jobs only, each listed once (the team'"'"'s reading)/; s/^The toy team.s own checklist line\.$/The toy team'"'"'s own checklist line, with a box ticked.'"$CR"'/'
awk -v ot="$OT" '{ print } /^The toy team.s own words: / { print "The team'"'"'s own note, the tests as first posted:"; print ot }' "$D/body" > "$T/bx" && cat "$T/bx" > "$D/body"
grep -qx "new jobs only, each listed once (the team's reading)" "$D/body" && grep -qx "The toy team's own checklist line, with a box ticked.$CR" "$D/body" && [ "$(grep -cxF "$OT" "$D/body")" = 2 ] || fail 'the team edits did not take'
cp "$D/body" "$T/b0"
# ROW-002 into S02, recorded
am_move ROW-002 S04 S02; am_change "$N" 'S02 takes ROW-002, the owner says' || { cp "$T/chg" "$T/out"; fail 'the plan change was refused'; }
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1; sh "$CHECKS/github.sh" tw-sync >> "$T/out" 2>&1
sh "$CHECKS/writer.sh" due > "$T/due" 2>&1 || { cp "$T/due" "$T/out"; fail 'writer.sh due failed'; }
grep -qx "amend $N" "$T/due" || { cp "$T/due" "$T/out"; fail "due does not owe amend $N"; }
am_amend "$N" "Yes, amend #$N" || { cp "$T/post" "$T/out"; fail "#$N was not amended in manual"; }
cmp -s "$T/title" "$D/title" || fail "the title changed: $(cat "$D/title")"
# the body: the team's lines stand, the {tests} and {tests:row} lines refilled, nothing else changed
NT="ROW-002, $OT"; NR="ROW-002, $OR"; NQ=$(awk '/^## / { s = substr($0, 4); next } s == "Requirements" && /^The answers/ { s = "" } s == "Requirements" && /^> [A-Z]+-[0-9]+ [|]/ { print $2 }' "$AM_F" | paste -sd , - | sed 's/,/, /g')
[ "$NQ" != "$OQ" ] && printf '%s\n' "$NQ" | grep -q 'REQ-' || fail "the amended ticket quotes no new requirement ($NQ)"
awk -v ot="$OT" -v nt="$NT" -v or_="$OR" -v nr="$NR" -v oq="$OQ" -v nq="$NQ" '/^## Tests$/ { t = 1 } /^## Requirements$/ { q = 1 } t && $0 == ot && !a { print nt; a = 1; next } t && $0 == or_ && !b { print nr; b = 1; next } q && $0 == oq && !c { print nq; c = 1; next } { print }' "$T/b0" > "$T/want"
cmp -s "$T/want" "$D/body" || { diff "$T/want" "$D/body" > "$T/out" || :; fail 'the body is not the team'"'"'s with the {tests} lines refilled (want < > the body)'; }
# the notice
am_comment "$N" 'vid: amended' > "$T/am"; cp "$T/am" "$T/out"
[ -s "$T/am" ] || fail 'no notice of the amendment was posted'
grep -q '^- added: ROW-002 ' "$T/am" || fail 'the notice does not name ROW-002 as added'
grep -q '{name}' "$T/am" || fail 'the notice does not name the {name} line the team changed'
! grep -q '{tests}' "$T/am" || fail 'the notice names the {tests} line, which ViD refilled'
# the records
FH=$(git rev-parse HEAD:forms/issue.md)
grep -qE "^amended $N .* parts=[0-9]+ at=[^ ]+ form=$FH added=ROW-002 words=\"Yes, amend #$N\"\$" .vid/tw/log || { grep "^amended $N " .vid/tw/log > "$T/out"; fail 'the amended line is not amended … form= added=ROW-002 words='; }
[ "$(awk -F'\t' '$1 == "{name}" { print $2 }' ".vid/tw/form/issue-$N")" = "$ON" ] || fail "the form record does not keep the {name} line's old filling"
[ "$(awk -F'\t' '$1 == "{tests}" { print $2 }' ".vid/tw/form/issue-$N")" = "$NT" ] || fail 'the form record does not hold the new {tests} filling'
grep -qx ROW-002 ".vid/tw/body/issue-$N" || fail 'the kept body ids do not gain ROW-002'
grep -qx "The toy team's own checklist line, with a box ticked.$CR" "$D/body" || fail "the team's line lost its carriage return"
# equal fillings: S03's {blocked-by} and {fakes} are both none; the team edits the blocked-by line
fm_post S03 || { cp "$T/post" "$T/out"; fail 'S03 was not posted in manual'; }; N3=$FM_N; D3=$FAKEGH/issues/$N3
[ "$(awk -F'\t' '$1 == "{blocked-by}" || $1 == "{fakes}" { print $2 }' ".vid/tw/form/issue-$N3" | paste -sd , -)" = 'none,none' ] && [ "$(awk -F'\t' '$1 == "{not-yet-ticketed}" { print $2 }' ".vid/tw/form/issue-$N3")" = S01 ] || fail "S03's blocked-by and fakes are not both none, its not-yet-ticketed not S01"
awk '/^## Depends on$/ { d = 1 } d && $0 == "none" && !e { $0 = "none (we wait on the API key)"; e = 1 } { print }' "$D3/body" > "$T/b3" && cat "$T/b3" > "$D3/body"
# the team copies S03's {tests} line right before the original; the two tie, so neither is refilled
OT3=$(awk -F'\t' '$1 == "{tests}" { print $2 }' ".vid/tw/form/issue-$N3"); awk -v ot="$OT3" '/^## Tests$/ { t = 1 } t && $0 == ot && !c { print ot; c = 1 } { print }' "$D3/body" > "$T/b3" && cat "$T/b3" > "$D3/body"
[ "$(grep -cxF "$OT3" "$D3/body")" = 2 ] || fail "the team's copy of S03's {tests} line did not take"
fm_post S01 || { cp "$T/post" "$T/out"; fail 'S01 was not posted in manual'; }; N1=$FM_N
am_move ROW-011 S04 S03; am_change "$N3" 'S03 takes ROW-011' || { cp "$T/chg" "$T/out"; fail 'the plan change for S03 was refused'; }
am_amend "$N3" "Yes, amend #$N3" || { cp "$T/post" "$T/out"; fail "#$N3 was not amended in manual"; }
cp "$D3/body" "$T/out"
grep -qx 'none (we wait on the API key)' "$D3/body" || fail "the team's blocked-by line did not stand"
! grep -qx "#$N1" "$D3/body" || fail "a line of S03's body reads #$N1, S01's ticket, though the team changed the blocked-by line"
[ "$(awk '/^## Depends on$/ { d = 1; next } d && /^## / { exit } d && NF' "$D3/body" | paste -sd , -)" = 'none (we wait on the API key),none' ] || fail 'the depends-on lines are not the team'"'"'s blocked-by line and a refilled not-yet-ticketed none'
[ "$(awk '/^## Works against fakes of$/ { d = 1; next } d && /^## / { exit } d && NF' "$D3/body")" = none ] || fail 'the fakes line is not none'
[ "$(grep -cxF "$OT3" "$D3/body")" = 2 ] || fail "the {tests} line or its team copy right before it was refilled, though the two tie"
am_comment "$N3" 'vid: amended' > "$T/am3"; cp "$T/am3" "$T/out"
grep -q '{blocked-by}' "$T/am3" && grep -q '{tests}' "$T/am3" && ! grep -q '{fakes}\|{not-yet-ticketed}' "$T/am3" || fail "S03's notice does not name {blocked-by} and {tests} alone as left"
exit 0
