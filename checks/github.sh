#!/bin/sh
# Purpose: ViD's GitHub adapter (v0.26.10.9 spec R19, R22–R24) — the one file that calls `gh`, for ticket mode. Every
# call goes through `gh` under the login of whoever runs it: it never asks for, prints, passes or stores a token. The
# first act of every subcommand is `gh auth status`; a failing one stops it. The calls are an allow-list (ghc below):
# gh auth status, gh repo view, gh label create, gh issue create|edit|view|list|comment|close|reopen (GM-4 K1: reopen, tw-reopen's), gh pr view|list|comment,
# gh repo create (v0.26.10.12.3 R2; FB-2 A1: the one repository mkrepo was given, repo:, spec-repo: or state-repo:, --private), and gh api only for the
# milestone endpoints (repos/<repo>/milestones…) and an issue comment's edit (-X PATCH repos/<the code
# repository>/issues/comments/<id>, tw-post's amendment, fix 3); GM-2 T3, for tw-post's first post in GitHub manual's form: a read
# of an issue's id (repos/<repo>/issues/<n>, a GET), and -X POST of one field to repos/<repo>/issues/<p>/sub_issues (sub_issue_id)
# and to repos/<repo>/issues/<n>/dependencies/blocked_by (issue_id), no other method, endpoint or field. FB-3 A2: gh api graphql, one read-only
# query of one repository, in results-fetch alone. 0.26.10.28.1 (9.1 C1, stage 9 S2): the first ticket
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
#   code-setup   (FB-2 A1) repo:, the code repository, made private and empty when missing (`repo <name> created`), or used as it
#                is (`repo <name> exists`). It, spec-setup and state-setup make through mkrepo, at the connect's repositories' step.
#   spec-export  one commit of exactly PRD.md, DECISIONS.md, BASELINE.md, ARCHITECTURE.md, design/, GRADING-CHECKLIST.md
#                and TEST-DIFFERENCES.md (INVENTORY.md's difference lines, verbatim) at ViD's HEAD, a path not there
#                named and left out, built in a temporary index and .vid/spec.git (borrowing ViD's objects), authored and
#                committed as ViD <vid@export.invalid>, a fast-forward of the spec repository's main only; `export <c>
#                from=<ViD commit> state=pushed`, or `state=unchanged` when the tree is main's already (nothing pushed).
#                FB-3 B2: with layout: one in GitHub manual (xlocal) the export is kept in the project, at refs/vid/export of ViD's
#                repository (state-save's bundle holds it), `state=local`, its dates the applied commit's, and no spec repository is made,
#                read or pushed; elsewhere the ref follows each export, so a project that changes mode keeps one line of exports.
#                GM-2 T1: in GitHub manual every path at the applied commit (.vid/tw/applied), with the issue form issue-form:
#                names at HEAD, and its commit is main's tree with the export's own files replaced (those it puts there now,
#                and those an earlier export put there, read from main's history), every other file kept; unchanged, and
#                tw-post's freshness check, compare the export's own files alone.
#   tw-sync      `sync main=<the code repository's main, git ls-remote> open=<TW's open tickets>` (each published one's
#                issue state). v0.26.10.28.2 (R3): main=none for an empty repository alone, main=absent for heads with no main; a failed read
#                is refused and records nothing.
#   decide-blocked <issue> <pr>, decide-post <pr> <file>   v0.26.10.24.6: the blocked label, and the decision's comment, for checks/decide.sh
#   spec-stamp   GM-4 K13, read only: with layout: one and spec-stamp:, the first line of the stamp file <spec-path>/<spec-stamp> on
#                the code repository's main (gh api repos/<repo>/contents/<file>?ref=<main's commit>, a GET), the export commit the
#                folder holds; nothing when no stamp is set or found. /vid mode's take-stock reads it (checks/mode.sh)
#   spec-folder   FB-4 B1, read only, in GitHub manual with layout: one (nothing read in another): the names and blob ids of the files in
#                the folder spec-path: on the code repository's main (fold's GETs of git/trees, no file's content), kept in
#                .vid/round/folder for lib.sh's folderis; the repository, its main and spec-path: as the kept read names them, no GET;
#                no main yet, or a read that fails (exit 1, said), leaves the file out
#   record-read <link>   IR I1: a record the owner names by its GitHub link, read only: <link> is a blob link at a commit,
#                https://github.com/<owner>/<repo>/blob/<40-hex sha>/<path>, or a pull request, https://github.com/<owner>/<repo>/pull/<n>.
#                For each file (the blob's; or each Markdown file the pull request changes and does not delete, read at its head commit,
#                in path order) one line `record: <the blob link at that commit>`, then the file's text. Its calls are GETs alone, of
#                repos/<owner>/<repo>/pulls/<n>, its files and contents/<path>?ref=<sha>; it writes nothing anywhere (no record, no cache,
#                no GitHub write; the start-up recovery of a stranded .vid/.old.<pid>.<name> folder is skipped), each name read as itself,
#                never as a pattern. Refused: a run anywhere but the top of ViD's repository, a link of neither form, a blob link at a
#                branch or tag or whose path holds ? or # (a line permalink), a pull request with no Markdown file, and in GitHub
#                manual, where a record reaches ViD only as the owner's copy committed in ViD's repository.
#   pr-body <pr>   0.26.10.29.5 (DP-1 R2, R8): the pull request's description, printed whole, read only (gh pr view), for checks/decide.sh's
#                Decisions section and checks/decisions.sh record
#   results-fetch   v0.26.10.24.5: .vid/code, the copy checks/results.sh reads: 0.26.10.28.4 (M5), the vid-results/* reports and every other head's commits, no file of the code;
#                FB-3 A2: of a report branch its own folder alone, the rest never named or sent; one with no such folder left out, in .vid/round/reports-skipped
#   pr-files <p> [<path>]   FB-3 A1.4: GitHub's list of a pull request's files (a GET of repos/<repo>/pulls/<p>/files), printed and kept nowhere, no file
#                of it written: a line a file, its path, status, lines added and deleted, earlier path and patch|none (none: GitHub gives no
#                change), tab-separated; with a path, that file's line less its path, then its change. checks/review.sh show's one read
#   closing-prs <issue>…   FB-3 A1.4: the merged pull requests GitHub keeps as closing each issue, `<issue> <p> <merge>` tab-separated, read
#                only: a graphql query of 50 issues; a number that is no issue is left out
#   own-refs     FB-3 A1.4: ViD's own reviews, .vid/decide/review/<id>/, as the refs vid-results/<id> of .vid/code (results-fetch makes them too)
#                0.26.10.28.1 (S5): a working clone found there is moved aside to .vid/code.old-<UTC>, saying so, and the bare copy cloned
#   tw-post [--amend <n>] [--words "<w>"] [--title "<t>"] <ticket>   (--words and --title in GitHub manual alone) refused when writer.sh check refuses it, writer.sh fresh finds it stale (the plan,
#                the export or its ticket work moved since it was written) or its export is not the spec repository's
#                main at ViD's HEAD; else an issue labelled <prefix>ticket (a placeholder, then the body and comments of
#                writer.sh parts), or issue n's body replaced, a comment naming the amendment, and each earlier writing's
#                part comment edited to say it is replaced, naming the current writing and its part comments (fix 3);
#                `published|amended <n> <the meta's fields> parts= at=`, then `sent <row> ticket=<n> hash=<h>` per row.
#                GM-4 F6: the issue form below is the setup's (issue-form: set), in either mode; without it part 1 is the body.
#                GM-2 T3: in GitHub manual a first post takes the owner's words (--words, refused without them) and may take a title
#                in them (--title); it is made in the project's own issue form (issue-form:, at HEAD; refused without it, or for a
#                placeholder it does not know, or a form lacking one every ticket needs), every part a comment, a sub-issue of
#                issue-parent: when set, blocked by the tickets of the steps it builds on, and each published ticket whose step
#                builds on its own blocked by it; its line ends `form=<the form's hash> words="<the words>"`, with .vid/tw/form/issue-<n>
#                and .vid/tw/body/issue-<n> (§5). The calls it adds: gh api repos/<repo>/issues/<n> (a read of its id), and, in that
#                post alone, -X POST …/issues/<p>/sub_issues -F sub_issue_id=<id> and …/issues/<n>/dependencies/blocked_by -F issue_id=<id>.
#                GM-2 T5, T6: in GitHub manual an amendment (--amend <n>, never --title) also takes the owner's words, refused
#                without them; its title is never changed, and its body only where ViD's own text stands as ViD wrote it: a ticket
#                posted in the form has each placeholder's kept filling (.vid/tw/form/issue-<n>) that the body still holds refilled,
#                any other left and named; one whose body is ViD's part 1 (not taken over from comments) has its first line alone
#                say it is replaced, unless the team changed that line; one taken over from comments keeps its body. Every part is
#                a comment, the earlier ones marked replaced; the notice names the cause (the writer's why line, the move's own),
#                each test added (the team's own additions marked), restated or taken out, each body line left, and the top-up's
#                size flag (writer.sh topup); its line ends `[form=<hash>] added=<ids> [size=<added>/<tests>] words="<the words>"`;
#                the kept body ids added to (.vid/tw/body/issue-<n>), and a `moved` line in .vid/next/team-answers for each test it
#                takes out. Two calls of the post: gh issue view <n> --json body (a read) and gh issue edit <n> --body-file.
#   tw-close <n> a withdrawal writer.sh due owes, the issue commented and closed as not planned: by a plan change, its comment
#                naming the newest change (`withdrawn <n> decision=<id>`), or, 0.26.10.28.6 (R2), a fix ticket whose rows were all ruled
#                known limits, its comment saying so (`withdrawn <n> decision=known-limit rows=<rows>`).
#                GM-2 T6: in GitHub manual `tw-close --words "<w>" [--cause "<line>"] <n>`: refused without the owner's words; its
#                comment names the cause (the owner's word by default) and where each test went, never a plan change; its line ends words=.
#   tw-team-no <n> <id> <added|dropped>   (GM-2 T7) GitHub manual's no to a team change: one comment on ticket n, saying the test
#                stays as the ticket had it; `team-no <n> <id> <kind> at=` logged. checks/team-change.sh calls it and records the answer.
#   tw-outside <n>  a published ticket closed outside ViD, read once: withdrawn (`withdrawn <n> decision=closed-outside`), or nothing changed.
#   0.26.10.29.2: tw-close's comment names the change's why and where each row went, on the issue and each open pull request (R3, R11),
#                and logs `handover`; tw-post --amend's names the cause and each row added, removed or changed, there too (R11);
#   tw-tell <n>  (R11) a known-limit fix ticket a pull request names, told so on the issue and the pull request (`told <n> limits=`);
#   tw-handovers (R3) the handovers of what writer.sh due owes, logged before any ticket is written (the round and tw-hand call it);
#   tw-hand …    (R12) the ticket writer called by hand: the lock, the saved records, the post and the save, in the run's order.
#                GM-4 K1 (J1): the one path of every ticket that goes out: publish (tw-publish), amend, withdraw, reopen (tw-reopen), fix
#                and reached, each with the owner's words (--words, required in GitHub manual, kept on the log line); exit 3 held.
#   tw-publish <step>  (GM-4 K1) the admission (plan.sh start), the publish's warnings, the write, its check and the post, with no lock or
#                save of its own: tw-hand publish and round.sh next wrap it. tw-reopen <n> (E6) a closed ticket reopened, one comment.
#   tw-act amend|withdraw|tell <n> | new <write's arguments>  (GM-4 K1) one act's steps (the write, a fix or reached ticket's
#                warnings, the post), no lock or save of its own: tw-hand's acts and round.sh's owed lines run it; exit 4 the write refused.
#                tw-post, tw-close and tw-tell, outside the round (VID_CALLER=round, GM-4 F2: the one caller mark), refuse while another
#                live session holds the lock and while .vid/state-at is not the saved head.
# GitHub manual (GM-1, phase 1): state-setup, ViD's own private state repository (state-repo:) made or checked (FB-2 A1: through mkrepo,
# at the connect, in both GitHub modes); the lock, state-save and state-restore use state-repo:, else the spec repository, one rule in every mode (GM-4 F2, stloc;
# the switch to GitHub manual asks state-repo:), and the saved records hold .vid/next/ too, and in GitHub manual of .vid/round/ the one read and the read before it alone (GM-4 F3, I2; GM-2 T12). ticket-writing <n> <file> and round-read read only; round-read --bodies's one new call (GM-4 F3), a GET of
# repos/<repo>/issues/<n>/sub_issues, is on the allow-list with no method but GET and no field.
# GM-4 K13: spec-publish [<export commit>], with layout: one, the export mirrored into spec-path: on the code repository: its calls,
# inside spec-publish alone (SPUB set there alone), are (FB-3 B1) GETs of git/trees/<tree>, names and ids alone, and -X POST --input <file> of repos/<repo>/git/blobs, git/trees, git/commits and
# git/refs (no field), -X PATCH --input <file> of git/refs/heads/vid-spec/<hex> (its own branch moved, no field), gh pr list's read
# of that branch's open pull request and gh pr create, and (FB-1 B1) gh pr close of an older folder pull request it replaces; nothing pushed from this machine (the one request to GitHub beside "never push to the code
# repository"), and nothing of the code read or sent: main's commit and tree are read from .vid/code. FB-3 B1: it changes only files
# ViD put in the folder; in GitHub manual with `spec-publish: hand` it writes nothing to GitHub, and spec-publish #<pr> reads the team's own publish.
# GM-3 S1: tickets [<folder>], read only, the published tickets on the allowed issue list and view calls (its lines at the subcommand); spec-fetch,
# read only, the spec repository's main fetched into ViD's copy, .vid/spec.git (specgit), nothing pushed (FB-3 B2: xlocal, from refs/vid/export, no network).
# FB-3 E1: ticket-decided <n>, read only, a ticket's state and its newest accepting decision comment, one allowed issue view.
# The planner's setup (v0.26.10.12.3.1 R3), read only — gh auth status and gh repo view alone:
#   access       one line each: `access gh — signed in` (or not, then it stops); for repo: and, in both layouts (GM-4 J5; FB-3 B2: but
#                with layout: one in GitHub manual), spec-repo: of .vid/tw/settings — not set yet, reached (its permission, private or
#                public; a public spec repository is not ready) or not reached (gh's words); then `access: ok`, or
#                `access: <n> of <m> not ready`. Exit 0; 2 on a usage error. It never creates, edits or pushes.
# The planner's subcommands (ViD's repository; they write only labels, comments and milestones):
#   comment <issue> --body-file <f>   (`ticket … state=commented` for a ticket) · label <issue> [--add <l>]…
#                [--remove <l>]… (the prefix added) · close <issue> | close --milestone <stage> --commit <sha>
#                (the milestone's description names the commit; `milestone … state=closed commit=`).
# Usage, one line a group (the usage message says the same):
#   sh checks/github.sh access
#   sh checks/github.sh spec-setup [--make-only] | spec-export | spec-publish [#<pr>] [--words "<w>"] [<export commit>]
#   sh checks/github.sh code-setup | state-setup | ticket-writing <n> <file> | tickets [<folder>] | ticket-decided <n> | spec-fetch
#   sh checks/github.sh tw-sync | tw-post [--amend <n>] [--words "<the owner's words>"] [--title "<a title>"] <ticket> | tw-outside <n> | tw-close [--words "<w>"] [--cause "<line>"] <n> | tw-team-no <n> <id> <added|dropped> | tw-tell <n> | tw-handovers | tw-reopen [--words "<w>"] <n> | tw-publish <step> [--words "<w>"] [--title "<t>"] | tw-act <amend|withdraw|tell> <n> | tw-act new <write's arguments> [--words "<w>"] [--cause "<line>"]
#   sh checks/github.sh tw-hand write <writer.sh write's arguments>|close <n>|tell <n>|publish <step> [--words "<w>"] [--title "<t>"]|amend <n> [--words "<w>"] [--cause "<line>"]|withdraw <n> [--words "<w>"] [--cause "<line>"]|reopen <n> [--words "<w>"]|fix <key> [--words "<w>"]|reached [--words "<w>"]
#   sh checks/github.sh decide-blocked <issue> <pr> | decide-post <pr> <file> | pr-body <pr> | results-fetch | own-refs | pr-files <pr> [<path>] | closing-prs <issue>… | round-read [--bodies]
#   sh checks/github.sh record-read <a blob link at a commit, or a pull request link>
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
# FB-2 B1: in spec-publish (SPX) a refusal right after a failed GitHub or git network call ($W/gfail, kept by keeperr) is that call
# unfinished: spfail, exit 5, the reply on the line; any other refusal is a rule's, exit 1
gref() { [ "${SPX:-}" != yes ] || [ ! -f "$W/gfail" ] || { _g=$(ghwhy "$W/gfail"); spfail "$*${_g:+ (GitHub: $_g)}"; }; echo "ViD github: refused — $*" >&2; exit 1; }
# ghwhy <file>: GM-4 proof D2, D6: GitHub's reply a failed call saved, its lines joined into one (a push's `To <address>` and
# hints left out), so a refusal can say what GitHub answered
ghwhy() { grep -v -e '^To ' -e '^hint:' -e '^[[:space:]]*$' "$1" 2>/dev/null | sed 's/^remote: *//' | head -n 4 | paste -sd '|' - | sed 's/|/; /g'; }
# keeperr <command…> (FB-2 B1): in spec-publish alone, a GitHub or git network call whose stderr is kept and passed on as before: left
# in $W/gfail when the call fails, removed when it succeeds; elsewhere the call as it is
keeperr() { [ "${SPX:-}" = yes ] || { "$@"; return; }; rm -f "$W/gfail"; _ke=0; "$@" 2> "$W/gerr" || _ke=$?; cat "$W/gerr" >&2; if [ "$_ke" = 0 ]; then rm -f "$W/gerr"; else mv "$W/gerr" "$W/gfail"; fi; return "$_ke"; }
# putd <folder> <copy>: a folder replaced in four steps — the copy beside it as .put.$$.<name>, the live one aside as .old.$$.<name>,
# the copy in, the old one removed; a step that fails stops it with the live folder whole (v0.26.10.28.1, R6); each rename through mvr (0.26.11.1.4, R6)
putd() { _q=$(dirname "$1")/.put.$$.$(basename "$1"); _o=$(dirname "$1")/.old.$$.$(basename "$1"); rm -rf "$_q" && cp -R "$2" "$_q" || { rm -rf "$_q"; return 1; }
  if [ -e "$1" ]; then mvr "$1" "$_o" || { rm -rf "$_q"; return 1; }; fi; mvr "$_q" "$1" || { [ ! -e "$_o" ] || mvr "$_o" "$1"; rm -rf "$_q"; return 1; }; rm -rf "$_o"; }
# a state-restore stopped between its two renames left .vid/.old.<pid>.<name> and no live folder: it is renamed back first
# (IR I1, FB-3 A1.4: never by record-read nor pr-files, which change nothing under the project)
[ "${1:-}" = record-read ] || [ "${1:-}" = pr-files ] || for _o in .vid/.old.*.decide .vid/.old.*.tw .vid/.old.*.plans .vid/.old.*.plan .vid/.old.*.next .vid/.old.*.results; do [ -d "$_o" ] && [ ! -e ".vid/${_o##*.}" ] || continue; mvr "$_o" ".vid/${_o##*.}"; done
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
REPO=''; SHARE=''; SCREATE=''; MKREPO=''; FORMPOST=''; RECREAD=''; RR=''; SPUB=''   # 0.26.10.28.7: the share's allow-list switches never come from the environment; GM-2 T3: nor the form post's (IR I1: nor record-read's)
RESREAD=''   # FB-3 A2: results-fetch's graphql read (A1.4: closing-prs' too), its switch never from the environment
PRREAD=''   # FB-3 A1.4: pr-files' read of a pull request's files, its switch never from the environment
FOLDREAD=''   # FB-4 B1: spec-folder's read of the folder's names and ids, its switch never from the environment
STAMPREAD=''; SPF=''; SMN=''   # GM-4 K13: spec-stamp's read of the stamp file, its switch never from the environment
SPX=''   # FB-2 B1: spec-publish's flag (gref, keeperr), never from the environment
# one read a tick (R3): the same three reads as DevAgent's dm.sh next, its own copy
RPQ='.[] | [.number, .headRefName, .isDraft, .headRefOid, ([.labels[].name] | join(",")), (.body | split("\n") | .[0]), ([.comments[].body | split("\n") | .[0]] | join("\u0001")), (([.comments[] | select(.body | startswith("vid: decision "))] | last | .body) // ""), .updatedAt] | @tsv'
RMQ='.[] | [.number, .headRefOid, (.mergeCommit.oid // "-"), (.body | split("\n") | .[0]), ([.comments[].body | split("\n") | .[0]] | join("\u0001"))] | @tsv'
RIQ='.[] | [.number, ([.labels[].name] | join(",")), ([.comments[].body | split("\n") | .[0]] | join("\u0001")), .updatedAt] | @tsv'
# ghc: the one way to call gh — the allow-list, checked at every call
ghc() {
  case "$1 ${2:-}" in
    'auth status'|'repo view'|'label create'|'issue create'|'issue edit'|'issue view'|'issue list'|'issue comment'|'issue close'|'issue reopen'|'pr view'|'pr list'|'pr comment') ;;   # GM-4 K1 (E6): issue reopen, tw-reopen's alone
    'pr create') [ "${SPUB:-}" = yes ] || gref "gh pr create is allowed in spec-publish alone (GM-4 K13): the folder's pull request" ;;
    'pr close') [ "${SPUB:-}" = yes ] || gref "gh pr close is allowed in spec-publish alone (FB-1 B1): an older folder pull request, replaced" ;;
    'repo create')   # 0.26.10.28.7 (R6): the share repository alone, private, in share-create; FB-2 A1: else the one repository mkrepo was given (MKREPO, set there alone), private
      if [ "${SHARE:-}" = yes ]; then [ "${SCREATE:-}" = yes ] && [ -n "${SREPO:-}" ] && [ "${3:-}" = "$SREPO" ] && [ "${4:-}" = --private ] && [ $# -eq 4 ] || gref "gh repo create is allowed for the share repository alone, --private, in share-create"
      else [ -n "${MKREPO:-}" ] && [ "${3:-}" = "$MKREPO" ] && [ "${4:-}" = --private ] && [ $# -eq 4 ] || gref "gh repo create is allowed for the repository the setup names alone (repo:, spec-repo: or state-repo:), --private, in code-setup, spec-setup or state-setup"; fi ;;
    api\ *) _p=''; _s=''; _m=''; _fl=''; _fn=0; _fv=''; _in=''; for _a in "$@"; do if [ -n "$_s" ]; then [ "$_s" = X ] && _m=$_a; [ "$_s" = F ] && _fv=$_a; [ "$_s" = I ] && _in=$_a; _s=''; continue; fi; case "$_a" in -X) _s=X ;; -f) _s=1; _fl=1; _fn=$((_fn + 1)) ;; -F) _s=F; _fl=1; _fn=$((_fn + 1)) ;; --jq) _s=1 ;; --input) _s=I ;; --paginate) ;; api) ;; *) _p=$_a ;; esac; done
      # IR I1: record-read's reads, GETs alone of the linked repository RR, only inside record-read: --jq and --paginate are its only options
      if [ "${RECREAD:-}" = yes ]; then
        _p=''; _s=''; for _a in "$@"; do if [ -n "$_s" ]; then _s=''; continue; fi
          case "$_a" in api) ;; --jq) _s=q ;; --paginate) ;; -*) gref "gh api in record-read does not take $_a: it reads, and writes nothing" ;; *) [ -z "$_p" ] || gref 'gh api in record-read takes one path'; _p=$_a ;; esac; done
        [ -z "$_s" ] || gref 'gh api in record-read: an option with no value'
        case "$_p" in "repos/$RR/pulls/"[0-9]*) _q=${_p#repos/$RR/pulls/}; _q=${_q%/files}; case "$_q" in ''|*[!0-9]*) gref "not a pull request's read: '$_p'" ;; esac ;;
          "repos/$RR/contents/"?*) printf '%s\n' "$_p" | grep -qE '^[^?#]+[?]ref=[0-9a-f]{40}$' || gref "a file is read at a commit alone, its path with no ? and no #: '$_p'" ;;
          *) gref "gh api in record-read reads the linked pull request and its files alone, not '$_p'" ;; esac
      # 0.26.10.28.7 (R6): the share's reads and its one write, each tied to SREPO, LOGIN or WHO, and only inside a share subcommand
      elif [ "${SHARE:-}" = yes ]; then
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
      [ -z "$_in" ] || [ "${SPUB:-}" = yes ] || gref "gh api --input is spec-publish's alone (GM-4 K13)"
      case "$_p" in graphql)   # FB-3 A2: one query of one repository, in results-fetch alone; A1.4: and closing-prs
          [ "${RESREAD:-}" = yes ] && [ -z "$_m$_fv$_in" ] && [ "$_fn" = 1 ] && [ "${3:-}" = -f ] && case "${4:-}" in 'query=query { repository(owner: '*) true ;; *) false ;; esac || gref "gh api graphql is allowed in results-fetch and closing-prs alone, as one query of one repository" ;;
        "repos/$REPO/pulls/"[0-9]*"/files?per_page=100") _q=${_p#"repos/$REPO/pulls/"}; case "${_q%/files*}" in *[!0-9]*) gref "not a pull request's files: '$_p'" ;; esac   # FB-3 A1.4: pr-files' read
          [ "${PRREAD:-}" = yes ] && [ -z "$_fl" ] && { [ -z "$_m" ] || [ "$_m" = GET ]; } || gref "gh api on a pull request's files is allowed as pr-files' read alone (a GET, no field)" ;;
        "repos/$REPO/milestones"|"repos/$REPO/milestones/"[0-9]*) ;;
        "repos/$REPO/git/trees/"*) _q=${_p#"repos/$REPO/git/trees/"}; _q=${_q%"?recursive=1"}; case "$_q" in *[!0-9a-f]*|'') gref "not a tree's read: '$_p'" ;; esac   # FB-3 B1: the folder's names and ids
          { [ "${SPUB:-}" = yes ] || [ "${FOLDREAD:-}" = yes ]; } && [ -z "$_fl" ] && [ -z "$_in" ] && { [ -z "$_m" ] || [ "$_m" = GET ]; } || gref "gh api on a tree is allowed only in spec-publish and spec-folder, as a read alone (a GET, no field)" ;;
        "repos/$REPO/git/blobs"|"repos/$REPO/git/trees"|"repos/$REPO/git/commits"|"repos/$REPO/git/refs")   # GM-4 K13: spec-publish's git data calls alone
          [ "${SPUB:-}" = yes ] && [ "$_m" = POST ] && [ -z "$_fl" ] && [ -n "$_in" ] || gref "gh api on the git data endpoints is allowed only in spec-publish: -X POST --input <file>, no field" ;;
        "repos/$REPO/git/refs/heads/vid-spec/"*)   # GM-4 K13: spec-publish's move of its own branch, left by an earlier call, alone
          _q=${_p#"repos/$REPO/git/refs/heads/vid-spec/"}; case "$_q" in *[!0-9a-f]*|'') gref "not ViD's own spec branch: '$_p'" ;; esac
          [ "${SPUB:-}" = yes ] && [ "$_m" = PATCH ] && [ -z "$_fl" ] && [ -n "$_in" ] || gref "gh api on ViD's spec branch is allowed only in spec-publish: -X PATCH --input <file>, no field" ;;
        "repos/$REPO/issues/"[0-9]*/sub_issues) _q=${_p#repos/$REPO/issues/}; case "${_q%/sub_issues}" in *[!0-9]*) gref "not an issue's sub-issues: '$_p'" ;; esac   # GM-1 S6: a GET alone
          # GM-2 T3: or, in tw-post's first post in the form alone, -X POST of one -F field, sub_issue_id=<an issue id>
          if [ "$_m" = POST ] && [ "${FORMPOST:-}" = yes ]; then [ "$_fn" = 1 ] && case "$_fv" in sub_issue_id=*[!0-9]*|sub_issue_id=) false ;; sub_issue_id=*) true ;; *) false ;; esac || gref "gh api -X POST on an issue's sub-issues takes one field, -F sub_issue_id=<an issue id>"
          else [ -z "$_fl" ] && { [ -z "$_m" ] || [ "$_m" = GET ]; } || gref "gh api on an issue's sub-issues is allowed as a read alone (a GET, no field), or as tw-post's link of a first post in the form"; fi ;;
        "repos/$REPO/issues/"[0-9]*/dependencies/blocked_by) _q=${_p#repos/$REPO/issues/}; case "${_q%/dependencies/blocked_by}" in *[!0-9]*) gref "not an issue's blocked-by links: '$_p'" ;; esac   # GM-2 T3
          [ "${FORMPOST:-}" = yes ] && [ "$_m" = POST ] && [ "$_fn" = 1 ] && case "$_fv" in issue_id=*[!0-9]*|issue_id=) false ;; issue_id=*) true ;; *) false ;; esac || gref "gh api on an issue's blocked-by links is allowed only as tw-post's link of a first post in the form: -X POST, one field, -F issue_id=<an issue id>" ;;
        "repos/$REPO/issues/"[0-9]*) case "${_p#repos/$REPO/issues/}" in *[!0-9]*) gref "not an issue: '$_p'" ;; esac   # GM-2 T3: the issue's id, a read alone
          [ -z "$_fl" ] && { [ -z "$_m" ] || [ "$_m" = GET ]; } || gref "gh api on an issue is allowed as a read alone (a GET, no field)" ;;
        # GM-4 K13: the stamp file in the code repository's spec folder, at main's commit, a read alone, in spec-stamp only
        "repos/$REPO/contents/"*) [ "${STAMPREAD:-}" = yes ] && [ -n "${SPF:-}" ] && [ -n "${SMN:-}" ] && [ "$_p" = "repos/$REPO/contents/$SPF?ref=$SMN" ] && [ -z "$_fl" ] && { [ -z "$_m" ] || [ "$_m" = GET ]; } || gref "gh api on the code repository's contents is allowed as spec-stamp's read of the stamp file alone, not '$_p'" ;;
        "repos/$REPO/issues/comments/"[0-9]*) case "${_p##*/}" in *[!0-9]*) gref "not an issue comment: '$_p'" ;; esac
        [ "$_m" = PATCH ] || gref "gh api on an issue comment is allowed for its edit alone (-X PATCH)" ;; *) gref "gh api is allowed for the milestone, sub-issue and issue comment edit endpoints, the sub-issues read, and GitHub manual's issue id read and its sub-issue and blocked-by links only, not '$_p'" ;; esac; fi ;;
    *) gref "gh $1 ${2:-} is not on the allow-list" ;;
  esac
  for _a in "$@"; do case "$_a" in token|--with-*) gref 'a token is never asked for, printed, passed or stored' ;; esac; done
  if [ "${SPX:-}" = yes ]; then keeperr gh "$@"; return; fi   # FB-2 B1: in spec-publish, its reply kept
  gh "$@"
}
# auth (low-1, R4): one of three refusals — gh not on PATH; gh's words say no account is signed in; else a neutral line, as gh prints its login advice for a network failure too
# (FB-2 B1: in spec-publish the neutral line is the call unfinished, exit 5; the login's stays a refusal, $W/gfail removed first)
auth() { command -v gh > /dev/null 2>&1 || gref "gh is not found on this machine's PATH: install it, or put it on PATH; signing in is not the problem"
  ghc auth status > "$W/auth" 2>&1 || { sed 's/^/    /' "$W/auth" >&2; ! grep -q 'not logged into any' "$W/auth" || { rm -f "$W/gfail"; gref 'gh auth status fails — log in with gh auth login (ViD never handles a token)'; }
    gref 'gh auth status failed (its words above); it may not be the login: check the network and the machine'"'"'s load, then run gh auth status by hand'; }; }
