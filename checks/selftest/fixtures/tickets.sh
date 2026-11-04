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
# courts the planner calls (github, ticket, event, prd, stages, plan, brief), RUN-STATE in ticket mode with a plan —
# A (ROW-001, stage 1), B (ROW-002, stage 1, builds on A), C (ROW-004, stage 2, builds on A) — recorded; the code
# repository (tk_code) and the fake gh (gh_fake).
gh_vid() {
  . "$CHECKS/selftest/fixtures/stages.sh"
  mkdir -p "$1/checks"; cd "$1"; git init -q
  cp "$CHECKS/github.sh" "$CHECKS/ticket.sh" "$CHECKS/event.sh" "$CHECKS/prd.sh" "$CHECKS/stages.sh" "$CHECKS/plan.sh" "$CHECKS/brief.sh" checks/
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
ghn() { grep -c "^gh $1" "$T/gh/log" 2>/dev/null || true; }   # ghn '<call prefix>': how many such calls the fake saw
# gh_worker <dir>: a stand-in's plain clone of the code repository there, made by github.sh clone (prefix vid:)
gh_worker() { ( cd "$T" && sh "$CHECKS/github.sh" clone owner/code "$1" --labels-prefix vid: > /dev/null ) || return 1; git -C "$1" config user.email agent@dev; git -C "$1" config user.name agent; }
# gh_ci <sha> <run id> <attempt> <conclusion> [<workflow>] [<xml file>]: a CI run of that commit in the fake gh, and,
# with an xml file, its report as the artifact vid-junit-<attempt>
gh_ci() {
  printf '%s %s %s %s push completed %s\n' "$2" "$3" "$1" "$(printf '%s' "${5:-CI}" | sed 's/ /%20/g')" "$4" >> "$T/gh/runs"
  if [ -n "${6:-}" ]; then mkdir -p "$T/gh/artifacts/$2/vid-junit-$3"; cp "$6" "$T/gh/artifacts/$2/vid-junit-$3/report.xml"; fi
}
# gh_skel_block <issue>: a skeleton ticket's filled return block, as a pull request's description (v0.26.10.12 R1: with
# its run-full: line, as a skeleton ticket written under 0.26.10.12 asks)
gh_skel_block() { printf 'The skeleton.\n\n```vid-return\nticket: #%s\nrows: none\nskeleton: test-framework: the toy runner\nskeleton: test-dir: tests/acceptance\nskeleton: run-one: sh tests/run.sh <names>\nskeleton: ci-workflow: CI\nskeleton: report: vid-junit-<run attempt>\nskeleton: run-full: gh workflow run CI --ref main\ndecisions:\n  - none\ndiscovered:\n  - none\nlaw-needed:\n  - none\nquestions:\n  - none\n```\n' "$1"; }
# gh_feature: after gh_vid — a builder ticket for step A (ROW-001, its test tests/invariants/test_a.py from ViD's copy;
# modules app/login, shared tests/invariants/harness.py) written with brief.sh write --ticket (fixtures/brief-write.sh's
# toy plugin) and published as ticket $N; worker 1 ($T/w1) claims it and commits the test first, unchanged, then
# app/login/main.py, and opens pull request $P with a filled block; its head has a green CI run (gh_ci). The approver's
# clone is $T/wa. Sets V (ViD's repository), N, P, HEAD1.
gh_feature() {
  V=$(pwd -P); . "$CHECKS/selftest/fixtures/brief-write.sh"; bw_plugin
  sh checks/brief.sh write --role builder --slice 1 --step A --rows ROW-001 --selection tests/invariants/test_a.py --ticket > "$T/bw" 2>&1 || { cat "$T/bw" >&2; return 1; }
  BR=$(sed -n 's/^ViD brief write: //p' "$T/bw" | head -n 1)
  sh checks/github.sh publish --ticket "$BR" > "$T/pub" 2>&1 || { cat "$T/pub" >&2; return 1; }
  N=$(awk '$1 == "ticket" && / kind=feature / { sub(/number=/, "", $2); print $2 }' .vid/tickets/map)
  gh_worker "$T/w1" && gh_worker "$T/wa" || return 1
  ( cd "$T/w1" && [ "$(sh "$CHECKS/github.sh" next-ticket --worker 1)" = "next $N" ] && sh "$CHECKS/github.sh" claim "$N" --worker 1 > /dev/null 2>&1 &&
    git fetch -q origin && git checkout -q -b "vid/$N" "origin/vid/$N" && mkdir -p tests/invariants app/login &&
    cp "$V/tests/invariants/test_a.py" tests/invariants/ && git add tests && git commit -qm 'the acceptance tests, unchanged' &&
    printf 'sign in\n' > app/login/main.py && git add app && git commit -qm 'sign in' ) || return 1
  gh_feat_block "$N" > "$T/pr.md"
  ( cd "$T/w1" && sh "$CHECKS/github.sh" push "vid/$N" --pr "$T/pr.md" > /dev/null 2>&1 ) || return 1
  P=$(ls "$T/gh/prs" | sort -n | tail -n 1); HEAD1=$(git -C "$T/w1" rev-parse HEAD); gh_ci "$HEAD1" 201 1 success
}
gh_feat_block() { printf 'Sign in.\n\nCloses #%s\n\n```vid-return\nticket: #%s\nrows:\n  REQ-001/ROW-001   pass   ci: 201\ndecisions:\n  - none\ndiscovered:\n  - none\nlaw-needed:\n  - none\nquestions:\n  - none\n```\n' "$1" "$1"; }
