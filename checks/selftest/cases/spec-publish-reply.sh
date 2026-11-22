#!/bin/sh
# Purpose: selftest case — a folder publish's failing GitHub call says what GitHub replied (the GM-4 proof's D6) and leaves the call
# unfinished, tried again (FB-2 B1: in spec-publish, a refusal right after a failed GitHub or git network call is exit 5, the marker,
# the reply on the line), the line kept in .vid/tw/log (FB-2 B2: `spec-failed export=<12> at=<t> why="<the line>"`). On the form
# fixture's toy (fixtures/form.sh) with `layout: one` and `spec-path: upstream/vid`, after the export: `gh auth status` failing with
# gh's neutral words, and the spec repository's `gh repo view`, each exit 5, the marker holding the log's newest export; gh's "not
# logged into any" words stay a refusal (exit 1, no line logged). A blob call GitHub refuses, the folder's tree call, main's tree
# with the folder, the commit call and the branch call each end the publish unfinished (exit 5, FB-1 B5) with a line that carries
# GitHub's reply; a tree GitHub makes that is not the one the export holds ends it with a refusal (exit 1, no line logged) naming
# both trees. Nothing is posted (no branch, no pull request). Then the branch read's `git ls-remote`, the open pull requests' read
# (`gh pr list --head`), the pull request's create, the standing branch's move, the publish ticket's label and its issue each fail
# once: exit 5, and (FB-2 B1) the spec repository's git fetch, the spec repository holding main, failing once: exit 5 with git's
# words. Each exit 5 leaves .vid/tw/spec-owed holding the export and one spec-failed line with the export and the words; the
# call again, with GitHub answering, publishes, makes the ticket and removes the marker. For a second export, main's fetch into
# .vid/code failing while GitHub has main: exit 5 too, and (FB-2 B1) with the git ls-remote of main failing as well, the
# ls-remote's words on the line; the one line, exit 0, of a code repository with no main removes the marker.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-reply: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
C=$T/code.git
# the fake gh: while $T/fail-<blobs|trees|toptree|commits|refs|move|prcreate|prlist|label|issue|specview> exists, that call fails once
# with GitHub's words (toptree: main's tree with the folder, the tree call holding a base_tree; move: the PATCH of a branch already
# standing; prcreate, prlist, label, issue: gh pr create, gh pr list, gh label create, gh issue create; specview: gh repo view of the
# spec repository); while $T/fail-auth exists, gh auth status fails once with gh's neutral words; while $T/wrong-trees exists, the
# tree call answers once with another tree
mv "$T/bin/gh" "$T/bin/gh-fake"
cat > "$T/bin/gh" <<WRAP
#!/bin/sh
i=''; n=''; k=''; for a; do [ -z "\$n" ] || { i=\$a; n=''; }; case \$a in --input) n=1 ;; */git/blobs) k=blobs ;; */git/trees) k=trees ;; */git/commits) k=commits ;; */git/refs/heads/*) k=move ;; */git/refs) k=refs ;; esac; done
case "\$1 \${2:-}" in 'pr create') k=prcreate ;; 'pr list') k=prlist ;; 'label create') k=label ;; 'issue create') k=issue ;; 'repo view') [ "\${3:-}" != owner/code-spec ] || k=specview ;; esac
[ "\$k" != trees ] || ! grep -q base_tree "\$i" 2>/dev/null || k=toptree
if [ "\$1 \${2:-}" = 'auth status' ] && [ -f "$T/fail-auth" ]; then rm -f "$T/fail-auth"; echo 'error connecting to api.github.com' >&2; exit 1; fi
if [ -n "\$k" ] && [ -f "$T/fail-\$k" ]; then rm -f "$T/fail-\$k"; echo "gh: GitObject \$k refused for the self-test (HTTP 422)" >&2; exit 1; fi
if [ "\$k" = trees ] && [ -f "$T/wrong-trees" ]; then rm -f "$T/wrong-trees"; echo 4b825dc642cb6eb9a060e54bf8d69288fbee4904; exit 0; fi
exec "$T/bin/gh-fake" "\$@"
WRAP
# the git before it: while $T/fail-lsbranch exists, the branch read (git ls-remote of refs/heads/vid-spec/…) fails once; while
# $T/fail-mainfetch exists, results-fetch's fetch of the commits into .vid/code fails once; FB-2 B1: while $T/fail-specfetch
# exists, a fetch from the spec repository's address fails once; while $T/fail-lsmain exists, the git ls-remote of main from the
# code repository's address fails once
RG=$(command -v git); SU=$(cat "$FAKEGH/repos/owner%code-spec/remote") && [ -n "$SU" ] || fail 'the scene is wrong: the spec repository has no address'
CU=$(cat "$FAKEGH/remote") && [ -n "$CU" ] || fail 'the scene is wrong: the code repository has no address'
cat > "$T/bin/git" <<WRAP
#!/bin/sh
k=''; l=''; f=''; m=''; u=''; for a; do case \$a in ls-remote) l=1 ;; fetch) f=1 ;; refs/heads/main) m=1 ;; refs/heads/vid-spec/*) [ -z "\$l" ] || k=lsbranch ;; vid-commits) k=mainfetch ;; esac
  [ "\$a" != "$SU" ] || u=spec; [ "\$a" != "$CU" ] || u=code; done
[ -z "\$f" ] || [ "\$u" != spec ] || k=specfetch
[ -z "\$l" ] || [ -z "\$m" ] || [ "\$u" != code ] || k=lsmain
if [ -n "\$k" ] && [ -f "$T/fail-\$k" ]; then rm -f "$T/fail-\$k"; echo "fatal: the remote could not be reached for the self-test (\$k)" >&2; exit 128; fi
exec "$RG" "\$@"
WRAP
chmod +x "$T/bin/gh" "$T/bin/git"
sp() { RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; }
posted() { git --git-dir="$C" for-each-ref 'refs/heads/vid-spec/*' | grep -q . || ls "$FAKEGH/prs" 2>/dev/null | grep -q .; }
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'; E12=$(awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' .vid/tw/log)
owed() { [ "$(cat .vid/tw/spec-owed 2>/dev/null)" = "$E12" ] || fail "after $1, .vid/tw/spec-owed does not hold the export"; }
# FB-2 B2: sf <scene> <words>: one spec-failed line more, naming the export and carrying the words; nsf <scene>: none more
NF=0; sfn() { grep -c '^spec-failed ' .vid/tw/log 2>/dev/null || true; }
sf() { n=$(sfn); [ "$n" = $((NF + 1)) ] || fail "after $1, .vid/tw/log holds $n spec-failed lines, not $((NF + 1))"; NF=$n
  grep '^spec-failed ' .vid/tw/log | tail -n 1 | grep -q "^spec-failed export=$E12 at=[^ ]* why=\".*$2.*\"\$" || fail "after $1, the spec-failed line lacks the export or the words: $(grep '^spec-failed ' .vid/tw/log | tail -n 1)"; }
nsf() { [ "$(sfn)" = "$NF" ] || fail "after $1, a spec-failed line was logged"; }
# u <scene> <words>: the call unfinished — exit 5, its last line carrying the words, the marker, the spec-failed line
u() { [ "$RC" = 5 ] || fail "$1 exited $RC, not 5"; tail -n 1 "$T/out" | grep -q "$2" || fail "the line of $1 does not carry the reply"; owed "$1"; sf "$1" "$2"; }
# the start's gh auth status: gh's neutral words a failed call, its not-logged-in words a refusal; the spec repository's read
touch "$T/fail-auth"; sp; [ ! -f "$T/fail-auth" ] || fail 'the scene is wrong: no auth status call was made'; u 'a failed auth status' 'error connecting to api.github.com'
touch "$FAKEGH/auth-fail"; sp; rm -f "$FAKEGH/auth-fail"; [ "$RC" = 1 ] || fail "gh's not-logged-in words exited $RC, not 1"; nsf "gh's not-logged-in words"
touch "$T/fail-specview"; sp; [ ! -f "$T/fail-specview" ] || fail 'the scene is wrong: no read of the spec repository'; u "a failed read of the spec repository" 'GitObject specview refused for the self-test'
touch "$T/fail-blobs"; sp; u 'a refused blob call' 'GitObject blobs refused for the self-test (HTTP 422)'
touch "$T/fail-trees"; sp; u 'a refused tree call' "the folder's tree could not be made.*GitObject trees refused for the self-test (HTTP 422)"
for k in toptree commits refs; do touch "$T/fail-$k"; sp; [ ! -f "$T/fail-$k" ] || fail "the scene is wrong: no $k call was made"; u "a failed $k call" "GitObject $k refused for the self-test (HTTP 422)"; done
touch "$T/wrong-trees"; sp; [ "$RC" = 1 ] || fail "another tree from GitHub exited $RC"; nsf 'another tree from GitHub'
tail -n 1 "$T/out" | grep -q "the folder's tree could not be made.*4b825dc642cb.*[0-9a-f]\{12\}" || fail 'a tree that is not the export'"'"'s is not named beside the export'"'"'s'
touch "$T/fail-lsbranch"; sp; [ ! -f "$T/fail-lsbranch" ] || fail 'the scene is wrong: no read of the branch'; u "a failed read of the branch" 'the remote could not be reached for the self-test (lsbranch)'
! posted || fail 'a failed publish posted a branch or a pull request'
# after the branch is made: the open pull requests' read, then the pull request's create, then the standing branch's move
touch "$T/fail-prlist"; sp; [ ! -f "$T/fail-prlist" ] || fail 'the scene is wrong: no read of the open pull requests'; u "a failed read of the open pull requests" 'GitObject prlist refused for the self-test'
git --git-dir="$C" rev-parse -q --verify "refs/heads/vid-spec/$E12" > /dev/null || fail 'the scene is wrong: the branch was not left standing'
touch "$T/fail-prcreate"; sp; [ ! -f "$T/fail-prcreate" ] || fail 'the scene is wrong: no pull request was asked for'; u "a failed pull request" 'GitObject prcreate refused for the self-test'
! grep -q '^spec-published ' .vid/tw/log || fail 'a publish with no pull request was logged'
touch "$T/fail-move"; sp; [ ! -f "$T/fail-move" ] || fail 'the scene is wrong: no move was made'; u 'a failed move of the branch' 'GitObject move refused for the self-test (HTTP 422)'
# the publish ticket: its label, then its issue
touch "$T/fail-label"; sp; [ ! -f "$T/fail-label" ] || fail 'the scene is wrong: no label was made'; u "a failed label of the publish ticket" 'GitObject label refused for the self-test'
grep -q '^spec-published ' .vid/tw/log || fail 'the pull request made, its publish was not logged before the ticket'
touch "$T/fail-issue"; sp; [ ! -f "$T/fail-issue" ] || fail 'the scene is wrong: no publish ticket was asked for'; u "a failed publish ticket" 'GitObject issue refused for the self-test'
# FB-2 B1: the spec repository holding main (the export pushed it), its fetch failing once: unfinished, git's words on the line
git --git-dir=.vid/spec.git ls-remote "$SU" refs/heads/main | grep -q . || fail 'the scene is wrong: the spec repository holds no main'
touch "$T/fail-specfetch"; sp; [ ! -f "$T/fail-specfetch" ] || fail 'the scene is wrong: the spec repository was not fetched'
u 'a failed fetch of the spec repository' 'the spec repository owner/code-spec could not be fetched.*the remote could not be reached for the self-test (specfetch)'
sp; [ "$RC" = 0 ] || fail "the call again, with GitHub answering, exited $RC"
grep -q '^spec-ticket pr=[0-9]* issue=[0-9]* at=' .vid/tw/log || fail 'the call again logged no spec-ticket line'
[ ! -f .vid/tw/spec-owed ] || fail 'the marker stayed after the call again published'
# a second export, main not in .vid/code and its fetch failing while GitHub has main: unfinished, never a refusal
echo 'A new line for the spec.' >> PRD.md; g commit -qam 'the spec changed'; git rev-parse HEAD > .vid/tw/applied; sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the second export failed'
E12=$(awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' .vid/tw/log); git --git-dir=.vid/code update-ref -d refs/heads/main
touch "$T/fail-mainfetch"; sp; [ ! -f "$T/fail-mainfetch" ] || fail 'the scene is wrong: main was not fetched'; u "a failed fetch of main" 'could not be fetched'
# FB-2 B1: main's fetch failing and then the ls-remote of main failing with its own words: the ls-remote's words on the line
touch "$T/fail-mainfetch" "$T/fail-lsmain"; sp; [ ! -f "$T/fail-mainfetch" ] && [ ! -f "$T/fail-lsmain" ] || fail 'the scene is wrong: main was not fetched, or not read by git ls-remote'
u 'a failed fetch of main and a failed read of main' 'the remote could not be reached for the self-test (lsmain)'
# a code repository with no main: the one line, exit 0, and a standing marker gone
echo 0123456789ab > .vid/tw/spec-owed; git init -q --bare "$T/empty.git"; echo "$T/empty.git" > "$FAKEGH/remote"; git --git-dir=.vid/code update-ref -d refs/heads/main
sp; [ "$RC" = 0 ] && grep -q 'no main' "$T/out" || fail "with no main the publish did not exit 0 naming it ($RC)"
[ ! -f .vid/tw/spec-owed ] || fail 'the marker stayed after the no-main call, which exits 0'
echo 'spec-publish-reply: ok'
