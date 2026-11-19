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
  # GM-1 S10: the code repository's pushes in the write log, as the fake logs those of every repository it makes
  if [ -d "$T/code.git" ]; then printf '#!/bin/sh\nprintf "owner/code push %%s\\n" "$1" >> %s\n' "'$T/gh/writes'" > "$T/code.git/hooks/update"; chmod +x "$T/code.git/hooks/update"; fi
}
# GM-1 S10, the fake's GitHub as a team leaves it (after gh_fake):
# gh_issue <title> [<body file>]: an issue of owner/code made through the fake, its number printed
# gh_attr <n> <name> <value>: an issue's created (an ISO time), assignees (logins, one a line), state (OPEN or CLOSED) or title
# gh_sub <parent> <child>: child a sub-issue of parent
# gh_writing <n> <ticket file> <body|comments> [<parts>]: the ticket posted as a writing in the writer's form, cut into <parts> (2) at
#   its `## ` lines, each opening `Ticket #<n>, part <k> of <m>, writing <hash>.` and a blank line; part 1 as the issue's body, or
#   every part a comment (a body in the project's own form left as it is); each part trimmed of its trailing blank lines, as GitHub
#   may give it back, or, with GW_KEPT set, kept whole with one more line, as gh --jq prints a part GitHub keeps whole
# gh_replaced <n>: each part comment of issue n marked `vid: replaced.`, as an amendment marks the earlier writing's
# gh_wclear: the write log emptied, so a case reads only what its own act wrote
gh_issue() { if [ -n "${2:-}" ]; then gh issue create -R owner/code --title "$1" --body-file "$2"; else gh issue create -R owner/code --title "$1" --body ''; fi | sed 's#.*/##'; }
gh_attr() { printf '%s\n' "$3" > "$FAKEGH/issues/$1/$2"; }
gh_sub() { printf '%s' "$1" > "$FAKEGH/issues/$2/parent"; }
gh_writing() {
  _gn=$1; _gf=$2; _gm=${4:-2}; _gh=$(git hash-object "$_gf" | cut -c1-12); _gd=$FAKEGH/issues/$_gn; mkdir -p "$_gd/comments"
  awk -v m="$_gm" -v o="$T/gw" '/^## / { h[++k] = NR } { L[NR] = $0 } END { n = (m > k + 1 ? k + 1 : m); for (p = 1; p <= n; p++) { a = (p == 1 ? 1 : h[int((p - 1) * k / n) + 1]); b = (p == n ? NR : h[int(p * k / n) + 1] - 1)
    f = o "." p; for (i = a; i <= b; i++) print L[i] > f; close(f) } print n > (o ".n") }' "$_gf"
  # each part stored as GitHub may keep it, its trailing blank lines trimmed, so a case runs the join's restoration
  _gt=$(cat "$T/gw.n"); _gp=1; while [ "$_gp" -le "$_gt" ]; do { printf 'Ticket #%s, part %s of %s, writing %s.\n\n' "$_gn" "$_gp" "$_gt" "$_gh"; if [ -n "${GW_KEPT:-}" ]; then cat "$T/gw.$_gp"; echo; else awk '{ L[++n] = $0 } END { while (n > 0 && L[n] == "") n--; for (i = 1; i <= n; i++) print L[i] }' "$T/gw.$_gp"; fi; } > "$T/gw.part"
    if [ "$_gp" = 1 ] && [ "$3" = body ]; then cp "$T/gw.part" "$_gd/body"; else _gk=$(( $(ls "$_gd/comments" | grep -c . || true) + 1 )); cp "$T/gw.part" "$_gd/comments/$_gk"; fi; _gp=$((_gp + 1)); done; rm -f "$T"/gw.*; }
gh_replaced() { for _gc in $(ls "$FAKEGH/issues/$1/comments" 2>/dev/null); do head -n 1 "$FAKEGH/issues/$1/comments/$_gc" | grep -qE '^Ticket #[0-9]+, part [0-9]+ of [0-9]+, writing [0-9a-f]+\.$' && printf 'vid: replaced. This comment held a part of an earlier writing of this ticket.\n' > "$FAKEGH/issues/$1/comments/$_gc"; done; return 0; }
gh_wclear() { : > "$FAKEGH/writes"; }
# gh_vid <dir>: the planner's toy ViD repository there, entered: the stage toy (fixtures/stages.sh: two stages, the
# rows' tests in ViD's copy) with stage cards, ARCHITECTURE.md's vid-code block (repo owner/code, prefix vid:), the
# courts the planner calls (github, event, prd, stages, plan, brief), RUN-STATE in ticket mode with a plan —
# A (ROW-001, stage 1), B (ROW-002, stage 1, builds on A), C (ROW-004, stage 2, builds on A) — recorded; the code
# repository (tk_code) and the fake gh (gh_fake).
gh_vid() {
  . "$CHECKS/selftest/fixtures/stages.sh"
  mkdir -p "$1/checks"; cd "$1"; git init -q
  cp "$CHECKS/github.sh" "$CHECKS/lib.sh" "$CHECKS/event.sh" "$CHECKS/prd.sh" "$CHECKS/stages.sh" "$CHECKS/plan.sh" "$CHECKS/brief.sh" "$CHECKS/planner.sh" checks/   # lib.sh beside github.sh (0.26.10.28.4); planner.sh beside plan.sh (0.26.11.1.2, R6)
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
