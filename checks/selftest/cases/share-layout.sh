#!/bin/sh
# Purpose: selftest case — the share bundle's layout (0.26.10.28.7, stage 3 R2). A toy project in each mode (local auto; GitHub auto,
# ticket mode with the owner's recorded answer auto; GitHub manual (FB-1 C1: the label github-manual, once github-team), its answer manual and the round's stand-in: switch on), each with a clone at .vid/code, an older clone at
# .vid/code.old-1, .vid/spec.git, a worktree under .vid/worktrees, a clone nested deeper, an earlier export holding a repo.bundle,
# the spec laid out for a hand publish (.vid/spec-out, FB-3 B1),
# and round.log and PLAN.md at its root. Convicts unless `share.sh build` writes .vid/shares/<yyyy-mm>-<mode>-<project>/ with
# records/.vid/ and records/round.log and records/PLAN.md, and none of the clones, object stores, worktrees, the export or any
# repo.bundle; the summary names the mode; in GitHub manual the manifest says the team's side is out of reach, and, with one
# repository (FB-3 B2), the run card that the spec is in the code repository's folder. A named
# logs folder with a planted clone (a folder holding .git), a blind copy, a checkout, a run's c/ and a tree gives logs/ without
# them, its timeline gzipped and a note kept. With --leave-out conversations no conversations/ is written and the manifest
# lists it as left out at the user's request; `share.sh pack` makes one archive file holding the bundle. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "share-layout: $*" >&2; cat "$T/out" >&2 2>/dev/null || true; exit 1; }
[ -f "$CHECKS/share.sh" ] || fail 'no checks/share.sh'
export CLAUDE_CONFIG_DIR="$T/claude"; mkdir -p "$CLAUDE_CONFIG_DIR/projects"
# toy <dir> <mode words for RUN-STATE> <stand-in setting>
toy() {
  mkdir -p "$1/checks" "$1/.vid/code" "$1/.vid/code.old-1" "$1/.vid/spec.git/objects" "$1/.vid/worktrees/w1" "$1/.vid/exports/e1" "$1/.vid/decide/inner/clone" "$1/.vid/tw"
  cp "$CHECKS/share.sh" "$1/checks/"; cd "$1"; git init -q
  printf 'run: active\nsession: S1\n%s' "$2" > .vid/RUN-STATE.md; [ -z "$3" ] || { mkdir -p .vid/plan; printf '%s\n' "$3" > .vid/plan/setup; }; [ -z "${4:-}" ] || printf '%s\n' "$4" > .vid/tw/settings
  printf 'stage name=develop state=start session=S1 records=33 at=2026-11-03T09:00:00Z\n' > .vid/metrics-events
  mkdir -p .vid/spec-out/0123456789ab/files; printf '# the laid-out spec\n' > .vid/spec-out/0123456789ab/files/PRD.md   # FB-3 B1
  git init -q .vid/code; printf 'app\n' > .vid/code/app.txt; printf 'old\n' > .vid/code.old-1/app.txt
  printf 'ref: refs/heads/main\n' > .vid/spec.git/HEAD; printf 'w\n' > .vid/worktrees/w1/file.txt
  printf 'bundle\n' > .vid/exports/e1/repo.bundle; printf 'gitdir: x\n' > .vid/decide/inner/clone/.git; printf 'c\n' > .vid/decide/inner/clone/code.txt
  printf 'a decision\n' > .vid/decide/inner/kept.md; printf 'round\n' > round.log; printf '# plan\n' > PLAN.md
}
for m in local-auto github-auto github-manual; do
  # GitHub auto by the owner's recorded answer; GitHub manual with the round's stand-in: switch on, which is no mode (the final review)
  u=''; case $m in local-auto) w=''; s='' ;; github-auto) w='mode: tickets
