#!/bin/sh
# Purpose: selftest case — with `spec-publish: hand` the team publishes the folder by its own process, and ViD prepares and reads
# (FB-3 B1). On the form fixture's toy (fixtures/form.sh) in GitHub manual with `layout: one`, `spec-path: upstream/vid`,
# `spec-stamp: STAMP` and `spec-publish: hand`, the code repository holding main. The folder not there: refused (exit 1) naming it,
# nothing written to GitHub, the export's files laid out in .vid/spec-out/<12>/files/ with changes.tsv, and a ticket still refused.
# The team's own pull request, its branch off another branch of the team's, with a README of theirs and a stamp in their form: `spec-publish
# #<n>` logs `spec-published pr=<n> … by=hand words="…"`, writes nothing to GitHub, and tw-hand publishes S01 naming #<n>; called
# again with no number, nothing more. A second export whose pull request differs in one file: refused, the file named, `changed` in
# changes.tsv, nothing logged; put right and merged, called with no number: main read, `pr=-`. A file dropped from the spec and still
# there is `gone` in changes.tsv. A number GitHub has no pull request of is refused; so is a pull request closed and not merged, and a number without `hand`. Main's fetch
# failing: unfinished, exit 5, with the marker. Back to `vid`, the same export: published already, no publish ticket, nothing closed;
# a newer export's own publish never closes the team's open pull request, and deletes no file the team's publish put there. In GitHub auto ViD publishes with
# `hand` too. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-hand: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; C=$T/code.git; SG=.vid/spec.git
fm_toy "$T/toy" || fail 'the toy could not be made'
set_() { grep -v "^spec-publish:" .vid/tw/settings > "$T/s" || true; echo "spec-publish: $1" >> "$T/s"; cat "$T/s" > .vid/tw/settings; }
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\nspec-stamp: STAMP\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings; set_ hand
mkdir -p design; echo 'one' > design/a.md; g add design; g commit -qm 'a design'; git rev-parse HEAD > .vid/tw/applied
tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified'
printf 'stage name=plan state=end session=S1 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
HOME=$T/home; export HOME; mkdir -p "$HOME"
stg() { printf 'stage name=replan state=%s session=hand%s at=%s\n' "$1" "$2" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; }
hand() { stg start ' records=29'; RC=0; sh "$GS" tw-hand "$@" > "$T/out" 2>&1 || RC=$?; stg end ''; }
sp() { gh_wclear; RC=0; sh "$GS" spec-publish "$@" > "$T/out" 2>&1 || RC=$?; }
quiet() { ! grep -q . "$FAKEGH/writes" 2>/dev/null || { cp "$FAKEGH/writes" "$T/out"; fail "$1 wrote to GitHub"; }; }
npub() { grep -c '^spec-published ' .vid/tw/log || true; }
ex() { sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'; E=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log); E12=$(printf %.12s "$E"); }
tg() { git -C "$T/dev" -c user.name=team -c user.email=team@example.invalid "$@" > /dev/null 2>&1 || fail "the team's clone: $*"; }
# fold: the export's files put into the team's checkout, as the team does it by hand from the laid-out files
fold() { D=$T/dev/upstream/vid; mkdir -p "$D"; git --git-dir="$SG" archive "$E" | tar -x -C "$D"; }
# pr <branch>: the team's pull request of its branch, its head as GitHub keeps it
pr() { tg push -q -f origin "$1"; N=$(gh pr create -R owner/code --head "$1" --base main --title 'docs: the spec' --body 'ours' | sed 's|.*/||'); pull; }
pull() { git --git-dir="$C" update-ref "refs/pull/$N/head" "$(git --git-dir="$C" rev-parse "refs/heads/$(cat "$FAKEGH/prs/$N/head")")"; }
# the folder not there
ex; sp; [ "$RC" = 1 ] || fail "with no folder on main, spec-publish exited $RC, not 1"; quiet 'the refusal'; [ "$(npub)" = 0 ] || fail 'a folder that is not there was logged'
tail -n 1 "$T/out" | grep -q 'upstream/vid' || fail 'the refusal does not name the folder'
git --git-dir="$SG" ls-tree -r --name-only "$E" > "$T/xf"; for f in $(cat "$T/xf"); do [ "$(git hash-object --no-filters ".vid/spec-out/$E12/files/$f" 2>/dev/null)" = "$(git --git-dir="$SG" rev-parse "$E:$f")" ] || fail "the laid-out $f is not the export's"; grep -qx "new	$f" ".vid/spec-out/$E12/changes.tsv" || fail "changes.tsv does not say $f is new"; done
[ "$(find ".vid/spec-out/$E12/files" -type f | grep -c .)" = "$(grep -c . "$T/xf")" ] || fail 'the laid-out folder holds more than the export'
[ ! -f .vid/tw/spec-owed ] || fail 'a refusal left the unfinished marker'
gh_wclear; hand publish S01 --words 'Yes, publish S01'; [ "$RC" = 1 ] && grep -q '/vid:vid-spec-publish' "$T/out" || fail "a ticket went out with the folder not there ($RC)"
# the team's own pull request, off another branch of the team's
tg checkout -q -b team/earlier; echo x > "$T/dev/other.txt"; tg add -A; tg commit -qm 'another publish, open'; tg checkout -q -b team/spec
fold; echo 'ours' > "$D/README.md"; printf 'commit: %s\n' "$E" > "$D/STAMP"; tg add -A; tg commit -qm 'the spec'; pr team/spec; N1=$N
sp '#999'; [ "$RC" = 1 ] && [ "$(npub)" = 0 ] || fail "a pull request GitHub does not have: exit $RC"
# closed and not merged: no publish
echo CLOSED > "$FAKEGH/prs/$N1/state"; sp "#$N1"; [ "$RC" = 1 ] && [ "$(npub)" = 0 ] || fail "a closed pull request, not merged, was taken as a publish (exit $RC)"
tail -n 1 "$T/out" | grep -q "#$N1 .*closed" || fail "the refusal does not name the closed pull request #$N1"; quiet 'the refusal of a closed pull request'; echo OPEN > "$FAKEGH/prs/$N1/state"
sp "#$N1" --words 'Yes, that one'; [ "$RC" = 0 ] || fail "spec-publish #$N1 exited $RC"; quiet "spec-publish #$N1"
grep '^spec-published ' .vid/tw/log | tail -n 1 | grep -qE "^spec-published pr=$N1 export=$E12 path=upstream/vid stamp=STAMP at=[^ ]+ by=hand words=\"Yes, that one\"\$" || fail "the line is not the hand publish's: $(grep '^spec-published ' .vid/tw/log | tail -n 1)"
sp; [ "$RC" = 0 ] && [ "$(npub)" = 1 ] || fail "called again: exit $RC, or logged again"; quiet 'the call again'
hand publish S01 --words 'Yes, publish S01'; [ "$RC" = 0 ] || fail "tw-hand publish S01, the folder in #$N1, exited $RC"
I=$(awk '$1 == "published" { print $2 }' .vid/tw/log | tail -n 1); [ -n "$I" ] && grep -rq "pull request #$N1" "$FAKEGH/issues/$I" || fail "the ticket does not name the team's pull request #$N1"
# a second export, the design dropped: one file of the team's pull request differs
echo 'A new line for the spec.' >> PRD.md; git rm -q design/a.md; g commit -qam 'the spec changed'; git rev-parse HEAD > .vid/tw/applied; ex
tg checkout -q -b team/spec-2; fold; echo 'a slip' >> "$D/PRD.md"; tg add -A; tg commit -qm 'the spec again'; pr team/spec-2; N2=$N
sp "#$N2"; [ "$RC" = 1 ] && [ "$(npub)" = 1 ] || fail "a pull request with a differing file: exit $RC, or logged"; quiet 'the refusal of a differing file'
tail -n 1 "$T/out" | grep -q 'PRD.md' || fail 'the refusal does not name PRD.md'; grep -qx 'changed	PRD.md' ".vid/spec-out/$E12/changes.tsv" || fail 'changes.tsv does not say PRD.md changed'
grep -qx 'gone	design/a.md' ".vid/spec-out/$E12/changes.tsv" || fail 'changes.tsv does not name the dropped file still there'
[ "$(cut -f1 ".vid/spec-out/$E12/changes.tsv" | sort | uniq -c | awk '{ printf "%s %s;", $1, $2 }')" = '1 changed;1 gone;' ] || fail "changes.tsv holds more: $(paste -sd ' ' ".vid/spec-out/$E12/changes.tsv")"
fold; tg add -A; tg commit -qm 'put right'; tg push -q origin team/spec-2; pull; gh pr merge "$N2" -R owner/code --merge > /dev/null || fail 'the fake could not merge'
# main's fetch failing: unfinished
mv "$T/bin/gh" "$T/bin/gh-fake"; printf '#!/bin/sh\nif [ "$1 $2 $3" = "repo view owner/code" ] && [ -f "%s/down" ]; then echo "a 502" >&2; exit 1; fi\nexec "%s" "$@"\n' "$T" "$T/bin/gh-fake" > "$T/bin/gh"; chmod +x "$T/bin/gh"
touch "$T/down"; sp; rm -f "$T/down"; [ "$RC" = 5 ] && [ "$(cat .vid/tw/spec-owed 2>/dev/null)" = "$E12" ] || fail "a failed read of the code repository exited $RC, or left no marker"
sp; [ "$RC" = 0 ] || fail "with the folder merged, spec-publish exited $RC"; quiet 'the read of main'; [ ! -f .vid/tw/spec-owed ] || fail 'the marker stayed'
grep '^spec-published ' .vid/tw/log | tail -n 1 | grep -qE "^spec-published pr=- export=$E12 path=upstream/vid stamp=STAMP at=[^ ]+ by=hand\$" || fail "main's hand publish is not logged with pr=-: $(grep '^spec-published ' .vid/tw/log | tail -n 1)"
# a vid publish again: the same export is published; a newer one is ViD's own, the team's open pull request left as it is
set_ vid; sp; [ "$RC" = 0 ] && grep -q 'already' "$T/out" || fail "the same export, back to vid, exited $RC"; quiet 'the same export, back to vid'
sp "#$N2"; [ "$RC" = 1 ] || fail "a pull request's number without hand exited $RC"
echo 'Another line.' >> PRD.md; g commit -qam 'the spec changed again'; git rev-parse HEAD > .vid/tw/applied; ex; sp; [ "$RC" = 0 ] || fail "ViD's own publish exited $RC"
[ "$(cat "$FAKEGH/prs/$N1/state")" = OPEN ] && [ "$(ls "$FAKEGH/prs/$N1/comments" 2>/dev/null | grep -c . || true)" = 0 ] || fail "the team's open pull request #$N1 was closed or commented on"
# a file the team's own publish put there, dropped from the spec since, is the team's: it stays
git --git-dir="$C" cat-file -e "refs/heads/$(cat "$FAKEGH/prs/$(sed -n 's/^spec-published pr=\([0-9]*\) .*/\1/p' .vid/tw/log | tail -n 1)/head"):upstream/vid/design/a.md" 2> /dev/null || fail 'ViD'"'"'s own publish deleted a file the team'"'"'s publish put there'
grep '^spec-published ' .vid/tw/log | tail -n 1 | grep -qv ' by=hand' || fail 'ViD'"'"'s own publish says by=hand'
! grep -q '^spec-replaced ' .vid/tw/log || fail 'a team'"'"'s pull request was logged replaced'
# GitHub auto: ViD publishes, whatever the key says
set_ hand; printf 'setup-answered key=github-mode value="auto" words="DevAgent" at=2026-11-19T10:00:00Z\n' >> .vid/plan/setup; echo 'A line in auto.' >> PRD.md; g commit -qam 'the spec in auto'; ex; sp
[ "$RC" = 0 ] && grep '^spec-published ' .vid/tw/log | tail -n 1 | grep -qE "^spec-published pr=[0-9]+ export=$E12 " && grep -q '^owner/code pr create' "$FAKEGH/writes" || fail "in GitHub auto with hand, ViD's own publish did not go out ($RC)"
sp "#$N2"; [ "$RC" = 1 ] || fail "in GitHub auto a pull request's number was read as a hand publish ($RC)"
echo 'spec-publish-hand: ok'
