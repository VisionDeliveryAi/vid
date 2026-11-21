#!/bin/sh
# Purpose: selftest case — an amendment in GitHub manual changes only the first line of a body that is ViD's own part 1, and nothing
# of one whose first line the team changed (GM-2 T5; its case manual-amend-part-body). On the form fixture's toy (fixtures/form.sh),
# S02 and S03 posted in GitHub auto, as /vid run posts them with no issue-form: set (the body ViD's part 1, its first line
# `Ticket #<n>, part 1 of <m>, writing <h>.`; GM-4 F6: with the form set they would go out in it), then the project back in
# GitHub manual, the form set again. The team edits S03's body's first line. ROW-002 moves from S04 into S02
# and ROW-011 into S03, by one recorded plan change. Both amended on the owner's words; each title stands; S02's body is its body
# with its first line alone changed, now saying it is replaced and naming the current writing; S03's body stands byte for byte, and
# its notice names its first line as left as the team changed it. The team then changes S02's first line
# in its count alone (`part 1 of <m>` to another number, the header's form kept); S02 gains ROW-018 and is amended again: its body
# stands byte for byte, and the notice names its first line. Before S02's first amendment the team takes
# ROW-013 out of its body (S02 then has no kept body record); next.sh changes lists it dropped, and after the amendment, which seeds
# the kept body from part 1 of the recorded writing, it is listed dropped again. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"; . "$CHECKS/selftest/fixtures/amend.sh"
fail() { echo "manual-amend-part-body: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
# S02 and S03 posted in GitHub auto, then GitHub manual again
printf 'setup-answered key=github-mode value="auto" words="auto, for the toy" at=2026-11-19T09:10:00Z\n' >> .vid/plan/setup
grep '^issue-form:' .vid/tw/settings > "$T/form-key"; grep -v '^issue-form:' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings   # GM-4 F6
tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified in auto'
for s in S02 S03; do fm_prep "$s" || { cp "$T/post" "$T/out"; fail "$s's ticket could not be written in auto"; }
  sh "$CHECKS/github.sh" tw-post "$FM_F" > "$T/post" 2>&1 || { cp "$T/post" "$T/out"; fail "$s was not posted in auto"; }; done
N2=$(awk '$1 == "published" && / step=S02 / { print $2 }' .vid/tw/log); N3=$(awk '$1 == "published" && / step=S03 / { print $2 }' .vid/tw/log)
printf 'setup-answered key=github-mode value="manual" words="by hand again" at=2026-11-19T09:20:00Z\n' >> .vid/plan/setup
cat "$T/form-key" >> .vid/tw/settings
I=$FAKEGH/issues
for n in $N2 $N3; do head -n 1 "$I/$n/body" | grep -qE "^Ticket #$n, part 1 of [0-9]+, writing [0-9a-f]+\.\$" || fail "#$n's body is not ViD's part 1"; cp "$I/$n/title" "$T/title.$n"; done
fm_team_edit "$N3" '1s/$/ (the team keeps its own notes below)/'
# the team takes ROW-013 out of S02's body, which has no kept body record
fm_team_edit "$N2" 's/ ROW-013,\{0,1\}//g; /ROW-013/d'; ! grep -q ROW-013 "$I/$N2/body" && [ ! -f ".vid/tw/body/issue-$N2" ] || fail "the team's removal of ROW-013 did not take, or S02 has a kept body"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed'; }
awk -F'\t' -v n="$N2" '$1 == "dropped" && $2 == n && $3 == "ROW-013"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail "ROW-013 is not listed dropped from #$N2"; }
cp "$I/$N2/body" "$T/b2"; cp "$I/$N3/body" "$T/b3"
# ROW-002 into S02 and ROW-011 into S03, one recorded change
am_move ROW-002 S04 S02; am_move ROW-011 S04 S03; am_change "$N2" 'S02 and S03 take a row of S04 each' || { cp "$T/chg" "$T/out"; fail 'the plan change was refused'; }
am_amend "$N2" "Yes, amend #$N2" || { cp "$T/post" "$T/out"; fail "#$N2 was not amended in manual"; }
am_amend "$N3" "Yes, amend #$N3" || { cp "$T/post" "$T/out"; fail "#$N3 was not amended in manual"; }
for n in $N2 $N3; do cmp -s "$T/title.$n" "$I/$n/title" || fail "#$n's title changed: $(cat "$I/$n/title")"; done
# S02: the first line alone
W2=$(for k in $(ls "$I/$N2/comments" | sort -n); do head -n 1 "$I/$N2/comments/$k"; done | sed -n "s/^Ticket #$N2, part 1 of [0-9]*, writing \([0-9a-f]*\)\.\$/\1/p" | tail -n 1)
[ -n "$W2" ] || fail "#$N2 has no part comment of its new writing"
sed 1d "$T/b2" > "$T/r2"; sed 1d "$I/$N2/body" > "$T/r2n"
cmp -s "$T/r2" "$T/r2n" || { diff "$T/r2" "$T/r2n" > "$T/out" || :; fail "#$N2's body changed past its first line"; }
F1=$(head -n 1 "$I/$N2/body"); case "$F1" in "$(head -n 1 "$T/b2" | sed 's/\.$//')"*"replaced"*"$W2"*) ;; *) fail "#$N2's first line does not say it is replaced, naming the current writing $W2: $F1" ;; esac
# S03: nothing, its first line named as left
cmp -s "$T/b3" "$I/$N3/body" || { diff "$T/b3" "$I/$N3/body" > "$T/out" || :; fail "#$N3's body changed though the team changed its first line"; }
am_comment "$N3" 'vid: amended' > "$T/am"; cp "$T/am" "$T/out"; grep -q 'first line' "$T/am" || fail "#$N3's notice does not name its first line as left"
am_read || { cat "$T/rd" "$T/ch" > "$T/out"; fail 'next.sh read or changes failed after the amendments'; }
awk -F'\t' -v n="$N2" '$1 == "dropped" && $2 == n && $3 == "ROW-013"' "$T/ch" | grep -q . || { cp "$T/ch" "$T/out"; fail "ROW-013's unanswered removal from #$N2 is no longer listed after the amendment"; }
# S02's first line changed in its count alone, the header's form kept
fm_team_edit "$N2" '1s/, part 1 of \([0-9]*\), /, part 1 of 9\1, /'; head -n 1 "$I/$N2/body" | grep -q ', part 1 of 9[0-9]*, ' || fail "the team's count edit did not take"
cp "$I/$N2/body" "$T/b2b"
am_move ROW-018 S04 S02; am_change "$N2" 'S02 takes ROW-018' || { cp "$T/chg" "$T/out"; fail 'the second plan change was refused'; }
am_amend "$N2" "Yes, amend #$N2 again" || { cp "$T/post" "$T/out"; fail "#$N2 was not amended a second time"; }
cmp -s "$T/b2b" "$I/$N2/body" || { diff "$T/b2b" "$I/$N2/body" > "$T/out" || :; fail "#$N2's body changed though the team changed its first line's count"; }
am_comment "$N2" 'vid: amended' > "$T/am"; cp "$T/am" "$T/out"; grep -q 'first line' "$T/am" || fail "#$N2's second notice does not name its first line as left"
exit 0
