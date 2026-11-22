#!/bin/sh
# Purpose: the dev side's start, printed for the owner in GitHub auto (v0.26.10.28.8, R4, R10). Run in the project, from the plugin's own
# checks/ (`sh "${CLAUDE_PLUGIN_ROOT}/checks/devagent-start.sh"`), so the paths it prints are the plugin's real folder.
#   devagent-start.sh        in GitHub auto (the owner's newest `setup-answered key=github-mode` line of .vid/plan/setup says auto), in order
#                            (0.26.10.28.8, R12): the line that makes the work folder; the job note, filled in, to save as it is; the first
#                            way, /vid:vid-devagent '<note>' in a new Claude Code conversation in the work folder, and what closing it does
#                            with each agents: (0.26.11.1.3, R5), a line the note leaves to that conversation's one question; then the background
#                            line, dm.sh up, for agents: command; and the lines for check, list, used and down. In GitHub manual (GM-1 S1),
#                            an old team answer (FB-1 C1: retired), or with no answer recorded, it prints nothing. Exit 0
#   devagent-start.sh mode   auto, manual, team (FB-1 C1: an old, retired answer) or none: the owner's recorded answer (a `github-mode:` line written by hand is no answer)
# It writes nothing, makes no folder and starts nothing. repo: and labels-prefix: are read where ViD reads them (ARCHITECTURE.md's vid-code
# block, then .vid/tw/settings). model: is devagent/dev-manager/dm.sh's MODEL0, read from that file. The work folder and the note go beside
# the project, in the folder that holds it, or in $HOME when that folder lies in ViD's records. Paths are single-quoted, so a space holds.
# serves: tickets
set -eu
HERE=$(cd "$(dirname "$0")" && pwd -P); . "$HERE/lib.sh"; ROOT=$(dirname "$HERE")
die() { echo "devagent-start: $*" >&2; exit 1; }
mode() { ghmode; }   # GM-1 S1: lib.sh's reading, manual among them
case ${1:-} in mode) mode; exit 0 ;; '') ;; *) die "usage: devagent-start.sh [mode]" ;; esac
[ "$(mode)" = auto ] || exit 0
# sq <text>: single-quoted for a shell, a ' inside written '\''
sq() { printf "'%s'" "$(printf %s "$1" | sed "s/'/'\\\\''/g")"; }
# invid <folder>: the nearest folder at or above it that holds .vid, as dm.sh reads it; nothing when none
invid() { d=$1; while :; do [ ! -e "$d/.vid" ] || { echo "$d"; return 0; }; [ "$d" != / ] || return 0; d=$(dirname "$d"); done; }
codekey() { [ -f ARCHITECTURE.md ] && sed -n '/^```vid-code[[:space:]]*$/,/^```[[:space:]]*$/p' ARCHITECTURE.md | sed -n "s/^$1:[[:space:]]*//p" | head -n 1 | sed 's/[[:space:]]*$//'; }
DM=$ROOT/devagent/dev-manager/dm.sh
[ -f "$DM" ] || die "no $DM: run this script from the plugin's own checks/"
MODEL=$(sed -n 's/^MODEL0=\([^ ]*\).*/\1/p' "$DM" | head -n 1); [ -n "$MODEL" ] || die "$DM names no MODEL0"
REPO=$(codekey repo || true); PFX=$(codekey labels-prefix || true); [ -n "$REPO" ] || { REPO=$(skey repo); PFX=$(skey labels-prefix); }
P=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P); P=$(cd "$P" && pwd -P); NAME=$(basename "$P")
# the work folder itself is checked, as dm.sh checks it (one already there may hold .vid), not only the folder it goes in; a project
# whose folder is at / (/app, say) puts both in $HOME, since / is no folder a user can write in
B=$(dirname "$P"); [ "$B" != / ] && [ -z "$(invid "$B/$NAME-devagent")" ] || B=${HOME:-}
[ -n "$B" ] && [ -d "$B" ] && [ "$(cd "$B" && pwd -P)" != / ] && [ -z "$(invid "$(cd "$B" && pwd -P)/$NAME-devagent")" ] || die "no folder outside ViD's records to put the work folder in: write the job note by hand, its work: outside any folder that holds .vid"
B=$(cd "$B" && pwd -P)
WK=$B/$NAME-devagent; NT=$B/$NAME-devagent-note.txt
TL=86400; AT=10800; AU=500   # the loop's seconds (a day), one agent's seconds (three hours, above the floor of 7200), one agent's turns
cat <<EOF
DevAgent, ViD's own dev side, works this project's tickets (you answered GitHub auto). You start it, on this machine; ViD starts nothing and does not wait for it.

1. Make DevAgent's work folder:

mkdir -p $(sq "$WK")

2. Save this job note, exactly as it is, to $NT (a folder that already exists, outside this project and the work folder):

\`\`\`
repo: $REPO
labels-prefix:${PFX:+ $PFX}
work: $WK
time-limit: $TL
agent-time-limit: $AT
agent-turn-limit: $AU
model: $MODEL
\`\`\`

EOF
if [ -n "$REPO" ]; then echo "- repo: and labels-prefix: are this project's, as ViD reads them."; else echo "- repo: is empty: the code repository is not recorded yet. Write it after repo:, as owner/name, before you start."; fi
cat <<EOF
- work: is the dev side's work folder, outside this project and outside ViD's records. Step 1 makes it.
- time-limit: $TL is a default you may change: the loop's seconds, one day. At it the loop stops and says so; up again picks up where it stopped.
- agent-time-limit: $AT is a default you may change: one agent's seconds, three hours. Keep it generous: an agent stopped twice at its limit leaves its ticket until the owner reopens it, so a low limit costs a ticket's wait, not a restart.
- agent-turn-limit: $AU is a default you may change: one agent's turns, in the same spirit.
- model: must be written in exactly this form, the full name an agent's first message shows. Every agent runs on it.
- agents: is left out: /vid:vid-devagent asks once whether DevAgent's agents run in that conversation (agents: conversation, no sign-in needed, the conversation kept open) or through the claude command (agents: command, signed in, running on its own), and writes your answer in the note. Without that line, dm.sh reads the note as agents: command.

3. Start it in a Claude Code conversation of its own, the first way: open a new Claude Code conversation in the work folder (cd $(sq "$WK") && claude) and type

/vid:vid-devagent $(sq "$NT")

It starts DevAgent and shows each pass as it ends; say stop there to stop it. With agents: command, closing that conversation ends only the view: DevAgent runs on. With agents: conversation, that conversation is DevAgent: closing it stops DevAgent until the conversation is opened again, in the work folder, with the same line.

Or, with agents: command, for a run with no conversation to watch it, start it in the background instead: paste this one line into a terminal.

sh $(sq "$DM") up $(sq "$NT")

The other commands:
- What it needs, starting nothing: sh $(sq "$DM") check $(sq "$NT")
- What is alive, in its work folder: cd $(sq "$WK") && sh $(sq "$DM") list
- The time and turns used so far: cd $(sq "$WK") && sh $(sq "$DM") used
- Stop it: sh $(sq "$DM") down $(sq "$NT")
EOF
