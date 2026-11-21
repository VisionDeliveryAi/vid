# Purpose: selftest fixture — GitHub manual's step end (GM-4 4c: K2, E1 to E13), on the GitHub manual toy (fixtures/manual.sh) and
# the fake gh. Sourced once $T is made (Env: CHECKS, T); it sources planner-toy.sh, tickets.sh, manual.sh and results-reports.sh.
# ac_project <dir>: the toy there, entered, in GitHub manual (github-mode manual, .vid/tw/applied the spec's commit, every question the
#   owner's, the state repository made), DECISIONS.md holding D-001 (committed), RUN-STATE in ticket mode, the step ticket S02 published as #$AC_N (its writing in .vid/tw/out
#   quoting ROW-001 and ROW-012, engine alpha; a `published` log line at 2026-11-18T09:00:00Z), the lock taken by session ac; on the
#   code repository's main $AC_RED (the tests) and $AC_C (a later commit), and $AC_OFF on a side branch off main (pushed, never merged)
# ac_send <id>: the report folder $T/r/<id> pushed as vid-results/<id> to the code repository, committed at $AC_WHEN when set (a
#   git date, such as `@1700000000 +0000`)
# ac_red [<k>]: T2 red-$AC_N-<k> (1) at $AC_RED, both rows red. ac_head <commit> [<k>] [<case>…]: the head report
#   step-$AC_N-<commit12>-<k> (1), engine alpha, its cases (by default both rows passing). ac_grade <commit>: its grade, both kept.
#   ac_good <commit>: the three, a ticket accepted at that commit
# ac_ask <commit>: the team's ask, a comment `vid: decide <commit>` on #$AC_N. ac_round <subcommand> [<argument>…]: round.sh, its output
#   in $T/out, its exit in RC. ac_last: the newest comment on #$AC_N. ac_comments: how many comments #$AC_N has
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
ac_project() {
  mn_project "$1"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
  printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
  printf '# DECISIONS\n\n## Log\n\n- **D-001** one font everywhere | why: brand | enforced: convention | scope: project\n' > DECISIONS.md; git add DECISIONS.md; git commit -qm 'decisions'
  git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings; gh repo create owner/vid-state --private > /dev/null
  AC_N=$(gh_issue 'Step S02'); mkdir -p .vid/tw/out "$T/r"
  { mn_ticket "$AC_N" S02 step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"
  printf 'published %s kind=step step=S02 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$AC_N" >> .vid/tw/log
  CLAUDE_CODE_SESSION_ID=ac; export CLAUDE_CODE_SESSION_ID; sh "$CHECKS/github.sh" lock-take ac > /dev/null 2>&1 || return 1
  tk_dev 'the tests'; AC_RED=$(git -C "$T/dev" rev-parse HEAD); tk_dev 'the step'; AC_C=$(git -C "$T/dev" rev-parse HEAD)
  ( cd "$T/dev" && git checkout -q -b side && g commit -q --allow-empty -m 'a side commit' && git push -q origin side 2>/dev/null && git checkout -q main ); AC_OFF=$(git -C "$T/dev" rev-parse side)
  gh_wclear; }
ac_send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A
  if [ -n "${AC_WHEN:-}" ]; then GIT_COMMITTER_DATE=$AC_WHEN GIT_AUTHOR_DATE=$AC_WHEN rr_git -C "$T/x" commit -qm "$1"; else rr_git -C "$T/x" commit -qm "$1"; fi
  git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
ac_red() { _i=red-$AC_N-${1:-1}; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-001 ROW-012' "$AC_RED")"
  rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-001=fail:no\ digest ROW-012=fail:no\ page)"; ac_send "$_i"; }
ac_head() { _c=$1; _k=${2:-1}; shift; [ $# -eq 0 ] || shift; _i=step-$AC_N-$(printf %s "$_c" | cut -c1-12)-$_k; [ $# -gt 0 ] || set -- ROW-001=pass ROW-012=pass
  rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nenvironments: 1' "$_c")"; rr_put "$_i" cases-alpha.xml "$(rr_cases "$@")"; ac_send "$_i"; }
ac_grade() { _i=grade-step-$AC_N-$(printf %s "$1" | cut -c1-12)-1; rr_put "$_i" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-001 kept — seen\nROW-012 kept — seen' "$1")"; ac_send "$_i"; }
ac_good() { ac_red; ac_head "$1"; ac_grade "$1"; }
ac_ask() { printf 'vid: decide %s\nby: MR\n' "$1" > "$T/ask"; gh issue comment "$AC_N" -R owner/code --body-file "$T/ask" > /dev/null; }
ac_round() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
ac_comments() { ls "$FAKEGH/issues/$AC_N/comments" 2>/dev/null | grep -c . || true; }
ac_last() { cat "$FAKEGH/issues/$AC_N/comments/$(ls "$FAKEGH/issues/$AC_N/comments" | sort -n | tail -n 1)"; }
# ac_unit <branch> <description>: a unit's pull request from a branch off main, merged (the fake's --merge, a merge commit on main), its
#   number in AC_P; the dev clone's main brought up to it, AC_M its merge commit
ac_unit() { ( cd "$T/dev" && git checkout -q -B "$1" main && g commit -q --allow-empty -m "$1" && git push -q -f origin "$1" 2>/dev/null && git checkout -q main ); _h=$(git -C "$T/dev" rev-parse "$1")
  AC_P=$(gh pr create -R owner/code --head "$1" --base main --title "$1" --body "$2" | sed 's#.*/##'); gh pr merge "$AC_P" -R owner/code --merge --match-head-commit "$_h" > /dev/null
  ( cd "$T/dev" && git pull -q origin main 2>/dev/null ); AC_M=$(git -C "$T/dev" rev-parse main); }
# ac_plan: RUN-STATE's plan block, the toy's ($T/plan.blk, mn_project's), recorded (plan.sh change create, inside a call's stage), so the closes owed and
#   the writer read its steps
ac_plan() { { cat .vid/RUN-STATE.md; printf '\n## The plan\n\n```vid-plan\n'; cat "$T/plan.blk"; printf '```\n'; } > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
  sh "$CHECKS/event.sh" 'stage name=replan state=start session=ac-plan records=29' > /dev/null 2>&1   # the call's stage, as vid-connect's start opens it
  sh "$CHECKS/plan.sh" change create 'the plan' --trigger initial --expect 'the skeleton first' > "$T/pc" 2>&1; _r=$?
  sh "$CHECKS/event.sh" 'stage name=replan state=end session=ac-plan' > /dev/null 2>&1; [ "$_r" = 0 ] || { cat "$T/pc" >&2; return 1; }; }
