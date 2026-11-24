# Purpose: selftest fixture — GitHub manual's toy project (GM-1 S10). Sourced after planner-toy.sh and tickets.sh (Env: CHECKS, T).
# mn_project <dir>: the planner toy there (planner-toy.sh), entered, under git with its spec committed and .vid/ ignored, and no
#   RUN-STATE: the plan block it held kept in $T/plan.blk, its PLAN.md in $T/plan.md; .vid/tw/settings naming the code repository
#   owner/code, the spec repository owner/code-spec and the state repository owner/vid-state, labels vid:, layout separate,
#   slack-channels none; every setup key answered but github-mode (GM-2 §5's issue-form, issue-parent and plan-page among them, no key written); the code repository and the fake gh (tickets.sh), the spec
#   repository made private on it; AP the spec's commit; $T/review a review pass that finds nothing; the write log emptied
# mn_ticket <n> <step> <kind> <row>…: ticket n's writing, in the writer's form, printed: its header (its stage its first row's,
#   as the writer writes it, or $MN_STAGE), the step, each row quoted
#   from INVENTORY.md as the writer quotes it (`> <its line>`, then its marks), the asks
# mn_body <row>…: an issue body in a project's own form, naming the rows, printed
# mn_switch [<mode.sh argument>…]: sh checks/mode.sh manual with $T/register, $T/plan.blk, $T/plan.md and $T/review; MN_RC its
#   exit, $T/mo its output
# mn_state: the state repository's address; mn_lock: its lock's commit, or nothing when the lock is free
mn_project() {
  pt_toy "$1"; awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md > "$T/plan.blk"
  cp PLAN.md "$T/plan.md"; rm -rf .vid; printf '.vid/\n' > .gitignore
  git init -q; git config user.email vid@selftest; git config user.name vid; git add -A; git commit -qm 'the spec'; AP=$(git rev-parse HEAD)
  mkdir -p .vid/tw .vid/plan
  printf 'repo: owner/code\nspec-repo: owner/code-spec\nstate-repo: owner/vid-state\nlabels-prefix: vid:\nlayout: separate\nsplit: journey\nslack-channels: none\n' > .vid/tw/settings
  for k in layout team split repo spec-repo slack-channels state-repo issue-form issue-parent plan-page; do printf 'setup-answered key=%s value="the toy" words="the toy, answered" at=2026-11-03T09:00:00Z\n' "$k"; done > .vid/plan/setup
  tk_code; gh_fake; { gh repo create owner/code-spec --private > /dev/null 2>&1 || :; }; printf 'none\n' > "$T/review"; gh_wclear
}
mn_ticket() {
  _n=$1; _s=$2; _k=$3; shift 3
  # GM-3 S2: the header's stage as the writer writes it, its first row's (planner.sh rows), or $MN_STAGE when set
  _g=${MN_STAGE:-$(sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' -v r="$1" '$1 == r { print $5; exit }')}
  printf '# Step ticket %s: the toy step\n\n## Header\n\n- number: %s\n- kind: %s\n- step: %s\n- stage: %s\n- plan: toyplan\n- base: none\n- export: toyexport\n- rows: %s\n\n## The step\n\n> step %s of the toy plan\n\n## Rows\n\n' "$_s" "$_n" "$_k" "$_s" "${_g:-1}" "$*" "$_s"
  for _r; do awk -F'|' -v r="$_r" 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } { k = tr($1); id = (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr($2) : k } id == r { print "> " $0; exit }' INVENTORY.md
    printf -- '- %s marks: none\n' "$_r"; done
  printf '\n## Asks\n\n- Claim it when you start: a comment, vid: claimed.\n'; }
mn_body() { printf '## What this delivers\n\nThe team'"'"'s own form, written by hand.\n\n## Tests\n\n'; for _r; do printf -- '- %s\n' "$_r"; done; }
mn_switch() { MN_RC=0; sh "$CHECKS/mode.sh" manual --register "$T/register" --plan "$T/plan.blk" --plan-md "$T/plan.md" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
mn_state() { gh repo view owner/vid-state --json url --jq .url; }
mn_lock() { git ls-remote "$(mn_state)" refs/heads/vid-state/lock | cut -f1; }
# mn_takeover <dir>: GM-3 S2's toy, made like a project whose tickets a stand-in writer wrote from a scratch copy, entered there:
#   the copy, $T/copy, the planner's toy with three rows more (ROW-022, a tab inside its line, ROW-023 and ROW-025, $MN_R22,
#   $MN_R23 and $MN_R25) and its plan block in its RUN-STATE: S02 holding ROW-022 and ROW-023, ROW-002 and ROW-018 out of S04
#   into S06, which builds on S05 (stage 2) and whose needs line names S05, ROW-010 out of S03 into S04, whose rows and needs
#   line name the range ROW-009..ROW-011 (the needs line's joined to the next row by a comma), S07 holding ROW-025 alone,
#   built on S02, S05 building on S07, faking S02 and its needs line naming S07, every lane Alpha-1; the project (mn_project) with the team Alpha in capitals in its settings, ROW-025 added, then
#   ROW-011 and ROW-025 retired and PLAN.md removed, committed: $MN_H, the tickets' commit; three tickets written from the copy
#   and posted, #$MN_N1 S01 the skeleton, #$MN_N2 S02 quoting ROW-001, ROW-022 (less its module: field, as the writer cuts it)
#   and ROW-023, #$MN_N3 S06 its header of stage 2, each a line of $T/register, their writings in $T/t1, $T/t2 and $T/t3; then
#   ROW-024 added ($MN_R24), and ROW-023 added and retired, each its own commit, on a side branch merged back by a merge commit
#   whose INVENTORY.md is its first parent's; the write log emptied
mn_takeover() {
  mn_project "$1"; _p=$PWD
  MN_R22="ROW-022 | behavior | REQ-001 | anonymous |$(printf '\t')"'n/a | A digest names the saved search it was built for. Fails if a digest does not name its saved search. | REQ-001 | owed: spec-only — first stage | origin: REQ-001 | module: digest'
  MN_R23='ROW-023 | behavior | REQ-001 | anonymous | n/a | A digest lists its jobs newest first. Fails if a digest lists an older job above a newer one. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
  MN_R24='ROW-024 | behavior | REQ-006 | anonymous | n/a | The page of saved searches shows how many of the ten are kept. Fails if the count shown differs from the searches kept. | REQ-006 | owed: spec-only — first stage | origin: REQ-006'
  MN_R25='ROW-025 | behavior | REQ-001 | anonymous | n/a | A digest sent on a holiday holds that day'"'"'s jobs. Fails if a holiday'"'"'s jobs are missing from its digest. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
  pt_toy "$T/copy"; pt_after ROW-020 "$MN_R22"; pt_after ROW-022 "$MN_R23"; pt_after ROW-023 "$MN_R25"
  pt_rs 's/^\(step S02 .*rows: ROW-001 \)/\1ROW-022 ROW-023 /; s/^needs ROW-001 /needs ROW-001 ROW-022 ROW-023 /'
  pt_rs 's/^\(step S04 .*rows: \)ROW-002 \(ROW-009 ROW-011 \)ROW-018 /\1\2/; s/^needs ROW-002 ROW-009 ROW-011 ROW-018 /needs ROW-009 ROW-011 /; s/lane: devagent/lane: Alpha-1/'
  pt_rs 's/^\(step S03 .*rows: ROW-006 ROW-007 \)ROW-010 /\1/; s/^needs ROW-006 ROW-007 ROW-010 /needs ROW-006 ROW-007 /; s/^\(step S04 .*rows: \)ROW-009 ROW-011 /\1ROW-009..ROW-011 /; s/^needs ROW-009 ROW-011 /needs ROW-009..ROW-011,/'
  pt_rs 's/^\(step S05 .*builds-on: \)S02 /\1S07 /; s/^\(step S05 .*\)$/\1 | fakes: S02/; s/^needs ROW-017 | -$/needs ROW-017 | S07/'
  awk '{ print } /^step S05 / { print "step S06 | name: the limit and the failure log | modules: digest | builds-on: S05 | rows: ROW-002 ROW-018 | lane: Alpha-1" }
    /^step S04 / { print "step S07 | name: the holiday digest | modules: digest | builds-on: S02 | rows: ROW-025 | lane: Alpha-1" }
    /^needs ROW-009\.\.ROW-011,/ { print "needs ROW-025 | -" }
    /^needs ROW-017 / { print "needs ROW-002 ROW-018 | S05" }' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x
  MN_N1=$(gh_issue 'Skeleton'); mn_ticket "$MN_N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$MN_N1" "$T/t1" comments 2
  MN_N2=$(gh_issue 'Step S02'); mn_ticket "$MN_N2" S02 step ROW-001 ROW-022 ROW-023 | sed "/^> ROW-022 /s/ | module: digest\$//" > "$T/t2"; gh_writing "$MN_N2" "$T/t2" body 2
  MN_STAGE=2; MN_N3=$(gh_issue 'Step S06'); mn_ticket "$MN_N3" S06 step ROW-002 ROW-018 > "$T/t3"; unset MN_STAGE; gh_writing "$MN_N3" "$T/t3" comments 2
  cd "$_p"; printf '%s S01\n%s S02\n%s S06\n' "$MN_N1" "$MN_N2" "$MN_N3" > "$T/register"; pt_teams 'Alpha | the whole product | core | 2'
  _ia() { awk -v a="$1" -v l="$2" '{ print } index($0, a " ") == 1 { print l }' INVENTORY.md > I.x && mv I.x INVENTORY.md; }
  _ia ROW-020 "$MN_R25"; git commit -qam 'ROW-025 added'
  grep -v -e '^ROW-011 ' -e '^ROW-025 ' INVENTORY.md > I.x && mv I.x INVENTORY.md; git rm -q PLAN.md; git commit -qam 'ROW-011 and ROW-025 retired, PLAN.md gone'; MN_H=$(git rev-parse HEAD)
  _ia ROW-020 "$MN_R24"; git commit -qam 'ROW-024 added after the tickets were written'
  _b=$(git symbolic-ref --short HEAD); git checkout -qb mn-side
  _ia ROW-020 "$MN_R23"; git commit -qam 'ROW-023 added'; grep -v '^ROW-023 ' INVENTORY.md > I.x && mv I.x INVENTORY.md; git commit -qam 'ROW-023 retired'
  git checkout -q "$_b"; git merge -q --no-ff -m 'the side branch merged' mn-side; git branch -qD mn-side
  gh_wclear; }
# mn_replan_toy <dir>: GM-3 U7, GM-2 T11's toy (fixtures/form.sh's fm_toy, sourced here when it is not yet) with phase 3's pending
#   changes, entered there. Each change to the spec goes through the real door, a draft (land.sh draft, a review that finds nothing)
#   and the owner's yes (land.sh <n> --words); the to-place row is then made as an apply leaves it, by records. In order:
#   - ROW-022 drafted (1) and landed; the applied commit moved to the landing, ROW-022 on the to-place list as no-step in the
#     owner's words, the plan ratified again: the to-place row;
#   - S02 posted as #$MN_N2 and S03 as #$MN_N3 (form.sh's fm_post); stage 2's named candidate, its ask the open issue #$MN_NW;
#   - draft 2, a /vid fix, landed: ROW-012 reworded (a pending reset, in #MN_N2), ROW-021 added ($MN_R21, a pending addition) and
#     ROW-019 deleted (a pending retirement, in #MN_N3);
#   - draft 3, a /vid stage re-cut, landed: ROW-002 to stage 2 (STAGES.md's split line of its REQ-006, a row line alone being refused, the owner's answer row in PRD.md), a landed
#     re-cut (pending moved-stage ROW-002, spec STAGES.md), which withdraws stage 2's candidate (#MN_NW in .vid/next/withdrawn);
#   then the call's read kept (next.sh read). MN_AP the applied commit, MN_H HEAD. Returns 1 on the first step that fails, its
#   output in $T/mr
mn_replan_toy() {
  command -v fm_toy > /dev/null 2>&1 || . "$CHECKS/selftest/fixtures/form.sh"
  fm_toy "$1" > "$T/mr" 2>&1 || return 1; printf 'none\n' > "$T/mrv"
  _mi() { awk -v l="$2" -v a="$1" '{ print } index($0, a " ") == 1 && !d { print l; d = 1 }' INVENTORY.md > "$T/mi" && cat "$T/mi" > INVENTORY.md; }
  _ml() { sh "$CHECKS/land.sh" draft --review "$T/mrv" --why "$1" > "$T/mr" 2>&1 || return 1; _d=$(sed -n 's/^draft \([0-9][0-9]*\)$/\1/p' "$T/mr")
    [ -n "$_d" ] && sh "$CHECKS/land.sh" "$_d" --words "$2" > "$T/mr" 2>&1; }
  _mi ROW-020 'ROW-022 | behavior | REQ-001 | anonymous | n/a | A saved search shows how many jobs its last digest held. Fails if the count is missing. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
  _ml '/vid add: a saved search shows its last digest size, in the owner words' 'Yes, land the digest size' || return 1
  MN_AP=$(git rev-parse HEAD); printf '%s\n' "$MN_AP" > .vid/tw/applied
  printf 'ROW-022\tno-step\t2026-11-19T10:00:00Z\tleave ROW-022 to place for now\n' > .vid/tw/to-place
  tw_ratify 'Yes, publish it' || return 1
  fm_post S02 || { cp "$T/post" "$T/mr"; return 1; }; MN_N2=$FM_N
  fm_post S03 || { cp "$T/post" "$T/mr"; return 1; }; MN_N3=$FM_N
  MN_NW=$(gh_issue 'Stage 2, candidate 1'); mkdir -p .vid/decide/stage/2/1; printf 'issue\t%s\n' "$MN_NW" > .vid/decide/stage/2/1/ask; : > .vid/decide/stage/2/1/named
  sed 's/at the stated size of 10,000 active jobs/at the stated size of 20,000 active jobs/' INVENTORY.md > "$T/mi" && cat "$T/mi" > INVENTORY.md
  MN_R21='ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
  _mi ROW-020 "$MN_R21"; grep -v '^ROW-019 ' INVENTORY.md > "$T/mi" && cat "$T/mi" > INVENTORY.md
  _ml '/vid fix: the size, the digest day and the footer row, in the owner words' 'Yes, land the fix' || return 1
  awk '{ print } /^row: ROW-004 -> STAGE-0$/ { print "split: REQ-006 -> STAGE-2" }' STAGES.md > "$T/mi" && cat "$T/mi" > STAGES.md
  { cat PRD.md; printf '\n### 2026-11-20 (the self-test)\n\n```vid-prd-answers\nA-301 | human | 2026-11-20 | Q: how should the product be delivered — in which stages? | A: the digest limit waits for stage 2 | settles: contract\n```\n'; } > "$T/mi" && cat "$T/mi" > PRD.md
  _ml '/vid stage: the digest limit moves to stage 2, in the owner words' 'Yes, move the limit to stage 2' || return 1
  MN_H=$(git rev-parse HEAD); sh "$CHECKS/next.sh" read > "$T/mr" 2>&1 || return 1; gh_wclear; }
