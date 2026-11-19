# Purpose: selftest fixture — GitHub manual's toy project (GM-1 S10). Sourced after planner-toy.sh and tickets.sh (Env: CHECKS, T).
# mn_project <dir>: the planner toy there (planner-toy.sh), entered, under git with its spec committed and .vid/ ignored, and no
#   RUN-STATE: the plan block it held kept in $T/plan.blk, its PLAN.md in $T/plan.md; .vid/tw/settings naming the code repository
#   owner/code, the spec repository owner/code-spec and the state repository owner/vid-state, labels vid:, layout separate,
#   slack-channels none; every setup key answered but github-mode; the code repository and the fake gh (tickets.sh), the spec
#   repository made private on it; AP the spec's commit; $T/review a review pass that finds nothing; the write log emptied
# mn_ticket <n> <step> <kind> <row>…: ticket n's writing, in the writer's form, printed: its header, the step, each row quoted
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
  for k in layout team split repo spec-repo slack-channels state-repo; do printf 'setup-answered key=%s value="the toy" words="the toy, answered" at=2026-11-03T09:00:00Z\n' "$k"; done > .vid/plan/setup
  tk_code; gh_fake; { gh repo create owner/code-spec --private > /dev/null 2>&1 || :; }; printf 'none\n' > "$T/review"; gh_wclear
}
mn_ticket() {
  _n=$1; _s=$2; _k=$3; shift 3
  printf '# Step ticket %s: the toy step\n\n## Header\n\n- number: %s\n- kind: %s\n- step: %s\n- stage: 1\n- plan: toyplan\n- base: none\n- export: toyexport\n- rows: %s\n\n## The step\n\n> step %s of the toy plan\n\n## Rows\n\n' "$_s" "$_n" "$_k" "$_s" "$*" "$_s"
  for _r; do awk -F'|' -v r="$_r" 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } { k = tr($1); id = (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr($2) : k } id == r { print "> " $0; exit }' INVENTORY.md
    printf -- '- %s marks: none\n' "$_r"; done
  printf '\n## Asks\n\n- Claim it when you start: a comment, vid: claimed.\n'; }
mn_body() { printf '## What this delivers\n\nThe team'"'"'s own form, written by hand.\n\n## Tests\n\n'; for _r; do printf -- '- %s\n' "$_r"; done; }
mn_switch() { MN_RC=0; sh "$CHECKS/mode.sh" manual --register "$T/register" --plan "$T/plan.blk" --plan-md "$T/plan.md" --review "$T/review" "$@" > "$T/mo" 2>&1 || MN_RC=$?; }
mn_state() { gh repo view owner/vid-state --json url --jq .url; }
mn_lock() { git ls-remote "$(mn_state)" refs/heads/vid-state/lock | cut -f1; }
