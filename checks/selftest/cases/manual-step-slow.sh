#!/bin/sh
# Purpose: selftest case — the step-time trigger (GM-4 E10, GM M11), next.sh triggers in GitHub manual on the toy and the fake gh
# (fixtures/accept.sh). Three step tickets accepted 2, 4 and 6 days after their publication (the median 4): an open step ticket out 9
# days is raised, `trigger important step-slow <its step>`, its evidence the ticket, its days out and the median; one out 7 days is
# not. With two accepted, none is raised. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-step-slow: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
iso() { date -u -r "$1" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "@$1" '+%Y-%m-%dT%H:%M:%SZ'; }
ac_project "$T/p" || fail 'the toy could not be made'; NOW=$(date -u +%s); D=86400; mkdir -p .vid/decide; : > .vid/tw/log; : > .vid/decide/accepted-at
k=0; for d in 2 4 6; do k=$((k + 1)); n=$(gh_issue "Done $k"); p=$((NOW - 20 * D)); printf 'published %s kind=step step=S0%s rows=ROW-001 at=%s\n' "$n" "$k" "$(iso "$p")" >> .vid/tw/log
  printf 'step-%s %s 0123456789ab at=%s\n' "$n" "$n" "$(iso $((p + d * D)))" >> .vid/decide/accepted-at; done
A=$(gh_issue 'Slow'); printf 'published %s kind=step step=S05 rows=ROW-012 at=%s\n' "$A" "$(iso $((NOW - 9 * D)))" >> .vid/tw/log
B=$(gh_issue 'Not slow'); printf 'published %s kind=step step=S06 rows=ROW-006 at=%s\n' "$B" "$(iso $((NOW - 7 * D)))" >> .vid/tw/log
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'the read failed'
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
grep -q "^trigger	important	step-slow	S05	#$A out 9 days; the median from publish to first acceptance 4 days" "$T/out" || fail 'the ticket past twice the median is not raised'
! grep -q "step-slow	S06" "$T/out" || fail 'a ticket under twice the median was raised'
sed -i.b '1d' .vid/decide/accepted-at; rm -f .vid/decide/accepted-at.b
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed with two accepted'; ! grep -q 'step-slow' "$T/out" || fail 'raised with two accepted'
exit 0