'; s='setup-answered key=github-mode value="auto" words="ViD'"'"'s own DevAgent" at=2026-11-03T09:00:00Z' ;; github-manual) w='mode: tickets
'; s='setup-answered key=github-mode value="manual" words="our developers, by hand" at=2026-11-03T09:00:00Z'; u='stand-in: on
layout: one
spec-path: upstream/vid
spec-repo: owner/old-spec' ;; esac
  toy "$T/Toy Project $m" "$w" "$s" "$u"
  sh checks/share.sh build > "$T/out" 2>&1 || fail "$m: the build failed"
  P=$(echo "toy-project-$m"); R="2026-11-$m-$P"; B=.vid/shares/$R
  [ -d "$B" ] || { ls .vid/shares >&2; fail "$m: no bundle at $B"; }
  [ -f "$B.summary" ] && grep -qx "mode	$m" "$B.summary" || fail "$m: the summary does not name the mode"
  for f in records/.vid/RUN-STATE.md records/.vid/decide/inner/kept.md records/round.log records/PLAN.md MANIFEST.json; do [ -f "$B/$f" ] || fail "$m: no $f"; done
  L=$(cd "$B" && find . | grep -E '/code(/|$)|code\.old|spec\.git|spec-out|worktrees|exports|repo\.bundle|/clone(/|$)|\.git$' || true); [ -z "$L" ] || fail "$m: code or an export in the bundle: $L"
  grep -q '"records/.vid/code"' "$B/MANIFEST.json" && grep -q '"records/.vid/spec.git"' "$B/MANIFEST.json" && grep -q '"records/.vid/spec-out"' "$B/MANIFEST.json" || fail "$m: the manifest does not list the laid-out spec, the clone and the object store as left out"
  if [ $m = github-manual ]; then grep -q 'out of reach' "$B/MANIFEST.json" || fail "manual: the manifest does not say the team's side is out of reach"
    # FB-3 B2: with one repository in GitHub manual the run card names the folder, and no spec repository
    grep -rqF -- "- **Spec repository:** none: the spec is in the code repository's folder upstream/vid, ViD's export in the project" "$B" || fail "manual, one repository: the run card's words: $(grep -rh 'Spec repository:' "$B" | head -n 1)"
  else ! grep -q 'out of reach' "$B/MANIFEST.json" || fail "$m: out of reach said outside GitHub manual"; fi
  cd "$T"
done
# a named logs folder, with code copies planted
cd "$T/Toy Project local-auto"; D=$T/dev; mkdir -p "$D/clones/c1" "$D/blind/b1" "$D/runs/r1/checkout" "$D/runs/r1/c" "$D/trees/t1" "$D/work/repo" "$D/runs/r2"
printf 'x\n' > "$D/clones/c1/a.txt"; printf 'x\n' > "$D/blind/b1/a.txt"; printf 'x\n' > "$D/runs/r1/checkout/a.txt"; printf 'x\n' > "$D/runs/r1/c/a.txt"
printf 'x\n' > "$D/trees/t1/a.txt"; mkdir -p "$D/work/repo/.git"; printf 'x\n' > "$D/work/repo/a.txt"
printf 'step 1 passed\n' > "$D/runs/r2/timeline-chromium.log"; printf 'a note\n' > "$D/notes.txt"
sh checks/share.sh build --logs "$D" --run 2026-11-logs > "$T/out" 2>&1 || fail 'the build with logs failed'
B=.vid/shares/2026-11-logs; [ -f "$B/logs/notes.txt" ] || fail 'the note is not in logs/'
[ -f "$B/logs/runs/r2/timeline-chromium.log.gz" ] && gzip -dc "$B/logs/runs/r2/timeline-chromium.log.gz" | grep -q 'step 1 passed' || fail 'the timeline is not gzipped in logs/'
L=$(cd "$B/logs" && find . | grep -E 'clones|blind|checkout|/c(/|$)|trees|work/repo' || true); [ -z "$L" ] || fail "code copies in logs/: $L"
for x in logs/clones logs/blind logs/runs/r1/checkout logs/runs/r1/c logs/trees logs/work/repo; do grep -q "\"$x\"" "$B/MANIFEST.json" || fail "$x is not listed as left out"; done
# the conversations left out at the user's request, and the archive
sh checks/share.sh build --leave-out conversations --run 2026-11-noconv > "$T/out" 2>&1 || fail 'the build without conversations failed'
B=.vid/shares/2026-11-noconv; [ -d "$B/records" ] || fail 'no records/ without conversations'
[ ! -e "$B/conversations" ] || fail 'conversations/ written though left out'
grep -q '\["conversations/", "left out at the user'"'"'s request"\]' "$B/MANIFEST.json" || fail 'the manifest does not list conversations as left out at the request'
grep -q "^left-out	conversations/	left out at the user's request" "$B.summary" || fail 'the summary does not list conversations as left out'
A=$(sh checks/share.sh pack "$B" 2> "$T/out") || fail 'pack failed'
[ "$(printf '%s\n' "$A" | grep -c .)" = 1 ] && [ -f "$A" ] || fail "pack printed no one archive: $A"
N=$(gzip -dc "$A" | tar -tf - | sed 's|/.*||' | sort -u); [ "$N" = 2026-11-noconv ] || fail "the archive does not hold the bundle under its name: $N"
gzip -dc "$A" | tar -tf - | grep -q '^2026-11-noconv/records/PLAN.md$' || fail 'the archive lacks the records'
echo 'share-layout: ok'
