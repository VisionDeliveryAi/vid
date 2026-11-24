#!/bin/sh
# Purpose: selftest case — a take-stock lists the tickets that look accepted already (FB-3 E1), on GitHub manual's toy and the fake gh.
# The switch's first take-stock of a project with closed stories, its register given, and a re-take, its register found, each print one
# `looks-accepted #<n> <step> <commit or -> <why>` line for a ticket on record, not withdrawn and not accepted, whose issue is closed: the
# newest comment whose first line is `vid: decision <commit>` and whose second is `ticket: accepted`, its commit, its author and its date;
# else `closed, no decision comment`. None for an open ticket, one accepted on record or one withdrawn. One read a ticket. The call ends
# as it would, its mode recorded, and writes nothing of it. `round.sh accept --tickets` with no words is refused and writes nothing; on the
# owner's words both are recorded, and the next take-stock lists neither. One GitHub cannot read is a refusal in GitHub's words, to run
# again. The take-stock in GitHub auto lists none. The skill asks once, after the call has ended. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-looks-accepted: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
retake() { MN_RC=0; sh "$CHECKS/mode.sh" manual --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
# dec <n> <its first line> <its second> <author> <date>: a comment on issue n
dec() { _d=$FAKEGH/issues/$1; mkdir -p "$_d/comments" "$_d/cby" "$_d/cat"; _k=$(( $(ls "$_d/comments" | grep -c . || true) + 1 )); printf '%s\n%s\n' "$2" "$3" > "$_d/comments/$_k"; echo "$4" > "$_d/cby/$_k"; echo "$5" > "$_d/cat/$_k"; }
kept() { { find .vid/decide -type f -size +0 -exec cksum {} + 2>/dev/null | grep -vE '/(queue/|unit-merges|unit-asks|merged-prs|refused|flags|accepted-log)' || :; grep -v '^engines ' .vid/tw/handed 2>/dev/null || :; grep '^accepted-outside ' .vid/metrics-events 2>/dev/null || :; } | sort | cksum; }
mn_project "$T/p"; tk_dev 'the skeleton'; C1=$(git -C "$T/dev" rev-parse HEAD); tk_dev 'the steps'; C2=$(git -C "$T/dev" rev-parse HEAD)
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step ROW-001 > "$T/t2"; gh_writing "$N2" "$T/t2" body 2
N3=$(gh_issue 'Step S03'); mn_ticket "$N3" S03 step ROW-006 > "$T/t3"; gh_writing "$N3" "$T/t3" body 2
N4=$(gh_issue 'Step S04'); mn_ticket "$N4" S04 step ROW-002 > "$T/t4"; gh_writing "$N4" "$T/t4" body 2
printf '%s S01\n%s S02\n%s S03\n%s S04\n' "$N1" "$N2" "$N3" "$N4" > "$T/register"
for n in "$N1" "$N2" "$N3" "$N4"; do printf 'vid:ticket\n' > "$FAKEGH/issues/$n/labels"; done
# #1 closed with two accepting comments (the newest is named), a `not yet` and one that only begins so; #2 closed without; #3 open with one; #4 closed, accepted on record
dec "$N1" "vid: decision $C1" 'ticket: accepted' ann 2026-11-10T09:00:00Z; dec "$N1" "vid: decision $C2" "ticket: accepted$(printf '\r')" ben 2026-11-11T09:00:00Z; dec "$N1" "vid: decision $C1" 'ticket: not yet' ann 2026-11-12T09:00:00Z; dec "$N1" "vid: decision $C1" 'ticket: accepted at 0123456789ab; its close runs there' ann 2026-11-13T09:00:00Z
dec "$N2" "vid: decision $C1" 'ticket: not yet' ann 2026-11-10T09:00:00Z; dec "$N2" 'Done, I think' 'ticket: accepted' ann 2026-11-11T09:00:00Z
dec "$N3" "vid: decision $C1" 'ticket: accepted' ann 2026-11-10T09:00:00Z; dec "$N4" "vid: decision $C1" 'ticket: accepted' ann 2026-11-10T09:00:00Z
for n in "$N1" "$N2" "$N4"; do gh_attr "$n" state CLOSED; done
mkdir -p .vid/decide; printf 'step-%s-%.12s\t%s\t%s\t%s\n' "$N4" "$C1" "$N4" "$C1" "$C1" > .vid/decide/merges; k0=$(kept)
L1="looks-accepted #$N1 S01 $C2 ticket: accepted, by ben on 2026-11-11T09:00:00Z"; L2="looks-accepted #$N2 S02 - closed, no decision comment"
two() { [ "$(grep '^looks-accepted ' "$T/mo")" = "$(printf '%s\n%s' "$L1" "$L2")" ] || fail "$1 does not list #$N1 and #$N2 alone, as they stand"; }
gh_wclear; : > "$FAKEGH/log"; mn_switch --applied "$AP" --words 'yes, ratify'; [ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
two 'the switch'; grep -qx 'mode: GitHub manual, recorded' "$T/mo" || fail 'the switch did not record its mode'
[ "$(grep -c "issue view $N1 .*vid: decision " "$FAKEGH/log")" = 1 ] || fail "#$N1's comments were not read for it in one read"; ! grep -q "issue view $N4 .*vid: decision " "$FAKEGH/log" || fail 'a ticket accepted on record was read for it'
[ "$(kept)" = "$k0" ] || fail 'the switch wrote a record of an acceptance'
! grep -q '^owner/code ' "$FAKEGH/writes" || fail 'something was posted on the code repository'
: > "$FAKEGH/log"; retake; [ "$MN_RC" = 0 ] || fail "the re-take exited $MN_RC"; two 'the re-take'; grep -qx 'mode: GitHub manual, re-taken' "$T/mo" || fail 'the re-take did not go on'
! grep -q "issue view $N3 .*vid: decision " "$FAKEGH/log" || fail 'a ticket the register shows open was read for it'; [ "$(kept)" = "$k0" ] || fail 'the re-take wrote a record of an acceptance'
# one that cannot be read: refused in GitHub's words
mkdir -p "$T/w"; printf '#!/bin/sh\ncase " $* " in *" issue view %s "*startswith*) echo "HTTP 502: the read the case makes fail" >&2; exit 1 ;; esac\nexec "%s" "$@"\n' "$N2" "$T/bin/gh" > "$T/w/gh"; chmod +x "$T/w/gh"
MN_RC=0; PATH="$T/w:$PATH" sh "$CHECKS/mode.sh" manual --review "$T/review" > "$T/mo" 2>&1 || MN_RC=$?; [ "$MN_RC" = 1 ] && grep -q 'the read the case makes fail' "$T/mo" && grep -q 'run this again' "$T/mo" || fail "with GitHub failing on #$N2 the re-take exited $MN_RC, not refused in its words"
# no words: nothing written. The owner's words: both recorded, and listed no more
CLAUDE_CODE_SESSION_ID=looks; export CLAUDE_CODE_SESSION_ID; sh "$CHECKS/github.sh" lock-take looks > "$T/mo" 2>&1 || fail 'no lock'
sh "$CHECKS/round.sh" accept --tickets "$N1 $N2" --outside '' > "$T/mo" 2>&1 || fail 'with no words it did not go on to refuse each'
[ "$(grep -c "^refused #[0-9]* no words" "$T/mo")" = 2 ] && [ "$(kept)" = "$k0" ] || fail 'with no words it is not refused, or something was written'
sh "$CHECKS/round.sh" accept --tickets "$N1 $N2" --outside 'both were done before this' > "$T/mo" 2>&1 || fail 'the record was refused'
grep -q "^accepted #$N1 $(printf %.12s "$C2"), outside ViD" "$T/mo" && grep -q "^accepted #$N2 " "$T/mo" || fail 'the two were not recorded'
sh "$CHECKS/github.sh" lock-free > "$T/mo" 2>&1; unset CLAUDE_CODE_SESSION_ID
retake --words 'yes, the re-take'; [ "$MN_RC" = 0 ] || fail "the re-take after it exited $MN_RC"; ! grep -q '^looks-accepted ' "$T/mo" || fail 'a ticket on record as accepted is listed'
# withdrawn, and the take-stock in GitHub auto: not listed
N5=$(gh_issue 'Step S05'); mn_ticket "$N5" S05 step ROW-017 > ".vid/tw/out/issue-$N5.md"; gh_writing "$N5" ".vid/tw/out/issue-$N5.md" body 2; printf 'vid:ticket\n' > "$FAKEGH/issues/$N5/labels"; gh_attr "$N5" state CLOSED
printf 'published %s kind=step step=S05 rows=ROW-017 at=2026-11-18T09:00:00Z\nwithdrawn %s at=2026-11-20T09:00:00Z\n' "$N5" "$N5" >> .vid/tw/log
retake --words 'yes, the re-take'; ! grep -q '^looks-accepted ' "$T/mo" || fail 'a withdrawn ticket is listed'
sed "/^withdrawn $N5 /d" .vid/tw/log > "$T/l" && cat "$T/l" > .vid/tw/log; retake --words 'yes, the re-take'; grep -qx "looks-accepted #$N5 S05 - closed, no decision comment" "$T/mo" || fail 'the same ticket, not withdrawn, is not listed'
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-24T09:00:00Z\n' >> .vid/plan/setup; rm -f .vid/tw/applied
MN_RC=0; sh "$CHECKS/mode.sh" auto --review "$T/review" --words 'yes, the re-take' > "$T/mo" 2>&1 || MN_RC=$?; ! grep -q '^looks-accepted ' "$T/mo" || fail 'GitHub auto lists them'
# the skill
S=$CHECKS/../skills/vid-mode/SKILL.md; [ -f "$S" ] || exit 0
for x in 'looks-accepted' 'accept --tickets' 'no test evidence' 'vid-accept-step'; do grep -qF "$x" "$S" || { : > "$T/mo"; fail "vid-mode does not say: $x"; }; done
echo 'mode-looks-accepted: ok'
