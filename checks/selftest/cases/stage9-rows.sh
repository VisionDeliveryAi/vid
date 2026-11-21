#!/bin/sh
# Purpose: selftest case — stage 9's rows built in 0.26.10.28.1 (STAGE-9-SPEC.md R4, R6; 9.1 R9). R4: /vid run's skill
# refuses a project the old ticket mode planned, in its one line, after its mode check and before the lock. CK-R-257:
# in ticket mode export.sh leaves .vid/code and .vid/code.old-* out, keeps ViD's records, and says DevAgent's
# transcripts are out of its reach; outside ticket mode .vid/code is packed as before. CK-T-233: in ticket mode the
# hook passes `enforced: ticket <n>` for a ticket the writer's log published and `enforced: step <id>` for a step of
# the plan, and refuses either otherwise; outside ticket mode an unpublished ticket passes as before. CK-R-006:
# planner.sh prd-form refuses a legacy block-form PRD in one line naming /vid create-prd's import door, and passes an
# enriched one. R5: github.sh results-fetch finding .vid/code a working clone moves it aside to .vid/code.old-<UTC>,
# saying so, and clones the bare copy; a bare copy is fetched in place, nothing moved. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "stage9-rows: $*" >&2; cat "$T/out" >&2 2>/dev/null || true; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
# R4: the skill's line, between the mode check and the lock (in ViD's own layout, where skills/ sits beside checks/); vid-connect's
# since GM-4 F2 and K10, which move the run skill's start there
SK=$CHECKS/../skills/vid-connect/SKILL.md
if [ -f "$SK" ]; then
  awk '/this project is not in ticket mode/ { m = NR } /This project was planned by the old ticket mode; re-plan it with \/vid plan\./ { r = NR } /`connect lock:`/ && !l { l = NR }
    END { exit !(m && r && l && m <= r && r < l) }' "$SK" || fail "vid-connect's refusal of an old-ticket-mode project is missing or out of place"
  grep -q 'a `.vid/tickets/` folder and no `.vid/tw/settings`' "$SK" || fail "vid-connect's refusal does not name what it reads"
fi
# CK-R-257: the export in ticket mode, then in develop mode
export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$T/claude/projects"
P="$T/proj"; mkdir -p "$P/checks"; cd "$P"; git init -q
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" "$CHECKS/export.sh" checks/
printf '.vid/\n' > .gitignore; printf 'spec\n' > PRD.md; g add -A; g commit -qm root
mkdir -p .vid/code/objects .vid/code.old-20261111T000000Z .vid/tw .vid/decide
printf 'run: active\nmode: tickets\n' > .vid/RUN-STATE.md; printf 'DevAgent code\n' > .vid/code/objects/x; printf 'old clone\n' > .vid/code.old-20261111T000000Z/f
printf 'published 3 step=S01\n' > .vid/tw/log; printf 'row ROW-001 passing\n' > .vid/decide/state
sh checks/export.sh --out "$T/x1" > "$T/out" 2>&1 || fail 'the ticket-mode export failed'
B=$(ls -d "$T"/x1/*/ | head -n 1)
[ -f "$B/vid/home/tw/log" ] && [ -f "$B/vid/home/decide/state" ] && [ -f "$B/vid/home/RUN-STATE.md" ] || fail "ViD's records are not in the export"
[ ! -e "$B/vid/home/code" ] || fail '.vid/code is in a ticket-mode export'
! ls -d "$B"/vid/home/code.old-* > /dev/null 2>&1 || fail '.vid/code.old-* is in a ticket-mode export'
grep -q '^devagent	out of reach' "$B/export.tsv" || fail "export.tsv has no devagent line"
grep -q "DevAgent's transcripts are out of its reach" "$T/out" || fail "the export does not say DevAgent's transcripts are out of its reach"
printf 'run: active\n' > .vid/RUN-STATE.md
sh checks/export.sh --out "$T/x2" > "$T/out" 2>&1 || fail 'the develop-mode export failed'
B=$(ls -d "$T"/x2/*/ | head -n 1)
[ -f "$B/vid/home/code/objects/x" ] || fail '.vid/code is left out outside ticket mode'
! grep -q '^devagent' "$B/export.tsv" || fail 'a devagent line outside ticket mode'
# CK-T-233: the hook's ticket and step refs
mkdir "$T/h"; cd "$T/h"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
mkdir -p .vid/tw; printf 'published 7 step=S01 kind=feature\npublished 8 step=S02 kind=feature\nwithdrawn 8 decision=x\n' > .vid/tw/log
RS='run: active
mode: tickets
## The plan
```vid-plan
step S01 | name: one | modules: app/ | builds-on: - | rows: ROW-001 | lane: builder
step S+02 | name: two | modules: app/ | builds-on: S01 | rows: ROW-002 | lane: builder
```'
printf '%s\n' "$RS" > .vid/RUN-STATE.md
printf '# Decisions\n' > DECISIONS.md; g add DECISIONS.md; g commit -qm decisions --no-verify
dec() { printf -- '- **D-%03d** a choice | why: a reason | enforced: %s | scope: project\n' "$1" "$2" >> DECISIONS.md; g add DECISIONS.md; }
k=1
for ok in 'ticket 7' 'ticket #7' 'step S01' 'step S+02' 'convention' 'convention — the build step runs lint' 'checks/hooks/pre-commit step 4b'; do
  dec "$k" "$ok"; sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail "the hook refused enforced: $ok in ticket mode"; g commit -qm "D-$k" --no-verify; k=$((k + 1))
