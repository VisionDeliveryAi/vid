#!/bin/sh
# Purpose: selftest case — with one repository no ticket quotes the folder at an export not published into it, and tw-hand sends
# nothing the owner did not ask for (GM-4 K13, J1; S0: a direct call sends what it was asked for and nothing else). On the form
# fixture's toy (fixtures/form.sh) in GitHub manual with `layout: one` and `spec-path: upstream/vid`, the code repository holding
# main, inside a call's stage: while the newest export is in no `spec-published` line, `github.sh tw-hand publish S01 --words` is
# refused (exit 1), naming /vid:vid-spec-publish, and nothing reaches GitHub: no pull request, no issue, no published line; a
# publish of a step the plan lacks (S99) sends nothing either. Once `github.sh spec-publish` has published the export (pull request
# #<p>), tw-hand publish S01 posts, and the ticket posted names that pull request, asking for it to be merged first. The spec then
# changed and not yet published: a reopening of the ticket the team closed, which quotes no export, goes out (`reopened` logged),
# with no pull request made.
# Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "tw-hand-spec-publish: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
printf 'stage name=plan state=end session=S1 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
HOME=$T/home; export HOME; mkdir -p "$HOME"
stg() { printf 'stage name=replan state=%s session=hand%s at=%s\n' "$1" "$2" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events; }
hand() { stg start ' records=29'; RC=0; sh "$GS" tw-hand "$@" > "$T/out" 2>&1 || RC=$?; stg end ''; }
posted() { grep -q '^owner/code \(issue create\|issue edit\|issue comment\|issue close\|pr create\|git \|comment\)' "$FAKEGH/writes" 2>/dev/null; }
# the export in no spec-published line: refused, nothing sent
gh_wclear; hand publish S01 --words 'Yes, publish S01'; [ "$RC" = 1 ] || fail "tw-hand publish S01 with the export unpublished exited $RC, not 1"
grep -q '/vid:vid-spec-publish' "$T/out" || fail 'the refusal does not name /vid:vid-spec-publish'
! posted || { cp "$FAKEGH/writes" "$T/out"; fail 'tw-hand sent something to GitHub while refusing'; }
! grep -q '^published \|^spec-published ' .vid/tw/log || fail 'a ticket or a folder publish was logged while refusing'
gh_wclear; hand publish S99 --words 'Yes, publish S99'; [ "$RC" != 0 ] || fail 'a step the plan lacks was published'
! posted || { cp "$FAKEGH/writes" "$T/out"; fail 'a refused command for a step the plan lacks sent something to GitHub'; }
# published: the ticket goes out naming the folder's pull request
sh "$GS" spec-publish > "$T/out" 2>&1 || fail 'spec-publish failed'
P=$(sed -n 's/^spec-published pr=\([0-9]*\) .*/\1/p' .vid/tw/log | tail -n 1); [ -n "$P" ] || fail 'the folder publish logged no pull request'
hand publish S01 --words 'Yes, publish S01'; [ "$RC" = 0 ] || fail "tw-hand publish S01, the export published, exited $RC"
N=$(awk '$1 == "published" { print $2 }' .vid/tw/log | tail -n 1); [ -n "$N" ] || fail 'S01 was not published'
grep -rq "pull request #$P" "$FAKEGH/issues/$N" || fail "the ticket posted, #$N, does not name the folder's open pull request #$P"
# the spec changed, not yet published: a reopening goes out, and no pull request is made
echo 'A new line for the spec.' >> PRD.md; g commit -qam 'the spec changed'; git rev-parse HEAD > .vid/tw/applied
tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified again on the changed spec'
echo CLOSED > "$FAKEGH/issues/$N/state"   # the team closed it
gh_wclear; hand reopen "$N" --words "Yes, reopen #$N"; [ "$RC" = 0 ] || fail "a reopening with the export unpublished exited $RC"
grep -q "^reopened $N " .vid/tw/log || fail "#$N's reopening was not logged"
! grep -q '^owner/code \(pr create\|git \)' "$FAKEGH/writes" || { cp "$FAKEGH/writes" "$T/out"; fail 'the reopening sent a folder publish with it'; }
exit 0
