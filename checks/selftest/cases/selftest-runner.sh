#!/bin/sh
# Purpose: selftest case — the runner's time limit, kept output and skips (0.26.10.28.3, 9.2 R1, M7). A copy of
# checks/selftest/run.sh runs a planted suite: a case that sleeps past VID_SELFTEST_CASE_SECONDS=2 is stopped, reported
# `TIMED OUT after 2 s`, and leaves no process behind (its own child included); a failing case's last 20 lines print
# under its line, and not the 21st from the end; a case exiting 77 prints `skipped — <its reason>`, fails nothing, and
# the summary reads `<c>/<c> courts convict, 1 skipped`, still matching metrics.sh's pattern; `slowest:` follows it;
# VID_SELFTEST_TIMES gets a line a case; a flaky case whose retry hangs is stopped at its limit and its output shown;
# with setsid and perl hidden from the PATH the suite still runs and says so once; a runner interrupted as a terminal
# interrupts it leaves no case group behind; a case's own `# selftest-limit: <n> s` line replaces the default for it alone;
# round-step, stage-walk and tw-change each name theirs, at least 1440, 1440 and 1140 s (FB-2 C1). Env: CHECKS.
set -eu
T=$(mktemp -d)
# the cleanup stops a planted child only while its pid is still that child, a `sleep`: a pid is never killed by number alone
trap 'set +e; for f in "$T"/kid.*; do [ -f "$f" ] || continue; k=$(cat "$f"); [ "$(ps -o comm= -p "$k" 2>/dev/null)" = sleep ] && kill -KILL "$k" 2>/dev/null; done; rm -rf "$T"; true' EXIT
fail() { echo "selftest-runner: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
alive() { kill -0 "$1" 2>/dev/null; }
# suite <dir> <case…>: a checks/selftest/ of the runner and the named planted cases
suite() { d=$1; shift; mkdir -p "$d/checks/selftest/cases"; cp "$CHECKS/selftest/run.sh" "$d/checks/selftest/run.sh"
  for c; do plant "$c" > "$d/checks/selftest/cases/$c.sh"; done; }
plant() { case $1 in
  good) printf '#!/bin/sh\nexit 0\n' ;;
  hangs) printf '#!/bin/sh\nsleep 300 & echo $! > "%s/kid.hangs"\necho "about to hang"\nwait\n' "$T" ;;
  fails) printf '#!/bin/sh\ni=1; while [ $i -le 25 ]; do echo "line $i of the failure"; i=$((i + 1)); done\nexit 1\n' ;;
  skips) printf '#!/bin/sh\n[ -d "$CHECKS/../viewer-nowhere" ] || { echo "needs viewer/"; exit 77; }\nexit 0\n' ;;
  flakyhang) printf '#!/bin/sh\necho "the flaky one hangs"\nsleep 300 & echo $! > "%s/kid.flaky.$$"\nwait\n' "$T" ;;
  long1|long2) printf '#!/bin/sh\nsleep 300 & echo $! > "%s/kid.%s"\necho $$ > "%s/case.%s"\nwait\n' "$T" "$1" "$T" "$1" ;;
  stubborn) printf '#!/bin/sh\nsh -c '"'"'trap "" TERM; exec sleep 300'"'"' & echo $! > "%s/kid.stubborn"\necho "a child that ignores TERM"\nwait\n' "$T" ;;
  ownlong) printf '#!/bin/sh\n# selftest-limit: 8 s — planted: longer than the default\nsleep 4\nexit 0\n' ;;
  ownhang) printf '#!/bin/sh\n# selftest-limit: 3 s — planted: its own limit, and it hangs\nsleep 300 & echo $! > "%s/kid.ownhang"\nwait\n' "$T" ;;
  esac; }
