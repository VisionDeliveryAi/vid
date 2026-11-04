#!/bin/sh
# Purpose: ViD's GitHub adapter (v0.26.10.9 spec R19, R22–R24) — the one file that calls `gh`, for ticket mode. Every
# call goes through `gh` under the login of whoever runs it: it never asks for, prints, passes or stores a token. The
# first act of every subcommand is `gh auth status`; a failing one stops it. The calls are an allow-list (ghc below):
# gh auth status, gh repo view|clone, gh label, gh issue create|edit|view|list|comment|close|reopen, gh pr create|edit|
# view|list|ready|comment|merge|checks|diff, gh run list|view|download, gh workflow run (v0.26.10.12 R3: the full run's
# manual start, run-full only), gh repo create (v0.26.10.12.3 R2: TW's spec-repo: alone, --private, spec-setup only),
# and gh api only for the milestone endpoints (repos/<repo>/milestones…), the sub-issue mutation (graphql
# addSubIssue) and an issue comment's edit (-X PATCH repos/<the code repository>/issues/comments/<id>, tw-post's
# amendment, fix 3). The code repository is the vid-code block's repo: (ARCHITECTURE.md) for the planner; the clone's
# .git/vid/repo for the stand-in.
# The ticket writer's subcommands (v0.26.10.12.3 R2, R7–R9; ViD's repository; repo:, spec-repo:
# and labels-prefix: read from .vid/tw/settings; each act a line of .vid/tw/log):
#   spec-setup   spec-repo: made private when missing (`gh repo create <it> --private`; `spec-repo <name> created`) or
#                checked private (`spec-repo <name> exists`; a public one refused); then spec-export.
#   spec-export  one commit of exactly PRD.md, DECISIONS.md, BASELINE.md, ARCHITECTURE.md, design/, GRADING-CHECKLIST.md
#                and TEST-DIFFERENCES.md (INVENTORY.md's difference lines, verbatim) at ViD's HEAD, a path not there
#                named and left out, built in a temporary index and .vid/spec.git (borrowing ViD's objects), authored and
#                committed as ViD <vid@export.invalid>, a fast-forward of the spec repository's main only; `export <c>
#                from=<ViD commit> state=pushed`, or `state=unchanged` when the tree is main's already (nothing pushed).
#   tw-sync      `sync main=<the code repository's main, git ls-remote> open=<TW's open tickets>` (each published one's
#                issue state).
#   tw-post [--amend <n>] <ticket>   refused when writer.sh check refuses it, writer.sh fresh finds it stale (the plan,
#                the export or its ticket work moved since it was written) or its export is not the spec repository's
#                main at ViD's HEAD; else an issue labelled <prefix>ticket (a placeholder, then the body and comments of
#                writer.sh parts), or issue n's body replaced, a comment naming the amendment, and each earlier writing's
#                part comment edited to say it is replaced, naming the current writing and its part comments (fix 3);
#                `published|amended <n> <the meta's fields> parts= at=`, then `sent <row> ticket=<n> hash=<h>` per row.
#   tw-close <n> a comment naming the newest plan change, the issue closed as not planned; `withdrawn <n> decision=`.
# The planner's setup (v0.26.10.12.3.1 R3), read only — gh auth status and gh repo view alone:
#   access       one line each: `access gh — signed in` (or not, then it stops); for repo: and, with layout: separate
#                (the default), spec-repo: of .vid/tw/settings — not set yet, reached (its permission, private or
#                public; a public spec repository is not ready) or not reached (gh's words); then `access: ok`, or
#                `access: <n> of <m> not ready`. Exit 0; 2 on a usage error. It never creates, edits or pushes.
# The planner's subcommands (ViD's repository; they write only issues, sub-issues, labels, comments and milestones):
#   publish [--ticket <file> [--issue <n> --why "<one line>"]]…   keeps GitHub in step with the plan: the labels
#                (<labels-prefix>ready, done, question, blocked); a milestone per stage, `Stage <n>: <name>`, its
#                description the stage's card in STAGES.md; an issue per step in its stage's milestone (its name:, the
#                REQ ids its rows derive from with each item's title, its modules:, "builds on #<issue>" per builds-on:);
#                and each ticket named — a new one an issue (the skeleton ticket in the first milestone; a feature or fix
#                ticket also a sub-issue of its step's issue) whose body is part 1 of `ticket.sh body` and whose comments
#                are parts 2 to n, labelled ready. --issue names the ticket a rewritten brief replaces: untaken (no
#                branch vid/<n> on the code repository), its body and parts are replaced; taken, a comment quotes the why
#                and the change. Idempotent by .vid/tickets/map: a second publish creates nothing, and edits only what
#                changed. Records `milestone stage= number= state=created|edited|closed` and `ticket issue= step= kind=
#                state=published|rewritten|commented`.
#   pull [--commit <sha>]   every ticket's state and labels, and whether it is taken, into .vid/tickets/state; every
#                pull request on a ticket's branch (open, draft or merged) into .vid/tickets/pr-<n>/ — meta, body.md,
#                comments/, runs (each run of its commits: `run id= attempt= sha= workflow= event= status= conclusion=
#                repo=`) and artifacts/<run>-<attempt>/ (the run's report, `gh run download --name vid-junit-<attempt>`;
#                a download that fails leaves <run>-<attempt>.none: no report; v0.26.10.12 R6: only a complete run's
#                report is downloaded, and a missing one is tried again at the next pull). Records the transitions first seen:
#                `ticket … state=taken|returned|merged`. --commit: main's runs at that commit, into
#                .vid/tickets/commit-<sha>/ (R18).
#   run-full     (v0.26.10.12 R3) no commit argument: fetches the read-only copy, starts the skeleton's manual run on
#                main (`gh workflow run <ci-workflow> --ref main`) and, once GitHub shows that run (a workflow_dispatch
#                run of the workflow newer than any before the start), records `run-full started run=<id> attempt=<n>
#                sha=<the run's own head commit, 12>`. Refused when the vid-code block names no run-full: (the merged
#                skeleton does not run every test on a manual start), when no pull request of a ticket of stages up to
#                RUN-STATE's stage: is merged, and when the run's commit does not descend from each of their merges
#                (the stage's last merge among them) — then nothing is recorded.
#   comment <issue> --body-file <f>   (`ticket … state=commented` for a ticket) · label <issue> [--add <l>]…
#                [--remove <l>]… (the prefix added) · close <issue> | close --milestone <stage> --commit <sha>
#                (the milestone's description names the commit; `milestone … state=closed commit=`).
# The stand-in's subcommands (the dev side, in a plain clone of the code repository; refused in a folder holding ViD's
# .vid/ — a checkout whose RUN-STATE says mode: tickets among them — so they never write the planner's records):
#   session --verb <name>   one line to .git/vid/sessions: `verb= session= transcript= at=` — the session id from
#                $CLAUDE_SESSION_ID, else the newest transcript in the session's own projects folder
#                ($HOME/.claude/projects/<the cwd, each character but a letter or digit as ->), its path the transcript.
#   clone <owner>/<repo> <dir> [--labels-prefix <p>]   gh repo clone, and <dir>/.git/vid/repo (and labels-prefix: the
#                prefix the planner's labels carry, as its vid-code block names it).
#   next-ticket --worker <k>   after `git fetch origin` and a fast-forward of main: `resume <n> unblocked|sent back`
#                for a ticket whose branch this worker claimed and whose pull request is a draft, labelled ready (not
#                blocked) or last commented `sent back`; else `next <n>` for the lowest open ready ticket with no
#                branch; else `none`. The chosen ticket's body and comments (and its pull request's comments) are saved
#                in .git/vid/tickets/<n>/.
#   claim <issue> --worker <k>   the claim commit, unique to the claimant, on the ticket's base (its part-1 header's
#                base=): `git commit-tree <base>^{tree} -p <base> -m "claim #<n> worker-<k>" -m "Stand-in: worker-<k>"`,
#                pushed only if the branch does not exist (`--force-with-lease=refs/heads/vid/<n>:`); refused, nothing
#                changes. Then `ticket.sh fetch` into .git/vid/tickets/<n>/ticket.md.
#   push <vid/<n>|main> [--worker <k>] [--pr <body file> [--draft]]   R24: only vid/<n>, never a force; main only
#                while the remote has no commit — the one empty root commit (`Initial commit`, `Stand-in: worker-<k>`),
#                made here when main has none. Refuses HEAD:main, any refspec with `:` or `+`, --force, any other name.
#                A branch whose changes touch .github/workflows/ needs the workflow scope (`gh auth refresh -s
#                workflow`). --pr opens the pull request ("Closes #<n>") or updates its description; without --draft
#                a draft is marked ready.
#   review --list   the open, non-draft pull requests on vid/<n> branches, `pr <n> vid/<k> head=<sha>` each.
#   review <pr> [--send-back <file>]   keeps the head it reviews (.git/vid/reviews/<pr>) and prints one line per
#                check: CI green on that head (gh pr checks); each of the ticket's test files present and byte-identical
#                to the ticket, or to the correction last sent (a ticket comment quoting it fenced under `#### <path>`);
#                every path the pull request changes against main as it is now (origin/main...head: a resumed branch
#                has merged origin/main) under the step's modules: or the shared: paths (section 16), or the ticket's tests —
#                anywhere for the skeleton ticket; the block passing `ticket.sh return-check`. Exit 1 on any refusal.
#                --send-back: a comment `sent back` with the reasons (the file) and the pull request returned to draft.
#   merge <pr>   only after a passing review: `gh pr merge --merge --match-head-commit <the reviewed head> --body
#                "Stand-in: approver"`, then a comment `merged` with the checks; GitHub refuses it when the head moved.
# Usage: sh checks/github.sh access | spec-setup|spec-export|tw-sync|tw-post … | publish|pull|run-full|comment|label|close … | session|clone|next-ticket|claim|push|review|merge …
set -u
IFS='
'
HERE=$(cd "$(dirname "$0")" && pwd)
usage() { echo 'ViD github: usage — sh checks/github.sh spec-setup | spec-export | tw-sync | tw-post [--amend <n>] <ticket> | tw-close <n> | publish [--ticket <file> [--issue <n> --why "<line>"]]… | pull [--commit <sha>] | run-full | comment <issue> --body-file <f> | label <issue> [--add <l>]… [--remove <l>]… | close <issue> | close --milestone <stage> --commit <sha> | session --verb <name> | clone <owner>/<repo> <dir> [--labels-prefix <p>] | next-ticket --worker <k> | claim <issue> --worker <k> | push <vid/<n>|main> [--worker <k>] [--pr <body file> [--draft]] | review --list | review <pr> [--send-back <file>] | merge <pr>' >&2; exit 2; }
gref() { echo "ViD github: refused — $*" >&2; exit 1; }
now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
REPO=''
# ghc: the one way to call gh — the allow-list, checked at every call
ghc() {
  case "$1 ${2:-}" in
    'auth status'|'repo view'|'repo clone'|'label create'|'issue create'|'issue edit'|'issue view'|'issue list'|'issue comment'|'issue close'|'issue reopen'|'pr create'|'pr edit'|'pr view'|'pr list'|'pr ready'|'pr comment'|'pr merge'|'pr checks'|'pr diff'|'run list'|'run view'|'run download'|'workflow run') ;;
    'repo create')   # v0.26.10.12.3 (R2, main's 7147906): the spec repository alone, private, and only in spec-setup
      [ "${SPECSETUP:-}" = yes ] && [ -n "${SPEC:-}" ] && [ "${3:-}" = "$SPEC" ] && [ "${4:-}" = --private ] && [ $# -eq 4 ] || gref "gh repo create is allowed for TW's spec-repo: alone, --private, in spec-setup" ;;
    'api graphql') _q=''; for _a in "$@"; do case "$_a" in query=*) _q=$_a ;; esac; done
      case "$_q" in query=mutation*addSubIssue*) ;; *) gref "gh api graphql is allowed for the sub-issue mutation only" ;; esac ;;
    api\ *) _p=''; _s=''; _m=''; for _a in "$@"; do if [ -n "$_s" ]; then [ "$_s" = X ] && _m=$_a; _s=''; continue; fi; case "$_a" in -X) _s=X ;; -f|-F|--jq) _s=1 ;; api) ;; *) _p=$_a ;; esac; done
      case "$_p" in "repos/$REPO/milestones"|"repos/$REPO/milestones/"[0-9]*) ;; "repos/$REPO/issues/comments/"[0-9]*) case "${_p##*/}" in *[!0-9]*) gref "not an issue comment: '$_p'" ;; esac
        [ "$_m" = PATCH ] || gref "gh api on an issue comment is allowed for its edit alone (-X PATCH)" ;; *) gref "gh api is allowed for the milestone, sub-issue and issue comment edit endpoints only, not '$_p'" ;; esac ;;
    *) gref "gh $1 ${2:-} is not on the allow-list" ;;
  esac
  for _a in "$@"; do case "$_a" in token|--with-*) gref 'a token is never asked for, printed, passed or stored' ;; esac; done
  gh "$@"
}
auth() { ghc auth status > "$W/auth" 2>&1 || { sed 's/^/    /' "$W/auth" >&2; gref 'gh auth status fails — log in with gh auth login (ViD never handles a token)'; }; }
ev() { if [ -f checks/event.sh ]; then sh checks/event.sh "$1" > /dev/null 2>&1 && return 0; fi; mkdir -p .vid; printf '%s at=%s\n' "$1" "$(now)" >> .vid/metrics-events; }
codekey() { [ -f ARCHITECTURE.md ] && sed -n '/^```vid-code[[:space:]]*$/,/^```[[:space:]]*$/p' ARCHITECTURE.md | sed -n "s/^$1:[[:space:]]*//p" | head -n 1 | sed 's/[[:space:]]*$//'; }
kv() { printf '%s\n' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -n 1; }
hsh() { git hash-object --stdin; }
num_of_url() { sed -n 's#.*/\([0-9][0-9]*\)$#\1#p' | tail -n 1; }
mapline() { [ -f .vid/tickets/map ] && awk -v w="$1" -v k="$2" -v v="$3" 'function g(x,  i) { for (i = 2; i <= NF; i++) if (index($i, x "=") == 1) return substr($i, length(x) + 2); return "" } $1 == w && g(k) == v { l = $0 } END { print l }' .vid/tickets/map; }
mapset() { # <what> <key> <value> <the whole new line>: replaces the line of that key, or adds it
  mkdir -p .vid/tickets; touch .vid/tickets/map
  awk -v w="$1" -v k="$2" -v v="$3" -v n="$4" 'function g(x,  i) { for (i = 2; i <= NF; i++) if (index($i, x "=") == 1) return substr($i, length(x) + 2); return "" } $1 == w && g(k) == v { if (!d) print n; d = 1; next } { print } END { if (!d) print n }' .vid/tickets/map > .vid/tickets/map.t && mv .vid/tickets/map.t .vid/tickets/map
}
planner() {
  [ -f .vid/RUN-STATE.md ] || gref "the planner's subcommands run in ViD's repository (no .vid/RUN-STATE.md here)"
  REPO=$(codekey repo); [ -n "$REPO" ] || gref "ARCHITECTURE.md's vid-code block names no repo: <owner>/<name>"
  PFX=$(codekey labels-prefix)
  auth
}
standin() {
  _t=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
  if [ -d "$_t/.vid" ]; then
    if grep -q '^mode:[[:space:]]*tickets' "$_t/.vid/RUN-STATE.md" 2>/dev/null; then gref "the stand-in's subcommands are refused here: this checkout's RUN-STATE says mode: tickets — the planner's repository"; fi
    gref "the stand-in's subcommands are refused in a folder holding ViD's .vid/ — the stand-in works in a plain clone of the code repository"
  fi
  auth
  REPO=$(cat "$(git rev-parse --git-dir 2>/dev/null)/vid/repo" 2>/dev/null)
}
standin_repo() { [ -n "$REPO" ] || gref "this clone has no .git/vid/repo — clone it with sh checks/github.sh clone <owner>/<repo> <dir>"; }
GD() { git rev-parse --absolute-git-dir; }
save_issue() { # <issue> <dir>: its body and its comments, as fetched
  mkdir -p "$2"; ghc issue view "$1" -R "$REPO" --json body --jq .body > "$2/body.md" || return 1
  _n=$(ghc issue view "$1" -R "$REPO" --json comments --jq '.comments | length'); _i=0
  while [ "$_i" -lt "${_n:-0}" ]; do ghc issue view "$1" -R "$REPO" --json comments --jq ".comments[$_i].body" > "$2/comment-$((_i + 1)).md"; _i=$((_i + 1)); done
}
save_prc() { # <pr> <dir> [<prefix>]: a pull request's comments
  mkdir -p "$2"; _n=$(ghc pr view "$1" -R "$REPO" --json comments --jq '.comments | length'); _i=0
  while [ "$_i" -lt "${_n:-0}" ]; do ghc pr view "$1" -R "$REPO" --json comments --jq ".comments[$_i].body" > "$2/${3:-}$((_i + 1)).md"; _i=$((_i + 1)); done
}
# v0.26.10.12.3 (R2, R7–R9): the ticket writer's — its settings (.vid/tw/settings), its log line
twkey() { sed -n "s/^$1:[[:space:]]*//p" .vid/tw/settings 2>/dev/null | head -n 1 | sed 's/[[:space:]]*$//'; }
twlog() { mkdir -p .vid/tw; printf '%s\n' "$1" >> .vid/tw/log; }
tw() {
  [ -f .vid/RUN-STATE.md ] || gref "the ticket writer's subcommands run in ViD's repository (no .vid/RUN-STATE.md here)"
  REPO=$(twkey repo); [ -n "$REPO" ] || gref ".vid/tw/settings names no repo: <owner>/<name>"
  SPEC=$(twkey spec-repo); PFX=$(twkey labels-prefix); auth
}
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
# specgit: .vid/spec.git, a bare repository whose objects borrow ViD's (alternates) — the export is built and pushed
# there; SG its path, SURL the spec repository's URL, SM its main (fetched), or empty (main 404–411)
specgit() {
  [ -n "$SPEC" ] || gref ".vid/tw/settings names no spec-repo: — sh checks/github.sh spec-setup first"
  SG=$(pwd -P)/.vid/spec.git
  [ -d "$SG" ] || { git init -q --bare "$SG" && git --git-dir="$SG" symbolic-ref HEAD refs/heads/main; } || gref "$SG could not be made"
  printf '%s/objects\n' "$(cd "$(git rev-parse --git-common-dir)" && pwd -P)" > "$SG/objects/info/alternates"
  SURL=$(ghc repo view "$SPEC" --json url --jq .url 2>/dev/null) && [ -n "$SURL" ] || gref "no access to the spec repository $SPEC: gh repo view $SPEC failed (sh checks/github.sh spec-setup makes it)"
  SM=$(git --git-dir="$SG" ls-remote "$SURL" refs/heads/main 2>/dev/null | cut -f1)
  if [ -n "$SM" ]; then git --git-dir="$SG" fetch -q "$SURL" "+refs/heads/main:refs/heads/main" 2>/dev/null || gref "the spec repository $SPEC could not be fetched (git needs its credentials: gh auth setup-git)"
  else git --git-dir="$SG" update-ref -d refs/heads/main 2>/dev/null || true; fi; }
