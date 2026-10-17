#!/bin/sh
# Purpose: selftest case — a continuation package, saved and restored (v0.9.7.1 spec 3.4b, c; R4). The
# brief-write fixture with bw_builder; a builder brief (S1, try 1-builder-1) and its worktree on vid/1-builder-1
# at quoted-at, holding a committed edit, a staged edit, an unstaged edit, a deletion, a rename, an executable
# new file and a binary new file. Convicts unless `save <brief> --worktree <wt>` publishes
# .vid/continuations/S1/1-builder-1/ (manifest naming the try, quoted-at, the landed commit, every payload's hash)
# and records `continuation-saved try=1-builder-1 files=` with no commit, stash or index change in the worktree;
# then, the worktree removed and a law commit landed, `write … --continue <package> --law <it>` adds `## 14
# continuation` naming the package and its manifest hash; `restore` on the successor's fresh worktree (the landed
# commit merged in) reproduces every file's bytes and mode and records `continuation-restored`; and restore
# refuses, changing nothing, a dirty tree, a new file that already exists, a corrupted payload, a manifest that
# changed after the brief (the check refuses the brief too), and a patch that no longer applies; and an
# untracked-only package (an empty patch) restores. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "save-restore: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
cp "$CHECKS/event.sh" "$CHECKS/lawfiles" checks/; mkdir -p lib; printf 'one\ntwo\n' > lib/a.txt; printf 'keep\n' > lib/b.txt; printf 'gone\n' > lib/c.txt; printf 'move me\n' > lib/d.txt
g add -A && g commit -qm 'toy files'
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'the brief was refused'
B=$(bw_out); Q=$(git rev-parse HEAD)
WT=$T/wt; g worktree add -q --detach "$WT" "$Q"
( cd "$WT" && g checkout -q -b vid/1-builder-1 "$Q" && printf 'landed\n' > lib/landed.txt && g add lib/landed.txt && g commit -qm landed
  printf 'one\nTWO\n' > lib/a.txt && g add lib/a.txt && printf 'keep\nmore\n' > lib/b.txt && g rm -q lib/c.txt && g mv lib/d.txt lib/e.txt
  printf '#!/bin/sh\necho hi\n' > lib/run.sh && chmod 755 lib/run.sh && printf '\000\001\002binary\377' > lib/blob.bin ) || fail 'the worktree setup failed'
