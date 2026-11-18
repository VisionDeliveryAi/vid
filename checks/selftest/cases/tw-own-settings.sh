#!/bin/sh
# Purpose: selftest case — ViD's own settings never reach a ticket (0.26.10.28.5, R2), on made-up decisions in the shape of a project's, no real data.
# The skeleton ticket of TW's toy quotes none of: a decision recording .vid/budget's keys labelled scope: project (a project made before the mark), an
# unlabelled one, a decision marked `| about: vid-settings` with none of the keys labelled scope: project, and a marked one joined to the ticket's own
# row, and one recording the run's other limits (silence, startup, run limit, builders, builder tool). A decision about the product
# labelled scope: project is still quoted. A marked budget line, as init writes it now, is labelled by decisions.sh
# apply with its mark kept, and passes rule 4c at the commit. vid-init records the budget with the mark. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "tw-own-settings: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
# the mark through decisions.sh apply and rule 4c, at a commit
mkdir "$T/r"; cd "$T/r"; g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
git init -q; mkdir -p checks/hooks .ran .fail app .vid
for c in placement conformance imports seams inventory census design-cite prd harness; do printf '#!/bin/sh\n# Purpose: stub court %s\nexit 0\n' "$c" > "checks/$c.sh"; done
cp "$CHECKS/hooks/pre-commit" checks/hooks/; cp "$CHECKS/decisions.sh" "$CHECKS/lib.sh" "$CHECKS/event.sh" "$CHECKS/labels.sh" checks/
printf '.ran/\n.fail/\n.vid/\n' > .gitignore; printf 'x\n' > app/x.txt
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\n```\n' > INVENTORY.md
printf '# DECISIONS\n\n## Log\n\n- **D-020** the budget: stacks=1, claims-per-slice=60, court-seconds=300 | why: the defaults | enforced: convention | about: vid-settings | origin: proposal\n' > DECISIONS.md
H=$(grep -F -- '- **D-020**' DECISIONS.md | git hash-object --stdin | cut -c1-12); printf 'D-020 %s | scope: project | sure\n' "$H" > .vid/decision-labels.proposed
sh checks/decisions.sh apply --no-commit > "$T/out" 2>&1 || fail 'apply refused the marked line'
grep -q '^- \*\*D-020\*\* .*| enforced: convention | scope: project | about: vid-settings | origin: proposal$' DECISIONS.md || fail "apply did not keep the mark: $(grep D-020 DECISIONS.md)"
git config core.hooksPath checks/hooks; g add -A; VID_ROLE=fix g commit -qm 'initial' > "$T/out" 2>&1 || fail 'rule 4c refused the marked line'
# the writer, on TW's toy
. "$CHECKS/selftest/fixtures/tw-toy.sh"; tw_toy "$T/toy"; GS=$CHECKS/github.sh
sec() { awk -v s="## $2" '$0 == s { on = 1; next } on && /^## / { exit } on' "$1"; }
{ printf -- '- **D-020** the run budget, stacks=1, memory-headroom-mb=2048, claims-per-slice=60, wall-hours-per-slice=8, court-seconds=300 | why: the defaults | enforced: convention | scope: project | origin: proposal\n'
  printf -- '- **D-021** the budget file .vid/budget keeps its defaults | why: the defaults | enforced: convention\n'
  printf -- '- **D-022** pages load in under a second | why: readers on phones | enforced: convention | scope: project\n'
  printf -- '- **D-023** the run keeps one builder at a time | why: one machine | enforced: convention | scope: project | about: vid-settings\n'
  printf -- '- **D-024** ROW-003 runs with one environment | why: one machine | enforced: convention | applies-to: ROW-003 | about: vid-settings\n'
  printf -- '- **D-025** the run limits, silence-minutes=20, startup-minutes=60, run-limit-minutes=1440, builders-target=2, builder-tool=codex | why: the defaults | enforced: convention | scope: project\n'; } >> DECISIONS.md
git -c user.email=t@t -c user.name=t commit -qam 'decisions' > /dev/null
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$GS" tw-sync > "$T/out" 2>&1 || fail 'tw-sync failed'; tw_start S01 || fail 'S01 was refused'
F=$(sh "$CHECKS/writer.sh" write skeleton 2> "$T/werr") || fail 'the skeleton was not written'; sec "$F" Decisions > "$T/out"
grep -q 'D-022' "$T/out" || fail 'a product decision labelled scope: project is no longer quoted'
for d in D-020 D-021 D-023 D-024 D-025; do ! grep -q "$d" "$T/out" || fail "$d, about ViD's own settings, reaches the ticket"; done
! grep -qE 'stacks=|claims-per-slice|court-seconds|silence-minutes|builder-tool' "$F" || fail "the ticket shows ViD's budget"
# init writes the mark
[ ! -f "$CHECKS/../skills/vid-init/SKILL.md" ] || grep -q 'with the mark `| about: vid-settings` beside its label' "$CHECKS/../skills/vid-init/SKILL.md" || fail 'vid-init does not record its budget with the mark'
echo 'tw-own-settings: ok'
