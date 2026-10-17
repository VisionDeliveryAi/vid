#!/bin/sh
# Purpose: selftest case — watchdog.sh must reject an operation with no
# mechanical probe and a progress claim carrying no evidence class (§8).
# Since v0.9.3 (3.9) the probe is refused at `declare` — before the
# operation runs — rather than at the first `check` past the envelope; an
# operation file written without a probe (a pre-0.9.3 declaration) is still
# refused at `check`. Polarity: a probed exceedance reports and exits 2; an
# evidenced claim and an explicit --unverified claim are legal.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
# no probe → conviction at declare
if sh "$CHECKS/watchdog.sh" declare op-noprobe 0 >/dev/null 2>&1; then exit 1; fi
# a pre-0.9.3 operation file with no probe, past its envelope → conviction at check
mkdir -p .vid/watchdog
printf 'start=%s\nenvelope=0\nprobe=\n' "$(( $(date +%s) - 5 ))" > .vid/watchdog/op-legacy
if sh "$CHECKS/watchdog.sh" check op-legacy >/dev/null 2>&1; then exit 1; fi
# a progress claim with no evidence class → conviction
if sh "$CHECKS/watchdog.sh" claim op-legacy "still running" >/dev/null 2>&1; then exit 1; fi
# polarity: past envelope WITH a probe → probe runs, output reported, exit 2
sh "$CHECKS/watchdog.sh" declare op-probed 0 'echo container-x running' container-x >/dev/null
sleep 1
ST=0; OUT=$(sh "$CHECKS/watchdog.sh" check op-probed 2>&1) || ST=$?
[ "$ST" -eq 2 ] || exit 1
printf '%s\n' "$OUT" | grep -q 'container-x running' || exit 1
# polarity: evidenced and explicitly-unverified claims are legal
sh "$CHECKS/watchdog.sh" claim op-probed --evidence 'last test id test_req_004' "half done" >/dev/null
sh "$CHECKS/watchdog.sh" claim op-probed --unverified "no observation yet" >/dev/null
exit 0
