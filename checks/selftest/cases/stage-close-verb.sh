#!/bin/sh
# Purpose: selftest case — the stage's end through its one entry, `close.sh stage <N>` (GM-4 K4, /vid:vid-stage-close), in each GitHub
# mode, on the writer's toy and the fake gh, stage 1 (S02, S03, S04). A row failing: refused, naming it, nothing posted. Due: the full
# run and the grade asked. Out: refused, naming what is missing. Its runs passed (planted): the walk started by walk.sh start, then,
# its walker ended, read; the summary's facts written; with the summary written, the stage closed; then refused as closed. A published
# step's stage is its ticket's header's in GitHub manual alone (D4, GM-3 S2). In GitHub manual (GM M16): round.sh step's `walk 1` is
# listed by the call as the move `walk-stage 1`, nothing starts until it is named, then the walker starts by walk.sh start and the
# call does not wait for it; with nothing left, end.sh complete writes the completion report and leaves RUN-STATE's run: line and
# its event out (decided for the owner). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/auto-t; mkdir -p "$T"; MO=auto
HOME=$T/home; export HOME; mkdir -p "$HOME"   # the plan page goes under HOME
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "stage-close-verb: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; WS=$CHECKS/walk.sh; R=owner/code; TAB=$(printf '\t')
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "$MO: no line: $1"; }
nis() { ls "$T/gh/issues" 2>/dev/null | grep -c . || true; }
# the walker: a fake command that writes, from the brief in its folder, a walk with every line done, once WALK_GO exists when it is set
mkwalker() { printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$PWD" "$@" > "$WALK_ARGS"; i=0; while [ -n "${WALK_GO:-}" ] && [ ! -f "$WALK_GO" ] && [ "$i" -lt 120 ]; do sleep 1; i=$((i + 1)); done' \
  '{ echo "by: WA"; sed -n "s/^candidate: /candidate: /p" brief.md; echo "browser: chrome"; echo "golden path: done"; sed -n "s/^- screen \([^:]*\):.*/screen \1: matches/p" brief.md' \
  '  awk '"'"'/^## The rows/ { on = 1; next } /^## / { on = 0 } on && /^- / { x = substr($0, 3); sub(/:.*/, "", x); print x ": done" }'"'"' brief.md; echo "wander: done"; } > walk.txt' > "$1"; chmod +x "$1"; }
# tk <n> <kind> <step> <rows,> <marks> <header stage>: a ticket published by hand; mg <n>: accepted (GitHub manual) or merged at a new main commit
tk() { { printf '# t\n\n## Header\n\n- number: %s\n- kind: %s\n- step: %s\n- stage: %s\n\n## Rows\n\n' "$1" "$2" "$3" "$6"; for r in $(echo "$4" | tr , ' '); do printf '> %s | behavior | a | b | n/a | x | REQ-001 | o\n- %s marks: %s\n' "$r" "$r" "$(echo "$5" | tr ' ' '\n' | sed -n "s/^$r=//p" | grep . || echo none)"; done
  printf '\n## Regression rows\n\n'; } > ".vid/tw/out/issue-$1.md"; gh issue create -R $R --title "t$1" --body b --label ticket > /dev/null
  printf 'published %s kind=%s step=%s rows=%s at=2026-11-09T10:00:00Z\n' "$1" "$2" "$3" "$4" >> .vid/tw/log; }
mg() { ( cd "$T/dev" && g commit -q --allow-empty -m "m$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main)
  if [ "$MO" = manual ]; then P=step-$1-$(printf %.12s "$MC"); else P=$((20 + $1)); fi; echo "$P" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$P" "$1" "$MC" "$MC" >> .vid/decide/merges; }
# a project in mode <mode>: the toy, stage 0 closed, stage 1's tickets accepted or merged, a screen's canvas
proj() { MO=$2; tw_toy "$1"; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out "$T/wk"
  printf 'close-chunk-minutes: 20\nclose-wait-minutes: 600\n' >> .vid/tw/settings; tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
  if [ "$MO" = manual ]; then printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied; fi
  gh issue create -R $R --title t0 --body b > /dev/null; tw_close 1
  tk 2 skeleton S01 ROW-003,ROW-004 '' 0; mg 2; tk 3 step S02 ROW-001 '' 1; mg 3; tk 4 step S03 ROW-006,SEAM-001,RULE-001 'SEAM-001=seam RULE-001=rule' 1; mg 4; tk 5 step S04 ROW-002 '' 1; mg 5
  for r in ROW-003 ROW-004 ROW-001 ROW-006 ROW-002 RULE-001; do tw_hand "row $r accepted"; done; tw_hand 'row SEAM-001 owed'; tw_hand 'closed S01'
  mkdir -p design/screens; echo '<html>the saved search canvas</html>' > 'design/screens/S01 Subscribe.dc.html'; mkwalker "$T/walker"; }
# the verb, in mode <mode>
verb() { proj "$T/$1" "$1"; n0=$(nis); K=.vid/decide/stage/1/1; VID_WALKER=$T/walker VID_WALK_TMP=$T/wk WALK_ARGS=$T/args; export VID_WALKER VID_WALK_TMP WALK_ARGS
  tw_hand 'row ROW-006 failing'; cs stage 1; [ "$RC" = 1 ] || fail "$MO: a stage not due exited $RC"; ok '^refused stage 1: no candidate is due: .*row ROW-006 failing'
  [ "$(nis)" = "$n0" ] && [ ! -d "$K" ] || fail "$MO: a refused stage close posted or wrote an ask"
  tw_hand 'row ROW-006 accepted'; cs stage 1; [ "$RC" = 0 ] || fail "$MO: the due stage exited $RC"; ok '^asked [0-9]* close stage-1$'; ok '^candidate 1 1$'
  if [ "$MO" = auto ]; then ok '^asked [0-9]* grade stage-1$'; else ok '^review stage-1 [0-9a-f]*$'; fi   # FB-3 A1.6: ViD's own grade in GitHub manual
  n1=$(nis); cs stage 1; [ "$RC" = 1 ] || fail "$MO: a stage with its runs out exited $RC"; ok '^refused stage 1: .*C3 not passed'; [ "$(nis)" = "$n1" ] || fail "$MO: a refused stage close posted"
  # its runs passed, its grade read, the seam row paid: the walk next
  mkdir -p "$K/d1" "$K/cs"; : > "$K/passed"; : > "$K/done"; : > "$K/d1/passed"; printf 'staging\thttp://127.0.0.1:5001\n' > "$K/d1/read"; : > "$K/cs/passed"; : > "$K/cs/ask"; tw_hand 'row SEAM-001 paid'
  for q in $(sed -n 's/^reqs\t//p' "$K/s1ask"); do printf '%s\tpass\t1\n' "$q"; done > .vid/decide/stage/1/s1; : > "$K/s1done"
  sh "$CHECKS/plan.sh" parse 2>/dev/null | awk -F'\t' '$1 == "row" && $3 ~ /^S0[234]$/ { print $2 }' | while read -r r; do grep -q "^row $r " .vid/tw/handed || tw_hand "row $r paid"; done   # the stage's other planned rows
  sh "$GS" results-fetch > /dev/null 2>&1 || fail "$MO: results-fetch failed"   # ViD's copy of the code repository, so the candidate holds its merges
  cs stage 1; [ "$RC" = 0 ] || fail "$MO: the walk's start exited $RC"; ok '^walk-started 1 [0-9]*$'; grep -qx claude-opus-5-5 "$T/args" 2>/dev/null || { sleep 1; grep -qx claude-opus-5-5 "$T/args"; } || fail "$MO: the walker was not started by walk.sh start"
  i=0; until sh "$WS" pending 2>/dev/null | grep -qx 'walk-read 1'; do i=$((i + 1)); [ "$i" -lt 30 ] || fail "$MO: the walker never ended"; sleep 1; done
  cs stage 1; [ "$RC" = 0 ] || fail "$MO: the walk's read exited $RC"; ok '^w1 done$'
  cs stage 1; [ "$RC" = 0 ] || fail "$MO: the summary's facts exited $RC"; ok '^facts 1 [0-9]* at '; ok '^summary 1$'; [ -s "$K/facts.txt" ] && [ ! -f "$K/summary.md" ] || fail "$MO: the facts were not written, or a summary was"
  { printf 'Went back: '; awk -F'\t' '$1 == "went-back" { printf "%s; ", $3 }' "$K/facts.txt"; printf '\nDecided for you: '; awk -F'\t' '$1 == "decided" { printf "%s; ", $2 }' "$K/facts.txt"; echo; } > "$K/summary.md"
  cs stage 1; [ "$RC" = 0 ] || fail "$MO: the close exited $RC"; ok '^stage-closed 1 at [0-9a-f]*$'; grep -q '^stage-closed 1 | stand-in: RM at ' .vid/tw/handed || fail "$MO: no stage-closed line"
  cs stage 1; [ "$RC" = 1 ] || fail "$MO: a closed stage exited $RC"; ok '^refused stage 1: closed already'
  # D4: a published step's stage is its ticket header's in GitHub manual, the plan's rule in GitHub auto
  sed 's/^- stage: 1$/- stage: 2/' .vid/tw/out/issue-5.md > "$T/i5" && cat "$T/i5" > .vid/tw/out/issue-5.md; cs step-stages; W=1; [ "$MO" = auto ] || W=2
  grep -qx "S04${TAB}$W" "$T/out" || fail "$MO: S04's stage is not $W: $(grep '^S04' "$T/out")"; }
verb auto
T=$T0/manual-t; mkdir -p "$T"; verb manual

# --- GitHub manual: the walk is a move the owner names (GM M16)
T=$T0/move-t; mkdir -p "$T"; unset VID_WALKER VID_WALK_TMP WALK_ARGS
. "$CHECKS/selftest/fixtures/accept.sh"
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail 'the plan could not be recorded'; sh "$CHECKS/github.sh" lock-free > /dev/null 2>&1 || fail 'the lock could not be freed'
printf 'engines alpha | stand-in: results reader\n' >> .vid/tw/handed; mkdir -p design/screens "$T/wk"; echo '<html>a canvas</html>' > 'design/screens/S01 Subscribe.dc.html'
F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs"; printf 'issue\t90\ncommit\t%s\nasked\t2026-11-19T10:00:00Z\n' "$AC_C" > "$F/ask"; echo "$AC_C" > "$F/commit"
: > "$F/named"; : > "$F/passed"; : > "$F/done"; : > "$F/d1/passed"; printf 'staging\thttp://127.0.0.1:5001\n' > "$F/d1/read"; : > "$F/cs/passed"; : > "$F/cs/ask"
mkwalker "$T/walker"; VID_WALKER=$T/walker VID_WALK_TMP=$T/wk WALK_ARGS=$T/args WALK_GO=$T/go; export VID_WALKER VID_WALK_TMP WALK_ARGS WALK_GO
sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || fail 'the connect did not start'; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'the read failed'
sh "$CHECKS/next-move.sh" call own-work on 'Yes, do your own work now' > "$T/out" 2>&1 || true; grep -q '^done own-work on' "$T/out" || fail 'own work was not switched on'
ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC"; grep -qx 'walk 1' "$T/out" || fail 'round.sh step printed no walk 1 line'
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; grep -q "^move${TAB}walk-stage${TAB}1${TAB}" "$T/L" || { cp "$T/L" "$T/out"; fail 'the call does not list the move walk-stage 1'; }
! ls "$F"/w1/*/pid > /dev/null 2>&1 || fail 'a walker started before the move was named'
sh "$CHECKS/next-move.sh" call > "$T/out" 2>&1 || fail 'the call with no move failed'; ! ls "$F"/w1/*/pid > /dev/null 2>&1 || fail 'a walker started with no move named'
sh "$CHECKS/next-move.sh" call walk-stage 1 'Yes, walk stage 1' > "$T/out" 2>&1 || true
grep -q '^done walk-stage 1: ' "$T/out" || fail 'the move walk-stage 1 was not done'; P=$(cat "$F"/w1/1/pid 2>/dev/null) || fail 'no walker pid recorded'
kill -0 "$P" 2>/dev/null && [ ! -f "$(cat "$F/w1/1/folder")/walk.txt" ] || fail 'the call waited for the walker: it had ended when the call returned'
grep -qx claude-opus-5-5 "$T/args" || fail 'the walker was not started by walk.sh start'
sh "$CHECKS/connect.sh" end > "$T/out" 2>&1 || fail 'the connect did not end'
# the walker ends; the next call lists read-walk 1, and the move reads the walk
: > "$WALK_GO"; i=0; while kill -0 "$P" 2>/dev/null; do i=$((i + 1)); [ "$i" -lt 30 ] || fail 'the walker never ended'; sleep 1; done
lst() { sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; }
sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || fail 'the connect did not start'; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'the read failed'
ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC"; grep -qx 'walk-read 1' "$T/out" || fail 'round.sh step printed no walk-read 1 line'
lst; grep -q "^move${TAB}read-walk${TAB}1${TAB}" "$T/L" || { cp "$T/L" "$T/out"; fail 'the call does not list the move read-walk 1'; }; [ ! -f "$F/w1/1/read" ] || fail 'the walk was read before the move was named'
sh "$CHECKS/next-move.sh" call > "$T/out" 2>&1 || fail 'the call with no move failed'
sh "$CHECKS/next-move.sh" call read-walk 1 'Yes, read the walk' > "$T/out" 2>&1 || true; grep -q '^done read-walk 1: w1 done$' "$T/out" || fail 'the move read-walk 1 did not read the walk done'
# every close condition met: step 2 prints summary 1 and writes no facts; the call lists write-summary 1; once named, the facts are written, the line gone
sh "$CHECKS/plan.sh" parse 2>/dev/null | awk -F'\t' '$1 == "row" { print $2 }' | sort -u | while read -r r; do grep -q "^row $r " .vid/tw/handed || printf 'row %s paid | stand-in: the self-test\n' "$r" >> .vid/tw/handed; done
for q in $(sh "$CHECKS/stages.sh" scope --upto 1 --reqs 2>/dev/null | grep '^REQ-'); do printf '%s\tpass\t1\n' "$q"; done > .vid/decide/stage/1/s1
sh "$CHECKS/close.sh" conds 1 > "$T/out" 2>/dev/null || true; [ ! -s "$T/out" ] || fail "the close's conditions are not met: $(cat "$T/out")"
ac_round step; [ "$RC" = 0 ] || fail "round.sh step exited $RC"; grep -qx 'summary 1' "$T/out" || fail 'round.sh step printed no summary 1 line'; [ ! -f "$F/facts.txt" ] || fail "step 2 wrote the summary's facts with no move named"
lst; grep -q "^move${TAB}write-summary${TAB}1${TAB}" "$T/L" || { cp "$T/L" "$T/out"; fail 'the call does not list the move write-summary 1'; }
sh "$CHECKS/next-move.sh" call > "$T/out" 2>&1 || fail 'the call with no move failed'; [ ! -f "$F/facts.txt" ] || fail 'the facts were written with no move named'
sh "$CHECKS/next-move.sh" call write-summary 1 'Yes, write the summary' > "$T/out" 2>&1 || true; grep -q '^done write-summary 1: facts 1 ' "$T/out" || fail 'the move write-summary 1 was not done'
[ -s "$F/facts.txt" ] && [ ! -f "$F/summary.md" ] || fail 'the move wrote no facts, or wrote the summary itself'; lst; ! grep -q "^move${TAB}write-summary${TAB}1${TAB}" "$T/L" || fail 'write-summary 1 is listed again once done'
sh "$CHECKS/connect.sh" end > "$T/out" 2>&1 || fail 'the connect did not end'

# --- the direct walk action keeps the no-walk rule: a stage with no screens and no journey starts no walker
T=$T0/none-t; mkdir -p "$T"; MO=auto; tw_toy "$T/toy"; mkdir -p .vid/round .vid/decide "$T/wk"; mkwalker "$T/walker"; unset WALK_GO; VID_WALKER=$T/walker VID_WALK_TMP=$T/wk; export VID_WALKER VID_WALK_TMP
sed 's/^\(ROW-003 | [^|]*| [^|]*| [^|]*| \)S01\/saved |/\1n\/a |/; s/^ROW-005 | journey | ingest |/ROW-005 | behavior | REQ-001 |/' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
X=$(git --git-dir="$T/code.git" rev-parse main); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs"; printf 'issue\t90\ncommit\t%s\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"
: > "$F/named"; : > "$F/passed"; : > "$F/d1/passed"; printf 'staging\thttp://127.0.0.1:5001\n' > "$F/d1/read"; : > "$F/cs/passed"; : > "$F/cs/ask"
cs walk 1; [ "$RC" = 1 ] || fail "the direct walk of a stage with no screens exited $RC"; ok '^refused stage 1: no walk is due: no walk is owed: no walk: this stage has no screens and no journey$'
! ls "$F"/w1/*/pid > /dev/null 2>&1 && [ -z "$(ls "$T/wk")" ] || fail 'a walker or a brief for a stage with no screens'; [ -f "$F/w1/none" ] || fail 'W1 is not recorded none'

# --- GitHub manual: nothing left, the end computed; the report written, RUN-STATE's run: line and its event left out (decided for the owner)
T=$T0/end-t; mkdir -p "$T"; tw_toy "$T/toy"; sh "$GS" spec-setup > /dev/null 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide/stage/2/1 .vid/tw/out; : > .vid/round/read
X=$(git --git-dir="$T/code.git" rev-parse main); E=.vid/decide/stage/2/1; echo "$X" > "$E/commit"; : > "$E/named"; printf 'issue\t9\ncommit\t%s\nasked\t2026-11-10T10:00:00Z\n' "$X" > "$E/ask"
printf 'issue\t10\ncommit\t%s\nasked\t2026-11-10T10:00:00Z\nreqs\tx\n' "$X" > "$E/s1ask"; : > "$E/s1done"; : > "$E/passed"
sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' '$2 == "row" && $5 != "later" && $6 != "later" { print $1 }' | while read -r r; do tw_hand "row $r accepted"; done
sh "$CHECKS/prd.sh" --effective 2>/dev/null | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); l = 0; for (i = 3; i <= NF; i++) if ($i ~ /phase:[ \t]*later/) l = 1 } k ~ /^REQ-[0-9]/ && !l { print k }' | sort -u | while read -r q; do printf '%s\tpass\t1\n' "$q"; done > .vid/decide/stage/2/s1
tw_hand "stage-closed 2 | stand-in: RM at $(printf %.12s "$X") candidate 1"; sed 's/^VID-QUESTION: /RESOLVED: /' PRD.md > "$T/p" && cp "$T/p" PRD.md; g commit -qam 'the questions answered'
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
RL=$(grep '^run:' .vid/RUN-STATE.md || true); RC=0; sh "$CHECKS/end.sh" complete > "$T/out" 2>&1 || RC=$?; MO=manual
[ "$RC" = 0 ] || fail "nothing left, the end exited $RC"; ok '^complete$'; grep -q '^Complete: every condition holds.$' .vid/decide/completion.md 2>/dev/null || fail 'no completion report, or it is not complete'
[ "$(grep '^run:' .vid/RUN-STATE.md || true)" = "$RL" ] || fail "RUN-STATE's run: line changed in GitHub manual: $(grep '^run:' .vid/RUN-STATE.md)"
! grep -q '^run state=complete' .vid/metrics-events 2>/dev/null || fail 'the run state=complete event was written in GitHub manual'
exit 0
