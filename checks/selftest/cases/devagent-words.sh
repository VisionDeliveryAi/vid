#!/bin/sh
# Purpose: selftest case — two texts a GitHub auto user reads (0.26.10.28.8, R8, R11). vid-deploy's SKILL.md, in a ticket-mode project
# (GM-4 K5: the verb refuses in no GitHub mode), sends the reader to its GitHub section in a bold paragraph above "**Stage events**", naming
# `mode: tickets`, the staging okay and the production okay, `/vid:vid-deploy staging` and `/vid:vid-deploy production`, and local auto, and
# refusing nothing; its first `##` heading is unchanged; the README's prerequisites name, for GitHub auto, both ways DevAgent's agents run (0.26.11.1.3, R5): in its own
# conversation, which stays open, or through the claude command, signed in; and, for a product with screens in the GitHub modes, a browser
# already on the machine for ViD's walk, which ViD never installs. The README, devagent/README.md and vid-devagent each name both ways, by
# the job note's `agents: conversation` and `agents: command`, and the README's vid-devagent entry says what closing the conversation does in
# each. Needs skills/, README.md and devagent/. Env: CHECKS.
set -eu
R=$CHECKS/..; [ -f "$R/skills/vid-deploy/SKILL.md" ] && [ -f "$R/README.md" ] && [ -f "$R/devagent/README.md" ] || { echo 'needs skills/, README.md and devagent/'; exit 77; }
fail() { echo "devagent-words: $*" >&2; exit 1; }
D=$R/skills/vid-deploy/SKILL.md
r=$(grep -n '^\*\*In the GitHub modes' "$D" | head -n 1 | cut -d: -f1); e=$(grep -n '^\*\*Stage events' "$D" | head -n 1 | cut -d: -f1)
[ -n "$r" ] && [ -n "$e" ] && [ "$r" -lt "$e" ] || fail 'the GitHub modes paragraph is not a bold paragraph above **Stage events**'
l=$(sed -n "${r}p" "$D"); for w in '`mode: tickets`' 'staging okay' 'production okay' '/vid:vid-deploy staging' '/vid:vid-deploy production' 'In local auto'; do printf '%s\n' "$l" | grep -qF "$w" || fail "the GitHub modes paragraph does not say $w"; done
! printf '%s\n' "$l" | grep -qi 'refuse' || fail 'vid-deploy still refuses in the GitHub modes (GM-4 K5)'
[ "$(grep -n '^## ' "$D" | head -n 1 | cut -d: -f2-)" = '## The claim first — "development complete" is computed (v0.9.3 3.14, R19)' ] || fail "vid-deploy's first ## heading changed"
P=$(sed -n '/^### Prerequisites/,/^### /p' "$R/README.md" | tr '\n' ' ' | tr -s ' ')
printf '%s\n' "$P" | grep -qF 'For GitHub auto: DevAgent'"'"'s agents run in its own Claude Code conversation' && printf '%s\n' "$P" | grep -qF 'or through the `claude` command, signed in' || fail 'the prerequisites do not name both ways DevAgent'"'"'s agents run for GitHub auto'
for f in README.md devagent/README.md skills/vid-devagent/SKILL.md; do for w in '`agents: conversation`' '`agents: command`'; do grep -qF "$w" "$R/$f" || fail "$f does not name $w"; done; done
E=$(sed -n '/^- \*\*vid-devagent\*\*/,/^- \*\*vid-help/p' "$R/README.md" | tr '\n' ' ' | tr -s ' ')
printf '%s\n' "$E" | grep -qF 'With `agents: command`, closing the conversation leaves DevAgent running' && printf '%s\n' "$E" | grep -qF 'with `agents: conversation`, closing it stops DevAgent until the conversation is opened again' || fail "the README's vid-devagent entry does not say what closing the conversation does in each way"
printf '%s\n' "$P" | grep -qF 'a browser already on the machine ViD runs on, for ViD'"'"'s walk' && printf '%s\n' "$P" | grep -qF 'ViD never installs one' || fail "the prerequisites do not name the walk's browser"
echo 'devagent-words: ok'
