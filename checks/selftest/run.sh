#!/bin/sh
# Purpose: ViD court self-tests (§4.2) — every court proves it still convicts
# on a known-bad fixture. A court failing open manufactures false assurance,
# which is worse than no court. Runs every case in checks/selftest/cases/;
# each case builds a scratch fixture, runs one court against a seeded
# violation, and exits 0 only if the court REJECTED it. Runs at init (the
# machine proven to convict on this stack) and after every law-change commit
# (touch the law, prove the judge still convicts — wired in hooks/pre-commit).
# Init-generated extractors add their own cases here at generation time, one
# known-bad fixture each. A fixture that passes is a build failure naming the
# court. Usage: sh checks/selftest/run.sh
# v0.9.8.1 (R1): a case listed in checks/selftest/flaky — by its path from
# checks/selftest/, with the date and the reason: flaky, its cause not yet
# found — that fails in the suite is run once more, alone, after the suite,
# by that exact path; any other failure is never retried. Each retry is
# named in the output and recorded `selftest-retried case=<path>
# result=convicts|failed` (where a .vid/ is here). A run a retry rescued
# says so, and touches $VID_SELFTEST_RESCUED when that names a file: the
# pre-commit hook publishes no certificate from it. A rescued run is never
# cited as evidence.
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
# Only this runner's own two are kept.
for _v in $(env | sed -n 's/^\(VID_[A-Za-z0-9_]*\)=.*/\1/p'); do
  case "$_v" in VID_SELFTEST_UNLISTED|VID_SELFTEST_RESCUED) ;; *) unset "$_v" ;; esac
done

SELF=$(cd "$(dirname "$0")" && pwd)
CHECKS=$(cd "$SELF/.." && pwd)
export CHECKS

FAILED=''
FAILP=''
RAN=0
# VID_SELFTEST_UNLISTED=1 (the pre-commit hook, when its self-test memo holds):
# only the cases checks/selftest/shipped does not list — a project's
# generated cases — run.
UNL=${VID_SELFTEST_UNLISTED:-}
for c in $(find "$SELF/cases" -type f -name '*.sh' 2>/dev/null | sort); do
  name=${c##*/}; name=${name%.sh}
  if [ -n "$UNL" ] && [ -f "$SELF/shipped" ] && grep -qxF "$name.sh" "$SELF/shipped"; then continue; fi
  RAN=$((RAN + 1))
  if sh "$c" >/dev/null 2>&1; then
    echo "selftest: $name convicts"
  else
    echo "selftest: $name FAILED TO CONVICT — the known-bad fixture passed." >&2
    FAILED="$FAILED $name"
    FAILP="$FAILP${c#"$SELF"/}
"
  fi
done

# v0.9.8.1 (R1): a listed flaky case that failed runs once more, alone, by its exact path; nothing else is retried
RESCUED=no
if [ -n "$FAILP" ] && [ -f "$SELF/flaky" ]; then
  FAILED=''
  for p in $FAILP; do
    name=${p##*/}; name=${name%.sh}
    if ! awk -v p="$p" '$0 !~ /^[[:space:]]*#/ && $1 == p { f = 1 } END { exit !f }' "$SELF/flaky"; then FAILED="$FAILED $name"; continue; fi
    if sh "$SELF/$p" >/dev/null 2>&1; then r=convicts; RESCUED=yes
      echo "selftest: $p convicts on its retry, alone — it is on checks/selftest/flaky; this run is rescued, publishes no certificate and is no evidence"
    else r=failed; FAILED="$FAILED $name"
      echo "selftest: $p FAILED TO CONVICT again on its retry, alone" >&2
    fi
    if [ -d .vid ] && [ -f "$CHECKS/event.sh" ]; then sh "$CHECKS/event.sh" "selftest-retried case=$p result=$r" 2>/dev/null || true; fi
  done
fi

if [ "$RAN" -eq 0 ] && [ -n "$UNL" ]; then
  echo 'selftest: no case beyond the shipped ones'
  exit 0
fi
if [ "$RAN" -eq 0 ]; then
  echo 'ViD selftest: no cases found — failing closed (an untested judge is not a judge).' >&2
  exit 1
fi
if [ -n "$FAILED" ]; then
  echo "ViD selftest: rejected — court(s) failing open:$FAILED" >&2
  echo 'A court that does not convict its known-bad fixture is manufacturing false assurance. Fix the court before anything else lands.' >&2
  exit 1
fi
if [ "$RESCUED" = yes ]; then
  echo "selftest: $RAN/$RAN courts convict, rescued by a retry (above)"
  if [ -n "${VID_SELFTEST_RESCUED:-}" ]; then : > "$VID_SELFTEST_RESCUED"; fi
  exit 0
fi
echo "selftest: $RAN/$RAN courts convict"
exit 0
