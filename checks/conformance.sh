#!/bin/sh
# Purpose: ViD court — staged changes must conform to BASELINE.md's machine
# blocks: no new file extension outside ```vid-allowed-extensions, no staged
# added line (outside *.md) mentioning a ```vid-forbidden term. Fails closed.
set -eu
IFS='
'

[ -f BASELINE.md ] || { echo 'ViD conformance: BASELINE.md missing — failing closed.' >&2; exit 1; }

block() {
  sed -n '/^```vid-'"$1"'/,/^```$/p' BASELINE.md | sed '1d;$d' | grep -v '^[[:space:]]*$' || true
}

ALLOWED=$(block allowed-extensions | tr ' ' '\n' | grep -v '^$' || true)
FORBIDDEN=$(block forbidden)
if [ -z "$ALLOWED" ]; then
  echo 'ViD conformance: no ```vid-allowed-extensions block in BASELINE.md — failing closed.' >&2
  exit 1
fi

FAIL=0

# 1. New files may not introduce an extension outside the allowed list.
for f in $(git diff --cached --name-only --diff-filter=A); do
  base=${f##*/}
  case "$base" in .*) continue ;; esac
  case "$base" in *.*) ext=".${base##*.}" ;; *) continue ;; esac
  OK=0
  for a in $ALLOWED; do
    [ "$ext" = "$a" ] && OK=1
  done
  if [ "$OK" -eq 0 ]; then
    echo "ViD conformance: rejected — '$f' introduces extension '$ext' outside BASELINE.md's allowed list." >&2
    FAIL=1
  fi
done

# 2. Staged added lines (outside *.md) may not mention a forbidden term.
for t in $FORBIDDEN; do
  HITS=$(git diff --cached -U0 -- . ':(exclude)*.md' | grep '^+' | grep -v '^+++' | grep -iF -- "$t" || true)
  if [ -n "$HITS" ]; then
    echo "ViD conformance: rejected — staged additions mention forbidden term '$t' (BASELINE.md):" >&2
    printf '%s\n' "$HITS" | head -n 5 | sed 's/^/    /' >&2
    FAIL=1
  fi
done

# 3. Design token court — active only when the project has a ratified design
# (design/ is optional, so absence skips this; the other courts fail closed).
# It polices APP SOURCE: colors enter the product through the ratified design
# and are referenced as tokens, so new raw hex colors outside design/ are
# rejected. Exempt: design/ (imported verbatim from the owner — spec, not
# source), checks/ (courts, not app source), *.md, *.svg, and — v0.9.7.3
# (3.9, R9) — the ledger tests (tests/invariants/): a test's expected colour
# value is data, not app source. Hex lengths 3/4/6/8 with a boundary; anchors
# whose names are hex-shaped can rarely false-positive.
if [ -f design/tokens.css ]; then
  HEX=$(git diff --cached -U0 -- . ':(exclude)*.md' ':(exclude)*.svg' ':(exclude)design/' ':(exclude)checks/' ':(exclude)tests/invariants/' | grep '^+' | grep -v '^+++' | grep -E '#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})($|[^0-9a-zA-Z])' || true)
  if [ -n "$HEX" ]; then
    echo 'ViD conformance: rejected — raw hex color in staged additions outside design/:' >&2
    printf '%s\n' "$HEX" | head -n 5 | sed 's/^/    /' >&2
    echo 'The design is law (CLAUDE.md): add a token to design/tokens.css and reference it.' >&2
    FAIL=1
  fi
fi

exit $FAIL