prlist() { ghc pr list -R "$REPO" --state all --json number,headRefName,state,isDraft,headRefOid,mergeCommit --jq '.[] | [.number, .headRefName, .state, .isDraft, .headRefOid, (.mergeCommit.oid // "-")] | @tsv'; }

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
    M=$(git ls-remote "$U" refs/heads/main 2>/dev/null | cut -f1); O=''
    for n in $(awk '$1 == "published" { print $2 }' .vid/tw/log 2>/dev/null | sort -un); do grep -q "^withdrawn $n " .vid/tw/log && continue
      [ "$(ghc issue view "$n" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))' | cut -f1)" = OPEN ] && O="$O${O:+,}$n"; done
    twlog "sync main=${M:-none} open=${O:--} at=$(now)"; echo "ViD github: synced — main ${M:-none}, open tickets ${O:-none}"; exit 0 ;;

  tw-post)   # v0.26.10.12.3 (R3, R7–R9): a written ticket published, or open ticket <n> amended in place
    tw; A=''; if [ "${1:-}" = --amend ]; then A=${2:-}; shift 2; fi; F=${1:-}; [ -f "$F" ] && [ -f "${F%.md}.meta" ] || usage
    { sh "$HERE/writer.sh" gate && sh "$HERE/writer.sh" check "$F" && sh "$HERE/writer.sh" fresh "$F" $A; } > "$W/ck" 2>&1 || { sed 's/^/    /' "$W/ck" >&2; gref "the gate is shut, the check refuses $F, or it is stale — nothing posted"; }
    X=$(sed -n 's/^- export: //p' "$F" | head -n 1); exptree; specgit
    [ -n "$SM" ] && [ "$X" = "$SM" ] && [ "$(git --git-dir="$SG" rev-parse "$SM^{tree}")" = "$TR" ] || gref "the ticket's export ${X:-none} is not the spec repository's main at ViD's HEAD: sh checks/github.sh spec-export, then write it again"
    ghc label create "${PFX}ticket" -R "$REPO" --force --description 'ViD: a ticket' > /dev/null || gref "the label ${PFX}ticket could not be made"
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
    mkdir -p .vid/tw/out; cp "$W/t.md" ".vid/tw/out/issue-$N.md"; echo "ViD github: $K1 ticket #$N ($(grep -c . "$W/pl") parts)"; exit 0 ;;

  tw-close)   # v0.26.10.12.3 (R7): open ticket <n> withdrawn when writer.sh due owes it, by the change due names; never merged
    tw; N=${1:-}; case "$N" in ''|*[!0-9]*) usage ;; esac; grep -q "^published $N " .vid/tw/log 2>/dev/null || gref "#$N is no ticket TW published"
    { sh "$HERE/writer.sh" gate && sh "$HERE/writer.sh" due; } > "$W/ck" 2>&1 || { sed 's/^/    /' "$W/ck" >&2; gref "the gate is shut, or writer.sh due failed — #$N not withdrawn"; }
    PC=$(grep -E "^withdraw $N( |$)" "$W/ck") && [ "$(ghc issue view "$N" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))' | cut -f1)" = OPEN ] || gref "the round owes no withdrawal of #$N, or it is not open: a merged or closed ticket is never changed"; D=$(kv "$PC" decision)
    printf 'vid: withdrawn by plan change %s, what %s. This ticket is not to be merged; its rows are planned again.\n' "${D:-none}" "$(kv "$PC" what)" > "$W/wd"; ghc issue comment "$N" -R "$REPO" --body-file "$W/wd" > /dev/null && ghc issue close "$N" -R "$REPO" --reason 'not planned' > /dev/null || gref "#$N could not be withdrawn"
    twlog "withdrawn $N decision=${D:-none} at=$(now)"; echo "ViD github: withdrew ticket #$N"; exit 0 ;;

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

  publish)
    planner
    TF=''; while [ $# -gt 0 ]; do
      case "$1" in --ticket) printf 'T\t%s\t\t\n' "${2:-}" >> "$W/tk"; shift 2 ;; --issue) [ -s "$W/tk" ] || usage; awk -F'\t' -v n="${2:-}" -v last="$(grep -c . "$W/tk")" 'BEGIN { OFS = "\t" } NR == last { $3 = n } { print }' "$W/tk" > "$W/tk2" && mv "$W/tk2" "$W/tk"; shift 2 ;;
        --why) [ -s "$W/tk" ] || usage; printf '%s\n' "${2:-}" > "$W/why.$(grep -c . "$W/tk")"; shift 2 ;; *) usage ;; esac; done
    ghc repo view "$REPO" --json name --jq .name > /dev/null 2>&1 || gref "no access to $REPO's issues and pull requests: gh repo view $REPO failed"
    mkdir -p .vid/tickets; touch .vid/tickets/map
    # the labels
    for l in ready done question blocked; do
      [ -n "$(mapline label name "$PFX$l")" ] && continue
      ghc label create "$PFX$l" -R "$REPO" --force --description "ViD: $l" > /dev/null || gref "the label $PFX$l could not be made"
      mapset label name "$PFX$l" "label name=$PFX$l"
    done
    # the milestones: one per stage
    LO=1; NS=1
    if [ -f STAGES.md ]; then NS=$(sed -n '/^```vid-stages/,/^```$/p' STAGES.md | sed -n 's/^[[:space:]]*STAGE-0*\([0-9][0-9]*\)[[:space:]]*|.*/\1/p' | sort -n | tail -n 1); sed -n '/^```vid-stages/,/^```$/p' STAGES.md | grep -qE '^[[:space:]]*STAGE-0+[[:space:]]*\|' && LO=0; fi
    k=$LO; while [ "$k" -le "${NS:-1}" ]; do
      nm=$( [ -f STAGES.md ] && sed -n '/^```vid-stages/,/^```$/p' STAGES.md | awk -F'|' -v k="$k" '{ x = $1; gsub(/[ \t]/, "", x); sub(/^STAGE-0*/, "", x); if (x == "") x = 0; if (x == k) { n = $2; gsub(/^[ \t]+|[ \t]+$/, "", n); print n } }')
      [ -n "$nm" ] || nm='the product'
      if [ -f STAGES.md ]; then awk -v k="$k" 'on && /^## / { exit } $0 ~ "^## Stage " k "( |$)" { on = 1 } on' STAGES.md | sed '/^<!--/,/-->$/d' > "$W/card"; else printf 'One stage.\n' > "$W/card"; fi
      tt="Stage $k: $nm"; h=$( { printf '%s\n' "$tt"; cat "$W/card"; } | hsh)
      ml=$(mapline milestone stage "$k")
      if [ -z "$ml" ]; then
        mn=$(ghc api "repos/$REPO/milestones" -f "title=$tt" -f "description=$(cat "$W/card")" --jq .number) && [ -n "$mn" ] || gref "the milestone '$tt' could not be made"
        mapset milestone stage "$k" "milestone stage=$k number=$mn hash=$h"; ev "milestone stage=$k number=$mn state=created"
      elif [ "$(kv "$ml" hash)" != "$h" ]; then
        mn=$(kv "$ml" number); ghc api -X PATCH "repos/$REPO/milestones/$mn" -f "title=$tt" -f "description=$(cat "$W/card")" > /dev/null || gref "the milestone $mn could not be edited"
        mapset milestone stage "$k" "milestone stage=$k number=$mn hash=$h"; ev "milestone stage=$k number=$mn state=edited"
      fi
      k=$((k + 1)); done
    mtitle() { _mt=''; [ -f STAGES.md ] && _mt=$(sed -n '/^```vid-stages/,/^```$/p' STAGES.md | awk -F'|' -v k="$1" '{ x = $1; gsub(/[ \t]/, "", x); sub(/^STAGE-0*/, "", x); if (x == "") x = 0; if (x == k) { n = $2; gsub(/^[ \t]+|[ \t]+$/, "", n); print n } }'); printf 'Stage %s: %s' "$1" "${_mt:-the product}"; }
    # the step issues
    awk '/^## The plan/ { s = 1; next } s && /^## / { exit } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md > "$W/plan"
    git show HEAD:PRD.md > "$W/prd" 2>/dev/null || : > "$W/prd"; [ -f checks/prd.sh ] && sh checks/prd.sh --effective "$W/prd" > "$W/eff" 2>/dev/null || : > "$W/eff"
    sed -n '/^```vid-inventory/,/^```$/p' INVENTORY.md 2>/dev/null | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } tr($1) ~ /^ROW-/ { print tr($1) "\t" tr($7) }' > "$W/inv"
    stageof() { _r=$(printf '%s\n' "$1" | awk '{ print $1 }'); [ -n "$_r" ] && [ -f STAGES.md ] && [ -f checks/stages.sh ] && sh checks/stages.sh stage-of "$_r" 2>/dev/null || echo "$LO"; }
    for sl in $(grep -E '^[[:space:]]*step[[:space:]]' "$W/plan"); do
      sid=$(printf '%s\n' "$sl" | awk -F'|' '{ x = $1; sub(/^[ \t]*step[ \t]+/, "", x); gsub(/[ \t]+$/, "", x); print x }')
      fld() { printf '%s\n' "$sl" | awk -F'|' -v k="$1" '{ for (i = 2; i <= NF; i++) { x = $i; gsub(/^[ \t]+|[ \t]+$/, "", x); if (index(x, k ":") == 1) { x = substr(x, length(k) + 2); gsub(/^[ \t]+/, "", x); print x } } }'; }
      snm=$(fld name); smd=$(fld modules); sbo=$(fld builds-on); srw=$(fld rows)
      st=$(stageof "$srw"); case "$st" in ''|*[!0-9]*) st=$LO ;; esac
      { printf 'ViD plan step **%s** — %s\n\nModules: %s\n\nRequirements:\n' "$sid" "$snm" "${smd:--}"
        for r in $(printf '%s\n' "$srw" | tr ' ' '\n' | grep -v '^$'); do awk -F'\t' -v r="$r" '$1 == r { print $2 }' "$W/inv"; done | tr ', ' '\n\n' | grep -E '^(REQ|INV)-' | awk '!s[$0]++' | while IFS= read -r q; do
          ttl=$(awk -F'|' -v q="$q" '{ x = $1; gsub(/^[ \t]+|[ \t]+$/, "", x); sub(/[ \t]+AMENDED$/, "", x) } x == q { for (i = 2; i <= NF; i++) { y = $i; gsub(/^[ \t]+|[ \t]+$/, "", y); if (y ~ / / && y !~ /^[a-z_-]+:/) { print y; exit } } }' "$W/eff" | tail -n 1)
          printf -- '- %s — %s\n' "$q" "${ttl:-(not in the effective PRD)}"; done
        printf '\nRows: %s\n' "$(printf '%s\n' "$srw" | tr ' ' '\n' | grep -c . )"
        for b in $(printf '%s\n' "$sbo" | tr ' ,' '\n\n' | grep -v '^-$' | grep -v '^$'); do bn=$(kv "$(mapline step step "$b")" number); if [ -n "$bn" ]; then printf '\nbuilds on #%s\n' "$bn"; else printf '\nbuilds on %s (not yet published)\n' "$b"; fi; done
      } > "$W/sbody"
      h=$(cat "$W/sbody" | hsh); ml=$(mapline step step "$sid")
      if [ -z "$ml" ]; then
        n=$(ghc issue create -R "$REPO" --title "$snm ($sid)" --body-file "$W/sbody" --milestone "$(mtitle "$st")" | num_of_url) && [ -n "$n" ] || gref "the issue of step $sid could not be made"
        mapset step step "$sid" "step step=$sid number=$n hash=$h"
      elif [ "$(kv "$ml" hash)" != "$h" ]; then
        n=$(kv "$ml" number); ghc issue edit "$n" -R "$REPO" --body-file "$W/sbody" > /dev/null || gref "the issue of step $sid could not be edited"
        mapset step step "$sid" "step step=$sid number=$n hash=$h"
      fi
    done
    # the tickets
    i=0; [ -f "$W/tk" ] && while IFS='	' read -r _t tf ti _x; do
      i=$((i + 1)); [ -f "$tf" ] || gref "no ticket file $tf"
      TH=$(sed -nE 's/^written: (brief\.sh write|ticket\.sh skeleton-body) ([0-9a-f]*).*/\2/p' "$tf" | head -n 1); [ -n "$TH" ] || gref "$tf has no written: stamp"
      if grep -q '^kind: skeleton$' "$tf"; then TK=skeleton; TS=-; else case "$(sed -n '1s/^role: *\([a-z]*\).*/\1/p' "$tf")" in fixer) TK=fix ;; *) TK=feature ;; esac; TS=$(sed -n '1s/.*step: *\([^ ]*\).*/\1/p' "$tf"); fi
      STG=$(awk '/^## 16 / { on = 1; next } on && /^stage: / { print $2; exit }' "$tf"); [ -n "$STG" ] || STG=$LO
      [ -n "$ti" ] || ti=$(kv "$(mapline ticket brief "$tf")" number)
      if [ -z "$ti" ]; then
        if [ "$TK" = skeleton ]; then ttl='The code skeleton'; else ttl="$(kv "$(mapline step step "$TS")" number | sed 's/^/#/') $TS — $( [ "$TK" = fix ] && echo 'fix' || echo 'build')"; fi
        printf 'ViD is writing this ticket; its body follows in a moment.\n' > "$W/ph"
        n=$(ghc issue create -R "$REPO" --title "$ttl" --body-file "$W/ph" --milestone "$(mtitle "$STG")" --label "${PFX}ready" | num_of_url) && [ -n "$n" ] || gref "the ticket for $tf could not be made"
        sh "$HERE/ticket.sh" body "$tf" --issue "$n" --out "$W/parts.$n" > "$W/pl" || gref "the ticket's parts could not be written"
        ghc issue edit "$n" -R "$REPO" --body-file "$(sed -n 1p "$W/pl")" > /dev/null || gref "the body of ticket #$n could not be written"
        for p in $(sed 1d "$W/pl"); do ghc issue comment "$n" -R "$REPO" --body-file "$p" > /dev/null || gref "a part of ticket #$n could not be posted"; done
        if [ "$TK" != skeleton ]; then
          sp=$(kv "$(mapline step step "$TS")" number); [ -n "$sp" ] || gref "step $TS has no issue to hold ticket #$n"
          pid=$(ghc issue view "$sp" -R "$REPO" --json id --jq .id); cid=$(ghc issue view "$n" -R "$REPO" --json id --jq .id)
          ghc api graphql -f query='mutation($p: ID!, $c: ID!) { addSubIssue(input: {issueId: $p, subIssueId: $c}) { issue { number } } }' -f "p=$pid" -f "c=$cid" > /dev/null || gref "ticket #$n could not be made a sub-issue of #$sp"
        fi
        mapset ticket number "$n" "ticket number=$n step=$TS kind=$TK brief=$tf parts=$(grep -c . "$W/pl") hash=$TH"
        ev "ticket issue=$n step=$TS kind=$TK state=published"; echo "published: ticket #$n ($TK, $tf, $(grep -c . "$W/pl") parts)"
      else
        old=$(mapline ticket number "$ti"); [ -n "$old" ] || gref "ticket #$ti is not in .vid/tickets/map"
        [ "$(kv "$old" hash)" = "$TH" ] && continue
        if git -C .vid/code ls-remote --heads origin "refs/heads/vid/$ti" 2>/dev/null | grep -q .; then
          why=$(cat "$W/why.$i" 2>/dev/null); ob=$(kv "$old" brief)
          { printf 'vid: this ticket changed after it was taken — %s\n\nWhat changed (the ticket as first written, then as now):\n\n````diff\n' "${why:-the plan changed}"
            diff -u "$ob" "$tf" | sed '1,2d'; printf '````\n'; } > "$W/cm"
          ghc issue comment "$ti" -R "$REPO" --body-file "$W/cm" > /dev/null || gref "the change could not be posted on ticket #$ti"
          mapset ticket number "$ti" "ticket number=$ti step=$TS kind=$TK brief=$tf parts=$(kv "$old" parts) hash=$TH"
          ev "ticket issue=$ti step=$TS kind=$TK state=commented why=taken"; echo "commented: ticket #$ti is taken — the change is a comment"
        else
          sh "$HERE/ticket.sh" body "$tf" --issue "$ti" --out "$W/parts.$ti" > "$W/pl" || gref "the ticket's parts could not be written"
          ghc issue edit "$ti" -R "$REPO" --body-file "$(sed -n 1p "$W/pl")" > /dev/null || gref "the body of ticket #$ti could not be replaced"
          for p in $(sed 1d "$W/pl"); do ghc issue comment "$ti" -R "$REPO" --body-file "$p" > /dev/null || gref "a part of ticket #$ti could not be posted"; done
          mapset ticket number "$ti" "ticket number=$ti step=$TS kind=$TK brief=$tf parts=$(grep -c . "$W/pl") hash=$TH"
          ev "ticket issue=$ti step=$TS kind=$TK state=rewritten"; echo "rewritten: ticket #$ti (not taken)"
        fi
      fi
    done < "$W/tk"
    echo "ViD github: published — $(grep -c '^milestone ' .vid/tickets/map) milestones, $(grep -c '^step ' .vid/tickets/map) step issues, $(grep -c '^ticket ' .vid/tickets/map) tickets, $(grep -c '^label ' .vid/tickets/map) labels"
    exit 0 ;;

  pull)
    planner
    WF=$(codekey ci-workflow)
    runs_of() { # <sha> <dir>: the runs that tested it, and the reports of the CI workflow's
      ghc run list -R "$REPO" --commit "$1" --json databaseId,attempt,headSha,workflowName,event,status,conclusion --jq '.[] | [.databaseId, .attempt, .headSha, .workflowName, .event, .status, .conclusion] | @tsv' 2>/dev/null | while IFS='	' read -r id at sh wf evn stt con; do
        [ -n "$id" ] || continue
        printf 'run id=%s attempt=%s sha=%s workflow=%s event=%s status=%s conclusion=%s repo=%s\n' "$id" "$at" "$sh" "$(printf '%s' "$wf" | sed 's/ /%20/g')" "$evn" "$stt" "${con:--}" "$REPO" >> "$2/runs"
        [ -n "$WF" ] && [ "$wf" != "$WF" ] && continue
        a="$2/artifacts/$id-$at"; [ -d "$a" ] && continue
        # v0.26.10.12 (R6): a run not yet complete is fetched by a later pull, never marked as having no report; a
        # complete run's missing report is tried again at every pull, never cached as missing
        [ "$stt" = completed ] || { rm -f "$a.none"; continue; }
        mkdir -p "$2/artifacts"
        if ghc run download "$id" -R "$REPO" --name "vid-junit-$at" --dir "$a" > /dev/null 2>&1; then rm -f "$a.none"; else rm -rf "$a"; : > "$a.none"; fi
      done; }
    if [ "${1:-}" = --commit ]; then
      C=${2:-}; [ -n "$C" ] || usage; D=.vid/tickets/commit-$C; rm -f "$D/runs"; mkdir -p "$D"; runs_of "$C" "$D"
      echo "ViD github: main's runs at $C → $D ($(grep -c '^run ' "$D/runs" 2>/dev/null || echo 0) runs)"; exit 0
    fi
    mkdir -p .vid/tickets; : > "$W/state"
    git -C .vid/code ls-remote --heads origin 'refs/heads/vid/*' 2>/dev/null | sed 's#.*refs/heads/vid/##' > "$W/branches" || : > "$W/branches"
    seen() { [ -f .vid/metrics-events ] && grep -q "^ticket issue=$1 .*state=$2\( \|$\)" .vid/metrics-events; }
    for tl in $(grep '^ticket ' .vid/tickets/map 2>/dev/null); do
      n=$(kv "$tl" number); s=$(ghc issue view "$n" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))') || continue
      tk=no; grep -qx "$n" "$W/branches" && tk=yes
      printf 'ticket number=%s state=%s labels=%s taken=%s\n' "$n" "${s%%	*}" "$(printf '%s' "${s#*	}" | sed 's/^$/-/')" "$tk" >> "$W/state"
      [ "$tk" = yes ] && ! seen "$n" taken && ev "ticket issue=$n step=$(kv "$tl" step) kind=$(kv "$tl" kind) state=taken"
    done
    prlist > "$W/prs" || gref 'the pull requests could not be listed'
    while IFS='	' read -r p hb pst dr ho mc; do
      case "$hb" in vid/[0-9]*) ;; *) continue ;; esac; n=${hb#vid/}
      tl=$(mapline ticket number "$n"); [ -n "$tl" ] || continue
      D=.vid/tickets/pr-$p; mkdir -p "$D/comments"
      st=$(printf '%s' "$pst" | tr 'A-Z' 'a-z'); [ "$st" = closed ] && [ "$mc" != - ] && st=merged
      printf 'number=%s ticket=%s state=%s draft=%s head=%s merge=%s branch=%s\n' "$p" "$n" "$st" "$dr" "$ho" "$mc" "$hb" > "$D/meta"
      ghc pr view "$p" -R "$REPO" --json body --jq .body > "$D/body.md"
      rm -f "$D"/comments/*; save_prc "$p" "$D/comments"
      rm -f "$D/runs"; : > "$D/runs"
      for c in $(ghc pr view "$p" -R "$REPO" --json commits --jq '.commits[].oid'); do runs_of "$c" "$D"; done
      printf 'pr number=%s ticket=%s state=%s draft=%s head=%s merge=%s\n' "$p" "$n" "$st" "$dr" "$ho" "$mc" >> "$W/state"
      ! seen "$n" returned && ev "ticket issue=$n step=$(kv "$tl" step) kind=$(kv "$tl" kind) state=returned pr=$p"
      [ "$st" = merged ] && ! seen "$n" merged && ev "ticket issue=$n step=$(kv "$tl" step) kind=$(kv "$tl" kind) state=merged pr=$p"
    done < "$W/prs"
    cp "$W/state" .vid/tickets/state
    echo "ViD github: pulled — $(grep -c '^ticket ' .vid/tickets/state) tickets, $(grep -c '^pr ' .vid/tickets/state) pull requests → .vid/tickets/"
    exit 0 ;;

  run-full)
    planner; [ $# -eq 0 ] || usage
    WF=$(codekey ci-workflow)
    [ -n "$(codekey run-full)" ] || gref "ARCHITECTURE.md's vid-code block names no run-full: — the merged skeleton does not run every test on a manual start yet; its skeleton fix ticket comes first (vid-replan, \"An older skeleton\")"
    [ -n "$WF" ] || gref "ARCHITECTURE.md's vid-code block names no ci-workflow: — the skeleton's test facts come first"
    git -C .vid/code fetch -q 2>/dev/null || gref 'the read-only copy (.vid/code) cannot be fetched'
    STG=$(sed -n 's/^stage:[[:space:]]*//p' .vid/RUN-STATE.md 2>/dev/null | head -n 1 | awk '{ print $1 }'); case "$STG" in ''|*[!0-9]*) STG=1 ;; esac
    # the stage's merges: the merged pull requests of tickets of stages up to it (a skeleton ticket's is the first), as
    # pull recorded them; the full run's commit must descend from each, the stage's last merge among them
    : > "$W/merges"
    for m in .vid/tickets/pr-*/meta; do
      [ -f "$m" ] || continue; ml=$(cat "$m"); [ "$(kv "$ml" state)" = merged ] || continue
      mc=$(kv "$ml" merge); tb=$(kv "$(mapline ticket number "$(kv "$ml" ticket)")" brief); ts=''
      [ -n "$tb" ] && [ -f "$tb" ] && ts=$(awk '/^## 16 / { on = 1; next } on && /^stage: / { print $2; exit }' "$tb")
      case "$ts" in ''|*[!0-9]*) ts=0 ;; esac
      [ "$ts" -le "$STG" ] && [ -n "$mc" ] && [ "$mc" != - ] && printf '%s\t%s\n' "$mc" "$(kv "$ml" number)" >> "$W/merges"
    done
    [ -s "$W/merges" ] || gref "no pull request of a ticket of stages up to $STG is merged (sh checks/github.sh pull first) — there is nothing for a full run to close"
    rl() { ghc run list -R "$REPO" --workflow "$WF" --json databaseId,attempt,headSha,workflowName,event,status,conclusion --jq '.[] | [.databaseId, .attempt, .headSha, .workflowName, .event, .status, .conclusion] | @tsv' 2>/dev/null; }
    B=$(rl | awk -F'\t' '$1 + 0 > m { m = $1 + 0 } END { print m + 0 }')
    ghc workflow run "$WF" -R "$REPO" --ref main > /dev/null 2> "$W/wr" || { sed 's/^/    /' "$W/wr" >&2; gref "GitHub refused the manual start of $WF on main"; }
    i=0; L=''
    while [ "$i" -lt 30 ]; do
      L=$(rl | awk -F'\t' -v b="$B" '$5 == "workflow_dispatch" && $1 + 0 > b && $1 + 0 > m { m = $1 + 0; l = $0 } END { print l }')
      [ -n "$L" ] && break; i=$((i + 1)); sleep 2
    done
    [ -n "$L" ] || gref "the manual start of $WF was accepted, but GitHub shows no run of it after a minute — nothing recorded; look at the repository's Actions page, then start it again"
    RUN=$(printf '%s' "$L" | cut -f1); ATT=$(printf '%s' "$L" | cut -f2); SHA=$(printf '%s' "$L" | cut -f3)
    git -C .vid/code cat-file -e "$SHA^{commit}" 2>/dev/null || git -C .vid/code fetch -q 2>/dev/null
    git -C .vid/code cat-file -e "$SHA^{commit}" 2>/dev/null || gref "run $RUN tested $SHA, which is not in the read-only copy after fetching — nothing recorded"
    while IFS='	' read -r mc pn; do
      git -C .vid/code merge-base --is-ancestor "$mc" "$SHA" 2>/dev/null || gref "run $RUN tests $(printf '%s' "$SHA" | cut -c1-12), which does not descend from the merge of pull request #$pn ($(printf '%s' "$mc" | cut -c1-12)) — nothing recorded; start the full run again once main holds every merge of the stage"
    done < "$W/merges"
    S12=$(printf '%s' "$SHA" | cut -c1-12)
    ev "run-full started run=$RUN attempt=$ATT sha=$S12"
    echo "ViD github: the full run started — run $RUN (attempt $ATT) of $WF on main at $S12; once it completes: sh checks/github.sh pull --commit $S12"
    exit 0 ;;

  comment)
    planner; n=${1:-}; [ "${2:-}" = --body-file ] && [ -f "${3:-}" ] || usage
    ghc issue comment "$n" -R "$REPO" --body-file "$3" > /dev/null || gref "the comment on #$n could not be posted"
    tl=$(mapline ticket number "$n"); [ -n "$tl" ] && ev "ticket issue=$n step=$(kv "$tl" step) kind=$(kv "$tl" kind) state=commented"
    echo "ViD github: commented on #$n"; exit 0 ;;

  label)
    if [ -f .vid/RUN-STATE.md ]; then planner; else standin; standin_repo; PFX=$(cat "$(GD)/vid/labels-prefix" 2>/dev/null); fi
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

  session)
    standin; [ "${1:-}" = --verb ] && [ -n "${2:-}" ] || usage
    PD="$HOME/.claude/projects/$(pwd -P | sed 's/[^A-Za-z0-9]/-/g')"
    TR=''; SID=${CLAUDE_SESSION_ID:-}
    if [ -n "$SID" ] && [ -f "$PD/$SID.jsonl" ]; then TR=$PD/$SID.jsonl
    else TR=$(ls -t "$PD"/*.jsonl 2>/dev/null | head -n 1); [ -n "$TR" ] && SID=$(basename "$TR" .jsonl); fi
    mkdir -p "$(GD)/vid"; printf 'verb=%s session=%s transcript=%s at=%s\n' "$2" "${SID:-unknown}" "${TR:-unknown}" "$(now)" >> "$(GD)/vid/sessions"
    echo "ViD github: session ${SID:-unknown} recorded for $2 in $(GD)/vid/sessions"; exit 0 ;;

  clone)
    R=${1:-}; DIR=${2:-}; [ -n "$R" ] && [ -n "$DIR" ] || usage; LPF=''; [ "${3:-}" = --labels-prefix ] && LPF=${4:-}
    [ -d "$(pwd -P)/.vid" ] && gref "the stand-in's subcommands are refused in a folder holding ViD's .vid/"
    REPO=$R; auth
    ghc repo clone "$R" "$DIR" > /dev/null 2>&1 || gref "gh repo clone $R failed"
    mkdir -p "$DIR/.git/vid"; printf '%s\n' "$R" > "$DIR/.git/vid/repo"; printf '%s\n' "$LPF" > "$DIR/.git/vid/labels-prefix"
    echo "ViD github: cloned $R into $DIR"; exit 0 ;;

  next-ticket)
    standin; standin_repo; [ "${1:-}" = --worker ] && WK=${2:-} || usage; [ -n "$WK" ] || usage
    git fetch -q origin 2>/dev/null
    # the fast-forward of main, whichever branch is checked out (the resume merges main into the ticket's branch next)
    if [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" = main ]; then git merge -q --ff-only origin/main 2>/dev/null
    elif git rev-parse -q --verify refs/heads/main > /dev/null; then git merge-base --is-ancestor refs/heads/main origin/main 2>/dev/null && git update-ref refs/heads/main origin/main
    else git branch -q main origin/main 2>/dev/null; fi
    PFX=$(cat "$(GD)/vid/labels-prefix" 2>/dev/null)
    prlist > "$W/prs" 2>/dev/null || : > "$W/prs"
    git ls-remote --heads origin 'refs/heads/vid/*' 2>/dev/null | sed 's#.*refs/heads/vid/##' > "$W/branches"
    pick() { save_issue "$1" "$(GD)/vid/tickets/$1" || gref "ticket #$1 could not be read"; }
    for n in $(ghc issue list -R "$REPO" --state open --json number --jq '.[].number' | sort -n); do
      grep -qx "$n" "$W/branches" || continue
      fc=$(git rev-list --reverse "origin/main..origin/vid/$n" 2>/dev/null | head -n 1); [ -n "$fc" ] || continue
      git log -1 --format=%B "$fc" | grep -qx "Stand-in: worker-$WK" || continue
      pl=$(awk -F'\t' -v b="vid/$n" '$2 == b && $3 == "OPEN"' "$W/prs" | tail -n 1); [ -n "$pl" ] || continue
      [ "$(printf '%s' "$pl" | cut -f4)" = true ] || continue
      p=$(printf '%s' "$pl" | cut -f1); s=$(ghc issue view "$n" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))'); lb=",${s#*	},"
      save_prc "$p" "$W/prc.$p" c
      lc=$(ls "$W/prc.$p" 2>/dev/null | sed 's/^c//; s/\.md$//' | sort -n | tail -n 1)
      why=''; case "$lb" in *",${PFX}ready,"*) case "$lb" in *",${PFX}blocked,"*) ;; *) why=unblocked ;; esac ;; esac
      [ -n "$lc" ] && head -n 1 "$W/prc.$p/c$lc.md" | grep -qi '^sent back' && why='sent back'
      [ -n "$why" ] || continue
      pick "$n"; mkdir -p "$(GD)/vid/tickets/$n"; for f in "$W/prc.$p"/*.md; do [ -f "$f" ] && cp "$f" "$(GD)/vid/tickets/$n/pr-comment-$(basename "$f" | sed 's/^c//')"; done
      echo "resume $n $why"; exit 0
    done
    for n in $(ghc issue list -R "$REPO" --state open --label "${PFX}ready" --json number --jq '.[].number' | sort -n); do
      grep -qx "$n" "$W/branches" && continue
      pick "$n"; echo "next $n"; exit 0
    done
    echo none; exit 0 ;;

  claim)
    standin; standin_repo; n=${1:-}; [ -n "$n" ] || usage; [ "${2:-}" = --worker ] && WK=${3:-} || usage; [ -n "$WK" ] || usage
    TD="$(GD)/vid/tickets/$n"; [ -f "$TD/body.md" ] || save_issue "$n" "$TD" || gref "ticket #$n could not be read"
    BASE=$(tr -d '\r' < "$TD/body.md" | sed -n '2p' | tr ' ' '\n' | sed -n 's/^base=//p')
    [ -n "$BASE" ] || gref "ticket #$n's body has no base= in its vid-ticket header"
    git fetch -q origin 2>/dev/null
    git cat-file -e "$BASE^{commit}" 2>/dev/null || gref "the ticket's base $BASE is not in this clone after fetching"
    CC=$(git -c user.email="worker-$WK@stand-in" -c user.name="worker-$WK" commit-tree "$BASE^{tree}" -p "$BASE" -m "claim #$n worker-$WK" -m "Stand-in: worker-$WK") || gref 'the claim commit could not be made'
    if ! git push -q --force-with-lease="refs/heads/vid/$n:" origin "$CC:refs/heads/vid/$n" 2> "$W/push"; then
      echo "ViD github: claim refused — vid/$n exists already (someone took the ticket); take the next one" >&2; exit 1; fi
    printf 'claim=%s base=%s worker=%s at=%s\n' "$CC" "$BASE" "$WK" "$(now)" > "$TD/claim"
    sh "$HERE/ticket.sh" fetch "$n" --from "$TD" --out "$TD/ticket.md" || gref "ticket #$n's parts do not join"
    echo "ViD github: claimed #$n — vid/$n at $CC (parent $BASE)"; exit 0 ;;

  push)
    standin; standin_repo
    RF=${1:-}; [ -n "$RF" ] || usage; shift
    WK=1; PRB=''; DRAFT=no
    while [ $# -gt 0 ]; do case "$1" in --worker) WK=${2:-1}; shift 2 ;; --pr) PRB=${2:-}; shift 2 ;; --draft) DRAFT=yes; shift ;; *) gref "push takes a branch name and --worker/--pr/--draft, never '$1'" ;; esac; done
    case "$RF" in *:*|+*|-*) gref "push takes a branch name, never a refspec or a flag: '$RF'" ;; esac
    if [ "$RF" = main ]; then
      git ls-remote --heads origin 2>/dev/null | grep -q . && gref "main is pushed once, as the empty repository's root commit, and the remote has commits already"
      if ! git rev-parse -q --verify refs/heads/main > /dev/null 2>&1; then
        git checkout -q --orphan main 2>/dev/null; git rm -rq --cached . > /dev/null 2>&1 || true
        git -c user.email="worker-$WK@stand-in" -c user.name="worker-$WK" commit -q --allow-empty -m 'Initial commit' -m "Stand-in: worker-$WK" || gref 'the root commit could not be made'
      fi
      [ "$(git rev-list --count refs/heads/main)" = 1 ] && [ "$(git rev-parse 'refs/heads/main^{tree}')" = "$(git hash-object -t tree /dev/null)" ] && git log -1 --format=%B refs/heads/main | grep -q '^Stand-in: ' || gref 'main may hold only the one empty root commit, with its Stand-in: trailer'
      git push -q origin refs/heads/main:refs/heads/main || gref 'the root commit could not be pushed'
      echo "ViD github: pushed the root commit $(git rev-parse --short=12 refs/heads/main) to main"; exit 0
    fi
    case "$RF" in vid/[0-9]*) case "${RF#vid/}" in *[!0-9]*) gref "push takes vid/<n>, not '$RF'" ;; esac ;; *) gref "push takes vid/<n> (or main, once, on an empty repository), not '$RF'" ;; esac
    git rev-parse -q --verify "refs/heads/$RF" > /dev/null || gref "no local branch $RF"
    git fetch -q origin 2>/dev/null
    if git diff --name-only origin/main "refs/heads/$RF" 2>/dev/null | grep -q '^\.github/workflows/' && ! grep -q "'workflow'" "$W/auth"; then
      gref "this branch changes .github/workflows/, and the login lacks the workflow scope: run gh auth refresh -s workflow"; fi
    git push -q origin "refs/heads/$RF:refs/heads/$RF" || gref "the push of $RF was refused (a push never forces)"
    echo "ViD github: pushed $RF"
    if [ -n "$PRB" ]; then
      [ -f "$PRB" ] || gref "no description file $PRB"
      n=${RF#vid/}; ex=$(prlist | awk -F'\t' -v b="$RF" '$2 == b && $3 == "OPEN" { print $1 "\t" $4 }' | tail -n 1)
      if [ -z "$ex" ]; then
        set -- --head "$RF" --base main --title "Ticket #$n" --body-file "$PRB"; [ "$DRAFT" = yes ] && set -- "$@" --draft
        p=$(ghc pr create -R "$REPO" "$@" | sed -n 's#.*/pull/\([0-9][0-9]*\)$#\1#p') && [ -n "$p" ] || gref 'the pull request could not be opened'
        echo "ViD github: pull request #$p opened$( [ "$DRAFT" = yes ] && echo ' (draft)')"
      else
        p=${ex%%	*}; ghc pr edit "$p" -R "$REPO" --body-file "$PRB" > /dev/null || gref "the description of #$p could not be updated"
        if [ "$DRAFT" = no ] && [ "${ex#*	}" = true ]; then ghc pr ready "$p" -R "$REPO" > /dev/null || gref "#$p could not be marked ready"; fi
        if [ "$DRAFT" = yes ] && [ "${ex#*	}" = false ]; then ghc pr ready "$p" -R "$REPO" --undo > /dev/null || gref "#$p could not be returned to draft"; fi
        echo "ViD github: pull request #$p updated"
      fi
    fi
    exit 0 ;;

  review)
    standin; standin_repo; P=${1:-}; [ -n "$P" ] || usage; shift
    if [ "$P" = --list ]; then   # the approver's loop: open, non-draft pull requests on vid/<n> branches
      prlist | awk -F'\t' '$2 ~ /^vid\/[0-9]+$/ && $3 == "OPEN" && $4 == "false" { print "pr " $1 " " $2 " head=" $5 }'; exit 0
    fi
    if [ "${1:-}" = --send-back ]; then [ -f "${2:-}" ] || usage; { printf 'sent back\n\n'; cat "$2"; } > "$W/sb"
      ghc pr comment "$P" -R "$REPO" --body-file "$W/sb" > /dev/null || gref "the send-back could not be posted on #$P"
      ghc pr ready "$P" -R "$REPO" --undo > /dev/null || gref "#$P could not be returned to draft"
      echo "ViD github: #$P sent back, returned to draft"; exit 0
    fi
    L=$(ghc pr view "$P" -R "$REPO" --json headRefOid,headRefName,isDraft --jq '[.headRefOid, .headRefName, .isDraft] | @tsv') || gref "no pull request #$P"
    HD=$(printf '%s' "$L" | cut -f1); HB=$(printf '%s' "$L" | cut -f2)
    case "$HB" in vid/[0-9]*) n=${HB#vid/} ;; *) gref "#$P is not on a vid/<n> branch" ;; esac
    TD="$(GD)/vid/tickets/$n"; rm -rf "$TD.r"; save_issue "$n" "$TD.r" || gref "ticket #$n could not be read"
    sh "$HERE/ticket.sh" fetch "$n" --from "$TD.r" --out "$TD.r/ticket.md" > /dev/null || gref "ticket #$n's parts do not join"
    TF=$TD.r/ticket.md; git fetch -q origin 2>/dev/null
    git rev-parse -q --verify refs/remotes/origin/main > /dev/null || gref "this clone has no origin/main after fetching — the changed paths cannot be read"
    git cat-file -e "$HD^{commit}" 2>/dev/null || gref "the head $HD is not in this clone"
    BAD=0
    if ghc pr checks "$P" -R "$REPO" > "$W/checks" 2>&1; then echo "review: ci green on $HD"; else echo "review: ci not green on $HD"; BAD=1; fi
    KND=feature; grep -q '^kind: skeleton$' "$TF" && KND=skeleton
    # the ticket's tests, with the correction last sent (a comment quoting a file fenced under #### <path>)
    awk '/^## [0-9]/ { on = ($2 == 16); next } on && /^### / { acc = ($0 == "### Acceptance tests"); next } on && acc && f == "" && /^#### / { p = substr($0, 6); k++; print p > (d "/tl"); w = 1; next } w && NF == 0 { next } w { w = 0; f = $0; o = d "/t." k; printf "" > o; next } f != "" && $0 == f { f = ""; close(o); next } f != "" { print > o }' d="$W" "$TF"
    for c in $(ls "$TD.r"/comment-*.md 2>/dev/null | sort -t- -k2 -n); do
      tr -d '\r' < "$c" | awk -v d="$W" '/^#### tests\// { p = substr($0, 6); q = p; gsub(/\//, "%", q); w = 1; next } w && NF == 0 { next } w { w = 0; f = $0; o = d "/cor." q; printf "" > o; next } f != "" && $0 == f { f = ""; close(o); next } f != "" { print > o }'
    done
    k=0; [ -f "$W/tl" ] && for p in $(cat "$W/tl"); do
      k=$((k + 1)); q=$(printf '%s' "$p" | sed 's#/#%#g'); want=$W/t.$k; [ -f "$W/cor.$q" ] && want=$W/cor.$q
      if ! git cat-file -e "$HD:$p" 2>/dev/null; then echo "review: test missing at the head — $p"; BAD=1
      elif git show "$HD:$p" | cmp -s - "$want"; then echo "review: test unchanged — $p"; else echo "review: test changed — $p"; BAD=1; fi
    done
    BASE=$(awk '/^## 16 / { on = 1; next } on && /^base: / { print $2; exit }' "$TF"); [ -n "$BASE" ] || BASE=$(sed -n 's/^base:[[:space:]]*//p' "$TF" | head -n 1)
    if [ "$KND" = skeleton ]; then echo 'review: paths free (the skeleton ticket)'
    else
      MODS=$(awk '/^## 16 / { on = 1; next } on && /^modules: / { sub(/^modules: /, ""); print; exit }' "$TF"); SHR=$(awk '/^## 16 / { on = 1; next } on && /^shared: / { sub(/^shared: /, ""); print; exit }' "$TF")
      # the pull request's own changes: against main as it is now (a resumed branch merges origin/main), as GitHub lists
      # them; a diff that cannot be read is a refusal, never an empty list
      if ! git diff --name-only "origin/main...$HD" > "$W/chg" 2>/dev/null; then echo 'review: paths unknown — the diff against origin/main could not be read'; BAD=1
      else
        OUTP=$(while IFS= read -r f; do
            ok=no; grep -qxF -- "$f" "$W/tl" 2>/dev/null && ok=yes
            for m in $(printf '%s %s\n' "$MODS" "$SHR" | tr ' ,' '\n\n' | grep -v '^-$' | grep -v '^$'); do m=${m%/}; case "$f" in ("$m"|"$m"/*) ok=yes ;; esac; done
            [ "$ok" = yes ] || printf '%s\n' "$f"; done < "$W/chg")
        if [ -z "$OUTP" ]; then echo 'review: paths inside the modules and shared paths'; else echo "review: paths outside the step — $(printf '%s\n' "$OUTP" | paste -sd ',' - | sed 's/,/, /g')"; BAD=1; fi
      fi
    fi
    ghc pr view "$P" -R "$REPO" --json body --jq .body > "$W/body.md"
    if sh "$HERE/ticket.sh" return-check "$W/body.md" --ticket "$TF" > "$W/rc" 2>&1; then echo 'review: block ok'; else echo 'review: block refused —'; sed 's/^/    /' "$W/rc"; BAD=1; fi
    mkdir -p "$(GD)/vid/reviews"
    if [ "$BAD" = 0 ]; then printf 'pr=%s head=%s result=ok at=%s\n' "$P" "$HD" "$(now)" > "$(GD)/vid/reviews/$P"; echo "ViD github: review of #$P passed at head $HD"; exit 0; fi
    printf 'pr=%s head=%s result=refused at=%s\n' "$P" "$HD" "$(now)" > "$(GD)/vid/reviews/$P"; echo "ViD github: review of #$P refused — send it back with the reasons above"; exit 1 ;;

  merge)
    standin; standin_repo; P=${1:-}; [ -n "$P" ] || usage
    RV="$(GD)/vid/reviews/$P"; [ -f "$RV" ] && grep -q ' result=ok ' "$RV" || gref "#$P has no passing review — sh checks/github.sh review $P first"
    HD=$(tr ' ' '\n' < "$RV" | sed -n 's/^head=//p')
    if ! ghc pr merge "$P" -R "$REPO" --merge --match-head-commit "$HD" --body 'Stand-in: approver' > "$W/m" 2>&1; then
      sed 's/^/    /' "$W/m" >&2; rm -f "$RV"; gref "GitHub refused the merge of #$P (the head moved from the reviewed $HD?) — review the new head"; fi
    { printf 'merged\n\nreviewed at %s:\n' "$HD"; sed -n 's/^/- /p' "$RV"; } > "$W/mc"
    ghc pr comment "$P" -R "$REPO" --body-file "$W/mc" > /dev/null || true
    echo "ViD github: #$P merged at the reviewed head $HD"; exit 0 ;;

  *) usage ;;
esac
