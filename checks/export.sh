#!/bin/sh
# Purpose: ViD's run export (v0.9.6.2 spec 3.7, R7) — packs one run into one
# self-contained folder the owner can keep or push. It READS: it never
# changes the project, its repository included (no object, no ref, no
# index write), and it computes no measure, prices nothing, uploads and
# deletes nothing. It writes <out>/<run id>-<UTC>/ (by default under the
# run's home's .vid/exports/; the run id from .vid/run, `none` without one):
#   vid/home/              the home's .vid/, exports/ left out
#   vid/worktrees/<name>/  each other worktree's own .vid/ (git worktree list)
#   repo.bundle            made in a temporary repository the export owns,
#                          which borrows the project's objects (git
#                          alternates): every ref of the project, plus
#                          refs/vid-export/tree/<receipt> per receipt tree
#                          (`tree=` in a .tree file of .vid/ledger-results/),
#                          each pointing at a commit made there with
#                          `git commit-tree <tree>`; then `git bundle create
#                          --all` from it — frozen uncommitted trees survive
#   transcripts/<folder>/  every Claude Code project folder (under
#                          ${CLAUDE_CONFIG_DIR:-~/.claude}/projects) whose
#                          name starts with the encoded path of the home or of
#                          a live worktree (worktree folders included, live or
#                          gone) AND holds a transcript of a session the
#                          events name (`session=`, a `session` event's
#                          `id=`) — the encoded name finds folders, the ids
#                          decide membership; plus every transcript a
#                          `session` or `agent-stop` event names outside those
#                          folders, with its sibling <id>/ (subagents/,
#                          tool-results/) and meta file; copied whole
#   plugin/<version>/      the plugin's whole version folder from the plugin
#                          cache, for each version named by `vid=` in the
#                          session events or by a plugin path in the
#                          transcripts; `missing` when gone
#   export.tsv             export version, records version, run id, host, time
#   manifest.tsv           written last: `<kind>\t<path>\t<bytes>\t<sha256>\t<source>\t<captured>`
#                          per file (kind `file`); a file over 95 MiB is cut
#                          into numbered parts <path>.part-000 … (kind `part`)
#                          and listed once more whole (kind `split`: its bytes
#                          and sha256, reassembled from the parts in order);
#                          kind `missing` for what was named but is absent.
# Usage: sh checks/export.sh [--out <dir>]
set -eu
IFS='
'
usage() { echo 'ViD export: usage — sh checks/export.sh [--out <dir>]' >&2; exit 2; }
OUT=''
while [ $# -gt 0 ]; do
  case "$1" in --out) [ $# -ge 2 ] || usage; OUT=$2; shift 2 ;; *) usage ;; esac
done
EXPORT_VERSION=1
SPLIT=${VID_EXPORT_SPLIT_BYTES:-99614720}   # 95 MiB; the variable exists for the self-test
CFG=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
# the run's home, as checks/event.sh resolves it
TOP=$(git rev-parse --show-toplevel 2>/dev/null) || { echo 'ViD export: refused — not inside a git worktree.' >&2; exit 1; }
H=$TOP
if [ ! -f "$TOP/.vid/RUN-STATE.md" ] && [ -f "$TOP/.vid/home" ]; then
  _h=$(sed -n 1p "$TOP/.vid/home"); if [ -n "$_h" ] && [ -f "$_h/.vid/RUN-STATE.md" ]; then H=$_h; fi
fi
H=$(cd "$H" && pwd -P)
[ -d "$H/.vid" ] || { echo "ViD export: refused — $H has no .vid/; nothing to export." >&2; exit 1; }
utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
RUNID=$(sed -n 's/^id=//p' "$H/.vid/run" 2>/dev/null | head -n 1); RUNID=${RUNID:-none}
[ -n "$OUT" ] || OUT="$H/.vid/exports"
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd -P)
B="$OUT/$RUNID-$(date -u '+%Y%m%dT%H%M%SZ')"
[ ! -e "$B" ] || { echo "ViD export: refused — $B already exists." >&2; exit 1; }
mkdir -p "$B"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
: > "$W/roots"; : > "$W/missing"
root() { printf '%s\t%s\t%s\n' "$1" "$2" "$(utc)" >> "$W/roots"; }        # <bundle dir> <source dir>: provenance for the manifest
missing() { printf 'missing\t%s\t-\t-\t%s\t%s\n' "$1" "$2" "$(utc)" >> "$W/missing"; }
h256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }
enc() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
# copyvid <.vid dir> <bundle dir>: the folder whole, its exports/ (and an --out inside it) left out
copyvid() {
  mkdir -p "$B/$2"
  _x=''; case "$OUT/" in "$1"/*) _r=${OUT#"$1"/}; _x=${_r%%/*} ;; esac
  ( cd "$1" && find . -type f ! -path './exports/*' | LC_ALL=C sort ) | { if [ -n "$_x" ]; then grep -v "^\./$_x/" || true; else cat; fi; } > "$W/list"
  ( cd "$1" && tar -cf - -T "$W/list" ) | ( cd "$B/$2" && tar -xf - )
  root "$2" "$1"
}

# 1. the records: the home's .vid/ and each other worktree's
copyvid "$H/.vid" vid/home
git -C "$H" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' > "$W/worktrees" || : > "$W/worktrees"
: > "$W/wtnames"
for wt in $(cat "$W/worktrees"); do
  [ -d "$wt" ] && wt=$(cd "$wt" && pwd -P) || continue
  [ "$wt" = "$H" ] && continue
  [ -d "$wt/.vid" ] || continue
  n=$(basename "$wt"); k=1; while grep -qxF "$n" "$W/wtnames"; do k=$((k + 1)); n="$(basename "$wt")-$k"; done
  printf '%s\n' "$n" >> "$W/wtnames"
  copyvid "$wt/.vid" "vid/worktrees/$n"
done

# 2. the history: a temporary repository borrowing the project's objects
TR="$W/repo.git"
CD=$(git -C "$H" rev-parse --git-common-dir); case "$CD" in /*) ;; *) CD="$H/$CD" ;; esac; CD=$(cd "$CD" && pwd -P)
git init -q --bare "$TR"
printf '%s\n' "$CD/objects" > "$TR/objects/info/alternates"
tg() { GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git --git-dir="$TR" "$@"; }
git -C "$H" for-each-ref --format='%(objectname) %(refname)' > "$W/refs"
while IFS=' ' read -r sha ref; do tg update-ref "$ref" "$sha"; done < "$W/refs"
_hb=$(git -C "$H" symbolic-ref -q HEAD 2>/dev/null || true); [ -n "$_hb" ] && tg symbolic-ref HEAD "$_hb"
for tf in $(find "$B/vid" -path '*/ledger-results/*.tree' -type f 2>/dev/null | LC_ALL=C sort); do
  rn=$(basename "$tf" .tree); tr_=$(sed -n 's/^tree=//p' "$tf" | head -n 1)
  [ -n "$tr_" ] || continue
  rf="refs/vid-export/tree/$(printf '%s' "$rn" | sed 's/[^A-Za-z0-9._-]/_/g; s/\.\.*/./g; s/^\.//; s/\.lock$/_lock/')"
  tg show-ref -q --verify "$rf" && continue
  if tg cat-file -e "$tr_^{tree}" 2>/dev/null; then
    c=$(GIT_AUTHOR_NAME=vid-export GIT_AUTHOR_EMAIL=vid@export GIT_COMMITTER_NAME=vid-export GIT_COMMITTER_EMAIL=vid@export \
      tg commit-tree "$tr_" -m "vid export: the tree receipt $rn tested")
    tg update-ref "$rf" "$c"
  else
    missing "tree:$rn" "$tr_"
  fi
done
if tg for-each-ref --count=1 | grep -q .; then
  tg bundle create "$B/repo.bundle" --all 2>/dev/null || missing repo.bundle "$CD"
else
  missing repo.bundle "$CD (no refs)"
fi
printf 'repo.bundle\t%s\t%s\n' "$CD" "$(utc)" >> "$W/roots"

# 3. the transcripts
PR="$CFG/projects"
for f in "$B"/vid/home/metrics-events "$B"/vid/worktrees/*/metrics-events; do if [ -f "$f" ]; then cat "$f"; fi; done > "$W/events"
{ tr ' ' '\n' < "$W/events" | sed -n 's/^session=//p'
  awk '$1 == "session" { for (i = 2; i <= NF; i++) if ($i ~ /^id=/) print substr($i, 4) }' "$W/events"; } | tr -d '"' | grep -v '^-*$' | sort -u > "$W/sids" || true
{ enc "$H"; echo; for wt in $(cat "$W/worktrees"); do [ -d "$wt" ] && enc "$(cd "$wt" && pwd -P)" && echo; done; } | grep -v '^$' | sort -u > "$W/prefixes"
: > "$W/tfolders"
if [ -d "$PR" ]; then
  for d in $(ls "$PR" 2>/dev/null); do
    [ -d "$PR/$d" ] || continue
    hit=no; for p in $(cat "$W/prefixes"); do case "$d" in "$p"*) hit=yes ;; esac; done
    [ "$hit" = yes ] || continue
    for s in $(cat "$W/sids"); do if [ -f "$PR/$d/$s.jsonl" ]; then printf '%s\n' "$d" >> "$W/tfolders"; break; fi; done
  done
fi
for d in $(sort -u "$W/tfolders"); do
  mkdir -p "$B/transcripts"; cp -Rp "$PR/$d" "$B/transcripts/$d"; root "transcripts/$d" "$PR/$d"
done
# transcripts an event names outside those folders
awk '$1 == "session" || $1 == "agent-stop" { for (i = 2; i <= NF; i++) if ($i ~ /^transcript=/) { v = substr($0, index($0, $i) + 11); if (v ~ /^"/) { sub(/^"/, "", v); sub(/".*/, "", v) } else sub(/ .*/, "", v); print v } }' "$W/events" | grep -v '^-$' | sort -u > "$W/named" || true
for t in $(cat "$W/named"); do
  inside=no
  for d in $(sort -u "$W/tfolders"); do case "$t" in "$PR/$d"/*) inside=yes ;; esac; done
  [ "$inside" = yes ] && continue
  if [ ! -f "$t" ]; then missing "transcript:$t" "$t"; continue; fi
  case "$t" in "$PR"/*) rel=${t#"$PR"/} ;; *) rel="outside${t}" ;; esac
  dst="$B/transcripts/$rel"; mkdir -p "$(dirname "$dst")"
  [ -f "$dst" ] || { cp -p "$t" "$dst"; root "transcripts/$rel" "$t"; }
  base=${t%.jsonl}
  if [ -d "$base" ] && [ ! -d "${dst%.jsonl}" ]; then cp -Rp "$base" "${dst%.jsonl}"; root "transcripts/${rel%.jsonl}" "$base"; fi
  if [ -f "$base.meta.json" ] && [ ! -f "${dst%.jsonl}.meta.json" ]; then cp -p "$base.meta.json" "${dst%.jsonl}.meta.json"; root "transcripts/${rel%.jsonl}.meta.json" "$base.meta.json"; fi
done

# 4. the plugin, each version that ran
{ awk '$1 == "session" { for (i = 2; i <= NF; i++) if ($i ~ /^vid=/) print substr($i, 5) }' "$W/events"
  [ -d "$B/transcripts" ] && find "$B/transcripts" -type f -name '*.jsonl' -exec grep -ohE 'plugins/cache/[^/"]+/vid/[^/"]+/' {} + 2>/dev/null | sed -E 's|.*/vid/([^/]+)/$|\1|'
} | grep -v '^-*$' | sort -u > "$W/versions" || true
for v in $(cat "$W/versions"); do
  src=''; for c in "$CFG"/plugins/cache/*/vid/"$v"; do [ -d "$c" ] && { src=$c; break; }; done
  if [ -n "$src" ]; then mkdir -p "$B/plugin"; cp -Rp "$src" "$B/plugin/$v"; root "plugin/$v" "$src"
  else missing "plugin/$v" "$CFG/plugins/cache/*/vid/$v"; fi
