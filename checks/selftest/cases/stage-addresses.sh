#!/bin/sh
# Purpose: selftest case — the owner told each address (v0.26.10.28.8, R7), checks/queue.sh on TW's toy, stage 1's candidate planted as
# stage-production.sh plants it, its deploy reads in the form results.sh writes them. With no D1 read, the status's stage line and
# `addresses 1` say the test site is not known yet and name no address; a passed D1 read names the test site as up, and no sign-in
# value; once the staging run's issue is closed, it is shown taken down after its run, never as up. The owner's production item names
# no staging address, and says the test site was taken down; with stage 1 in production (a D2 read's production line), the status and
# `addresses 1` name the live copy, and a later stage's production item names it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "stage-addresses: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; QS=$CHECKS/queue.sh; mkdir -p .vid/round .vid/decide
ad() { sh "$QS" addresses "$1" > "$T/out" 2>&1 || fail "addresses $1 failed"; }
st() { VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1 || true; grep "^stage $1: candidate " "$T/out" > "$T/line" || fail "no stage $1 line in the status"; }
it() { sh "$QS" keys > "$T/out" 2>&1 || true; grep "^production:$1:" "$T/out" > "$T/item" || fail "no production item for stage $1"; }
has() { grep -qF -- "$2" "$1" || fail "$(basename "$1") lacks: $2 — $(cat "$1")"; }; hasnt() { ! grep -qF -- "$2" "$1" || fail "$(basename "$1") holds: $2 — $(cat "$1")"; }
X=$(git --git-dir="$T/code.git" rev-parse main); C12=$(printf %.12s "$X")
plant() { F=.vid/decide/stage/$1/1; mkdir -p "$F/d1" "$F/cs"; printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"; : > "$F/named"; : > "$F/passed"; }
plant 1
# no D1 read: not known yet, no address
st 1; has "$T/line" ' · test site: not known yet'; hasnt "$T/line" 'http'
ad 1; [ "$(cat "$T/out")" = 'test site: not known yet' ] || fail "addresses with no D1: $(cat "$T/out")"
# a passed D1: the test site, up, and no sign-in value
: > "$F/d1/passed"; printf 'd1\tpassed\t1\nstaging\thttp://127.0.0.1:5001\nsignin\tsubscriber\thttp://127.0.0.1:5001/in-here\n' > "$F/d1/read"
ad 1; [ "$(cat "$T/out")" = 'test site: http://127.0.0.1:5001, up' ] || fail "addresses after D1: $(cat "$T/out")"
st 1; has "$T/line" ' · test site: http://127.0.0.1:5001, up'; hasnt "$T/line" 'in-here'; hasnt "$T/line" 'subscriber'
# the staging run's issue closed at the walk's end: taken down, never up
: > "$F/cs/passed"; printf 'issue\t3\n' > "$F/cs/ask"; : > "$F/cs/issue-closed"
ad 1; [ "$(cat "$T/out")" = 'test site: http://127.0.0.1:5001, taken down after its run' ] || fail "addresses after CS closed: $(cat "$T/out")"
st 1; has "$T/line" ' · test site: http://127.0.0.1:5001, taken down after its run'; hasnt "$T/line" ', up'
# the owner's production item: no staging address as live; the test site taken down
tw_hand "stage-closed 1 | stand-in: RM at $C12 candidate 1"; printf 'production:1:1:7\tRehearsal of %s: migrates no; outside services changing: none. Deploy to production? yes or no\n' "$C12" > "$F/yes"
it 1; has "$T/item" 'The test site was taken down after its run.'; hasnt "$T/item" '127.0.0.1:5001'; hasnt "$T/item" 'Production runs now'
# stage 1 in production: the live copy named
mkdir -p "$F/d2"; : > "$F/d2/passed"; printf 'd2\tpassed\t1\nproduction\thttp://127.0.0.1:5201\n' > "$F/d2/read"; printf '%s\tD2 #9\t2026-11-09T12:00:00Z\n' "$X" > .vid/decide/production   # close.sh's prec at a passed D2
ad 1; [ "$(sed -n 2p "$T/out")" = 'live copy: http://127.0.0.1:5201' ] || fail "addresses after D2, before its production run: $(cat "$T/out")"   # production runs it already
echo "recovered $X" > "$F/d2/closed"; printf '%s\trecovered #9\t2026-11-09T12:30:00Z\n' "$X" >> .vid/decide/production   # recovered to its own commit, before CP
ad 1; [ "$(sed -n 2p "$T/out")" = 'live copy: http://127.0.0.1:5201' ] || fail "addresses after a recovery to its own commit: $(cat "$T/out")"; rm -f "$F/d2/closed"
tw_hand "production 1 | stand-in: D2 #9 at $C12"
ad 1; [ "$(sed -n 2p "$T/out")" = 'live copy: http://127.0.0.1:5201' ] && [ "$(grep -c . "$T/out")" = 2 ] || fail "addresses in production: $(cat "$T/out")"
st 1; has "$T/line" ' · live copy: http://127.0.0.1:5201'; has "$T/line" ', taken down after its run'
# a later stage's go-live: its item names the live copy, and not that stage's test site
plant 2; : > "$F/d1/passed"; printf 'd1\tpassed\t1\nstaging\thttp://127.0.0.1:5002\n' > "$F/d1/read"; tw_hand "stage-closed 2 | stand-in: RM at $C12 candidate 1"
printf 'production:2:1:8\tRehearsal of %s: migrates no; outside services changing: none. Deploy to production? yes or no\n' "$C12" > "$F/yes"
it 2; has "$T/item" 'Production runs now at http://127.0.0.1:5201.'; hasnt "$T/item" '127.0.0.1:5002'
st 2; has "$T/line" ' · test site: http://127.0.0.1:5002, up'
# stage 2's D2 replaces production (another commit, another address): stage 1 names the new address, not its old one
Y=$(printf '%040d' 7); echo "$Y" > "$F/commit"; mkdir -p "$F/d2"; : > "$F/d2/passed"; printf 'd2\tpassed\t1\nproduction\thttp://127.0.0.1:5202\n' > "$F/d2/read"; printf '%s\tD2 #10\t2026-11-09T12:45:00Z\n' "$Y" >> .vid/decide/production
ad 2; [ "$(sed -n 2p "$T/out")" = 'live copy: http://127.0.0.1:5202' ] || fail "stage 2 after its D2: $(cat "$T/out")"
ad 1; [ "$(sed -n 2p "$T/out")" = 'live copy: http://127.0.0.1:5202' ] || fail "stage 1 after stage 2's D2 replaced production: $(cat "$T/out")"; echo "$X" > "$F/commit"
# a recovery found production running nothing (none in .vid/decide/production): no live copy is named
printf '%s\t1\t2026-11-09T12:00:00Z\nnone\t1\t2026-11-09T13:00:00Z\n' "$X" > .vid/decide/production
ad 1; hasnt "$T/out" 'live copy'; it 2; hasnt "$T/item" 'Production runs now'
echo 'stage-addresses: ok'
