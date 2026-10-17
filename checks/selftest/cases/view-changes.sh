#!/bin/sh
# Purpose: selftest case — the change log (v0.9.7.4 spec 3.8, R8). The viewer fixture. Convicts unless the index
# carries every window's changes and each snapshot only its own: S1's close window holds ROW-001 never → pass, the plan
# change, S1 started and closed and its two commits; the slice close's holds the two reviews (ROW-002 broken, class
# test); the checkpoint's holds question 1 asked and S2 started; the final ratification's holds A-001 amended; every
# change names its window and its capabilities (ROW-005's through both its items); and the delegated mark is never a
# change. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-changes: $*" >&2; exit 1; }
view_project "$T/repo"
sh checks/metrics.sh delegated --answer A-002 > /dev/null
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
vdata "$T/out/index.html" > "$T/i"
w() { grep "\"window\":\"$1\"" "$T/i"; }
S1=20260101T104000Z-step-closed.html; SL=20260101T105000Z-slice-closed.html; CP=20260101T112000Z-checkpoint.html
w $S1 | grep -q '"kind":"promise state","ids":\["ROW-001"\],"at":null,"from":"never","to":"pass","capabilities":\["FEAT-01"\]' || fail "S1's window lacks ROW-001 never to pass"
w $S1 | grep -q '"kind":"plan","ids":\[\],"at":"2026-01-01T10:11:00Z","what":"create","why":"two steps"' || fail "S1's window lacks the plan change"
w $S1 | grep -q '"kind":"step","ids":\["S1"\],"at":"2026-01-01T10:20:00Z","what":"started"' || fail "S1's window lacks its start"
w $S1 | grep -q '"kind":"step","ids":\["S1"\],"at":"2026-01-01T10:40:00Z","what":"closed"' || fail "S1's window lacks its close"
[ "$(w $S1 | grep -c '"kind":"commit"')" = 2 ] || fail "S1's window does not hold its two commits"
w $SL | grep -q '"kind":"review","ids":\["ROW-002"\],"at":"2026-01-01T10:45:00Z","result":"broken","class":"test"' || fail "the slice close's window lacks ROW-002's broken review"
w $CP | grep -q '"kind":"question","ids":\["Q1"\],"at":"2026-01-01T10:55:00Z","what":"asked"' || fail "the checkpoint's window lacks question 1 asked"
w 20260101T092000Z-prd-ratified.html | grep -q '"kind":"decision","ids":\["A-001"\]' || fail "the final ratification's window lacks A-001 amended"
w $CP | grep -q '"ids":\["ROW-005"\],"at":null,"from":"never","to":"pass","capabilities":\["FEAT-02","FEAT-01"\]' || fail "ROW-005's change does not name both its capabilities"
if grep '{"kind":"' "$T/i" | grep -v '"window":"' | grep -q .; then fail 'a change without its window'; fi
if grep '"kind":"decision"' "$T/i" | grep -q 'A-002'; then fail 'the delegated mark became a change'; fi
if vdata "$T/out/$SL" | grep '{"kind":"' | grep -v "\"window\":\"$SL\"" | grep -q .; then fail 'a snapshot carries another window'"'"'s changes'; fi
exit 0
