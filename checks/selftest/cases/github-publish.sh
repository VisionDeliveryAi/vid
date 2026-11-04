#!/bin/sh
# Purpose: selftest case — what GitHub holds, kept in step (v0.26.10.9 spec R10, R11, R13, R19; §5 github-publish). The
# planner's toy (fixtures/tickets.sh gh_vid: two stages, three steps) and the fake gh: `ticket.sh skeleton-body` and
# `github.sh publish --ticket <it>` make two milestones ("Stage 1: the basics", its card the description), three step
# issues in their stages' milestones (B's body names REQ-002 with its title and "builds on #<A's issue>"), one ticket
# (the skeleton, in the first milestone, labelled vid:ready, its body part 1 with its vid-ticket header), four labels
# with the prefix, each recorded in .vid/tickets/map with `milestone … state=created` and `ticket … state=published`;
# a second publish creates nothing; the skeleton rewritten while untaken is edited in place (`state=rewritten`); once
# its branch vid/<n> exists (taken), a further change is a comment (`state=commented`). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "github-publish: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
sh checks/ticket.sh skeleton-body --req REQ-001 > "$T/out" 2>&1 || fail 'skeleton-body failed'
sh checks/github.sh publish --ticket .vid/tickets/skeleton.md > "$T/out" 2>&1 || fail 'publish failed'
[ "$(ls "$T/gh/milestones" | grep -c .)" = 2 ] || fail 'not two milestones'
[ "$(cat "$T/gh/milestones/1/title")" = 'Stage 1: the basics' ] && grep -q 'sign in and keep notes' "$T/gh/milestones/1/description" || fail "milestone 1 is not stage 1's, with its card"
[ "$(ls "$T/gh/labels" | sort | paste -sd ' ' -)" = 'vid:blocked vid:done vid:question vid:ready' ] || fail "the labels are $(ls "$T/gh/labels" | paste -sd ' ' -)"
[ "$(ls "$T/gh/issues" | grep -c .)" = 4 ] || fail "$(ls "$T/gh/issues" | grep -c .) issues, not three step issues and one ticket"
NA=$(awk '$2 == "step=A" { sub(/number=/, "", $3); print $3 }' .vid/tickets/map); NB=$(awk '$2 == "step=B" { sub(/number=/, "", $3); print $3 }' .vid/tickets/map); NC=$(awk '$2 == "step=C" { sub(/number=/, "", $3); print $3 }' .vid/tickets/map)
[ -n "$NA" ] && [ -n "$NB" ] && [ -n "$NC" ] || fail 'the step issues are not in the map'
grep -qx 'Stage 1: the basics' "$T/gh/issues/$NB/milestone" && grep -qx 'Stage 2: sharing' "$T/gh/issues/$NC/milestone" || fail 'a step issue is in the wrong milestone'
grep -q '^- REQ-002 — a person writes a note$' "$T/gh/issues/$NB/body" && grep -q "^builds on #$NA$" "$T/gh/issues/$NB/body" || fail "B's issue lacks its requirement or its builds-on"
NS=$(awk '$1 == "ticket" && / kind=skeleton / { sub(/number=/, "", $2); print $2 }' .vid/tickets/map); [ -n "$NS" ] || fail 'the skeleton ticket is not in the map'
grep -qx 'Stage 1: the basics' "$T/gh/issues/$NS/milestone" && grep -qx 'vid:ready' "$T/gh/issues/$NS/labels" || fail 'the skeleton ticket is not in the first milestone, labelled ready'
sed -n 2p "$T/gh/issues/$NS/body" | grep -q "^issue=$NS step=- stage=1 kind=skeleton part=1/1 hash=" || fail "the skeleton ticket's body is not its part 1"
[ "$(grep -c '^milestone stage=. number=. state=created' .vid/metrics-events)" = 2 ] && grep -q "^ticket issue=$NS step=- kind=skeleton state=published" .vid/metrics-events || fail 'the events are missing'
C1=$(ghn 'issue create'); M1=$(ghn 'api repos/owner/code/milestones '); L1=$(ghn 'label create')
sh checks/github.sh publish --ticket .vid/tickets/skeleton.md > "$T/out" 2>&1 || fail 'the second publish failed'
[ "$(ghn 'issue create')" = "$C1" ] && [ "$(ghn 'api repos/owner/code/milestones ')" = "$M1" ] && [ "$(ghn 'label create')" = "$L1" ] && [ "$(ghn 'issue edit')" = 1 ] || fail 'the second publish made or edited something'
# untaken: rewritten in place
sh checks/ticket.sh skeleton-body --req REQ-002 --out .vid/tickets/skeleton-2.md > "$T/out" 2>&1
sh checks/github.sh publish --ticket .vid/tickets/skeleton-2.md --issue "$NS" --why 'the golden path is REQ-002' > "$T/out" 2>&1 || fail 'the rewrite failed'
[ "$(ghn "issue edit $NS ")" = 2 ] && grep -q 'REQ-002 | functional' "$T/gh/issues/$NS/body" || fail 'the untaken ticket was not edited in place'
grep -q "^ticket issue=$NS .*state=rewritten" .vid/metrics-events || fail 'no rewritten event'
# taken: a comment
git -C "$T/dev" push -q origin "HEAD:refs/heads/vid/$NS" 2>/dev/null
sh checks/ticket.sh skeleton-body --req REQ-003 --out .vid/tickets/skeleton-3.md > "$T/out" 2>&1
sh checks/github.sh publish --ticket .vid/tickets/skeleton-3.md --issue "$NS" --why 'the golden path is REQ-003' > "$T/out" 2>&1 || fail 'the change to a taken ticket failed'
[ "$(ghn "issue edit $NS ")" = 2 ] || fail 'a taken ticket was edited'
ls "$T/gh/issues/$NS/comments"/* > /dev/null 2>&1 && grep -q 'changed after it was taken — the golden path is REQ-003' "$T/gh/issues/$NS/comments"/* || fail 'the taken ticket got no comment quoting the why'
grep -q "^ticket issue=$NS .*state=commented" .vid/metrics-events || fail 'no commented event'
exit 0
