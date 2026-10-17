#!/bin/sh
# Purpose: selftest case — init's labelling pass comes before the initial commit, with no commit of its own (v0.9.7.3
# spec 3.3, R3). A repository with no commit yet, its files written (step 2's decisions, a budget line of step 6's):
# the initial commit without the pass is refused by the label rule (4c); `decisions.sh propose --all`, the proposals,
# `apply --no-commit` label every line and make no commit; then the initial commit passes the hook. vid-init's step 7
# names the pass before its initial commit. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/r"; cd "$T/r"
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
git init -q; mkdir -p checks/hooks .ran .fail app .vid
for c in placement conformance imports seams inventory census design-cite prd harness; do printf '#!/bin/sh\n# Purpose: stub court %s\nexit 0\n' "$c" > "checks/$c.sh"; done
cp "$CHECKS/hooks/pre-commit" checks/hooks/; cp "$CHECKS/decisions.sh" "$CHECKS/event.sh" checks/
printf '.ran/\n.fail/\n.vid/\n' > .gitignore; printf 'x\n' > app/x.txt
fail() { echo "labels-init-order: $*" >&2; cat "$T/r/.vid/out" >&2 2>/dev/null; exit 1; }
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\n```\n' > INVENTORY.md
printf '# DECISIONS\n\n## Log\n\n- **D-001** the stack is the scaffold'"'"'s | why: owner hint | enforced: convention\n- **D-002** login is one form | why: hint | enforced: convention\n- **D-003** stacks=2 in the budget | why: step 6 | enforced: convention\n' > DECISIONS.md
git config core.hooksPath checks/hooks; g add -A
if VID_ROLE=fix g commit -qm 'initial' > .vid/out 2>&1; then fail 'the initial commit passed with unlabelled decisions'; fi
grep -q 'no label' .vid/out || fail 'the initial commit was not refused by the label rule'
sh checks/decisions.sh propose --all > .vid/out 2>&1; grep -q '3 decisions → .vid/briefs/labels-1.md' .vid/out || fail 'the pass did not cover every decision'
H() { grep -F -- "- **$1**" DECISIONS.md | git hash-object --stdin | cut -c1-12; }
printf 'D-001 %s | scope: project | sure\nD-002 %s | applies-to: LOGIN | sure\nD-003 %s | scope: project | sure\n' "$(H D-001)" "$(H D-002)" "$(H D-003)" > .vid/decision-labels.proposed
sh checks/decisions.sh apply --no-commit > .vid/out 2>&1 || fail 'apply --no-commit was refused'
git rev-parse -q --verify HEAD > /dev/null && fail 'apply --no-commit made a commit'
grep -q '(not committed' .vid/out || fail 'apply --no-commit does not say the labels land in the next commit'
g add -A; VID_ROLE=fix g commit -qm 'initial' > .vid/out 2>&1 || fail 'the initial commit was refused after the pass'
[ "$(git show HEAD:DECISIONS.md | grep -cE '[|] (scope: project|applies-to: LOGIN)$')" = 3 ] || fail 'the initial commit does not carry the labels'
# the text check below needs ViD's own skills beside checks/; a project keeps no copy, so there it stops here
[ -f "$CHECKS/../skills/vid-init/SKILL.md" ] || exit 0
S7=$(awk '/^## 7\./ { on = 1; next } on && /^## / { exit } on' "$CHECKS/../skills/vid-init/SKILL.md")
P=$(printf '%s\n' "$S7" | grep -n 'decisions.sh apply --no-commit' | head -n 1 | cut -d: -f1); C=$(printf '%s\n' "$S7" | grep -n 'VID_ROLE=fix git commit' | head -n 1 | cut -d: -f1)
[ -n "$P" ] && [ -n "$C" ] && [ "$P" -lt "$C" ] || fail 'vid-init step 7 does not name the pass before the initial commit'
exit 0
