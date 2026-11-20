# Purpose: selftest fixture — GitHub manual's first post in the project's own issue form (GM-2 T3, T11). Sourced (Env: CHECKS, T).
# fm_form <file>: the toy issue form, invented: a title line with {step} and {name}, then a body using every placeholder, each a
#   whole line, among lines of the toy team's own words
# fm_toy <dir>: the ticket writer's toy (tw-toy.sh) there, entered: S04 working against S05 through fakes (`fakes: S05`, the plan
#   change recorded and ratified again); the stand-in's records a step ticket needs (two engines, S01's rows accepted, S01
#   closed); the spec repository owner/code-spec and ViD's state repository owner/vid-state made private on the fake; the form
#   committed at forms/issue.md; GitHub manual, its applied version that commit (.vid/tw/applied), state-repo: and issue-form:
#   set, and the epic, issue FM_P, made on the fake (no issue-parent: yet); the write log emptied
# fm_prep <step>: the step's ticket written — the export, the sync, plan.sh start, writer.sh write (skeleton for S01, else step);
#   FM_F the ticket's file, $T/post the output; returns 1 on the first refusal
# fm_post <step> [<tw-post option>…]: fm_prep, then github.sh tw-post --words "Yes, publish <step>" and the options given; FM_N
#   the issue number, $T/post tw-post's output; returns 1 on the first refusal
# fm_team_edit <n> <sed script>: issue n's body edited on the fake as the team would edit it on GitHub, outside every gh call ViD
#   makes: the write log gains nothing
fm_form() { cat > "$1" <<'EOF'
# {step}: {name}

## What this delivers

The toy team's own words: one line of what the step gives the user.

{full-ticket}

- Step, name, stage, lane and parent:
{step}
{name}
{stage}
{lane}
{parent}

## Requirements

{requirements}

## Tests

{tests}
{tests:row}
{tests:rule}
{tests:difference}
{tests:hostility}
{tests:seam}

## Depends on

{blocked-by}
{not-yet-ticketed}

## Works against fakes of

{fakes}

## Done when

The toy team's own checklist line.
EOF
}
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fm_toy() {
  tw_toy "$1"
  pt_rs 's/^\(step S04 .*\)$/\1 | fakes: S05/'
  sh "$CHECKS/plan.sh" change other 'S04 works against S05 through fakes' --trigger initial --expect 'the same steps' > "$T/fmc" 2>&1 || { cat "$T/fmc" >&2; return 1; }
  tw_ratify 'Yes, publish it' || return 1
  for _l in 'engines chromium firefox' 'row ROW-003 accepted' 'row ROW-004 accepted' 'closed S01' 'candidate 0' 'staged 0'; do tw_hand "$_l"; done
  printf 'state-repo: owner/vid-state\nissue-form: forms/issue.md\n' >> .vid/tw/settings
  gh repo create owner/code-spec --private > /dev/null; gh repo create owner/vid-state --private > /dev/null
  mkdir -p forms; fm_form forms/issue.md; g add forms/issue.md; g commit -qm 'the issue form'
  git rev-parse HEAD > .vid/tw/applied
  printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=github-mode value="manual" words="by hand" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
  printf 'The epic: the toy release.\n' > "$T/epic"; FM_P=$(gh_issue 'The toy release' "$T/epic"); gh_wclear
}
fm_prep() {
  sh "$CHECKS/github.sh" spec-export > "$T/post" 2>&1 && sh "$CHECKS/github.sh" tw-sync >> "$T/post" 2>&1 && sh "$CHECKS/plan.sh" start "$1" >> "$T/post" 2>&1 || return 1
  if [ "$1" = S01 ]; then FM_F=$(sh "$CHECKS/writer.sh" write skeleton 2>> "$T/post"); else FM_F=$(sh "$CHECKS/writer.sh" write step "$1" 2>> "$T/post"); fi; }
fm_post() {
  _s=$1; shift; FM_N=''; fm_prep "$_s" || return 1
  sh "$CHECKS/github.sh" tw-post --words "Yes, publish $_s" "$@" "$FM_F" > "$T/post" 2>&1 || return 1
  FM_N=$(sed -n 's/^ViD github: [a-z]* ticket #\([0-9]*\).*/\1/p' "$T/post"); [ -n "$FM_N" ]; }
fm_team_edit() { sed "$2" "$FAKEGH/issues/$1/body" > "$FAKEGH/issues/$1/body.x" && mv "$FAKEGH/issues/$1/body.x" "$FAKEGH/issues/$1/body" && date -u '+%Y-%m-%dT%H:%M:%SZ' > "$FAKEGH/issues/$1/updated"; }
