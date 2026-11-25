#!/bin/sh
# Purpose: selftest case — a known limit stays on the later runs, and its result stops nothing (FB-7 A3), checks/close.sh on the writer's toy
# and the fake gh. Ruled before the ask, an earlier stage's row too, it is asked in the full run, in the staging run (a deploy-owed one too) and in the production run's golden path, where
# one marked owed-staging or seam is asked as well; it is packed with other rows, never in a chunk of limits alone; a run with limits alone asks
# none. Red, unrun or split between engines, it stops no run, gets no fix line, no engine-split line, pays nothing and asks no stand-in
# of the owner; the staging okay lists no outside-service row of it. A step's close leaves it out, as before. Env: CHECKS.
set -eu
HOME=$(mktemp -d); export HOME; unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T" "$HOME"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
. "$CHECKS/selftest/fixtures/closes.sh"
fail() { echo "limit-still-run: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
CL_NOASK=1; cl_toy; limit ROW-002; limit ROW-003 20; limit ROW-006; limit DIF-001; limit SEAM-002; sed 's/^close-chunk-minutes: 20$/close-chunk-minutes: 1/' .vid/tw/settings > "$T/s"; cat "$T/s" > .vid/tw/settings
# the full run: asked, never in a chunk of limits alone; red in one engine and passed in the other
cl_ask; for r in ROW-001 ROW-002 ROW-003 ROW-006; do awk -F'\t' -v r=" $r " '$1 == "chunk" && index(" " $4 " ", r) { f = 1 } END { exit !f }' $K/ask || fail "the full run leaves out $r: $(cat $K/ask)"; done
awk -F'\t' '$1 == "chunk" && $2 != "p1cx" { n = split($4, a, " "); f = 0; for (i = 1; i <= n; i++) if (a[i] !~ /^ROW-00[236]$/) f = 1; if (!f) b = 1 } END { exit b }' $K/ask || fail "a chunk of known limits alone: $(cat $K/ask)"
ROWS=$(awk -F'\t' '$1 == "chunk" { print $4 }' $K/ask | tr ' ' '\n' | sort -u | grep . | paste -sd ' ' -); N=$C3N; cl_s1; rq p1c1-1 "$X" alpha $(allof pass ROW-002=fail:x); rq p2c1-1 "$X" beta $(allof pass ROW-006='err:setup: x'); rq p1cx-1 "$X" alpha test_other=pass; fetch; cs decide --stage 1
ok '^stage-c3 1 passed$'; no '^split '; ! grep -q '^engine-split' .vid/tw/handed || fail 'a known limit split the engines'; ! grep -q '^fix ' .vid/tw/handed || fail 'a fix line for a known limit'
# the okay and the staging run
cs okay --stage 1; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out"); grep -qx 'outside-service rows: SEAM-001' "$T/gh/issues/$O/body" || fail "the okay's outside-service rows: $(grep '^outside-service' "$T/gh/issues/$O/body")"; rm -rf $K/d1; cl_d1
cs ask --cs 1; CSN=$(sed -n 's/^asked \([0-9]*\) cs stage-1$/\1/p' "$T/out"); ROWS=$(awk -F'\t' '$1 == "chunk" { print $4 }' $K/cs/ask | tr ' ' '\n' | sort -u | grep . | paste -sd ' ' -); for r in DIF-001 ROW-003 SEAM-002; do case " $ROWS " in *" $r "*) ;; *) fail "the staging run leaves out $r: $ROWS" ;; esac; done
for c in $(awk -F'\t' '$1 == "chunk" { print $2 }' $K/cs/ask); do case $c in p1*) e=alpha ;; *) e=beta ;; esac; N=$CSN; rq $c-1 "$X" $e $(allof pass DIF-001=fail:x); done; fetch; cs decide --stage 1
ok '^stage-cs 1 passed$'; ok '^paid SEAM-001$'; no '^paid SEAM-002$'; no '^paid DIF-001$'; no '^stand-in'; grep -q '^row SEAM-002 known-limit' .vid/tw/handed || fail 'a known limit changed its state'
# production: its golden path asks the limits marked owed-staging or seam
mkdir -p $K/d2; : > $K/d2/passed; printf 'd2\tpassed\t1\nproduction\thttp://127.0.0.1:5002\n' > $K/d2/read; printf 'issue\t99\ncommit\t%s\nasked\t2026-11-09T10:00:00Z\n' "$X" > $K/d2/ask
cs ask --cp 1; ok '^asked [0-9]* cp stage-1$'; R9=$(cut -d' ' -f1 $K/cp/rows | sort | paste -sd ' ' -); [ "$R9" = 'DIF-001 ROW-003 ROW-004 SEAM-002' ] || fail "the production run's rows: $R9"
# limits alone: no row asked
rm -rf $K/cs; for r in SEAM-001 ROW-007; do limit $r; done; cs ask --cs 1; ok '^cs 1 passed, no row to run$'
# a step's close leaves a known limit out
cs decide S03; : > "$T/h"; cp .vid/tw/handed "$T/hb"; printf 'engines alpha beta | stand-in: x\n' > .vid/tw/handed; nt step S03 ROW-014; mg 60 "$TN"; fetch; cs ask S03; ok '^asked [0-9]* close S03$'; case " $(cut -d' ' -f1 .vid/decide/close/S03/1/rows | paste -sd ' ' -) " in *' ROW-006 '*) fail 'a step close asks a known limit' ;; esac
exit 0
