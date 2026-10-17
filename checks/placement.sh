#!/bin/sh
# Purpose: ViD court — every new staged file must land under a path prefix from
# the ```vid-placement block in CLAUDE.md (a line may be an exact filename).
# Root doc/config files, checks/, tests/ are always allowed. Fails closed.
set -eu
IFS='
'

[ -f CLAUDE.md ] || { echo 'ViD placement: CLAUDE.md missing — failing closed.' >&2; exit 1; }

MAP=$(sed -n '/^```vid-placement/,/^```$/p' CLAUDE.md | sed '1d;$d' | sed 's/[[:space:]]*$//' | grep -v '^$' || true)
if [ -z "$MAP" ]; then
  echo 'ViD placement: no ```vid-placement block in CLAUDE.md — failing closed.' >&2
  exit 1
fi

FAIL=0
for f in $(git diff --cached --name-only --diff-filter=A); do
  case "$f" in
    checks/*|tests/*) continue ;;
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
