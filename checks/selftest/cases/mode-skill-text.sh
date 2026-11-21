#!/bin/sh
# Purpose: selftest case — /vid mode both ways in its skill (GM-4 F13, the skill's half). vid-mode names `/vid:vid-mode auto|manual`
# and its description both directions; it runs `mode.sh auto` as well as `mode.sh manual`; each of the switch to auto's refusals,
# the `no-auto sub-issues`, `no-auto pending` and `no-auto to-place` lines, is said as mode.sh prints it, the mode left as it is;
# the ratification in GitHub auto needs the owner's own words (`--words`); the take-stock runs in both modes (`re-taken`); and the
# flags the switch to manual alone takes are not passed to auto. Reads skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-mode" ] || { echo 'mode-skill-text: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "mode-skill-text: $*" >&2; exit 1; }
M=$S/vid-mode/SKILL.md; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
tr '\n' ' ' < "$M" | tr -s ' ' > "$T/m"
grep -qF '/vid:vid-mode auto|manual' "$T/m" || fail 'vid-mode does not give /vid:vid-mode auto|manual'
grep '^description:' "$M" | grep -qF '/vid mode auto' || fail "vid-mode's description does not name the switch to auto"
grep -qF 'mode.sh" auto' "$T/m" && grep -qF 'mode.sh" manual' "$T/m" || fail 'vid-mode does not run mode.sh both ways'
for w in 'no-auto sub-issues' 'no-auto pending' 'no-auto to-place'; do grep -qF "\`$w" "$T/m" || fail "vid-mode does not say the $w refusal"; done
grep -qF 'as mode.sh prints it' "$T/m" || fail 'vid-mode does not say the refusals as mode.sh prints them'
grep -qF 'ratified again in GitHub auto' "$T/m" || fail 'vid-mode does not hold the ratification in auto'
grep -qF 'mode: GitHub auto, re-taken' "$T/m" && grep -qF 'mode: GitHub manual, re-taken' "$T/m" || fail 'vid-mode does not take stock in both modes'
grep -qF -- '--applied, --from, --take-over, --devagent and --to-place' "$T/m" || fail 'vid-mode does not keep the switch to manual'"'"'s flags off auto'
echo 'mode-skill-text: ok'
