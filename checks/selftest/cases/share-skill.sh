#!/bin/sh
# Purpose: selftest case — the share verb's words and order (0.26.10.28.7, R1, R5, R6), read from skills/vid-share/SKILL.md, the help
# card and the README. The skill shows every item before its one question (where, size and parts; redaction counts by kind; left
# out and missing; the conversations carrying CLAUDE.md, memory files and tool output, and that they may be left out; that a
# pattern catches only what it knows), then asks its three answers in order, send, file, stop, and names the leave-out's rebuild.
# The read-only line comes where the repository's owner is chosen. It asks who to invite, offers none, names no default account,
# and shows the write-access words, the people-only fact and the organisation's Read for a person or a team before the second
# yes, which comes before share-invite; it asks the Read role in an organisation; it says how to invite later. The help card
# lists /vid:vid-share between view and help, and the README lists it. Needs skills/ (ViD's layout). Env: CHECKS.
set -eu
R=$CHECKS/..; [ -d "$R/skills/vid-help" ] && [ -f "$R/README.md" ] || { echo 'needs skills/ and README.md'; exit 77; }
fail() { echo "share-skill: $*" >&2; exit 1; }
S=$R/skills/vid-share/SKILL.md; [ -f "$S" ] || fail 'skills/vid-share/SKILL.md is missing'
grep -q '^name: vid-share$' "$S" || fail 'the skill is not named vid-share'
at() { grep -nF -- "$1" "$S" | head -n 1 | cut -d: -f1; }
need() { n=$(at "$1"); [ -n "$n" ] || fail "the skill does not say: $1"; echo "$n"; }
# R5: every item, then the one question with its three answers in order
W=$(need 'where the bundle is, its size, and its parts with their file counts'); K=$(need 'the redaction counts by kind')
L=$(need 'what was left out, and why, and what is missing'); C=$(need 'the conversations carry your own CLAUDE.md, your memory files, and anything a tool printed')
O=$(need 'you may leave the conversations out'); P=$(need 'a pattern catches only what it knows')
Q=$(need 'one question, with three answers'); A1=$(need '1. **send**'); A2=$(need '2. **file**'); A3=$(need '3. **stop**')
for n in $W $K $L $C $O $P; do [ "$n" -lt "$Q" ] || fail 'an item is shown after the question'; done
[ "$Q" -lt "$A1" ] && [ "$A1" -lt "$A2" ] && [ "$A2" -lt "$A3" ] || fail 'the three answers are not send, file, stop in order'
need 'Nothing is sent without "send"' > /dev/null; need 'rebuild with `--leave-out conversations` or `--leave-out logs` and show' > /dev/null
# R6: the account, then who to invite, then the words, then the second yes, then the invitation
RO=$(need 'read-only access for a person you invite needs an organisation'"'"'s repository'); CR=$(need 'share-create --repo')
[ "$RO" -lt "$CR" ] || fail 'the read-only line is not said where the account is chosen, before the repository is made'
WHO=$(need 'Ask which GitHub account to invite, or **none**'); need 'There is no default: never suggest an' > /dev/null
WW=$(need 'On a repository in a personal account, GitHub gives every invited person write access, not read only')
need 'A personal account'"'"'s repository can invite only people, not an organisation' > /dev/null
need 'give the Read role to a person, or to one of that organisation'"'"'s own teams' > /dev/null
Y2=$(need 'a second, separate yes'); IN=$(need 'share-invite --repo')
[ "$WHO" -lt "$WW" ] && [ "$WW" -lt "$Y2" ] && [ "$Y2" -lt "$IN" ] || fail 'who, the write-access words, the second yes and the invitation are not in that order'
grep -qF -- '--who <login> --shown-write-words --second-yes' "$S" || fail 'the invitation does not pass its two flags'
need 'invited with the Read role' > /dev/null; need 'how to invite someone later' > /dev/null; need 'Collaborators (or Collaborators and teams), then Add people' > /dev/null
# no account named: --who and --repo only ever with placeholders
! grep -oE -- '--(who|repo) [^ <`]+' "$S" | grep -q . || fail "the skill names an account: $(grep -oE -- '--(who|repo) [^ <`]+' "$S" | head -n 1)"
# R1: the help card's row between view and help, and the README's
H=$R/skills/vid-help/SKILL.md; v=$(grep -n 'vid-view' "$H" | head -n 1 | cut -d: -f1); s=$(grep -n '/vid:vid-share' "$H" | head -n 1 | cut -d: -f1); h=$(grep -nE 'vid-help(\*\*|`\)) \| This card' "$H" | cut -d: -f1)
[ -n "$s" ] && [ -n "$v" ] && [ -n "$h" ] && [ "$v" -lt "$s" ] && [ "$s" -lt "$h" ] || fail 'the help card does not list /vid:vid-share between view and help'
grep -qF '(`/vid:vid-share`)' "$R/README.md" || fail 'the README does not list /vid:vid-share'
echo 'share-skill: ok'