done
for bad in 'ticket 9' 'step S09'; do
  dec "$k" "$bad"; sh checks/hooks/pre-commit > "$T/out" 2>&1 && fail "the hook passed enforced: $bad in ticket mode"
  grep -q "^ViD pre-commit: rejected — DECISIONS.md cites 'enforced: $bad'" "$T/out" || fail "enforced: $bad: not the one-line refusal"
  g checkout -q HEAD -- DECISIONS.md
done
printf 'run: active\n' > .vid/RUN-STATE.md
dec "$k" 'ticket 9'; sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail 'outside ticket mode the hook refused enforced: ticket 9'
# CK-R-006: the legacy block-form PRD
mkdir "$T/l"; cd "$T/l"; printf '# toy\n\n### REQ-001 sign in\n\nFail-if: no sign-in.\n' > PRD.md
sh "$CHECKS/planner.sh" prd-form > "$T/out" 2>&1 && fail 'a legacy PRD passed prd-form'
[ "$(grep -c . "$T/out")" = 1 ] && grep -q "legacy block form.*/vid create-prd's import door" "$T/out" || fail 'the legacy refusal is not one line naming the import door'
printf '# toy\n\n```vid-prd\nREQ-001 | functional | x\n```\n' > PRD.md; sh "$CHECKS/planner.sh" prd-form > "$T/out" 2>&1 || fail 'an enriched PRD was refused'
# R5: results-fetch moves a working clone aside
mkdir "$T/r"; cd "$T/r"; git init -q; mkdir -p .vid/tw; printf 'run: active\nmode: tickets\n' > .vid/RUN-STATE.md; printf 'repo: owner/code\nlabels-prefix:\n' > .vid/tw/settings
. "$CHECKS/selftest/fixtures/tickets.sh"; git init -q --bare "$T/code.git"; ( git clone -q "$T/code.git" "$T/cw" 2>/dev/null && cd "$T/cw" && g commit -q --allow-empty -m one && git push -q origin HEAD:main 2>/dev/null ); gh_fake
git clone -q "$T/code.git" .vid/code 2>/dev/null; [ -d .vid/code/.git ] || fail 'the working clone was not made (the case is wrong)'
sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || fail 'results-fetch refused a working clone'
grep -q '^ViD github: .vid/code was a working clone — moved aside to .vid/code.old-[0-9TZ]*; the bare copy is cloned in its place$' "$T/out" || fail 'results-fetch does not say it moved the clone aside'
ls -d .vid/code.old-* > /dev/null 2>&1 && [ -d "$(ls -d .vid/code.old-* | head -n 1)/.git" ] || fail 'the working clone is not kept aside'
[ "$(git --git-dir=.vid/code rev-parse --is-bare-repository)" = true ] || fail '.vid/code is not the bare copy'
sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || fail 'results-fetch refused the bare copy'
! grep -q 'moved aside' "$T/out" && [ "$(ls -d .vid/code.old-* | grep -c .)" = 1 ] || fail 'the bare copy was moved aside'
exit 0
