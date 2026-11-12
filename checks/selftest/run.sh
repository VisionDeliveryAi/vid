#!/bin/sh
# Purpose: ViD court self-tests (§4.2) — every court proves it still convicts
# on a known-bad fixture. A court failing open manufactures false assurance,
# which is worse than no court. Runs every case in checks/selftest/cases/;
# each case builds a scratch fixture, runs one court against a seeded
# violation, and exits 0 only if the court REJECTED it. ViD's own builds run
# every case. In a project, a law-change commit runs only the project's own
# cases (hooks/pre-commit, VID_SELFTEST_UNLISTED=1; v0.26.10.12.1, F-108): the
# generated extractors add theirs here, one known-bad fixture each. A fixture that passes is a build failure naming the
# court. Usage: sh checks/selftest/run.sh
# v0.9.8.1 (R1): a case listed in checks/selftest/flaky — by its path from
# checks/selftest/, with the date and the reason: flaky, its cause not yet
# found — that fails in the suite is run once more, alone, after the suite,
# by that exact path; any other failure is never retried. Each retry is
# named in the output and recorded `selftest-retried case=<path>
# result=convicts|failed` (where a .vid/ is here). A run a retry rescued
# says so, and is never cited as evidence.
# selftest-parallel: VID_SELFTEST_WORKERS cases run at once — by default the
# machine's cores; 1 runs them one after another, as before. A case on
# checks/selftest/serial or checks/selftest/flaky (by its path from
# checks/selftest/: sensitive to timing, signals or load) runs after the
# others, one at a time. Every case runs in its own TMPDIR, its stdin
# /dev/null; the verdicts print in the cases'
# order — the parallel ones once all of them have ended, then each serial one
# as it ends. xargs -P runs them, so a case's signals are as in a serial run
# (an & would ignore its SIGINT); an xargs without -P runs them serially.
# 0.26.10.28.3 (9.2 R1, M7): each case runs under a time limit, VID_SELFTEST_CASE_SECONDS (900 by default), in the
# foreground of its runner, never under &: in a session and process group of its own (setsid, else perl's
# POSIX::setsid, as test.sh and observe.sh start theirs; with neither, as before, said once), its pid recorded, a
# sleeper beside it stopping its group (TERM, then KILL 5 s later) once the limit passes — `selftest: <name> TIMED OUT
# after <s> s`, a failure. Its output is kept: a failed or timed-out case's last 20 lines print under its line,
# indented; a passing case's is discarded. A case that cannot run in this layout exits 77: `selftest: <name> skipped —
# <its last line of output>`, failing nothing; the summary gains `, <k> skipped` only when k is above 0, <c> counting
# the cases that ran. `slowest: <name> <s> s, …`, the five slowest, follows the summary; with VID_SELFTEST_TIMES=<file>
# each case's seconds go there, `<name> <s>` a line. A flaky case's retry runs the same way, under its limit. The
# runner's INT and TERM also stop each recorded case group. The verdict and summary lines keep their form.
# 0.26.10.28.4 follow-up: a case that needs more than the default names its own limit in one line of its
# own text, `# selftest-limit: <n> s` (decide-hold: 2880 s), which replaces VID_SELFTEST_CASE_SECONDS for that case alone.
# serves: both (0.26.10.28.4, M9)
set -eu
IFS='
'

