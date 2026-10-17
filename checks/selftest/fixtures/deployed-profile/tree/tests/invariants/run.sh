#!/bin/sh
# Purpose: the toy runner — ROW-001 (the product is up), ROW-P01 (a (process) journey: a feed item entered at the inbound boundary is indexed), ROW-S01 (the deployed pass starts on a fresh stack).
# Provenance: hand-authored
SEL=${1:-}; OUT=/vid-results/pending.xml; TMP=/tmp/report; : > "$TMP"; FAILED=0
emit() { echo "case tests/invariants/run.sh::$1 $2 0.0" >> "$TMP"; [ "$2" = passed ] || FAILED=1; }
waitfor() { i=0; while [ ! -f "$1" ] && [ "$i" -lt "$2" ]; do sleep 1; i=$((i + 1)); done; [ -f "$1" ]; }
if [ -z "$SEL" ]; then
  if waitfor /db/product-up 30; then emit 'up[ROW-001]' passed; else emit 'up[ROW-001]' failed; fi
  echo left-by-pass-1 > /db/sentinel; echo left-by-pass-1 > /transport/.sentinel
fi
if [ "$SEL" = process ]; then
  if [ ! -f /db/sentinel ] && [ ! -f /transport/.sentinel ]; then emit 'fresh[ROW-S01]' passed; else emit 'fresh[ROW-S01]' failed; fi
fi
case "$SEL" in ''|process)
  waitfor /db/product-up 30 || true
  echo feed > /inbox/feed-1.item
  if waitfor /db/feed-1.indexed 15; then emit 'feed[ROW-P01]' passed; else emit 'feed[ROW-P01]' failed; fi ;;
esac
cp "$TMP" "$OUT"
exit "$FAILED"