run() { ( cd "$1" && VID_SELFTEST_WORKERS=${W:-2} VID_SELFTEST_CASE_SECONDS=${LIMIT:-2} VID_SELFTEST_TIMES=$T/times sh checks/selftest/run.sh ) > "$T/out" 2>&1; }
# the time limit, the kept output, the skip
suite "$T/a" good hangs fails skips
run "$T/a" && fail 'a suite with a hung case and a failing case passed'
grep -qx 'selftest: hangs TIMED OUT after 2 s' "$T/out" || fail 'the hung case was not reported TIMED OUT after 2 s'
grep -qx '    about to hang' "$T/out" || fail "the hung case's output was not shown"
k=$(cat "$T/kid.hangs"); sleep 1; ! alive "$k" || fail "the hung case's child $k outlived it"
grep -qx '    line 25 of the failure' "$T/out" && grep -qx '    line 6 of the failure' "$T/out" || fail "the failing case's last 20 lines were not printed"
! grep -q 'line 5 of the failure' "$T/out" || fail 'more than 20 lines were printed'
grep -qx 'selftest: skips skipped — needs viewer/' "$T/out" || fail 'the skipped case did not say why'
{ grep -qxF 'ViD selftest: rejected — court(s) failing open: fails hangs' "$T/out" || grep -qxF 'ViD selftest: rejected — court(s) failing open: hangs fails' "$T/out"; } || fail "the rejection does not name the two failures alone: $(grep rejected "$T/out")"
grep -q '^slowest: ' "$T/out" || fail 'no slowest line'
[ "$(grep -c . "$T/times")" = 4 ] || fail "VID_SELFTEST_TIMES holds not a line a case: $(cat "$T/times")"
# a timed-out case whose child ignores TERM: the KILL follows, and the child goes too
suite "$T/s" stubborn; run "$T/s" && fail 'a hung case passed'
grep -qx 'selftest: stubborn TIMED OUT after 2 s' "$T/out" || fail 'the stubborn case was not reported TIMED OUT'
sleep 1; ! alive "$(cat "$T/kid.stubborn")" || fail "a child that ignores TERM outlived its timed-out case"
# a clean suite with a skip: the summary counts it apart, and metrics.sh's pattern still reads it
rm "$T/a/checks/selftest/cases/hangs.sh" "$T/a/checks/selftest/cases/fails.sh"
run "$T/a" || fail 'a suite of a good case and a skipped one failed'
grep -qx 'selftest: 1/1 courts convict, 1 skipped' "$T/out" || fail "the summary does not count the skip apart: $(grep 'courts convict' "$T/out")"
[ "$(grep -oE '[0-9]+/[0-9]+ courts convict' "$T/out" | tail -n 1)" = '1/1 courts convict' ] || fail "metrics.sh's pattern no longer reads the summary"
[ "$(tail -n 1 "$T/out" | cut -c1-9)" = 'slowest: ' ] || fail 'slowest does not follow the summary'
rm "$T/a/checks/selftest/cases/skips.sh"; run "$T/a" || fail 'one good case failed'
grep -qx 'selftest: 1/1 courts convict' "$T/out" || fail 'with nothing skipped the summary is not as before'
# a case's own limit: `# selftest-limit: <n> s` replaces the default (here 2 s) for that case alone
suite "$T/o" ownlong ownhang; run "$T/o" && fail 'a suite with a case past its own limit passed'
grep -qx 'selftest: ownlong convicts' "$T/out" || fail 'a case under its own longer limit was not let run past the default'
grep -qx 'selftest: ownhang TIMED OUT after 3 s' "$T/out" || fail "a case was not stopped at its own limit: $(grep 'ownhang' "$T/out" | head -n 1)"
sleep 1; ! alive "$(cat "$T/kid.ownhang")" || fail "the case stopped at its own limit left its child"
# FB-2 C1: the three long shipped cases name their own limit, at least the runner's rule (the slowest time alone, ×3)
for p in round-step:1440 stage-walk:1440 tw-change:1140; do c=${p%%:*}; n=$(sed -n 's/^# selftest-limit: *\([0-9][0-9]*\) s\( .*\)\{0,1\}$/\1/p' "$CHECKS/selftest/cases/$c.sh" | head -n 1)
  [ -n "$n" ] && [ "$n" -ge "${p#*:}" ] || fail "$c.sh names no limit of its own of ${p#*:} s or more (found: ${n:-none})"; done
