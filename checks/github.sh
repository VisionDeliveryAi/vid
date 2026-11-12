#!/bin/sh
# Purpose: ViD's GitHub adapter (v0.26.10.9 spec R19, R22–R24) — the one file that calls `gh`, for ticket mode. Every
# call goes through `gh` under the login of whoever runs it: it never asks for, prints, passes or stores a token. The
# first act of every subcommand is `gh auth status`; a failing one stops it. The calls are an allow-list (ghc below):
# gh auth status, gh repo view, gh label create, gh issue create|edit|view|list|comment|close, gh pr view|list|comment,
# gh repo create (v0.26.10.12.3 R2: TW's spec-repo: alone, --private, spec-setup only), and gh api only for the
# milestone endpoints (repos/<repo>/milestones…) and an issue comment's edit (-X PATCH repos/<the code
# repository>/issues/comments/<id>, tw-post's amendment, fix 3). 0.26.10.28.1 (9.1 C1, stage 9 S2): the first ticket
# mode's subcommands (publish, pull, run-full, session, clone, next-ticket, claim, push, review, merge) are removed,
# with the calls only they made. The code repository is the vid-code block's repo: (ARCHITECTURE.md), else
# .vid/tw/settings' repo:.
# 0.26.10.28.7 (R6): the share, a run's logs sent to a private repository in the user's own account or an organisation they
# own, in every mode (no ticket-mode setting read). Each share subcommand reads the login first; the repository is read
# private and owned before every write, a read that fails a refusal; its commits are authored and committed as ViD
# <vid@export.invalid>, as spec-export's. The calls it adds, each tied to the share repository (SREPO), the login (LOGIN)
# or the one account the user named to invite (WHO): gh api user; gh repo create <SREPO> --private, in share-create
# alone (SCREATE set there alone); gh api users/<WHO> (a read, the name in GitHub's login form, nothing after it); gh api
# orgs/<the repository's owner>/memberships/<LOGIN>; gh api repos/<SREPO>/collaborators/<WHO> (its read, and -X PUT,
# the invitation); gh api repos/<SREPO>/invitations (a read). Whether a run's folder is in the repository already is read
# by git from the fetched main, with no call.
#   share-login  the login, printed; a failing gh auth status says so (exit 1): the bundle stays a file
#   share-create --repo <owner>/<name>   the owner is the login, or an organisation the login is an owner of; made
#                `--private` when missing, or used as it is when private and owned so; then read private and owned
#   share-push --repo <r> --project <p> --run <n> <folder>   runs share.sh scan on the folder (beside this file) and
#                refuses on anything left, with no call after gh auth status; then the repository read private and owned;
#                the folder's files at projects/<p>/<n>/ on main, a fast-forward, never over a run folder already there
#   share-invite --repo <r> --who <login> --shown-write-words --second-yes   refused without either flag, which the skill
#                passes only once it showed the write-access words and the user said yes to invite; the repository read
#                private and owned; on a personal account's repository a person only (an account that reads as an
#                organisation refused); on an organisation's, the person with the Read role; a collaborator, or one
#                invited and pending, not invited again
# The ticket writer's subcommands (v0.26.10.12.3 R2, R7–R9; ViD's repository; repo:, spec-repo:
# and labels-prefix: read from .vid/tw/settings; each act a line of .vid/tw/log):
#   spec-setup   spec-repo: made private when missing (`gh repo create <it> --private`; `spec-repo <name> created`) or
#                checked private (`spec-repo <name> exists`; a public one refused); then spec-export. v0.26.10.26.7 (R12):
#                `spec-setup --make-only` stops before the export, for /vid run's start: the first export is round.sh next's.
#   spec-export  one commit of exactly PRD.md, DECISIONS.md, BASELINE.md, ARCHITECTURE.md, design/, GRADING-CHECKLIST.md
#                and TEST-DIFFERENCES.md (INVENTORY.md's difference lines, verbatim) at ViD's HEAD, a path not there
#                named and left out, built in a temporary index and .vid/spec.git (borrowing ViD's objects), authored and
#                committed as ViD <vid@export.invalid>, a fast-forward of the spec repository's main only; `export <c>
#                from=<ViD commit> state=pushed`, or `state=unchanged` when the tree is main's already (nothing pushed).
#   tw-sync      `sync main=<the code repository's main, git ls-remote> open=<TW's open tickets>` (each published one's
#                issue state). v0.26.10.28.2 (R3): main=none for an empty repository alone, main=absent for heads with no main; a failed read
#                is refused and records nothing.
#   decide-blocked <issue> <pr>, decide-post <pr> <file>   v0.26.10.24.6: the blocked label, and the decision's comment, for checks/decide.sh
#   results-fetch   v0.26.10.24.5: .vid/code, the copy checks/results.sh reads: 0.26.10.28.4 (M5), the vid-results/* reports and every other head's commits, no file of the code;
#                0.26.10.28.1 (S5): a working clone found there is moved aside to .vid/code.old-<UTC>, saying so, and the bare copy cloned
#   tw-post [--amend <n>] <ticket>   refused when writer.sh check refuses it, writer.sh fresh finds it stale (the plan,
#                the export or its ticket work moved since it was written) or its export is not the spec repository's
#                main at ViD's HEAD; else an issue labelled <prefix>ticket (a placeholder, then the body and comments of
#                writer.sh parts), or issue n's body replaced, a comment naming the amendment, and each earlier writing's
#                part comment edited to say it is replaced, naming the current writing and its part comments (fix 3);
#                `published|amended <n> <the meta's fields> parts= at=`, then `sent <row> ticket=<n> hash=<h>` per row.
#   tw-close <n> a withdrawal writer.sh due owes, the issue commented and closed as not planned: by a plan change, its comment
#                naming the newest change (`withdrawn <n> decision=<id>`), or, 0.26.10.28.6 (R2), a fix ticket whose rows were all ruled
#                known limits, its comment saying so (`withdrawn <n> decision=known-limit rows=<rows>`).
#   tw-outside <n>  a published ticket closed outside ViD, read once: withdrawn (`withdrawn <n> decision=closed-outside`), or nothing changed.
# The planner's setup (v0.26.10.12.3.1 R3), read only — gh auth status and gh repo view alone:
#   access       one line each: `access gh — signed in` (or not, then it stops); for repo: and, with layout: separate
#                (the default), spec-repo: of .vid/tw/settings — not set yet, reached (its permission, private or
#                public; a public spec repository is not ready) or not reached (gh's words); then `access: ok`, or
#                `access: <n> of <m> not ready`. Exit 0; 2 on a usage error. It never creates, edits or pushes.
# The planner's subcommands (ViD's repository; they write only labels, comments and milestones):
#   comment <issue> --body-file <f>   (`ticket … state=commented` for a ticket) · label <issue> [--add <l>]…
#                [--remove <l>]… (the prefix added) · close <issue> | close --milestone <stage> --commit <sha>
#                (the milestone's description names the commit; `milestone … state=closed commit=`).
# Usage, one line a group (the usage message says the same):
#   sh checks/github.sh access
#   sh checks/github.sh spec-setup [--make-only] | spec-export
#   sh checks/github.sh tw-sync | tw-post [--amend <n>] <ticket> | tw-outside <n> | tw-close <n>
#   sh checks/github.sh decide-blocked <issue> <pr> | decide-post <pr> <file> | results-fetch | round-read
#   sh checks/github.sh deploy-ask|grade-ask --stage <N> --commit <c> --title <t> --body-file <f> | run-ask --step <s> --commit <c> --title <t> --body-file <f>
#   sh checks/github.sh state-save | state-restore [<repo>] | lock-take [<session>] | lock-renew | lock-free
#   sh checks/github.sh comment <issue> --body-file <f> | label <issue> [--add <l>]… [--remove <l>]… | close <issue> | close --milestone <stage> --commit <sha>
#   sh checks/github.sh share-login | share-create --repo <owner/name> | share-push --repo <owner/name> --project <p> --run <n> <folder> | share-invite --repo <owner/name> --who <login> --shown-write-words --second-yes
# serves: both (0.26.10.28.7, R6: the share works in every mode; tickets before it)
set -u
IFS='
'
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"   # 0.26.10.28.4 (9.3 R3): the shared helpers, lib.sh beside this file
usage() { sed -n '/^# Usage, one line a group/,/^set -u/p' "$0" | sed '1d;$d;s/^#   /    /' | { echo 'ViD github: usage —'; cat; } >&2; exit 2; }
gref() { echo "ViD github: refused — $*" >&2; exit 1; }
# putd <folder> <copy>: a folder replaced in four steps — the copy beside it as .put.$$.<name>, the live one aside as .old.$$.<name>,
# the copy in, the old one removed; a step that fails stops it with the live folder whole (v0.26.10.28.1, R6)
putd() { _q=$(dirname "$1")/.put.$$.$(basename "$1"); _o=$(dirname "$1")/.old.$$.$(basename "$1"); rm -rf "$_q" && cp -R "$2" "$_q" || { rm -rf "$_q"; return 1; }
  if [ -e "$1" ]; then mv "$1" "$_o" || { rm -rf "$_q"; return 1; }; fi; mv "$_q" "$1" || { [ ! -e "$_o" ] || mv "$_o" "$1"; rm -rf "$_q"; return 1; }; rm -rf "$_o"; }
