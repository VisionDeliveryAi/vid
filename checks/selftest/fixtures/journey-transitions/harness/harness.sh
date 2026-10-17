#!/bin/sh
# Purpose: the fixture harness client for journeys (v0.9.2 3.5 — a TOY, never
# installed). Two doors onto a toy product held in this shell's variables:
#   the ENGINE door — what a person does in a browser:
#     harness_press ENGINE ACTOR CONTROL    → presses one control on the current page; the page changes
#                                             as the product answers; records `press …` in $HARNESS_LOG
#     harness_page [ACTOR]                  → the marker of the page now shown to ACTOR (default member):
#                                             P02/default, P03/default, P03/applied, P04/default
#     harness_text [ACTOR]                  → the text of the page now shown to ACTOR
#   the API door — what a client program does:
#     harness_api ENGINE ACTOR METHOD PATH  → as ACTOR: POST /applications/<role> (201, or 409 when it
#                                             exists), DELETE /applications/<role> (204, or 404),
#                                             GET /applications (ACTOR's own roles, one per line); prints
#                                             the status first; records `api …` in $HARNESS_LOG. Never
#                                             changes the page shown.
#   setup:
#     harness_engines · harness_actor ENGINE ACTOR — the actors this harness provisions: `member` and
#     `other-member`, two signed-in members with their own applications · harness_reset (both members
#     fresh, no application, `member` on P02/default; setup may also use the API door — a transition
#     may not)
#     harness_assert STATUS MESSAGE — as in the surface fixture
# The authoring rule (3.5): a journey's transition is operated through the
# engine door and asserted on what the page then shows; the API door is for
# setup and for behavior rows. `TOY_PRODUCT=empty` makes every door answer
# 404 with no page — the empty scaffold, where every case must fail.
: "${HARNESS_LOG:=/dev/null}"
# the toy product's state lives in two files, not shell variables, so a door
# called inside $( ) still changes the product
: "${HARNESS_STATE:=$(mktemp -d)}"; export HARNESS_STATE
CASE_FAIL=''; PINS_ASSERTS=0
ROLE=role-7; ROLE_TITLE='Data Engineer'
_page() { cat "$HARNESS_STATE/page" 2>/dev/null || echo none; }
_setpage() { printf '%s\n' "$1" > "$HARNESS_STATE/page"; }
_apps() { cat "$HARNESS_STATE/apps.$1" 2>/dev/null || true; }
_add() { printf '%s\n' "$2" >> "$HARNESS_STATE/apps.$1"; }
_del() { _apps "$1" | grep -vx "$2" > "$HARNESS_STATE/apps.new" || true; mv "$HARNESS_STATE/apps.new" "$HARNESS_STATE/apps.$1"; }

harness_engines() { printf 'alpha\n'; }
harness_actor() { case "$2" in member|other-member) printf 'actor %s %s\n' "$1" "$2" >> "$HARNESS_LOG"; return 0 ;; esac; echo "harness: no actor '$2' (member, other-member)" >&2; return 1; }
harness_reset() { : > "$HARNESS_STATE/apps.member"; : > "$HARNESS_STATE/apps.other-member"; if [ "${TOY_PRODUCT:-}" = empty ]; then _setpage none; else _setpage P02/default; fi; printf 'reset\n' >> "$HARNESS_LOG"; }
harness_assert() { PINS_ASSERTS=$((PINS_ASSERTS + 1)); if [ "$1" != 0 ]; then CASE_FAIL="${CASE_FAIL:+$CASE_FAIL; }$2"; return 1; fi; return 0; }
_applied() { _apps "$1" | grep -qx "$2"; }

harness_press() {
  e=$1; a=$2; c=$3; from=$(harness_page)
  if [ "${TOY_PRODUCT:-}" = empty ]; then printf 'press %s %s %s from=%s to=none 404\n' "$e" "$a" "$c" "$from" >> "$HARNESS_LOG"; _setpage none; return 0; fi
  case "$from/$c" in
    P02/default/View) _setpage P03/default ;;
    P03/default/Apply) _add "$a" "$ROLE"; _setpage P03/applied ;;
    P03/applied/Withdraw) _del "$a" "$ROLE"; _setpage P03/default ;;
    */My\ applications) _setpage P04/default ;;
    *) printf 'press %s %s %s from=%s no-such-control\n' "$e" "$a" "$c" "$from" >> "$HARNESS_LOG"; return 0 ;;
  esac
  printf 'press %s %s %s from=%s to=%s\n' "$e" "$a" "$c" "$from" "$(harness_page "$a")" >> "$HARNESS_LOG"
}
# the page a role shows follows the product's state, whichever door changed it
harness_page() { a=${1:-member}; p=$(_page); case "$p" in P03/*) if _applied "$a" "$ROLE"; then p=P03/applied; else p=P03/default; fi; _setpage "$p" ;; esac; printf '%s\n' "$p"; }
harness_text() {
  a=${1:-member}
  case "$(harness_page "$a")" in
    P02/default) echo "Jobs — $ROLE_TITLE [View]" ;;
    P03/default) echo "$ROLE_TITLE — [Apply]" ;;
    P03/applied) echo "$ROLE_TITLE — Application sent [Withdraw]" ;;
    P04/default) n=$(_apps "$a" | grep -c .); if [ "$n" -eq 0 ]; then echo 'My applications — No applications'; else echo "My applications — $n application(s): $(_apps "$a" | tr '\n' ' ')"; fi ;;
    *) echo '404 — no page' ;;
  esac
}
harness_api() {
  e=$1; a=$2; m=$3; p=$4
  printf 'api %s %s %s %s\n' "$e" "$a" "$m" "$p" >> "$HARNESS_LOG"
  if [ "${TOY_PRODUCT:-}" = empty ]; then echo 404; return 0; fi
  case "$m $p" in
    "POST /applications/"*) r=${p##*/}; if _applied "$a" "$r"; then echo 409; else _add "$a" "$r"; echo 201; fi ;;
    "DELETE /applications/"*) r=${p##*/}; if _applied "$a" "$r"; then _del "$a" "$r"; echo 204; else echo 404; fi ;;
    "GET /applications") echo 200; _apps "$a" | grep . || true ;;
    *) echo 404 ;;
  esac
}
