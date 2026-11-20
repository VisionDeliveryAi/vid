#!/bin/sh
# Purpose: selftest case — the /vid next and /vid mode skills hold only order (GM-1 S9, S5, S6; its case next-skill-text). vid-next
# names its steps in order and invokes vid-connect, vid-read and vid-triggers by name; vid-connect holds Slack's check (the
# connector's tools, each channel's read, `none`, never a stop) and the refresh first; vid-read holds Slack's reading rules (the
# marks, the match, the link and one-line reading alone, never posting, never deciding); no tier word, warning or count rule is in
# vid-next's or vid-mode's text. GM-2 T10: vid-next runs the moves the owner names through next-move.sh call, names phase 2's
# moves (publish, amend, withdraw, team-change, answer, done, decline, engines) by kind and subject, and ends the call
# (vid-connect's end) after them; vid-tickets holds the GitHub manual layout behind its mode check (the issue form, the
# owner's words), in manual.md beside its SKILL.md, which sends GitHub manual there (tw-lane holds SKILL.md to 120
# lines). Reads skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-run" ] || { echo 'next-skill-text: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "next-skill-text: $*" >&2; exit 1; }
[ -f "$S/vid-next/SKILL.md" ] && [ -f "$S/vid-connect/SKILL.md" ] && [ -f "$S/vid-read/SKILL.md" ] && [ -f "$S/vid-mode/SKILL.md" ] || fail "a skill of /vid next or /vid mode is missing"
N=$S/vid-next/SKILL.md; C=$S/vid-connect/SKILL.md; R=$S/vid-read/SKILL.md; M=$S/vid-mode/SKILL.md
awk '/^[0-9]\. \*\*/ { print $1 }' "$N" | paste -sd' ' - | grep -qx '0. 1. 2. 3. 4. 5. 6. 7.' || fail 'vid-next does not name its steps 0 to 7 in order'
for k in 'next.sh" mode' vid-connect vid-read vid-triggers; do grep -q "$k" "$N" || fail "vid-next does not call $k"; done
a=$(grep -n 'Invoke the `vid-connect`' "$N" | cut -d: -f1); b=$(grep -n 'Invoke the `vid-read`' "$N" | cut -d: -f1); c=$(grep -n 'Invoke the `vid-triggers`' "$N" | cut -d: -f1)
[ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ] || fail 'vid-next does not invoke vid-connect, vid-read and vid-triggers in that order'
grep -q 'connect.sh" start' "$C" && grep -q 'refresh of `checks/` first, before anything is restored or locked' "$C" || fail 'vid-connect does not run the refresh first'
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
grep -q 'In GitHub manual, read `manual.md`' "$S/vid-tickets/SKILL.md" || fail 'vid-tickets does not send GitHub manual to its manual layout'
TW=$S/vid-tickets/manual.md; [ -f "$TW" ] && grep -q '^# TW in GitHub manual' "$TW" && grep -q 'next.sh"\{0,1\} mode' "$TW" && grep -q 'issue-form:' "$TW" && grep -q "owner's words" "$TW" || fail 'vid-tickets lacks the GitHub manual layout behind its mode check'
for f in "$N" "$M"; do grep -niE 'critical|important|minor|tier [0-9]|warn(ing)? (when|if)|more than [0-9]|[0-9]+ days|open-ticket limit|counted once|first kind|re-plan rule|top-up' "$f" > /dev/null && { grep -niE "critical|important|minor" "$f" >&2; fail "$(basename "$(dirname "$f")") holds a tier, warning, count or re-plan rule"; } || :; done
echo 'next-skill-text: ok'
