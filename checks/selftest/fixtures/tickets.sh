# Purpose: selftest fixture — ticket mode's toy code repository (v0.26.10.9 spec §5). Sourced (Env: CHECKS, T).
# tk_code: a local bare repository at $T/code.git (its main, one empty root commit made from the dev side's clone
# $T/dev; an existing $T/code.git is kept as it is) and, in the current directory, the read-only copy .vid/code cloned
# and fetched, as the planner keeps it.
# tk_dev <message> [<file> <content>]…: a commit on main in $T/dev, pushed (the dev team's merges, in short).
# tk_ticket_mode: RUN-STATE at `mode: tickets` with a replan session started an hour ago.
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
tk_code() {
  if [ ! -d "$T/code.git" ]; then
    git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main
    git clone -q "$T/code.git" "$T/dev" 2>/dev/null
    ( cd "$T/dev" && git checkout -q -b main 2>/dev/null; g commit -q --allow-empty -m 'Initial commit' -m 'Stand-in: worker-1' && git push -q origin main 2>/dev/null )
  else [ -d "$T/dev" ] || git clone -q "$T/code.git" "$T/dev" 2>/dev/null; fi
  mkdir -p .vid; git clone -q "$T/code.git" .vid/code 2>/dev/null; git -C .vid/code fetch -q
}
tk_dev() {
  _m=$1; shift
  ( cd "$T/dev" && while [ $# -ge 2 ]; do mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; git add "$1"; shift 2; done
    g commit -q --allow-empty -m "$_m" && git push -q origin main 2>/dev/null )
}
tk_ticket_mode() {
  mkdir -p .vid; printf 'run: active\nsession: S1\nmode: tickets\nplan: required\nstage: 1\n' > .vid/RUN-STATE.md
  printf 'stage name=replan state=start session=S1 records=29 at=%s\n' "$(date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
}
# gh_fake: the fake gh (fixtures/fake-gh) first on PATH, its state in $T/gh, serving owner/code from $T/code.git.
gh_fake() {
  mkdir -p "$T/bin" "$T/gh"; cp "$CHECKS/selftest/fixtures/fake-gh" "$T/bin/gh"; chmod +x "$T/bin/gh"
  PATH="$T/bin:$PATH"; FAKEGH=$T/gh; export PATH FAKEGH
  echo owner/code > "$T/gh/repo"; echo "$T/code.git" > "$T/gh/remote"
}
# gh_vid <dir>: the planner's toy ViD repository there, entered: the stage toy (fixtures/stages.sh: two stages, the
# rows' tests in ViD's copy) with stage cards, ARCHITECTURE.md's vid-code block (repo owner/code, prefix vid:), the
# courts the planner calls (github, event, prd, stages, plan, brief), RUN-STATE in ticket mode with a plan —
# A (ROW-001, stage 1), B (ROW-002, stage 1, builds on A), C (ROW-004, stage 2, builds on A) — recorded; the code
# repository (tk_code) and the fake gh (gh_fake).
gh_vid() {
  . "$CHECKS/selftest/fixtures/stages.sh"
  mkdir -p "$1/checks"; cd "$1"; git init -q
  cp "$CHECKS/github.sh" "$CHECKS/lib.sh" "$CHECKS/event.sh" "$CHECKS/prd.sh" "$CHECKS/stages.sh" "$CHECKS/plan.sh" "$CHECKS/brief.sh" checks/   # lib.sh beside github.sh (0.26.10.28.4)
  st_files
  { cat STAGES.md; printf '\n## Stage 1 — the basics\n\n- **Usable:** sign in and keep notes.\n\n## Stage 2 — sharing\n\n- **Usable:** share a note.\n'; } > STAGES.x && mv STAGES.x STAGES.md
  printf '# Architecture\n\n| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| app/login | signing in | sessions | `app.login` | none |\n| app/notes | notes | notes | `app.notes` | none |\n\n```vid-code\nrepo: owner/code\nlabels-prefix: vid:\n```\n' > ARCHITECTURE.md
  printf '# Baseline\n\n## Stack\n\n| Layer | Choice | FORBIDDEN alternatives (named) |\n|---|---|---|\n| app | the toy language | others |\n' > BASELINE.md
  printf '# toy\n\n```vid-placement\napp/\n```\n' > CLAUDE.md
  printf '.vid/\n' > .gitignore; g add -A && g commit -qm 'the spec'
  tk_ticket_mode
  printf '\n## The plan\n\n```vid-plan\nstep A | name: sign in | modules: app/login | builds-on: - | rows: ROW-001\nstep B | name: notes | modules: app/notes | builds-on: A | rows: ROW-002\nstep C | name: sharing | modules: app/share | builds-on: A | rows: ROW-004\nshared: tests/invariants/harness.py\n```\n' >> .vid/RUN-STATE.md
  sh checks/plan.sh change create 'the plan' --trigger initial --expect 'the skeleton first' > /dev/null 2>&1
  tk_code; gh_fake
}
# tk_receipt <sha> <run> <attempt> <pr|-> <stage|-> <case line>…: a CI receipt in ViD's records, as the first ticket
# mode's import published one (0.26.10.28.1: written here, that mode removed): .vid/ledger-results/<sha 12>.ci-<run>-
# <attempt>.xml with .cases (the case lines, `case <test path>::<name> <status> <seconds>`) and .rows (the rows they
# name), and its `ledger-run type=ci` event; RN its name
tk_receipt() {
  _c=$(printf '%s' "$1" | cut -c1-12); RN=$_c.ci-$2-$3.xml; _pr=$4; _sg=$5; _ru=$2; _at=$3; shift 5; mkdir -p .vid/ledger-results
  printf '<testsuites/>\n' > ".vid/ledger-results/$RN"; printf '%s\n' "$@" > ".vid/ledger-results/$RN.cases"
  printf '%s\n' "$@" | grep -oE 'ROW-[0-9]+' | sort -u > ".vid/ledger-results/$RN.rows"
  printf 'ledger-run type=ci report=%s repo=owner/code workflow=CI run=%s attempt=%s commit=%s pr=%s%s status=0 at=%s\n' "$RN" "$_ru" "$_at" "$_c" "$_pr" "$( [ "$_sg" = - ] || printf ' stage=%s' "$_sg")" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
}
