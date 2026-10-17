#!/bin/sh
# Purpose: selftest case — a hold no open question names is flagged (v0.9.8.1 R30, F-19). The hold-flags fixture:
# ROW-001 held reason=rounds and no question asked: `metrics.sh closure` prints `hold FLAG unqueued row=ROW-001
# reason=rounds` after its closure lines, which are unchanged, and the observer's resume prints it too. The quiet
# controls: an open question gating ROW-001, then one gating `all`, flag nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"; . "$CHECKS/selftest/fixtures/hold-flags.sh"
fail() { echo "hold-flag-unqueued: $*" >&2; sh checks/metrics.sh closure >&2 2>/dev/null; exit 1; }
hf_repo
[ "$(sh checks/metrics.sh row-state --table | awk -F'\t' '$1 == "ROW-001" { print $5 }')" = rounds ] || fail 'the fixture row is not held'
sh checks/metrics.sh closure > "$T/c1"
grep -qx 'hold FLAG unqueued row=ROW-001 reason=rounds' "$T/c1" || fail 'an unqueued hold is not flagged'
[ "$(grep -n '^hold FLAG' "$T/c1" | cut -d: -f1)" -gt "$(grep -n '^closure later' "$T/c1" | cut -d: -f1)" ] || fail 'the flag is not after the closure lines'
grep -q '^hold FLAG .*ROW-002' "$T/c1" && fail 'an unheld row was flagged'
sh checks/observe.sh resume > "$T/r" 2>&1 || true
grep -q '^resume: hold FLAG unqueued row=ROW-001 reason=rounds' "$T/r" || fail "resume does not print the flag: $(grep 'held\|FLAG' "$T/r")"
hf_ev 'question n=4 state=asked gates=ROW-001 at=2026-10-02T09:03:00Z'
sh checks/metrics.sh closure > "$T/c2"
[ -z "$(flags)" ] || fail "a hold its open question names was flagged: $(flags)"
grep -v '^hold FLAG' "$T/c1" | cmp -s - "$T/c2" || fail 'the closure lines changed with the flag'
hf_ev 'question n=4 state=answered at=2026-10-02T09:04:00Z'; hf_ev 'question n=5 state=asked gates=all at=2026-10-02T09:05:00Z'
[ -z "$(flags)" ] || fail "a hold under an open question gating all was flagged: $(flags)"
exit 0
