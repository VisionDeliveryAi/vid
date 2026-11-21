#!/bin/sh
# Purpose: selftest case — a refused plan change keeps every line (low-1, R2), checks/land.sh on the writer's toy and the fake gh.
# S04 builds on S02 and S03; all three started, S02 and S03 then not closed: a draft adding ROW-021 to S04 is refused by rule B
# with two gap lines, and land.sh's refusal holds both, each with its step and rows, on one line. Then the same draft is made while
# S02 and S03 are closed, the records change so that rule B refuses it, and `land.sh <n>`'s own dry run refuses it the same way:
# both gap lines, one line, nothing landed. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "land-refusal-lines: $*" >&2; sed 's/^/    /' "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
LS=$CHECKS/land.sh; printf 'none\n' > "$T/rv"; sed "s/^open-tickets: 2$/open-tickets: 9/" .vid/tw/settings > "$T/st" && cp "$T/st" .vid/tw/settings
ld() { RC=0; if [ "$1" = draft ]; then shift; set -- draft --review "$T/rv" "$@"; fi; sh "$LS" "$@" > "$T/out" 2>&1 || RC=$?; }
tw_start S02 || fail "S02 was refused: $(cat "$T/start")"; tw_start S03 || fail "S03 was refused: $(cat "$T/start")"
tw_closed S02; tw_closed S03; tw_start S04 || fail "S04 was refused: $(cat "$T/start")"
R2=$(sh "$CHECKS/plan.sh" parse | awk -F'\t' '$1 == "row" && $3 == "S02" { printf "%s%s", (n++ ? " " : ""), $2 }'); R3=$(sh "$CHECKS/plan.sh" parse | awk -F'\t' '$1 == "row" && $3 == "S03" { printf "%s%s", (n++ ? " " : ""), $2 }')
[ -n "$R2" ] && [ -n "$R3" ] || fail 'no rows for S02 or S03'
# the draft: ROW-021 added to INVENTORY.md and to S04's rows
spec() { awk '/^ROW-020 \|/ { print; print "ROW-021 | behavior | REQ-001 | (process) | n/a | A job read twice in a day is listed once with its first read time. Fails if a second read moves its time. | REQ-001 | owed: spec-only — ticket"; next } { print }' INVENTORY.md > "$T/i" && cp "$T/i" INVENTORY.md
  sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | sed '1d;$d' | sed 's/^\(step S04 .*rows: [^|]*RULE-004\) /\1 ROW-021 /; s/^\(needs ROW-002 .*RULE-004\) /\1 ROW-021 /' > "$T/plan"; grep -q 'RULE-004 ROW-021 |' "$T/plan" || fail "the plan block was not drafted: $(grep 'step S04' "$T/plan")"; }
open_() { grep -v '^closed S0[23] ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed; }   # S02 and S03 not closed, their rows accepted
# one line holding both gap lines, each with its step and rows
lines() { W=$(grep "$1" "$T/out") || fail "no refusal line: $1"; [ "$(printf '%s\n' "$W" | grep -c .)" = 1 ] || fail 'the refusal spreads over more than one line'
  for g in "S04 builds on S02, which is not closed, and its rows $R2 are not owed" "S04 builds on S03, which is not closed, and its rows $R3 are not owed"; do
    printf '%s\n' "$W" | grep -qF "$g" || fail "the refusal lacks the gap line: $g"; done
  [ "$(grep -c . "$T/out")" = 1 ] || fail "the refusal is not one line: $(grep -c . "$T/out") lines"; }
# the draft's refusal (LA:116, from the dry run's LA:241)
H0=$(git rev-parse HEAD); cp .vid/tw/handed "$T/handed"; open_; spec
ld draft --why 'ROW-021 added to S04' --plan "$T/plan"; [ "$RC" = 1 ] || fail "rule B did not refuse the draft ($RC)"; lines 'the draft could not land'
[ "$(git rev-parse HEAD)" = "$H0" ] && [ ! -d .vid/decide/drafts/1 ] || fail 'a refused draft was made or committed'; git checkout -q -- INVENTORY.md
# the landing's refusal (LA:241): the draft made with S02 and S03 closed, then the records change so that rule B refuses it
cp "$T/handed" .vid/tw/handed; spec; ld draft --why 'ROW-021 added to S04' --plan "$T/plan"; [ "$RC" = 0 ] || fail "the draft failed ($RC)"; grep -q '^draft 1$' "$T/out" || fail 'no draft 1'
open_; ld 1 --words 'Yes, land it'; [ "$RC" = 1 ] || fail "rule B did not refuse the landing ($RC)"; lines "the dry run's plan change was refused"
[ "$(git rev-parse HEAD)" = "$H0" ] && [ ! -s .vid/decide/landed ] || fail 'a refused landing landed something'
echo 'land-refusal-lines: ok'
