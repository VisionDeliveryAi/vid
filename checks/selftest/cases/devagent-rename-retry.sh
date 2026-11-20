#!/bin/sh
# Purpose: selftest case — DevAgent's test manager retries a refused rename (0.26.11.1.4, R6), on the fixture project with a local bare
# repository as origin. run.sh's own mvr, taken from run.sh: refused twice, the third try goes in; refused every time, it returns
# non-zero after 5 tries, the source and the target as they were. Its renames, each refused once by a stub mv and each run still
# pushing its report whole: the start's lstart, a rest chunk's left-out cases file and covers, a planted chunk's cases file, the
# sorted file in a plain run and in a fault run, a head run's setup-errors tally, and a fault run's new attempt folder; the stub
# names each rename it refused, so a rename it never met fails the case. A start whose rename is refused every time is not run and
# pushes nothing. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
R=$CHECKS/../devagent/test-manager/run.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-rename-retry: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the helper, as run.sh defines it
MVR=$(grep '^mvr() {' "$R") || fail 'run.sh defines no mvr'; eval "$MVR"
RMV=$(command -v mv); mkdir "$T/stub" "$T/a" "$T/st"
# the stub: a rename of one of run.sh's own files is refused the first time for each source (FAILS=all: every time), the refusal
# named in $T/st/refused by its kind; every other rename goes through
cat > "$T/stub/mv" <<EOF
#!/bin/sh
for a; do case "\$a" in -*) continue ;; esac; s=\$a; break; done
case "\$s" in */lstart.t) k=lstart ;; */cases-*.xml.t) k=cases ;; */covers.t) k=covers ;; */s2) k=sorted ;; */setup-errors.t) k=setup-errors ;;
  */report/pr-*-[0-9]*) k=attempt ;; "$T"/a/*) k=helper ;; *) exec "$RMV" "\$@" ;; esac
c=$T/st/\$(printf '%s' "\$s" | cksum | cut -d' ' -f1); n=\$(( \$(cat "\$c" 2>/dev/null || echo 0) + 1 )); echo "\$n" > "\$c"
if [ "\${FAILS:-1}" = all ] || [ "\$n" -le "\${FAILS:-1}" ]; then echo "\$k" >> "$T/st/refused"; echo "mv: refused (\$n)" >&2; exit 1; fi
exec "$RMV" "\$@"
EOF
chmod +x "$T/stub/mv"; OP=$PATH
# the helper: refused twice, then in; refused every time, 5 tries and both as they were
printf 's\n' > "$T/a/s"; printf 't\n' > "$T/a/t"; RC=0; ( PATH="$T/stub:$OP"; FAILS=2; export FAILS; mvr "$T/a/s" "$T/a/t" ) 2> "$T/out" || RC=$?
[ "$RC" = 0 ] && [ "$(cat "$T/a/t")" = s ] && [ ! -e "$T/a/s" ] || fail "run.sh's mvr refused twice did not go in on the third try ($RC)"
[ "$(grep -c . "$T/st/refused")" = 2 ] || fail "run.sh's mvr was refused $(grep -c . "$T/st/refused") times, not 2"
rm -f "$T/st"/*; printf 's\n' > "$T/a/s"; RC=0; ( PATH="$T/stub:$OP"; FAILS=all; export FAILS; mvr "$T/a/s" "$T/a/t" ) 2> "$T/out" || RC=$?
[ "$RC" != 0 ] && [ "$(cat "$T/a/s")" = s ] && [ "$(cat "$T/a/t")" = s ] || fail "run.sh's mvr refused every time did not leave the two as they were ($RC)"
[ "$(grep -c . "$T/st/refused")" = 5 ] || fail "run.sh's mvr was tried $(grep -c . "$T/st/refused") times, not 5"
sp_project; cd "$T"
S=$T/work/dev-setup.txt; H=$(printf %s "$SP_C" | cut -c1-12); A=pr-1-$H; O="git -C $T/origin.git"
has() { $O rev-parse -q --verify "refs/heads/vid-results/$1" > /dev/null; }
names() { $O show "vid-results/$1:$1/cases-alpha.xml" | sed -n 's/.*<testcase name="\([^"]*\)".*/\1/p' | tr '\n' ' '; }
# run <the kinds the stub must refuse> -- <run.sh's arguments>: each rename refused once, the run pushes, each kind named was refused
run() { k=''; while [ "$1" != -- ]; do k="$k $1"; shift; done; shift; rm -f "$T/st"/*; RC=0
  PATH="$T/stub:$OP" sh "$R" run --setup "$S" --commit "$SP_C" "$@" > "$T/out" 2>&1 || RC=$?
  [ "$RC" = 0 ] || fail "a run with each rename refused once exited $RC: $*"
  for x in $k; do grep -qx "$x" "$T/st/refused" 2>/dev/null || fail "the $x rename was never refused in: $* (refused: $(paste -sd ' ' "$T/st/refused" 2>/dev/null))"; done; }
# a rest chunk: the start, its left-out cases file and covers, the sorted file
SP_COVER=1; export SP_COVER
run lstart cases covers sorted -- --ask req-9-p1cx --leave-out ROW-003; has req-9-p1cx-1 || fail 'the rest chunk pushed nothing'
[ "$(names req-9-p1cx-1)" = 'ROW-001-home ROW-002-product ROW-004-after ROW-005-value ROW-006-weak ' ] || fail "the rest chunk's cases: $(names req-9-p1cx-1)"
! $O show vid-results/req-9-p1cx-1:req-9-p1cx-1/results.txt | grep -q '^covers: ROW-003' || fail "the left-out row's covers: line stayed"
unset SP_COVER
# a planted chunk: its cases file
run lstart cases sorted -- --ask req-40-p1c1 --select 'ROW-00[14]' --engines alpha --plant-red ROW-001; has req-40-p1c1-1 || fail 'the planted chunk pushed nothing'
$O show vid-results/req-40-p1c1-1:req-40-p1c1-1/cases-alpha.xml | grep -q '<testcase name="ROW-001-home" time="[0-9]*"><failure message="a labelled plant' || fail 'the planted case does not read failed'
# a head run: its setup-errors tally
run lstart sorted setup-errors -- --ask "$A" --select 'ROW-001'; has "$A-1" && [ -f work/setup-errors ] && grep -q "^pr-1 " work/setup-errors || fail "the head run's tally: $(cat work/setup-errors 2>/dev/null)"
# a fault run: the sorted file in its branch, and its new attempt folder from the head's
printf 'ROW-001\tno.patch\tnone\tROW-001\n' > work/f.txt; printf 'diff --git a/nothing.txt b/nothing.txt\n--- a/nothing.txt\n+++ b/nothing.txt\n@@ -1 +1 @@\n-a\n+b\n' > work/no.patch
run lstart sorted attempt -- --ask "$A" --faults work/f.txt; has "$A-2" || fail 'the fault run made no new attempt'
$O ls-tree -r --name-only "vid-results/$A-2" | grep -q "^$A-2/faults/ROW-001/" || fail "the fault run's attempt lacks its fault: $($O ls-tree -r --name-only "vid-results/$A-2" | tr '\n' ' ')"
# refused every time: the start is not run, nothing pushed
rm -f "$T/st"/*; RC=0; PATH="$T/stub:$OP" FAILS=all sh "$R" run --setup "$S" --commit "$SP_C" --ask req-50-p1c1 --select ROW-001 --engines alpha > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] && ! has req-50-p1c1-1 || fail "a run whose start's rename was refused every time exited $RC or pushed"
[ "$(grep -c '^lstart$' "$T/st/refused")" = 5 ] || fail "the start's rename was tried $(grep -c '^lstart$' "$T/st/refused") times, not 5"
echo 'devagent-rename-retry: ok'
