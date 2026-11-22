#!/bin/sh
# Purpose: selftest case — a folder publish's failing git data call says what GitHub replied (the GM-4 proof's D6). On the form
# fixture's toy (fixtures/form.sh) with `layout: one` and `spec-path: upstream/vid`, after the export: a blob call GitHub refuses,
# and the folder's tree call GitHub refuses, each end the publish unfinished (exit 5, FB-1 B5: a failed call, tried again) with a
# line that carries GitHub's reply; a tree GitHub makes that is not the one the export holds ends it with a refusal (exit 1) naming
# both trees. FB-1 B5: main's tree with the folder, the commit call and the branch call failing once each also exit 5. Nothing is
# posted (no branch, no pull request). Then the pull request failing once leaves the branch standing (exit 1), and its move failing
# once exits 5 too. Each exit 5 leaves .vid/tw/spec-owed holding the export; the call again, with GitHub answering, publishes and
# removes it, as does the one line, exit 0, of a code repository with no main. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-reply: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
C=$T/code.git
# the fake gh: while $T/fail-<blobs|trees|toptree|commits|refs|move|prcreate> exists, that call fails once with GitHub's words (toptree:
# main's tree with the folder, the tree call holding a base_tree; move: the PATCH of a branch already standing; prcreate: gh pr create); while $T/wrong-trees exists, the tree call answers once with another tree
mv "$T/bin/gh" "$T/bin/gh-fake"
cat > "$T/bin/gh" <<WRAP
#!/bin/sh
i=''; n=''; for a; do [ -z "\$n" ] || { i=\$a; n=''; }; case \$a in --input) n=1 ;; */git/blobs) k=blobs ;; */git/trees) k=trees ;; */git/commits) k=commits ;; */git/refs/heads/*) k=move ;; */git/refs) k=refs ;; esac; done
[ "\$1 \${2:-}" != 'pr create' ] || k=prcreate
[ "\${k:-}" != trees ] || ! grep -q base_tree "\$i" 2>/dev/null || k=toptree
if [ -n "\${k:-}" ] && [ -f "$T/fail-\$k" ]; then rm -f "$T/fail-\$k"; echo "gh: GitObject \$k refused for the self-test (HTTP 422)" >&2; exit 1; fi
if [ "\${k:-}" = trees ] && [ -f "$T/wrong-trees" ]; then rm -f "$T/wrong-trees"; echo 4b825dc642cb6eb9a060e54bf8d69288fbee4904; exit 0; fi
exec "$T/bin/gh-fake" "\$@"
WRAP
chmod +x "$T/bin/gh"
sp() { RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; }
posted() { git --git-dir="$C" for-each-ref 'refs/heads/vid-spec/*' | grep -q . || ls "$FAKEGH/prs" 2>/dev/null | grep -q .; }
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'; E12=$(awk '$1 == "export" { v = $2 } END { print substr(v, 1, 12) }' .vid/tw/log)
touch "$T/fail-blobs"; sp; [ "$RC" = 5 ] || fail "a refused blob call exited $RC, not 5"
tail -n 1 "$T/out" | grep -q 'GitObject blobs refused for the self-test (HTTP 422)' || fail "the refused blob call's line does not carry GitHub's reply"
touch "$T/fail-trees"; sp; [ "$RC" = 5 ] || fail "a refused tree call exited $RC, not 5"
tail -n 1 "$T/out" | grep -q "the folder's tree could not be made.*GitObject trees refused for the self-test (HTTP 422)" || fail "the refused tree call's line does not carry GitHub's reply"
owed() { [ "$(cat .vid/tw/spec-owed 2>/dev/null)" = "$E12" ] || fail "after $1, .vid/tw/spec-owed does not hold the export"; }
owed 'a failed tree call'
for k in toptree commits refs; do touch "$T/fail-$k"; sp; [ "$RC" = 5 ] || fail "a failed $k call exited $RC, not 5"; [ ! -f "$T/fail-$k" ] || fail "the scene is wrong: no $k call was made"; owed "a failed $k call"
  tail -n 1 "$T/out" | grep -q "GitObject $k refused for the self-test (HTTP 422)" || fail "the failed $k call's line does not carry GitHub's reply"; done
touch "$T/wrong-trees"; sp; [ "$RC" = 1 ] || fail "another tree from GitHub exited $RC"
tail -n 1 "$T/out" | grep -q "the folder's tree could not be made.*4b825dc642cb.*[0-9a-f]\{12\}" || fail 'a tree that is not the export'"'"'s is not named beside the export'"'"'s'
! posted || fail 'a failed publish posted a branch or a pull request'
# the pull request failing once after the branch is made (exit 1, the branch standing), then the branch's move failing once: exit 5
touch "$T/fail-prcreate"; sp; [ "$RC" = 1 ] && [ ! -f "$T/fail-prcreate" ] || fail "the scene is wrong: the pull request's failure exited $RC"
git --git-dir="$C" rev-parse -q --verify "refs/heads/vid-spec/$E12" > /dev/null || fail 'the scene is wrong: the branch was not left standing'
touch "$T/fail-move"; sp; [ "$RC" = 5 ] || fail "a failed move of the standing branch exited $RC, not 5"; [ ! -f "$T/fail-move" ] || fail 'the scene is wrong: no move was made'
tail -n 1 "$T/out" | grep -q "GitObject move refused for the self-test (HTTP 422)" || fail "the failed move's line does not carry GitHub's reply"; owed 'a failed move of the branch'
sp; [ "$RC" = 0 ] || fail "the call again, with GitHub answering, exited $RC"
grep -q '^spec-published ' .vid/tw/log || fail 'the call again logged no spec-published line'
[ ! -f .vid/tw/spec-owed ] || fail 'the marker stayed after the call again published'
# a code repository with no main: the one line, exit 0, and a standing marker gone
echo 'A new line for the spec.' >> PRD.md; g commit -qam 'the spec changed'; git rev-parse HEAD > .vid/tw/applied; sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the second export failed'
echo 0123456789ab > .vid/tw/spec-owed; git init -q --bare "$T/empty.git"; echo "$T/empty.git" > "$FAKEGH/remote"; git --git-dir=.vid/code update-ref -d refs/heads/main
sp; [ "$RC" = 0 ] && grep -q 'no main' "$T/out" || fail "with no main the publish did not exit 0 naming it ($RC)"
[ ! -f .vid/tw/spec-owed ] || fail 'the marker stayed after the no-main call, which exits 0'
echo 'spec-publish-reply: ok'