L=$(git -C "$WT" rev-parse HEAD); ST0=$(git -C "$WT" status --porcelain); IX0=$(git -C "$WT" write-tree 2>/dev/null || true)
sh checks/brief.sh save "$B" --worktree "$WT" > "$T/out" 2>&1 || fail 'save was refused'
P=.vid/continuations/S1/1-builder-1; [ -f "$P/manifest" ] || fail 'no package'
grep -qx 'try=1-builder-1' "$P/manifest" && grep -qx "quoted-at=$Q" "$P/manifest" && grep -qx "landed=$L" "$P/manifest" || fail "the manifest lacks try, quoted-at or the landed commit: $(cat "$P/manifest")"
[ "$(grep -c '^file	' "$P/manifest")" -eq 3 ] || fail 'the manifest does not list the patch and the two new files'
grep -q '^continuation-saved try=1-builder-1 files=7 bytes=' .vid/metrics-events || fail "no continuation-saved files=7: $(grep continuation .vid/metrics-events)"
[ "$(git -C "$WT" status --porcelain)" = "$ST0" ] && [ "$(git -C "$WT" rev-parse HEAD)" = "$L" ] || fail 'save changed the worktree'
[ -z "$(git -C "$WT" stash list)" ] || fail 'save stashed'
for f in lib/a.txt lib/b.txt lib/e.txt lib/run.sh lib/blob.bin; do cp -p "$WT/$f" "$T/want.$(basename "$f")"; done
g worktree remove --force "$WT"
g merge -q --ff-only "$L" 2>/dev/null || g merge -q --no-edit "$L"
printf -- '- **D-900** a law commit | why: toy | enforced: convention\n' >> DECISIONS.md; g add -A && g commit -qm law; LAW=$(git rev-parse HEAD)
bw_write --role builder --slice 1 --step S1 --rows ROW-101 --continue "$P" --law "$LAW" || fail 'the continuation brief was refused'
B2=$(bw_out); awk '/^## 14/ { on = 1; next } on' "$B2" | grep -qx "package: $P    manifest: $(git hash-object "$P/manifest")" || fail 'section 14 does not name the package and its hash'
awk '/^## 14/ { on = 1; next } on' "$B2" | grep -qx "law: $LAW" || fail 'section 14 does not name the law commit'
W2=$T/wt2; g worktree add -q --detach "$W2" "$(git rev-parse HEAD)"; cd "$W2"; g checkout -q -b vid/1-builder-2
H0=$(git rev-parse HEAD)
printf 'x\n' > dirt.txt; if sh checks/brief.sh restore "$T/repo/$B2" > "$T/out" 2>&1; then fail 'a dirty tree took the restore'; fi; rm dirt.txt
printf 'here\n' > lib/run.sh; g add lib/run.sh; g commit -qm 'run.sh exists'
if sh checks/brief.sh restore "$T/repo/$B2" > "$T/out" 2>&1; then fail 'a new file over an existing path was restored'; fi
grep -qF 'already exist' "$T/out" || fail 'the refusal does not name the existing new file'
[ -z "$(git status --porcelain)" ] || fail 'a refused restore changed the tree'
g reset -q --hard "$H0"
cp "$T/repo/$P/new/lib/blob.bin" "$T/blob.keep"; printf 'X' >> "$T/repo/$P/new/lib/blob.bin"
if sh checks/brief.sh restore "$T/repo/$B2" > "$T/out" 2>&1; then fail 'a corrupted payload was restored'; fi
grep -qF 'corrupted' "$T/out" || fail 'the refusal does not say corrupted'; cp "$T/blob.keep" "$T/repo/$P/new/lib/blob.bin"
sh checks/brief.sh restore "$T/repo/$B2" > "$T/out" 2>&1 || fail 'the restore was refused'
for f in lib/a.txt lib/b.txt lib/e.txt lib/run.sh lib/blob.bin; do cmp -s "$f" "$T/want.$(basename "$f")" || fail "$f differs from the saved work"; done
[ ! -e lib/c.txt ] && [ ! -e lib/d.txt ] || fail 'the deletion or the rename was not restored'
[ -x lib/run.sh ] || fail 'the executable bit was lost'
grep -q '^continuation-restored try=1-builder-2 from=1-builder-1' "$T/repo/.vid/metrics-events" || fail 'no continuation-restored event at the home'
# a patch that no longer applies: the base moved under it
g reset -q --hard "$H0"; g clean -qfd
printf 'one\nCHANGED\n' > lib/a.txt; g commit -qam 'the base moved'
if sh checks/brief.sh restore "$T/repo/$B2" > "$T/out" 2>&1; then fail 'a patch that no longer applies was taken'; fi
grep -qF 'no longer applies' "$T/out" || fail 'the refusal is not the patch'"'"'s'
[ -z "$(git status --porcelain)" ] || fail 'a refused apply changed the tree'
# a manifest changed after the brief
cd "$T/repo"; printf '# edited\n' >> "$P/manifest"
if sh checks/brief.sh "$B2" > "$T/out" 2>&1; then fail 'the check took a brief whose package changed'; fi
cd "$W2"; g reset -q --hard "$H0"
if sh checks/brief.sh restore "$T/repo/$B2" > "$T/out" 2>&1; then fail 'a changed manifest was restored'; fi
# an untracked-only package: the empty patch is skipped
cd "$T/repo"; B3=$B2; WT3=$T/wt3; g worktree add -q --detach "$WT3" HEAD; ( cd "$WT3" && g checkout -q -b vid/1-builder-3 && printf 'only new\n' > lib/new-only.txt )
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'brief 3 was refused'; B3=$(bw_out)
sh checks/brief.sh save "$B3" --worktree "$WT3" > "$T/out" 2>&1 || fail 'the untracked-only save was refused'
P3=.vid/continuations/S1/1-builder-3; [ ! -s "$P3/tracked.patch" ] || fail 'the untracked-only patch is not empty'
bw_write --role builder --slice 1 --step S1 --rows ROW-101 --continue "$P3" || fail 'brief 4 was refused'; B4=$(bw_out)
W4=$T/wt4; g worktree add -q --detach "$W4" HEAD; cd "$W4"
sh checks/brief.sh restore "$T/repo/$B4" > "$T/out" 2>&1 || fail 'the untracked-only package did not restore'
[ "$(cat lib/new-only.txt)" = 'only new' ] || fail 'the new file is not restored'
exit 0
