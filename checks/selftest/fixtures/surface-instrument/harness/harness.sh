#!/bin/sh
# Purpose: the fixture harness client (v0.9.2 3.4 — a TOY, never installed).
# The public surface a surface test-author pass receives, and all it may
# call. It stands in for a project's harness: two engines, an actor door, a
# page loader that records every navigation, the fixture's own data (its
# page size, its records), and the assertion counter the runner reads. The
# "browser" is a page reader over static HTML under $SCAFFOLD (the app's
# rendered pages, one file per actor × fixture × route); the instrument
# never opens those files itself — it reads only its own table, the
# canvases under design/ and what these functions answer.
#
#   harness_engines                      → the engines the harness runs, one per line
#   harness_actor ENGINE ACTOR           → signs ACTOR in for ENGINE (anonymous needs no door);
#                                          fails naming the actor when the fixture has none
#   harness_fixture NAME                 → selects the data fixture the state needs. The fixtures this
#                                          harness provides: `-` (the default: the four records of
#                                          data/records.txt, page size 3 — a listed board) and `unlisted`
#                                          (no records: the board with nothing listed). A state needing a
#                                          fixture not named here is `unwritable: missing prerequisite`.
#   harness_load ENGINE ACTOR ROUTE      → loads the route ONCE (records `navigate ENGINE ACTOR ROUTE FIXTURE`
#                                          in $HARNESS_LOG); prints the page's path, or nothing on a 404
#   harness_page_size                    → the page size the fixture set
#   harness_records                      → the fixture's records: `id|title|salary` (salary `-` when absent)
#   harness_count PAGE IDENTIFIER        → how many elements on the loaded page carry data-element=IDENTIFIER
#   harness_attr PAGE IDENTIFIER N ATTR  → the ATTR value of the N-th element carrying that identifier
#   harness_element_text PAGE IDENTIFIER N → the text inside the N-th element carrying that identifier
#   harness_text PAGE                    → the page's text, tags stripped
#   harness_assert STATUS MESSAGE        → counts one assertion; STATUS 0 passes, anything else fails the
#                                          case with MESSAGE (the runner reads PINS_ASSERTS and CASE_FAIL)
#   harness_run_hook NAME                → runs the pins hook NAME; a hook that asserts nothing fails the
#                                          case with `pins not authored`
# Fixture law: the records are hand-authored (data/records.txt, Provenance
# header); a page under $SCAFFOLD is what the product rendered — never
# read by a test as a string.
HARNESS_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || HARNESS_DIR=.
: "${HARNESS_ROOT:=$HARNESS_DIR}"
: "${HARNESS_LOG:=/dev/null}"
: "${SCAFFOLD:=.}"
HARNESS_FIXTURE=-
PINS_ASSERTS=0
CASE_FAIL=''

harness_engines() { printf 'alpha\nbeta\n'; }

harness_actor() {
  e=$1; a=$2
  [ "$a" = anonymous ] && return 0
  if grep -qx "$a" "$HARNESS_ROOT/data/actors.txt"; then printf 'actor %s %s\n' "$e" "$a" >> "$HARNESS_LOG"; return 0; fi
  echo "harness: no actor '$a' in the fixture (data/actors.txt) — the fixture did not hold; no row was measured" >&2
  return 1
}

harness_fixture() { HARNESS_FIXTURE=${1:--}; }

harness_load() {
  e=$1; a=$2; r=$3
  printf 'navigate %s %s %s %s\n' "$e" "$a" "$r" "$HARNESS_FIXTURE" >> "$HARNESS_LOG"
  slug=$(printf '%s' "$r" | sed 's#^/##; s#/#_#g'); [ -n "$slug" ] || slug=index
  for base in "$SCAFFOLD" ${SCAFFOLD_BASE:+"$SCAFFOLD_BASE"}; do   # quoted: a project path may hold a space
    if [ "$HARNESS_FIXTURE" != - ] && [ -f "$base/pages/$a/$HARNESS_FIXTURE/$slug.html" ]; then printf '%s\n' "$base/pages/$a/$HARNESS_FIXTURE/$slug.html"; return 0; fi
    if [ "$HARNESS_FIXTURE" = - ] && [ -f "$base/pages/$a/$slug.html" ]; then printf '%s\n' "$base/pages/$a/$slug.html"; return 0; fi
  done
  return 0
}

harness_page_size() { echo 3; }
harness_records() { grep -v '^#' "$HARNESS_ROOT/data/records.txt" | grep -v '^[[:space:]]*$'; }

harness_count() { [ -f "$1" ] || { echo 0; return 0; }; grep -oE "data-element=[\"']$2[\"']" "$1" | wc -l | tr -d ' '; }
harness_attr() {
  [ -f "$1" ] || return 0
  tr '\n' ' ' < "$1" | grep -oE "<[^>]*data-element=[\"']$2[\"'][^>]*>" | sed -n "${3}p" | sed -E "s/.*[[:space:]]$4=[\"']([^\"']*)[\"'].*/\1/"
}
harness_element_text() {
  [ -f "$1" ] || return 0
  tr '\n' ' ' < "$1" | awk -v id="$2" -v n="$3" '{
    s = $0; k = 0
    while (match(s, "<[A-Za-z][A-Za-z0-9-]*[^>]*data-element=[\"\047]" id "[\"\047][^>]*>")) {
      k++; tag = substr(s, RSTART + 1); sub(/[ \t>].*/, "", tag); s = substr(s, RSTART + RLENGTH)
      if (k == n) { t = s; close_tag = "</" tag ">"; if (index(t, close_tag) > 0) t = substr(t, 1, index(t, close_tag) - 1); gsub(/<[^>]*>/, " ", t); gsub(/[ \t]+/, " ", t); print t; exit }
    } }'
}
harness_text() { [ -f "$1" ] || return 0; sed 's/<!--[^>]*-->//g; s/<[^>]*>/ /g' "$1" | tr -s ' \n' '  '; }

harness_assert() {
  PINS_ASSERTS=$((PINS_ASSERTS + 1))
  if [ "$1" != 0 ]; then CASE_FAIL="${CASE_FAIL:+$CASE_FAIL; }$2"; return 1; fi
  return 0
}

harness_run_hook() {
  PINS_ASSERTS=0
  if command -v "$1" >/dev/null 2>&1; then "$1" || true; else CASE_FAIL="${CASE_FAIL:+$CASE_FAIL; }pins hook $1 not declared"; return 1; fi
  printf 'hook %s assertions=%s\n' "$1" "$PINS_ASSERTS" >> "$HARNESS_LOG"
  if [ "$PINS_ASSERTS" -eq 0 ]; then CASE_FAIL="${CASE_FAIL:+$CASE_FAIL; }pins not authored ($1)"; return 1; fi
  return 0
}