cg() { git --git-dir=.vid/code -c log.showSignature=false "$@"; }   # ViD's copy of the code repository's reports and commits
# FB-3 A1.4: ownrefs, each of ViD's own reviews as a report. A folder .vid/decide/review/<id>/ holding grade.txt or sorted.txt is the local
# ref vid-results/<id> of .vid/code, that folder with those files alone, in a commit of ViD's whose message is `vid-own` and whose time is
# fixed, so the same record is the same commit and no report of DevAgent's or a team's is ever older than it; it stands in place of a
# branch of that name. One whose record is gone is dropped. No .vid/code: nothing, the next fetch makes them. $W/own, their ids
ownrefs() { ls .vid/decide/review/*/grade.txt .vid/decide/review/*/sorted.txt 2>/dev/null | sed 's|^\.vid/decide/review/||; s|/[^/]*$||' | grep -xE '[A-Za-z0-9._-]+' | sort -u > "$W/own" || :
  [ -d .vid/code ] || return 0
  cg for-each-ref --format='%(refname:lstrip=3) %(contents:subject)' refs/heads/vid-results/ | sed -n 's/ vid-own$//p' | grep -vxFf "$W/own" > "$W/owd" || :; while read -r i; do cg update-ref -d "refs/heads/vid-results/$i" || return 1; done < "$W/owd"
  while read -r i; do { for f in grade.txt sorted.txt; do [ ! -f ".vid/decide/review/$i/$f" ] || printf '100644 blob %s\t%s\n' "$(cg hash-object -w --stdin < ".vid/decide/review/$i/$f")" "$f"; done; } > "$W/owt"
    t=$(cg mktree < "$W/owt") && t=$(printf '040000 tree %s\t%s\n' "$t" "$i" | cg mktree) && n=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_AUTHOR_DATE=2000-01-01T00:00:00Z GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid GIT_COMMITTER_DATE=2000-01-01T00:00:00Z cg commit-tree "$t" -m vid-own) && cg update-ref "refs/heads/vid-results/$i" "$n" || return 1; done < "$W/own"; }
codekey() { [ -f ARCHITECTURE.md ] && sed -n '/^```vid-code[[:space:]]*$/,/^```[[:space:]]*$/p' ARCHITECTURE.md | sed -n "s/^$1:[[:space:]]*//p" | head -n 1 | sed 's/[[:space:]]*$//'; }
kv() { printf '%s\n' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -n 1; }
# GM-4 K13: spdest, where spec-publish puts the export: SP the folder (spec-path:, docs/specs while missing, no trailing /), SS the
# stamp inside it (spec-stamp:, written with or without the folder's name; empty for none). spdone <12 hex>: the newest
# spec-published line names that export, that folder and that stamp, so a changed folder or stamp is published again
spdest() { SP=$(twkey spec-path); SP=${SP:-docs/specs}; SP=${SP%/}; SS=$(twkey spec-stamp); SS=${SS#"$SP"/}; }
spdone() { spdest; _sl=$(grep '^spec-published ' .vid/tw/log 2>/dev/null | tail -n 1 || true); [ -n "$_sl" ] && [ "$(kv "$_sl" export)" = "$1" ] && [ "$(kv "$_sl" path)" = "$SP" ] && [ "$(kv "$_sl" stamp)" = "${SS:--}" ]; }
# spplain: the spec folder (spdest's SP) is a plain path from the code repository's top
spplain() { case "$SP" in ''|/*|.|..|./*|../*|*/../*|*/..|*/.|*/./*|*//*|*[!A-Za-z0-9._/-]*) return 1 ;; esac; }
# gw: GitHub's reply to the last git data call ($W/gde), in brackets
gw() { _g=$(ghwhy "$W/gde"); if [ -n "$_g" ]; then printf ' (GitHub: %s)' "$_g"; elif [ -n "${1:-}" ]; then printf ' (GitHub made %s, the export'"'"'s is %s)' "$1" "$2"; else printf ' (GitHub gave no reply)'; fi; }
# FB-3 B1: fold <tree>: $W/fold, the folder's files at that tree of the code repository, `<blob id>\t<path from the folder>`, names and
# ids alone (GETs, down to the folder and then whole); empty when the folder is not there
fold() { FT=$1; : > "$W/fold"; for _c in $(printf '%s\n' "$SP" | tr / '\n'); do FT=$(ghc api "repos/$REPO/git/trees/$FT" --jq ".tree[] | select(.path == \"$_c\" and .type == \"tree\") | .sha" 2> "$W/gde") || spfail "the folder $SP could not be read$(gw) — nothing posted; the next call reads it"; [ -n "$FT" ] || return 0; done
  ghc api "repos/$REPO/git/trees/$FT?recursive=1" --jq "$FOQ" > "$W/fold" 2> "$W/gde" || spfail "the folder $SP could not be read$(gw) — nothing posted; the next call reads it"
  [ "$(head -n 1 "$W/fold")" != truncated ] || gref "the folder $SP holds more files than GitHub lists in one read — nothing posted"; }
FOQ='(if .truncated then "truncated" else empty end), (.tree[] | select(.type == "blob") | [.sha, .path] | @tsv)'
# FB-3 B1: BYH, a spec-published line of the team's own publish (by=hand stands before the words, so no words of the owner's read as it)
BYH='^spec-published pr=[^ ]+ export=[^ ]+ path=[^ ]+ stamp=[^ ]+ at=[^ ]+ by=hand( |$)'
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
# mkrepo <key> <name> (FB-2 A1): a repository the setup names. Missing, made by `gh repo create <name> --private`, with no README, so
# empty, and `<key> <name> created`; present, the spec and state repositories must be private (else return 2) and the code
# repository (repo) is used as it is, `<key> <name> exists`. MKD says which; a make that fails returns 1. MKREPO, the allow list's
# one switch for repo create, is set here alone, to this name
mkrepo() { MKD=exists; if ghc repo view "$2" --json name --jq .name > /dev/null 2>&1; then
    [ "$1" = repo ] || [ "$(ghc repo view "$2" --json isPrivate --jq .isPrivate 2>/dev/null)" = true ] || return 2; twlog "$1 $2 exists at=$(now)"; return 0; fi
  MKREPO=$2 ghc repo create "$2" --private > /dev/null || return 1; MKD=created; twlog "$1 $2 created at=$(now)"; }
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
# GM-4 F8: H is the commit the team has, lib.sh's applied, in every mode: HEAD, and in GitHub manual the applied commit (GM-2 T1,
# .vid/tw/applied), so the team gets the applied version: every path, and TEST-DIFFERENCES.md cut from its INVENTORY.md; and (§5)
# the issue form issue-form: names is added as HEAD holds it, at the same path
exptree() {
  _xc=$(applied); XW=HEAD; ! manual || XW='the applied commit'
  if manual; then [ -n "$_xc" ] && git cat-file -e "$_xc^{commit}" 2>/dev/null || gref "GitHub manual: .vid/tw/applied names no commit of this repository${_xc:+ ($_xc)}; /vid mode manual records the applied version the team has"; fi
  H=$(git rev-parse -q --verify "$_xc^{commit}") && [ -n "$_xc" ] || gref "no commit at $XW"
  GIT_INDEX_FILE="$W/index"; export GIT_INDEX_FILE; git read-tree --empty || gref 'the temporary index could not be made'
  : > "$W/xp"
  for p in $(printf '%s\n' PRD.md DECISIONS.md BASELINE.md ARCHITECTURE.md design/ GRADING-CHECKLIST.md); do
    q=${p%/}; git ls-tree -r -z --name-only "$H" -- "$q" > "$W/xf"
    if [ ! -s "$W/xf" ]; then [ -n "${1:-}" ] && echo "ViD github: $p is not at $XW — not exported"; continue; fi
    git check-ignore -z --stdin --no-index < "$W/xf" > "$W/xi" 2>/dev/null || true
    [ ! -s "$W/xi" ] || gref "$p holds a file git ignores ($(tr '\0' '\n' < "$W/xi" | head -n 1)) — an ignored file is never exported"
    git ls-tree -r -z "$H" -- "$q" | git update-index -z --index-info || gref "$p could not be read at $XW"
    printf '%s\n' "$p" >> "$W/xp"
  done
  git show "$H:INVENTORY.md" 2>/dev/null | awk '/^```vid-inventory/ { b = 1; next } /^```/ { b = 0 } b && /^[ \t]*difference[ \t]*[|]/' > "$W/dif"
  if [ -s "$W/dif" ]; then { printf '# The test differences: INVENTORY.md'"'"'s difference rows, verbatim\n\n'; cat "$W/dif"; } | git hash-object -w --stdin > "$W/difb" &&
    git update-index --add --cacheinfo "100644,$(cat "$W/difb"),TEST-DIFFERENCES.md" || gref 'TEST-DIFFERENCES.md could not be made'; echo TEST-DIFFERENCES.md >> "$W/xp"
  elif [ -n "${1:-}" ]; then echo "ViD github: INVENTORY.md at $XW has no difference row — TEST-DIFFERENCES.md not exported"; fi
  _xform=$(skey issue-form); if [ -n "$_xform" ]; then   # GM-2 T1 (§5): the form, at HEAD, beside the spec; GM-4 F6: whenever the setup names it
    case $_xform in /*|./*|../*|*/../*|*/..|..|*/|design|PRD.md|DECISIONS.md|BASELINE.md|ARCHITECTURE.md|GRADING-CHECKLIST.md|TEST-DIFFERENCES.md) gref "issue-form: $_xform is not a file of ViD's repository the export can carry beside the spec (a path from the top, not one of the spec's own)" ;; esac
    [ "$(git cat-file -t "HEAD:$_xform" 2>/dev/null)" = blob ] || gref "issue-form: $_xform is not a file committed at HEAD: commit it in ViD's repository, then export"
    git update-index --add --cacheinfo "100644,$(git rev-parse "HEAD:$_xform"),$_xform" || gref "issue-form: $_xform could not be put in the export"
    printf '%s\n' "$_xform" >> "$W/xp"; fi
  [ -s "$W/xp" ] || gref "nothing to export: none of R2's paths is at $XW"
  # 0.26.11.1.2 (R7): in the exported copy alone, each text file's profane words (lib.sh's PROF, the writer's list) written "(a word)";
  # a binary file, a file with none, and ViD's own files are left as they are, and nothing is refused
  # git's raw names, NUL-separated (-z) both ways; a newline in a name read as \001 between the two, and given back
  git ls-files -s -z > "$W/xl0" || gref 'the export index could not be read'; _x1=$(printf '\001')
  # a raw name holding \001 itself is refused, named (the carrier would turn it into a newline); each record read whole, split at its first tab
  _xa=$(tr '\000' '\n' < "$W/xl0" | grep -F "$_x1" | head -n 1) || true; [ -z "$_xa" ] || gref "a file name holds a \\001 byte, which the export cannot carry: ${_xa#*	}"
  tr '\n\000' '\001\n' < "$W/xl0" > "$W/xl"; : > "$W/xu"; _xf=''
  while IFS= read -r _xr; do _xm=${_xr%%	*}; _xp=${_xr#*	}; case ${_xm%% *} in 100*) ;; *) continue ;; esac; _xb=${_xm#* }; _xb=${_xb%% *}
    git cat-file blob "$_xb" > "$W/xb" || { _xf=$_xp; break; }; grep -Iq . "$W/xb" || continue   # a binary file as it is
    awk "$PROF"' prof($0) != "" { f = 1; exit } END { exit !f }' "$W/xb" || continue
    { awk "$PROF"' { print profx($0) }' "$W/xb" > "$W/xc" && { [ -z "$(tail -c 1 "$W/xb")" ] || { printf '%s' "$(cat "$W/xc")" > "$W/xd" && mv -f "$W/xd" "$W/xc"; }; } &&   # no final newline added
      _xn=$(git hash-object -w "$W/xc") && { printf '%s %s\t' "${_xm%% *}" "$_xn"; printf '%s' "$_xp" | tr '\001' '\n'; printf '\000'; } >> "$W/xu"; } || { _xf=$_xp; break; }
  done < "$W/xl"; [ -z "$_xf" ] || gref "a profane word in $_xf could not be blanked in the export"
  [ ! -s "$W/xu" ] || git update-index -z --index-info < "$W/xu" || gref 'the blanked copies could not be put in the export'
  TR=$(git write-tree) || gref 'the export tree could not be written'; unset GIT_INDEX_FILE; }
# stpriv <repo>: ST and SU, its URL, or a refusal unless it is private (R6). sturl: the same for stloc's repository
stpriv() { ST=$1; [ "$(ghc repo view "$ST" --json isPrivate --jq .isPrivate 2>/dev/null)" = true ] || gref "$ST is not a private repository: ViD's records never go there"; SU=$(ghc repo view "$ST" --json url --jq .url) && [ -n "$SU" ] || gref "no access to $ST"; }
sturl() { stloc; stpriv "$ST"; }
# stloc (GM-4 F2): ST, where the lock and the saved records live, one rule in every mode: state-repo:, else the spec repository. GitHub
# manual's switch asks state-repo: (GM M15), so a project there has it
stloc() { ST=$(twkey state-repo); [ -n "$ST" ] || ST=$SPEC; }
# 0.26.10.29.2 (R3, R11): oprs <n>, the open pull requests naming ticket n (the body's first line `ticket: #<n>`), one a line, from the
# list of open pull requests, as the round's read takes it (no search, which GitHub indexes late), read whole: a list as long as
# the limit (VID_OPRS_LIMIT, 1000) is a refusal, never a short list
oprs() { _lm=${VID_OPRS_LIMIT:-1000}; ghc pr list -R "$REPO" --state open --limit "$_lm" --json number,headRefName,isDraft,headRefOid,labels,body,comments,updatedAt --jq "$RPQ" > "$W/op" || gref "the open pull requests naming #$1 could not be read — nothing posted"
  [ "$(grep -c . "$W/op")" -lt "$_lm" ] || gref "the open pull requests could not be read whole ($_lm or more), so those naming #$1 are not known — nothing posted"
  awk -F'\t' -v n="$1" '{ t = $6; if (t !~ /^ticket: #/) next; sub(/^ticket: #/, "", t); sub(/[^0-9].*$/, "", t); if (t == n) print $1 }' "$W/op"; }
# rhd: the saved records' head (empty while none is saved); a failed read is a refusal, never "none"
rhd() { _o=$(git ls-remote "$SU" refs/heads/vid-state/records 2>/dev/null) || gref "the saved records' head could not be read (git ls-remote) — nothing posted"; printf '%s' "$_o" | cut -f1; }
# 0.26.10.29.2 (R12): rhead, outside the round (which marks its calls VID_CALLER=round, GM-4 F2: the one mark; /vid next's calls and every
# direct call are checked alike, and pass while the lock is this session's, as vid-connect's start leaves it), a post, amendment, withdrawal or telling refuses
# while another live session holds the run's lock, and while .vid/state-at is not the saved records' head (with no state-at: only while
# none is saved), so a folder behind them never sends a row twice and nothing goes out unrecorded beside a run
rhead() { [ "${VID_CALLER:-}" != round ] || return 0
   sturl; _h=$(rhd) || exit 1
  _ll=$(git ls-remote "$SU" refs/heads/vid-state/lock 2>/dev/null) || gref 'the lock could not be read — nothing posted'
  if [ -n "$(printf '%s' "$_ll" | cut -f1)" ]; then rm -rf "$W/rl"; git init -q "$W/rl" && git -C "$W/rl" fetch -q "$SU" refs/heads/vid-state/lock && _lb=$(git -C "$W/rl" show FETCH_HEAD:lock) || gref 'the lock could not be read — nothing posted'
    _ls=$(printf '%s\n' "$_lb" | sed -n 's/^session: //p'); _la=$(printf '%s\n' "$_lb" | sed -n 's/^at: //p'); _ag=$(($(date +%s) - ${_la:-0})); _me=${CLAUDE_CODE_SESSION_ID:-$(cat .vid/lock-session 2>/dev/null)}
    [ "$_ls" = "$_me" ] || [ "$_ag" -ge "${VID_LOCK_COLD:-900}" ] || gref "the run's lock is held by $_ls, ${_ag}s old: this goes out through that run, or by sh checks/github.sh tw-hand once the lock is free — nothing posted"; fi
  if [ -f .vid/state-at ]; then [ "$_h" = "$(cat .vid/state-at)" ] || gref "this folder's records are not the saved records' head (${_h:-none}): another folder saved since. sh checks/github.sh tw-hand restores them first — nothing posted"
  else [ -z "$_h" ] || gref "this folder holds no saved state while records are saved ($(printf %.12s "$_h")): sh checks/github.sh tw-hand restores them first — nothing posted"; fi; }
# hov <n> <rows> (0.26.10.29.2, R3): the log already holds ticket n's handover of these rows since its newest writing
hov() { awk -v n="$1" -v r="rows=$2" '($1 == "published" || $1 == "amended") && $2 == n { f = 0 } $1 == "handover" && $2 == n { for (i = 3; i <= NF; i++) if ($i == r) f = 1 } END { exit !f }' .vid/tw/log 2>/dev/null; }
# tell <n> <file>: the comment on issue n and on each of its open pull requests (0.26.10.29.2, R3, R11), whoever claimed it or not; OP
# their numbers. The pull requests are read first ($W/opn, unless the caller read them already), so a failed read posts nothing
tell() { [ -f "$W/opn" ] || oprs "$1" > "$W/opn"; OP=$(paste -sd , "$W/opn"); ghc issue comment "$1" -R "$REPO" --body-file "$2" > /dev/null || return 1; for _p in $(cat "$W/opn"); do ghc pr comment "$_p" -R "$REPO" --body-file "$2" > /dev/null || return 1; done; }
# xlocal (FB-3 B2): with one repository in GitHub manual ViD's line of export commits is refs/vid/export (XR) of its own repository, and
# .vid/spec.git a copy made from it: the predicate that decides where a ticket quotes the spec (writer.sh reading, tw-hand)
xlocal() { [ "$(twkey layout)" = one ] && manual; }
# wasmanual (FB-3 B2): the project has ever been in GitHub manual, by the owner's recorded answers
wasmanual() { grep -q '^setup-answered key=github-mode value="manual"' .vid/plan/setup 2>/dev/null; }
XR=refs/vid/export; XFETCH=''
# xfollow: refs/vid/export moved to .vid/spec.git's main, forward only (the relative path, so Git Bash needs no translation); 1 when it is none
xfollow() { _xo=$(git rev-parse -q --verify "$XR^{commit}" 2>/dev/null || true); _xn=$(git --git-dir="$SG" rev-parse -q --verify refs/heads/main) || return 1; [ "$_xo" != "$_xn" ] || return 0
  [ -z "$_xo" ] || git --git-dir="$SG" merge-base --is-ancestor "$_xo" "$_xn" 2>/dev/null || return 1; git fetch -q --no-tags .vid/spec.git "refs/heads/main:$XR" 2>/dev/null && [ "$(git rev-parse -q --verify "$XR^{commit}")" = "$_xn" ]; }
# specloc (FB-3 B2, xlocal's specgit): SM the newest export, refs/vid/export, and .vid/spec.git's main set from it. A project whose exports
# were pushed moves them in once, while the ref lacks the log's newest export: from .vid/spec.git's main when that holds it, else from
# the spec repository its spec-repo: still names, fetched this once; from neither, refused (no export a ticket names is lost)
specloc() { SURL=''; _xe=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log 2>/dev/null); _xm=''
  if git rev-parse -q --verify "$XR^{commit}" > /dev/null 2>&1; then [ -z "$_xe" ] || git merge-base --is-ancestor "$_xe" "$XR" 2>/dev/null || _xm=1; elif [ -n "$_xe$XFETCH" ]; then _xm=1; fi
  if [ -n "$_xm" ]; then
    [ -n "$_xe" ] && git --git-dir="$SG" merge-base --is-ancestor "$_xe" refs/heads/main 2>/dev/null || { [ -z "$SPEC" ] || specmain; }
    if [ -n "$_xe" ]; then git --git-dir="$SG" merge-base --is-ancestor "$_xe" refs/heads/main 2>/dev/null && { xfollow || xjoin; } || gref "the export $(printf %.12s "$_xe"), the newest .vid/tw/log names, is in neither this project ($XR, .vid/spec.git) nor ${SPEC:-a spec repository}: name the spec repository that holds it once (sh checks/planner.sh setup spec-repo <owner/name> --words \"<their words>\"), and the exports are moved into the project"
    elif git --git-dir="$SG" rev-parse -q --verify refs/heads/main > /dev/null; then xfollow || gref "the exports could not be moved into the project ($XR)"; fi; fi
  SM=$(git rev-parse -q --verify "$XR^{commit}" 2>/dev/null || true)
  if [ -n "$SM" ]; then git --git-dir="$SG" update-ref refs/heads/main "$SM" || gref "$SG could not be set from $XR"; else git --git-dir="$SG" update-ref -d refs/heads/main 2>/dev/null || true; fi; }
# xjoin: a line pushed elsewhere since (another spec repository, or its main put back) and the one the ref kept, joined by one commit of the
# pushed one's tree, the pushed one first, so no export of either is lost; logged as an export kept in the project
xjoin() { _jn=$(git --git-dir="$SG" rev-parse refs/heads/main) && _jf=$(kv "$(awk '$1 == "export" { l = $0 } END { print l }' .vid/tw/log)" from) && [ -n "$_jf" ] || return 1
  _jd=$(git log -1 --format=%cI "$_jf" 2>/dev/null || true)   # the applied commit's dates, as spec-export's, so the same join is the same commit
  _jc=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid GIT_AUTHOR_DATE="$_jd" GIT_COMMITTER_DATE="$_jd" git --git-dir="$SG" commit-tree "$_jn^{tree}" -p "$_jn" -p "$_xo" -m "ViD export of $(printf %.12s "$_jf")" -m "from: $_jf") || return 1
  git --git-dir="$SG" update-ref refs/heads/main "$_jc" && xfollow && twlog "export $_jc from=$_jf state=local at=$(now)"; }
