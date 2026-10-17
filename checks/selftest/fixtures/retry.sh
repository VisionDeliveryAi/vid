# Purpose: selftest fixture — a toy self-test for the retry cases (v0.9.8.1 R1). Sourced by a case after it has made
# $T (Env: CHECKS, T). rt_suite <dir> makes, there, checks/selftest/ with a copy of run.sh and checks/event.sh, and a
# .vid/, and enters it. rt_case <path> <how>: a case at checks/selftest/<path> that appends its path to $T/ran and
# then convicts (how=ok), fails every time (how=fail) or fails only its first time (how=once). rt_list <path>: that
# path listed in checks/selftest/flaky. rt_run: run.sh, its output in $T/out, its status in RT. rt_ran <path>: how
# many times that case ran.
rt_suite() { mkdir -p "$1/checks/selftest/cases" "$1/.vid"; cd "$1"
  cp "$CHECKS/selftest/run.sh" checks/selftest/run.sh; cp "$CHECKS/event.sh" checks/event.sh
  printf '# Purpose: the flaky cases\n' > checks/selftest/flaky; : > "$T/ran"; }
rt_case() { mkdir -p "checks/selftest/${1%/*}"
  case "$2" in ok) b='exit 0' ;; fail) b='exit 1' ;; once) b="if [ -f \"$T/once.\$(echo $1 | tr / _)\" ]; then exit 0; fi; : > \"$T/once.\$(echo $1 | tr / _)\"; exit 1" ;; esac
  printf '#!/bin/sh\n# Purpose: a toy case\necho %s >> "%s/ran"\n%s\n' "$1" "$T" "$b" > "checks/selftest/$1"; }
rt_list() { printf '%s 2026-10-16 a toy reason\n' "$1" >> checks/selftest/flaky; }
rt_run() { RT=0; VID_SELFTEST_RESCUED="$T/rescued" sh checks/selftest/run.sh > "$T/out" 2>&1 || RT=$?; }
rt_ran() { grep -cxF "$1" "$T/ran" || true; }
