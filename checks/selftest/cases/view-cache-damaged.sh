#!/bin/sh
# Purpose: selftest case — no trust without a check (v0.9.7.4 spec 3.5, R6). The viewer fixture. After a first run:
# one cached data entry altered by a byte, another's hash file removed, and a stray file with a malformed key planted.
# Convicts unless the next run deletes the stray file and says so, recomputes exactly the two damaged moments
# saying each failed its hash, and every page then passes the contract's check. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-cache-damaged: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r1" 2>&1 || fail "the first run failed: $(cat "$T/r1")"
D="$T/out/.cache/data"
fpof() { vdata "$T/out/$1" | sed -n 's/.*"fingerprint":"\([0-9a-f]*\)".*/\1/p'; }
A=$(fpof 20260101T100000Z-setup-done.html); B=$(fpof 20260101T105000Z-slice-closed.html)
[ -n "$A" ] && [ -n "$B" ] && [ -f "$D/$A.json" ] && [ -f "$D/$B.sum" ] || fail 'the cache entries are not where they should be'
printf ' ' >> "$D/$A.json"; rm -f "${D:?}/${B:?}.sum"; printf 'x\n' > "$D/not-a-key.json"
vview . --out "$T/out" > "$T/r2" 2>&1 || fail "the second run failed: $(cat "$T/r2")"
grep -q 'a cache entry with a malformed key (not-a-key.json) deleted' "$T/r2" || fail "the stray file is not reported: $(cat "$T/r2")"
[ ! -e "$D/not-a-key.json" ] || fail 'the stray file is still there'
grep -q 'the cached data of 20260101T100000Z-setup-done.html failed its hash' "$T/r2" || fail "the altered entry is not reported: $(cat "$T/r2")"
grep -q 'the cached data of 20260101T105000Z-slice-closed.html failed its hash' "$T/r2" || fail "the entry without its hash is not reported: $(cat "$T/r2")"
[ "$(grep -c '^ViD view: computed ' "$T/r2")" = 2 ] || fail "not exactly the two damaged moments were computed: $(grep computed "$T/r2")"
for f in "$T"/out/*.html; do sh "$VIEWER_SH" --check "$f" > "$T/c" 2>&1 || fail "$(basename "$f") fails the check: $(cat "$T/c")"; done
exit 0
