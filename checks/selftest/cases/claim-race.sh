#!/bin/sh
# Purpose: selftest case — the claim is race-free (v0.26.10.9 spec R22; §5 claim-race). The planner's toy publishes
# the skeleton ticket; two stand-in workers, each in its own clone, find it with `github.sh next-ticket` and claim it
# at the same moment: exactly one `claim` succeeds; the other is refused and changes nothing (no claim file, the
# branch untouched); the branch vid/<n> is the winner's claim commit, `claim #<n> worker-<k>` with its Stand-in:
# trailer, whose parent is the ticket's base. A second ticket claimed one after the other: the first claimant wins,
# the second is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "claim-race: $*" >&2; cat "$T/o1" "$T/o2" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
sh checks/ticket.sh skeleton-body --req REQ-001 > /dev/null 2>&1 && sh checks/github.sh publish --ticket .vid/tickets/skeleton.md > /dev/null 2>&1 || fail 'the ticket was not published'
N=$(awk '$1 == "ticket" { sub(/number=/, "", $2); print $2 }' .vid/tickets/map); BASE=$(git -C .vid/code rev-parse origin/main)
gh_worker "$T/w1" && gh_worker "$T/w2" || fail 'the clones failed'
for k in 1 2; do [ "$(cd "$T/w$k" && sh "$CHECKS/github.sh" next-ticket --worker $k)" = "next $N" ] || fail "worker $k does not find ticket $N"; done
( cd "$T/w1" && if sh "$CHECKS/github.sh" claim "$N" --worker 1 > "$T/o1" 2>&1; then echo 0; else echo 1; fi > "$T/r1" ) &
( cd "$T/w2" && if sh "$CHECKS/github.sh" claim "$N" --worker 2 > "$T/o2" 2>&1; then echo 0; else echo 1; fi > "$T/r2" ) &
wait
R="$(cat "$T/r1")$(cat "$T/r2")"; case "$R" in 01) WIN=1; LOSE=2 ;; 10) WIN=2; LOSE=1 ;; *) fail "the claims exited $R — not exactly one success" ;; esac
grep -q 'claim refused' "$T/o$LOSE" || fail 'the loser was not told the claim was refused'
[ ! -f "$T/w$LOSE/.git/vid/tickets/$N/claim" ] || fail 'the loser recorded a claim'
CC=$(sed -n 's/^claim=\([^ ]*\).*/\1/p' "$T/w$WIN/.git/vid/tickets/$N/claim")
[ "$(git -C "$T/code.git" rev-parse "refs/heads/vid/$N")" = "$CC" ] || fail "the branch is not the winner's claim commit"
[ "$(git -C "$T/code.git" rev-parse "refs/heads/vid/$N^")" = "$BASE" ] || fail 'the claim commit is not on the base'
git -C "$T/code.git" log -1 --format=%B "refs/heads/vid/$N" | grep -qx "Stand-in: worker-$WIN" && git -C "$T/code.git" log -1 --format=%s "refs/heads/vid/$N" | grep -qx "claim #$N worker-$WIN" || fail 'the claim commit lacks its message or trailer'
[ -f "$T/w$WIN/.git/vid/tickets/$N/ticket.md" ] || fail "the winner's ticket was not fetched"
# one after the other
sh checks/ticket.sh skeleton-body --req REQ-002 --out .vid/tickets/skeleton-b.md > /dev/null 2>&1 && sh checks/github.sh publish --ticket .vid/tickets/skeleton-b.md > /dev/null 2>&1 || fail 'the second ticket was not published'
N2=$(awk '$1 == "ticket" { sub(/number=/, "", $2); n = $2 } END { print n }' .vid/tickets/map); [ "$N2" != "$N" ] || fail 'no second ticket'
for k in 1 2; do [ "$(cd "$T/w$k" && sh "$CHECKS/github.sh" next-ticket --worker $k)" = "next $N2" ] || fail "worker $k does not find ticket $N2"; done
( cd "$T/w1" && sh "$CHECKS/github.sh" claim "$N2" --worker 1 ) > "$T/o1" 2>&1 || fail 'the first sequential claim failed'
H=$(git -C "$T/code.git" rev-parse "refs/heads/vid/$N2")
if ( cd "$T/w2" && sh "$CHECKS/github.sh" claim "$N2" --worker 2 ) > "$T/o2" 2>&1; then fail 'the second sequential claim succeeded'; fi
[ "$(git -C "$T/code.git" rev-parse "refs/heads/vid/$N2")" = "$H" ] || fail 'the refused claim moved the branch'
exit 0