# v0.9.4 fix: a case's git commands reach only its scratch repository. git
# exports repository variables to the hooks it runs (githooks(5)) — in a
# linked worktree an absolute GIT_DIR and GIT_INDEX_FILE, in the main
# checkout an absolute GIT_INDEX_FILE for `commit -a` and `commit <paths>`,
# GIT_CONFIG_PARAMETERS under `git -c … commit` — and pre-commit runs this
# suite on every law commit. Inherited, they point a case's `git init`,
# `add` and `commit` at the project's repository (measured in a linked
# worktree: a commit on its branch, `core.bare = true` in the shared
# config, every command in the main checkout refused). So every
# repository-local variable is unset before any case runs; with git absent,
# or rev-parse failing, nothing is unset and the suite runs as before.
unset $(git rev-parse --local-env-vars 2>/dev/null)
# v0.9.5 (3.9): nor any global or system git configuration — a setting such
# as commit.gpgsign with a failing signer, a core.hooksPath or a conditional
# include cannot change a case's outcome, serial or memoised. Every shipped
# case sets its own identity and names no branch. (git 2.32 or later honours
# GIT_CONFIG_GLOBAL; the hook's self-test memo is off before it.)
GIT_CONFIG_GLOBAL=/dev/null; GIT_CONFIG_NOSYSTEM=1; export GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM
# v0.9.8.1 (R2): nor any VID_ setting of the caller — a law commit made with VID_ROLE=fix ran every case with it,
# and refusal-record's protected-path commit then passed: under VID_ROLE=fix it fails every time, without it it passes.
# Only this runner's own are kept.
for _v in $(env | sed -n 's/^\(VID_[A-Za-z0-9_]*\)=.*/\1/p'); do
  case "$_v" in VID_SELFTEST_UNLISTED|VID_SELFTEST_WORKERS|VID_SELFTEST_CASE_SECONDS|VID_SELFTEST_TIMES) ;; *) unset "$_v" ;; esac
done
# selftest-parallel: nor one host lease folder for all — test.sh's is under XDG_RUNTIME_DIR, else TMPDIR, and each case
# has its own TMPDIR (below); a case that needs XDG_RUNTIME_DIR sets its own.
unset XDG_RUNTIME_DIR
J=${VID_SELFTEST_WORKERS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}
unset VID_SELFTEST_WORKERS
case "$J" in ''|*[!0-9]*|0) J=1 ;; esac
if [ "$J" -gt 1 ] && ! echo 1 | xargs -n 1 -P 2 true >/dev/null 2>&1; then J=1; fi
LIM=${VID_SELFTEST_CASE_SECONDS:-900}; case "$LIM" in ''|*[!0-9]*|0) LIM=900 ;; esac
TIMES=${VID_SELFTEST_TIMES:-}
unset VID_SELFTEST_CASE_SECONDS VID_SELFTEST_TIMES

SELF=$(cd "$(dirname "$0")" && pwd)
CHECKS=$(cd "$SELF/.." && pwd)
export CHECKS

