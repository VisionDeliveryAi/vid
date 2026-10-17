#!/bin/sh
# Purpose: selftest case — the one ordinary-receipt rule in the evidence reader (v0.9.8 spec 3.4, R15). A row red on an
# ordinary receipt and passing on a newer proof receipt (its name carries .proof.) stays red: `rows` reads no proof
# receipt, nor does its --history; `credit` and `reach` credit nothing from one; `ordinary` exits 1 on a proof
# receipt and 0 on an ordinary one. The expected-empty control: with only ordinary receipts the newer pass is read.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "proof-receipt-ineligible-evidence: $*" >&2; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
printf 'ROW-001\ts1\t\nROW-002\ts1\t\n' > "$T/map"
H=$(git rev-parse --short=12 HEAD)
rcpt "$H.live.sel-1.run-a.xml" HEAD inline ROW-001=failed ROW-002=failed
P="$H.proof.sel-2.run-b.xml"
rcpt "$P" HEAD inline ROW-001=passed
st() { sh checks/evidence.sh rows --at HEAD --map "$T/map" | awk -F'\t' -v r="$1" '$1 == r { print $2 }'; }
[ "$(st ROW-001)" = red ] || fail "a newer proof receipt was read as evidence: ROW-001 is $(st ROW-001), not red"
sh checks/evidence.sh rows --at HEAD --map "$T/map" --history | awk -F'\t' '$1 == "ROW-001" { print $4 }' | grep -qF '.proof.' && fail 'the history read a proof receipt'
[ -z "$(sh checks/evidence.sh credit "$P")" ] || fail 'a proof receipt credits rows'
[ -z "$(sh checks/evidence.sh reach "$P")" ] || fail 'a proof receipt reaches rows'
sh checks/evidence.sh ordinary "$P" && fail 'ordinary says a proof receipt is ordinary'
sh checks/evidence.sh ordinary "$H.live.sel-1.run-a.xml" || fail 'ordinary says an ordinary receipt is not'
# the control: the same pass on an ordinary receipt is read
rcpt "$H.live.sel-3.run-c.xml" HEAD inline ROW-002=passed
[ "$(st ROW-002)" = pass ] || fail "the control: a newer ordinary pass is not read (ROW-002 is $(st ROW-002))"
[ -n "$(sh checks/evidence.sh credit "$H.live.sel-3.run-c.xml")" ] || fail 'the control: an ordinary receipt credits nothing'
exit 0