done

# 5. export.tsv
RV=$(sed -n 's/^records:[[:space:]]*//p' "$H/checks/records-version" 2>/dev/null | head -n 1)
printf 'export-version\t%s\nrecords\t%s\nrun\t%s\nhome\t%s\nhost\t%s\ntime\t%s\n' "$EXPORT_VERSION" "${RV:-none}" "$RUNID" "$H" "$(hostname 2>/dev/null || uname -n)" "$(utc)" > "$B/export.tsv"
printf 'export.tsv\tgenerated\t%s\n' "$(utc)" >> "$W/roots"

# 6. the manifest, last: every file, its provenance; a file over the limit cut into numbered parts
srcof() { awk -F'\t' -v p="$1" 'BEGIN { best = -1 } { r = $1; if ((p == r || index(p, r "/") == 1) && length(r) > best) { best = length(r); s = $2; t = $3; rest = substr(p, length(r) + 2) } }
  END { if (best < 0) { print "-\t-" } else { if (rest != "" && s != "generated") s = s "/" rest; print s "\t" t } }' "$W/roots"; }
: > "$B/manifest.tsv.tmp"
( cd "$B" && find . -type f ! -name manifest.tsv.tmp | sed 's|^\./||' | LC_ALL=C sort ) > "$W/files"
for f in $(cat "$W/files"); do
  st=$(srcof "$f"); sz=$(wc -c < "$B/$f" | tr -d ' ')
  if [ "$sz" -gt "$SPLIT" ]; then
    printf 'split\t%s\t%s\t%s\t%s\n' "$f" "$sz" "$(h256 "$B/$f")" "$st" >> "$B/manifest.tsv.tmp"
    i=0; n=$(( (sz + SPLIT - 1) / SPLIT ))
    while [ "$i" -lt "$n" ]; do
      pt="$f.part-$(printf '%03d' "$i")"
      dd if="$B/$f" of="$B/$pt" bs="$SPLIT" skip="$i" count=1 2>/dev/null
      printf 'part\t%s\t%s\t%s\t%s\n' "$pt" "$(wc -c < "$B/$pt" | tr -d ' ')" "$(h256 "$B/$pt")" "$st" >> "$B/manifest.tsv.tmp"
      i=$((i + 1))
    done
    rm -f "$B/$f"
  else
    printf 'file\t%s\t%s\t%s\t%s\n' "$f" "$sz" "$(h256 "$B/$f")" "$st" >> "$B/manifest.tsv.tmp"
  fi
done
cat "$W/missing" >> "$B/manifest.tsv.tmp"
mv "$B/manifest.tsv.tmp" "$B/manifest.tsv"
echo "ViD export: $B — $(grep -c '^file	\|^part	' "$B/manifest.tsv") files, $(grep -c '^split	' "$B/manifest.tsv") split, $(grep -c '^missing	' "$B/manifest.tsv") missing; refs: $(tg for-each-ref | grep -c .) ($(tg for-each-ref refs/vid-export/ | grep -c .) receipt trees)"