# a state-restore stopped between its two renames left .vid/.old.<pid>.<name> and no live folder: it is renamed back first
for _o in .vid/.old.*.decide .vid/.old.*.tw .vid/.old.*.plans .vid/.old.*.plan .vid/.old.*.results; do [ -d "$_o" ] && [ ! -e ".vid/${_o##*.}" ] || continue; mv "$_o" ".vid/${_o##*.}"; done
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
REPO=''; SHARE=''; SCREATE=''   # 0.26.10.28.7: the share's allow-list switches never come from the environment
# one read a tick (R3): the same three reads as DevAgent's dm.sh next, its own copy
RPQ='.[] | [.number, .headRefName, .isDraft, .headRefOid, ([.labels[].name] | join(",")), (.body | split("\n") | .[0]), ([.comments[].body | split("\n") | .[0]] | join("\u0001")), (([.comments[] | select(.body | startswith("vid: decision "))] | last | .body) // ""), .updatedAt] | @tsv'
RMQ='.[] | [.number, .headRefOid, (.mergeCommit.oid // "-"), (.body | split("\n") | .[0]), ([.comments[].body | split("\n") | .[0]] | join("\u0001"))] | @tsv'
RIQ='.[] | [.number, ([.labels[].name] | join(",")), ([.comments[].body | split("\n") | .[0]] | join("\u0001")), .updatedAt] | @tsv'
# ghc: the one way to call gh — the allow-list, checked at every call
ghc() {
  case "$1 ${2:-}" in
    'auth status'|'repo view'|'label create'|'issue create'|'issue edit'|'issue view'|'issue list'|'issue comment'|'issue close'|'pr view'|'pr list'|'pr comment') ;;
    'repo create')   # v0.26.10.12.3 (R2, main's 7147906): the spec repository alone, private, and only in spec-setup; 0.26.10.28.7 (R6): or the share repository alone, private, in share-create
      if [ "${SHARE:-}" = yes ]; then [ "${SCREATE:-}" = yes ] && [ -n "${SREPO:-}" ] && [ "${3:-}" = "$SREPO" ] && [ "${4:-}" = --private ] && [ $# -eq 4 ] || gref "gh repo create is allowed for the share repository alone, --private, in share-create"
      else [ "${SPECSETUP:-}" = yes ] && [ -n "${SPEC:-}" ] && [ "${3:-}" = "$SPEC" ] && [ "${4:-}" = --private ] && [ $# -eq 4 ] || gref "gh repo create is allowed for TW's spec-repo: alone, --private, in spec-setup"; fi ;;
    api\ *) _p=''; _s=''; _m=''; for _a in "$@"; do if [ -n "$_s" ]; then [ "$_s" = X ] && _m=$_a; _s=''; continue; fi; case "$_a" in -X) _s=X ;; -f|-F|--jq) _s=1 ;; api) ;; *) _p=$_a ;; esac; done
      # 0.26.10.28.7 (R6): the share's reads and its one write, each tied to SREPO, LOGIN or WHO, and only inside a share subcommand
      if [ "${SHARE:-}" = yes ]; then
        # each argument one of the share's exact forms: --jq <q>, --paginate, -X PUT, -f permission=pull, and one path; anything else
        # (--method, an attached -X…, a field, --input) is refused, since a field makes gh api a POST
        _p=''; _m=''; _f=''; _g=''; _s=''; for _a in "$@"; do if [ -n "$_s" ]; then case "$_s" in X) [ "$_a" = PUT ] || gref "gh api in a share subcommand takes -X PUT alone"; _m=PUT ;; f) [ "$_a" = permission=pull ] || gref "gh api in a share subcommand takes -f permission=pull alone"; _f=yes ;; esac; _s=''; continue; fi
          case "$_a" in api) ;; -X) _s=X ;; -f) _s=f ;; --jq) _s=q ;; --paginate) _g=yes ;; -*) gref "gh api in a share subcommand does not take $_a" ;; *) [ -z "$_p" ] || gref 'gh api in a share subcommand takes one path'; _p=$_a ;; esac; done
        [ -z "$_s" ] || gref "gh api in a share subcommand: an option with no value"
        case "$_p" in repos/*/collaborators/*) [ -z "$_f" ] || [ "$_m" = PUT ] || gref "a field is taken only by the invitation" ;; *) [ -z "$_f" ] || gref "a field is taken only by the invitation" ;; esac
        case "$_p" in repos/*/invitations) ;; *) [ -z "$_g" ] || gref "--paginate is taken only by the invitations read" ;; esac
        case "$_p" in
        user) [ -z "$_m" ] || gref "gh api user is a read" ;;
        users/*) [ -z "$_m" ] && lform "${WHO:-}" && [ "$_p" = "users/$WHO" ] || gref "gh api users/<name> is allowed only as a read of the one account the user named to invite, in GitHub's login form, with nothing after it" ;;
        orgs/*) [ -z "$_m" ] && [ -n "${SOWN:-}" ] && [ -n "${LOGIN:-}" ] && [ "$_p" = "orgs/$SOWN/memberships/$LOGIN" ] || gref "gh api orgs/ is allowed only as a read of your membership of the share repository's owner" ;;
        repos/*/collaborators/*) [ -n "${SREPO:-}" ] && lform "${WHO:-}" && [ "$_p" = "repos/$SREPO/collaborators/$WHO" ] && { [ -z "$_m" ] || [ "$_m" = PUT ]; } || gref "gh api on a collaborator is allowed only on the share repository, for the one account named, as a read or -X PUT" ;;
        repos/*/invitations) [ -n "${SREPO:-}" ] && [ "$_p" = "repos/$SREPO/invitations" ] && [ -z "$_m" ] || gref "gh api on invitations is allowed only as a read of the share repository's" ;;
        *) gref "gh api in a share subcommand is allowed for the share's own calls only, not '$_p'" ;; esac
      else
      case "$_p" in "repos/$REPO/milestones"|"repos/$REPO/milestones/"[0-9]*) ;; "repos/$REPO/issues/comments/"[0-9]*) case "${_p##*/}" in *[!0-9]*) gref "not an issue comment: '$_p'" ;; esac
        [ "$_m" = PATCH ] || gref "gh api on an issue comment is allowed for its edit alone (-X PATCH)" ;; *) gref "gh api is allowed for the milestone, sub-issue and issue comment edit endpoints only, not '$_p'" ;; esac; fi ;;
    *) gref "gh $1 ${2:-} is not on the allow-list" ;;
  esac
  for _a in "$@"; do case "$_a" in token|--with-*) gref 'a token is never asked for, printed, passed or stored' ;; esac; done
  gh "$@"
}
auth() { ghc auth status > "$W/auth" 2>&1 || { sed 's/^/    /' "$W/auth" >&2; gref 'gh auth status fails — log in with gh auth login (ViD never handles a token)'; }; }
codekey() { [ -f ARCHITECTURE.md ] && sed -n '/^```vid-code[[:space:]]*$/,/^```[[:space:]]*$/p' ARCHITECTURE.md | sed -n "s/^$1:[[:space:]]*//p" | head -n 1 | sed 's/[[:space:]]*$//'; }
kv() { printf '%s\n' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -n 1; }
num_of_url() { sed -n 's#.*/\([0-9][0-9]*\)$#\1#p' | tail -n 1; }
mapline() { [ -f .vid/tickets/map ] && awk -v w="$1" -v k="$2" -v v="$3" 'function g(x,  i) { for (i = 2; i <= NF; i++) if (index($i, x "=") == 1) return substr($i, length(x) + 2); return "" } $1 == w && g(k) == v { l = $0 } END { print l }' .vid/tickets/map; }
planner() {
  [ -f .vid/RUN-STATE.md ] || gref "the planner's subcommands run in ViD's repository (no .vid/RUN-STATE.md here)"
  REPO=$(codekey repo); PFX=$(codekey labels-prefix); [ -n "$REPO" ] || { REPO=$(twkey repo); PFX=$(twkey labels-prefix); }; [ -n "$REPO" ] || gref "ARCHITECTURE.md's vid-code block names no repo: <owner>/<name>"
  auth
}
devagent() {
  _t=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
  if [ -d "$_t/.vid" ]; then
    if grep -q '^mode:[[:space:]]*tickets' "$_t/.vid/RUN-STATE.md" 2>/dev/null; then gref "DevAgent's subcommands are refused here: this checkout's RUN-STATE says mode: tickets — the planner's repository"; fi
    gref "DevAgent's subcommands are refused in a folder holding ViD's .vid/ — DevAgent works in a plain clone of the code repository"
  fi
  auth
  REPO=$(cat "$(git rev-parse --git-dir 2>/dev/null)/vid/repo" 2>/dev/null)
}
devagent_repo() { [ -n "$REPO" ] || gref "this clone has no .git/vid/repo, which names its repository"; }
GD() { git rev-parse --absolute-git-dir; }
# v0.26.10.12.3 (R2, R7–R9): the ticket writer's — its settings (.vid/tw/settings), its log line
twlog() { mkdir -p .vid/tw; printf '%s\n' "$1" >> .vid/tw/log; }
tw() {
  [ -f .vid/RUN-STATE.md ] || gref "the ticket writer's subcommands run in ViD's repository (no .vid/RUN-STATE.md here)"
  REPO=$(twkey repo); [ -n "$REPO" ] || gref ".vid/tw/settings names no repo: <owner>/<name>"
  SPEC=$(twkey spec-repo); PFX=$(twkey labels-prefix); auth
}
# codemain (v0.26.10.28.2, R3): the code repository's main as git ls-remote reads it, its commit; `none` when the read succeeds and lists no head at all, an empty
# repository; `absent` when it lists heads but no main; a failed read returns 1 and says nothing. codemain <its address> reads that address, no gh call
codemain() { _u=${1:-}; [ -n "$_u" ] || { _u=$(ghc repo view "$REPO" --json url --jq .url 2>/dev/null) && [ -n "$_u" ]; } || return 1; git ls-remote "$_u" > "$W/lsr" 2>/dev/null || return 1
  _m=$(awk '$2 == "refs/heads/main" { print $1; exit }' "$W/lsr"); if [ -n "$_m" ]; then echo "$_m"; elif grep -q 'refs/heads/' "$W/lsr"; then echo absent; else echo none; fi; }
