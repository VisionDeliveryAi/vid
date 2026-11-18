# Purpose: selftest fixture — the toy for recording the dev side's decisions (0.26.10.29.5, DP-1 R2): ViD's repository in ticket
# mode, entered at $T/v, for `decisions.sh record`. Sourced by the dp-r2-* cases once $T is made (Env: CHECKS, T). The stub courts
# and the real hooks (fixtures/stub-courts.sh, and commit-msg), core.hooksPath set; beside them decisions.sh, labels.sh, lib.sh,
# event.sh, github.sh and results.sh. INVENTORY.md: ROW-001, ROW-002, the rule RULE-001; ARCHITECTURE.md's module table app/login,
# app/notes; DECISIONS.md holding D-001; RUN-STATE in ticket mode, its plan step S01 (modules: `app.login`, app/notes/, app/gone) and
# S02; the writer's log publishing ticket 3 (S01); ticket 3's file (rows: ROW-001 RULE-001 SEAM-001 HOS-001 ROW-009, the last no
# longer in INVENTORY.md). The fake gh (fixtures/tickets.sh), its code repository $T/code.git, the spec repository made and exported
# (spec-setup). Helpers: dpr_pr <p> <ticket> <body> [<state>]: pull request p naming that ticket with that description, MERGED by
# default and then a line of .vid/decide/merges; dpr_rec: `decisions.sh record`, its output in $T/out, its exit in RC; dpr_spec: the
# spec repository's DECISIONS.md at main; dpr_reads <p>: how many times the fake gh read pull request p's description.
. "$CHECKS/selftest/fixtures/tickets.sh"
mkdir -p "$T/v"; cd "$T/v"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
cp "$CHECKS/decisions.sh" "$CHECKS/lib.sh" "$CHECKS/event.sh" "$CHECKS/github.sh" "$CHECKS/results.sh" "$CHECKS/page.sh" checks/
cp "$CHECKS/hooks/commit-msg" checks/hooks/
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\nROW-002 | behavior | notes | anon | n/a | x | REQ-002 | owed: prerequisite — later\nrule | RULE-001 | sessions expire | grep x | 1 | owed: census-armed — later | origin: REQ-001\n```\n' > INVENTORY.md
printf '# Architecture\n\n| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| app/login | signing in | sessions | `app.login` | none |\n| app/notes | notes | notes | `app.notes` | none |\n' > ARCHITECTURE.md
printf '# PRD\n\nA toy.\n' > PRD.md
printf '# DECISIONS\n\n## Log\n\n- **D-001** one font everywhere | why: brand | enforced: convention | scope: project\n' > DECISIONS.md
g add -A && g commit -qm 'the toy'; git config core.hooksPath checks/hooks
mkdir -p .vid/tw/out .vid/decide
printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n\n## The plan\n\n```vid-plan\nstep S01 | name: sign in | modules: `app.login`, app/notes/, app/gone | builds-on: - | rows: ROW-001 | lane: builder\nstep S02 | name: notes | modules: app/notes | builds-on: S01 | rows: ROW-002 | lane: builder\n```\n' > .vid/RUN-STATE.md
printf 'repo: owner/code\nspec-repo: owner/code-spec\nlabels-prefix:\n' > .vid/tw/settings
printf 'published 3 step=S01 kind=feature at=2026-11-16T00:00:00Z\n' > .vid/tw/log
printf '# Feature ticket S01: sign in\n\n## Header\n\n- number: 3\n- kind: feature\n- step: S01\n- stage: 1\n- rows: ROW-001 RULE-001 SEAM-001 HOS-001 ROW-009\n' > .vid/tw/out/issue-3.md
git init -q --bare "$T/code.git"; gh_fake
sh checks/github.sh spec-setup > "$T/out" 2>&1 || { cat "$T/out" >&2; echo 'dp-record fixture: spec-setup failed' >&2; exit 1; }
DPR_SPEC=$T/gh/repos/owner%code-spec/remote.git
dpr_pr() { mkdir -p "$T/gh/prs/$1/comments"; printf '%s\n' "$3" > "$T/gh/prs/$1/body"; echo "${4:-MERGED}" > "$T/gh/prs/$1/state"; echo "ticket-$2" > "$T/gh/prs/$1/head"; echo false > "$T/gh/prs/$1/draft"
  [ "${4:-MERGED}" != MERGED ] || printf '%s\t%s\t%s\t%s\n' "$1" "$2" 0123456789abcdef0123456789abcdef01234567 fedcba9876543210fedcba9876543210fedcba98 >> .vid/decide/merges; }
dpr_rec() { RC=0; sh checks/decisions.sh record > "$T/out" 2>&1 || RC=$?; }
dpr_spec() { git --git-dir="$DPR_SPEC" show main:DECISIONS.md 2>/dev/null; }
dpr_reads() { grep -c "^gh pr view $1 .*--json body" "$T/gh/log" 2>/dev/null || true; }
