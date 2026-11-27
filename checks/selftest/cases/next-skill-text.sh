#!/bin/sh
# Purpose: selftest case — the /vid next and /vid mode skills hold only order (GM-1 S9, S5, S6; its case next-skill-text). vid-next
# names its steps in order and invokes vid-connect, vid-read and vid-triggers by name; vid-connect holds Slack's check (the
# connector's tools, each channel's read, `none`, never a stop) and the restore and the lock before the refresh (GM-4 F2); vid-read holds Slack's reading rules (the
# marks, the match, the link and one-line reading alone, never posting, never deciding); no tier word, warning or count rule is in
# vid-next's or vid-mode's text. GM-2 T10: vid-next runs the moves the owner names through next-move.sh call, names phase 2's
# moves (publish, amend, withdraw, team-change, answer, done, decline, engines) by kind and subject, and ends the call
# (vid-connect's end) after them; vid-tickets holds its GitHub manual paragraphs behind the mode check (the issue form, the
# owner's words) in its SKILL.md, no manual.md beside it (GM-4 F6). GM-3 U6: vid-next names the three re-plan moves (planning-analysis, implement-replan, accept-spec-change), invokes
# the vid-replan skill by name for planning-analysis after next-move.sh call and before the call's end, leaves no move to a
# later phase, and holds no rule. GM-4 K11's first cut (F15, F9, K6): step 0 reads the one mode command, devagent-start.sh mode
# (no `next.sh mode`); step 1 connects as every caller does (no `--run`); step 6 names the vid-answer skill for the answer and
# decline moves, one line each, and holds none of their forms (vid-answer holds them); no `accept-spec-change` move (a draft is
# answered through vid-answer). GM-4 K11's step 6 (4b): publish, amend, withdraw and reopen one line each naming vid-tickets,
# team-change and done vid-answer, planning-analysis and implement-replan vid-replan, each move's form in its skill and none in
# vid-next; FB-5 A1: the owner's list sorted by the vid-sort skill, step 7, before the save, step 8; no plan page in vid-next or
# vid-triggers, the re-plan page's show vid-replan's, named after the save, its rules there alone. GM-4 K11's step 2 (4c): ViD's own work
# a list of skill calls in order, one line each: vid-accept-step (`round.sh step`, then `round.sh accept` for each `decide` line),
# vid-step-close, then `round.sh asks`; behind the owner's switch (`next.sh own-work`: until on, one line saying it is off, listing the
# move `own-work on`, and each `context ask` line said with its command); none of those skills' lines in vid-next. Step 6 (F16): the
# engines and own-work moves one line each naming vid-accept-step, their forms there alone; the writer's refusal of a publish with no
# engines line names the engines move. F13: vid-mode says what stays readable after the switch (the `step-` records and unit-merges,
# read in both modes). GM-4 K11's stage calls (4d): step 2 names vid-stage-close, vid-deploy and vid-grade, one line each, between
# vid-step-close and `round.sh asks`, which posts the owed asks, okays and stage close; step 6 names the walk-stage, read-walk and
# write-summary moves one line each as vid-stage-close's, their forms and their done lines there alone, none of the stage's, the okays'
# or the grade ask's lines in vid-next. Reads skills/: skipped in a project's layout. Env: CHECKS.
# FB-2 A2: step 0's none, with no ratified line in .vid/plan/ratified, invokes the vid-plan skill and does its sitting, the owner's yes its
# GitHub manual route through the vid-mode skill, then step 1; it no longer ends naming /vid:vid-plan.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-run" ] || { echo 'next-skill-text: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "next-skill-text: $*" >&2; exit 1; }
[ -f "$S/vid-next/SKILL.md" ] && [ -f "$S/vid-connect/SKILL.md" ] && [ -f "$S/vid-read/SKILL.md" ] && [ -f "$S/vid-mode/SKILL.md" ] || fail "a skill of /vid next or /vid mode is missing"
N=$S/vid-next/SKILL.md; C=$S/vid-connect/SKILL.md; R=$S/vid-read/SKILL.md; M=$S/vid-mode/SKILL.md
T0=$(mktemp); trap 'rm -f "$T0"' EXIT
awk '/^[0-9]\. \*\*/ { print $1 }' "$N" | paste -sd' ' - | grep -qx '0. 1. 2. 3. 4. 5. 6. 7. 8.' || fail 'vid-next does not name its steps 0 to 8 in order'
for k in 'devagent-start.sh" mode' vid-connect vid-read vid-triggers; do grep -q "$k" "$N" || fail "vid-next does not call $k"; done
# FB-2 A2: step 0's none, with no ratified line, plans first through the vid-plan skill, its yes the GitHub manual route through the
# vid-mode skill, then step 1; DevAgent's answer names /vid:vid-run; no "/vid:vid-plan plans it" ending
awk '/^0\. \*\*The mode/ { on = 1 } on && /^1\. \*\*/ { exit } on' "$N" | tr '\n' ' ' > "$T0"
for p in 'invoke the `vid-plan` skill' 'no `ratified` line' '`.vid/plan/ratified`' 'the `vid-mode` skill' '--words' 'go on at step 1' '/vid:vid-run'; do grep -qiF -- "$p" "$T0" || fail "vid-next's step 0 does not say: $p"; done
! grep -qF '/vid:vid-plan plans it' "$T0" || fail "vid-next's step 0 still ends naming /vid:vid-plan"
a=$(grep -n 'Invoke the `vid-connect`' "$N" | cut -d: -f1); b=$(grep -n 'Invoke the `vid-read`' "$N" | cut -d: -f1); c=$(grep -n 'Invoke the `vid-triggers`' "$N" | cut -d: -f1)
[ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ] || fail 'vid-next does not invoke vid-connect, vid-read and vid-triggers in that order'
grep -q 'connect.sh" start' "$C" && grep -q 'the records. restore and the lock first, then the refresh of' "$C" || fail 'vid-connect does not run the restore and the lock before the refresh (GM-4 F2)'
grep -q 'slack-channels:' "$C" && grep -q '`none`' "$C" && grep -q "Slack connector's tools" "$C" && grep -q 'read each channel' "$C" && grep -q 'Slack never stops a call' "$C" || fail "vid-connect lacks one of Slack's check rules"
grep -q 'connect.sh end' "$C" || fail 'vid-connect does not end the call with the save and the lock freed'
grep -q 'slack-read' "$R" && grep -q 'so no message is read twice' "$R" || fail 'vid-read does not keep the marks'
grep -q 'by a `#<n>` in it, or a link' "$R" && grep -q 'unmatched' "$R" || fail 'vid-read does not match each message or list it as unmatched'
grep -q "Never the message's text" "$R" && grep -q 'one-line reading' "$R" || fail 'vid-read may keep a message'"'"'s text'
grep -q 'Never post to Slack' "$R" && grep -q 'Nothing read there changes a record, decides, answers or counts as a report' "$R" || fail 'vid-read lacks the rule that Slack decides nothing and is never posted to'
grep -q 'belongs on its ticket' "$R" || fail 'vid-read does not turn a Slack-only ask into a line for the owner'
grep -q 'next-move.sh" call' "$N" || fail 'vid-next does not run the moves through next-move.sh call'
for m in publish amend withdraw team-change answer done decline engines; do grep -q "\`$m " "$N" || fail "vid-next does not name the move $m"; done
a=$(grep -n 'next-move.sh" call <move>' "$N" | head -n 1 | cut -d: -f1); b=$(grep -n "vid-connect's end" "$N" | tail -n 1 | cut -d: -f1)
[ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] || fail 'vid-next does not end the call after the moves named'
# GM-3 U6: the re-plan's three moves named; planning-analysis's analysis the vid-replan skill's, after the moves, before the save
for m in 'planning-analysis' 'implement-replan'; do grep -qF "\`$m" "$N" || fail "vid-next does not name the move $m"; done
a=$(grep -n 'next-move.sh" call <move>' "$N" | head -n 1 | cut -d: -f1); r=$(grep -n 'Invoke the `vid-replan` skill' "$N" | head -n 1 | cut -d: -f1); b=$(grep -n '^7\. \*\*' "$N" | cut -d: -f1)
[ -n "$a" ] && [ -n "$r" ] && [ -n "$b" ] && [ "$a" -lt "$r" ] && [ "$r" -lt "$b" ] || fail 'vid-next does not invoke vid-replan after the moves and before the call ends'
! grep -qi 'done from phase\|from phase 3' "$N" || fail 'vid-next still leaves a move to phase 3'
# GM-4 F6: the ticket writer's GitHub manual text is in its SKILL.md (no manual.md), behind the one mode command
TW=$S/vid-tickets/SKILL.md; [ ! -e "$S/vid-tickets/manual.md" ] && grep -q 'devagent-start.sh"\{0,1\} mode' "$TW" && grep -q 'issue-form:' "$TW" && grep -q "owner's words" "$TW" || fail 'vid-tickets lacks its GitHub manual paragraphs in SKILL.md behind the mode check'
for f in "$N" "$M"; do grep -niE 'critical|important|minor|tier [0-9]|warn(ing)? (when|if)|more than [0-9]|[0-9]+ days|open-ticket limit|counted once|first kind|re-plan rule|top-up' "$f" > /dev/null && { grep -niE "critical|important|minor" "$f" >&2; fail "$(basename "$(dirname "$f")") holds a tier, warning, count or re-plan rule"; } || :; done
# GM-4 K11 (F15, F9, K6): one mode command, the connect every caller's, the answer and decline moves vid-answer's, no accept-spec-change
! grep -qE 'next\.sh"? mode' "$N" || fail 'vid-next still reads next.sh mode'
! grep -qF -- '--run' "$N" || fail "vid-next runs the run's start"
! grep -q 'accept-spec-change' "$N" || fail 'vid-next still names the accept-spec-change move'
for m in answer decline; do [ "$(grep -c "^   - \`$m " "$N")" = 1 ] || fail "vid-next does not name the $m move in one line"
  grep "^   - \`$m " "$N" | grep -q '`vid-answer`' || fail "vid-next's $m move does not name the vid-answer skill"; done
A=$S/vid-answer/SKILL.md; [ -f "$A" ] || fail 'there is no vid-answer skill'
for f in 'answer "#<n>:<k>" there "<words>"' 'decline <what> ["<subject>"] "<words>"'; do ! grep -qF -- "$f" "$N" || fail "vid-next still holds the move's form $f"
  grep -qF -- "$f" "$A" || fail "vid-answer does not hold the move's form $f"; done
# GM-4 K11 step 6 (4b): each move one line naming the skill it calls; the moves' forms are the skills', none in vid-next
for mv in publish:vid-tickets amend:vid-tickets withdraw:vid-tickets reopen:vid-tickets team-change:vid-answer done:vid-answer planning-analysis:vid-replan implement-replan:vid-replan; do
  m=${mv%%:*}; k=${mv#*:}; [ "$(grep -c "^   - \`$m " "$N")" = 1 ] || fail "vid-next does not name the $m move in one line"
  grep "^   - \`$m " "$N" | grep -q "\`$k\`" || fail "vid-next's $m move does not name the $k skill"; done
TK=$S/vid-tickets/SKILL.md
for mf in 'vid-tickets|publish <step> "<words>"' 'vid-tickets|--title "<title>"' 'vid-tickets|amend "#<n>" "<words>"' 'vid-tickets|withdraw "#<n>" "<words>"' 'vid-tickets|reopen "#<n>" "<words>"' 'vid-answer|team-change "#<n>" <id> yes "<words>"' 'vid-answer|done "<kind> <subject>" "<words>"' 'vid-replan|implement-replan "<words>"'; do
  k=${mf%%|*}; f=${mf#*|}; ! grep -qF -- "$f" "$N" || fail "vid-next still holds the move's form $f"; grep -qF -- "$f" "$S/$k/SKILL.md" || fail "$k does not hold the move's form $f"; done
# FB-5 A1: no plan page; the sort a step of its own before the save; the re-plan page vid-replan's show, after it, its rules there alone
! grep -qi 'plan page' "$S/vid-triggers/SKILL.md" && ! grep -qiE '(^|[^-])plan page' "$N" || fail 'vid-next or vid-triggers still names the plan page'
grep -n '^7\. \*\*Sort' "$N" | grep -q . && awk '/^7\. \*\*/ { on = 1 } /^8\. \*\*/ { exit } on' "$N" | grep -qF 'Invoke the `vid-sort` skill' && grep -q '^8\. \*\*Save' "$N" || fail 'vid-next does not sort through vid-sort before its save'
e=$(grep -n '^8\. \*\*' "$N" | cut -d: -f1); p=$(grep -n 'The re-plan page' "$N" | tail -n 1 | cut -d: -f1)
[ -n "$e" ] && [ -n "$p" ] && [ "$p" -gt "$e" ] || fail "vid-next does not name the re-plan page after its step 8"
for f in 'next-move.sh shell' 'action: "read"'; do ! grep -qF -- "$f" "$N" || fail "vid-next holds the re-plan page's rule: $f"
  grep -qF -- "$f" "$S/vid-replan/SKILL.md" || fail "vid-replan does not hold the re-plan page's rule: $f"; done
# GM-4 K11 step 2 (4c): the skills in order, one line each, behind the owner's switch; none of their lines here
K2=$S/vid-accept-step/SKILL.md; K3=$S/vid-step-close/SKILL.md; [ -f "$K2" ] && [ -f "$K3" ] || fail 'vid-accept-step or vid-step-close is missing'
S2=$(awk '/^2\. \*\*/ { on = 1 } on && /^3\. \*\*/ { exit } on' "$N")
! printf '%s\n' "$S2" | grep -qi 'later phase' || fail "vid-next's step 2 still says it starts in a later phase"
printf '%s\n' "$S2" | grep -qF 'next.sh" own-work' || fail "vid-next's step 2 does not read the owner's switch, next.sh own-work"
printf '%s\n' "$S2" | grep -F 'own-work on "' | grep -qi 'off' || fail "vid-next's step 2 does not say in one line that own work is off, listing the move own-work on"
printf '%s\n' "$S2" | grep -F '`context ask' | grep -qi 'command' || fail "vid-next's step 2 does not say each context ask line with its command"
# FIX-BATCH-T2 (F-34): and each context unit-ask line, a piece's ask, with its words; vid-accept-step's row says it at each call with own work off
printf '%s\n' "$S2" | grep -F '`context unit-ask' | grep -qi 'its words' || fail "vid-next's step 2 does not say each context unit-ask line with its words"
grep -F '| `context unit-ask #<p>' "$K2" | grep -q 'With own work off.*at each call, with its words' || fail "vid-accept-step's context unit-ask row does not say the call's line with own work off"
a=$(printf '%s\n' "$S2" | grep -n '`vid-accept-step`' | head -n 1 | cut -d: -f1); b=$(printf '%s\n' "$S2" | grep -n '`vid-step-close`' | head -n 1 | cut -d: -f1); c=$(printf '%s\n' "$S2" | grep -n 'round.sh" asks' | head -n 1 | cut -d: -f1)
[ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ] || fail "vid-next's step 2 does not name vid-accept-step, vid-step-close and round.sh asks in that order"
L1=$(printf '%s\n' "$S2" | grep '`vid-accept-step`' | head -n 1); x=${L1%%round.sh\" step*}; y=${L1%%round.sh\" accept*}
[ "$x" != "$L1" ] && [ "$y" != "$L1" ] && [ "${#x}" -lt "${#y}" ] && printf '%s\n' "$L1" | grep -q '`decide' || fail "vid-next's vid-accept-step line does not run round.sh step, then round.sh accept for each decide line"
for f in '`decided #' '`accepted #' '`refused #<n>' '`context closed #<n>' '`unit-merged' '`asked <n> close' '`closed <step>`' '`ticket-closed' '`out <step>' 'GM M8' 'vid: decide'; do ! grep -qF -- "$f" "$N" || fail "vid-next holds a line of its skills: $f"; done
for f in '`accepted #<n> <c12>`' '`context closed #<n> <words>`' '`context unit-ask #<p>' '`context ask #<n> <c12>'; do grep -qF -- "$f" "$K2" || fail "vid-accept-step does not say the line $f"; done
for f in '`ticket-closed #<n>`' '`out <step> #<' '`refused <step>: '; do grep -qF -- "$f" "$K3" || fail "vid-step-close does not say the line $f"; done
# step 6 (F16, K11): the engines and own-work moves vid-accept-step's, one line each, their forms there alone
for m in engines own-work; do [ "$(grep -c "^   - \`$m " "$N")" = 1 ] || fail "vid-next does not name the $m move in one line"
  grep "^   - \`$m " "$N" | grep -q '`vid-accept-step`' || fail "vid-next's $m move does not name the vid-accept-step skill"; done
for f in 'engines "<primary> <other>…" "<words>"' 'own-work on|off "<words>"'; do ! grep -qF -- "$f" "$N" || fail "vid-next still holds the move's form $f"
  grep -qF -- "$f" "$K2" || fail "vid-accept-step does not hold the move's form $f"; done
grep -qF 'results.sh declare' "$K2" || fail 'vid-accept-step does not name the engines move through results.sh declare'
grep 'no engines line in .vid/tw/handed' "$CHECKS/writer.sh" > "$T0" && grep -qF 'the engines move' "$T0" && grep -qF 'results.sh declare' "$T0" || fail "the writer's refusal of a publish with no engines line does not name the engines move and the command that declares them"
# F13: what stays readable after the switch, said by vid-mode
grep -F '`step-`' "$M" | grep -qF 'unit-merges' || fail 'vid-mode does not say the step- records and unit-merges stay readable in both modes'
# GM-4 K11's stage calls (4d): step 2's skills in order, one line each, before round.sh asks
K4=$S/vid-stage-close/SKILL.md; [ -f "$K4" ] || fail 'there is no vid-stage-close skill'
o=''; for k in '`vid-accept-step`' '`vid-step-close`' '`vid-stage-close`' '`vid-deploy`' '`vid-grade`' 'round.sh" asks'; do
  [ "$(printf '%s\n' "$S2" | grep -cF -- "$k")" = 1 ] || fail "vid-next's step 2 does not name $k in one line"; o="$o $(printf '%s\n' "$S2" | grep -nF -- "$k" | cut -d: -f1)"; done
[ "$(printf '%s\n' $o | sort -n | paste -sd' ' -)" = "$(printf '%s\n' $o | paste -sd' ' -)" ] || fail "vid-next's step 2 does not name vid-accept-step, vid-step-close, vid-stage-close, vid-deploy, vid-grade and round.sh asks in that order"
printf '%s\n' "$S2" | grep -F 'round.sh" asks' | grep -q 'okays' && printf '%s\n' "$S2" | grep -F 'round.sh" asks' | grep -q 'stage' || fail "vid-next's round.sh asks line does not post the okays and the stage close"
# step 6: the three moves vid-stage-close's, one line each, their forms and done lines there alone
for m in walk-stage read-walk write-summary; do [ "$(grep -c "^   - \`$m " "$N")" = 1 ] || fail "vid-next does not name the $m move in one line"
  grep "^   - \`$m " "$N" | grep -q '`vid-stage-close`' || fail "vid-next's $m move does not name the vid-stage-close skill"
  f="$m <N> \"<words>\""; ! grep -qF -- "$f" "$N" || fail "vid-next still holds the move's form $f"; grep -qF -- "$f" "$K4" || fail "vid-stage-close does not hold the move's form $f"
  grep -qF -- "\`done $m <N>" "$K4" || fail "vid-stage-close does not say the line done $m"; done
for f in '`walk-started' '`done write-summary' '`stage-closed' 'later-work-off' '`grade-ask' 'summary.md' 'facts.txt' 'walk.sh' 'end.sh' 'close.sh okay'; do ! grep -qF -- "$f" "$N" || fail "vid-next holds a line of its skills: $f"; done
# review fix (4d, S0): a process calls a skill by invoking it; step 2 invokes each skill on its line, step 6 each move's skill
for k in vid-accept-step vid-step-close vid-stage-close vid-deploy vid-grade; do printf '%s\n' "$S2" | grep -F "\`$k\`" | grep -qF "Invoke the \`$k\` skill" || fail "vid-next's step 2 names $k without invoking it"; done
awk '/^6\. \*\*/ { on = 1 } on && /^7\. \*\*/ { exit } on' "$N" | grep -qF "Invoke each named move's skill" || fail "vid-next's step 6 does not invoke each named move's skill"
echo 'next-skill-text: ok'