# exptree [say]: TR, the tree of exactly R2's paths at ViD's HEAD (H), built in a temporary index — never ViD's own;
# $W/xp the paths it holds. A path not at HEAD is left out (named, with say); an ignored file is refused
exptree() {
  H=$(git rev-parse -q --verify HEAD) || gref 'no commit at HEAD'
  GIT_INDEX_FILE="$W/index"; export GIT_INDEX_FILE; git read-tree --empty || gref 'the temporary index could not be made'
  : > "$W/xp"
  for p in $(printf '%s\n' PRD.md DECISIONS.md BASELINE.md ARCHITECTURE.md design/ GRADING-CHECKLIST.md); do
    q=${p%/}; git ls-tree -r -z --name-only HEAD -- "$q" > "$W/xf"
    if [ ! -s "$W/xf" ]; then [ -n "${1:-}" ] && echo "ViD github: $p is not at HEAD — not exported"; continue; fi
    git check-ignore -z --stdin --no-index < "$W/xf" > "$W/xi" 2>/dev/null || true
    [ ! -s "$W/xi" ] || gref "$p holds a file git ignores ($(tr '\0' '\n' < "$W/xi" | head -n 1)) — an ignored file is never exported"
    git ls-tree -r -z HEAD -- "$q" | git update-index -z --index-info || gref "$p could not be read at HEAD"
    printf '%s\n' "$p" >> "$W/xp"
  done
  git show HEAD:INVENTORY.md 2>/dev/null | awk '/^```vid-inventory/ { b = 1; next } /^```/ { b = 0 } b && /^[ \t]*difference[ \t]*[|]/' > "$W/dif"
  if [ -s "$W/dif" ]; then { printf '# The test differences: INVENTORY.md'"'"'s difference rows, verbatim\n\n'; cat "$W/dif"; } | git hash-object -w --stdin > "$W/difb" &&
    git update-index --add --cacheinfo "100644,$(cat "$W/difb"),TEST-DIFFERENCES.md" || gref 'TEST-DIFFERENCES.md could not be made'; echo TEST-DIFFERENCES.md >> "$W/xp"
  elif [ -n "${1:-}" ]; then echo "ViD github: INVENTORY.md at HEAD has no difference row — TEST-DIFFERENCES.md not exported"; fi
  [ -s "$W/xp" ] || gref "nothing to export: none of R2's paths is at HEAD"
  TR=$(git write-tree) || gref 'the export tree could not be written'; unset GIT_INDEX_FILE; }
