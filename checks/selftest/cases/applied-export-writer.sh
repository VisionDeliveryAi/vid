#!/bin/sh
# Purpose: selftest case — GM-4 F8's readers in the export and the writer: both read the spec at lib.sh's applied, the one reader
# of what the team has, in every mode (HEAD outside GitHub manual, the applied record in it): github.sh's exptree and writer.sh's
# load take the commit from applied before any mode check, and neither reads .vid/tw/applied itself (its log, applied.log, and
# the refusal's words apart). On the ticket writer's toy in GitHub auto, with a .vid/tw/applied left naming an older commit, the
# export holds HEAD's PRD.md, and neither the export nor a written ticket makes a record of the applied version. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "applied-export-writer: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
G=$CHECKS/github.sh; WR=$CHECKS/writer.sh
sed -n '/^exptree() {/,/^  H=/p' "$G" > "$T/x"; sed -n '/^load() {/,/^}/p' "$WR" > "$T/l"
grep -q '^  _xc=$(applied)' "$T/x" || fail "github.sh's export does not take its commit from applied in every mode"
! grep -q '_xc:-HEAD' "$T/x" || fail "github.sh's export falls back to HEAD beside applied"
grep -q '^  AT=$(applied)' "$T/l" || fail "writer.sh's load does not take its commit from applied in every mode"
for f in "$G" "$WR"; do grep -v '^[[:space:]]*#' "$f" | grep -n '\.vid/tw/applied' | grep -v -e '\.vid/tw/applied\.log' -e 'tw/applied names no commit' > "$T/out" && fail "$(basename "$f") reads .vid/tw/applied itself"; done
. "$CHECKS/selftest/fixtures/tw-toy.sh"
tw_toy "$T/toy"; gh repo create owner/code-spec --private > /dev/null
O=$(git rev-parse HEAD); printf '\nA line added after the first commit.\n' >> PRD.md; git commit -qam 'PRD.md changed'; tw_ratify 'Yes, publish it'
mkdir -p .vid/tw; printf '%s\n' "$O" > .vid/tw/applied
sh "$G" spec-export > "$T/out" 2>&1 || fail 'the export failed in GitHub auto'
U=$(gh repo view owner/code-spec --json url --jq .url); git -C "$T" init -q sx; git -C "$T/sx" fetch -q "$U" main
git -C "$T/sx" show FETCH_HEAD:PRD.md | grep -q 'A line added after the first commit' || fail "the export in GitHub auto does not hold HEAD's PRD.md"
rm -f .vid/tw/applied; sh "$G" spec-export > "$T/out" 2>&1 || fail 'the export failed in GitHub auto'
sh "$G" tw-sync > "$T/out" 2>&1 || fail 'the sync failed'; tw_start S01 || fail 'S01 could not be admitted'; F=$(sh "$WR" write skeleton 2> "$T/out") || fail 'the skeleton could not be written in GitHub auto'
[ ! -e .vid/tw/applied ] || fail 'GitHub auto keeps a record of the applied version'
echo 'applied-export-writer: ok'