W=$(mktemp -d)
# stopall: each recorded case group — TERM, then KILL — since a case in a session of its own no longer gets the
# terminal's signal; with no group (no setsid or perl), the case's own pid
stopall() {
  for _sig in TERM KILL; do
    for _pf in "$W"/*.pid; do
      [ -f "$_pf" ] || continue; _cp=$(cat "$_pf" 2>/dev/null) || continue; [ -n "$_cp" ] || continue
      if [ "$SSM" = none ]; then kill "-$_sig" "$_cp" 2>/dev/null || true; else kill "-$_sig" "-$_cp" 2>/dev/null || true; fi
    done
    [ "$_sig" = KILL ] || sleep 1
  done
}
SSM=none
trap 'rm -rf "$W"' EXIT; trap 'stopall; exit 130' INT; trap 'stopall; exit 143' TERM; trap 'stopall; exit 129' HUP
: > "$W/serial"
for _f in serial flaky; do
  if [ -f "$SELF/$_f" ]; then awk '$0 !~ /^[[:space:]]*#/ && NF { print $1 }' "$SELF/$_f" >> "$W/serial"; fi
done
# the session: perl's POSIX::setsid, else setsid (test.sh and observe.sh start theirs with setsid first; here perl
# first, since it alone can set the case's INT and QUIT back to their defaults: under perl the case is started beside
# one.sh and waited for, so one.sh's own INT and TERM stop the case group at once; under setsid the case runs in
# one.sh's foreground and an interrupt waits for it to end or reach its limit); with neither, the case runs as
# before, and the sleeper stops its own pid alone
if command -v perl >/dev/null 2>&1; then SSM=perl
elif command -v setsid >/dev/null 2>&1; then SSM=setsid
else echo "selftest: no setsid or perl — a timed-out case's children may outlive it"; fi
export LIM SSM
# wrap.sh <pid file> <command…>: writes its own pid, then becomes the case, so the pid is the case's and, under
# setsid or perl, its session's and process group's
printf '#!/bin/sh\necho $$ > "$1"; shift; exec "$@"\n' > "$W/wrap.sh"
# one.sh <checks/selftest/> <scratch> <index>: the case on line <index> of <scratch>/list runs alone, in its own
# TMPDIR (and, v0.26.10.28.2 R1, its own count of the machine's test environments, DevAgent's
# DEVAGENT_ENVIRONMENTS, never the real one), in the foreground, under its limit; its output in <i>.out, its seconds in
# <i>.sec, its exit status in <i>.rc, and <i>.to when the sleeper stopped it. The same text runs a serial case, a
# parallel one under xargs, and a flaky case's retry.
cat > "$W/one.sh" <<'ONE_SH'
#!/bin/sh
p=$(sed -n "$3p" "$2/list"); rm -rf "$2/$3.tmp" "$2/$3.to" "$2/$3.end"; mkdir "$2/$3.tmp"; s0=$(date +%s)
# a case's own limit: a line `# selftest-limit: <n> s` in the case, which its sleeper applies in place of the default
_cl=$(sed -n 's/^# selftest-limit: *\([0-9][0-9]*\) s\( .*\)\{0,1\}$/\1/p' "$1/$p" | head -n 1); case "$_cl" in ''|0*) ;; *) LIM=$_cl; export LIM ;; esac
# the sleeper, sleeper.sh: in a session of its own under perl or setsid, so a HUP or KILL to the runner's
# group does not end it; it applies the limit, and stops the case group at once once one.sh or the scratch folder is gone
case "$SSM" in
  perl) perl -e 'use POSIX (); POSIX::setsid(); exec @ARGV or exit 127' sh "$2/sleeper.sh" "$2" "$3" "$$" < /dev/null > /dev/null 2>&1 & ;;
  setsid) setsid sh "$2/sleeper.sh" "$2" "$3" "$$" < /dev/null > /dev/null 2>&1 & ;;
  *) sh "$2/sleeper.sh" "$2" "$3" "$$" < /dev/null > /dev/null 2>&1 & ;;
esac
SL=$!
case "$SSM" in
  perl) : ;;
  setsid) TMPDIR=$2/$3.tmp DEVAGENT_ENVIRONMENTS=$2/$3.tmp/devagent-environments setsid sh "$2/wrap.sh" "$2/$3.pid" sh "$1/$p" ;;
  *) TMPDIR=$2/$3.tmp DEVAGENT_ENVIRONMENTS=$2/$3.tmp/devagent-environments sh "$2/wrap.sh" "$2/$3.pid" sh "$1/$p" ;;
esac > "$2/$3.out" 2>&1 < /dev/null
rc=$?
if [ "$SSM" = perl ]; then
  # beside one.sh, its INT and QUIT set back to their defaults before it takes its session, so its signals are as in a
  # serial run; waited for, so an INT or TERM to one.sh stops the case's group at once
  TMPDIR=$2/$3.tmp DEVAGENT_ENVIRONMENTS=$2/$3.tmp/devagent-environments perl -e '$SIG{INT} = "DEFAULT"; $SIG{QUIT} = "DEFAULT"; use POSIX (); POSIX::setsid(); exec @ARGV or exit 127' sh "$2/wrap.sh" "$2/$3.pid" sh "$1/$p" > "$2/$3.out" 2>&1 < /dev/null &
  CP=$!
  trap 'kill -TERM "-$CP" 2>/dev/null || kill -TERM "$CP" 2>/dev/null; sleep 1; kill -KILL "-$CP" 2>/dev/null; : > "$2/$3.end"; echo 130 > "$2/$3.rc"; rm -f "$2/$3.pid"; exit 130' INT TERM HUP
  wait "$CP"; rc=$?; trap - INT TERM HUP
fi
: > "$2/$3.end"; wait "$SL" 2>/dev/null
echo $(( $(date +%s) - s0 )) > "$2/$3.sec"; echo "$rc" > "$2/$3.rc"; rm -f "$2/$3.pid"; rm -rf "$2/$3.tmp" 2>/dev/null; exit 0
ONE_SH
# sleeper.sh <scratch> <index> <one.sh's pid>: once a second, until the case's .end: when one.sh is gone (killed) or the
# scratch folder is (the runner ended), the case's group stopped at once; when the limit passes, .to, TERM, then KILL
cat > "$W/sleeper.sh" <<'SLEEPER_SH'
#!/bin/sh
d=$1; i=$2; op=$3; c=''; n=0
k() { [ -n "$c" ] || return 0; if [ "$SSM" = none ]; then kill "-$1" "$c" 2>/dev/null; else kill "-$1" "-$c" 2>/dev/null; fi; }
while :; do
  [ -n "$c" ] || c=$(cat "$d/$i.pid" 2>/dev/null)
  [ ! -f "$d/$i.end" ] || exit 0
  if ! kill -0 "$op" 2>/dev/null || [ ! -d "$d" ]; then
    # one.sh may have died between the case's session and its pid's write: the pid is waited for a few seconds
    w=0; while [ -z "$c" ] && [ "$w" -lt 3 ] && [ -d "$d" ]; do sleep 1; w=$((w + 1)); c=$(cat "$d/$i.pid" 2>/dev/null); done
    k TERM; sleep 1; k KILL; exit 0; fi
  [ "$n" -lt "$LIM" ] || break
  sleep 1; n=$((n + 1))
done
echo "$LIM" > "$d/$i.to"; k TERM
j=0; while [ "$j" -lt 5 ] && [ ! -f "$d/$i.end" ] && kill -0 "$op" 2>/dev/null; do sleep 1; j=$((j + 1)); done
k KILL; exit 0
SLEEPER_SH
ONE='exec sh "$2/one.sh" "$1" "$2" "$3"'
: > "$W/list"; : > "$W/par"; : > "$W/ser"

FAILED=''
FAILI=''
SKIPPED=0
RAN=0
# VID_SELFTEST_UNLISTED=1 (the pre-commit hook in a project): only the cases
# checks/selftest/shipped does not list — a project's generated cases — run.
UNL=${VID_SELFTEST_UNLISTED:-}
for c in $(find "$SELF/cases" -type f -name '*.sh' 2>/dev/null | sort); do
  name=${c##*/}; name=${name%.sh}
  if [ -n "$UNL" ] && [ -f "$SELF/shipped" ] && grep -qxF "$name.sh" "$SELF/shipped"; then continue; fi
  RAN=$((RAN + 1)); p=${c#"$SELF"/}; printf '%s\n' "$p" >> "$W/list"
  if [ "$J" -gt 1 ] && ! grep -qxF "$p" "$W/serial"; then echo "$RAN" >> "$W/par"; else echo "$RAN" >> "$W/ser"; fi
done
# tail20 <index>: the case's last 20 lines, indented, under its failure's line
tail20() { tail -n 20 "$W/$1.out" 2>/dev/null | sed 's/^/    /' >&2; }
verdict() {   # <index>: that case's line, as before; no status recorded is a failure
  p=$(sed -n "$1p" "$W/list"); name=${p##*/}; name=${name%.sh}; rc=$(cat "$W/$1.rc" 2>/dev/null || echo none)
  if [ -f "$W/$1.to" ]; then
    echo "selftest: $name TIMED OUT after $(cat "$W/$1.to") s" >&2; tail20 "$1"
    FAILED="$FAILED $name"; FAILI="$FAILI $1"
  elif [ "$rc" = 0 ]; then
    echo "selftest: $name convicts"
  elif [ "$rc" = 77 ]; then
    echo "selftest: $name skipped — $(grep -v '^[[:space:]]*$' "$W/$1.out" 2>/dev/null | tail -n 1)"; SKIPPED=$((SKIPPED + 1))
  else
    echo "selftest: $name FAILED TO CONVICT — the known-bad fixture passed." >&2; tail20 "$1"
    FAILED="$FAILED $name"; FAILI="$FAILI $1"
  fi
}
if [ -s "$W/par" ]; then xargs -n 1 -P "$J" sh -c "$ONE" sh "$SELF" "$W" < "$W/par" || true; fi
for i in $(cat "$W/par"); do verdict "$i"; done
for i in $(cat "$W/ser"); do sh -c "$ONE" sh "$SELF" "$W" "$i"; verdict "$i"; done

# v0.9.8.1 (R1): a listed flaky case that failed runs once more, alone, by its exact path; nothing else is retried.
# 0.26.10.28.3 (R1): through the same one.sh, under its limit, its output kept
RESCUED=no
if [ -n "$FAILI" ] && [ -f "$SELF/flaky" ]; then
  FAILED=''
  for i in $(printf '%s\n' "$FAILI" | tr ' ' '\n' | grep .); do
    p=$(sed -n "${i}p" "$W/list"); name=${p##*/}; name=${name%.sh}
    if ! awk -v p="$p" '$0 !~ /^[[:space:]]*#/ && $1 == p { f = 1 } END { exit !f }' "$SELF/flaky"; then FAILED="$FAILED $name"; continue; fi
    sh -c "$ONE" sh "$SELF" "$W" "$i"
    if [ ! -f "$W/$i.to" ] && [ "$(cat "$W/$i.rc" 2>/dev/null)" = 0 ]; then r=convicts; RESCUED=yes
      echo "selftest: $p convicts on its retry, alone — it is on checks/selftest/flaky; this run is rescued and is no evidence"
    else r=failed; FAILED="$FAILED $name"
      if [ -f "$W/$i.to" ]; then echo "selftest: $p TIMED OUT again on its retry, alone, after $(cat "$W/$i.to") s" >&2
      else echo "selftest: $p FAILED TO CONVICT again on its retry, alone" >&2; fi
      tail20 "$i"
    fi
    if [ -d .vid ] && [ -f "$CHECKS/event.sh" ]; then sh "$CHECKS/event.sh" "selftest-retried case=$p result=$r" 2>/dev/null || true; fi
  done
fi

# the cases' times: VID_SELFTEST_TIMES's file, a line a case, and the five slowest after the summary
: > "$W/times"; i=0
for p in $(cat "$W/list"); do i=$((i + 1)); n=${p##*/}; [ ! -f "$W/$i.sec" ] || printf '%s %s\n' "${n%.sh}" "$(cat "$W/$i.sec")" >> "$W/times"; done
[ -z "$TIMES" ] || cp "$W/times" "$TIMES" 2>/dev/null || true
slowest() { [ -s "$W/times" ] || return 0; echo "slowest: $(sort -k2,2nr -k1,1 "$W/times" | head -n 5 | awk '{ printf "%s%s %s s", (NR > 1 ? ", " : ""), $1, $2 }')"; }

C=$((RAN - SKIPPED)); SK=''; [ "$SKIPPED" -eq 0 ] || SK=", $SKIPPED skipped"
if [ "$RAN" -eq 0 ] && [ -n "$UNL" ]; then
  echo 'selftest: 0/0 courts convict — no case beyond the shipped ones'
  exit 0
fi
if [ "$RAN" -eq 0 ]; then
  echo 'ViD selftest: no cases found — failing closed (an untested judge is not a judge).' >&2
  exit 1
fi
if [ -n "$FAILED" ]; then
  echo "ViD selftest: rejected — court(s) failing open:$FAILED" >&2
  echo 'A court that does not convict its known-bad fixture is manufacturing false assurance. Fix the court before anything else lands.' >&2
  slowest
  exit 1
fi
if [ "$RESCUED" = yes ]; then
  echo "selftest: $C/$C courts convict$SK, rescued by a retry (above)"
  slowest
  exit 0
fi
echo "selftest: $C/$C courts convict$SK"
slowest
exit 0
