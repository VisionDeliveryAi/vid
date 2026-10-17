#!/bin/sh
# Purpose: selftest case — the run export (v0.9.6.2 spec 3.7, R7; §6 case
# 20). A scratch project with a run, a frozen uncommitted tree and a
# committed one in two receipts, a live worktree with its own .vid/, a
# worktree since removed, and a scratch Claude Code folder
# (CLAUDE_CONFIG_DIR): transcript folders of the project and of the removed
# worktree, a decoy folder sharing the encoded prefix whose sessions no
# event names, a transcript outside them named by a `session` event, and a
# plugin cache holding the version that event names. Convicts unless
# `sh checks/export.sh` leaves the repository byte for byte as it was (no
# new ref or object) and the working tree too; the manifest lists every
# file of the bundle with its bytes and sha256, and the version a
# transcript names but the cache lacks as missing; a file over the split
# limit (lowered for the case) is cut into numbered parts that reassemble
# to the whole file's sha256; the bundle, restored into an empty folder,
# holds every ref of the project plus one refs/vid-export/tree/<receipt>
# per receipt, and the frozen tree checks out with its uncommitted
# content; the removed worktree's transcript folder, the outside
# transcript with its sibling folder, a template and a seed file of the
# plugin version are included, and the decoy is not. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
fail() { echo "export: $*" >&2; cat "$T/out" >&2 2>/dev/null || true; exit 1; }
[ -f "$CHECKS/export.sh" ] || fail 'no checks/export.sh'
export CLAUDE_CONFIG_DIR="$T/claude"
P="$T/proj"; mkdir -p "$P/checks" "$P/app"; cd "$P"; git init -q
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" "$CHECKS/export.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
printf '.vid/\n.claude/\n' > .gitignore; printf 'v1\n' > app/main.txt
g add -A; g commit -qm root; g tag v0
P=$(pwd -P); E=$(printf '%s' "$P" | sed 's/[^A-Za-z0-9]/-/g')
mkdir -p .vid/ledger-results; printf 'run: active\nsession: S0\nplan: required\n' > .vid/RUN-STATE.md
sh checks/event.sh 'stage name=develop state=start session=S0 records=4'
# a frozen uncommitted tree and a committed one
printf 'v2 frozen, never committed\n' > "$T/frozen.txt"
FT=$(GIT_INDEX_FILE="$T/idx" sh -c 'git read-tree HEAD && git update-index --add --cacheinfo 100644,$(git hash-object -w "$1"),app/main.txt && git write-tree' sh "$T/frozen.txt")
printf '<report/>\n' > .vid/ledger-results/r1; printf 'tree=%s\nbase=x\n' "$FT" > .vid/ledger-results/r1.tree
printf '<report/>\n' > .vid/ledger-results/r2; printf 'tree=%s\nbase=x\n' "$(git rev-parse HEAD^{tree})" > .vid/ledger-results/r2.tree
# a live worktree with its own .vid/, and one removed
g worktree add -q "$P/.claude/worktrees/live" -b live 2>/dev/null
mkdir -p "$P/.claude/worktrees/live/.vid"; printf 'note\n' > "$P/.claude/worktrees/live/.vid/note"
g worktree add -q "$P/.claude/worktrees/gone" -b gone 2>/dev/null
( cd "$P/.claude/worktrees/gone" && mkdir -p .vid && printf '%s\n' "$P" > .vid/home && sh checks/event.sh 'stage name=develop state=start session=S2 records=4' )
g worktree remove --force "$P/.claude/worktrees/gone"
# the Claude Code folders
PR="$CLAUDE_CONFIG_DIR/projects"; mkdir -p "$PR/$E/S0/subagents" "$PR/$E--claude-worktrees-gone" "$PR/$E-decoy" "$T/elsewhere/S3/tool-results"
{ printf '{"cwd":"%s","msg":"see plugins/cache/mk/vid/9.9.8/skills/x"}\n' "$P"; i=0; while [ $i -lt 60 ]; do printf '{"line":%d,"pad":"0123456789012345678901234567890123456789"}\n' $i; i=$((i + 1)); done; } > "$PR/$E/S0.jsonl"
printf '{"agent":"a1"}\n' > "$PR/$E/S0/subagents/agent-a1.jsonl"
printf '{"s":"S2"}\n' > "$PR/$E--claude-worktrees-gone/S2.jsonl"
printf '{"s":"X"}\n' > "$PR/$E-decoy/X.jsonl"
printf '{"s":"S3"}\n' > "$T/elsewhere/S3.jsonl"; printf 'r\n' > "$T/elsewhere/S3/tool-results/r.txt"
sh checks/event.sh "session id=S3 source=startup transcript=$T/elsewhere/S3.jsonl vid=9.9.9"
PC="$CLAUDE_CONFIG_DIR/plugins/cache/mk/vid/9.9.9"; mkdir -p "$PC/.claude-plugin" "$PC/templates" "$PC/seed" "$PC/skills/x" "$PC/hooks" "$PC/checks"
printf '{"name":"vid","version":"9.9.9"}\n' > "$PC/.claude-plugin/plugin.json"; printf '# PRD\n' > "$PC/templates/PRD.md"; printf '# rules\n' > "$PC/seed/rules.md"; printf 'x\n' > "$PC/skills/x/SKILL.md"
# the repository and the working tree before
snap() { ( cd "$P" && find .git -type f -exec shasum {} + | LC_ALL=C sort; git for-each-ref; find . -path ./.git -prune -o -path ./.vid -prune -o -path ./.claude -prune -o -type f -print | LC_ALL=C sort | xargs shasum ) > "$1"; }
snap "$T/before"
VID_EXPORT_SPLIT_BYTES=1000 sh checks/export.sh > "$T/out" 2>&1 || fail 'the export failed'
snap "$T/after"
cmp -s "$T/before" "$T/after" || { diff "$T/before" "$T/after" >&2 || true; fail 'the export changed the repository or the working tree'; }
B=$(ls -d .vid/exports/*/ | head -n 1); B=${B%/}
[ -n "$B" ] && [ -f "$B/manifest.tsv" ] || fail 'no bundle with a manifest'
RID=$(sed -n 's/^id=//p' .vid/run); case "$(basename "$B")" in "$RID"-*) ;; *) fail 'the bundle is not named <run id>-<UTC>' ;; esac
# the manifest: every file, its bytes and hash
( cd "$B" && find . -type f ! -name manifest.tsv | sed 's|^\./||' | LC_ALL=C sort ) > "$T/files"
awk -F'\t' '$1 == "file" || $1 == "part" { print $2 }' "$B/manifest.tsv" | LC_ALL=C sort > "$T/listed"
cmp -s "$T/files" "$T/listed" || { diff "$T/files" "$T/listed" >&2 || true; fail 'the manifest does not list exactly the files'; }
while IFS="$(printf '\t')" read -r k p n h s c; do
  case "$k" in file|part) ;; *) continue ;; esac
  [ "$(shasum -a 256 "$B/$p" | cut -d' ' -f1)" = "$h" ] && [ "$(wc -c < "$B/$p" | tr -d ' ')" = "$n" ] || fail "the manifest's hash or size is wrong for $p"
done < "$B/manifest.tsv"
grep -q "^missing	plugin/9.9.8	" "$B/manifest.tsv" || fail 'the version a transcript names, absent from the cache, is not listed missing'
# the split file reassembles
SP="transcripts/$E/S0.jsonl"
grep -q "^split	$SP	" "$B/manifest.tsv" || fail 'the large transcript was not split'
[ ! -f "$B/$SP" ] && [ -f "$B/$SP.part-000" ] && [ -f "$B/$SP.part-001" ] || fail 'the parts are not numbered beside the absent whole'
cat "$B/$SP".part-* > "$T/whole"
[ "$(shasum -a 256 "$T/whole" | cut -d' ' -f1)" = "$(awk -F'\t' -v p="$SP" '$1 == "split" && $2 == p { print $4; exit }' "$B/manifest.tsv")" ] && cmp -s "$T/whole" "$PR/$E/S0.jsonl" || fail 'the parts do not reassemble to the whole'
# the bundle, restored into an empty folder
RB="$B/repo.bundle"; if [ ! -f "$RB" ]; then cat "$B/repo.bundle".part-* > "$T/repo.bundle"; RB="$T/repo.bundle"; fi   # split too, at the lowered limit
git clone -q --mirror "$RB" "$T/restored.git" 2>/dev/null || fail 'the bundle does not restore'
git -C "$P" for-each-ref --format='%(objectname) %(refname)' > "$T/prefs"
git --git-dir="$T/restored.git" for-each-ref --format='%(objectname) %(refname)' > "$T/rrefs"
while read -r l; do grep -qxF "$l" "$T/rrefs" || fail "the restored bundle lacks $l"; done < "$T/prefs"
[ "$(grep -c ' refs/vid-export/tree/' "$T/rrefs")" -eq 2 ] || fail 'not one receipt-tree ref per receipt'
[ "$(git --git-dir="$T/restored.git" show refs/vid-export/tree/r1:app/main.txt)" = 'v2 frozen, never committed' ] || fail 'the frozen tree does not check out'
mkdir "$T/co"; git --git-dir="$T/restored.git" archive refs/vid-export/tree/r1 | tar -x -C "$T/co"; grep -q 'v2 frozen' "$T/co/app/main.txt" || fail 'the frozen tree did not check out'
# what is included
[ -f "$B/vid/home/RUN-STATE.md" ] && [ -f "$B/vid/home/run" ] && [ -f "$B/vid/worktrees/live/note" ] || fail 'the records are not all there'
[ ! -d "$B/vid/home/exports" ] || fail 'exports/ was exported'
[ -f "$B/transcripts/$E--claude-worktrees-gone/S2.jsonl" ] || fail "the removed worktree's transcript folder is missing"
[ -f "$B/transcripts/$E/S0/subagents/agent-a1.jsonl" ] || fail 'a subagent transcript is missing'
[ ! -d "$B/transcripts/$E-decoy" ] || fail 'a folder no event names was exported'
O="$B/transcripts/outside$T/elsewhere"
[ -f "$O/S3.jsonl" ] && [ -f "$O/S3/tool-results/r.txt" ] || fail 'the outside transcript, with its sibling folder, is missing'
[ -f "$B/plugin/9.9.9/templates/PRD.md" ] && [ -f "$B/plugin/9.9.9/seed/rules.md" ] || fail 'a template or a seed file of the plugin version is missing'
grep -q '^export-version	' "$B/export.tsv" && grep -q '^records	' "$B/export.tsv" && grep -q '^host	' "$B/export.tsv" || fail 'export.tsv is incomplete'
exit 0
