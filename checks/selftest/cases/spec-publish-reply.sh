#!/bin/sh
# Purpose: selftest case — a folder publish's failing git data call says what GitHub replied (the GM-4 proof's D6). On the form
# fixture's toy (fixtures/form.sh) with `layout: one` and `spec-path: upstream/vid`, after the export: a blob call GitHub refuses,
# and the folder's tree call GitHub refuses, each end the publish with a refusal whose line carries GitHub's reply; a tree GitHub
# makes that is not the one the export holds ends it with a line naming both trees. Nothing is posted (no branch, no pull
# request), and the call again, with GitHub answering, publishes. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "spec-publish-reply: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
fm_toy "$T/toy" || fail 'the toy could not be made'
grep -v '^layout:' .vid/tw/settings > "$T/s"; printf 'layout: one\nspec-path: upstream/vid\n' >> "$T/s"; cat "$T/s" > .vid/tw/settings
C=$T/code.git
# the fake gh: while $T/fail-<blobs|trees> exists, that git data call fails once with GitHub's words; while $T/wrong-trees exists,
# the tree call answers once with another tree
mv "$T/bin/gh" "$T/bin/gh-fake"
cat > "$T/bin/gh" <<WRAP
#!/bin/sh
for a; do case \$a in */git/blobs) k=blobs ;; */git/trees) k=trees ;; esac; done
if [ -n "\${k:-}" ] && [ -f "$T/fail-\$k" ]; then rm -f "$T/fail-\$k"; echo "gh: GitObject \$k refused for the self-test (HTTP 422)" >&2; exit 1; fi
if [ "\${k:-}" = trees ] && [ -f "$T/wrong-trees" ]; then rm -f "$T/wrong-trees"; echo 4b825dc642cb6eb9a060e54bf8d69288fbee4904; exit 0; fi
exec "$T/bin/gh-fake" "\$@"
WRAP
chmod +x "$T/bin/gh"
sp() { RC=0; sh "$GS" spec-publish > "$T/out" 2>&1 || RC=$?; }
posted() { git --git-dir="$C" for-each-ref 'refs/heads/vid-spec/*' | grep -q . || ls "$FAKEGH/prs" 2>/dev/null | grep -q .; }
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the export failed'
touch "$T/fail-blobs"; sp; [ "$RC" = 1 ] || fail "a refused blob call exited $RC"
tail -n 1 "$T/out" | grep -q 'GitObject blobs refused for the self-test (HTTP 422)' || fail "the refused blob call's line does not carry GitHub's reply"
touch "$T/fail-trees"; sp; [ "$RC" = 1 ] || fail "a refused tree call exited $RC"
tail -n 1 "$T/out" | grep -q "the folder's tree could not be made.*GitObject trees refused for the self-test (HTTP 422)" || fail "the refused tree call's line does not carry GitHub's reply"
touch "$T/wrong-trees"; sp; [ "$RC" = 1 ] || fail "another tree from GitHub exited $RC"
tail -n 1 "$T/out" | grep -q "the folder's tree could not be made.*4b825dc642cb.*[0-9a-f]\{12\}" || fail 'a tree that is not the export'"'"'s is not named beside the export'"'"'s'
! posted || fail 'a failed publish posted a branch or a pull request'
sp; [ "$RC" = 0 ] || fail "the call again, with GitHub answering, exited $RC"
grep -q '^spec-published ' .vid/tw/log || fail 'the call again logged no spec-published line'
echo 'spec-publish-reply: ok'