# specgit: .vid/spec.git, a bare repository whose objects borrow ViD's (alternates) — the export is built and pushed
# there; SG its path, SURL the spec repository's URL, SM its main (fetched), or empty (main 404–411)
specgit() {
  xlocal || ! wasmanual || [ -z "$SPEC" ] || [ "$(lc "$SPEC")" != "$(lc "$(twkey state-repo)")" ] || gref "spec-repo: names the state-repo:, $SPEC, ViD's own state repository: answer it again (sh checks/planner.sh setup spec-repo <owner/name> --words \"<their words>\")"   # FB-3 B2: manual's state repository may be the old spec repository
  xlocal || [ -n "$SPEC" ] || gref ".vid/tw/settings names no spec-repo: — sh checks/github.sh spec-setup first"
  SG=$(pwd -P)/.vid/spec.git
  [ -d "$SG" ] || { git init -q --bare "$SG" && git --git-dir="$SG" symbolic-ref HEAD refs/heads/main; } || gref "$SG could not be made"
  GC=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && case $GC in /*|?:/*) ;; *) false ;; esac || { GC=$(cd "$(git rev-parse --git-common-dir)" && pwd -P); ! command -v cygpath > /dev/null 2>&1 || GC=$(cygpath -m "$GC"); }   # git before 2.31 has no --path-format; Git Bash's cygpath gives Windows git's form
  printf '%s/objects\n' "$GC" > "$W/alt" || exit 1; put "$SG/objects/info/alternates" < "$W/alt" || exit 1   # the path in the form the git that reads it gives, never the shell's (v0.26.10.25.2.1, F-007: Git Bash's /c/… is no path to Windows git)
  if xlocal; then specloc; else specmain; fi; }
specmain() {   # the spec repository's main, fetched
  SURL=$(ghc repo view "$SPEC" --json url --jq .url 2>/dev/null) && [ -n "$SURL" ] || gref "no access to the spec repository $SPEC: gh repo view $SPEC failed (sh checks/github.sh spec-setup makes it)"
  SM=$(git --git-dir="$SG" ls-remote "$SURL" refs/heads/main 2>/dev/null | cut -f1)
  if [ -n "$SM" ]; then keeperr git --git-dir="$SG" fetch -q "$SURL" "+refs/heads/main:refs/heads/main" 2>/dev/null || gref "the spec repository $SPEC could not be fetched (git needs its credentials: gh auth setup-git)"
  else git --git-dir="$SG" update-ref -d refs/heads/main 2>/dev/null || true; fi; }

# ownp <tree> (GM-2 T1): $W/own, the export's own files, once a call: every file of the tree it builds now, and every file an
# earlier export of ViD's put on the spec repository's main, read from main's history: the files each export commit added or
# changed, an export commit being one authored ViD <vid@export.invalid> whose message opens "ViD export of ", as spec-export
# writes it (a share's push has that author too, and is no export); no record kept beside it. Any other file, one under
# design/ too, is no export's
ownp() { [ ! -f "$W/own" ] || return 0
  { git --git-dir="$SG" ls-tree -r -z --name-only "$1" && { [ -z "$SM" ] || git --git-dir="$SG" log -z --format= --name-only --no-renames --diff-filter=AMT --author='<vid@export\.invalid>' --grep='^ViD export of ' "$SM"; }; } > "$W/own0" || return 1
  tr '\n\000' '\001\n' < "$W/own0" | grep -v '^$' | sort -u > "$W/own"; }
# mtree <commit or nothing> <tree> (GM-2 T1): in .vid/spec.git, the commit's tree with every one of the export's own files (ownp)
# taken out and the tree's entries put in, printed: GitHub manual's export commit, which keeps every file of the spec repository's
# main no export put there. A commit whose own files hold the tree already gives its own tree back, so the export and the
# freshness check compare the export's own files alone
mtree() { ownp "$2" || return 1; _mi=$W/mindex; rm -f "$_mi"; GIT_INDEX_FILE=$_mi git --git-dir="$SG" read-tree --empty || return 1
  if [ -n "$1" ]; then git --git-dir="$SG" ls-tree -r -z "$1" > "$W/ml0" || return 1
    tr '\n\000' '\001\n' < "$W/ml0" | awk -v O="$W/own" 'BEGIN { while ((getline l < O) > 0) own[l] = 1 } { p = substr($0, index($0, "\t") + 1); if (!(p in own)) print }' | tr '\001\n' '\n\000' > "$W/ml1"
    [ ! -s "$W/ml1" ] || GIT_INDEX_FILE=$_mi git --git-dir="$SG" update-index -z --index-info < "$W/ml1" || return 1; fi
  git --git-dir="$SG" ls-tree -r -z "$2" > "$W/ml2" && GIT_INDEX_FILE=$_mi git --git-dir="$SG" update-index -z --index-info < "$W/ml2" || return 1
  GIT_INDEX_FILE=$_mi git --git-dir="$SG" write-tree; }

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

# GM-2 T3: GitHub manual's first post, in the project's own issue form (issue-form:, a file of ViD's repository read at HEAD). FKN: the
# placeholders, each a whole line of the form's body; FTI: those its title line may hold, every one (each fills one line).
# {full-ticket}, {blocked-by}, {not-yet-ticketed},
# {fakes}, and {tests} or one of its kinds, are in every form (GM M4, M7)
FKN=' {name} {step} {stage} {lane} {requirements} {tests} {tests:row} {tests:rule} {tests:difference} {tests:hostility} {tests:seam} {blocked-by} {not-yet-ticketed} {fakes} {parent} {full-ticket} '
FTI=$FKN
# formfill <ticket file>: the form filled for the ticket, read from local files alone, before anything is posted; a form that cannot be
# filled refuses, naming why. Sets FM (the form's path), FH (its hash), FT (the title), FIP (issue-parent:, or empty for none), and
# writes $W/fb (the body), $W/fr (the record, `<placeholder>\t<the line it was filled with>` a line, in the form's order), $W/fbl (the
# tickets the step builds on that have one: the blocked-by links), $W/fla (the tickets whose step builds on this one: their links,
# added later) and $W/fid (the test ids the body names)
formfill() {
  FM=$(skey issue-form); [ -n "$FM" ] || gref ".vid/tw/settings names no issue-form: — a ticket posted in the project's own issue form is amended in it — nothing posted"
  [ "$(git cat-file -t "HEAD:$FM" 2>/dev/null)" = blob ] || gref "issue-form: $FM is not a file committed at HEAD: commit it in ViD's repository — nothing posted"
  FH=$(git rev-parse "HEAD:$FM"); git show "HEAD:$FM" | tr -d '\r' > "$W/form" || gref "issue-form: $FM could not be read — nothing posted"
  FIP=$(skey issue-parent); case $FIP in none|'') FIP='' ;; *[!0-9]*) gref "issue-parent: $FIP is not an issue number, or none — nothing posted" ;; esac
  _fs=$(sed -n 's/^- step: //p' "$1" | head -n 1); _fa=$(applied)
  # the plan's steps (RUN-STATE's block, as the writer reads it, a tab read as a space): id, name, builds-on,
  # lane, fakes; and the tickets published, not withdrawn
  # GM-3 U4: a step the plan no longer holds (a ticket left with only retired tests) is read from the newest
  # recorded plan that held it, as the writer reads it
  _fsp() { tr '\t' ' ' | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } /^[ \t]*step[ \t]/ { id = tr($1); sub(/^step[ \t]+/, "", id); nm = bo = ln = fk = ""
      for (i = 2; i <= NF; i++) { x = tr($i); if (x ~ /^name:/) nm = tr(substr(x, 6)); else if (x ~ /^builds-on:/) bo = tr(substr(x, 11)); else if (x ~ /^lane:/) ln = tr(substr(x, 6)); else if (x ~ /^fakes:/) fk = tr(substr(x, 7)) }
      gsub(/,/, " ", bo); gsub(/,/, " ", fk); if (bo == "-") bo = ""; if (fk == "-") fk = ""; print id "\t" nm "\t" bo "\t" ln "\t" fk }'; }
  plan_block | _fsp > "$W/fs"
  if manual && ! awk -F'\t' -v s="$_fs" '$1 == s { f = 1 } END { exit !f }' "$W/fs"; then
    for _h in $(grep '^plan-change ' .vid/metrics-events 2>/dev/null | sed -n 's/^plan-change what=[^ ]* hash=\([0-9a-f]*\) .*/\1/p' | sed -n '1!G;h;$p'); do
      grep -qE "^[[:space:]]*step[[:space:]]+$_fs[[:space:]]*[|]" ".vid/plans/$_h.plan" 2>/dev/null || continue; _fsp < ".vid/plans/$_h.plan" | awk -F'\t' -v s="$_fs" '$1 == s' >> "$W/fs"; break; done; fi
  awk -F'\t' -v s="$_fs" '$1 == s { f = 1 } END { exit !f }' "$W/fs" || gref "the ticket's step $_fs is no step of the plan — nothing posted"
  awk 'function kv(k,   i) { for (i = 3; i <= NF; i++) if (index($i, k "=") == 1) return substr($i, length(k) + 2); return "" }
    $1 == "withdrawn" { W[$2] = 1 } $1 == "published" && $2 ~ /^[0-9]+$/ && !($2 in S) { S[$2] = kv("step"); O[++n] = $2 }
    END { for (i = 1; i <= n; i++) if (!(O[i] in W)) print O[i] "\t" S[O[i]] }' .vid/tw/log 2>/dev/null > "$W/ftk" || :
  _fn=$(awk -F'\t' -v s="$_fs" '$1 == s { print $2 }' "$W/fs"); _fb=$(awk -F'\t' -v s="$_fs" '$1 == s { print $3 }' "$W/fs")
  _fl=$(awk -F'\t' -v s="$_fs" '$1 == s { print $4 }' "$W/fs"); _fk=$(awk -F'\t' -v s="$_fs" '$1 == s { print $5 }' "$W/fs")
  : > "$W/fbl"; _fy=''; for _b in $(printf '%s\n' "$_fb" | tr ' ' '\n' | grep -v '^$'); do _t=$(awk -F'\t' -v s="$_b" '$2 == s { print $1 }' "$W/ftk")
    if [ -n "$_t" ]; then printf '%s\n' "$_t" >> "$W/fbl"; else _fy="$_fy${_fy:+, }$_b"; fi; done
  awk -F'\t' -v s="$_fs" 'FILENAME == ARGV[1] { n = split($3, b, " "); for (i = 1; i <= n; i++) if (b[i] == s) D[$1] = 1; next } ($2 in D) { print $1 }' "$W/fs" "$W/ftk" > "$W/fla"
  # the tests by kind, each id's kind as the applied INVENTORY.md gives it (a line opening rule, difference, hostility or seam), else row;
  # its vid-inventory blocks' lines alone, as next.sh's invat reads them
  { git show "$_fa:INVENTORY.md" 2>/dev/null || :; } | awk '/^```vid-inventory/ { b = 1; next } b && /^```/ { b = 0; next } b && !/^[ \t]*(#|$|grammar:)/' | awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } NF > 1 { k = tr($1); if (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) print tr($2) "\t" k; else print k "\trow" }' > "$W/fki"
  sed -n 's/^- rows: //p' "$1" | head -n 1 | tr ' ' '\n' | grep -v '^$' > "$W/frw" || { manual && grep -q '^- [A-Z][A-Z0-9]*-[0-9][0-9A-Z-]* marks: retired; ' "$1"; } || gref "the ticket names no rows — nothing posted"   # GM-3 U4: or only retired tests, listed
  awk -F'\t' 'FILENAME == ARGV[1] { if (!($1 in K)) K[$1] = $2; next } { print $1 "\t" (($1 in K) ? K[$1] : "row") }' "$W/fki" "$W/frw" > "$W/frk"
  ids() { paste -sd , - | sed 's/,/, /g'; }
  # the requirement ids the ticket's Requirements section quotes (the answers they cite left out)
  _fq=$(awk '/^## / { s = substr($0, 4); next } s == "Requirements" && /^The answers they cite:/ { s = "" } s == "Requirements" && /^> / { id = substr($0, 3); sub(/[ \t]*\|.*/, "", id); if (id ~ /^[A-Z][A-Z0-9]*-[0-9]+$/) print id }' "$1" | ids)
  { printf '{name}\t%s\n{step}\t%s\n{stage}\t%s\n{lane}\t%s\n{requirements}\t%s\n' "$_fn" "$_fs" "$(sed -n 's/^- stage: //p' "$1" | head -n 1)" "$_fl" "$_fq"
    printf '{tests}\t%s\n' "$(cut -f1 "$W/frk" | ids)"; for _k in row rule difference hostility seam; do printf '{tests:%s}\t%s\n' "$_k" "$(awk -F'\t' -v k="$_k" '$2 == k { print $1 }' "$W/frk" | ids)"; done
    printf '{blocked-by}\t%s\n{not-yet-ticketed}\t%s\n{fakes}\t%s\n' "$(sed 's/^/#/' "$W/fbl" | ids | grep . || echo none)" "${_fy:-none}" "$(printf '%s\n' "$_fk" | tr ' ' '\n' | grep -v '^$' | ids | grep . || echo none)"
    printf '{parent}\t%s\n{full-ticket}\t%s\n' "${FIP:+#$FIP}" 'The full ticket is in the comments below.'; } > "$W/fv"
  # the body: each placeholder line filled, left out when its filling is empty; any other line as it stands
  awk -v V="$W/fv" -v K="$FKN" -v R="$W/fr" -v E="$W/fe" 'BEGIN { FS = "\t"; while ((getline l < V) > 0) { split(l, a, "\t"); X[a[1]] = substr(l, length(a[1]) + 2) } FS = " " }
    NR == 1 { next } { t = $0; gsub(/^[ \t]+|[ \t]+$/, "", t) }
    t ~ /^\{[a-z][a-z:-]*\}$/ && index(K, " " t " ") { print t "\t" X[t] > R; if (X[t] != "") print X[t]; next }
    t ~ /^\{[^{}]*\}$/ { print "an unknown placeholder " t " (line " NR ")" > E; exit }
    match($0, /\{[a-z][a-z:-]*\}/) { p = substr($0, RSTART, RLENGTH); if (index(K, " " p " ")) print "the placeholder " p " shares its line with other text (line " NR "): each placeholder is a whole line" > E; else print "an unknown placeholder " p " (line " NR ")" > E; exit }
    { print }' "$W/form" > "$W/fb"
  [ ! -s "$W/fe" ] || gref "issue-form: $FM: $(head -n 1 "$W/fe") — nothing posted"
  for _p in '{full-ticket}' '{blocked-by}' '{not-yet-ticketed}' '{fakes}'; do cut -f1 "$W/fr" | grep -qxF "$_p" || gref "issue-form: $FM holds no $_p line, which every ticket's body needs — nothing posted"; done
  cut -f1 "$W/fr" | grep -q '^{tests' || gref "issue-form: $FM holds no {tests} line (nor one of its kinds), which every ticket's body needs — nothing posted"
  # the title: the form's first line, `# ` left out, its placeholders filled
  FT=$(sed -n '1{s/^#[[:space:]]*//;p;}' "$W/form" | awk -v V="$W/fv" -v K="$FTI" -v A="$FKN" 'BEGIN { FS = "\t"; while ((getline l < V) > 0) { split(l, a, "\t"); X[a[1]] = substr(l, length(a[1]) + 2) } FS = " " }
    { o = ""; s = $0; while (match(s, /\{[a-z][a-z:-]*\}/)) { p = substr(s, RSTART, RLENGTH); if (!index(K, " " p " ")) { print (index(A, " " p " ") ? "the placeholder " p ", which its title line may not hold" : "an unknown placeholder " p " in its title line") > "/dev/stderr"; exit 1 } o = o substr(s, 1, RSTART - 1) X[p]; s = substr(s, RSTART + RLENGTH) } print o s }' 2> "$W/fe") ||
    gref "issue-form: $FM: $(head -n 1 "$W/fe") — nothing posted"
  [ -n "$(printf '%s' "$FT" | tr -d '[:space:]')" ] || gref "issue-form: $FM: its first line, the title, is empty once filled — nothing posted"
  # the test ids the body names, each a whole word: the applied inventory's, and the ticket's rows
  { cut -f1 "$W/fki"; cat "$W/frw"; } | sort -u > "$W/fall"
  awk -v I="$W/fall" 'BEGIN { while ((getline l < I) > 0) A[l] = 1 } { m = split($0, w, /[^A-Za-z0-9_-]+/); for (i = 1; i <= m; i++) if (w[i] in A) print w[i] }' "$W/fb" | sort -u > "$W/fid"; }

# GM-2 T5: bodyids <body> <rows file…>: the test ids the body names, each a whole word: the applied inventory's (its blocks' lines) and
# the rows given, sorted, unique
bodyids() { _bf=$1; shift; { { git show "$(applied):INVENTORY.md" 2>/dev/null || :; } | awk '/^```vid-inventory/ { b = 1; next } b && /^```/ { b = 0; next } b && !/^[ \t]*(#|$|grammar:)/' |
      awk -F'|' 'function tr(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s } NF > 1 { k = tr($1); print (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) ? tr($2) : k }'; cat "$@"; } | grep -v '^$' | sort -u > "$W/bu"
  awk -v I="$W/bu" 'BEGIN { while ((getline l < I) > 0) A[l] = 1 } { m = split($0, w, /[^A-Za-z0-9_-]+/); for (i = 1; i <= m; i++) if (w[i] in A) print w[i] }' "$_bf" | LC_ALL=C sort -u; }
# GM-2 T5: refill <record> <form>: the body ViD wrote, rebuilt from the form as first posted (<form>, the body's lines after its title
# line) with each placeholder line filled from the record (`<placeholder>\t<its filling>`, in the form's order; left out when
# empty), is diffed line by line (the longest common subsequence) against the body as GitHub holds it ($W/ob0, compared with its
# carriage returns left out). Each placeholder line the diff keeps in common is replaced by its new filling ($W/fv, formfill's; left
# out when empty), with that line's own ending; every other line of the body stands as it is, byte for byte,
# so equal fillings, or a team copy of a placeholder's line, never move a filling; a placeholder line two body
# lines could stand for equally (a tie: each matched in an alignment as long, G the common lines before and L those after) is left,
# never guessed. Writes $W/nb (the body), $W/nfr (the
# record: the new filling where refilled, the old one elsewhere) and $W/left (each placeholder whose line was not found as written)
refill() { awk -v R="$1" -v FM="$2" -v V="$W/fv" -v NB="$W/nb" -v NF_="$W/nfr" -v LF="$W/left" 'BEGIN { FS = "\t"
      while ((getline l < V) > 0) { split(l, a, "\t"); X[a[1]] = substr(l, length(a[1]) + 2) }
      while ((getline l < R) > 0) { split(l, a, "\t"); P[++k] = a[1]; O[k] = substr(l, length(a[1]) + 2) } FS = " "
      q = 0; f = 0; while ((getline l < FM) > 0) { sub(/\r$/, "", l); if (++f == 1) continue; t = l; gsub(/^[ \t]+|[ \t]+$/, "", t)
        if (q < k && t == P[q + 1]) { q++; if (O[q] == "") continue; A[++n] = O[q]; E[n] = q } else A[++n] = l } }
    { C[++m] = $0; B[m] = $0; sub(/\r$/, "", B[m]) }
    END { for (i = n + 1; i >= 1; i--) for (j = m + 1; j >= 1; j--) { if (i > n || j > m) L[i, j] = 0; else if (A[i] == B[j]) L[i, j] = L[i + 1, j + 1] + 1; else L[i, j] = (L[i + 1, j] >= L[i, j + 1]) ? L[i + 1, j] : L[i, j + 1] }
      for (i = 0; i <= n; i++) for (j = 0; j <= m; j++) { if (!i || !j) G[i, j] = 0; else if (A[i] == B[j]) G[i, j] = G[i - 1, j - 1] + 1; else G[i, j] = (G[i - 1, j] >= G[i, j - 1]) ? G[i - 1, j] : G[i, j - 1] }
      i = 1; j = 1; while (i <= n && j <= m) { if (A[i] == B[j] && L[i, j] == L[i + 1, j + 1] + 1) { if (i in E) { c = 0; for (h = 1; h <= m; h++) if (A[i] == B[h] && G[i - 1, h - 1] + 1 + L[i + 1, h + 1] == L[1, 1]) c++
            if (c == 1) { U[j] = E[i]; M[E[i]] = 1 } } i++; j++ } else if (L[i + 1, j] >= L[i, j + 1]) i++; else j++ }
      printf "" > NB; for (j = 1; j <= m; j++) { if (j in U) { e = U[j]; v = (P[e] in X) ? X[P[e]] : O[e]; cr = (C[j] ~ /\r$/) ? "\r" : ""; if (v != "") print v cr > NB } else print C[j] > NB }
      printf "" > LF; for (e = 1; e <= k; e++) { v = ((e in M) && (P[e] in X)) ? X[P[e]] : O[e]; print P[e] "\t" v > NF_; if (!(e in M) && O[e] != "") print P[e] > LF } }' "$W/ob0"; }