# stpriv <repo>: ST and SU, its URL, or a refusal unless it is private (R6). sturl: the same for state-repo:, or the spec repository
stpriv() { ST=$1; [ "$(ghc repo view "$ST" --json isPrivate --jq .isPrivate 2>/dev/null)" = true ] || gref "$ST is not a private repository: ViD's records never go there"; SU=$(ghc repo view "$ST" --json url --jq .url) && [ -n "$SU" ] || gref "no access to $ST"; }
sturl() { _s=$(twkey state-repo); stpriv "${_s:-$SPEC}"; }
# specgit: .vid/spec.git, a bare repository whose objects borrow ViD's (alternates) — the export is built and pushed
# there; SG its path, SURL the spec repository's URL, SM its main (fetched), or empty (main 404–411)
specgit() {
  [ -n "$SPEC" ] || gref ".vid/tw/settings names no spec-repo: — sh checks/github.sh spec-setup first"
  SG=$(pwd -P)/.vid/spec.git
  [ -d "$SG" ] || { git init -q --bare "$SG" && git --git-dir="$SG" symbolic-ref HEAD refs/heads/main; } || gref "$SG could not be made"
  GC=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && case $GC in /*|?:/*) ;; *) false ;; esac || { GC=$(cd "$(git rev-parse --git-common-dir)" && pwd -P); ! command -v cygpath > /dev/null 2>&1 || GC=$(cygpath -m "$GC"); }   # git before 2.31 has no --path-format; Git Bash's cygpath gives Windows git's form
  printf '%s/objects\n' "$GC" > "$W/alt" || exit 1; put "$SG/objects/info/alternates" < "$W/alt" || exit 1   # the path in the form the git that reads it gives, never the shell's (v0.26.10.25.2.1, F-007: Git Bash's /c/… is no path to Windows git)
  SURL=$(ghc repo view "$SPEC" --json url --jq .url 2>/dev/null) && [ -n "$SURL" ] || gref "no access to the spec repository $SPEC: gh repo view $SPEC failed (sh checks/github.sh spec-setup makes it)"
  SM=$(git --git-dir="$SG" ls-remote "$SURL" refs/heads/main 2>/dev/null | cut -f1)
  if [ -n "$SM" ]; then git --git-dir="$SG" fetch -q "$SURL" "+refs/heads/main:refs/heads/main" 2>/dev/null || gref "the spec repository $SPEC could not be fetched (git needs its credentials: gh auth setup-git)"
  else git --git-dir="$SG" update-ref -d refs/heads/main 2>/dev/null || true; fi; }

# 0.26.10.28.7 (R6): the share's helpers. lform: a name in GitHub's login form (letters, digits, single hyphens, 1 to 39)
lform() { case "${1:-}" in ''|-*|*-|*--*|*[!A-Za-z0-9-]*) return 1 ;; esac; [ ${#1} -le 39 ]; }
srepo() { SREPO=${1:-}; case "$SREPO" in */*/*) gref "'$SREPO' is not <owner>/<name>" ;; */*) ;; *) gref "'$SREPO' is not <owner>/<name>" ;; esac
  lform "${SREPO%%/*}" || gref "'${SREPO%%/*}' is not a GitHub account name"; case "${SREPO#*/}" in ''|.|..|*[!A-Za-z0-9._-]*) gref "'${SREPO#*/}' is not a repository name" ;; esac; SOWN=${SREPO%%/*}; }
slogin() { auth; SHARE=yes; LOGIN=$(ghc api user --jq .login 2>/dev/null) && lform "$LOGIN" || gref 'your GitHub login could not be read'; }
# lc: lower case, as GitHub compares logins
lc() { printf '%s' "$1" | tr 'A-Z' 'a-z'; }
# orgown <org>: the login is an active owner (admin) of it, else a refusal
orgown() { [ "$(ghc api "orgs/$SOWN/memberships/$LOGIN" --jq '.state + " " + .role' 2>/dev/null)" = 'active admin' ] || gref "you ($LOGIN) are not an owner of $SOWN: a share goes only to your own account or an organisation you own"; }
# sowned: SREPO read private (its visibility PRIVATE, never INTERNAL or PUBLIC) and owned by the login, or by an organisation the login owns (SORG yes); a read that fails refuses, nothing written
sowned() { _v=$(ghc repo view "$SREPO" --json visibility,isInOrganization,owner --jq '[.visibility, .isInOrganization, .owner.login] | map(tostring) | join(" ")' 2>/dev/null) || gref "$SREPO could not be read: it counts as not private, and nothing is written"
  [ "${_v%% *}" = PRIVATE ] || gref "$SREPO is not private (it reads ${_v%% *}; an internal one is seen by its whole enterprise): nothing is written"; _o=${_v##* }; _g=${_v#* }; _g=${_g%% *}
  [ "$(lc "$_o")" = "$(lc "$SOWN")" ] || gref "$SREPO reads as owned by $_o: nothing is written"
  if [ "$_g" = true ]; then SORG=yes; orgown; else SORG=no; [ "$(lc "$_o")" = "$(lc "$LOGIN")" ] || gref "$SREPO is owned by $_o, not by you ($LOGIN): a share goes only to your own account or an organisation you own"; fi; }
sname() { case "${2:-}" in ''|.|..|*[!A-Za-z0-9._-]*) gref "the $1 '${2:-}' is not a plain name (letters, digits, . _ -)" ;; esac; }

CMD=${1:-}; [ $# -gt 0 ] && shift
case "$CMD" in
  access)   # v0.26.10.12.3.1 (PE R3): what ViD can reach, read only; it reports and never refuses
    [ $# -eq 0 ] || usage; M=0; B=0
    say() { M=$((M + 1)); [ "$1" = ok ] || B=$((B + 1)); shift; echo "access $*"; }
    words() { tr '\n' ' ' < "$1" | sed 's/[[:space:]]*$//'; }
    if ghc auth status > "$W/auth" 2>&1; then say ok 'gh — signed in'; else say no "gh — not signed in: $(words "$W/auth")"; echo "access: $B of $M not ready"; exit 0; fi
    for k in repo spec-repo; do
      [ "$k" = repo ] || [ "$(twkey layout)" != one ] || continue; n=$(twkey "$k")
      if [ -z "$n" ]; then say no "$k — not set yet"; continue; fi
      if P=$(ghc repo view "$n" --json isPrivate --jq .isPrivate 2> "$W/e") && V=$(ghc repo view "$n" --json viewerPermission --jq .viewerPermission 2> "$W/e"); then
        v=public; [ "$P" = true ] && v=private
        if [ "$k" = repo ] || [ "$v" = private ]; then say ok "$k $n — reached, $V, $v"; else say no "$k $n — public: spec-setup refuses it"; fi
      elif [ "$k" = repo ]; then say no "$k $n — not reached: $(words "$W/e")"
      else say no "$k $n — not reached: $(words "$W/e"); spec-setup makes it if it does not exist yet"; fi
    done
    if [ "$B" = 0 ]; then echo 'access: ok'; else echo "access: $B of $M not ready"; fi; exit 0 ;;

  tw-sync)   # v0.26.10.12.3 (R9): the code repository's main and TW's open tickets
    tw; U=$(ghc repo view "$REPO" --json url --jq .url 2>/dev/null) && [ -n "$U" ] || gref "no access to $REPO: gh repo view $REPO failed"
    M=$(codemain) || gref "the code repository's main could not be read (git ls-remote): nothing recorded"; O=''   # v0.26.10.28.2 (R3): none is an empty repository alone
    ghc issue list -R "$REPO" --state open --limit 1000 --json number --jq '.[].number' > "$W/on" || gref 'the open issues could not be read'
    for n in $(awk '$1 == "published" { print $2 }' .vid/tw/log 2>/dev/null | sort -un); do grep -q "^withdrawn $n " .vid/tw/log && continue; grep -qx "$n" "$W/on" && O="$O${O:+,}$n"; done
    twlog "sync main=${M:-none} open=${O:--} at=$(now)"; echo "ViD github: synced — main ${M:-none}, open tickets ${O:-none}"; exit 0 ;;

  tw-post)   # v0.26.10.12.3 (R3, R7–R9): a written ticket published, or open ticket <n> amended in place
    tw; A=''; if [ "${1:-}" = --amend ]; then A=${2:-}; shift 2; fi; F=${1:-}; [ -f "$F" ] && [ -f "${F%.md}.meta" ] || usage
    { sh "$HERE/writer.sh" gate && sh "$HERE/writer.sh" check "$F" && sh "$HERE/writer.sh" fresh "$F" $A; } > "$W/ck" 2>&1 || { sed 's/^/    /' "$W/ck" >&2; gref "the gate is shut, the check refuses $F, or it is stale — nothing posted"; }
    X=$(sed -n 's/^- export: //p' "$F" | head -n 1); exptree; specgit
    [ -n "$SM" ] && [ "$X" = "$SM" ] && [ "$(git --git-dir="$SG" rev-parse "$SM^{tree}")" = "$TR" ] || gref "the ticket's export ${X:-none} is not the spec repository's main at ViD's HEAD: sh checks/github.sh spec-export, then write it again"
    ghc label create "${PFX}ticket" -R "$REPO" --force --description 'ViD: a ticket' > /dev/null || gref "the label ${PFX}ticket could not be made"
    ghc label create "${PFX}blocked" -R "$REPO" --force --description 'ViD: a question stops this' > /dev/null || gref "the label ${PFX}blocked could not be made"
    TT=$(sed -n '1s/^# //p' "$F"); if [ -n "$A" ]; then N=$A; else printf 'ViD is writing this ticket; its body follows in a moment.\n' > "$W/ph"
      N=$(ghc issue create -R "$REPO" --title "$TT" --body-file "$W/ph" --label "${PFX}ticket" | num_of_url) && [ -n "$N" ] || gref "the issue for $F could not be made"; fi
    sed "s/^- number: .*/- number: $N/" "$F" > "$W/t.md"; sh "$HERE/writer.sh" parts "$W/t.md" "$N" "$W/p" > "$W/pl" || gref "the parts of $F could not be made"
    ghc issue edit "$N" -R "$REPO" --title "$TT" --body-file "$(sed -n 1p "$W/pl")" > /dev/null || gref "the body of #$N could not be written"
    : > "$W/cu"; for p in $(sed 1d "$W/pl"); do ghc issue comment "$N" -R "$REPO" --body-file "$p" >> "$W/cu" || gref "a part of #$N could not be posted"; done
    [ -z "$A" ] || { printf 'vid: amended %s. Earlier results for its changed rows do not count.\n' "$(sed -n 's/^why //p' "${F%.md}.meta")" > "$W/am"; ghc issue comment "$N" -R "$REPO" --body-file "$W/am" > /dev/null || gref "the amendment of #$N could not be named"
      CU=$(paste -sd ' ' "$W/cu" | sed 's/ /, /g'); printf 'vid: replaced. This comment held a part of an earlier writing of this ticket. The current writing, %s, is this issue'"'"'s body%s.\n' "$(sed -n '1s/.*, writing \([0-9a-f]*\)\.$/\1/p' "$(sed -n 1p "$W/pl")")" "${CU:+, then its part comments $CU}" > "$W/rp"
      for c in $(ghc issue view "$N" -R "$REPO" --json comments --jq '.comments[] | .url + "\t" + (.body | split("\n") | .[0])' | tr -d '\r' | awk -F'\t' -v CU="$W/cu" 'BEGIN { while ((getline l < CU) > 0) K[l] = 1 } !($1 in K) && ($2 ~ /^Ticket #[0-9]+, part [0-9]+ of [0-9]+, writing [0-9a-f]+\.$/ || index($2, "vid: replaced.") == 1) { sub(/.*issuecomment-/, "", $1); print $1 }'); do
        ghc api -X PATCH "repos/$REPO/issues/comments/$c" -F "body=@$W/rp" > /dev/null || gref "the earlier part comment $c of #$N could not be marked replaced"; done; }
    K1=published; [ -z "$A" ] || K1=amended; twlog "$K1 $N $(sed -n 1p "${F%.md}.meta") parts=$(grep -c . "$W/pl") at=$(now)"
    awk -v n="$N" -v t="$(now)" '$1 == "sent" { print "sent " $2 " ticket=" n " hash=" $3 " at=" t }' "${F%.md}.meta" >> .vid/tw/log
    mkdir -p .vid/tw/out; put ".vid/tw/out/issue-$N.md" < "$W/t.md" || exit 1; echo "ViD github: $K1 ticket #$N ($(grep -c . "$W/pl") parts)"; exit 0 ;;

  tw-outside)   # v0.26.10.27.3 (8.1b R1): tw-outside <n>, a published ticket neither open in the round's read nor merged by ViD's
    # records: a merged pull request naming it, found by GitHub's search, is recorded (decide/merged-tickets) and prints `merged <n> <p>`; else
    # its issue read once: CLOSED is withdrawn closed-outside, printing `closed-outside <n>`; OPEN, or a failed read, changes nothing
    tw; N=${1:-}; case "$N" in ''|*[!0-9]*) usage ;; esac; grep -q "^published $N " .vid/tw/log 2>/dev/null || gref "#$N is no ticket TW published"
    ghc pr list -R "$REPO" --state merged --limit 100 --search "\"ticket: #$N\" in:body" --json number,headRefOid,mergeCommit,body,comments --jq "$RMQ" > "$W/s" || gref "the merged pull requests naming #$N could not be searched"
    P=$(awk -F'\t' -v n="$N" '{ t = $4; if (t !~ /^ticket: #/) next; sub(/^ticket: #/, "", t); sub(/[^0-9].*$/, "", t); if (t == n) { print $1; exit } }' "$W/s")
    if [ -n "$P" ]; then mkdir -p .vid/decide; printf '%s\t%s\n' "$N" "$P" >> .vid/decide/merged-tickets; echo "merged $N $P"; exit 0; fi
    S=$(ghc issue view "$N" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))') || gref "#$N could not be read"; S=$(printf '%s\n' "$S" | cut -f1)
    [ "$S" = CLOSED ] || exit 0
    twlog "withdrawn $N decision=closed-outside at=$(now)"; ev "ticket issue=$N state=closed-outside"; echo "closed-outside $N"; exit 0 ;;
  tw-close)   # v0.26.10.12.3 (R7): open ticket <n> withdrawn when writer.sh due owes it, by the change due names; never merged
    # 0.26.10.28.6 (R2): or, owed `withdraw <n> limits=<rows>`, a fix ticket whose rows were all ruled known limits, its comment saying so, `decision=known-limit`
    tw; N=${1:-}; case "$N" in ''|*[!0-9]*) usage ;; esac; grep -q "^published $N " .vid/tw/log 2>/dev/null || gref "#$N is no ticket TW published"
    { sh "$HERE/writer.sh" gate && sh "$HERE/writer.sh" due; } > "$W/ck" 2>&1 || { sed 's/^/    /' "$W/ck" >&2; gref "the gate is shut, or writer.sh due failed — #$N not withdrawn"; }
    PC=$(grep -E "^withdraw $N( |$)" "$W/ck") && [ "$(ghc issue view "$N" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))' | cut -f1)" = OPEN ] || gref "the round owes no withdrawal of #$N, or it is not open: a merged or closed ticket is never changed"; D=$(kv "$PC" decision); LR=$(kv "$PC" limits)
    if [ -n "$LR" ]; then D=known-limit; printf 'vid: withdrawn. Its rows %s were ruled known limits or taken out of the plan, so nothing in it is left to build. This ticket is not to be merged.\n' "$(printf '%s' "$LR" | sed 's/,/, /g')" > "$W/wd"
    else printf 'vid: withdrawn by plan change %s, what %s. This ticket is not to be merged; its rows are planned again.\n' "${D:-none}" "$(kv "$PC" what)" > "$W/wd"; fi
    ghc issue comment "$N" -R "$REPO" --body-file "$W/wd" > /dev/null && ghc issue close "$N" -R "$REPO" --reason 'not planned' > /dev/null || gref "#$N could not be withdrawn"
    twlog "withdrawn $N decision=${D:-none}${LR:+ rows=$LR} at=$(now)"; echo "ViD github: withdrew ticket #$N"; exit 0 ;;

  spec-setup)   # v0.26.10.12.3 (R2, main 436–448): the private spec repository, made once, then an export
    tw
    [ -n "$SPEC" ] || gref ".vid/tw/settings names no spec-repo: <owner>/<name>"
    case "$SPEC" in */*/*|/*|*/|*[!A-Za-z0-9._/-]*) gref "spec-repo: '$SPEC' is not <owner>/<name>" ;; */*) ;; *) gref "spec-repo: '$SPEC' is not <owner>/<name>" ;; esac
    [ "$SPEC" != "$REPO" ] || gref "spec-repo: names the code repository $REPO — the spec repository is another, <project>-spec"
    if ghc repo view "$SPEC" --json name --jq .name > /dev/null 2>&1; then
      [ "$(ghc repo view "$SPEC" --json isPrivate --jq .isPrivate 2>/dev/null)" = true ] || gref "$SPEC exists and is not private — ViD's spec repository is private; make it private, or name another"
      twlog "spec-repo $SPEC exists at=$(now)"; echo "ViD github: the spec repository $SPEC exists (private)"
    else
      SPECSETUP=yes ghc repo create "$SPEC" --private > /dev/null || gref "the spec repository $SPEC could not be made"
      twlog "spec-repo $SPEC created at=$(now)"; echo "ViD github: the spec repository $SPEC made, private"
    fi
    [ "${1:-}" != --make-only ] || exit 0   # v0.26.10.26.7 (R12)
    sh "$0" spec-export; exit $? ;;

  spec-export)   # v0.26.10.12.3 (R2, main 450–494 less the spec-export: key and its ! entries): always R2's paths
    tw; exptree say; specgit
    if [ -n "$SM" ] && [ "$(git --git-dir="$SG" rev-parse "$SM^{tree}")" = "$TR" ]; then twlog "export $SM from=$H state=unchanged at=$(now)"
      echo "ViD github: the export at $(printf '%.12s' "$H") changes nothing — $SPEC stays at $(printf '%.12s' "$SM")"; exit 0; fi
    set -- -m "ViD export of $(printf '%.12s' "$H")" -m "from: $H" -m "paths: $(paste -sd ' ' "$W/xp")"; [ -z "$SM" ] || set -- -p "$SM" "$@"
    # authored and committed as ViD <vid@export.invalid> — no one's address (.invalid is reserved), in the call's own
    # environment, so neither git config nor an exported GIT_AUTHOR_*/GIT_COMMITTER_* overrides it (main's v0.26.10.17)
    C=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid \
      git --git-dir="$SG" commit-tree "$TR" "$@") || gref 'the export commit could not be made'
    # fast-forward only, never forced: no + and no --force, so a remote that moved is a refusal
    git --git-dir="$SG" push -q "$SURL" "$C:refs/heads/main" 2> "$W/xpush" || { sed 's/^/    /' "$W/xpush" >&2; gref "the export could not be pushed to $SPEC (a fast-forward of main only)"; }
    git --git-dir="$SG" update-ref refs/heads/main "$C"
    twlog "export $C from=$H state=pushed at=$(now)"
    echo "ViD github: exported $(paste -sd ' ' "$W/xp") at $(printf '%.12s' "$H") to $SPEC as $(printf '%.12s' "$C")"; exit 0 ;;

  decide-blocked)   # v0.26.10.24.6 (R2): prints blocked when the issue or the pull request carries the label; a label it cannot read is refused
    tw; [ -n "${1:-}" ] && [ -n "${2:-}" ] || usage; L=$(ghc issue view "$1" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))') || gref "the labels of #$1 could not be read"
    M=$(ghc pr view "$2" -R "$REPO" --json labels --jq '[.labels[].name] | join(",")') || gref "the labels of pull request $2 could not be read"
    case ",$(printf %s "$L" | cut -f2),$M," in *",${PFX}blocked,"*) echo blocked ;; esac; exit 0 ;;

  decide-post)   # v0.26.10.24.6 (R2): the decision, a comment on the pull request
    tw; [ -n "${1:-}" ] && [ -f "${2:-}" ] || usage; ghc pr comment "$1" -R "$REPO" --body-file "$2" > /dev/null || gref "the decision on pull request $1 could not be posted"; exit 0 ;;

  results-fetch)   # v0.26.10.24.5 (R2): .vid/code, the local copy checks/results.sh reads: every head and vid-results/* branch; 0.26.10.28.4: no file of the code
    tw; U=$(ghc repo view "$REPO" --json url --jq .url 2>/dev/null) && [ -n "$U" ] || gref "no access to $REPO: gh repo view $REPO failed"
    # 0.26.10.28.1 (stage 9 R5, S5): a working clone there (the first ticket mode's) is moved aside, and the bare copy cloned
    if [ -d .vid/code/.git ]; then CO=.vid/code.old-$(date -u '+%Y%m%dT%H%M%SZ'); mv .vid/code "$CO" || gref ".vid/code, a working clone, could not be moved aside"; echo "ViD github: .vid/code was a working clone — moved aside to $CO; the bare copy is cloned in its place"; fi
    # 0.26.10.28.4 (9.3 R5, M5): .vid/code holds no file of DevAgent's code. The reports: each vid-results/* branch's newest commit and its own folder
    # (--depth=1, the reports alone offered as had). DevAgent's commits: every other branch and pull-request head with no tree (--filter=tree:0), through a
    # promisor remote whose address is never stored, so nothing is fetched later; HEAD unborn, so no attributes are read from a code tree. At every fetch:
    # what no ref reaches is dropped, then the proof (nothing but the reports' trees and files, the empty tree aside; each report its folder alone), else
    # .vid/code is removed and the fetch refused. A copy in the earlier, full form is replaced
    cg() { git --git-dir=.vid/code "$@"; }; xref() { rm -rf .vid/code; gref "the fetch brought DevAgent's files ($1); ViD keeps none. .vid/code removed, nothing fetched."; }
    if [ -d .vid/code ] && [ "$(cg config extensions.partialClone 2>/dev/null)" != vid-commits ]; then rm -rf .vid/code; echo "ViD github: .vid/code held DevAgent's files, the earlier form — replaced by a copy that holds none"; fi
    [ -d .vid/code ] || { git init -q --bare .vid/code && cg config core.repositoryformatversion 1 && cg config extensions.partialClone vid-commits; } || { rm -rf .vid/code; gref ".vid/code could not be made"; }
    cg symbolic-ref HEAD refs/vid/none || gref ".vid/code's HEAD could not be set"   # unborn, outside both fetches' refs
    LR=$(git ls-remote "$U" 'refs/heads/vid-results/*' 2>/dev/null) || gref "$REPO's reports could not be listed (git ls-remote)"   # whole: a branch ending in vid-results/… is no report
    [ -z "$LR" ] || cg fetch -q --no-tags --depth=1 --negotiation-tip='refs/heads/vid-results/*' "$U" '+refs/heads/vid-results/*:refs/heads/vid-results/*' 2>/dev/null || gref "$REPO's reports could not be fetched into .vid/code"
    cg -c remote.vid-commits.url="$U" fetch -q --no-tags --filter=tree:0 vid-commits '+refs/heads/*:refs/heads/*' '^refs/heads/vid-results/*' '+refs/pull/*/head:refs/pull/*/head' 2>/dev/null || gref "$REPO's commits could not be fetched into .vid/code"
    # each report its folder alone; what no ref reaches dropped; then each report read whole, and nothing present that no report holds
    cg for-each-ref --format='%(refname)' refs/heads/vid-results/ > "$W/rr"
    for r in $(sed 's|^refs/heads/vid-results/||' "$W/rr"); do cg ls-tree "refs/heads/vid-results/$r" 2>/dev/null | awk -v r="$r" -F'\t' '{ n++; if ($2 != r || $1 !~ /^040000 tree /) bad = 1 } END { exit !(n == 1 && !bad) }' || xref "refs/heads/vid-results/$r holds more than its folder, or not whole"; done
    # no tag: none is fetched, and any an earlier copy took goes, so nothing keeps an old report's files; HEAD stays unborn
    # a pull-request head whose tree is here is a report's commit, kept only by that ref: dropped, as a tag is, so no old report's files stay
    cg for-each-ref --format='%(refname)' refs/pull/ | while read -r p; do ! cg cat-file -e "$p^{tree}" 2>/dev/null || cg update-ref -d "$p"; done
    cg for-each-ref --format='%(refname)' refs/tags/ | while read -r t; do cg update-ref -d "$t"; done; ! cg rev-parse -q --verify HEAD > /dev/null 2>&1 || xref 'HEAD names a commit'
    cg -c gc.reflogExpire=now -c gc.reflogExpireUnreachable=now -c repack.writeBitmaps=false gc -q --prune=now 2>/dev/null || xref 'a copy that could not be checked whole'   # no bitmap: a copy with no code has no full closure
    E=$(git hash-object -t tree /dev/null); cg cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' 2>/dev/null | awk '$2 == "tree" || $2 == "blob" { print $1 }' | sort > "$W/have"
    : > "$W/rep"; [ ! -s "$W/rr" ] || { cg rev-list --objects --stdin < "$W/rr" > "$W/ro" 2>/dev/null || xref 'a report that could not be read whole'; cut -d' ' -f1 "$W/ro" | sort -u > "$W/rep"; }
    X=$(comm -23 "$W/have" "$W/rep" | grep -vx "$E" | head -n 1 || true)
    if [ -n "$X" ]; then XR=$(cg for-each-ref --format='%(refname)' refs/heads/ refs/pull/ | grep -v '^refs/heads/vid-results/' | while read -r r; do cg rev-list --objects --missing=allow-any "$r" 2>/dev/null | grep -q "^$X" && { echo "$r"; break; }; done)
      xref "${XR:-an object no report holds, $X}"; fi
    echo "ViD github: results fetched from $REPO into .vid/code, the reports and the commits, no file of the code"; exit 0 ;;

  round-read)   # v0.26.10.25.1 (R3): one read a tick, whatever the count. Tab-separated: open <p> <ticket> <head> <draft> <labels> <newest decide at the head> <newest decision there> <updated>, the two by comment; merged <p> <ticket> <head> <merge>; issue <n> <labels> <comment heads, \001 between> <updated>; main <the code repository's main> (v0.26.10.28.2); result <report id> <its commit>, a line a vid-results/* branch (v0.26.10.28.6)
    tw; ghc pr list -R "$REPO" --state open --limit 200 --json number,headRefName,isDraft,headRefOid,labels,body,comments,updatedAt --jq "$RPQ" > "$W/o" || gref 'the open pull requests could not be read'
    L=20; while :; do ghc pr list -R "$REPO" --state merged --limit "$L" --search 'sort:updated-desc' --json number,headRefOid,mergeCommit,body,comments --jq "$RMQ" > "$W/m" || gref 'the merged pull requests could not be read'
      [ "$(grep -c . "$W/m")" -ge "$L" ] || break; ! grep -qx "$(tail -n 1 "$W/m" | cut -f1)" .vid/decide/merged-prs 2>/dev/null || break; L=$((L * 10)); done
    ghc issue list -R "$REPO" --state open --limit 1000 --json number,labels,comments,updatedAt --jq "$RIQ" > "$W/i" || gref 'the open issues could not be read'
    awk -F'\t' -v OFS='\t' '{ t = $6; sub(/^ticket: #/, "", t); sub(/[^0-9].*$/, "", t); if (t == "") t = "-"; n = split($7, c, "\001"); d = 0; e = 0; for (i = 1; i <= n; i++) { if (c[i] == "vid: decide " $4) d = i; if (c[i] == "vid: decision " $4) e = i } print "open", $1, t, $4, $3, $5, d, e, $9, $7 }' "$W/o"
    awk -F'\t' -v OFS='\t' '{ t = $4; sub(/^ticket: #/, "", t); sub(/[^0-9].*$/, "", t); print "merged", $1, (t == "" ? "-" : t), $2, $3, $5 }' "$W/m"; sed 's/^/issue	/' "$W/i"
    # v0.26.10.28.2 (R4): main <the code repository's main, none or absent>; a failed read gives the last one read, so it changes nothing
    # its address kept in .vid/round/code-url, so a tick stays four gh calls; a failed read drops it, and the next read asks gh again
    mkdir -p .vid/round; CU=$(sed -n "s|^$REPO ||p" .vid/round/code-url 2>/dev/null | head -n 1); [ -n "$CU" ] || { CU=$(ghc repo view "$REPO" --json url --jq .url 2>/dev/null) && [ -n "$CU" ] && echo "$REPO $CU" > .vid/round/code-url || CU=''; }   # keyed by repo
    # v0.26.10.28.6 (R3): result <id> <commit> for each vid-results/* branch, from the same ls-remote, so the round's wait sees a report with no
    # other change; a failed read gives the last list read, as main does
    if [ -n "$CU" ] && codemain "$CU" > "$W/cm"; then put .vid/round/code-main < "$W/cm"; awk '$2 ~ /^refs\/heads\/vid-results\// { sub(/^refs\/heads\/vid-results\//, "", $2); print $2 "\t" $1 }' "$W/lsr" | sort > "$W/cr"; put .vid/round/code-results < "$W/cr"; else rm -f .vid/round/code-url; fi
    [ ! -s .vid/round/code-main ] || printf 'main\t%s\n' "$(cat .vid/round/code-main)"; [ ! -s .vid/round/code-results ] || sed 's/^/result	/' .vid/round/code-results; exit 0 ;;
  deploy-ask)   # v0.26.10.26.2 (R1): deploy-ask --stage <N> --commit <c> --title <t> --body-file <f>: a staging okay, D1, an issue labelled <prefix>deploy, logged `asked <n> deploy`; prints its number
    planner; S=''; C=''; TT=''; F=''; while [ $# -ge 2 ]; do case $1 in --stage) S=$2 ;; --commit) C=$2 ;; --title) TT=$2 ;; --body-file) F=$2 ;; *) usage ;; esac; shift 2; done
    [ -n "$S" ] && [ -n "$C" ] && [ -n "$TT" ] && [ -f "$F" ] || usage; ghc label create "${PFX}deploy" -R "$REPO" --force --description 'ViD: a deploy okay' > /dev/null || gref "the label ${PFX}deploy could not be made"
    N=$(ghc issue create -R "$REPO" --title "$TT" --body-file "$F" --label "${PFX}deploy" | num_of_url) && [ -n "$N" ] || gref "the deploy okay for stage $S could not be made"
    twlog "asked $N deploy stage=$S commit=$C at=$(now)"; ev "ticket issue=$N stage=$S kind=deploy state=asked"; echo "$N"; exit 0 ;;
  grade-ask)   # v0.26.10.26.1 (R3): grade-ask --stage <N> --commit <c> --title <t> --body-file <f>: a stage grade's ask, S1, an issue labelled <prefix>grade, logged `asked <n> grade`; prints its number
    planner; S=''; C=''; TT=''; F=''; while [ $# -ge 2 ]; do case $1 in --stage) S=$2 ;; --commit) C=$2 ;; --title) TT=$2 ;; --body-file) F=$2 ;; *) usage ;; esac; shift 2; done
    [ -n "$S" ] && [ -n "$C" ] && [ -n "$TT" ] && [ -f "$F" ] || usage; ghc label create "${PFX}grade" -R "$REPO" --force --description 'ViD: a stage grade' > /dev/null || gref "the label ${PFX}grade could not be made"
    N=$(ghc issue create -R "$REPO" --title "$TT" --body-file "$F" --label "${PFX}grade" | num_of_url) && [ -n "$N" ] || gref "the grade ask for stage $S could not be made"
    if grep -qx 'grade: ask-#' "$F"; then sed "s/^grade: ask-#\$/grade: ask-$N/" "$F" > "$W/gb"; ghc issue edit "$N" -R "$REPO" --body-file "$W/gb" > /dev/null || gref "the grade ask #$N could not be numbered"; fi   # v0.26.10.27.2: an owner's ask, numbered by its issue
    twlog "asked $N grade stage=$S commit=$C at=$(now)"; ev "ticket issue=$N stage=$S kind=grade state=asked"; echo "$N"; exit 0 ;;
  run-ask)   # v0.26.10.25.3 (R8): run-ask --step <s> --commit <c> --title <t> --body-file <f>: a close's ask, an issue labelled <prefix>run, logged `asked <n> close`; prints its number
    planner; S=''; C=''; TT=''; F=''; while [ $# -ge 2 ]; do case $1 in --step) S=$2 ;; --commit) C=$2 ;; --title) TT=$2 ;; --body-file) F=$2 ;; *) usage ;; esac; shift 2; done
    [ -n "$S" ] && [ -n "$C" ] && [ -n "$TT" ] && [ -f "$F" ] || usage; ghc label create "${PFX}run" -R "$REPO" --force --description 'ViD: a close run' > /dev/null || gref "the label ${PFX}run could not be made"
    N=$(ghc issue create -R "$REPO" --title "$TT" --body-file "$F" --label "${PFX}run" | num_of_url) && [ -n "$N" ] || gref "the close ask for $S could not be made"
    twlog "asked $N close step=$S commit=$C at=$(now)"; ev "ticket issue=$N step=$S kind=close state=asked"; echo "$N"; exit 0 ;;

  state-save)   # v0.26.10.25.1 (R6): ViD's records and project on vid-state/records of the state repository, as files and a bundle; nothing to push when nothing changed
    tw; sturl; RP=$W/sr; git init -q "$RP"; T0=$(git ls-remote "$SU" refs/heads/vid-state/records 2>/dev/null | cut -f1); HD=$(git rev-parse HEAD) || gref 'no commit at HEAD'; rm -f "$RP/.git/hooks"/* 2>/dev/null
    for f in RUN-STATE.md budget metrics-events decide tw plans plan VID-FINDINGS.md; do [ ! -e ".vid/$f" ] || cp -R ".vid/$f" "$RP/$f"; done; rm -rf "$RP"/decide/tmp.*; mkdir "$RP/results"; cp .vid/results/*.txt "$RP/results/" 2>/dev/null
    if [ -n "$T0" ]; then git -C "$RP" fetch -q "$SU" refs/heads/vid-state/records || gref "$ST could not be fetched"; fi; printf '%s\n' "$HD" > "$RP/home.head"
    if [ -n "$T0" ] && [ "$(git -C "$RP" show FETCH_HEAD:home.head 2>/dev/null)" = "$HD" ]; then git -C "$RP" show FETCH_HEAD:home.bundle > "$RP/home.bundle"; else git bundle create -q "$RP/home.bundle" --all 2>/dev/null || gref 'the project could not be bundled'; fi
    git -C "$RP" -c core.excludesFile=/dev/null add -A -f . ; TR=$(git -C "$RP" write-tree); if [ -n "$T0" ] && [ "$(git -C "$RP" rev-parse FETCH_HEAD^{tree})" = "$TR" ]; then echo "$T0" > "$W/sa" || exit 1; put .vid/state-at < "$W/sa" || exit 1; echo 'ViD github: the records are as saved'; exit 0; fi
    set -- -m 'ViD records'; [ -z "$T0" ] || set -- -p "$T0" "$@"; C=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid git -C "$RP" commit-tree "$TR" "$@") || gref 'the records could not be committed'
    git -C "$RP" push -q "$SU" "$C:refs/heads/vid-state/records" 2> "$W/e" || { sed 's/^/    /' "$W/e" >&2; gref "the records could not be pushed to $ST"; }; echo "$C" > "$W/sa" || exit 1; put .vid/state-at < "$W/sa" || exit 1; echo "ViD github: the records saved to $ST"; exit 0 ;;

  state-restore)   # v0.26.10.25.1 (R6): state-restore <repo> in an empty folder, or with no repository in a project whose records are behind the branch
    if [ -n "${1:-}" ]; then auth; stpriv "$1"; else tw; sturl; fi; T0=$(git ls-remote "$SU" refs/heads/vid-state/records 2>/dev/null | cut -f1); [ -n "$T0" ] || { [ -z "${1:-}" ] || gref "$ST holds no records"; echo 'ViD github: no records saved yet'; exit 0; }
    [ "$T0" != "$(cat .vid/state-at 2>/dev/null)" ] || { echo 'ViD github: the records are current'; exit 0; }; RP=$W/sr; mkdir "$W/rt"; git init -q "$RP"; git -C "$RP" fetch -q "$SU" refs/heads/vid-state/records && git -C "$RP" archive FETCH_HEAD | tar -x -C "$W/rt" || gref "$ST could not be read"
    if [ -e .git ]; then git fetch -q "$W/rt/home.bundle" HEAD && git merge -q --ff-only FETCH_HEAD || gref 'the project is not behind the saved one'; else [ -z "$(ls -A)" ] || gref 'state-restore <repo> takes an empty folder'; git clone -q "$W/rt/home.bundle" . && git remote remove origin || gref 'the project could not be cloned from its bundle'; fi
    git config core.hooksPath checks/hooks; mkdir -p .vid; for f in RUN-STATE.md budget metrics-events decide tw plans plan results VID-FINDINGS.md; do if [ ! -e "$W/rt/$f" ]; then rm -rf ".vid/$f"; elif [ -d "$W/rt/$f" ]; then putd ".vid/$f" "$W/rt/$f" || exit 1; else put ".vid/$f" < "$W/rt/$f" || exit 1; fi; done
    tw; specgit; sh "$HERE/github.sh" results-fetch > /dev/null || gref 'the code repository could not be fetched'; echo "$T0" > "$W/sa" || exit 1; put .vid/state-at < "$W/sa" || exit 1; echo "ViD github: the records restored from $ST"; exit 0 ;;

  lock-take|lock-renew|lock-free)   # v0.26.10.25.1 (R7): vid-state/lock, one parentless commit: session, machine, time. Pushed with a lease on what was read, so of two takers one wins. VID_LOCK_COLD (900 seconds)
    tw; ST=$(twkey state-repo); [ -n "$ST" ] || ST=$SPEC; SU=$(ghc repo view "$ST" --json url --jq .url) || gref "no access to $ST"; LR=refs/heads/vid-state/lock; LL=$(git ls-remote "$SU" "$LR" 2>/dev/null) || gref 'the lock could not be read'; LO=$(printf '%s' "$LL" | cut -f1); ME=${CLAUDE_CODE_SESSION_ID:-$(cat .vid/lock-session 2>/dev/null)}; LS=''; LA=0; RP=$W/l; git init -q "$RP"
    if [ -n "$LO" ]; then git -C "$RP" fetch -q "$SU" "$LR" || gref 'the lock could not be read'; LB=$(git -C "$RP" show FETCH_HEAD:lock); LS=$(printf '%s\n' "$LB" | sed -n 's/^session: //p'); LA=$(printf '%s\n' "$LB" | sed -n 's/^at: //p'); fi
    lpush() { printf 'session: %s\nmachine: %s\nat: %s\n' "$1" "$(hostname)" "$(date +%s)" > "$RP/lock"; git -C "$RP" add lock; C=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid git -C "$RP" commit-tree "$(git -C "$RP" write-tree)" -m 'ViD lock'); git -C "$RP" push -q "--force-with-lease=$LR:$LO" "$SU" "$C:$LR" 2>/dev/null; }
    case $CMD in
      lock-take) S=${1:-${CLAUDE_CODE_SESSION_ID:-session-$$-$(date +%s)}}; A=$(($(date +%s) - LA)); CO=${VID_LOCK_COLD:-900}; if [ -n "$LO" ] && [ "$LS" != "$S" ] && [ "$A" -lt "$CO" ]; then gref "the lock is held by $LS, ${A}s old; it may be taken in $((CO - A))s"; fi
        lpush "$S" || gref 'another session took the lock'; echo "$S" > "$W/ls" || exit 1; put .vid/lock-session < "$W/ls" || exit 1; ev "lock-taken session=$S from=${LS:-none}"; echo "ViD github: the lock is $S's" ;;
      lock-renew) lost() { echo "ViD github: refused — the lock is lost: $1" >&2; exit 3; }; [ -n "$ME" ] && [ "$LS" = "$ME" ] || lost "it is ${LS:-nobody}'s"; lpush "$ME" || { LL=$(git ls-remote "$SU" "$LR" 2>/dev/null) || gref 'the lock could not be renewed'; [ "$(printf '%s' "$LL" | cut -f1)" != "$LO" ] || gref 'the lock could not be renewed'; lost 'another session took it'; }; echo 'ViD github: the lock renewed' ;;   # exit 3 only for a loss seen; a failed call is an error like any other (R4)
      lock-free) [ -n "$ME" ] && [ "$LS" = "$ME" ] || gref "the lock is ${LS:-nobody}'s, not this session's"; git -C "$RP" push -q "--force-with-lease=$LR:$LO" "$SU" ":$LR" 2>/dev/null || gref 'the lock could not be freed'; rm -f .vid/lock-session; echo 'ViD github: the lock freed' ;;
    esac; exit 0 ;;

  comment)
    planner; n=${1:-}; [ "${2:-}" = --body-file ] && [ -f "${3:-}" ] || usage
    ghc issue comment "$n" -R "$REPO" --body-file "$3" > /dev/null || gref "the comment on #$n could not be posted"
    tl=$(mapline ticket number "$n"); [ -n "$tl" ] && ev "ticket issue=$n step=$(kv "$tl" step) kind=$(kv "$tl" kind) state=commented"
    echo "ViD github: commented on #$n"; exit 0 ;;

  label)
    if [ -f .vid/RUN-STATE.md ]; then planner; else devagent; devagent_repo; PFX=$(cat "$(GD)/vid/labels-prefix" 2>/dev/null); fi
    n=${1:-}; [ -n "$n" ] || usage; shift; set -- "$@"; A=''; R=''
    while [ $# -gt 0 ]; do case "$1" in --add) A="$A${A:+,}$PFX${2:-}"; shift 2 ;; --remove) R="$R${R:+,}$PFX${2:-}"; shift 2 ;; *) usage ;; esac; done
    [ -n "$A$R" ] || usage
    if [ -n "$A" ] && [ -n "$R" ]; then ghc issue edit "$n" -R "$REPO" --add-label "$A" --remove-label "$R" > /dev/null
    elif [ -n "$A" ]; then ghc issue edit "$n" -R "$REPO" --add-label "$A" > /dev/null; else ghc issue edit "$n" -R "$REPO" --remove-label "$R" > /dev/null; fi || gref "the labels of #$n could not be changed"
    echo "ViD github: #$n labels${A:+ +$A}${R:+ -$R}"; exit 0 ;;

  close)
    planner
    if [ "${1:-}" = --milestone ]; then
      S=${2:-}; [ "${3:-}" = --commit ] && C=${4:-} || usage
      ml=$(mapline milestone stage "$S"); [ -n "$ml" ] || gref "stage $S has no milestone"
      mn=$(kv "$ml" number)
      if [ -f STAGES.md ]; then awk -v k="$S" 'on && /^## / { exit } $0 ~ "^## Stage " k "( |$)" { on = 1 } on' STAGES.md | sed '/^<!--/,/-->$/d' > "$W/card"; else printf 'One stage.\n' > "$W/card"; fi
      printf '\nDone: the dev team'"'"'s CI passed every row of this stage at %s, and every row is graded KEPT. That commit is your deploy'"'"'s input.\n' "$C" >> "$W/card"
      ghc api -X PATCH "repos/$REPO/milestones/$mn" -f "description=$(cat "$W/card")" -f state=closed > /dev/null || gref "milestone $mn could not be closed"
      ev "milestone stage=$S number=$mn state=closed commit=$C"; echo "ViD github: milestone $mn (stage $S) closed at $C"; exit 0
    fi
    n=${1:-}; [ -n "$n" ] || usage; ghc issue close "$n" -R "$REPO" > /dev/null || gref "#$n could not be closed"
    echo "ViD github: #$n closed"; exit 0 ;;

  share-login)   # 0.26.10.28.7 (R6): the login, or the words that no login means a file alone
    ghc auth status > "$W/auth" 2>&1 || { sed 's/^/    /' "$W/auth" >&2; echo 'ViD share: no GitHub login, the login check fails: the bundle stays a file you can send by hand' >&2; exit 1; }
    SHARE=yes; LOGIN=$(ghc api user --jq .login 2>/dev/null) && lform "$LOGIN" || gref 'your GitHub login could not be read'; echo "$LOGIN"; exit 0 ;;

  share-create)   # 0.26.10.28.7 (R6): share-create --repo <owner>/<name>, made private, in the login's account or an organisation it owns
    slogin; [ "${1:-}" = --repo ] || usage; srepo "${2:-}"
    [ "$(lc "$SOWN")" = "$(lc "$LOGIN")" ] || orgown
    if ghc repo view "$SREPO" --json name > /dev/null 2>&1; then sowned; echo "ViD share: $SREPO is there, private and yours: the share goes in it"; exit 0; fi
    SCREATE=yes ghc repo create "$SREPO" --private > /dev/null || gref "$SREPO could not be made"
    sowned; echo "ViD share: $SREPO made, private"; exit 0 ;;

  share-push)   # 0.26.10.28.7 (R6): share-push --repo <r> --project <p> --run <n> <folder>
    auth; R=''; P=''; N=''
    while [ $# -gt 1 ]; do case "$1" in --repo) R=$2 ;; --project) P=$2 ;; --run) N=$2 ;; *) break ;; esac; shift 2; done
    F=${1:-}; [ -n "$R" ] && [ -n "$P" ] && [ -n "$N" ] && [ -d "$F" ] && [ $# -eq 1 ] || usage; sname project "$P"; sname run "$N"
    # the scan first, on the folder as it is now: a bundle changed after its scan is never pushed, and nothing is called
    # nothing but files and folders: a link's own text is no file any scan reads
    [ -z "$(find "$F" ! -type f ! -type d | head -n 1)" ] || gref "$F holds a link or another special file ($(find "$F" ! -type f ! -type d | head -n 1 | sed "s|^$F/||")): nothing is pushed"
    sh "$HERE/share.sh" scan "$F" > "$W/scan" 2>&1 || { sed 's/^/    /' "$W/scan" >&2; gref "the bundle's scan finds something left in $F: nothing is pushed"; }
    F=$(cd "$F" && pwd -P); srepo "$R"; SHARE=yes; LOGIN=$(ghc api user --jq .login 2>/dev/null) && lform "$LOGIN" || gref 'your GitHub login could not be read'
    sowned; U=$(ghc repo view "$SREPO" --json url --jq .url 2>/dev/null) && [ -n "$U" ] || gref "no access to $SREPO"
    B=$W/share.git; git init -q --bare "$B" || gref 'a temporary repository could not be made'; mkdir "$W/nohooks"
    # G [<index>] <git args>: git on the temporary repository, no hook, no line-ending change; an index file given is the one used,
    # with GW the work tree (an empty folder unless the bundle's is set), never the project's
    mkdir "$W/wt"; GW=$W/wt
    G() { case "$1" in "$W"/i*) _gi=$1; shift; GIT_INDEX_FILE=$_gi GIT_WORK_TREE=$GW git -c core.bare=false -c core.hooksPath="$W/nohooks" -c core.autocrlf=false -c core.safecrlf=false --git-dir="$B" "$@" ;;
      *) git -c core.hooksPath="$W/nohooks" -c core.autocrlf=false -c core.safecrlf=false --git-dir="$B" "$@" ;; esac; }
    M=$(G ls-remote "$U" refs/heads/main 2>/dev/null | cut -f1)
    if [ -n "$M" ]; then G fetch -q "$U" "+refs/heads/main:refs/heads/main" 2>/dev/null || gref "$SREPO could not be fetched"
      ! G cat-file -e "$M:projects/$P/$N" 2>/dev/null || gref "projects/$P/$N is in $SREPO already: a run's folder is never overwritten; pick another run name"; fi
    GW=$F; G "$W/i1" add -A -f . || gref "the bundle's files could not be read"; GW=$W/wt
    T1=$(G "$W/i1" write-tree) || gref 'the bundle tree could not be written'
    if [ -n "$M" ]; then G "$W/i2" read-tree "$M"; else G "$W/i2" read-tree --empty; fi || gref 'the main tree could not be read'
    G "$W/i2" read-tree --prefix="projects/$P/$N/" "$T1" && T=$(G "$W/i2" write-tree) || gref 'the share tree could not be written'
    set -- -m "ViD share: projects/$P/$N"; [ -z "$M" ] || set -- -p "$M" "$@"
    # authored and committed as ViD <vid@export.invalid>, in the call's own environment, as spec-export's: no one's name or address
    C=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid \
      git -c core.hooksPath="$W/nohooks" --git-dir="$B" commit-tree "$T" "$@") || gref 'the share commit could not be made'
    sowned   # private and owned again, right before the push
    G push -q "$U" "$C:refs/heads/main" 2> "$W/push" || { sed 's/^/    /' "$W/push" >&2; gref "the share could not be pushed to $SREPO (a fast-forward of main only)"; }
    echo "ViD share: projects/$P/$N pushed to $SREPO as $(printf '%.12s' "$C")"; exit 0 ;;

  share-invite)   # 0.26.10.28.7 (R6): share-invite --repo <r> --who <login> --shown-write-words --second-yes
    auth; R=''; WHO=''; SW=''; SY=''
    while [ $# -gt 0 ]; do case "$1" in --repo) R=${2:-}; shift ;; --who) WHO=${2:-}; shift ;; --shown-write-words) SW=yes ;; --second-yes) SY=yes ;; *) usage ;; esac; shift; done
    [ -n "$R" ] && [ -n "$WHO" ] || usage
    [ "$SW" = yes ] && [ "$SY" = yes ] || gref 'an invitation needs --shown-write-words and --second-yes: the write-access words shown, then a yes to invite; nothing is invited'
    lform "$WHO" || gref "'$WHO' is not a GitHub login: nothing is invited"; srepo "$R"
    SHARE=yes; LOGIN=$(ghc api user --jq .login 2>/dev/null) && lform "$LOGIN" || gref 'your GitHub login could not be read'
    sowned; [ "$(printf '%s' "$WHO" | tr 'A-Z' 'a-z')" != "$(printf '%s' "$LOGIN" | tr 'A-Z' 'a-z')" ] || gref "$WHO is you: nothing is invited"
    TY=$(ghc api "users/$WHO" --jq .type 2>/dev/null) || gref "the account $WHO could not be read: nothing is invited"
    if [ "$SORG" = no ]; then [ "$TY" = User ] || gref "On a repository in a personal account, GitHub invites people only, not an organisation: $WHO reads as $TY. Nothing is invited."
    else [ "$TY" = User ] || gref "$WHO reads as $TY: the verb invites a person; a team of $SOWN is added by hand (the repository's Settings, Collaborators and teams)"; fi
    if ghc api "repos/$SREPO/collaborators/$WHO" > /dev/null 2>&1; then echo "ViD share: $WHO has access to $SREPO already: not invited again"; exit 0; fi
    ghc api "repos/$SREPO/invitations" --paginate --jq '.[].invitee.login' > "$W/inv" 2>/dev/null || gref "the invitations of $SREPO could not be read: nothing is invited"
    if tr 'A-Z' 'a-z' < "$W/inv" | grep -qxF "$(printf '%s' "$WHO" | tr 'A-Z' 'a-z')"; then echo "ViD share: $WHO is invited to $SREPO already, pending: not invited again"; exit 0; fi
    sowned   # private and owned again, right before the invitation
    if [ "$SORG" = yes ]; then ghc api -X PUT "repos/$SREPO/collaborators/$WHO" -f permission=pull > /dev/null || gref "$WHO could not be invited"; A=read
    else ghc api -X PUT "repos/$SREPO/collaborators/$WHO" > /dev/null || gref "$WHO could not be invited"; A=write; fi
    echo "ViD share: $WHO invited to $SREPO, $A access; to take it away: the repository's Settings, then Collaborators, then Remove"; exit 0 ;;

  *) usage ;;
esac
