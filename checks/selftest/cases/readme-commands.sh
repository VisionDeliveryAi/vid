#!/bin/sh
# Purpose: selftest case — the README and the help card name real commands and the three modes (0.26.10.28.5, R1). Neither tells the user to "say
# `vid …`", and neither names a bare `/vid <verb>`: every command is `/vid:vid-<verb>`, and each one so named is a skill the plugin ships, so no
# command can be named that does not exist. The help card names local auto, GitHub auto and GitHub team, each with what it is for and the verb that
# starts it, GitHub auto's dev side's start too; the README names them once; devagent/README.md names no bare verb either. The install check no longer says init runs the self-test. 0.26.11.1.3 (R2): the PC paragraph has no WSL question, and says the check, the record and how to turn it off. Needs skills/ (ViD's layout). Env: CHECKS.
set -eu
R=$CHECKS/..; [ -d "$R/skills/vid-help" ] && [ -f "$R/README.md" ] || { echo 'needs skills/ and README.md'; exit 77; }
fail() { echo "readme-commands: $*" >&2; exit 1; }
H=$R/skills/vid-help/SKILL.md; M=$R/README.md
V='init|create-prd|test-inventory|design|stage|develop|plan|run|grade|fix|add|deploy|view|help'
for f in "$M" "$H" "$R/devagent/README.md"; do [ -f "$f" ] || continue; b=${f#"$R"/}
  ! grep -nE '[Ss]ay `vid [a-z]|`vid ('"$V"')`' "$f" > /dev/null || fail "$b tells the user to say a vid verb: $(grep -nE '[Ss]ay `vid [a-z]|`vid ('"$V"')`' "$f" | head -n 1)"
  ! grep -nE '(^|[^:a-z-])/vid ('"$V"')([^a-z-]|$)' "$f" > /dev/null || fail "$b names a bare /vid <verb>: $(grep -nE '(^|[^:a-z-])/vid ('"$V"')([^a-z-]|$)' "$f" | head -n 1)"
  for c in $(grep -oE '/vid:vid-[a-z-]+' "$f" | sort -u); do v=${c#/vid:}; [ -f "$R/skills/$v/SKILL.md" ] || fail "$b names $c, which is no skill of the plugin"; done; done
# the three modes, each with what it is for and the verb that starts it
# 0.26.10.28.8 (R1, R2): GitHub auto's start is DevAgent's, the same in both, and neither names the old folder (its name built from two pieces, so this line cannot match itself)
S='sh <plugin>/devagent/dev-manager/dm.sh up <job note>'; O=stand; O=${O}in/
grep -i '\*\*GitHub auto\*\*' "$H" | grep -qF "$S" && grep -A 4 -i '\*\*GitHub auto\*\*' "$M" | grep -qF "$S" || fail "GitHub auto does not give its start as $S in both"
! grep -qF "$O" "$M" "$H" || fail "the README or the help card names $O"
# 0.26.10.28.8 (R12): the conversation of its own first, /vid:vid-devagent <job note>, then the background line; the help card's row
V2='/vid:vid-devagent <job note>'; fst() { awk -v a="$V2" -v b="$S" 'index($0, a) && !i { i = NR } index($0, b) && !j { j = NR } END { exit !(i && j && i <= j) }'; }
grep -i '\*\*GitHub auto\*\*' "$H" | fst || fail "the help card's GitHub auto line does not offer $V2 before the background line"
grep -A 6 -i '\*\*GitHub auto\*\*' "$M" | fst || fail "the README's GitHub auto does not offer $V2 before the background line"
grep -q '^| \*\*/vid:vid-devagent\*\* |' "$H" || fail 'the help card has no /vid:vid-devagent row'
W='a decision record or proposal the owner names: the map, the amendment, one yes'; grep -q '^| \*\*/vid:vid-incorporate\*\* | '"$W"' |' "$H" && grep -qF -- '(`/vid:vid-incorporate`): '"$W" "$M" || fail 'the help card or the README does not list /vid:vid-incorporate (IR I7)'
# before: in the text read as one line, the verb's first place ahead of the background line's first place
bef() { tr '\n' ' ' | awk '{ i = index($0, "/vid:vid-devagent"); j = index($0, "dm.sh up"); exit !(i && j && i < j) }'; }
D=$R/devagent/README.md; [ ! -f "$D" ] || { bef < "$D" || fail "devagent/README.md does not offer /vid:vid-devagent before dm.sh up"; }
J=$R/devagent/job-note.example; [ ! -f "$J" ] || { sed -n 1,4p "$J" | bef || fail "job-note.example's head does not offer /vid:vid-devagent before dm.sh up"; }
grep -A 4 -i '\*\*GitHub auto\*\*' "$M" | grep -qi 'nothing merges without' && grep -A 4 -i '\*\*GitHub auto\*\*' "$M" | grep -q 'DevAgent' || fail 'the README does not say what GitHub auto is for'
for m in 'local auto' 'GitHub auto' 'GitHub team'; do grep -qi "\*\*$m\*\*" "$H" || fail "the help card does not name $m"
  l=$(grep -i "\*\*$m\*\*" "$H" | head -n 1); printf '%s\n' "$l" | grep -qE '/vid:vid-(init|develop|plan|run)' || fail "the help card's $m line names no verb that starts it"
  [ "$(grep -ci "\*\*$m\*\*" "$M")" = 1 ] || fail "the README does not name $m once"; done
# the install check
! grep -q 'init reports its$\|init reports its own court self-test' "$M" || fail 'the install check still says init runs the self-test'
grep -q '/vid:vid-help' "$M" || fail 'the install check does not name /vid:vid-help'
# 0.26.11.1.3 (R2, lane B's hand-over): on a PC, no question; ViD checks once that WSL runs, keeps yes or no in .vid/windows, and says once how to turn it off
W=$(awk '/^- \*\*On a PC:\*\*/ { f = 1 } f && /^$|^### / { exit } f' "$M" | tr '\n' ' ' | tr -s ' ')
[ -n "$W" ] || fail 'the README has no On a PC paragraph'
! printf '%s\n' "$W" | grep -qiE 'asks you|your yes' || fail "the README's PC paragraph still has ViD ask about WSL"
for w in 'checks once that WSL runs' '`.vid/windows`' 'change `wsl: yes` to `wsl: no`' 'delete `.vid/windows`'; do printf '%s\n' "$W" | grep -qF "$w" || fail "the README's PC paragraph does not say: $w"; done
echo 'readme-commands: ok'
