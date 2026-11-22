#!/bin/sh
# Purpose: ViD court — every new staged file must land under a path prefix from
# the ```vid-placement block in CLAUDE.md (a line may be an exact filename).
# Root doc/config files, checks/, tests/ are always allowed. Fails closed.
# 0.26.10.29.3 (R8, F33): so is .claude/settings.json, the one file under .claude/ init writes, on the owner's yes.
# FB-1 A1: in ticket mode (RUN-STATE's mode: tickets, inventory.sh's test) it passes before the CLAUDE.md test: ViD's
# repository holds no app source there, so there is nothing to place.
# serves: both (0.26.10.28.4, M9)
set -eu
IFS='
'

! grep -q '^mode:[[:space:]]*tickets' .vid/RUN-STATE.md 2>/dev/null || exit 0
[ -f CLAUDE.md ] || { echo 'ViD placement: CLAUDE.md missing — failing closed.' >&2; exit 1; }

MAP=$(sed -n '/^```vid-placement/,/^```$/p' CLAUDE.md | sed '1d;$d' | sed 's/[[:space:]]*$//' | grep -v '^$' || true)
if [ -z "$MAP" ]; then
  echo 'ViD placement: no ```vid-placement block in CLAUDE.md — failing closed.' >&2
  exit 1
fi

FAIL=0
for f in $(git diff --cached --name-only --diff-filter=A); do
  case "$f" in
    checks/*|tests/*|.claude/settings.json) continue ;;
    */*) ;;
    *)
      case "$f" in
        *.md|*.yml|*.yaml|*.toml|*.json|*.lock|*.txt|.*|LICENSE*|Makefile*|Dockerfile*) continue ;;
      esac
      ;;
  esac
  OK=0
  for p in $MAP; do
    case "$f" in
      "$p"*) OK=1 ;;
    esac
  done
  if [ "$OK" -eq 0 ]; then
    echo "ViD placement: rejected — '$f' is outside the placement map in CLAUDE.md." >&2
    FAIL=1
  fi
done

if [ "$FAIL" -ne 0 ]; then
  echo 'Put the file where the map says it goes, or (owner-sanctioned only) extend the map.' >&2
fi
exit $FAIL
