#!/bin/sh
# Purpose: selftest case — the lock is never an empty spec repository's default branch (FB-1 B4). On the ticket writer's toy
# (fixtures/tw-toy.sh), GitHub auto with no `state-repo:`, so the lock lives in the spec repository, made empty, with a hook that acts
# as GitHub does (the first branch pushed to an empty repository its default; deleting the default refused): after take, free,
# take and free, the default branch is not the lock and every free exits 0; the first spec-export then fast-forwards the
# placeholder main (a commit of no files whose message does not open "ViD export of "), its tree the export's. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "state-lock-empty-spec-repo: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh
tw_toy "$T/toy"; grep -q '^state-repo:' .vid/tw/settings && fail 'the scene is wrong: the toy names a state-repo:'
gh repo create owner/code-spec --private > /dev/null; SR=$T/gh/repos/owner%code-spec/remote.git
[ -z "$(git --git-dir="$SR" for-each-ref refs/heads)" ] || fail 'the scene is wrong: the spec repository is not empty'
# GitHub's rules, as a hook: the first branch pushed to an empty repository is its default; deleting the default is refused
cat > "$SR/hooks/pre-receive" <<'HOOK'
#!/bin/sh
D=$(git rev-parse --git-dir)/default-branch; fresh=''; [ -n "$(git for-each-ref refs/heads)" ] || fresh=1
while read -r o n r; do
  [ -z "$fresh" ] || [ -s "$D" ] || printf '%s\n' "$r" > "$D"
  case $n in *[!0]*) ;; *) if [ "$r" = "$(cat "$D" 2>/dev/null)" ]; then echo "error: refusing to delete the current branch: $r (Cannot delete the default branch)" >&2; exit 1; fi ;; esac
done; exit 0
HOOK
chmod +x "$SR/hooks/pre-receive"
lk() { git --git-dir="$SR" rev-parse -q --verify refs/heads/vid-state/lock || true; }
CLAUDE_CODE_SESSION_ID=empty-spec; export CLAUDE_CODE_SESSION_ID
for k in first second; do
  sh "$GS" lock-take > "$T/out" 2>&1 || fail "the $k lock-take failed"; [ -n "$(lk)" ] || fail "the $k take left no lock on the spec repository"
  [ "$(cat "$SR/default-branch" 2>/dev/null || true)" != refs/heads/vid-state/lock ] || fail 'the lock became the default branch of the empty spec repository'
  RC=0; sh "$GS" lock-free > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the $k lock-free exited $RC"; [ -z "$(lk)" ] || fail "the lock is still there after the $k free"
done
[ "$(cat "$SR/default-branch")" = refs/heads/main ] || fail "the default branch is $(cat "$SR/default-branch"), not the placeholder main"
M0=$(git --git-dir="$SR" rev-parse refs/heads/main); [ "$(git --git-dir="$SR" rev-parse "$M0^{tree}")" = "$(git hash-object -t tree /dev/null)" ] || fail 'the placeholder main holds files'
case $(git --git-dir="$SR" log -1 --format=%s "$M0") in 'ViD export of '*) fail 'the placeholder main reads as an export' ;; esac
# the first export: a fast-forward of the placeholder, its tree the export's
sh "$GS" spec-export > "$T/out" 2>&1 || fail 'the first spec-export failed'
X=$(awk '$1 == "export" { v = $2 } END { print v }' .vid/tw/log); M1=$(git --git-dir="$SR" rev-parse refs/heads/main)
[ "$M1" = "$X" ] || fail "the spec repository's main is not the logged export"
[ "$(git --git-dir="$SR" rev-parse "$M1^")" = "$M0" ] || fail 'the first export is not a fast-forward of the placeholder main'
[ "$(git --git-dir="$SR" rev-parse "$M1:PRD.md")" = "$(git rev-parse HEAD:PRD.md)" ] || fail "the export's tree does not hold PRD.md as HEAD does"
git --git-dir="$SR" ls-tree -r --name-only "$M1" > "$T/tr"; while read -r f; do case $f in PRD.md|DECISIONS.md|BASELINE.md|ARCHITECTURE.md|GRADING-CHECKLIST.md|TEST-DIFFERENCES.md|design/*) ;; *) fail "the export's tree holds $f, no export's path" ;; esac; done < "$T/tr"
echo 'state-lock-empty-spec-repo: ok'
