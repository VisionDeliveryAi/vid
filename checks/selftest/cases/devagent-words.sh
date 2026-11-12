#!/bin/sh
# Purpose: selftest case — two texts a GitHub auto user reads (0.26.10.28.8, R8, R11). vid-deploy's SKILL.md refuses in a ticket-mode project,
# as a bold paragraph above "**Stage events**", naming `mode: tickets`, the staging okay and the production okay and /vid:vid-run, and its first
# `##` heading is unchanged; the README's prerequisites name, for GitHub auto, the claude command signed in, and, for a product with screens in
# the GitHub modes, a browser already on the machine for ViD's walk, which ViD never installs. Needs skills/ and README.md. Env: CHECKS.
set -eu
R=$CHECKS/..; [ -f "$R/skills/vid-deploy/SKILL.md" ] && [ -f "$R/README.md" ] || { echo 'needs skills/ and README.md'; exit 77; }
fail() { echo "devagent-words: $*" >&2; exit 1; }
D=$R/skills/vid-deploy/SKILL.md
r=$(grep -n '^\*\*In the GitHub modes, this verb refuses' "$D" | head -n 1 | cut -d: -f1); e=$(grep -n '^\*\*Stage events' "$D" | head -n 1 | cut -d: -f1)
[ -n "$r" ] && [ -n "$e" ] && [ "$r" -lt "$e" ] || fail 'the refusal is not a bold paragraph above **Stage events**'
l=$(sed -n "${r}p" "$D"); for w in '`mode: tickets`' 'refuse' 'staging okay' 'production okay' '/vid:vid-run' 'In local auto'; do printf '%s\n' "$l" | grep -qF "$w" || fail "the refusal does not say $w"; done
[ "$(grep -n '^## ' "$D" | head -n 1 | cut -d: -f2-)" = '## The claim first — "development complete" is computed (v0.9.3 3.14, R19)' ] || fail "vid-deploy's first ## heading changed"
P=$(sed -n '/^### Prerequisites/,/^### /p' "$R/README.md" | tr '\n' ' ' | tr -s ' ')
printf '%s\n' "$P" | grep -qF 'For GitHub auto: the `claude` command, signed in' || fail 'the prerequisites do not name the signed-in claude command for GitHub auto'
printf '%s\n' "$P" | grep -qF 'a browser already on the machine ViD runs on, for ViD'"'"'s walk' && printf '%s\n' "$P" | grep -qF 'ViD never installs one' || fail "the prerequisites do not name the walk's browser"
echo 'devagent-words: ok'
