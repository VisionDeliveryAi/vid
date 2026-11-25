# Purpose: selftest fixture — asks on a step's own pull request in GitHub manual (FB-5 B1), on GitHub manual's toy and the fake gh
# (fixtures/accept.sh, sourced here). Env: CHECKS, T.
# ap_pull <branch> <description> [<file>]: a pull request from a branch of its own off main (its file <branch>.txt, or <file>); its number
#   AP_P, its head AP_H, that head's 12 characters AP_h. ap_push <branch>: one commit more on it, AP_H and AP_h its head
# ap_ask <pull request> <words after `vid: decide `>: the team's ask there. ap_replies <n>: how many `vid: decision` comments the issue or
#   pull request n holds. ap_lastp <n>: the newest comment of issue or pull request n
# ap_rep <pull request> <commit> [<k>] [<case>…]: a report by anyone, pr-<p>-<commit12>-<k>, its cases (by default both rows passing)
# ap_squash <pull request>: merged by GitHub as one commit on main, AP_M (its description's `Closes #<n>` closes the issue). ap_merge <pull
#   request>: the same by a merge commit. ap_child <parent>: a sub-issue of it, its number
. "$CHECKS/selftest/fixtures/accept.sh"
ap_dir() { if [ -d "$FAKEGH/prs/$1" ]; then echo "$FAKEGH/prs/$1"; else echo "$FAKEGH/issues/$1"; fi; }
ap_pull() { ( cd "$T/dev" && git checkout -q -B "$1" main && echo "$1" > "${3:-$1.txt}" && git add -A && g commit -q -m "$1" && git push -q -f origin "$1" 2>/dev/null && git checkout -q main )
  AP_H=$(git -C "$T/dev" rev-parse "$1"); AP_h=$(printf %.12s "$AP_H"); AP_P=$(gh pr create -R owner/code --head "$1" --base main --title "$1" --body "$2" | sed 's#.*/##'); }
ap_push() { ( cd "$T/dev" && git checkout -q "$1" && echo more >> "$1.txt" && git add -A && g commit -q -m "$1, more" && git push -q origin "$1" 2>/dev/null && git checkout -q main ); AP_H=$(git -C "$T/dev" rev-parse "$1"); AP_h=$(printf %.12s "$AP_H"); }
ap_ask() { printf 'vid: decide %s\nby: A. Person\n' "$2" > "$T/apc"; gh pr comment "$1" -R owner/code --body-file "$T/apc" > /dev/null; }
ap_replies() { _c=0; for _f in $(ls "$(ap_dir "$1")/comments" 2>/dev/null); do ! head -n 1 "$(ap_dir "$1")/comments/$_f" | grep -q '^vid: decision ' || _c=$((_c + 1)); done; echo "$_c"; }
ap_lastp() { _d=$(ap_dir "$1")/comments; cat "$_d/$(ls "$_d" | sort -n | tail -n 1)"; }
ap_rep() { _p=$1; _c=$2; _k=${3:-1}; shift 2; [ $# -eq 0 ] || shift; [ $# -gt 0 ] || set -- ROW-001=pass ROW-012=pass; ac_report "pr-$_p-$(printf %.12s "$_c")-$_k" 'A. Person' "$_c" "cases.xml=$*"; }
ap_squash() { _h=$(git -C "$T/code.git" rev-parse "refs/heads/$(cat "$FAKEGH/prs/$1/head")")
  ( cd "$T/dev" && git pull -q origin main 2>/dev/null; git merge -q --squash "$(cat "$FAKEGH/prs/$1/head")" > /dev/null 2>&1 && g commit -q -m "the squash of #$1" && git push -q origin main 2>/dev/null ) || return 1
  AP_M=$(git -C "$T/dev" rev-parse main); echo "$AP_M" > "$FAKEGH/prs/$1/merge"; echo "$_h" > "$FAKEGH/prs/$1/headoid"; echo MERGED > "$FAKEGH/prs/$1/state"
  for _i in $(grep -oiE 'closes #[0-9]+' "$FAKEGH/prs/$1/body" | grep -oE '[0-9]+'); do echo CLOSED > "$FAKEGH/issues/$_i/state"; done; }
ap_merge() { gh pr merge "$1" -R owner/code --merge --body x > /dev/null || return 1; ( cd "$T/dev" && git pull -q origin main 2>/dev/null ); AP_M=$(git -C "$T/dev" rev-parse main); }
ap_child() { _k=$(gh_issue 'a piece'); gh_sub "$1" "$_k"; echo "$_k"; }