# a flaky case whose retry hangs: stopped at its limit, its output shown
suite "$T/f" good flakyhang; printf 'cases/flakyhang.sh 2026-11-11 planted: it hangs\n' > "$T/f/checks/selftest/flaky"
run "$T/f" && fail 'a hanging flaky case passed'
grep -q '^selftest: cases/flakyhang.sh TIMED OUT again on its retry, alone, after 2 s$' "$T/out" || fail 'the hanging retry was not stopped at its limit'
[ "$(grep -c '^    the flaky one hangs$' "$T/out")" -ge 2 ] || fail "the retry's output was not shown"
for f in "$T"/kid.flaky.*; do k=$(cat "$f"); ! alive "$k" || fail "the flaky case's child $k outlived it"; done
# no setsid, no perl: the suite still runs, and says so once
mkdir "$T/nobin"; for d in /bin /usr/bin /usr/sbin; do for t in "$d"/*; do b=${t##*/}; case $b in perl*|setsid) continue ;; esac; [ -e "$T/nobin/$b" ] || ln -s "$t" "$T/nobin/$b"; done; done
suite "$T/n" good; ( cd "$T/n" && PATH=$T/nobin VID_SELFTEST_WORKERS=1 VID_SELFTEST_CASE_SECONDS=5 sh checks/selftest/run.sh ) > "$T/out" 2>&1 || fail 'without setsid and perl the suite failed'
[ "$(grep -c "^selftest: no setsid or perl — a timed-out case's children may outlive it$" "$T/out")" = 1 ] || fail 'without setsid and perl the runner did not say so once'
grep -qx 'selftest: 1/1 courts convict' "$T/out" || fail 'without setsid and perl the good case did not convict'
# a runner stopped from outside leaves nothing behind: the runner in a process group of its own, two workers
# each in a long case; an INT to the group, as a terminal sends, then a KILL to it: the cases, their children and the
# sleepers (each in its own session) all end within a few seconds
if command -v setsid >/dev/null 2>&1; then SG='setsid'; elif command -v perl >/dev/null 2>&1; then SG='perl'; else SG=''; fi
gone() { _i=0; while [ "$_i" -lt 15 ]; do _l=$(ps -axo pid=,command= | grep -F "$1" | grep -v grep || true); [ -z "$_l" ] && return 0; sleep 1; _i=$((_i + 1)); done; echo "$_l" | head -n 3 >&2; return 1; }
for sig in INT KILL; do
  [ -n "$SG" ] || break
  rm -f "$T"/case.long* "$T"/kid.long*; rm -rf "$T/t$sig"; suite "$T/t$sig" long1 long2; mkdir "$T/t$sig/tmp"
  ( cd "$T/t$sig" && TMPDIR=$T/t$sig/tmp VID_SELFTEST_WORKERS=2 VID_SELFTEST_CASE_SECONDS=120 && export TMPDIR VID_SELFTEST_WORKERS VID_SELFTEST_CASE_SECONDS && if [ "$SG" = setsid ]; then exec setsid sh checks/selftest/run.sh; else exec perl -e '$SIG{INT} = "DEFAULT"; use POSIX (); POSIX::setsid(); exec @ARGV or exit 127' sh checks/selftest/run.sh; fi ) > "$T/out" 2>&1 < /dev/null & RP=$!
  i=0; while { [ ! -s "$T/case.long1" ] || [ ! -s "$T/case.long2" ]; } && [ "$i" -lt 30 ]; do sleep 1; i=$((i + 1)); done; [ -s "$T/case.long1" ] && [ -s "$T/case.long2" ] || fail "the two long cases never started ($sig)"
  kill "-$sig" "-$RP"; i=0; while alive "$RP" && [ "$i" -lt 20 ]; do sleep 1; i=$((i + 1)); done; ! alive "$RP" || fail "the runner did not stop on $sig to its group"; wait "$RP" 2>/dev/null || true
  for n in long1 long2; do gone "$T/t$sig/checks/selftest/cases/$n.sh" || fail "the case $n outlived its runner ($sig)"; i=0; while alive "$(cat "$T/kid.$n")" && [ "$i" -lt 10 ]; do sleep 1; i=$((i + 1)); done; ! alive "$(cat "$T/kid.$n")" || fail "the case $n's child outlived its runner ($sig)"; done
  gone "$T/t$sig/tmp" || fail "a sleeper or one.sh outlived the runner ($sig)"
done
exit 0
