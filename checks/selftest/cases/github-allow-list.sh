#!/bin/sh
# Purpose: selftest case — github.sh's allow-list and its login rule (v0.26.10.9 spec R19, R24; §5 github-allow-list; GM-4 K13: spec-stamp's read of the stamp file).
# Read: every gh call in checks/github.sh goes through ghc, each one's subcommand is on the list (0.26.10.28.1, the first
# ticket mode's calls removed with it: gh auth status, repo view, label create, issue create|edit|view|list|comment|
# close, pr view|list|comment, repo create (v0.26.10.12.3 R2), api for milestones and an issue comment's edit
# (v0.26.10.12.3 fix 3: -X PATCH alone, the code repository's alone), and 0.26.10.28.7's share forms (api user, users/<WHO>,
# orgs/<SOWN>/memberships/<LOGIN>, repos/<SREPO>/collaborators/<WHO> and repos/<SREPO>/invitations), GM-2 T3's three (the read
# of an issue's id, repos/$REPO/issues/<n>; and, under FORMPOST, which the file sets empty first (as it does RECREAD and RR, record-read's), -X POST of one -F field to an
# issue's sub_issues, sub_issue_id, and to its dependencies/blocked_by, issue_id), and IR I1's record-read forms (GETs of the
# linked repository's pulls/<N>, pulls/<N>/files and contents/<path>?ref=<sha>); no other line calls gh; the file holds no
# `auth token` and no `--with-token`. Run: comment, label and close log only listed calls; with gh auth status failing,
# each of them stops after that one call; each of the ten removed subcommands is a usage error that calls no gh. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "github-allow-list: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
OK='auth status|repo view|repo create|label create|issue create|issue edit|issue view|issue list|issue comment|issue close|pr view|pr list|pr comment|api -X|api "repos/\$REPO/milestones"'
# 0.26.10.28.7 (R6): the share's own forms, exactly these (share-allow proves each is tied to its one target)
# GM-1 S6: round-read --bodies's one new call (GM-4 F3), a GET of an issue's sub-issues (next-read checks it is refused with any method but GET or a field)
OK="$OK"'|api "repos/\$REPO/issues/\$p/sub_issues"'
# GM-2 T3: the read of an issue's id, for the links of a first post in the form (its POSTs are api -X, checked below)
OK="$OK"'|api "repos/\$REPO/issues/\$b"|api "repos/\$REPO/issues/\$N"'
# IR I1: record-read's three GETs of the linked repository (github-record-read checks each is a read, with no method or field)
OK="$OK"'|api "repos/\$RR/pulls/\$N"|api "repos/\$RR/pulls/\$N/files"|api "repos/\$RR/contents/\$q\?ref=\$H"'
OK="$OK"'|api user|api "users/\$WHO"|api "orgs/\$SOWN/memberships/\$LOGIN"|api "repos/\$SREPO/collaborators/\$WHO"|api "repos/\$SREPO/invitations"'
# GM-4 K1: issue reopen, tw-reopen's; GM-4 K13: pr create, spec-publish's alone (its git data calls are api -X), under SPUB, which the file sets empty first
OK="$OK"'|issue reopen|pr create'
# FB-1 B1: pr close, spec-publish's alone, for an older folder pull request it replaces, under SPUB as pr create is
OK="$OK"'|pr close'
# GM-4 K13: spec-stamp's one read, a GET of the stamp file on the code repository's main, under STAMPREAD, which the file sets empty first
OK="$OK"'|api "repos/\$REPO/contents/\$SPF\?ref=\$SMN"'
# FB-3 B1: the publish's read of the folder's names and ids, a GET of a tree, under SPUB
OK="$OK"'|api "repos/\$REPO/git/trees/\$FT"|api "repos/\$REPO/git/trees/\$FT\?recursive=1"'
# FB-4 B1: and spec-folder's, under FOLDREAD, which the file sets empty first
grep -q "^FOLDREAD=''" "$GS" && grep -q '{ \[ "\${SPUB:-}" = yes \] || \[ "\${FOLDREAD:-}" = yes \]; } && \[ -z "\$_fl" \] && \[ -z "\$_in" \]' "$GS" || fail "a tree's read is not limited to spec-publish and spec-folder, as a read alone"
# FB-3 A2, A1.4: one graphql query, results-fetch's and closing-prs', under RESREAD, which the file sets empty first
OK="$OK"'|api graphql'
grep -q "^RESREAD=''" "$GS" && grep -q '\[ "\${RESREAD:-}" = yes \] && \[ -z "\$_m\$_fv\$_in" \] && \[ "\$_fn" = 1 \]' "$GS" || fail 'gh api graphql is not limited to one query, under RESREAD'
# FB-3 A1.4: pr-files' read of a pull request's files, under PRREAD, which the file sets empty first
OK="$OK"'|api "repos/\$REPO/pulls/\$1/files\?per_page=100"'
grep -q "^PRREAD=''" "$GS" && grep -q '\[ "\${PRREAD:-}" = yes \] && \[ -z "\$_fl" \]' "$GS" || fail "a pull request's files are not limited to pr-files' read"
grep -q "^STAMPREAD=''; SPF=''; SMN=''" "$GS" || fail 'STAMPREAD is not set empty before any call'
grep -q '"repos/\$REPO/contents/"\*) \[ "\${STAMPREAD:-}" = yes \]' "$GS" || fail "the code repository's contents are not limited to spec-stamp's read"
grep -q "^REPO=''; SHARE=''; .*SPUB=''" "$GS" || fail 'SPUB is not set empty before any call'
grep -q "'pr create') \[ \"\${SPUB:-}\" = yes \] || gref" "$GS" || fail 'gh pr create is not limited to spec-publish'
grep -q "'pr close') \[ \"\${SPUB:-}\" = yes \] || gref" "$GS" || fail 'gh pr close is not limited to spec-publish'
grep -v '^[[:space:]]*#' "$GS" | grep -oE 'ghc [a-z"-][^ ]* [^ ]*' | sed 's/^ghc //' | awk '{ print $1 " " $2 }' | sort -u > "$T/calls"
[ -s "$T/calls" ] || fail 'no ghc call found — the case reads nothing'
while IFS= read -r c; do printf '%s\n' "$c" | grep -qxE "$OK" || fail "a gh call off the list: ghc $c"; done < "$T/calls"
grep -v '^[[:space:]]*#' "$GS" | grep -nE '(^|[;&|(]|\$\()[[:space:]]*gh[[:space:]]' > "$T/raw" || true
[ "$(grep -c . "$T/raw")" = 1 ] && grep -q 'gh "\$@"' "$T/raw" || { cat "$T/raw" >&2; fail 'gh is called outside ghc'; }
# the issue comment's edit (fix 3): only repos/$REPO/issues/comments/<digits>, only with -X PATCH, called only so
grep -q '"repos/\$REPO/issues/comments/"\[0-9\]\*) case "\${_p##\*/}" in \*\[!0-9\]\*) gref' "$GS" && grep -q '\[ "\$_m" = PATCH \] || gref' "$GS" || fail 'the issue comment edit is not limited to -X PATCH on the code repository'
[ "$(grep -v '^[[:space:]]*#' "$GS" | grep -c 'issues/comments/\$')" = 1 ] && grep -q 'ghc api -X PATCH "repos/\$REPO/issues/comments/\$c" -F ' "$GS" || fail 'an issue comment is reached other than by its edit'
# GM-2 T3: the form post's two links, each -X POST of its one -F field, only under FORMPOST, which no environment sets
grep -q "^REPO=''; SHARE=''; .*FORMPOST=''" "$GS" || fail 'FORMPOST is not set empty before any call'
# IR I1: nor record-read's mode and repository, RECREAD and RR, set empty on the same line
grep "^REPO=''; SHARE=''; " "$GS" | grep -q " RECREAD='';" && grep "^REPO=''; SHARE=''; " "$GS" | grep -q " RR=''" || fail 'RECREAD or RR is not set empty before any call'
[ "$(grep -v '^[[:space:]]*#' "$GS" | grep -c 'FORMPOST=yes ghc api -X POST "repos/\$REPO/issues/\$[A-Za-z]*/sub_issues" -F "sub_issue_id=\$ID"')" = 1 ] || fail 'the sub-issue link is not one -X POST of -F sub_issue_id under FORMPOST'
[ "$(grep -v '^[[:space:]]*#' "$GS" | grep -c 'FORMPOST=yes ghc api -X POST "repos/\$REPO/issues/\$[A-Za-z]*/dependencies/blocked_by" -F "issue_id=\$[A-Za-z]*"')" = 2 ] || fail 'the blocked-by links are not -X POST of -F issue_id under FORMPOST'
[ "$(grep -v '^[[:space:]]*#' "$GS" | grep -c 'sub_issues"* -F\|blocked_by"* -F')" = "$(grep -v '^[[:space:]]*#' "$GS" | grep -c 'FORMPOST=yes ghc api -X POST')" ] || fail 'a link is posted outside FORMPOST'
grep -q 'auth token' "$GS" && fail 'the file holds "auth token"'
grep -q -- '--with-token' "$GS" && fail 'the file holds "--with-token"'
# a run logs only listed calls
gh_vid "$T/vid"; V=$(pwd -P); printf 'x\n' > "$T/f"
mkdir -p "$T/gh/issues/1/comments"; echo OPEN > "$T/gh/issues/1/state"
sh checks/github.sh comment 1 --body-file "$T/f" > "$T/out" 2>&1 || fail 'comment failed'
sh checks/github.sh label 1 --add ready > "$T/out" 2>&1 || fail 'label failed'
sh checks/github.sh close 1 > "$T/out" 2>&1 || fail 'close failed'
LOK='auth status|repo view|label create|issue create|issue edit|issue view|issue list|issue comment|issue close|pr view|pr list|pr comment|api repos/owner/code/milestones|api -X'
awk '{ print $2 " " $3 }' "$T/gh/log" | sort -u | while IFS= read -r c; do printf '%s\n' "$c" | grep -qxE "$LOK" || { echo "$c"; exit 1; }; done > "$T/out" || fail "a logged call off the list: $(cat "$T/out")"
# a failing login stops every subcommand after its one call
touch "$T/gh/auth-fail"
stops() { _d=$1; shift; _n=$(wc -l < "$T/gh/log"); if ( cd "$_d" && sh "$GS" "$@" ) > "$T/out" 2>&1; then fail "$* ran with a failing login"; fi
  [ "$(sed -n "$((_n + 1)),\$p" "$T/gh/log" | paste -sd '|' -)" = 'gh auth status' ] || fail "$* called more than gh auth status: $(sed -n "$((_n + 1)),\$p" "$T/gh/log" | paste -sd '|' -)"; }
stops "$V" comment 1 --body-file "$T/f"; stops "$V" label 1 --add ready; stops "$V" close 1; stops "$V" close --milestone 1 --commit abc
rm -f "$T/gh/auth-fail"
# the first ticket mode's subcommands are gone: a usage error, no gh call
for a in publish pull run-full session clone next-ticket claim push review merge; do
  _n=$(wc -l < "$T/gh/log"); _st=0; ( cd "$V" && sh "$GS" "$a" ) > "$T/out" 2>&1 || _st=$?
  [ "$_st" = 2 ] && grep -q '^ViD github: usage' "$T/out" || fail "the removed subcommand $a is not a usage error (exit $_st)"
  [ "$(wc -l < "$T/gh/log")" = "$_n" ] || fail "the removed subcommand $a called gh"
done
exit 0
