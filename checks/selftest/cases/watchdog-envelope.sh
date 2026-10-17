#!/bin/sh
# Purpose: selftest case — an envelope is whole seconds (v0.9.5 spec 3.3,
# R3; §7 case 26). Convicts unless `watchdog.sh declare` refuses `the fix
# pass` and `90m` as envelopes (writing no operation file) and accepts
# `5400`, and a re-declare refuses the same while keeping the declared
# envelope. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
W() { sh "$CHECKS/watchdog.sh" "$@"; }   # quoted: a project path may hold a space
fail() { echo "watchdog-envelope: $*" >&2; exit 1; }
for e in 'the fix pass' 90m; do
  if W declare fix-pass "$e" 'kill -0 4242 # fix-pass' 4242 >/dev/null 2>&1; then fail "the envelope '$e' was accepted"; fi
  [ ! -f .vid/watchdog/fix-pass ] || fail "a refused envelope '$e' wrote the operation"
done
W declare fix-pass 5400 'kill -0 4242 # fix-pass' 4242 >/dev/null || fail 'the envelope 5400 was refused'
for e in 'the fix pass' 90m; do
  if W declare fix-pass "$e" >/dev/null 2>&1; then fail "a re-declare to '$e' was accepted"; fi
done
grep -qx 'envelope=5400' .vid/watchdog/fix-pass || fail 'a refused re-declare changed the envelope'
exit 0
