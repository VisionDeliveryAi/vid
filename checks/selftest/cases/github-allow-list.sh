#!/bin/sh
# Purpose: selftest case — github.sh's allow-list and its login rule (v0.26.10.9 spec R19, R24; §5 github-allow-list).
# Read: every gh call in checks/github.sh goes through ghc, each one's subcommand is on the list (gh auth status, repo
# view|clone, label, issue create|edit|view|list|comment|close|reopen, pr create|edit|view|list|ready|comment|merge|
# checks|diff, run list|view|download, workflow run (v0.26.10.12 R3), repo create (v0.26.10.12.3 R2), api for milestones,
# the sub-issue mutation and an issue comment's edit (v0.26.10.12.3 fix 3: -X PATCH alone, the code repository's alone));
# no other line calls gh; the
# file holds no `auth token` and no `--with-token`. Run: a publish and a pull log only listed calls; with gh auth status
# failing, every subcommand — the planner's and the stand-in's — stops after that one call; push, claim and merge in a
# checkout whose RUN-STATE says mode: tickets are refused before any gh call. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "github-allow-list: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
OK='auth status|repo view|repo create|repo clone|label create|issue create|issue edit|issue view|issue list|issue comment|issue close|issue reopen|pr create|pr edit|pr view|pr list|pr ready|pr comment|pr merge|pr checks|pr diff|run list|run view|run download|workflow run|api graphql|api -X|api "repos/\$REPO/milestones"'
grep -v '^[[:space:]]*#' "$GS" | grep -oE 'ghc [a-z"-][^ ]* [^ ]*' | sed 's/^ghc //' | awk '{ print $1 " " $2 }' | sort -u > "$T/calls"
[ -s "$T/calls" ] || fail 'no ghc call found — the case reads nothing'
while IFS= read -r c; do printf '%s\n' "$c" | grep -qxE "$OK" || fail "a gh call off the list: ghc $c"; done < "$T/calls"
grep -v '^[[:space:]]*#' "$GS" | grep -nE '(^|[;&|(]|\$\()[[:space:]]*gh[[:space:]]' > "$T/raw" || true
[ "$(grep -c . "$T/raw")" = 1 ] && grep -q 'gh "\$@"' "$T/raw" || { cat "$T/raw" >&2; fail 'gh is called outside ghc'; }
# the issue comment's edit (fix 3): only repos/$REPO/issues/comments/<digits>, only with -X PATCH, called only so
grep -q '"repos/\$REPO/issues/comments/"\[0-9\]\*) case "\${_p##\*/}" in \*\[!0-9\]\*) gref' "$GS" && grep -q '\[ "\$_m" = PATCH \] || gref' "$GS" || fail 'the issue comment edit is not limited to -X PATCH on the code repository'
[ "$(grep -v '^[[:space:]]*#' "$GS" | grep -c 'issues/comments/\$')" = 1 ] && grep -q 'ghc api -X PATCH "repos/\$REPO/issues/comments/\$c" -F ' "$GS" || fail 'an issue comment is reached other than by its edit'
grep -q 'auth token' "$GS" && fail 'the file holds "auth token"'
grep -q -- '--with-token' "$GS" && fail 'the file holds "--with-token"'
# a run logs only listed calls
gh_vid "$T/vid"; V=$(pwd -P)
sh checks/ticket.sh skeleton-body --req REQ-001 > /dev/null 2>&1; sh checks/github.sh publish --ticket .vid/tickets/skeleton.md > "$T/out" 2>&1 || fail 'publish failed'
sh checks/github.sh pull > "$T/out" 2>&1 || fail 'pull failed'
LOK='auth status|repo view|repo create|repo clone|label create|issue create|issue edit|issue view|issue list|issue comment|issue close|issue reopen|pr create|pr edit|pr view|pr list|pr ready|pr comment|pr merge|pr checks|pr diff|run list|run view|run download|workflow run|api graphql|api repos/owner/code/milestones|api -X'
awk '{ print $2 " " $3 }' "$T/gh/log" | sort -u | while IFS= read -r c; do printf '%s\n' "$c" | grep -qxE "$LOK" || { echo "$c"; exit 1; }; done > "$T/out" || fail "a logged call off the list: $(cat "$T/out")"
gh_worker "$T/w1" || fail 'the clone failed'
# a failing login stops every subcommand after its one call
touch "$T/gh/auth-fail"; printf 'x\n' > "$T/f"
stops() { _d=$1; shift; _n=$(wc -l < "$T/gh/log"); if ( cd "$_d" && sh "$GS" "$@" ) > "$T/out" 2>&1; then fail "$* ran with a failing login"; fi
  [ "$(sed -n "$((_n + 1)),\$p" "$T/gh/log" | paste -sd '|' -)" = 'gh auth status' ] || fail "$* called more than gh auth status: $(sed -n "$((_n + 1)),\$p" "$T/gh/log" | paste -sd '|' -)"; }
stops "$V" publish; stops "$V" pull; stops "$V" run-full; stops "$V" comment 1 --body-file "$T/f"; stops "$V" label 1 --add ready; stops "$V" close 1; stops "$V" close --milestone 1 --commit abc
stops "$T/w1" session --verb x; stops "$T/w1" next-ticket --worker 1; stops "$T/w1" claim 1 --worker 1; stops "$T/w1" push vid/1; stops "$T/w1" review 1; stops "$T/w1" merge 1; stops "$T" clone owner/code "$T/w9"
rm -f "$T/gh/auth-fail"
# the stand-in's writes under mode: tickets
for a in 'push vid/1' 'claim 1 --worker 1' 'merge 1'; do
  _n=$(wc -l < "$T/gh/log")
  if ( cd "$V" && IFS=' ' && sh "$GS" $a ) > "$T/out" 2>&1; then fail "$a ran under mode: tickets"; fi
  grep -q 'mode: tickets' "$T/out" || fail "the refusal of $a does not name mode: tickets"
  [ "$(wc -l < "$T/gh/log")" = "$_n" ] || fail "$a called gh under mode: tickets"
done
exit 0
