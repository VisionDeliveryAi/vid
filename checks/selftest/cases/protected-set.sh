#!/bin/sh
# Purpose: selftest case — one protected-path set (v0.9.7.1 spec 3.4, 3.9; R4, R9). The brief-write fixture with
# bw_builder, checks/lawfiles beside brief.sh. Convicts unless `save` refuses, publishing nothing and leaving the
# worktree as it was, a change to each of tests/invariants/, checks/, design/, PRD.md, DEPLOYMENT.md,
# DESIGN-BRIEF.md, docker-compose.test.yml and a file checks/lawfiles names (INVENTORY.md), and a symlink; saves
# a change to DECISIONS.md (not protected); `restore` refuses a package whose patch touches PRD.md even with a
# well-formed manifest; and `return` refuses a pass whose receipt's tree differs from the commit's in a protected
# path, or whose tree object is missing, and accepts it in a `## 13` harness-upgrade brief. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "protected-set: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
cp "$CHECKS/event.sh" "$CHECKS/lawfiles" checks/; mkdir -p design; printf 'd\n' > design/x.md; printf 'p\n' > DEPLOYMENT.md; printf 'b\n' > DESIGN-BRIEF.md; printf 'services: {}\n' > docker-compose.test.yml
g add -A && g commit -qm toy
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'the brief was refused'; B=$(bw_out)
WT=$T/wt; g worktree add -q --detach "$WT" HEAD
for f in tests/invariants/links.sh checks/brief.sh design/x.md PRD.md DEPLOYMENT.md DESIGN-BRIEF.md docker-compose.test.yml INVENTORY.md; do
  printf '\n# edit\n' >> "$WT/$f"
  if sh checks/brief.sh save "$B" --worktree "$WT" > "$T/out" 2>&1; then fail "a change to $f was saved"; fi
  grep -qF "$f (protected)" "$T/out" || fail "the refusal does not name $f"
  [ ! -d .vid/continuations/S1/1-builder-1 ] || fail "a refused save published a package ($f)"
  git -C "$WT" diff --quiet -- "$f" && fail "the refused save undid the edit to $f"
  git -C "$WT" checkout -q -- "$f"
done
ln -s /etc/hosts "$WT/link"; if sh checks/brief.sh save "$B" --worktree "$WT" > "$T/out" 2>&1; then fail 'a symlink was saved'; fi; rm "$WT/link"
printf -- '- **D-901** toy | why: toy | enforced: convention\n' >> "$WT/DECISIONS.md"
sh checks/brief.sh save "$B" --worktree "$WT" > "$T/out" 2>&1 || fail 'a DECISIONS.md change was refused'
# restore refuses a protected path even in a well-formed package
P=.vid/continuations/S1/1-builder-1; git -C "$WT" checkout -q -- DECISIONS.md; printf '\n# prd\n' >> "$WT/PRD.md"
git -C "$WT" diff --binary HEAD > "$P/tracked.patch"
awk -F'\t' -v h="$(git hash-object "$P/tracked.patch")" 'BEGIN { OFS = "\t" } $1 == "file" && $2 == "tracked.patch" { $4 = h } { print }' "$P/manifest" > "$T/m" && cat "$T/m" > "$P/manifest"
bw_write --role builder --slice 1 --step S1 --rows ROW-101 --continue "$P" || fail 'the continuation brief was refused'; B2=$(bw_out)
W2=$T/wt2; g worktree add -q --detach "$W2" HEAD; cd "$W2"
if sh checks/brief.sh restore "$T/repo/$B2" > "$T/out" 2>&1; then fail 'restore took a patch to PRD.md'; fi
grep -qF 'PRD.md (protected)' "$T/out" || fail 'the restore refusal does not name PRD.md'
cd "$T/repo"
# return: a pass whose receipt tested other protected content
bw_return || fail 'bw_return failed'; BR=$(bw_out); RR=${BR%.md}.return.md
printf 'brief: %s\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$BR" "$(git rev-parse HEAD)" "$GREEN" > "$T/hb"
OT=$(sed -n 's/^tree=//p' .vid/ledger-results/$GREEN.tree)
printf '\n# changed\n' >> tests/invariants/links.sh; g commit -qam 'a test changed after the run'
sed "s/^commit: .*/commit: $(git rev-parse HEAD)/" "$T/hb" > "$RR"
if sh checks/brief.sh return "$RR" > "$T/out" 2>&1; then fail 'a pass on a changed test was accepted'; fi
grep -qF 'protected paths (tests/invariants/links.sh)' "$T/out" || fail 'the refusal does not name the protected path'
sed -i.bak "s/^tree=.*/tree=0123456789abcdef0123456789abcdef01234567/" .vid/ledger-results/$GREEN.tree
if sh checks/brief.sh return "$RR" > "$T/out" 2>&1; then fail 'a pass with a missing tree was accepted'; fi
grep -qF 'missing here' "$T/out" || fail 'the refusal does not say the tree is missing'
mv .vid/ledger-results/$GREEN.tree.bak .vid/ledger-results/$GREEN.tree
printf '\n## 13 harness upgrade\n\nharness: x\n' >> "$BR"
sh checks/brief.sh return "$RR" > "$T/out" 2>&1 || fail 'a harness upgrade'"'"'s pass was held to the protected check'
exit 0
