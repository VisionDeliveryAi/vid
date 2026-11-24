# Purpose: selftest fixture — pull requests with changes, for ViD's own review (FB-3 A1.4, A1.6). Sourced after a toy with $T/dev, the
# dev clone of the fake gh's owner/code (Env: CHECKS, T).
# rv_pr merge|squash <branch> <description> [<file> <content>]…: a branch off main with those files in one commit, its pull request
#   merged (a merge commit, or one commit on main as a squash makes it, the branch's head then no ancestor of main); its number in
#   RV_P, its merge commit in RV_M; the dev clone's main brought up to it
# rv_pr_open <branch> <description> [<file> <content>]…: the same, left open
# rv_objects: every object of .vid/code, its type, sorted
rv_branch() { _b=$1; shift; ( cd "$T/dev" && git checkout -q -B "$_b" main && while [ $# -ge 2 ]; do mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; git add "$1"; shift 2; done
  g commit -q --allow-empty -m "$_b" && git push -q -f origin "$_b" 2>/dev/null && git checkout -q main ); RV_H=$(git -C "$T/dev" rev-parse "$_b"); }
rv_pr_open() { _d=$2; _n=$1; shift 2; rv_branch "$_n" "$@"; RV_P=$(gh pr create -R owner/code --head "$_n" --base main --title "$_n" --body "$_d" | sed 's#.*/##'); }
rv_pr() { _how=$1; shift; rv_pr_open "$@"
  if [ "$_how" = merge ]; then gh pr merge "$RV_P" -R owner/code --merge --match-head-commit "$RV_H" > /dev/null; ( cd "$T/dev" && git pull -q origin main 2>/dev/null )
  else ( cd "$T/dev" && git merge -q --squash "$1" > /dev/null 2>&1 && g commit -q --allow-empty -m "$1 (#$RV_P)" && git push -q origin main 2>/dev/null )
    git -C "$T/dev" rev-parse main > "$FAKEGH/prs/$RV_P/merge"; printf '%s\n' "$RV_H" > "$FAKEGH/prs/$RV_P/headoid"; echo MERGED > "$FAKEGH/prs/$RV_P/state"; fi
  RV_M=$(git -C "$T/dev" rev-parse main); }
rv_objects() { git --git-dir=.vid/code cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' | sort; }