CMD=${1:-}; [ $# -gt 0 ] && shift
case "$CMD" in
  access)   # v0.26.10.12.3.1 (PE R3): what ViD can reach, read only; it reports and never refuses
    [ $# -eq 0 ] || usage; M=0; B=0
    say() { M=$((M + 1)); [ "$1" = ok ] || B=$((B + 1)); shift; echo "access $*"; }
    words() { tr '\n' ' ' < "$1" | sed 's/[[:space:]]*$//'; }
    if ghc auth status > "$W/auth" 2>&1; then say ok 'gh — signed in'; else say no "gh — not signed in: $(words "$W/auth")"; echo "access: $B of $M not ready"; exit 0; fi
    for k in repo spec-repo; do   # GM-4 J5: the private spec repository in both layouts; FB-3 B2: but with one repository in GitHub manual
      [ "$k" = repo ] || ! xlocal || continue
      n=$(twkey "$k")
      if [ -z "$n" ]; then say no "$k — not set yet"; continue; fi
      if P=$(ghc repo view "$n" --json isPrivate --jq .isPrivate 2> "$W/e") && V=$(ghc repo view "$n" --json viewerPermission --jq .viewerPermission 2> "$W/e"); then
        v=public; [ "$P" = true ] && v=private
        if [ "$k" = repo ] || [ "$v" = private ]; then say ok "$k $n — reached, $V, $v"; else say no "$k $n — public: spec-setup refuses it"; fi
      elif [ "$k" = repo ]; then say no "$k $n — not reached: $(words "$W/e"); the connect makes it if it does not exist yet"   # FB-2 A1
      else say no "$k $n — not reached: $(words "$W/e"); spec-setup makes it if it does not exist yet"; fi
    done
    if [ "$B" = 0 ]; then echo 'access: ok'; else echo "access: $B of $M not ready"; fi; exit 0 ;;

  tw-sync)   # v0.26.10.12.3 (R9): the code repository's main and TW's open tickets
    tw; U=$(ghc repo view "$REPO" --json url --jq .url 2>/dev/null) && [ -n "$U" ] || gref "no access to $REPO: gh repo view $REPO failed"
    M=$(codemain) || gref "the code repository's main could not be read (git ls-remote): nothing recorded"; O=''   # v0.26.10.28.2 (R3): none is an empty repository alone
    ghc issue list -R "$REPO" --state open --limit 1000 --json number --jq '.[].number' > "$W/on" || gref 'the open issues could not be read'
    # GM-4 E4: an accepted ticket (its merge on record in merges) reads as closed to the writer, its issue open until the step's close
    for n in $(awk '$1 == "published" { print $2 }' .vid/tw/log 2>/dev/null | sort -un); do grep -q "^withdrawn $n " .vid/tw/log && continue; awk -F'\t' -v n="$n" '$2 == n { f = 1 } END { exit !f }' .vid/decide/merges 2>/dev/null && continue; grep -qx "$n" "$W/on" && O="$O${O:+,}$n"; done
    twlog "sync main=${M:-none} open=${O:--} at=$(now)"; echo "ViD github: synced — main ${M:-none}, open tickets ${O:-none}"; exit 0 ;;

  tw-post)   # v0.26.10.12.3 (R3, R7–R9): a written ticket published, or open ticket <n> amended in place
    tw; A=''; if [ "${1:-}" = --amend ]; then A=${2:-}; shift 2; fi
    # GM-2 T3: a post takes the owner's words (--words), and may take a title in them (--title); GM-4 K1: in either mode, the words
    # required in GitHub manual alone (GM M16: each post there is the owner's yes) and kept on the log line whenever given
    WO=''; WS=''; TI=''; while [ $# -gt 1 ]; do case $1 in --words) WO=$2; WS=1 ;; --title) TI=$2 ;; *) break ;; esac; shift 2; done
    [ -z "$WS" ] || [ -n "$(printf '%s' "$WO" | tr -d '[:space:]')" ] || manual || WS=''   # GitHub auto: blank words are no words
    WQ=$(printf '%s' "$WO" | tr '\t\n\r' '   ' | tr '"' "'")
    F=${1:-}; { ! manual || [ $# -eq 1 ]; } && [ -f "$F" ] && [ -f "${F%.md}.meta" ] || usage   # a trailing argument refused in GitHub manual alone
    # GM-4 F6: the form of a post comes from the setup alone. An amendment takes GM-2 T5's way (the body read, changed only where ViD's
    # own text stands, every part a comment) for a ticket posted in the issue form, in either mode, and in GitHub manual for every ticket
    # (GM-2 T5: there the team may change the body); else, in GitHub auto, part 1 is the body again, as today
    [ -z "$A" ] || [ -z "$TI" ] || gref "an amendment never changes the ticket's title (no --title with --amend) — nothing posted"
    FA=''; if [ -n "$A" ] && { manual || [ -f ".vid/tw/form/issue-$A" ]; }; then FA=1   # GM-2 T5, T6
      ! manual || { [ -n "$WS" ] && [ -n "$(printf '%s' "$WO" | tr -d '[:space:]')" ]; } || gref "in GitHub manual a ticket is amended only on the owner's words (tw-post --amend $A --words \"<their words>\") — nothing posted"; fi
    # GM-2 T3; GM-4 F6: a first post goes out in the project's own form when issue-form: is set, in either mode, else part 1 is its body;
    # in GitHub manual on the owner's words (GM M16); checked before anything is read or posted
    FP=''; if [ -z "$A" ]; then
      ! manual || { [ -n "$WS" ] && [ -n "$(printf '%s' "$WO" | tr -d '[:space:]')" ]; } || gref "in GitHub manual a ticket goes out only on the owner's words (tw-post --words \"<their words>\") — nothing posted"
      if [ -n "$(skey issue-form)" ]; then FP=1; formfill "$F"; [ -z "$TI" ] || FT=$(printf '%s' "$TI" | tr '\t\n' '  '); fi; fi
    rhead   # 0.26.10.29.2 (R12)
    { sh "$HERE/writer.sh" gate && sh "$HERE/writer.sh" check "$F" && sh "$HERE/writer.sh" fresh "$F" $A; } > "$W/ck" 2>&1 || { sed 's/^/    /' "$W/ck" >&2; gref "the gate is shut, the check refuses $F, or it is stale — nothing posted"; }
    X=$(sed -n 's/^- export: //p' "$F" | head -n 1); exptree; specgit
    if manual; then   # GM-2 T1: the export's own paths alone: the ticket's export, on main's history, and main each hold there what the export holds now
      [ -n "$SM" ] && git --git-dir="$SG" rev-parse -q --verify "$X^{commit}" > /dev/null 2>&1 && git --git-dir="$SG" merge-base --is-ancestor "$X" "$SM" 2>/dev/null &&
        [ "$(mtree "$X" "$TR")" = "$(git --git-dir="$SG" rev-parse "$X^{tree}")" ] && [ "$(mtree "$SM" "$TR")" = "$(git --git-dir="$SG" rev-parse "$SM^{tree}")" ] ||
        gref "the ticket's export ${X:-none} does not hold, at the export's own paths, the applied version $(if xlocal; then echo "ViD's newest export"; else echo "the spec repository's main"; fi) holds: sh checks/github.sh spec-export, then write it again"
    else [ -n "$SM" ] && [ "$X" = "$SM" ] && [ "$(git --git-dir="$SG" rev-parse "$SM^{tree}")" = "$TR" ] || gref "the ticket's export ${X:-none} is not the spec repository's main at ViD's HEAD: sh checks/github.sh spec-export, then write it again"; fi
    [ -z "$A" ] || oprs "$A" > "$W/opn"   # 0.26.10.29.2 (R11): its pull requests read whole before anything is posted
    if [ -n "$FA" ]; then   # GM-2 T5: the body as GitHub holds it, read before anything is posted; the form refilled from the new writing
      # $W/ob0 keeps the body's bytes, its line endings among them; $W/ob, with its carriage returns left out,
      # is for comparing alone
      ghc issue view "$A" -R "$REPO" --json body --jq .body > "$W/ob0" || gref "the body of #$A could not be read — nothing posted"; tr -d '\r' < "$W/ob0" > "$W/ob"
      BK=part1; if [ -f ".vid/tw/form/issue-$A" ]; then BK=form; formfill "$F"
        # the form as first posted: the hash on the ticket's first published line
        FHP=$(awk -v n="$A" '$1 == "published" && $2 == n { print; exit }' .vid/tw/log | tr ' ' '\n' | sed -n 's/^form=//p' | head -n 1)
        git cat-file -p "$FHP" > "$W/form0" 2>/dev/null || gref "the form #$A was first posted in (${FHP:-no hash}) could not be read — nothing posted"
      elif grep -qE "^published $A .* taken-over=comments( |\$)" .vid/tw/log; then BK=team; fi
      awk -v n="$A" '($1 == "published" || $1 == "amended") && $2 == n { l = $0 } END { print l }' .vid/tw/log | tr ' ' '\n' | sed -n 's/^rows=//p' | tr , '\n' | grep -v '^-*$' > "$W/or" || :
      kv "$(sed -n 1p "${F%.md}.meta")" rows | tr , '\n' | grep -v '^-*$' > "$W/nr" || :
      grep -vxF -f "$W/or" "$W/nr" > "$W/ad" || :; grep -vxF -f "$W/nr" "$W/or" > "$W/to" || :
      # the team's own additions: an added test the body names now that no post or amendment of ViD's put there
      # (the kept body read through a file that always exists, empty for a ticket taken over)
      : > "$W/kb0"; [ ! -f ".vid/tw/body/issue-$A" ] || cp ".vid/tw/body/issue-$A" "$W/kb0"
      bodyids "$W/ob" "$W/or" "$W/nr" | grep -xF -f "$W/ad" | grep -vxF -f "$W/kb0" > "$W/ta" || :
      # a ticket with no kept body (taken over) has one seeded first with what phase 1 reads the body held
      # (next.sh changes' `was`): the ids part 1 of the recorded writing names when the body opens with ViD's part-1 header, else the
      # log line's rows, so a team removal not yet answered stays listed after this amendment
      : > "$W/seed"; if [ ! -f ".vid/tw/body/issue-$A" ]; then
        if head -n 1 "$W/ob" | grep -qE "^Ticket #$A, part 1 of [0-9]+, writing [0-9a-f]+\.\$"; then rm -rf "$W/op1"
          if grep -q "^Ticket #$A, part 1 of [0-9]*, writing " ".vid/tw/out/issue-$A.md" 2>/dev/null; then awk -v n="$A" 'index($0, "Ticket #" n ", part 1 of ") == 1 { on = 1; next } on && index($0, "Ticket #" n ", part ") == 1 { exit } on' ".vid/tw/out/issue-$A.md" > "$W/op1.md"
          else sh "$HERE/writer.sh" parts ".vid/tw/out/issue-$A.md" "$A" "$W/op1" > /dev/null 2>&1 && cp "$W/op1/part-1.md" "$W/op1.md" || : > "$W/op1.md"; fi
          bodyids "$W/op1.md" "$W/or" > "$W/seed"
        else cp "$W/or" "$W/seed"; fi; fi
      # the part-1 header ViD wrote, exactly: the one its last amendment wrote (.vid/tw/head/issue-<n>), else
      # the header of the writing posted (a take-over's parts= and writing=, or the log line's parts= and the recorded writing's hash)
      EH=''; if [ "$BK" = part1 ]; then if [ -f ".vid/tw/head/issue-$A" ]; then EH=$(sed -n 1p ".vid/tw/head/issue-$A")
        else _tl=$(awk -v n="$A" '($1 == "published" || $1 == "amended") && $2 == n { l = $0 } END { print l }' .vid/tw/log); _tp=$(kv "$_tl" parts); _tw=$(kv "$_tl" writing)
          [ -n "$_tw" ] || _tw=$(git hash-object ".vid/tw/out/issue-$A.md" 2>/dev/null | cut -c1-12); EH="Ticket #$A, part 1 of $_tp, writing $_tw."; fi; fi
      SZ=$(sh "$HERE/writer.sh" topup "$(grep -c . "$W/ad")" "$(grep -c . "$W/or")") || gref "writer.sh topup failed — nothing posted"; fi
    # GM-2 T3: the ids of the tickets its step builds on, read before anything is posted
    : > "$W/fbi"; [ -z "$FP" ] || for b in $(cat "$W/fbl"); do i=$(ghc api "repos/$REPO/issues/$b" --jq .id) && [ -n "$i" ] || gref "the id of #$b, the ticket of a step this one builds on, could not be read — nothing posted"; echo "$i" >> "$W/fbi"; done
    ghc label create "${PFX}ticket" -R "$REPO" --force --description 'ViD: a ticket' > /dev/null || gref "the label ${PFX}ticket could not be made"
    ghc label create "${PFX}blocked" -R "$REPO" --force --description 'ViD: a question stops this' > /dev/null || gref "the label ${PFX}blocked could not be made"
    TT=$(sed -n '1s/^# //p' "$F")
    if [ -n "$FP" ]; then   # GM-2 T3: the issue made with the filled form as its body
      N=$(ghc issue create -R "$REPO" --title "$FT" --body-file "$W/fb" --label "${PFX}ticket" | num_of_url) && [ -n "$N" ] || gref "the issue for $F could not be made"
    elif [ -n "$A" ]; then N=$A; else printf 'ViD is writing this ticket; its body follows in a moment.\n' > "$W/ph"
      N=$(ghc issue create -R "$REPO" --title "$TT" --body-file "$W/ph" --label "${PFX}ticket" | num_of_url) && [ -n "$N" ] || gref "the issue for $F could not be made"; fi
    sed "s/^- number: .*/- number: $N/" "$F" > "$W/t.md"; sh "$HERE/writer.sh" parts "$W/t.md" "$N" "$W/p" > "$W/pl" || gref "the parts of $F could not be made"
    # GM-2 T3: in the form every part is a comment, part 1 among them; else part 1 is the body, as today
    if [ -n "$FP" ] || [ -n "$FA" ]; then cp "$W/pl" "$W/pc"; else ghc issue edit "$N" -R "$REPO" --title "$TT" --body-file "$(sed -n 1p "$W/pl")" > /dev/null || gref "the body of #$N could not be written"; sed 1d "$W/pl" > "$W/pc"; fi
    : > "$W/cu"; for p in $(cat "$W/pc"); do ghc issue comment "$N" -R "$REPO" --body-file "$p" >> "$W/cu" || gref "a part of #$N could not be posted"; done
    if [ -n "$FA" ]; then   # GM-2 T5: the body changed only where ViD's own text stands as ViD wrote it
      : > "$W/left"; cp "$W/ob0" "$W/nb"; H2=$(sed -n '1s/.*, writing \([0-9a-f]*\)\.$/\1/p' "$(sed -n 1p "$W/pl")")
      if [ "$BK" = form ]; then refill ".vid/tw/form/issue-$A" "$W/form0"
      elif [ "$BK" = part1 ]; then if [ "$(head -n 1 "$W/ob")" = "$EH" ]; then   # the header exactly as ViD wrote it
          NH="$(printf '%s' "$EH" | sed 's/ This part is replaced: .*$//') This part is replaced: the current writing, $H2, is in this issue's comments."
          { printf '%s' "$NH"; head -n 1 "$W/ob0" | grep -q "$(printf '\r')\$" && printf '\r'; printf '\n'; sed 1d "$W/ob0"; } > "$W/nb"
        else echo 'its first line' > "$W/left"; fi; fi
      cmp -s "$W/ob0" "$W/nb" || ghc issue edit "$A" -R "$REPO" --body-file "$W/nb" > /dev/null || gref "the body of #$A could not be refilled; its new part comments are posted: amend it again"; fi
    # 0.26.10.29.2 (R11): the amendment's cause and each row added, removed or changed (the meta's `tell` lines), on the issue and each open pull request
    # GM-2 T5, T6: in GitHub manual the move's cause, each test added (the team's own marked), restated or taken out, each body line left;
    # GM-4 F6: in GitHub auto, a form ticket's amendment names its cause as every amendment there does
    if [ -n "$FA" ] && manual; then { printf 'vid: amended. Cause: %s.\n\n' "$(sed -n 's/^why //p' "${F%.md}.meta")"
        if grep -q '^tell ' "${F%.md}.meta"; then sed -n 's/^tell //p' "${F%.md}.meta" | awk -v TA="$W/ta" 'BEGIN { while ((getline l < TA) > 0) A[l] = 1 } /^- added: / && ($3 in A) { $0 = $0 ", the team'"'"'s own addition" } { print }'
        else echo 'No test was added, restated or taken out.'; fi
        ! grep -q '^tell - restated: ' "${F%.md}.meta" || printf '\nEarlier results for its restated tests do not count.\n'
        [ ! -s "$W/left" ] || { printf '\nLeft as the team changed it:\n'; sed 's/^\(.*\)$/- the body'"'"'s \1 line/; s/the body.s its first line line/the body'"'"'s first line/' "$W/left"; }
        [ -z "$SZ" ] || printf '\nThe top-up is over the size a ticket is written to: %s tests at its last writing; %s.\n' "$(grep -c . "$W/or")" "$SZ"; } > "$W/am"
    elif [ -n "$A" ]; then { printf 'vid: amended %s. Earlier results for its changed rows do not count.\n' "$(sed -n 's/^why //p' "${F%.md}.meta")"; ! grep -q '^tell ' "${F%.md}.meta" || { echo; sed -n 's/^tell //p' "${F%.md}.meta"; }; } > "$W/am"; fi
    [ -z "$A" ] || { tell "$N" "$W/am" || gref "the amendment of #$N could not be named"
      CU=$(paste -sd ' ' "$W/cu" | sed 's/ /, /g'); if [ -n "$FA" ]; then printf 'vid: replaced. This comment held a part of an earlier writing of this ticket. The current writing, %s, is in this issue'"'"'s part comments %s.\n' "$H2" "$CU" > "$W/rp"; else printf 'vid: replaced. This comment held a part of an earlier writing of this ticket. The current writing, %s, is this issue'"'"'s body%s.\n' "$(sed -n '1s/.*, writing \([0-9a-f]*\)\.$/\1/p' "$(sed -n 1p "$W/pl")")" "${CU:+, then its part comments $CU}" > "$W/rp"; fi
      for c in $(ghc issue view "$N" -R "$REPO" --json comments --jq '.comments[] | .url + "\t" + (.body | split("\n") | .[0])' | tr -d '\r' | awk -F'\t' -v CU="$W/cu" 'BEGIN { while ((getline l < CU) > 0) K[l] = 1 } !($1 in K) && ($2 ~ /^Ticket #[0-9]+, part [0-9]+ of [0-9]+, writing [0-9a-f]+\.$/ || index($2, "vid: replaced.") == 1) { sub(/.*issuecomment-/, "", $1); print $1 }'); do
        ghc api -X PATCH "repos/$REPO/issues/comments/$c" -F "body=@$W/rp" > /dev/null || gref "the earlier part comment $c of #$N could not be marked replaced"; done; }
    # 0.26.10.29.2 (R3): the rows an amendment takes out of a ticket whose pull request is open, handed over (`handover`, after its amended line)
    HO=''; if [ -n "$A" ]; then awk -v n="$N" '($1 == "published" || $1 == "amended") && $2 == n { l = $0 } END { print l }' .vid/tw/log | tr ' ' '\n' | sed -n 's/^rows=//p' | tr , '\n' | grep -v '^-*$' > "$W/r0" || true
      kv "$(sed -n 1p "${F%.md}.meta")" rows | tr , '\n' > "$W/r1"; HR=$(grep -vxF -f "$W/r1" "$W/r0" | paste -sd , -); [ -z "$HR" ] || [ ! -s "$W/opn" ] || hov "$N" "$HR" || HO="handover $N pr=$(paste -sd , "$W/opn") rows=$HR"; fi
    K1=published; [ -z "$A" ] || K1=amended
    MA=''; if [ -n "$FA" ]; then MA=" added=$(paste -sd , "$W/ad" | grep . || echo -)"; [ -z "$SZ" ] || MA="$MA size=$(grep -c . "$W/ad")/$(grep -c . "$W/or")"; [ "$BK" != form ] || MA=" form=$FHP$MA"; [ -z "$WS" ] || MA="$MA words=\"$WQ\""; fi   # GM-2 §5, T6
    MW=''; [ -n "$FA" ] || [ -z "$WS" ] || MW=" words=\"$WQ\""   # GM-4 K1: the owner's words on every post that takes them
    # GM-4 E3: an amendment names the tests its notice names restated, restated=<ids>, last, when there are any
    RSD=$(sed -n 's/^tell - restated: \([^ ,]*\).*/\1/p' "${F%.md}.meta" 2>/dev/null | paste -sd , -); [ -n "$A" ] && [ -n "$RSD" ] && MA="$MA restated=$RSD" || true
    twlog "$K1 $N $(sed -n 1p "${F%.md}.meta") parts=$(grep -c . "$W/pl") at=$(now)${FP:+ form=$FH}$MW$MA"
    awk -v n="$N" -v t="$(now)" '$1 == "sent" { print "sent " $2 " ticket=" n " hash=" $3 " at=" t }' "${F%.md}.meta" >> .vid/tw/log; [ -z "$HO" ] || twlog "$HO at=$(now)"
    mkdir -p .vid/tw/out; put ".vid/tw/out/issue-$N.md" < "$W/t.md" || exit 1
    if [ -n "$FA" ]; then   # GM-2 T5 (§5): the refilled form record, the body's ids added to, and a `moved` line for each test taken out
      mkdir -p .vid/tw/body .vid/next; [ "$BK" != form ] || put ".vid/tw/form/issue-$N" < "$W/nfr" || exit 1
      tr -d '\r' < "$W/nb" > "$W/nbc"; { bodyids "$W/nbc" "$W/or" "$W/nr"; cat "$W/seed" "$W/kb0"; } | grep -v '^$' | LC_ALL=C sort -u > "$W/fbo"; put ".vid/tw/body/issue-$N" < "$W/fbo" || exit 1
      if [ "$BK" = part1 ] && [ ! -s "$W/left" ]; then mkdir -p .vid/tw/head; printf '%s\n' "$NH" | put ".vid/tw/head/issue-$N" || exit 1; fi
      ! manual || for r in $(cat "$W/to"); do printf '%s\tmoved\t%s\t-\t-\t%s\t%s\n' "$N" "$r" "$(now)" "$WQ" >> .vid/next/team-answers; done
      echo "ViD github: the tests of #$N: $(grep -c . "$W/ad") added, $(grep -c . "$W/to") taken out, against its $(grep -c . "$W/or") at its last writing${SZ:+; flagged: $SZ}"; fi
    if [ -n "$FP" ]; then   # GM-2 T3 (§5): the form record and the body's ids, kept; then the links: the parent, the blocked-by ones, and those
      # this ticket adds to the earlier tickets whose step builds on its own (their bodies untouched). The post is recorded before
      # them, so a link that fails is named, the ticket kept, and never posted twice
      mkdir -p .vid/tw/form .vid/tw/body; put ".vid/tw/form/issue-$N" < "$W/fr" || exit 1
      cat "$W/fid" ".vid/tw/body/issue-$N" 2>/dev/null | LC_ALL=C sort -u > "$W/fbo"; put ".vid/tw/body/issue-$N" < "$W/fbo" || exit 1
      # every link is tried, each one that fails named, one refusal at the end; only a failed read of the
      # new issue's id makes none
      LK=''; lk() { LK="$LK${LK:+; }$1"; }; ID=$(ghc api "repos/$REPO/issues/$N" --jq .id) && [ -n "$ID" ] || { ID=''; lk "the id of #$N could not be read, so no link was made"; }
      if [ -n "$ID" ]; then [ -z "$FIP" ] || FORMPOST=yes ghc api -X POST "repos/$REPO/issues/$FIP/sub_issues" -F "sub_issue_id=$ID" > /dev/null || lk "#$N could not be made a sub-issue of #$FIP"
        paste -d ' ' "$W/fbl" "$W/fbi" > "$W/fbp"; for l in $(cat "$W/fbp"); do b=${l%% *}; i=${l#* }; FORMPOST=yes ghc api -X POST "repos/$REPO/issues/$N/dependencies/blocked_by" -F "issue_id=$i" > /dev/null || lk "#$N could not be made blocked by #$b"; done
        for e in $(cat "$W/fla"); do FORMPOST=yes ghc api -X POST "repos/$REPO/issues/$e/dependencies/blocked_by" -F "issue_id=$ID" > /dev/null || lk "#$e could not be made blocked by #$N"; done; fi
      [ -z "$LK" ] || gref "ticket #$N is posted and recorded, but $LK: make each such link by hand on GitHub"; fi
    echo "ViD github: $K1 ticket #$N ($(grep -c . "$W/pl") parts)"; exit 0 ;;

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
    # GM-2 T6: done on the owner's words (--words), its cause the move's (--cause), never a plan change's; GM-4 K1, F6: in either mode,
    # the words required in GitHub manual alone (GM M16) and optional in GitHub auto, where a withdrawal with none is the round's
    tw; WO=''; WS=''; WC=''; while [ $# -gt 1 ]; do case $1 in --words) WO=$2; WS=1 ;; --cause) WC=$2 ;; *) break ;; esac; shift 2; done
    [ -z "$WS" ] || [ -n "$(printf '%s' "$WO" | tr -d '[:space:]')" ] || manual || WS=''   # GitHub auto: blank words are no words
    ! manual || { [ -n "$WS" ] && [ -n "$(printf '%s' "$WO" | tr -d '[:space:]')" ]; } || gref "in GitHub manual a ticket is withdrawn only on the owner's words (tw-close --words \"<their words>\" <n>) — nothing posted"
    WQ=$(printf '%s' "$WO" | tr '\t\n\r' '   ' | tr '"' "'")
    N=${1:-}; [ $# -eq 1 ] || [ -z "$WS$WC" ] || usage; case "$N" in ''|*[!0-9]*) usage ;; esac; grep -q "^published $N " .vid/tw/log 2>/dev/null || gref "#$N is no ticket TW published"; rhead   # 0.26.10.29.2 (R12)
    # GM-4 K1 (E6, GM M8): in GitHub manual a ticket the team closed on GitHub, not withdrawn, is withdrawn on the owner's words
    # alone: today's closed-outside line with the words, nothing posted and no tw-outside, so the writer owes its rows a new ticket
    if manual; then ! grep -q "^withdrawn $N " .vid/tw/log || gref "#$N is withdrawn already"
      _cs=$(ghc issue view "$N" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))') || gref "#$N could not be read — nothing posted"
      if [ "$(printf '%s\n' "$_cs" | cut -f1)" = CLOSED ]; then twlog "withdrawn $N decision=closed-outside at=$(now) words=\"$WQ\""; echo "ViD github: withdrew ticket #$N (closed on GitHub: nothing posted)"; exit 0; fi; fi
    { sh "$HERE/writer.sh" gate && sh "$HERE/writer.sh" due; } > "$W/ck" 2>&1 || { sed 's/^/    /' "$W/ck" >&2; gref "the gate is shut, or writer.sh due failed — #$N not withdrawn"; }
    PC=$(grep -E "^withdraw $N( |$)" "$W/ck") && [ "$(ghc issue view "$N" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))' | cut -f1)" = OPEN ] || gref "the round owes no withdrawal of #$N, or it is not open: a merged or closed ticket is never changed"; D=$(kv "$PC" decision); LR=$(kv "$PC" limits); KS=$(kv "$PC" kept)
    # 0.26.10.29.2 (R11): its pull requests read fresh and whole first; a known-limit fix ticket a pull request names merges as it is, never withdrawn
    oprs "$N" > "$W/opn"; [ -z "$LR" ] || [ ! -s "$W/opn" ] || gref "a pull request names #$N ($(paste -sd , "$W/opn")): a fix ticket whose rows are all known limits is told (tw-tell) and merges as it is — #$N not withdrawn"
    if [ -n "$WS" ] && [ -z "$LR" ]; then D=''; [ -n "$WC" ] || WC="the owner's withdrawal"; printf 'vid: withdrawn. Cause: %s. This ticket is not to be merged; its tests are planned again.\n' "$(printf '%s' "$WC" | tr '\t\n' '  ')" > "$W/wd"   # GM-2 T6
    elif [ -n "$LR" ]; then D=known-limit; printf 'vid: withdrawn. Its rows %s were ruled known limits or taken out of the plan, so nothing in it is left to build. This ticket is not to be merged.\n' "$(printf '%s' "$LR" | sed 's/,/, /g')" > "$W/wd"
    elif [ -n "$D" ]; then printf 'vid: withdrawn by plan change %s, what %s. This ticket is not to be merged; its rows are planned again.\n' "$D" "$(kv "$PC" what)" > "$W/wd"
    # 0.26.10.29.2 (R11): no plan change behind it (a landing or a ruling took its rows): named as an amendment names its cause
    else { printf 'vid: withdrawn. This ticket is not to be merged; its rows are planned again.\n\n'; sh "$HERE/writer.sh" cause "$N" 2>/dev/null; } > "$W/wd"; fi
    if [ -z "$LR" ]; then
      # 0.26.10.29.2 (R3, R11): its cause, the change's why, and where each row went, on the issue and on each open pull request naming it
      WY=''; [ -z "$D" ] || [ -n "$WS" ] || WY=$(grep "^plan-change .* decision=$D " .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/.* why="\(.*\)" at=[^ ]*$/\1/p')
      { [ -z "$WY" ] || printf '\nWhy: %s\n' "$WY"
        # 0.26.10.29.2 (R11): a big change, its step kept: more than half of its rows gone or replaced
        [ -z "$KS" ] || printf '\nMore than half of the rows it held are gone or replaced, so it is withdrawn rather than amended; the rows step %s keeps go out in a new ticket that names this one.\n' "$KS"
        printf '\nWhere its rows went:\n\n'; sh "$HERE/writer.sh" where "$N"; } >> "$W/wd" 2> "$W/we" || { sed 's/^/    /' "$W/we" >&2; gref "where the rows of #$N went could not be read — #$N not withdrawn"; }; fi
    tell "$N" "$W/wd" && ghc issue close "$N" -R "$REPO" --reason 'not planned' > /dev/null || gref "#$N could not be withdrawn"
    twlog "withdrawn $N decision=${D:-none}${LR:+ rows=$LR}${KS:+ kept=$KS} at=$(now)${WS:+ words=\"$WQ\"}"
    # 0.26.10.29.2 (R3): its rows handed over, so the ticket that next carries any of them names it (writer.sh's `- earlier work:`)
    HR=$(awk -v n="$N" '($1 == "published" || $1 == "amended") && $2 == n { l = $0 } END { print l }' .vid/tw/log | tr ' ' '\n' | sed -n 's/^rows=//p'); [ -n "$LR" ] || hov "$N" "$HR" || twlog "handover $N pr=${OP:--} rows=$HR at=$(now)"
    echo "ViD github: withdrew ticket #$N"; exit 0 ;;
  tw-team-no)   # GM-2 T7: the no to a team change, one comment on the ticket: the test stays as the ticket had it (GM-4 F6: in either mode)
    tw; N=${1:-}; ID=${2:-}; KD=${3:-}; [ $# -eq 3 ] || usage; case "$N" in ''|*[!0-9]*) usage ;; esac
    case "$KD" in added|dropped) ;; *) usage ;; esac; case "$ID" in ''|*[!A-Za-z0-9_-]*) usage ;; esac
    grep -q "^published $N " .vid/tw/log 2>/dev/null && ! grep -q "^withdrawn $N " .vid/tw/log || gref "#$N is no open ticket TW published"; rhead
    if [ "$KD" = added ]; then printf 'vid: %s is not taken into this ticket: it stays out of its tests, as the ticket had it. Build and test the tests the ticket names.\n' "$ID" > "$W/no"
    else printf 'vid: %s stays in this ticket: it is still one of its tests, as the ticket had it. Build and test it.\n' "$ID" > "$W/no"; fi
    ghc issue comment "$N" -R "$REPO" --body-file "$W/no" > /dev/null || gref "the comment on #$N could not be posted"
    twlog "team-no $N $ID $KD at=$(now)"; echo "ViD github: told #$N that $ID stays as the ticket had it"; exit 0 ;;
  tw-tell)   # 0.26.10.29.2 (R11): a fix ticket whose every row is a known limit while a pull request names it, owed `tell <n> limits=<rows>`: not
    # withdrawn, as it merges as it is (0.26.10.28.6 R2), but told, on the issue and each open pull request, its rows named as known limits; `told <n> limits=`
    tw; N=${1:-}; case "$N" in ''|*[!0-9]*) usage ;; esac; grep -q "^published $N " .vid/tw/log 2>/dev/null || gref "#$N is no ticket TW published"; rhead   # 0.26.10.29.2 (R12)
    { sh "$HERE/writer.sh" gate && sh "$HERE/writer.sh" due; } > "$W/ck" 2>&1 || { sed 's/^/    /' "$W/ck" >&2; gref "the gate is shut, or writer.sh due failed — #$N not told"; }
    PC=$(grep -E "^tell $N " "$W/ck") || gref "the round owes #$N no telling"; LR=$(kv "$PC" limits)
    { printf 'vid: amended. Its rows %s were ruled known limits, so nothing in it is left to build; it is not withdrawn, as a pull request names it: it merges as it is.\n\n' "$(printf '%s' "$LR" | sed 's/,/, /g')"
      sh "$HERE/writer.sh" where "$N"; } > "$W/tl" 2> "$W/we" || { sed 's/^/    /' "$W/we" >&2; gref "the rows of #$N could not be read — #$N not told"; }
    tell "$N" "$W/tl" || gref "#$N could not be told"; twlog "told $N limits=$LR at=$(now)"; echo "ViD github: told ticket #$N"; exit 0 ;;
  tw-handovers)   # 0.26.10.29.2 (R3): the handovers of everything writer.sh due owes now (a withdrawal's rows; the rows an amendment
    # takes out of a ticket a pull request names), logged before any ticket is written, so a ticket receiving rows names the ticket they
    # left whatever order the tickets are written in; each once (hov): tw-close and tw-post --amend log none a second time
    tw; rhead; sh "$HERE/writer.sh" handovers > "$W/hw" 2> "$W/he" || { sed 's/^/    /' "$W/he" >&2; gref 'writer.sh handovers failed — no handover logged'; }   # no gate: it posts nothing, and a shut gate refuses each line in its turn
    while IFS="$(printf '\t')" read -r n k rows; do [ -n "$rows" ] || continue; ! hov "$n" "$rows" || continue; rm -f "$W/opn"; oprs "$n" > "$W/opn"; [ "$k" = w ] || [ -s "$W/opn" ] || continue
      P=$(paste -sd , "$W/opn"); twlog "handover $n pr=${P:--} rows=$rows at=$(now)"; done < "$W/hw"; rm -f "$W/opn"; echo 'ViD github: handovers logged'; exit 0 ;;
  tw-reopen)   # GM-4 K1 (E6): tw-reopen [--words "<w>"] <n>, a published ticket closed on GitHub and not withdrawn, reopened at the owner's word:
    # the issue reopened, then one comment, `vid: reopened at the owner's word`; logged `reopened <n> at=` and, given, ` words=`. Refused, nothing posted,
    # in GitHub manual without the words (GM M16; optional in GitHub auto, K1), for a ticket ViD did not publish or withdrew, and for one not closed.
    # FB-2 A3: an open ticket its dev side left (its newest `DM: left: ` comment with no reopen after it) takes the same one comment, no
    # issue reopen call, logged `reopened <n> at=… open=left`; any other open ticket is still refused
    tw; WO=''; WS=''; while [ $# -gt 1 ]; do case $1 in --words) WO=$2; WS=1 ;; *) break ;; esac; shift 2; done
    [ -n "$(printf '%s' "$WO" | tr -d '[:space:]')" ] || WS=''
    ! manual || [ -n "$WS" ] || gref "in GitHub manual a ticket is reopened only on the owner's words (tw-reopen --words \"<their words>\" <n>) — nothing posted"
    WQ=$(printf '%s' "$WO" | tr '\t\n\r' '   ' | tr '"' "'"); N=${1:-}; [ $# -eq 1 ] || usage; case "$N" in ''|*[!0-9]*) usage ;; esac
    grep -q "^published $N " .vid/tw/log 2>/dev/null && ! grep -q "^withdrawn $N " .vid/tw/log || gref "#$N is no ticket ViD published and has not withdrawn — nothing posted"; rhead
    _cs=$(ghc issue view "$N" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))') || gref "#$N could not be read — nothing posted"
    OL=''; if [ "$(printf '%s\n' "$_cs" | cut -f1)" != CLOSED ]; then
      _lc=$(ghc issue view "$N" -R "$REPO" --json comments --jq '.comments[] | .url + "\t" + (.body | split("\n") | .[0])') || gref "#$N could not be read — nothing posted"
      printf '%s\n' "$_lc" | cut -f2- | awk '/^DM: left: / { l = 1 } $0 == "vid: reopened at the owner'"'"'s word" { l = 0 } END { exit !l }' || gref "#$N is not closed on GitHub, nor left by its dev side: there is nothing to reopen — nothing posted"; OL=1; fi
    printf "vid: reopened at the owner's word\n" > "$W/ro"
    [ -n "$OL" ] || ghc issue reopen "$N" -R "$REPO" > /dev/null || gref "#$N could not be reopened"
    ghc issue comment "$N" -R "$REPO" --body-file "$W/ro" > /dev/null || gref "#$N is reopened, but its comment could not be posted"
    twlog "reopened $N at=$(now)${OL:+ open=left}${WS:+ words=\"$WQ\"}"; echo "ViD github: reopened ticket #$N"; exit 0 ;;
  tw-act)   # GM-4 K1: tw-act amend <n> [--cause "<line>"] [--words "<w>"] | withdraw <n> [--words "<w>"] [--cause "<line>"] | tell <n> |
    # new <writer.sh write's arguments: skeleton | step <S> | fix <key> | reached> [--words "<w>"]: the steps of one ticket act, the
    # one copy tw-hand's actions and the round's owed lines (round.sh due_) run: the write (writer.sh write), a fix or reached ticket's
    # publish warnings (plan.sh warnings of its step, GM-2 T4), and the post (tw-post, tw-close or tw-tell). No lock, export, sync,
    # read, handovers or save of its own: tw-hand and round.sh next make them around it. Exit 0 posted, the post's lines; 1 the post
    # refused or failed; 4 the write refused, nothing posted, the writer's lines on stderr
    tw; AK=${1:-}; [ $# -ge 2 ] || usage; shift; AW=''; AWS=''; AC=''; ACS=''; AS=''
    while [ $# -gt 0 ]; do case $1 in --words) [ $# -ge 2 ] || usage; AW=$2; AWS=1; shift 2 ;; --cause) [ $# -ge 2 ] || usage; AC=$2; ACS=1; shift 2 ;; *) AS="$AS
$1"; shift ;; esac; done
    set -- $AS; aw() { [ -z "$AWS" ] || printf -- '--words\n%s\n' "$AW"; }; ac() { [ -z "$ACS" ] || printf -- '--cause\n%s\n' "$AC"; }
    case $AK in
      amend) [ $# -eq 1 ] || usage; F=$(sh "$HERE/writer.sh" write amend "$1" $(ac) 2> "$W/ae") || { cat "$W/ae" >&2; exit 4; }; F=$(printf '%s\n' "$F" | tail -n 1)
        sh "$0" tw-post --amend "$1" $(aw) "$F"; exit $? ;;
      withdraw) [ $# -eq 1 ] || usage; sh "$0" tw-close $(aw) $(ac) "$1"; exit $? ;;
      tell) [ $# -eq 1 ] && [ -z "$AWS$ACS" ] || usage; sh "$0" tw-tell "$1"; exit $? ;;
      new) [ $# -ge 1 ] && [ -z "$ACS" ] || usage; F=$(sh "$HERE/writer.sh" write "$@" 2> "$W/ae") || { cat "$W/ae" >&2; exit 4; }; F=$(printf '%s\n' "$F" | tail -n 1)
        case $1 in fix|reached) _fs=$(sed -n 's/^- step: //p' "$F" | head -n 1); [ -z "$_fs" ] || sh "$HERE/plan.sh" warnings "$_fs" 2> /dev/null | grep '^warning' || true ;; esac   # GM-2 T4: a publish's warnings
        sh "$0" tw-post $(aw) "$F"; exit $? ;;
      *) usage ;; esac ;;
  tw-publish)   # GM-4 K1 (J1): tw-publish <step> [--words "<w>"] [--title "<t>"], the steps of a step going out, in order: the admission
    # (plan.sh start), the publish's warnings (plan.sh warnings, its `warning …` lines printed), the write (writer.sh write skeleton for
    # the plan's skeleton step, kind: skeleton, else write step <step>), its check, and the post (tw-post). No lock, export or save of
    # its own: tw-hand publish and round.sh next make them around it. In GitHub manual the words are required (GM M16), checked before
    # the admission. Exit 0 posted; 1 refused, nothing posted; 3 held, the admission's lines printed, nothing recorded; 4 admitted,
    # the write refused, nothing posted
    tw; S=${1:-}; case "$S" in ''|-*|*[!A-Za-z0-9._-]*) usage ;; esac; shift; PW=''; PWS=''; PT=''
    while [ $# -gt 0 ]; do case $1 in --words) [ $# -ge 2 ] || usage; PW=$2; PWS=1; shift 2 ;; --title) [ $# -ge 2 ] || usage; PT=$2; shift 2 ;; *) usage ;; esac; done
    ! manual || { [ -n "$PWS" ] && [ -n "$(printf '%s' "$PW" | tr -d '[:space:]')" ]; } || gref "in GitHub manual a ticket goes out only on the owner's words (tw-publish $S --words \"<their words>\") — nothing posted"
    sh "$HERE/plan.sh" start "$S" > "$W/ad" 2>&1 || { cat "$W/ad"; echo "ViD github: held — step $S was not admitted (the admission's lines above); nothing posted" >&2; exit 3; }
    sh "$HERE/plan.sh" warnings "$S" 2> /dev/null | grep '^warning' || true   # J2's lines, as the listing shows them
    SK=$(plan_block | awk -F'|' '/^[ \t]*step[ \t]/ { for (i = 2; i <= NF; i++) { x = $i; gsub(/^[ \t]+|[ \t]+$/, "", x); if (x == "kind: skeleton") { s = $1; sub(/^[ \t]*step[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); print s; exit } } }')
    if [ "$S" = "$SK" ]; then set -- skeleton; else set -- step "$S"; fi
    F=$(sh "$HERE/writer.sh" write "$@" 2> "$W/we") || { sed 's/^/    /' "$W/we" >&2; echo "ViD github: refused — the ticket of $S could not be written; $S is admitted, nothing posted" >&2; exit 4; }
    F=$(printf '%s\n' "$F" | tail -n 1); set --; [ -z "$PWS" ] || set -- --words "$PW"; [ -z "$PT" ] || set -- "$@" --title "$PT"
    sh "$0" tw-post "$@" "$F"; exit $? ;;
  tw-hand)   # 0.26.10.29.2 (R12): the ticket writer called outside /vid run — tw-hand write <writer.sh write's arguments> | close <n> | tell <n> —
    # does what the run does at its start, in order: the run's lock taken (refused, naming the holder, while another live session holds
    # it), or borrowed when this session holds it (renewed, the restore skipped, left held); the folder brought to the saved records (a
    # restore, or a refusal naming the records not yet saved while they are behind, this call's own lock-taken event apart); the export
    # and the sync; the ticket written and posted, withdrawn or told; the records saved; the lock freed only when this call took it.
    # 0.26.10.29.2 (R12): a borrowed lock needs the folder at the saved head; a take that found this session's own lock keeps it;
    # the round's read is taken afresh; the records are saved only when the act wrote to the log, and only at the saved head
    # GM-4 K1 (J1): the one path of every ticket that goes out — tw-hand publish <step> [--words "<w>"] [--title "<t>"] (tw-publish) |
    # amend <n> [--words "<w>"] [--cause "<line>"] | withdraw <n> [--words "<w>"] [--cause "<line>"] | reopen <n> [--words "<w>"] (tw-reopen)
    # | fix <key> [--words "<w>"] | reached [--words "<w>"], beside write, close and tell; a number may be written #<n>. In GitHub manual
    # the words are required for each (GM M16; optional in GitHub auto, a reopening's too, K1), checked before the lock is taken: refused, nothing posted, without them. Exit 0 posted;
    # 1 refused; 3 held (the admission's hold, its lines printed). A fix or reached ticket prints its step's publish warnings (GM-2 T4)
    tw; K=${1:-}; SJ=''; HW=''; HWS=''; HC=''; HT=''
    case "$K" in write) [ $# -ge 2 ] || usage ;; close|tell) case "${2:-}" in ''|*[!0-9]*) usage ;; esac ;;
      publish|amend|withdraw|reopen|fix|reached)
        if [ "$K" != reached ]; then SJ=${2:-}; SJ=${SJ#\#}; case "$K" in publish|fix) case "$SJ" in ''|-*|*[!A-Za-z0-9._-]*) usage ;; esac ;; *) case "$SJ" in ''|*[!0-9]*) usage ;; esac ;; esac; shift 2; else shift; fi
        while [ $# -gt 0 ]; do [ $# -ge 2 ] || usage; case $1 in --words) HW=$(printf '%s' "$2" | tr '\n\r' '  '); HWS=1 ;; --cause) case $K in amend|withdraw) HC=$(printf '%s' "$2" | tr '\n\r' '  ') ;; *) usage ;; esac ;;
            --title) [ "$K" = publish ] || usage; HT=$(printf '%s' "$2" | tr '\n\r' '  ') ;; *) usage ;; esac; shift 2; done
        [ -n "$(printf '%s' "$HW" | tr -d '[:space:]')" ] || HWS=''
        if [ -z "$HWS" ] && manual; then gref "in GitHub manual a ticket goes out, changes or reopens only on the owner's words (tw-hand $K${SJ:+ $SJ} --words \"<their words>\") — nothing posted"; fi
        set -- "$K" "$SJ" ;;
      *) usage ;; esac
    hw() { [ -z "$HWS" ] || printf -- '--words\n%s\n' "$HW"; }; hc() { [ -z "$HC" ] || printf -- '--cause\n%s\n' "$HC"; }
    stloc; SU=$(ghc repo view "$ST" --json url --jq .url) || gref "no access to $ST"
    LL=$(git ls-remote "$SU" refs/heads/vid-state/lock 2>/dev/null) || gref 'the lock could not be read'; LO=$(printf '%s' "$LL" | cut -f1); LS=''
    if [ -n "$LO" ]; then git init -q "$W/hl"; git -C "$W/hl" fetch -q "$SU" refs/heads/vid-state/lock && LS=$(git -C "$W/hl" show FETCH_HEAD:lock | sed -n 's/^session: //p') || gref 'the lock could not be read'; fi
    HM=${CLAUDE_CODE_SESSION_ID:-$(cat .vid/lock-session 2>/dev/null)}; FR=''; HS=''
    hfail() { [ -z "$FR" ] || sh "$0" lock-free > /dev/null 2>&1 || echo "ViD github: the lock this call took could not be freed" >&2; gref "$1"; }
    BR=''; if [ -n "$LO" ] && [ -n "$HM" ] && [ "$LS" = "$HM" ]; then sh "$0" lock-renew > "$W/hk" 2>&1 || { sed 's/^/    /' "$W/hk" >&2; gref "the run's lock could not be renewed — nothing written"; }; BR=1
    else HS=${CLAUDE_CODE_SESSION_ID:-hand-$$-$(date +%s)}; sh "$0" lock-take "$HS" > "$W/hk" 2>&1 || { sed 's/^/    /' "$W/hk" >&2; gref "the run's lock is another live session's — nothing written"; }
      # freed at the end only when this take found no holder, or a cold one: a lock this session already held (taken since the read) stays
      FM=$(grep "^lock-taken session=$HS " .vid/metrics-events 2>/dev/null | tail -n 1 | sed -n 's/.* from=\([^ ]*\).*/\1/p'); if [ "$FM" = "$HS" ]; then BR=1; else FR=1; fi; fi
    SA=$(cat .vid/state-at 2>/dev/null || true); T0=$(rhd) || hfail 'the saved records could not be read — nothing written'
    # 0.26.10.29.2 (R12): a borrowed lock skips the restore, so its folder must be at the saved head already
    [ -z "$BR" ] || [ "$T0" = "$SA" ] || [ -z "$T0$SA" ] || hfail "this folder's records are not the saved records' head (${T0:-none}) while this session holds the run's lock: nothing is restored under a run — nothing written"
    if [ -z "$BR" ]; then
      if [ -n "$T0" ] && [ "$T0" != "$SA" ]; then
        # the records here against the last save this folder knows (its state-at, else the saved head): any that differ would be lost
        git init -q "$W/hr" && git -C "$W/hr" fetch -q "$SU" refs/heads/vid-state/records || hfail 'the saved records could not be read — nothing written'
        B0=$T0; [ -z "$SA" ] || ! git -C "$W/hr" cat-file -e "$SA^{commit}" 2>/dev/null || B0=$SA; mkdir -p "$W/hb" "$W/hc/results"
        git -C "$W/hr" archive "$B0" | tar -x -C "$W/hb" || hfail 'the saved records could not be read — nothing written'; rm -f "$W/hb/home.head" "$W/hb/home.bundle"
        for f in RUN-STATE.md budget metrics-events decide tw plans plan next VID-FINDINGS.md; do [ ! -e ".vid/$f" ] || cp -R ".vid/$f" "$W/hc/$f"; done; rm -rf "$W/hc"/decide/tmp.*; cp .vid/results/*.txt "$W/hc/results/" 2>/dev/null || true
        [ ! -f "$W/hc/metrics-events" ] || { awk -v s="lock-taken session=$HS " 'index($0, s) == 1 { k = NR } { a[NR] = $0 } END { for (i = 1; i <= NR; i++) if (i != k) print a[i] }' "$W/hc/metrics-events" > "$W/hm" && cat "$W/hm" > "$W/hc/metrics-events"; }
        find "$W/hb" "$W/hc" -mindepth 1 -depth -type d -empty -exec rmdir {} \; 2>/dev/null || true   # git keeps no empty folder
        diff -rq "$W/hb" "$W/hc" 2>/dev/null | awk -v B="$W/hb" -v C="$W/hc" '{ if ($1 == "Files") p = $2; else { p = substr($0, 9); i = index(p, ": "); p = substr(p, 1, i - 1) "/" substr(p, i + 2) }
          if (index(p, B) == 1) p = substr(p, length(B) + 1); else if (index(p, C) == 1) p = substr(p, length(C) + 1); sub(/^\/+/, "", p); print ".vid/" p }' > "$W/hd"
        [ ! -s "$W/hd" ] || hfail "this folder holds records not yet saved while the saved ones are newer: $(paste -sd ' ' "$W/hd"). A save from here would replace the newer ones, and a restore drops these: keep what you need of them elsewhere, then restore (sh checks/github.sh state-restore) — nothing written"
        sh "$0" state-restore > "$W/hs" 2>&1 || { sed 's/^/    /' "$W/hs" >&2; hfail 'the saved records could not be restored — nothing written'; }; fi; fi
    # the export, the sync and (0.26.10.29.2) the round's read of the pull requests, fresh, so the writer owes what GitHub holds now
    # GM-4 F3: the read through round.sh read, the one entry that writes .vid/round/read
    { sh "$0" spec-export && sh "$0" tw-sync && sh "$HERE/round.sh" read; } > "$W/hx" 2>&1 || { sed 's/^/    /' "$W/hx" >&2; hfail 'the export, the sync or the read failed — nothing written'; }
    # GM-4 K13, S0: tw-hand publishes no folder (a direct call sends what it was asked for alone). In GitHub manual with one repository
    # a ticket quotes the folder, so an act that writes one (publish, amend, fix, reached, write) is refused, nothing posted, while the
    # code repository has a main and no spec-published line names the export, its folder and its stamp; withdraw, close, tell and
    # reopen quote none. GitHub auto's tickets quote the spec repository
    case $K in publish|amend|fix|reached|write) if manual && [ "$(twkey layout)" = one ]; then
      _xm=$(awk '$1 == "sync" { for (i = 2; i <= NF; i++) if (index($i, "main=") == 1) m = substr($i, 6) } END { print m }' .vid/tw/log 2>/dev/null)
      _xe=$(awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' .vid/tw/log 2>/dev/null)
      case $_xm in ''|none|absent) ;; *) spdone "$_xe" || hfail "the spec at the export ${_xe:-none} is not in the code repository's folder $SP yet, and the ticket would quote it there: publish it first with /vid:vid-spec-publish — nothing posted" ;; esac; fi ;; esac
    NL=$(grep -c . .vid/tw/log 2>/dev/null || true)
    sh "$0" tw-handovers > "$W/hx" 2>&1 || { sed 's/^/    /' "$W/hx" >&2; hfail 'the handovers could not be logged — nothing written'; }   # 0.26.10.29.2 (R3): before any ticket is written
    # GM-4 K1: every act but publish and reopen is tw-act's steps, the round's own; a write it refuses (4) posts nothing
    rc=0; case $K in
      write) shift; if [ "$1" = amend ]; then _n=$2; shift 2; sh "$0" tw-act amend "$_n" "$@" > "$W/ho" 2>&1 || rc=$?; else sh "$0" tw-act new "$@" > "$W/ho" 2>&1 || rc=$?; fi ;;
      close) sh "$0" tw-act withdraw "$2" > "$W/ho" 2>&1 || rc=$? ;;
      tell) sh "$0" tw-act tell "$2" > "$W/ho" 2>&1 || rc=$? ;;
      publish) if [ -n "$HT" ]; then sh "$0" tw-publish "$SJ" $(hw) --title "$HT" > "$W/ho" 2>&1 || rc=$?; else sh "$0" tw-publish "$SJ" $(hw) > "$W/ho" 2>&1 || rc=$?; fi ;;
      amend) sh "$0" tw-act amend "$SJ" $(hc) $(hw) > "$W/ho" 2>&1 || rc=$? ;;
      withdraw) sh "$0" tw-act withdraw "$SJ" $(hw) $(hc) > "$W/ho" 2>&1 || rc=$? ;;
      reopen) sh "$0" tw-reopen $(hw) "$SJ" > "$W/ho" 2>&1 || rc=$? ;;
      fix) sh "$0" tw-act new fix "$SJ" $(hw) > "$W/ho" 2>&1 || rc=$? ;;
      reached) sh "$0" tw-act new reached $(hw) > "$W/ho" 2>&1 || rc=$? ;;
    esac
    [ "$K" = publish ] || [ "$rc" != 4 ] || { sed 's/^/    /' "$W/ho" >&2; hfail 'the ticket could not be written — nothing posted'; }
    # GM-4 K1: a publish the admission held records nothing: its lines printed, the lock this call took freed, exit 3. One admitted whose
    # write was refused (tw-publish's 4) posted nothing, but its admission is recorded: saved below, then refused
    if [ "$rc" = 3 ]; then cat "$W/ho"; [ -z "$FR" ] || sh "$0" lock-free > /dev/null 2>&1 || echo "ViD github: the lock this call took could not be freed" >&2; exit 3; fi
    AD=''; [ "$rc" != 4 ] || AD=1
    # 0.26.10.29.2 (R12): saved only when the act wrote to the log, and only from a folder at the saved head. An act that
    # failed with nothing in the log may still have changed the issue, and the message says so; the save itself refuses when the head it
    # rereads is not the one checked here (VID_SAVE_AT), so the check and the save are one step
    if [ "$rc" != 0 ] && [ -z "$AD" ] && [ "$(grep -c . .vid/tw/log 2>/dev/null || true)" = "$NL" ]; then sed 's/^/    /' "$W/ho" >&2; hfail 'nothing was recorded and nothing saved; if the act failed part way (the lines above say where), the issue may already be changed on GitHub'; fi
    T1=$(rhd) || hfail 'posted, but the saved records could not be read, so nothing is saved: sh checks/github.sh state-save once they can be'
    [ "$T1" = "$(cat .vid/state-at 2>/dev/null)" ] || [ -z "$T1$(cat .vid/state-at 2>/dev/null)" ] || hfail "posted, but the saved records moved meanwhile (${T1:-none}): nothing saved over them"
    VID_SAVE_AT=${T1:-none} sh "$0" state-save > "$W/hv" 2>&1 || { cat "$W/ho"; sed 's/^/    /' "$W/hv" >&2
      if grep -q 'nothing saved over them' "$W/hv"; then hfail 'posted, but another folder saved meanwhile: nothing is saved over its records, and the post is in this folder alone'; fi
      hfail 'the records could not be saved: run sh checks/github.sh state-save before anything else'; }
    [ -z "$AD" ] || { sed 's/^/    /' "$W/ho" >&2; hfail "step $SJ is admitted and saved, but its ticket could not be written (the lines above) — nothing posted"; }
    [ "$rc" = 0 ] || { sed 's/^/    /' "$W/ho" >&2; hfail 'the act failed part way (the lines above say where); what it recorded is saved'; }; cat "$W/ho"
    if [ -n "$FR" ]; then sh "$0" lock-free > /dev/null 2>&1 || gref 'posted and saved, but the lock this call took could not be freed'; echo 'ViD github: the records saved; the lock freed'
    else echo "ViD github: the records saved; the run's lock kept"; fi; exit 0 ;;

  state-setup)   # GM-1 S2 (M15): ViD's own private state repository, state-repo:, made private when missing, or checked private; never repo: or spec-repo: (FB-3 B2: xlocal, the old spec repository may be it)
    tw; STATE=$(twkey state-repo); [ -n "$STATE" ] || gref ".vid/tw/settings names no state-repo: <owner>/<name>"
    case "$STATE" in */*/*|/*|*/|*[!A-Za-z0-9._/-]*) gref "state-repo: '$STATE' is not <owner>/<name>" ;; */*) ;; *) gref "state-repo: '$STATE' is not <owner>/<name>" ;; esac
    _lc() { printf %s "$1" | tr 'A-Z' 'a-z'; }   # GitHub's names ignore case
    [ "$(_lc "$STATE")" != "$(_lc "$REPO")" ] && { xlocal || [ "$(_lc "$STATE")" != "$(_lc "$SPEC")" ]; } || gref "state-repo: names the code or the spec repository ($STATE): ViD's records go to a repository of their own"
    rc=0; mkrepo state-repo "$STATE" || rc=$?   # FB-2 A1
    [ "$rc" != 2 ] || gref "$STATE exists and is not private: ViD's records go only to a private repository; make it private, or name another"
    [ "$rc" = 0 ] || gref "the state repository $STATE could not be made"
    if [ "$MKD" = created ]; then echo "ViD github: the state repository $STATE made, private"; else echo "ViD github: the state repository $STATE exists (private)"; fi; exit 0 ;;

  code-setup)   # FB-2 A1: repo:, the code repository, made private and empty when missing, or used as it is
    tw; case "$REPO" in */*/*|/*|*/|*[!A-Za-z0-9._/-]*) gref "repo: '$REPO' is not <owner>/<name>" ;; */*) ;; *) gref "repo: '$REPO' is not <owner>/<name>" ;; esac
    mkrepo repo "$REPO" || gref "the code repository $REPO could not be made"
    if [ "$MKD" = created ]; then echo "ViD github: the code repository $REPO made, private and empty"; else echo "ViD github: the code repository $REPO exists"; fi; exit 0 ;;

  ticket-writing)   # GM-1 S2: ticket-writing <n> <file>, read only: issue n's newest writing, the parts of its newest `writing <hash>` not
    # marked replaced, in their order (part 1 in the body when the body opens with its line, else in a comment), joined into <file>
    # without their two header lines and their trailing blank lines; a section line (`## `) a part opens is given the one blank line
    # before it that a part's end loses.
    # Prints `writing <n> <hash> <body|comments> <parts>`, or `incomplete <n> <why>` and writes nothing
    tw; N=${1:-}; O=${2:-}; case "$N" in ''|*[!0-9]*) usage ;; esac; [ -n "$O" ] || usage
    ghc issue view "$N" -R "$REPO" --json body --jq .body > "$W/b0" || gref "#$N could not be read"; tr -d '\r' < "$W/b0" > "$W/b"
    ghc issue view "$N" -R "$REPO" --json comments --jq '.comments[] | .url + "\t" + (.body | split("\n") | .[0])' > "$W/c0" || gref "the comments of #$N could not be read"; tr -d '\r' < "$W/c0" > "$W/ch"
    PH='function ph(t, n,   x, k, m, h) { if (t !~ ("^Ticket #" n ", part [0-9]+ of [0-9]+, writing [0-9a-f]+[.]$")) return ""; x = t; sub(/^Ticket #[0-9]+, part /, "", x); k = x; sub(/ .*/, "", k)
      sub(/^[0-9]+ of /, "", x); m = x; sub(/,.*/, "", m); h = x; sub(/.*writing /, "", h); sub(/[.]$/, "", h); return k " " m " " h }'
    { head -n 1 "$W/b" | awk -v n="$N" "$PH"' { p = ph($0, n); if (p != "") print "b " p }'; awk -F'\t' -v n="$N" "$PH"' { p = ph($2, n); if (p != "") print NR - 1 " " p }' "$W/ch"; } > "$W/pl"
    HW=$(awk '$1 != "b" { h = $4 } END { print h }' "$W/pl"); [ -n "$HW" ] || HW=$(awk '$1 == "b" { print $4 }' "$W/pl")
    [ -n "$HW" ] || { echo "incomplete $N no part of a writing in its body or comments"; exit 0; }
    M=$(awk -v h="$HW" '$4 == h { m = $3 } END { print m }' "$W/pl"); SRC=comments; : > "$W/j"; : > "$W/jr"; : > "$W/jo"; k=1
    while [ "$k" -le "$M" ]; do
      w=$(awk -v h="$HW" -v k="$k" '$4 == h && $2 == k { w = $1 } END { print w }' "$W/pl"); [ -n "$w" ] || { echo "incomplete $N part $k of $M of writing $HW is missing"; exit 0; }
      if [ "$w" = b ]; then cp "$W/b" "$W/pt"; SRC=body; else ghc issue view "$N" -R "$REPO" --json comments --jq ".comments[$w].body" > "$W/p0" || gref "a comment of #$N could not be read"; tr -d '\r' < "$W/p0" > "$W/pt"; fi
      awk 'NR > 2 { L[++n] = $0 } END { while (n > 0 && L[n] == "") n--; for (i = 1; i <= n; i++) print L[i] }' "$W/pt" > "$W/pb"   # its trailing blank lines dropped, as GitHub may trim them
      { [ "$k" = 1 ] || ! head -n 1 "$W/pb" | grep -q '^## ' || [ -z "$(tail -n 1 "$W/j")" ] || echo; cat "$W/pb"; } >> "$W/j"
      awk 'NR > 2' "$W/pt" >> "$W/jr"; awk 'NR > 2 { L[++n] = $0 } END { if (n > 0 && L[n] == "") n--; for (i = 1; i <= n; i++) print L[i] }' "$W/pt" >> "$W/jo"; k=$((k + 1)); done
    # three joins, each a way GitHub may give a part back (trimmed, kept whole, or kept with --jq's newline); the one that
    # hashes to the writing's own hash is its text; with none (a body the team edited), the trimmed join, as it stands
    for v in j jr jo; do [ "$(git hash-object "$W/$v" | cut -c1-12)" != "$HW" ] || { cp "$W/$v" "$W/j"; break; }; done
    put "$O" < "$W/j" || exit 1; echo "writing $N $HW $SRC $M"; exit 0 ;;

  tickets)   # GM-3 S1: tickets [<folder>], read only: every issue of the code repository labelled <prefix>ticket, open or closed, and
    # (FB-3 C3) each ticket on ViD's record (lib.sh onrec) whatever its labels, in issue order; one on record GitHub has no issue of is
    # `not-found <n> <why>`, kept on record, and any other failed read refuses;
    # one line each: `ticket <n> <open|closed> <step>`, the step from its newest writing's header as ticket-writing joins it, or
    # `not-taken-over <n> <why>` (`no header` for a writing whose header names no step; ticket-writing's words when there is no whole
    # writing). A list as long as its limit (VID_TICKETS_LIMIT, 1000) is read again with the limit doubled, up to a cap
    # (VID_TICKETS_CAP, 10000); one as long as the cap may be cut, and is the one line `cut <cap> <why>`: never a whole list. With <folder>, each issue's ticket-writing line is kept there as <n>.line and its writing as <n>.md, so a caller
    # reads each ticket once
    tw; K=${1:-}; [ -z "$K" ] || [ -d "$K" ] || usage; L=${VID_TICKETS_LIMIT:-1000}; CP=${VID_TICKETS_CAP:-10000}; [ "$L" -le "$CP" ] || L=$CP
    while :; do ghc issue list -R "$REPO" --label "${PFX}ticket" --state all --limit "$L" --json number,state --jq '.[] | [.number, .state] | @tsv' > "$W/tl" || gref "the issues labelled ${PFX}ticket could not be read"
      [ "$(grep -c . "$W/tl")" -ge "$L" ] || break; [ "$L" -lt "$CP" ] || { echo "cut $CP $CP or more issues are labelled ${PFX}ticket, the most read at once: the list may be cut"; exit 0; }
      L=$((L * 2)); [ "$L" -le "$CP" ] || L=$CP; done
    tr -d '\r' < "$W/tl" | awk -F'\t' 'NF { print $1 "\t" tolower($2) }' > "$W/tn"
    for n in $(onrec); do ! grep -q "^$n	" "$W/tn" || continue   # FB-3 C3: on record, its label gone or never there
      if ghc issue view "$n" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))' > "$W/st" 2> "$W/e"; then printf '%s\t%s\n' "$n" "$(cut -f1 "$W/st" | tr -d '\r' | tr 'A-Z' 'a-z')" >> "$W/tn"
      elif grep -qi 'could not resolve to an issue' "$W/e"; then echo "not-found $n on record in .vid/tw/log, and the code repository has no issue of that number (deleted, or moved): kept on record"
      else sed 's/^/    /' "$W/e" >&2; gref "#$n could not be read"; fi; done
    sort -n "$W/tn" -o "$W/tn"
    pni=0; while IFS='	' read -r n s; do case "$n" in ''|*[!0-9]*) gref "the issue list gave '$n', no issue number" ;; esac
      pni=$((pni + 1)); prog now "ticket $pni of $(grep -c . "$W/tn" | tr -d ' ')"   # FB-3 D2
      sh "$0" ticket-writing "$n" "$W/tw.md" > "$W/tw.line" 2> "$W/e" || { sed 's/^/    /' "$W/e" >&2; gref "#$n could not be read"; }
      [ -z "$K" ] || { cp "$W/tw.line" "$K/$n.line"; [ ! -f "$W/tw.md" ] || cp "$W/tw.md" "$K/$n.md"; } || gref "#$n could not be kept in $K"
      if [ "$(cut -d' ' -f1 "$W/tw.line")" != writing ]; then echo "not-taken-over $n $(cut -d' ' -f3- "$W/tw.line")"
      else st=$(awk '/^## / { h = (substr($0, 4) == "Header"); next } h && index($0, "- step: ") == 1 { print substr($0, 9); exit }' "$W/tw.md")
        if [ -n "$st" ]; then echo "ticket $n $s $st"; else echo "not-taken-over $n no header"; fi; fi; rm -f "$W/tw.md"
    done < "$W/tn"; exit 0 ;;

  ticket-decided)   # FB-3 E1: ticket-decided <n>, read only, one view of the issue: `<open|closed>\t<commit>\t<author>\t<date>`, its state and
    # its newest comment whose first line is `vid: decision <commit>` and whose second is `ticket: accepted`, `-` each with none; an issue
    # GitHub does not have is `not-found\t-\t-\t-`, and any other failed read refuses
    tw; N=${1:-}; case "$N" in ''|*[!0-9]*) usage ;; esac
    CDQ='.state, (.comments[] | select(.body | startswith("vid: decision ")) | [(.body | split("\n") | .[0]), (.body | split("\n") | .[1] // ""), (.author.login // "-"), .createdAt] | @tsv)'
    if ghc issue view "$N" -R "$REPO" --json state,comments --jq "$CDQ" > "$W/cd" 2> "$W/e"; then   # a line end's CR is @tsv's two characters
      tr -d '\r' < "$W/cd" | awk -F'\t' -v OFS='\t' 'NR == 1 { s = tolower($1); c = a = d = "-"; next } { sub(/(\\r|[ \t])*$/, "", $1); sub(/(\\r|[ \t])*$/, "", $2) } $2 == "ticket: accepted" && $1 ~ /^vid: decision [0-9a-f]+$/ && length($1) >= 21 { c = substr($1, 15); a = $3; d = $4 } END { print s, c, a, d }'
    elif grep -qi 'could not resolve to an issue' "$W/e"; then printf 'not-found\t-\t-\t-\n'
    else sed 's/^/    /' "$W/e" >&2; gref "#$N could not be read"; fi; exit 0 ;;

  spec-fetch)   # GM-3 S1: read only, the spec repository's main fetched into ViD's copy, .vid/spec.git; nothing pushed
    # its main read on its own first, a failed read refused with git's words (an absent main is a read that succeeded)
    tw; if xlocal; then XFETCH=yes; specgit; echo "ViD github: ViD's exports, kept in the project, read into .vid/spec.git, the newest ${SM:-none}"; exit 0; fi   # FB-3 B2: no network, but the one move of pushed exports (specloc)
    [ -z "$SPEC" ] || { U=$(ghc repo view "$SPEC" --json url --jq .url 2>/dev/null) && [ -n "$U" ] || gref "no access to the spec repository $SPEC: gh repo view $SPEC failed"
      git ls-remote "$U" refs/heads/main > /dev/null 2> "$W/sle" || { sed 's/^/    /' "$W/sle" >&2; gref "the spec repository $SPEC could not be read (git ls-remote, the lines above)"; }; }
    specgit; echo "ViD github: the spec repository $SPEC read into .vid/spec.git, its main ${SM:-none}"; exit 0 ;;

  spec-setup)   # v0.26.10.12.3 (R2, main 436–448): the private spec repository, made once, then an export
    tw
    ! xlocal || gref "with layout: one in GitHub manual ViD's export is kept in the project (FB-3 B2): there is no spec repository to make"
    [ -n "$SPEC" ] || gref ".vid/tw/settings names no spec-repo: <owner>/<name>"
    case "$SPEC" in */*/*|/*|*/|*[!A-Za-z0-9._/-]*) gref "spec-repo: '$SPEC' is not <owner>/<name>" ;; */*) ;; *) gref "spec-repo: '$SPEC' is not <owner>/<name>" ;; esac
    [ "$SPEC" != "$REPO" ] || gref "spec-repo: names the code repository $REPO — the spec repository is another, <project>-spec"
    rc=0; mkrepo spec-repo "$SPEC" || rc=$?   # FB-2 A1
    [ "$rc" != 2 ] || gref "$SPEC exists and is not private — ViD's spec repository is private; make it private, or name another"
    [ "$rc" = 0 ] || gref "the spec repository $SPEC could not be made"
    if [ "$MKD" = created ]; then echo "ViD github: the spec repository $SPEC made, private"; else echo "ViD github: the spec repository $SPEC exists (private)"; fi
    [ "${1:-}" != --make-only ] || exit 0   # v0.26.10.26.7 (R12)
    sh "$0" spec-export; exit $? ;;

  spec-export)   # v0.26.10.12.3 (R2, main 450–494 less the spec-export: key and its ! entries): always R2's paths
    tw; exptree say; specgit; XO=$SPEC; ! xlocal || XO="the export kept in the project"
    # FB-3 B2: back in GitHub auto (or with two repositories) the line kept in the project meanwhile (refs/vid/export, XH; in a project
    # that was ever in GitHub manual, wasmanual: any other pushes after the spec repository's main alone) is followed and pushed whole: SM the newest of it and of the spec repository's main (RM); each on its own line, both are the commit's parents (XP)
    RM=$SM; XP=''; XH=$(git rev-parse -q --verify "$XR^{commit}" 2>/dev/null || true)
    wasmanual || XH=''
    if ! xlocal && [ -n "$XH" ] && [ "$XH" != "$SM" ]; then
      if [ -z "$SM" ] || git --git-dir="$SG" merge-base --is-ancestor "$SM" "$XH" 2>/dev/null; then SM=$XH; elif ! git --git-dir="$SG" merge-base --is-ancestor "$XH" "$SM" 2>/dev/null; then XP=$XH; fi; fi
    ! manual || TR=$(mtree "$SM" "$TR") || gref "the export could not be put beside the files of $SPEC's main no export put there"   # GM-2 T1: they are kept
    if [ -n "$SM" ] && [ "$RM" = "$SM" ] && [ -z "$XP" ] && [ "$(git --git-dir="$SG" rev-parse "$SM^{tree}")" = "$TR" ]; then twlog "export $SM from=$H state=unchanged at=$(now)"; xfollow || true
      echo "ViD github: the export at $(printf '%.12s' "$H") changes nothing — $XO stays at $(printf '%.12s' "$SM")"; exit 0; fi
    set -- -m "ViD export of $(printf '%.12s' "$H")" -m "from: $H" -m "paths: $(paste -sd ' ' "$W/xp")"; [ -z "$XP" ] || set -- -p "$XP" "$@"; [ -z "$SM" ] || set -- -p "$SM" "$@"
    # FB-3 B2: kept in the project, its dates are the applied commit's, so the same spec on the same parent is the same commit
    XD=''; ! xlocal || XD=$(git log -1 --format=%cI "$H")
    # authored and committed as ViD <vid@export.invalid> — no one's address (.invalid is reserved), in the call's own
    # environment, so neither git config nor an exported GIT_AUTHOR_*/GIT_COMMITTER_* overrides it (main's v0.26.10.17)
    if [ -n "$SM" ] && [ "$RM" != "$SM" ] && [ "$(git --git-dir="$SG" rev-parse "$SM^{tree}")" = "$TR" ]; then C=$SM; else   # FB-3 B2: the line's newest holds it already
    C=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid GIT_AUTHOR_DATE="$XD" GIT_COMMITTER_DATE="$XD" \
      git --git-dir="$SG" commit-tree "$TR" "$@") || gref 'the export commit could not be made'; fi
    if xlocal; then git --git-dir="$SG" update-ref refs/heads/main "$C" && xfollow || gref "the export could not be kept in the project ($XR, forward only)"
      twlog "export $C from=$H state=local at=$(now)"; echo "ViD github: exported $(paste -sd ' ' "$W/xp") at $(printf '%.12s' "$H") as $(printf '%.12s' "$C"), kept in the project"; exit 0; fi
    # fast-forward only, never forced: no + and no --force, so a remote that moved is a refusal
    git --git-dir="$SG" push -q "$SURL" "$C:refs/heads/main" 2> "$W/xpush" || { sed 's/^/    /' "$W/xpush" >&2; gref "the export could not be pushed to $SPEC (a fast-forward of main only)"; }
    git --git-dir="$SG" update-ref refs/heads/main "$C"; xfollow || true
    twlog "export $C from=$H state=pushed at=$(now)"
    echo "ViD github: exported $(paste -sd ' ' "$W/xp") at $(printf '%.12s' "$H") to $SPEC as $(printf '%.12s' "$C")"; exit 0 ;;

  spec-publish)   # GM-4 K13 (J4): spec-publish [#<pr>] [--words "<w>"] [<export commit>], with layout: one, the export commit's spec tree put into spec-path:
    # (default docs/specs) on the code repository through GitHub's git data API alone: each file of the export a blob, spec-stamp:
    # (optional, a file inside the folder) holding the export commit, and (FB-3 B1) one tree on main's tree with those files at the folder
    # (main's commit and its tree read from .vid/code, the copy ViD fetches; no file of the code read or sent), one commit on main, the
    # branch vid-spec/<12 hex>, a pull request of it and a publish ticket (an issue labelled <prefix>spec) naming it. Refused, nothing
    # posted: with any layout but one; for a folder or stamp that leaves the folder (an entry outside spec-path is never sent); for an
    # export entry no plain file (a submodule, or a name holding a quote, a backslash or a control byte). With no main on the code
    # repository yet, one line, exit 0, nothing posted. A call that failed part way is finished by the next: the branch, left made,
    # moved to the new commit; a pull request open on it reused; the publish logged once the pull request exists, and the publish
    # ticket, logged `spec-ticket pr=<n> issue=<i> at=<time>`, made alone when it is all that is owed. Nothing more when the newest
    # spec-published line names this export, this folder and this stamp (spdone) and its ticket is made: a changed folder or stamp is
    # published again. Nothing pushed from this machine, and ViD merges nothing: the team merges it.
    # FB-3 B1: it changes only files ViD put there. Kept: every file of main's folder the export lacks; overwritten: a path the export
    # holds, and the stamp; deleted: a path the export no longer holds (an older stamp too) whose file on main is the one an earlier
    # spec-published export of this folder, ViD's own, put there, so a first publish deletes nothing. The folder's names and ids
    # (fold) are read before any deletion, and once after the tree call, so a tree that does not hold the export is refused.
    # FB-3 B1, spec-publish: hand, in GitHub manual (GitHub auto publishes as ever): the team publishes by its own process and nothing is written to GitHub. The code repository is
    # fetched; the folder read at main, or at pull request #<pr>'s head (closed and not merged, refused). Every file of the export there: logged `spec-published
    # pr=<pr|-> export= path= stamp= at= by=hand[ words=]` (the stamp's form is the team's, not read). Not there: the export laid out in
    # .vid/spec-out/<12>/files with changes.tsv (`new|changed|gone <path>`; not saved, made again each call), and refused (exit 1),
    # naming the folder. A by=hand line makes no publish ticket and is never replaced (spreplace).
    # Logged `spec-published pr=<n> export=<12 hex> path=<folder> stamp=<file|-> at=<time>`, and (FB-1 B6) ` words="<w>"` last when the
    # owner's words were given, quoted as tw-post's are (in GitHub auto blank words are no words); whether they are required is the skill's rule
    # FB-1 B5: a git data call that itself fails, or a close of FB-1 B1's that fails, exits 5, the call unfinished, not refused (1 is a
    # rule's refusal): .vid/tw/spec-owed (saved with the records) holds the export, one line, until a call exits 0. FB-2 B1: one rule
    # for every call: the flag SPX set before tw (its auth inside it), a refusal right after a failed GitHub or git network call is
    # spfail (gref, keeperr), GitHub's reply on the line; a refusal after calls that succeeded stays a rule's (exit 1)
    # FB-1 B5: spfail <why>, the call unfinished: the marker written (the export, or the log's newest export before it is known; none
    # while there is no export), exit 5; FB-2 B2: and logged `spec-failed export=<12|-> at=<time> why="<the line>"` (quotes as ');
    # spok, a call that finishes: the marker gone
    SPX=yes; E12=''
    spfail() { _e=$E12; [ -n "$_e" ] || _e=$(awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' .vid/tw/log 2>/dev/null); [ -z "$_e" ] || { printf '%s\n' "$_e" > "$W/so" && put .vid/tw/spec-owed < "$W/so"; }
      twlog "spec-failed export=${_e:--} at=$(now) why=\"$(printf '%s' "$*" | tr '\t\n\r' '   ' | tr '"' "'")\""; echo "ViD github: not finished — $*" >&2; exit 5; }
    spok() { rm -f .vid/tw/spec-owed; }
    tw; SPUB=yes; WO=''; WS=''; PN=''; EA=''; while [ $# -gt 0 ]; do case $1 in --words) [ $# -ge 2 ] || usage; WO=$2; WS=1; shift 2 ;; '#'*) PN=${1#?}; case $PN in ''|*[!0-9]*) usage ;; esac; shift ;; *) [ -z "$EA" ] || usage; EA=$1; shift ;; esac; done
    HND=''; ! manual || [ "$(twkey spec-publish)" != hand ] || HND=yes; [ -z "$PN" ] || [ -n "$HND" ] || gref "#$PN is read as the team's own publish in GitHub manual with the setup's spec-publish: hand alone (sh checks/planner.sh setup spec-publish hand --words \"<their words>\") — nothing posted"   # FB-3 B1
    [ -z "$WS" ] || [ -n "$(printf '%s' "$WO" | tr -d '[:space:]')" ] || manual || WS=''; WQ=$(printf '%s' "$WO" | tr '\t\n\r' '   ' | tr '"' "'")
    [ "$(twkey layout)" = one ] || gref "layout: $(twkey layout | grep . || echo separate): the spec reaches the team by the spec repository's export alone (sh checks/github.sh spec-export); spec-publish is layout: one's — nothing posted"
    spdest
    spplain || gref "spec-path: '$SP' is no folder inside the code repository (a plain path from its top): nothing outside the folder is ever published — nothing posted"
    case "$SS" in '') ;; /*|.|..|./*|../*|*/../*|*/..|*/.|*/./*|*//*|*/|*[!A-Za-z0-9._/-]*) gref "spec-stamp: '$(twkey spec-stamp)' is no file inside spec-path: $SP: an entry outside the folder is never published — nothing posted" ;; esac
    specgit; E=${EA:-$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log 2>/dev/null)}; [ -n "$E" ] || gref 'no export yet: sh checks/github.sh spec-export first — nothing posted'
    E=$(git --git-dir="$SG" rev-parse -q --verify "$E^{commit}") || gref "the export $EA is not in ViD's copy of the spec repository (.vid/spec.git) — nothing posted"; E12=$(printf %.12s "$E")
    # spticket <pr>: the publish ticket naming the pull request, logged `spec-ticket pr=<n> issue=<i> at=<time>` once made
    spticket() { printf 'vid: pull request #%s brings the spec at export %s into the folder %s. Merge it before working on a ticket that quotes this export, then close this issue.\n' "$1" "$E12" "$SP" > "$W/pt"
      ghc label create "${PFX}spec" -R "$REPO" --force --description 'ViD: the spec published' > /dev/null || gref "pull request #$1 is made, but the label ${PFX}spec could not be: sh checks/github.sh spec-publish again makes its publish ticket"
      I=$(ghc issue create -R "$REPO" --title "ViD: merge pull request #$1, the spec at export $E12" --body-file "$W/pt" --label "${PFX}spec" | num_of_url) && [ -n "$I" ] || gref "pull request #$1 is made, but its publish ticket could not be: sh checks/github.sh spec-publish again makes it"
      twlog "spec-ticket pr=$1 issue=$I at=$(now)"; }
    # FB-1 B1: spreplace <pr>: each pull request of an earlier spec-published line but <pr> (a republish of the same export to a
    # changed folder or stamp reuses its own), with no `spec-replaced pr=<it>` line yet, in two halves, each on its own: the pull
    # request, open, told `vid: replaced by pull request #<pr> …` and closed (merged or closed already: left as it is); its publish
    # ticket (spec-ticket), open, told `vid: replaced by #<ticket> …` and closed, unless its pull request was merged. Each item's
    # comments are read first (FB-3 B1: a by=hand line, the team's own publish, is none of them), so one opening `vid: replaced by` there is never posted again and only the close is tried. Logged
    # `spec-replaced pr=<old> by=<pr> issue=<i|-> at=<time>` once both halves are done; a half not done leaves the call unfinished
    # (exit 5), and the next call tries it again. FB-2 B2: each failed call's reply kept as it happens (rpk, $W/rpw: `#<old>: <reply>`,
    # never $W/gfail, which a later call that succeeds removes) and put on spfail's line, so on its spec-failed line
    RPL='.state + "\t" + ([.comments[].body | select(startswith("vid: replaced by"))] | length | tostring)'
    rpk() { _ro=$1; shift; _rk=0; "$@" 2> "$W/rpe" || _rk=$?; cat "$W/rpe" >&2; [ "$_rk" = 0 ] && return 0; _g=$(ghwhy "$W/rpe"); [ -z "$_g" ] || printf '#%s: %s\n' "$_ro" "$_g" >> "$W/rpw"; return "$_rk"; }
    spreplace() { _rf=''; : > "$W/rpw"
      for _o in $(grep -vE "$BYH" .vid/tw/log | sed -n 's/^spec-published pr=\([0-9][0-9]*\) .*/\1/p' | sort -un); do [ "$_o" != "$1" ] || continue; ! grep -q "^spec-replaced pr=$_o " .vid/tw/log || continue
        _oi=$(sed -n "s/^spec-ticket pr=$_o issue=\([0-9]*\) .*/\1/p" .vid/tw/log | tail -n 1); _pk=1; _tk=1
        _ps=$(rpk "$_o" ghc pr view "$_o" -R "$REPO" --json state,comments --jq "$RPL" 2>/dev/null) || _ps=''; _pst=$(printf '%s' "$_ps" | cut -f1)
        case $_pst in OPEN) if [ "$(printf '%s' "$_ps" | cut -f2)" = 0 ]; then printf 'vid: replaced by pull request #%s, the spec at export %s; nothing of this one is to merge.\n' "$1" "$E12" > "$W/rp" && rpk "$_o" ghc pr comment "$_o" -R "$REPO" --body-file "$W/rp" > /dev/null || _pk=''; fi
            [ -z "$_pk" ] || rpk "$_o" ghc pr close "$_o" -R "$REPO" > /dev/null || _pk='' ;;
          MERGED|CLOSED) ;; *) _pk='' ;; esac
        if [ -n "$_oi" ]; then case $_pst in '') _tk='' ;; MERGED) ;; *)   # its pull request's state unread: the ticket waits for the next call
          _is=$(rpk "$_oi" ghc issue view "$_oi" -R "$REPO" --json state,comments --jq "$RPL" 2>/dev/null) || _is=''
          case $(printf '%s' "$_is" | cut -f1) in OPEN) if [ "$(printf '%s' "$_is" | cut -f2)" = 0 ]; then printf 'vid: replaced by #%s: merge pull request #%s instead.\n' "$I" "$1" > "$W/ri" && rpk "$_oi" ghc issue comment "$_oi" -R "$REPO" --body-file "$W/ri" > /dev/null || _tk=''; fi
              [ -z "$_tk" ] || rpk "$_oi" ghc issue close "$_oi" -R "$REPO" > /dev/null || _tk='' ;;
            CLOSED) ;; *) _tk='' ;; esac ;; esac; fi
        if [ -n "$_pk" ] && [ -n "$_tk" ]; then twlog "spec-replaced pr=$_o by=$1 issue=${_oi:--} at=$(now)"; else _rf="$_rf${_rf:+,} #$_o"; fi
      done
      _g=$(paste -sd '|' "$W/rpw" | sed 's/|/; /g'); [ -z "$_rf" ] || spfail "pull request #$1 is made; the older$_rf or its ticket could not be closed${_g:+ (GitHub: $_g)}: spec-publish again closes it"; }
    # GM-4 K13: published already: nothing more, but the publish ticket when a call failed after the pull request was made; FB-1 B1:
    # and the older folder pull requests' close, when a call stopped before it was done
    LP=$(grep '^spec-published ' .vid/tw/log 2>/dev/null | tail -n 1 || true); if spdone "$E12" && [ -z "$PN" ]; then P=$(kv "$LP" pr)
      if [ -n "$HND" ] || printf '%s\n' "$LP" | grep -qE "$BYH"; then echo "ViD github: the export $E12 is published into $SP already ($([ "$P" = - ] && echo 'on main' || echo "pull request #$P"))"; spok; exit 0; fi   # FB-3 B1
      I=$(sed -n "s/^spec-ticket pr=$P issue=\([0-9]*\) .*/\1/p" .vid/tw/log | tail -n 1)
      if [ -n "$I" ]; then echo "ViD github: the export $E12 is published into $SP already (pull request #$P)"; spreplace "$P"; spok; exit 0; fi
      spticket "$P"; echo "ViD github: the export $E12 is published into $SP (pull request #$P): its publish ticket #$I made"; spreplace "$P"; spok; exit 0; fi
    # the entries, each read whole (a newline in a name as \001); every one a plain file or link, and at its place inside the folder
    git --git-dir="$SG" ls-tree -r -z "$E" > "$W/pe0" || gref "the export $E12 could not be read — nothing posted"; tr '\n\000' '\001\n' < "$W/pe0" > "$W/pe"
    awk -F'\t' -v P="$SP" '{ split($1, m, " "); p = $2; f = P "/" p
        if (m[2] != "blob" || p ~ /["\\]/ || p ~ /[[:cntrl:]]/ || index(f, P "/") != 1 || f ~ /(^|\/)\.\.?(\/|$)/) print p }' "$W/pe" | tr '\001' ' ' > "$W/pbad"
    [ ! -s "$W/pbad" ] || gref "the export $E12 holds $(head -n 1 "$W/pbad"), which the folder $SP cannot take as a plain file of its own — nothing posted"
    [ -z "$SS" ] || ! awk -F'\t' -v s="$SS" '$2 == s || index(s, $2 "/") == 1 || index($2, s "/") == 1 { f = 1 } END { exit !f }' "$W/pe" || gref "spec-stamp: $SS is a file of the export itself — nothing posted"
    STB=''; if [ -n "$SS" ] && [ -z "$HND" ]; then STB=$(printf '%s\n' "$E" | git --git-dir="$SG" hash-object -w --stdin) || gref 'the stamp could not be made — nothing posted'; fi
    # main: its commit and tree, from .vid/code, fetched first (FB-3 B1)
    # GM-4 K13: a code repository with no main yet (the normal start, before the skeleton merges) has no folder to publish into: one
    # line, exit 0, nothing posted; the export goes there by a later call once main exists
    # FB-2 B1: main's fetch (results-fetch, its own process) keeps its reply ($W/rfe); main on GitHub and not in .vid/code is the call
    # unfinished (exit 5, the fetch's reply, or a later read's), never a rule
    # FB-3 B1: the fetch is made first, each call, so the folder is read, and what is deleted decided, as main stands
    RF=''; sh "$0" results-fetch > /dev/null 2> "$W/rfe" || RF=no
    MC=$(git --git-dir=.vid/code rev-parse -q --verify refs/heads/main 2>/dev/null) || {
      CU=$(ghc repo view "$REPO" --json url --jq .url 2>/dev/null) && [ -n "$CU" ] && keeperr git ls-remote "$CU" refs/heads/main > "$W/pm" 2>/dev/null && [ ! -s "$W/pm" ] &&
        { echo "ViD github: the code repository has no main yet, so no folder $SP to publish the export $E12 into: nothing posted; it goes there once main exists"; spok; exit 0; }
      [ -f "$W/gfail" ] || cp "$W/rfe" "$W/gfail" 2>/dev/null || : > "$W/gfail"; gref "the code repository's main is not in .vid/code (sh checks/github.sh results-fetch) — nothing posted; the next call fetches it"; }
    [ -z "$RF" ] || { cp "$W/rfe" "$W/gfail"; gref 'the code repository could not be fetched into .vid/code — nothing posted; the next call fetches it'; }
    MT=$(git --git-dir=.vid/code cat-file commit "$MC" 2>/dev/null | sed -n '1s/^tree //p'); [ -n "$MT" ] || gref "main's tree could not be read from .vid/code — nothing posted"
    # GM-4 proof D6: each git data call's reply kept ($W/gde), so a refusal says what GitHub answered (gw)
    gd() { SPUB=yes ghc api -X POST "repos/$REPO/git/$1" --input "$W/pj" --jq "$2" 2> "$W/gde"; }
    # olds [all]: $W/olds, `<blob id>\t<path>` of each file an earlier publish of this folder put there (ViD's own, its stamp too; all: the
    # team's too) that this export and its stamp do not hold; was: those of them in $W/fold unchanged, by path
    olds() { : > "$W/ol0"; grep '^spec-published ' .vid/tw/log 2>/dev/null | if [ "${1:-}" = all ]; then cat; else grep -vE "$BYH"; fi > "$W/ol1"
      while IFS= read -r _l; do [ "$(kv "$_l" path)" = "$SP" ] && _x=$(git --git-dir="$SG" rev-parse -q --verify "$(kv "$_l" export)^{commit}" 2>/dev/null) || continue
        git --git-dir="$SG" ls-tree -r -z "$_x" | tr '\n\000' '\001\n' | sed 's/^[0-9]* [a-z]* //' >> "$W/ol0"; _st=$(kv "$_l" stamp); [ "$_st" = - ] || printf '%s\t%s\n' "$(printf '%s\n' "$_x" | git --git-dir="$SG" hash-object --stdin)" "$_st" >> "$W/ol0"; done < "$W/ol1"
      awk -F'\t' -v S="$SS" 'FILENAME == ARGV[1] { H[$2] = 1; next } $2 != S && !($2 in H) && !U[$0]++' "$W/pe" "$W/ol0" > "$W/olds"; }
    was() { awk 'FILENAME == ARGV[1] { O[$0] = 1; next } $0 in O { sub(/^[^\t]*\t/, ""); print }' "$W/olds" "$W/fold" | sort -u; }
    awk -F'\t' '{ split($1, m, " "); print m[3] "\t" $2 }' "$W/pe" > "$W/px"
    if [ -n "$HND" ]; then   # FB-3 B1: the team's own publish, read
      HT=$MT; HW="the code repository's main"; if [ -n "$PN" ]; then HW="pull request #$PN"; HT=$(git --git-dir=.vid/code cat-file commit "refs/pull/$PN/head" 2>/dev/null | sed -n '1s/^tree //p'); [ -n "$HT" ] || gref "pull request #$PN is not on the code repository — nothing posted"
        # closed and not merged, it publishes nothing: its state by spreplace's read
        HS=$(ghc pr view "$PN" -R "$REPO" --json state,comments --jq "$RPL" 2> "$W/gde") || spfail "the state of pull request #$PN could not be read$(gw) — nothing posted; the next call reads it"
        [ "$(printf '%s' "$HS" | cut -f1)" != CLOSED ] || gref "pull request #$PN is closed and not merged, so it publishes nothing: name the one that does — nothing posted"; fi
      fold "$HT"; awk -F'\t' 'FILENAME == ARGV[1] { F[$2] = $1; next } !($2 in F) { print "new\t" $2; next } F[$2] != $1 { print "changed\t" $2 }' "$W/fold" "$W/px" > "$W/hc"
      if [ ! -s "$W/hc" ]; then if spdone "$E12" && [ "$(kv "$LP" pr)" = "${PN:--}" ]; then echo "ViD github: the export $E12 is published into $SP already ($HW)"; else twlog "spec-published pr=${PN:--} export=$E12 path=$SP stamp=${SS:--} at=$(now) by=hand${WS:+ words=\"$WQ\"}"
        echo "ViD github: the export $E12 is in the folder $SP, in $HW: the team's publish recorded, nothing posted"; fi; spok; exit 0; fi
      HN=$(grep -c . "$W/hc" | tr -d ' '); HF=$(head -n 3 "$W/hc" | cut -f2 | paste -sd , - | sed 's/,/, /g'); olds all; was | sed 's/^/gone	/' >> "$W/hc"
      HO=.vid/spec-out/$E12; rm -rf .vid/spec-out; mkdir -p "$HO/files" && git --git-dir="$SG" -c core.autocrlf=false archive "$E" | tar -x -C "$HO/files" && put "$HO/changes.tsv" < "$W/hc" || gref "the export $E12 could not be laid out in $HO — nothing posted"
      gref "the export $E12 is not in the folder $SP of $HW: $HN of its files are not there or differ ($HF$([ "$HN" -le 3 ] || echo ', …')). Laid out in $HO/files, with $HO/changes.tsv; the team publishes it by its own process, then /vid:vid-spec-publish #<its pull request> reads it — nothing posted"; fi
    # FB-3 B1: what this publish deletes: a file ViD put there, dropped from the export and unchanged on main
    olds; : > "$W/pdel"; [ ! -s "$W/olds" ] || { fold "$MT"; was > "$W/pdel"; }
    # each file a blob: what GitHub names it must be the export's own
    { awk -F'\t' '{ split($1, m, " "); print m[3] }' "$W/pe"; [ -z "$STB" ] || echo "$STB"; } | sort -u > "$W/pbl"
    for b in $(cat "$W/pbl"); do { printf '{"content":"'; git --git-dir="$SG" cat-file blob "$b" | base64 | tr -d '\n\r'; printf '","encoding":"base64"}\n'; } > "$W/pj" || gref "a file of the export could not be read — nothing posted"
      r=$(gd blobs .sha) || spfail "a file of the export could not be sent (blob $b)$(gw): no branch names what was sent — nothing posted; the next call sends it"
      [ "$r" = "$b" ] || gref "a file of the export could not be sent as itself (blob $b)$(gw "$r" "$b"): no branch names what was sent — nothing posted"; done
    # FB-3 B1: one tree: main's, with the export's files and the stamp at the folder, and each deleted path out; read back by its names and ids
    { printf '{"base_tree":"%s","tree":[\n' "$MT"; awk -F'\t' -v P="$SP/" -v S="$SS" -v SB="$STB" 'FILENAME == ARGV[2] { L[++n] = "{\"path\":\"" P $0 "\",\"mode\":\"100644\",\"type\":\"blob\",\"sha\":null}"; next } { split($1, m, " "); L[++n] = sprintf("{\"path\":\"%s\",\"mode\":\"%s\",\"type\":\"blob\",\"sha\":\"%s\"}", P $2, m[1], m[3]) }
        END { if (S != "") L[++n] = sprintf("{\"path\":\"%s\",\"mode\":\"100644\",\"type\":\"blob\",\"sha\":\"%s\"}", P S, SB); for (i = 1; i <= n; i++) print L[i] (i < n ? "," : "") }' "$W/pe" "$W/pdel"; printf ']}\n'; } > "$W/pj"
    TOP=$(gd trees .sha) || spfail "the folder's tree could not be made$(gw) — nothing posted; the next call makes it"; [ -n "$TOP" ] || gref "the folder's tree could not be made$(gw) — nothing posted"
    fold "$TOP"; [ -z "$STB" ] || printf '%s\t%s\n' "$STB" "$SS" >> "$W/px"
    BADF=$(awk -F'\t' 'FILENAME == ARGV[1] { F[$2] = $1; next } F[$2] != $1 { print $2 " is " (($2 in F) && F[$2] != "" ? F[$2] : "not there") ", the export'"'"'s is " $1; exit }' "$W/fold" "$W/px")
    [ -z "$BADF" ] || gref "the folder's tree could not be made as the export holds it (GitHub made $TOP, where $BADF) — nothing posted"
    printf '{"message":"ViD export %s into %s","tree":"%s","parents":["%s"],"author":{"name":"ViD","email":"vid@export.invalid"}}\n' "$E12" "$SP" "$TOP" "$MC" > "$W/pj"; PC=$(gd commits .sha) || spfail "the commit could not be made$(gw) — nothing posted; the next call makes it"; [ -n "$PC" ] || gref "the commit could not be made$(gw) — nothing posted"
    # GM-4 K13: the branch, ViD's own: made, or, left by a call that failed after making it, moved to this commit (forced)
    BR=vid-spec/$E12; CU=$(ghc repo view "$REPO" --json url --jq .url) && [ -n "$CU" ] && keeperr git ls-remote "$CU" "refs/heads/$BR" > "$W/pbr" 2>/dev/null || gref "the code repository's branches could not be read — nothing posted"
    if [ -s "$W/pbr" ]; then printf '{"sha":"%s","force":true}\n' "$PC" > "$W/pj"; SPUB=yes ghc api -X PATCH "repos/$REPO/git/refs/heads/$BR" --input "$W/pj" --jq .ref > /dev/null 2> "$W/gde" || spfail "the branch $BR, left by an earlier call, could not be moved to the new commit$(gw) — nothing posted; the next call moves it"
    else printf '{"ref":"refs/heads/%s","sha":"%s"}\n' "$BR" "$PC" > "$W/pj"; gd refs .ref > /dev/null || spfail "the branch $BR could not be made$(gw) — nothing posted; the next call makes it"; fi
    { printf 'vid: this pull request brings the spec ViD exported, export %s, into the folder %s, and changes nothing outside it.' "$E12" "$SP"; [ -z "$SS" ] || printf ' The file %s/%s names the export.' "$SP" "$SS"
      printf '\n\nMerge it before working on a ticket that quotes this export. ViD merges nothing.\n'; } > "$W/pb"
    # GM-4 K13: a pull request open on the branch (an earlier call's) is reused, never made twice; the publish is logged once the pull
    # request exists, so a call that fails on its ticket leaves that alone owed, made by the next call
    ghc pr list -R "$REPO" --state open --head "$BR" --json number,headRefName,state,isDraft,headRefOid,mergeCommit --jq '.[] | [.number, .headRefName, .state, .isDraft, .headRefOid, (.mergeCommit.oid // "-")] | @tsv' > "$W/ppr" || gref "the open pull requests of $BR could not be read — the branch is made, nothing more posted: sh checks/github.sh spec-publish again"
    P=$(awk -F'\t' -v b="$BR" '$2 == b && $3 == "OPEN" { print $1; exit }' "$W/ppr")
    [ -n "$P" ] || P=$(ghc pr create -R "$REPO" --head "$BR" --base main --title "ViD: the spec at export $E12, into $SP" --body-file "$W/pb" | num_of_url) && [ -n "$P" ] || gref "the branch $BR is made, but its pull request could not be: sh checks/github.sh spec-publish again makes it"
    twlog "spec-published pr=$P export=$E12 path=$SP stamp=${SS:--} at=$(now)${WS:+ words=\"$WQ\"}"
    I=$(sed -n "s/^spec-ticket pr=$P issue=\([0-9]*\) .*/\1/p" .vid/tw/log | tail -n 1); [ -n "$I" ] || spticket "$P"; echo "ViD github: the export $E12 published into $SP: pull request #$P, ticket #$I"; spreplace "$P"; spok; exit 0 ;;
  decide-blocked)   # v0.26.10.24.6 (R2): prints blocked when the issue or the pull request carries the label; a label it cannot read is refused
    tw; [ -n "${1:-}" ] && [ -n "${2:-}" ] || usage; L=$(ghc issue view "$1" -R "$REPO" --json state,labels --jq '.state + "\t" + ([.labels[].name] | join(","))') || gref "the labels of #$1 could not be read"
    M=$(ghc pr view "$2" -R "$REPO" --json labels --jq '[.labels[].name] | join(",")') || gref "the labels of pull request $2 could not be read"
    case ",$(printf %s "$L" | cut -f2),$M," in *",${PFX}blocked,"*) echo blocked ;; esac; exit 0 ;;

  pr-body)   # 0.26.10.29.5 (DP-1 R2, R8): the pull request's description, whole; a description that cannot be read is refused, never empty
    tw; [ -n "${1:-}" ] || usage; ghc pr view "$1" -R "$REPO" --json body --jq .body || gref "the description of pull request $1 could not be read"; exit 0 ;;

  spec-stamp)   # GM-4 K13: read only. With layout: one and spec-stamp:, the stamp file <spec-path>/<spec-stamp> (spec-path: read as
    # docs/specs while missing) on the code repository's main, its first line printed: the export commit a publish into the folder
    # set it to, ViD's or one by hand. Nothing printed, exit 0, with no stamp key, no main or no such file; a read that fails refuses.
    # It reads that one file alone, no file of the code
    tw; [ "$(twkey layout)" = one ] && [ -n "$(twkey spec-stamp)" ] || exit 0
    SPP=$(twkey spec-path); SPP=${SPP:-docs/specs}; SST=$(twkey spec-stamp); SPF=$SPP/${SST#"$SPP"/}   # the stamp read as spec-publish reads it, with or without the folder
    U=$(ghc repo view "$REPO" --json url --jq .url) || gref "no access to $REPO"
    SMN=$(git ls-remote "$U" refs/heads/main 2> /dev/null | cut -f1) || gref "$REPO's main could not be read"; [ -n "$SMN" ] || exit 0
    STAMPREAD=yes; SV=$(ghc api "repos/$REPO/contents/$SPF?ref=$SMN" --jq '.content | @base64d' 2> "$W/se") || { STAMPREAD=''; grep -q '404' "$W/se" && exit 0; sed 's/^/    /' "$W/se" >&2; gref "the stamp $SPF could not be read"; }; STAMPREAD=''
    printf '%s\n' "$SV" | sed -n '1s/[[:space:]]*$//p'; exit 0 ;;

  spec-folder)   # FB-4 B1: read only, in GitHub manual with layout: one alone. Main's commit; unmoved since the kept read, with its repository and
    # folder, no GET; else the folder's names and ids (fold), written whole to .vid/round/folder, an empty list when it is not there
    manual && [ "$(twkey layout)" = one ] || exit 0
    mkdir -p .vid/round; : > "$W/kept"; [ ! -f .vid/round/folder ] || mv -f .vid/round/folder "$W/kept"   # out until it is read
    tw; spdest; spplain || gref "spec-path: '$SP' is no folder inside the code repository (a plain path from its top)"
    spfail() { gref "$*"; }; U=$(ghc repo view "$REPO" --json url --jq .url) && [ -n "$U" ] && git ls-remote "$U" refs/heads/main > "$W/fm" 2> "$W/gde" || gref "the folder $SP could not be read: $REPO's main could not be read"
    SMN=$(cut -f1 "$W/fm"); [ -n "$SMN" ] || exit 0
    printf 'main\t%s\t%s\t%s\n' "$SMN" "$REPO" "$SP" > "$W/fo"
    if [ "$(sed -n 1p "$W/kept")" = "$(cat "$W/fo")" ]; then cp "$W/kept" "$W/fo"; else FOLDREAD=yes; fold "$SMN"; FOLDREAD=''; cat "$W/fold" >> "$W/fo"; fi
    put .vid/round/folder < "$W/fo" || gref "the folder's read could not be kept"; exit 0 ;;

  record-read)   # IR I1: record-read <link>, read only; every file read before anything is printed, so a failed read prints nothing
    [ $# -eq 1 ] || usage; N=''
    # at the top of ViD's repository, as the ticket writer's subcommands, so the mode is read and never fails open
    [ -f .vid/RUN-STATE.md ] || gref "record-read runs at the top of ViD's repository (no .vid/RUN-STATE.md here), where its mode is read"
    if manual; then gref "in GitHub manual ViD reads no file of the team's repositories: a record reaches ViD as the owner's copy, committed in ViD's repository, and is named by its path there"; fi
    NM='[A-Za-z0-9._-]+'
    # a blob link's path holds no ? and no #: a line permalink (?plain=1#L12) names a part of a file, and is refused
    if printf '%s\n' "$1" | grep -qE "^https://github\.com/$NM/$NM/blob/[0-9a-f]{40}/[^?#]+\$"; then
      RR=$(printf '%s\n' "$1" | sed -E 's#^https://github\.com/([^/]+/[^/]+)/blob/.*#\1#'); H=$(printf '%s\n' "$1" | sed -E 's#^https://github\.com/[^/]+/[^/]+/blob/([0-9a-f]{40})/.*#\1#')
      printf '%s\n' "$1" | sed -E 's#^https://github\.com/[^/]+/[^/]+/blob/[0-9a-f]{40}/##' > "$W/rf"; auth; RECREAD=yes
    elif printf '%s\n' "$1" | grep -qE "^https://github\.com/$NM/$NM/pull/[0-9]+/?\$"; then
      RR=$(printf '%s\n' "$1" | sed -E 's#^https://github\.com/([^/]+/[^/]+)/pull/.*#\1#'); N=$(printf '%s\n' "$1" | sed -E 's#^.*/pull/([0-9]+)/?$#\1#'); auth; RECREAD=yes
      H=$(ghc api "repos/$RR/pulls/$N" --jq .head.sha 2> "$W/e") || gref "pull request $N of $RR could not be read: $(tail -n 1 "$W/e")"
      printf '%s\n' "$H" | grep -qxE '[0-9a-f]{40}' || gref "pull request $N of $RR gave no head commit"
      ghc api "repos/$RR/pulls/$N/files" --paginate --jq '.[] | select(.status != "removed") | .filename' > "$W/pf" 2> "$W/e" || gref "the files of pull request $N could not be read: $(tail -n 1 "$W/e")"
      grep -iE '[.](md|markdown)$' "$W/pf" | LC_ALL=C sort -u > "$W/rf" || :
      [ -s "$W/rf" ] || gref "pull request $N of $RR changes no Markdown file at its head"
    else gref "not a record's link: give a blob link at a commit (https://github.com/<owner>/<repo>/blob/<40-hex sha>/<path>) or a pull request (https://github.com/<owner>/<repo>/pull/<n>)"; fi
    # a pull request's names are raw, so each is encoded for the address; a blob link's path is in the link's own form already.
    # Each name read a line at a time, never expanded as a pattern
    k=0; while IFS= read -r p; do k=$((k + 1)); q=$p; [ -z "${N:-}" ] || q=$(printf '%s' "$p" | sed 's/%/%25/g; s/ /%20/g; s/#/%23/g; s/?/%3F/g')
      ghc api "repos/$RR/contents/$q?ref=$H" --jq '.content | @base64d' > "$W/rt.$k" 2> "$W/e" < /dev/null || gref "$p at $H could not be read: $(tail -n 1 "$W/e")"; printf '%s\n' "$q" > "$W/rq.$k"; done < "$W/rf"
    j=0; while [ "$j" -lt "$k" ]; do j=$((j + 1)); echo "record: https://github.com/$RR/blob/$H/$(cat "$W/rq.$j")"; cat "$W/rt.$j"; done; exit 0 ;;

  decide-post)   # v0.26.10.24.6 (R2): the decision, a comment on the pull request
    tw; [ -n "${1:-}" ] && [ -f "${2:-}" ] || usage; ghc pr comment "$1" -R "$REPO" --body-file "$2" > /dev/null || gref "the decision on pull request $1 could not be posted"; exit 0 ;;

  results-fetch)   # v0.26.10.24.5 (R2): .vid/code, the local copy checks/results.sh reads: every head and vid-results/* branch; 0.26.10.28.4: no file of the code
    prog now "fetching the team's reports"   # FB-3 D2
    tw; U=$(ghc repo view "$REPO" --json url --jq .url 2>/dev/null) && [ -n "$U" ] || gref "no access to $REPO: gh repo view $REPO failed"
    # 0.26.10.28.1 (stage 9 R5, S5): a working clone there (the first ticket mode's) is moved aside, and the bare copy cloned
    if [ -d .vid/code/.git ]; then CO=.vid/code.old-$(date -u '+%Y%m%dT%H%M%SZ'); mv .vid/code "$CO" || gref ".vid/code, a working clone, could not be moved aside"; echo "ViD github: .vid/code was a working clone — moved aside to $CO; the bare copy is cloned in its place"; fi
    # 0.26.10.28.4 (9.3 R5, M5): .vid/code holds no file of DevAgent's code. The reports: each vid-results/* branch's own folder alone (FB-3 A2,
    # below). DevAgent's commits: every other branch and pull-request head with no tree (--filter=tree:0), through a
    # promisor remote whose address is never stored, so nothing is fetched later; HEAD unborn, so no attributes are read from a code tree. At every fetch:
    # what no ref reaches is dropped, then the proof (nothing but the reports' trees and files, the empty tree aside; each report its folder alone), else
    # .vid/code is removed and the fetch refused. A copy in the earlier, full form is replaced
    xref() { rm -rf .vid/code; gref "the fetch brought DevAgent's files ($1); ViD keeps none. .vid/code removed, nothing fetched."; }
    if [ -d .vid/code ] && [ "$(cg config extensions.partialClone 2>/dev/null)" != vid-commits ]; then rm -rf .vid/code; echo "ViD github: .vid/code held DevAgent's files, the earlier form — replaced by a copy that holds none"; fi
    [ -d .vid/code ] || { git init -q --bare .vid/code && cg config core.repositoryformatversion 1 && cg config extensions.partialClone vid-commits; } || { rm -rf .vid/code; gref ".vid/code could not be made"; }
    cg symbolic-ref HEAD refs/vid/none || gref ".vid/code's HEAD could not be set"   # unborn, outside both fetches' refs
    LR=$(git ls-remote "$U" 'refs/heads/vid-results/*' 2>/dev/null) || gref "$REPO's reports could not be listed (git ls-remote)"   # whole: a branch ending in vid-results/… is no report
    # FB-3 A2: of a report branch its own folder alone is read and fetched, whatever else the branch holds. GitHub names that folder's tree (one
    # read-only graphql query of 50 branches; nothing of the rest is named or sent), that tree alone is fetched, and the branch's ref here is a
    # parentless commit of ViD's holding the folder alone, at the branch's commit's time, its message `vid-report: <the branch's commit>`; a branch
    # whose ref says its commit already is not asked for. A branch with no such folder is left out, its line in .vid/round/reports-skipped (id,
    # commit, author, date, why; tab), asked again at each fetch. A read GitHub fails is the call refused, the copy and the list as they were
    ownrefs || gref "ViD's own reviews could not be put into .vid/code"; mkdir -p .vid/round; : > "$W/sk"; : > "$W/got"
    printf '%s\n' "$LR" | awk '$2 ~ /^refs\/heads\/vid-results\// { sub(/^refs\/heads\/vid-results\//, "", $2); print $1 "\t" $2 }' > "$W/lr"
    cg for-each-ref --format='%(refname:lstrip=3) %(contents:subject)' refs/heads/vid-results/ | awk -v OFS='\t' '$2 == "vid-report:" { print $1, $3 }' > "$W/here"
    # an id is any plain character git allows in a branch's last part but the double quote (graphql's, and git's own quoting of a name)
    LC_ALL=C awk -F'\t' -v OFS='\t' -v H="$W/here" -v O="$W/own" -v SK="$W/sk" 'BEGIN { while ((getline l < H) > 0) { split(l, x, "\t"); C[x[1]] = x[2] } while ((getline l < O) > 0) OW[l] = 1 } $2 in OW { next }
      $2 !~ /^[!#-~]+$/ || index($2, "/") { print $2, $1, "-", "-", "its name holds " (index($2, "/") ? "a slash after vid-results/" : "a double quote, or a letter past plain text") ", so it is pushed again under a plain name" > SK; next } C[$2] != $1 { print $1, $2 }' "$W/lr" > "$W/ask"
    RESREAD=yes; split -l 50 "$W/ask" "$W/ask." 2>/dev/null || :; for f in "$W"/ask.??*; do [ -s "$f" ] || continue
      Q=$(awk -F'\t' -v o="${REPO%%/*}" -v n="${REPO#*/}" 'BEGIN { printf "query { repository(owner: \"%s\", name: \"%s\") {", o, n } { printf " c%d: object(oid: \"%s\") { oid ... on Commit { committedDate author { name } } } f%d: object(expression: \"%s:%s\") { __typename oid }", NR, $1, NR, $1, $2 } END { print " } }" }' "$f")
      ghc api graphql -f query="$Q" --jq '.data.repository | to_entries[] | [.key, (.value.__typename // "-"), (.value.oid // "-"), (.value.committedDate // "-"), (.value.author.name // "-")] | @tsv' > "$W/gq" 2> "$W/e" || gref "$REPO's reports could not be read: $(ghwhy "$W/e")"
      [ "$(grep -c . "$W/gq")" = $(($(grep -c . "$f") * 2)) ] || gref "$REPO's reports could not be read: the reply is not whole"
      awk -F'\t' -v OFS='\t' -v SK="$W/sk" -v A="$f" 'BEGIN { while ((getline l < A) > 0) { split(l, x, "\t"); c[++n] = x[1]; id[n] = x[2] } } { k = substr($1, 2) + 0; if ($1 ~ /^c/) { o[k] = $3; d[k] = $4; a[k] = $5 } else { t[k] = $2; f[k] = $3 } }
        END { for (k = 1; k <= n; k++) if (o[k] != c[k] || d[k] == "-") { print id[k]; exit 3 }
          for (k = 1; k <= n; k++) if (t[k] == "Tree") print c[k], id[k], f[k], d[k]; else print id[k], c[k], a[k], d[k], (t[k] == "-" ? "it has no folder " id[k] : id[k] " is a file there, not a folder") >> SK }' "$W/gq" > "$W/g1" || gref "$REPO's reports could not be read: $(tail -n 1 "$W/g1") is listed, its commit not there"
      cat "$W/g1" >> "$W/got"; done; RESREAD=''
    # the folders by their trees' own ids; noop, so no commit held here is taken as holding files that are not here
    [ ! -s "$W/got" ] || cg -c fetch.negotiationAlgorithm=noop fetch -q --no-tags --no-write-fetch-head "$U" $(cut -f3 "$W/got" | sort -u) 2>/dev/null || gref "$REPO's reports could not be fetched into .vid/code"
    cg -c remote.vid-commits.url="$U" fetch -q --no-tags --filter=tree:0 vid-commits '+refs/heads/*:refs/heads/*' '^refs/heads/vid-results/*' '+refs/pull/*/head:refs/pull/*/head' 2>/dev/null || gref "$REPO's commits could not be fetched into .vid/code"
    while IFS="$(printf '\t')" read -r c i f d <&4; do t=$(printf '040000 tree %s\t%s\n' "$f" "$i" | cg mktree --missing) && n=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_AUTHOR_DATE="$d" GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid GIT_COMMITTER_DATE="$d" cg commit-tree "$t" -m "vid-report: $c") && cg update-ref "refs/heads/vid-results/$i" "$n" || gref "the report $i could not be kept in .vid/code"; done 4< "$W/got"
    for i in $(cut -f1 "$W/sk"); do cg update-ref -d "refs/heads/vid-results/$i" 2>/dev/null || :; done
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
    # FB-3 A2: git keeps what a promised commit names once it was held here (a pull request opened on a report's own branch), so the copy is
    # made again once, from nothing; a stray object there too is the refusal
    if [ -n "$X" ] && [ -z "${VID_REFETCH:-}" ]; then rm -rf .vid/code; VID_REFETCH=1 sh "$HERE/github.sh" results-fetch; exit $?; fi
    if [ -n "$X" ]; then XR=$(cg for-each-ref --format='%(refname)' refs/heads/ refs/pull/ | grep -v '^refs/heads/vid-results/' | while read -r r; do cg rev-list --objects --missing=allow-any "$r" 2>/dev/null | grep -q "^$X" && { echo "$r"; break; }; done)
      xref "${XR:-an object no report holds, $X}"; fi
    if [ ! -s "$W/sk" ]; then rm -f .vid/round/reports-skipped; else sort "$W/sk" | put .vid/round/reports-skipped; fi || gref 'the list of report branches left out could not be written'
    echo "ViD github: results fetched from $REPO into .vid/code, the reports and the commits, no file of the code"; exit 0 ;;

  pr-files)   # FB-3 A1.4: printed straight from gh; nothing of it is kept in a file or a folder of ViD's
    case ${1:-} in ''|*[!0-9]*) usage ;; esac; [ $# -le 2 ] || usage; tw; PRREAD=yes
    if [ $# -eq 1 ]; then Q='.[] | [.filename, .status, .additions, .deletions, (.previous_filename // "-"), (if .patch then "patch" else "none" end)] | @tsv'
    else Q=$(printf '%s' "$2" | sed 's/\\/\\\\/g; s/"/\\"/g'); Q='.[] | select(.filename == "'"$Q"'") | ([.status, .additions, .deletions, (.previous_filename // "-"), (if .patch then "patch" else "none" end)] | @tsv), (.patch // empty)'; fi
    ghc api "repos/$REPO/pulls/$1/files?per_page=100" --paginate --jq "$Q" 2> "$W/e" || gref "pull request $1's files could not be read: $(ghwhy "$W/e")"; exit 0 ;;

  closing-prs)   # FB-3 A1.4: GitHub's closing references of a ticket and its sub-issues
    [ $# -ge 1 ] || usage; for n in "$@"; do case $n in ''|*[!0-9]*) usage ;; esac; done; tw; RESREAD=yes; printf '%s\n' "$@" | sort -un > "$W/cn"; split -l 50 "$W/cn" "$W/cn."
    J='.data.repository | to_entries[] | .value | .number as $n | .closedByPullRequestsReferences.nodes[] | select(.merged and ((.repository.nameWithOwner | ascii_downcase) == ("'"$REPO"'" | ascii_downcase))) | [$n, .number, (.mergeCommit.oid // "-")] | @tsv'
    for f in "$W"/cn.??*; do while [ -s "$f" ]; do
      Q=$(awk -v o="${REPO%%/*}" -v n="${REPO#*/}" 'BEGIN { printf "query { repository(owner: \"%s\", name: \"%s\") {", o, n } { printf " i%d: issue(number: %s) { number closedByPullRequestsReferences(first: 100, includeClosedPrs: true) { nodes { number merged mergeCommit { oid } repository { nameWithOwner } } } }", NR, $1 } END { print " } }" }' "$f")
      ! ghc api graphql -f query="$Q" --jq "$J" > "$W/cq" 2> "$W/e" || { cat "$W/cq"; break; }
      grep -oE 'Could not resolve to an Issue with the number of [0-9]+' "$W/e" | grep -oE '[0-9]+$' | sort -u > "$W/cx"; [ -s "$W/cx" ] || gref "the pull requests closing the issues could not be read: $(ghwhy "$W/e")"
      grep -vxFf "$W/cx" "$f" > "$W/cy" || :; [ "$(grep -c . "$W/cy")" -lt "$(grep -c . "$f")" ] || gref "the pull requests closing the issues could not be read: $(ghwhy "$W/e")"; mv "$W/cy" "$f"; done; done; exit 0 ;;

  own-refs)   # FB-3 A1.4: ViD's own reviews (.vid/decide/review/) as the reports they are in .vid/code (ownrefs); no GitHub. What a review's record runs
    [ -f .vid/RUN-STATE.md ] || gref "run it at the top of ViD's repository"; ownrefs || gref "ViD's own reviews could not be put into .vid/code"; exit 0 ;;

  round-read)   # v0.26.10.25.1 (R3): one read a tick, whatever the count. Tab-separated: open <p> <ticket> <head> <draft> <labels> <newest decide at the head> <newest decision there> <updated>, the two by comment; merged <p> <ticket> <head> <merge>; issue <n> <labels> <comment heads, \001 between> <updated>; main <the code repository's main> (v0.26.10.28.2); result <report id> <its commit>, a line a vid-results/* branch (v0.26.10.28.6)
    # GM-4 F3: round-read --bodies, the one read with the ticket bodies, sub-issues and assignees (phase 1's next-read, GM-1 S6, moved in),
    # read only, tab-separated: the round read (these lines, a failure of it one `unread round - <gh's words>` line); `ticket <n> <state>
    # <assignees> <created at>` and `body <n> <line>` for each ticket the log publishes and does not withdraw; `sub <ticket> <parent> <child>
    # <state> <assignees> <title>` for each sub-issue under one, at every depth, breadth first; `assigned <n> <labels> <comment first lines,
    # \001 between> <title>` and `abody <n> <line>` for each open issue assigned to the owner (gh's @me). An empty list is `-`. A read that
    # fails is `unread <part> <n or -> <gh's words>`, and the rest is read: it never stops the call. round.sh read gives it in GitHub manual
    case ${1:-} in '') ;; --bodies) [ $# -eq 1 ] || usage ;; *) usage ;; esac
    if [ "${1:-}" = --bodies ]; then
    tw; TQ='[.state, ([.assignees[].login] | join(",")), .createdAt] | @tsv'; SQ='.[] | [.number, .state, .title, ([.assignees[].login] | join(","))] | @tsv'
    AQ='.[] | [.number, ([.labels[].name] | join(",")), ([.comments[].body | split("\n") | .[0]] | join("\u0001")), .title] | @tsv'
    un() { printf 'unread\t%s\t%s\t%s\n' "$1" "$2" "$(tr '\n\t' '  ' < "$W/e" | cut -c1-200)"; }
    sh "$0" round-read 2> "$W/e" || un round -
    awk '$1 == "published" { p[$2] = 1 } $1 == "withdrawn" { delete p[$2] } END { for (n in p) print n }' .vid/tw/log 2>/dev/null | sort -n > "$W/pn"
    pni=0; for n in $(cat "$W/pn"); do pni=$((pni + 1)); prog now "ticket $pni of $(grep -c . "$W/pn")"   # FB-3 D2
      if ghc issue view "$n" -R "$REPO" --json state,assignees,createdAt --jq "$TQ" > "$W/t" 2> "$W/e"; then tr -d '\r' < "$W/t" | awk -F'\t' -v OFS='\t' -v n="$n" 'NR == 1 { print "ticket", n, $1, ($2 == "" ? "-" : $2), $3 }'; else un ticket "$n"; continue; fi
      if ghc issue view "$n" -R "$REPO" --json body --jq .body > "$W/t" 2> "$W/e"; then tr -d '\r' < "$W/t" | awk -v n="$n" '{ L[NR] = $0 } END { while (NR > 0 && L[NR] == "") NR--; for (i = 1; i <= NR; i++) print "body\t" n "\t" L[i] }'; else un body "$n"; fi; done
    for n in $(cat "$W/pn"); do printf '%s %s\n' "$n" "$n"; done > "$W/q"; : > "$W/seen"
    while [ -s "$W/q" ]; do IFS=' ' read -r r p < "$W/q"; sed 1d "$W/q" > "$W/q2"; mv "$W/q2" "$W/q"; grep -qx "$p" "$W/seen" && continue; echo "$p" >> "$W/seen"
      if ghc api "repos/$REPO/issues/$p/sub_issues" --paginate --jq "$SQ" > "$W/s" 2> "$W/e"; then
        tr -d '\r' < "$W/s" | awk -F'\t' -v OFS='\t' -v r="$r" -v p="$p" 'NF { print "sub", r, p, $1, toupper($2), ($4 == "" ? "-" : $4), $3 }'
        tr -d '\r' < "$W/s" | awk -F'\t' -v r="$r" 'NF { print r " " $1 }' >> "$W/q"; else un sub "$p"; fi; done
    AL=${VID_ASSIGNED_LIMIT:-1000}   # a list as long as the limit may be cut, and says so, as oprs does
    if ghc issue list -R "$REPO" --assignee @me --state open --limit "$AL" --json number,labels,comments,title --jq "$AQ" > "$W/a" 2> "$W/e"; then
      [ "$(grep -c . "$W/a")" -lt "$AL" ] || printf 'unread\tassigned\t-\t%s or more open issues are assigned to the owner: the list may be cut\n' "$AL"
      tr -d '\r' < "$W/a" > "$W/a1"; for n in $(cut -f1 "$W/a1"); do awk -F'\t' -v OFS='\t' -v n="$n" '$1 == n { print "assigned", n, ($2 == "" ? "-" : $2), ($3 == "" ? "-" : $3), $4; exit }' "$W/a1"
        if ghc issue view "$n" -R "$REPO" --json body --jq .body > "$W/ab" 2> "$W/e"; then tr -d '\r' < "$W/ab" | awk -v n="$n" '{ L[NR] = $0 } END { while (NR > 0 && L[NR] == "") NR--; for (i = 1; i <= NR; i++) print "abody\t" n "\t" L[i] }'; else un abody "$n"; fi; done
    else un assigned -; fi; exit 0; fi
    tw; ghc pr list -R "$REPO" --state open --limit 200 --json number,headRefName,isDraft,headRefOid,labels,body,comments,updatedAt --jq "$RPQ" > "$W/o" || gref 'the open pull requests could not be read'
    L=20; while :; do ghc pr list -R "$REPO" --state merged --limit "$L" --search 'sort:updated-desc' --json number,headRefOid,mergeCommit,body,comments --jq "$RMQ" > "$W/m" || gref 'the merged pull requests could not be read'
      [ "$(grep -c . "$W/m")" -ge "$L" ] || break; ! { cat .vid/decide/merged-prs 2>/dev/null; cut -f1 .vid/decide/unit-merges 2>/dev/null; } | grep -qx "$(tail -n 1 "$W/m" | cut -f1)" || break; L=$((L * 10)); done   # GM-4 E5: unit-merges counts
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
    # 0.26.10.29.2 (R12): a hand-call's save names the head it checked (VID_SAVE_AT, `none` for no records yet); when the head read
    # here, the parent of this save, is another, another folder saved meanwhile and nothing is saved over it. The run's own save names none
    [ -z "${VID_SAVE_AT:-}" ] || [ "${T0:-none}" = "$VID_SAVE_AT" ] || gref "the saved records' head (${T0:-none}) is not the one this call checked ($VID_SAVE_AT): nothing saved over them"
    for f in RUN-STATE.md budget metrics-events decide tw plans plan next VID-FINDINGS.md; do [ ! -e ".vid/$f" ] || cp -R ".vid/$f" "$RP/$f"; done; rm -rf "$RP"/decide/tmp.*; mkdir "$RP/results"; cp .vid/results/*.txt "$RP/results/" 2>/dev/null
    # GM-4 F3 (I2), GM-2 T12: in GitHub manual alone, the one read and the read before it, alone of .vid/round/, for the call page's
    # what is new after a restore; GM-4 §1: in GitHub auto, whose round read changes every tick and has no page that reads the one
    # before, nothing of .vid/round/ is saved, as before. Copied into the save's scratch folder by its own name ($W/sr, RP), so the copy
    # reads as one into scratch, never a record copied back over (M10 rule 1)
    if manual; then for f in read read.prev; do [ ! -f ".vid/round/$f" ] || { mkdir -p "$W/sr/round" && cp ".vid/round/$f" "$W/sr/round/$f"; } || gref "the round's $f could not be copied"; done; fi
    # GM-3 S2 (GM M15): the bundle carries refs/vid/*, the take-over commits among them; it is reused only when HEAD and they are unchanged
    HK=$(printf '%s\n' "$HD"; git for-each-ref --format='%(objectname) %(refname)' refs/vid/) || gref 'the refs under refs/vid could not be read'
    if [ -n "$T0" ]; then git -C "$RP" fetch -q "$SU" refs/heads/vid-state/records || gref "$ST could not be fetched"; fi; printf '%s\n' "$HK" > "$RP/home.head"
    if [ -n "$T0" ] && [ "$(git -C "$RP" show FETCH_HEAD:home.head 2>/dev/null)" = "$HK" ]; then git -C "$RP" show FETCH_HEAD:home.bundle > "$RP/home.bundle"; else git bundle create -q "$RP/home.bundle" --all 2>/dev/null || gref 'the project could not be bundled'; fi
    git -C "$RP" -c core.excludesFile=/dev/null add -A -f . ; TR=$(git -C "$RP" write-tree); if [ -n "$T0" ] && [ "$(git -C "$RP" rev-parse FETCH_HEAD^{tree})" = "$TR" ]; then echo "$T0" > "$W/sa" || exit 1; put .vid/state-at < "$W/sa" || exit 1; echo 'ViD github: the records are as saved'; exit 0; fi
    set -- -m 'ViD records'; [ -z "$T0" ] || set -- -p "$T0" "$@"; C=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid git -C "$RP" commit-tree "$TR" "$@") || gref 'the records could not be committed'
    git -C "$RP" push -q "$SU" "$C:refs/heads/vid-state/records" 2> "$W/e" || { sed 's/^/    /' "$W/e" >&2; gref "the records could not be pushed to $ST"; }; echo "$C" > "$W/sa" || exit 1; put .vid/state-at < "$W/sa" || exit 1; echo "ViD github: the records saved to $ST"; exit 0 ;;

  state-restore)   # v0.26.10.25.1 (R6): state-restore <repo> in an empty folder, or with no repository in a project whose records are behind the branch
    if [ -n "${1:-}" ]; then auth; stpriv "$1"; else tw; sturl; fi; T0=$(git ls-remote "$SU" refs/heads/vid-state/records 2>/dev/null | cut -f1); [ -n "$T0" ] || { [ -z "${1:-}" ] || gref "$ST holds no records"; echo 'ViD github: no records saved yet'; exit 0; }
    [ "$T0" != "$(cat .vid/state-at 2>/dev/null)" ] || { echo 'ViD github: the records are current'; exit 0; }; RP=$W/sr; mkdir "$W/rt"; git init -q "$RP"; git -C "$RP" fetch -q "$SU" refs/heads/vid-state/records && git -C "$RP" archive FETCH_HEAD | tar -x -C "$W/rt" || gref "$ST could not be read"
    if [ -e .git ]; then git fetch -q "$W/rt/home.bundle" HEAD && git merge -q --ff-only FETCH_HEAD || gref 'the project is not behind the saved one'; else [ -z "$(ls -A)" ] || gref 'state-restore <repo> takes an empty folder'; git clone -q "$W/rt/home.bundle" . && git remote remove origin || gref 'the project could not be cloned from its bundle'; fi
    git fetch -q "$W/rt/home.bundle" '+refs/vid/*:refs/vid/*' || gref 'the refs under refs/vid could not be restored from the bundle'   # GM-3 S2 (GM M15)
    # FB-1 A1: the commit checks are not switched on here: the connect's hooks step, after the restore in every start, does it once they pass
    mkdir -p .vid; for f in RUN-STATE.md budget metrics-events decide tw plans plan next results VID-FINDINGS.md; do if [ ! -e "$W/rt/$f" ]; then rm -rf ".vid/$f"; elif [ -d "$W/rt/$f" ]; then putd ".vid/$f" "$W/rt/$f" || exit 1; else put ".vid/$f" < "$W/rt/$f" || exit 1; fi; done
    # GM-4 F3 (I2), GM-2 T12: in GitHub manual alone, the one read and the read before it, as one pair: a save that holds round/ gives
    # both back (one it lacks removed); a save with no round/ leaves .vid/round/ as it is, and nothing else of .vid/round/ is ever
    # touched. GM-4 §1: in GitHub auto the restore leaves .vid/round/ as before
    if manual && [ -d "$W/rt/round" ]; then mkdir -p .vid/round; for f in read read.prev; do if [ -f "$W/rt/round/$f" ]; then put ".vid/round/$f" < "$W/rt/round/$f" || exit 1; else rm -f ".vid/round/$f"; fi; done; fi
    tw; specgit; sh "$HERE/github.sh" results-fetch > /dev/null || gref 'the code repository could not be fetched'; echo "$T0" > "$W/sa" || exit 1; put .vid/state-at < "$W/sa" || exit 1; echo "ViD github: the records restored from $ST"; exit 0 ;;

  lock-take|lock-renew|lock-free)   # v0.26.10.25.1 (R7): vid-state/lock, one parentless commit: session, machine, time. Pushed with a lease on what was read, so of two takers one wins. VID_LOCK_COLD (900 seconds)
    tw; stloc; SU=$(ghc repo view "$ST" --json url --jq .url) || gref "no access to $ST"; LR=refs/heads/vid-state/lock; LL=$(git ls-remote "$SU" "$LR" 2>/dev/null) || gref 'the lock could not be read'; LO=$(printf '%s' "$LL" | cut -f1); ME=${CLAUDE_CODE_SESSION_ID:-$(cat .vid/lock-session 2>/dev/null)}; LS=''; LA=0; RP=$W/l; git init -q "$RP"
    if [ -n "$LO" ]; then git -C "$RP" fetch -q "$SU" "$LR" || gref 'the lock could not be read'; LB=$(git -C "$RP" show FETCH_HEAD:lock); LS=$(printf '%s\n' "$LB" | sed -n 's/^session: //p'); LA=$(printf '%s\n' "$LB" | sed -n 's/^at: //p'); fi
    lpush() { printf 'session: %s\nmachine: %s\nat: %s\n' "$1" "$(hostname)" "$(date +%s)" > "$RP/lock"; git -C "$RP" add lock; C=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid git -C "$RP" commit-tree "$(git -C "$RP" write-tree)" -m 'ViD lock'); git -C "$RP" push -q "--force-with-lease=$LR:$LO" "$SU" "$C:$LR" 2>/dev/null; }
    case $CMD in
      lock-take) S=${1:-${CLAUDE_CODE_SESSION_ID:-session-$$-$(date +%s)}}; A=$(($(date +%s) - LA)); CO=${VID_LOCK_COLD:-900}; if [ -n "$LO" ] && [ "$LS" != "$S" ] && [ "$A" -lt "$CO" ]; then gref "the lock is held by $LS, ${A}s old; it may be taken in $((CO - A))s"; fi
        # GM-4 proof D2: GitHub makes the first branch pushed to an empty repository its default, and never deletes its default
        # branch; so on the repository that holds the lock (FB-1 B4: state-repo:, or else the spec repository) while it holds no
        # branch yet, a main is pushed first, one commit of no files whose message does not open "ViD export of " (ownp reads no
        # export in it; the first export fast-forwards it), and the lock is never its default branch
        if [ -z "$LO" ]; then git ls-remote --heads "$SU" > "$W/lh" 2> "$W/lhe" || gref "the branches of $ST could not be read: $(ghwhy "$W/lhe")"
          if [ ! -s "$W/lh" ]; then _e=$(git -C "$RP" hash-object -w -t tree /dev/null) && _c=$(GIT_AUTHOR_NAME=ViD GIT_AUTHOR_EMAIL=vid@export.invalid GIT_COMMITTER_NAME=ViD GIT_COMMITTER_EMAIL=vid@export.invalid git -C "$RP" commit-tree "$_e" -m "ViD's repository's default branch, so that ViD's lock is never it") || gref 'the default branch could not be made'
            git -C "$RP" push -q "$SU" "$_c:refs/heads/main" 2> "$W/lhe" || { git ls-remote --heads "$SU" 2>/dev/null | grep -q . || gref "the default branch of $ST could not be pushed: $(ghwhy "$W/lhe")"; }; fi; fi
        lpush "$S" || gref 'another session took the lock'; echo "$S" > "$W/ls" || exit 1; put .vid/lock-session < "$W/ls" || exit 1; ev "lock-taken session=$S from=${LS:-none}"; echo "ViD github: the lock is $S's" ;;
      lock-renew) lost() { echo "ViD github: refused — the lock is lost: $1" >&2; exit 3; }; [ -n "$ME" ] && [ "$LS" = "$ME" ] || lost "it is ${LS:-nobody}'s"; lpush "$ME" || { LL=$(git ls-remote "$SU" "$LR" 2>/dev/null) || gref 'the lock could not be renewed'; [ "$(printf '%s' "$LL" | cut -f1)" != "$LO" ] || gref 'the lock could not be renewed'; lost 'another session took it'; }; echo 'ViD github: the lock renewed' ;;   # exit 3 only for a loss seen; a failed call is an error like any other (R4)
      lock-free) [ -n "$ME" ] && [ "$LS" = "$ME" ] || gref "the lock is ${LS:-nobody}'s, not this session's"; git -C "$RP" push -q "--force-with-lease=$LR:$LO" "$SU" ":$LR" 2> "$W/lfe" || gref "the lock could not be freed: GitHub said: $(ghwhy "$W/lfe")"; rm -f .vid/lock-session; echo 'ViD github: the lock freed' ;;
    esac; exit 0 ;;

  comment)
    ! ownask "${1:-}" || exit 0   # FB-3 A1.6: ViD's own ask has no issue: nothing is sent
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
    ! ownask "${1:-}" || exit 0   # FB-3 A1.6
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
