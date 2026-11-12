#!/bin/sh
# Purpose: selftest case — completion, computed (v0.26.10.27.4, stage 8.3, R2, R3), checks/end.sh and close.sh endconds on the writer's
# toy (stages 0 to 2) and the fake gh. All six conditions met: complete, the report's nine parts each with its evidence, `run: complete`
# and its event; --check writes nothing. Then each condition unmet alone: the final stage's newest candidate not closed; a row not yet
# decided; a requirement with no grade; a grade ask out; a ticket open; a question open; a PRD VID-QUESTION; a finding unruled, and a
# row ruling whose draft has not landed. Unmet, the report is written and RUN-STATE keeps its run: line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "end-complete: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; ES=$CHECKS/end.sh; TAB=$(printf '\t'); R=owner/code
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
en() { RC=0; sh "$ES" complete "$@" > "$T/out" 2>&1 || RC=$?; }
sh "$GS" spec-setup > /dev/null 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide/stage/2/1 .vid/tw/out; : > .vid/round/read
X=$(git --git-dir="$T/code.git" rev-parse main); echo "$X" > .vid/decide/stage/2/1/commit; : > .vid/decide/stage/2/1/named; printf 'issue\t9\ncommit\t%s\nasked\t2026-11-10T10:00:00Z\n' "$X" > .vid/decide/stage/2/1/ask
printf 'issue\t10\ncommit\t%s\nasked\t2026-11-10T10:00:00Z\nreqs\tx\n' "$X" > .vid/decide/stage/2/1/s1ask; : > .vid/decide/stage/2/1/s1done; : > .vid/decide/stage/2/1/passed
sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' '$2 == "row" && $5 != "later" && $6 != "later" { print $1 }' > "$T/rows"; while read -r r; do tw_hand "row $r accepted"; done < "$T/rows"   # later rows get no handed line
LR=$(sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' '$2 == "row" && ($5 == "later" || $6 == "later") { print $1; exit }'); [ -n "$LR" ] || fail 'no later row in the toy'
sh "$CHECKS/prd.sh" --effective 2>/dev/null | awk -F'|' '{ k = $1; gsub(/[ \t]/, "", k); l = 0; for (i = 3; i <= NF; i++) if ($i ~ /phase:[ \t]*later/) l = 1 } k ~ /^REQ-[0-9]/ && !l { print k }' | sort -u > "$T/reqs"
while read -r q; do printf '%s\tpass\t1\n' "$q"; done < "$T/reqs" > .vid/decide/stage/2/s1
tw_hand "stage-closed 2 | stand-in: RM at $(printf %.12s "$X") candidate 1"; sed 's/^VID-QUESTION: /RESOLVED: /' PRD.md > "$T/p" && cp "$T/p" PRD.md   # the toy's open questions answered
mkdir -p .vid/results; printf 'RULE-001\tpassed\tcovers 3\n' > .vid/results/pr-30-abc.txt   # a rule row's count, as the results reader keeps it
printf 'flag word=stuck on=S02 at=2026-11-10T09:00:00Z\nflag-cleared word=stuck on=S02 at=2026-11-10T09:30:00Z\n' >> .vid/metrics-events   # raised and cleared
# all met
en --check; [ "$RC" = 0 ] && ok '^complete$' || fail "--check: not complete ($RC)"; [ ! -f .vid/decide/completion.md ] && ! grep -q '^run: complete' .vid/RUN-STATE.md || fail '--check wrote something'
tw_hand "production 2 | stand-in: D2 #53 at $(printf %.12s "$X")" 2>/dev/null; sed -i.b 's/^\(production 2 | stand-in: D2 #53 at [0-9a-f]*\) | stand-in: the self-test$/\1/' .vid/tw/handed   # 8.1b's real line
en; [ "$RC" = 0 ] && ok '^complete$' || fail "not complete ($RC)"; grep -q '^run: complete$' .vid/RUN-STATE.md && grep -q '^run state=complete ' .vid/metrics-events || fail 'no run: complete or no event'
C=.vid/decide/completion.md; for h in '## 1. The rows' '## 2. Completion' '## 3. What shipped, by requirement' '## 4. The deploy-owed rows and the later items' '## 5. The rule rows' '## 6. The metrics roll-up' "## 7. The findings for the owner's ruling" "## 8. The decisions ViD made on the owner's behalf" '## 9. The open questions'; do grep -qxF "$h" "$C" || fail "the report lacks: $h"; done
grep -qx "Stage 2 is in production (D2 #53 at $(printf %.12s "$X"), the handed record). Stage 0 is never released." "$C" || fail "the production line: $(grep -i 'production' "$C" | head -n 3)"
grep -q '^Complete: every condition holds.$' "$C" && grep -q "^- $(head -n 1 "$T/reqs"): pass, graded at stage 2's candidate 1 (grade ask #10)$" "$C" && grep -q 'rows at deploy$' "$C" && grep -q ' later$' "$C" || fail "the report's lines: $(sed -n 1,40p "$C")"
grep -q '^- RULE-001: 3 places (.vid/results/pr-30-abc.txt)$' "$C" && grep -q '^1 later$' "$C" && grep -q '^- REQ-020 (PRD.md, phase: later)$' "$C" || fail "the rule rows or the later items: $(sed -n '/^## 4/,/^## 6/p' "$C")"
grep -q '^- flag word=stuck on=S02 ' "$C" && grep -q '^- flag-cleared word=stuck on=S02 ' "$C" || fail 'the roll-up lacks a flag raised and cleared'
{ [ -z "$LR" ] || { grep -q '^- later: [0-9]' "$C" && ! grep -q '^- not-yet-decided' "$C" && ! grep -q "^- $LR: owed to" "$C"; }; } || fail "a later row read undecided or deploy-owed: $(sed -n '/^## 1/,/^## 2/p' "$C")"
grep -q '^- accepted: ' "$C" && ! grep -qi 'test' "$(sed -n '/^## 1/,/^## 2/p' "$C" > "$T/h1"; echo "$T/h1")" || fail 'the rows headline'
VID_STATUS_KEEP=1 sh "$CHECKS/queue.sh" status > "$T/out" 2>&1; ok '^end: complete$'   # R7
sed 's/^run:.*/run: active/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
# requirement ids matched whole: a row derived from REQ-0010 alone, merged after the grade, is no row of REQ-001
cp INVENTORY.md "$T/inv"; cp .vid/tw/handed "$T/hd"; awk '/^ROW-020 \|/ { print; print "ROW-099 | behavior | REQ-0010 | (process) | n/a | A plant. Fails if it fails. | REQ-0010 | owed: spec-only — ticket"; next } { print }' "$T/inv" > INVENTORY.md
grep -q '^ROW-099 ' INVENTORY.md || fail 'no ROW-099 planted'; tw_hand 'row ROW-099 accepted'; printf 'published 50 kind=step step=S02 rows=ROW-099 at=2026-11-10T12:00:00Z\n' >> .vid/tw/log; printf '60\t50\tabc\tdeadbeef0000\n' >> .vid/decide/merges
en; [ "$RC" = 0 ] || fail "REQ-001 read REQ-0010's row as its own ($RC)"; cp "$T/inv" INVENTORY.md; cp "$T/hd" .vid/tw/handed; grep -v '^published 50 ' .vid/tw/log > "$T/l" || true; cat "$T/l" > .vid/tw/log; grep -v '^60	' .vid/decide/merges > "$T/m" || true; cat "$T/m" > .vid/decide/merges
sed 's/^run:.*/run: active/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
un() { en; [ "$RC" = 1 ] || fail "$1: complete ($RC)"; ok "^$2"; grep -q '^run: active$' .vid/RUN-STATE.md || fail "$1: run: changed"; grep -q "condition ${2%% *}" .vid/decide/completion.md || fail "$1: the report lacks the condition"; }
# 1: the newest candidate not closed
mkdir -p .vid/decide/stage/2/2; echo "$X" > .vid/decide/stage/2/2/commit; : > .vid/decide/stage/2/2/named; printf 'issue\t11\ncommit\t%s\nasked\t2026-11-10T11:00:00Z\n' "$X" > .vid/decide/stage/2/2/ask
un 'candidate 2 open' "1 stage 2's newest candidate, 2, is not closed"; VID_STATUS_KEEP=1 sh "$CHECKS/queue.sh" status > "$T/out" 2>&1; ok '^end: [0-9]* conditions unmet$'; rm -rf .vid/decide/stage/2/2
# 2: a row not yet decided
r=$(head -n 1 "$T/rows"); grep -v "^row $r " .vid/tw/handed > "$T/h"; cp .vid/tw/handed "$T/h0"; cat "$T/h" > .vid/tw/handed; un 'a row undecided' "2 $r not yet decided"; cat "$T/h0" > .vid/tw/handed
# 3: a requirement with no grade; a grade ask out
q=$(head -n 1 "$T/reqs"); cp .vid/decide/stage/2/s1 "$T/s1"; grep -v "^$q$TAB" "$T/s1" > .vid/decide/stage/2/s1; un 'no grade' "3 $q not graded"; cp "$T/s1" .vid/decide/stage/2/s1
mkdir -p .vid/decide/grade/12; printf 'issue\t12\ncommit\t%s\nasked\t2026-11-10T11:00:00Z\nreqs\t%s\n' "$X" "$q" > .vid/decide/grade/12/ask; un 'a grade ask out' '3 a grade ask out'; rm -rf .vid/decide/grade/12
rm .vid/decide/stage/2/1/s1done; un 'a stage grade out' '3 a stage grade out: 2/1, #10'; : > .vid/decide/stage/2/1/s1done
# 4: a ticket open
printf 'issue\t13\tticket\tb\t-\n' > .vid/round/read; un 'a ticket open' '4 ticket #13 open'; : > .vid/round/read
# 5: a question open; a PRD VID-QUESTION
mkdir -p .vid/decide/queue; printf '13:1\t13\tQuestion: may the list be public?\tasked\n' > .vid/decide/queue/questions; un 'a question' '5 '; : > .vid/decide/queue/questions
cp .vid/RUN-STATE.md "$T/rs1"; awk '/^## Open product questions/ { print; print ""; print "- Q999 · asked 2026-11-10 · the session asks: may a digest be sent twice?"; next } { print }' "$T/rs1" > .vid/RUN-STATE.md; grep -q '^- Q999 ' .vid/RUN-STATE.md || printf '\n## Open product questions\n\n- Q999 · the session asks: may a digest be sent twice?\n' >> .vid/RUN-STATE.md
un "the session's own question" '5 Q999 open in RUN-STATE'; grep -q '^- Q999: .* (RUN-STATE)$' .vid/decide/completion.md || fail "the report's open questions lack the session's own"; cp "$T/rs1" .vid/RUN-STATE.md
cp PRD.md "$T/prd"; echo 'VID-QUESTION: (OQ-99) May a digest be sent twice?' >> PRD.md; un 'a VID-QUESTION' '5 PRD.md:'; cp "$T/prd" PRD.md
# 6: a row ruling whose draft has not landed
printf '2026-11-10T11:00:00Z\tstage:1:1:1\trow\tthe owner\towner\tto the door\n' > .vid/decide/queue/answers; echo 'stage:1:1:1' > .vid/decide/queue/doors; un 'a draft unlanded' '6 stage:1:1:1 ruled'
mkdir -p .vid/decide/drafts/1; echo 'stage:1:1:1' > .vid/decide/drafts/1/for; : > .vid/decide/drafts/1/declined; en; [ "$RC" = 0 ] || fail "a declined draft still held completion ($RC)"
echo 'end-complete: ok'
