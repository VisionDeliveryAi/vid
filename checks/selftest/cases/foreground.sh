#!/bin/sh
# Purpose: selftest case — helpers run in the foreground (0.26.11.1.2, R3, LA-17). A turn's end stops every
# background agent the turn started, so each of the 14 skill files that start agents carries one sentence S, the same
# everywhere, beside each spawn paragraph. The list is closed: a skill that only mentions agents is not on it. Convicts
# a listed file without S, a spawn paragraph without S in it or in the paragraph right after it, an opening of S that
# does not run on into S word for word (an old or changed copy), and proves itself on a copy with S removed from one
# file. vid-plan's three places are pinned by planner-scope.sh. A text check, gated on ViD's own skills beside checks/.
# Env: CHECKS.
set -eu
R="$CHECKS/../skills"
[ -d "$R" ] || { echo 'needs skills/'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "foreground: $*" >&2; exit 1; }
S='Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.'
O='Run every helper in the foreground'
FILES='vid-plan/SKILL.md vid-develop/SKILL.md vid-fix/SKILL.md vid-test-manager/SKILL.md vid-test-inventory/SKILL.md
vid-create-prd/SKILL.md vid-grade/SKILL.md vid-grade/GRADING.md vid-design/SKILL.md vid-verify/SKILL.md
vid-deploy/SKILL.md vid-init/SKILL.md vid-add/SKILL.md vid-stage/SKILL.md'
# file|a phrase of the spawn paragraph (the paragraph holding it, blank-line bounded, whitespace squeezed)
SPAWNS='vid-develop/SKILL.md|**Spawn by type (v0.9.7.1 3.1).**
vid-develop/SKILL.md|with the background facility
vid-fix/SKILL.md|the whole-set review in delta mode over the rows it touches, by a fresh agent
vid-fix/SKILL.md|Spawn it by its type, `vid:fixer`
vid-test-manager/SKILL.md|the run manager spawns `passes/test-analyst.md`
vid-test-manager/SKILL.md|**The test environments (v0.9.6 3.9, R9).**
vid-test-inventory/SKILL.md|**The lenses.** Spawn each as
vid-test-inventory/SKILL.md|**How it is spawned.**
vid-test-inventory/SKILL.md|in `mode: delta` on that append against the effective set
vid-test-inventory/SKILL.md|means "spawn test-author passes"
vid-test-inventory/SKILL.md|Fresh-context passes are spawned exactly where the chain marks them
vid-create-prd/SKILL.md|**The judged half:** one restricted reader
vid-create-prd/SKILL.md|Write the pass'"'"'s brief to `.vid/briefs/<pass>-<n>.md`
vid-grade/SKILL.md|Graders are fresh-context subagents
vid-grade/SKILL.md|**The wanderer (§5)**
vid-grade/SKILL.md|one fresh deep grader per area
vid-grade/GRADING.md|Spawn one fresh `vid:grader` subagent per batch
vid-grade/GRADING.md|Spawn it in parallel with the readers
vid-design/SKILL.md|Spawn `passes/consistency.md` with exactly that
vid-design/SKILL.md|Before commit B, spawn
vid-verify/SKILL.md|One fresh grader per pass, spawned with the repo path
vid-deploy/SKILL.md|**An agent spawned during a deploy
vid-init/SKILL.md|After step 6 has written its budget lines
vid-add/SKILL.md|once per add (v0.26.10.24 R1)
vid-stage/SKILL.md|review step (0.26.10.29.3 R3)
vid-stage/SKILL.md|reads the real file): spawn'
check() {
  for f in $FILES; do
    [ -f "$1/$f" ] || { echo "$f is missing"; return 1; }
    flat=$(tr '\n' ' ' < "$1/$f" | tr -s ' \t' ' ')
    ns=$(printf '%s' "$flat" | grep -oF "$S" | grep -c . || :); no=$(printf '%s' "$flat" | grep -oF "$O" | grep -c . || :)
    [ "$ns" -gt 0 ] || { echo "$f lacks the foreground sentence"; return 1; }
    [ "$ns" = "$no" ] || { echo "$f holds a copy of the foreground sentence that differs from it"; return 1; }
  done
  printf '%s\n' "$SPAWNS" | while IFS='|' read -r f h; do
    r=$(awk -v RS= -v h="$h" -v s="$S" '{ p = $0; gsub(/[ \t\n]+/, " ", p); has = index(p, s) > 0 }
      want { if (!has) bad = 1; want = 0 } index(p, h) { n++; if (!has) want = 1 }
      END { if (want) bad = 1; print (n ? (bad ? "bare" : "ok") : "none") }' "$1/$f")
    case $r in ok) ;; none) echo "$f: no paragraph holds \"$h\""; return 1 ;; *) echo "$f: the spawn paragraph \"$h\" has no foreground sentence beside it"; return 1 ;; esac
  done
}
m=$(check "$R") || fail "$m"
# cut S from the first paragraph that holds it (that spawn paragraph left bare, the file still holding S), or from all
cut() { awk -v RS= -v ORS='\n\n' -v s="$S" -v all="$2" '{ p = $0; gsub(/[ \t\n]+/, " ", p)
    while ((all || !done) && (i = index(p, s))) { p = substr(p, 1, i - 1) substr(p, i + length(s)); done = 1 } print p }' "$R/$1"; }
for f in $FILES; do mkdir -p "$T/c/$(dirname "$f")"; cp "$R/$f" "$T/c/$f"; done
cut vid-fix/SKILL.md 0 > "$T/c/vid-fix/SKILL.md"
m=$(check "$T/c") && fail 'a spawn paragraph with its sentence removed is not convicted'
case $m in *'has no foreground sentence beside it'*) ;; *) fail "the bare spawn paragraph is convicted for another reason: $m" ;; esac
cp "$R/vid-fix/SKILL.md" "$T/c/vid-fix/SKILL.md"; cut vid-verify/SKILL.md 1 > "$T/c/vid-verify/SKILL.md"
m=$(check "$T/c") && fail 'a file with the sentence removed is not convicted'
case $m in *'lacks the foreground sentence'*) ;; *) fail "the bare file is convicted for another reason: $m" ;; esac
exit 0
