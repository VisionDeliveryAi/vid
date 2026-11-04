#!/bin/sh
# Purpose: selftest case — the /vid add refresh (v0.26.10.11 R1–R9) and the add guards (v0.26.10.24 R1, R2), in the plugin
# repository: vid-add, vid-develop's completion grade and vid-replan's new-work row say what the spec says. Every failing check is named, then the case
# fails. In a project ViD's skills are not beside checks/ and the case proves nothing. Env: CHECKS.
set -eu
A="$CHECKS/../skills/vid-add/SKILL.md"
[ -f "$A" ] || exit 0
BAD=''
no() { BAD="$BAD
add-text: $*"; }
F=$(tr '\n' ' ' < "$A" | tr -s ' ')
has() { printf '%s' "$F" | grep -qF -- "$1"; }
# bullet <file> <start>: the list item whose first line starts with <start>, joined on one line
bullet() { awk -v p="$2" 'on && (/^- / || /^#/) { exit } on { print } !on && index($0, p) == 1 { on = 1; print }' "$1" | tr '\n' ' ' | tr -s ' '; }
# R3: the placement is the commit right after the append commit, before the whole-set review
PL=$(grep -n "^- \*\*A new feature's stage" "$A" | head -n 1 | cut -d: -f1)
WR=$(grep -n 'passes/whole-set-review.md' "$A" | head -n 1 | cut -d: -f1)
if [ -z "$PL" ] || [ -z "$WR" ] || [ "$PL" -ge "$WR" ]; then no "the placement paragraph does not come before the whole-set review"; fi
bullet "$A" "- **A new feature's stage" | grep -qF 'right after the append commit' || no 'the placement paragraph does not say "right after the append commit"'
# R1: after the final close, pilot work opens a new final stage; no pilot item, nothing to build
P=$(bullet "$A" "- **A new feature's stage")
for _t in '`stage-closed n=<k>`' '`STAGE-<k+1> | <name> | features: <the add'"'"'s new pilot features>`' 'split: <REQ…> -> STAGE-<k+1>' '`features: -`' 'An add that brings no pilot item places nothing and builds nothing' 'there is nothing to build'; do
  printf '%s' "$P" | grep -qF -- "$_t" || no "the placement paragraph does not name $_t"
done
# R2: the add writes RUN-STATE's stage: after opening a stage
printf '%s' "$P" | grep -qF 'right after the placement commit that opens STAGE-<k+1>, write RUN-STATE'"'"'s `stage:` line as `stage: <k+1>`' || no "the add does not write RUN-STATE's stage: after opening a stage"
# R4: develop as it is, said plainly; the add's rows join the plan as a scope change
has 'restricted to the delta' && no 'vid-add still says "restricted to the delta"'
has 'sh checks/plan.sh change add "<why>" --trigger scope-change --evidence commit:<the append commit>' || no 'vid-add does not name plan.sh change add with --trigger scope-change'
# R5: one grade — develop's completion grade, scoped to the adds since the last completion; vid-add runs no grade
has 'Run /vid grade' && no 'vid-add still runs /vid grade'
D="$CHECKS/../skills/vid-develop/SKILL.md"
G=$(awk '/^## Done/ { on = 1 } on && /^## Completion report/ { exit } on' "$D" | tr '\n' ' ' | tr -s ' ')
for _t in '`stage name=add state=start`' '`completion unmet=0 strict-gaps=0`' '`base=`' 'declared dependents'; do
  printf '%s' "$G" | grep -qF -- "$_t" || no "develop's completion grade does not name $_t"
done
# R6: the add's stamp carries records=30 and base=
has 'stage name=add state=start session=$CLAUDE_CODE_SESSION_ID records=30 base=$(git rev-parse --short=12 HEAD)' || no "vid-add's start event does not carry records=30 and base="
# R7: a hold, on or asked for — the yes ends it as "continue" does; the no hands back naming the feature's stage
for _t in '`sh checks/stages.sh hold --off`' '`stage-hold n=N state=on`' 'state=asked' "say 'continue' to build it with stage <its stage>" "sh checks/event.sh 'stage-hold n=N state=off'"; do
  printf '%s' "$P" | grep -qF -- "$_t" || no "the placement paragraph does not name $_t"
done
# R8: ticket mode — spec, placement and inventory delta, then /vid replan; replan's new-work: row names /vid add
has '`mode: tickets`, run §1, §2 (the placement included) and §2b' || no 'vid-add does not say what it runs under mode: tickets'
has "say '/vid replan' to put it in the plan as tickets" || no 'vid-add under mode: tickets does not hand back naming /vid replan'
grep -E '^\| `new-work:`' "$CHECKS/../skills/vid-replan/SKILL.md" | grep -qF '/vid add' || no "vid-replan's new-work: row does not name /vid add"
# R9, moved to develop (v0.26.10.24 R2): without the standing authorization nothing deploys; the last line names "deploy to staging"
printf '%s' "$G" | grep -qF "the completion report's last line is \"rule on the findings table, then say 'deploy to staging'\"" || no "develop's scoped grade does not end the report with rule on the findings table, then say 'deploy to staging'"
# v0.26.10.24 R1: the ticket-mode paragraph is the base's, byte for byte
[ "$(awk '/^\*\*Ticket mode/ { on = 1 } on && !NF { exit } on' "$A" | cksum)" = '3224359588 528' ] || no 'the ticket-mode paragraph is not the base'"'"'s, byte for byte'
# (a) the start's floor and the takeover
has 'read `checks/records-version` first: absent or below 32' || no "vid-add's start does not stop below records 32"
has 'whenever a session takes the add over, record it again with its first `base=`' || no "vid-add does not record the add's start again at a takeover"
# (b) one review, in both modes, repairs in the same append
RV=$(bullet "$A" '- After the append commit (and its placement')
for _t in 'in the same append' 'not reviewed again' 'once per add'; do printf '%s' "$RV" | grep -qF -- "$_t" || no "the review bullet does not say $_t"; done
printf '%s' "$RV" | grep -qiE 'ticket|outside' && no 'the review bullet carries a mode exception'
has 'a further dated append' && no 'vid-add still says "a further dated append"'
# (c) §3 hands over: the skill invoked, its "Before any work", the add's end; (d) §4 is "Throughout the add"
S3=$(awk '/^## 3\./ { on = 1; next } /^## 4\./ { on = 0 } on' "$A" | tr '\n' ' ' | tr -s ' ')
S4=$(awk '/^## 4\./ { on = 1 } /^## 5\./ { on = 0 } on' "$A" | tr '\n' ' ' | tr -s ' ')
for _t in 'invoke the vid-develop skill (the Skill tool)' '"Before any work"' 'stage name=add state=end' 'develop starts through its "continue" path'; do printf '%s' "$S3" | grep -qF -- "$_t" || no "§3 does not name $_t"; done
for _t in '## 4. Throughout the add' 'inventory.sh impact' '.vid/VID-FINDINGS.md'; do printf '%s' "$S4" | grep -qF -- "$_t" || no "§4 does not name $_t"; done
has 'One grade' && no 'vid-add still has "One grade"'
has 'Run the /vid develop loop' && no 'vid-add still says "Run the /vid develop loop"'
# (e) a kept hold's "continue" invokes develop
S5=$(awk '/^## 5\./ { on = 1 } on' "$A" | tr '\n' ' ' | tr -s ' ')
for _t in 'invoke the vid-develop skill (the Skill tool)' '"Before any work"'; do printf '%s' "$S5" | grep -qF -- "$_t" || no "the kept hold's hand-back does not name $_t"; done
[ -z "$BAD" ] || { printf '%s\n' "$BAD" | sed '/^$/d' >&2; exit 1; }
exit 0
