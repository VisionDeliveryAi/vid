#!/bin/sh
# Purpose: selftest case — the design question (v0.9.5 spec 3.14, R13; §7
# case 21). A text check, like passes.sh, gated on ViD's own skills beside
# checks/ (a project keeps no copy of them, so there it proves nothing).
# Convicts unless vid-design runs the render-and-see gate before it asks,
# asks the question word for word, takes (a) with no question when the gate
# fails, records the answer in the DECISIONS form, no longer calls the
# alternates "never offered", and vid-init's hint names the question.
# Env: CHECKS.
set -eu
D="$CHECKS/../skills/vid-design/SKILL.md"; I="$CHECKS/../skills/vid-init/SKILL.md"
[ -f "$D" ] && [ -f "$I" ] || exit 0
fail() { echo "design-question: $*" >&2; exit 1; }
J=$(tr '\n' ' ' < "$D" | tr -s ' ')
printf '%s\n' "$J" | grep -qF 'run the render-and-see gate **first**' || fail 'the gate does not come first'
G=$(printf '%s\n' "$J" | awk '{ print index($0, "render-and-see gate **first**") }'); Q=$(printf '%s\n' "$J" | awk '{ print index($0, "**Who makes the design?**") }')
[ "$G" -gt 0 ] && [ "$Q" -gt "$G" ] || fail 'the question is not after the gate'
printf '%s\n' "$J" | grep -qF '> **Who makes the design?** (a) You design it in your own tool from this > brief. Recommended: it has worked in practice. (b) ViD drafts it here. > Quicker to start, but you may reject it on taste.' || fail 'the question is not word for word'
printf '%s\n' "$J" | grep -qF '**The gate fails.** Ask nothing.' || fail 'a failed gate still asks'
printf '%s\n' "$J" | grep -qF 'and take (a).' || fail 'a failed gate does not take (a)'
printf '%s\n' "$J" | grep -qF 'design made <from the brief in the owner'"'"'s tool | here in the session> | why: the owner'"'"'s answer at the design question | enforced: convention' || fail 'the DECISIONS record'
printf '%s\n' "$J" | grep -qF 'never offered as the default' && fail 'the alternates are still "never offered as the default"'
printf '%s\n' "$J" | grep -qF '## 2. The owner authors — the recommended path' || fail "§2's heading"
tr '\n' ' ' < "$I" | tr -s ' ' | grep -qF '/vid design asks whether you design from its brief in your own tool or ViD drafts it here; it only offers the second when it can see its own drawings.' || fail "init's hint question"
exit 0
