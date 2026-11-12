#!/bin/sh
# Purpose: selftest case — Windows line endings in a spec file (0.26.10.28.1, 9.1 R4, F1). checks/eol.sh check refuses,
# with R4's line, each of PRD.md, INVENTORY.md, CLAUDE.md, STAGES.md, DECISIONS.md and DESIGN-BRIEF.md saved CR LF in
# the working tree, and so does the hook's commit; it refuses a file whose working copy is CR LF and staged copy LF, and
# one whose staged copy is CR LF and working copy LF; an all-LF project commits as before. eol.sh write makes
# .gitattributes with the four pins, and adds only the missing ones to one that holds two of them and a line of its
# own. Git's conversion: a project init's form wrote and committed, core.autocrlf true and every file checked out
# again — the hook still runs, checks/ holds LF, and a PRD.md then saved CR LF by hand is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/p"; cd "$T/p"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "eol-line-endings: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
CR=$(printf '\r')
line() { echo "ViD: refused — $1 has Windows line endings (CR LF), which ViD's checks cannot read. Save it with LF line endings; .gitattributes keeps git from adding them back (sh checks/eol.sh write)."; }
cp "$CHECKS/eol.sh" checks/eol.sh; cp "$CHECKS/lawfiles" checks/lawfiles; chmod +x checks/hooks/pre-commit
g add checks; g commit -qm 'the courts' --no-verify; g config core.hooksPath checks/hooks
FILES='PRD.md INVENTORY.md CLAUDE.md STAGES.md DECISIONS.md DESIGN-BRIEF.md'
for f in $FILES; do printf '# %s\nline one\n' "$f" > "$f"; done
VID_ROLE=fix g add -A; VID_ROLE=fix g commit -qm 'the spec, LF' > "$T/out" 2>&1 || fail 'an all-LF project did not commit'
sh checks/eol.sh check > "$T/out" 2>&1 || fail 'an all-LF project was refused by check'
# each spec file saved CR LF in the working tree: check refuses with R4's line, and the hook's commit too
for f in $FILES; do
  printf '# %s\r\nline one\r\n' "$f" > "$f"
  sh checks/eol.sh check > "$T/out" 2>&1 && fail "$f saved CR LF passed check"
  [ "$(cat "$T/out")" = "$(line "$f")" ] || fail "$f: not R4's line alone"
  g add "$f"; VID_ROLE=fix g commit -qm "$f CR LF" > "$T/out" 2>&1 && fail "the hook committed $f saved CR LF"
  grep -qxF "$(line "$f")" "$T/out" || fail "the hook's refusal of $f has no R4 line"
  printf '# %s\nline one\n' "$f" > "$f"; g add "$f"
done
[ -z "$(g status --porcelain -- $FILES)" ] || fail 'the files are not back to their committed LF form'
# working CR LF, staged LF
printf 'new\n' >> PRD.md; g add PRD.md; printf '# PRD.md\r\nline one\r\nnew\r\n' > PRD.md
sh checks/eol.sh check > "$T/out" 2>&1 && fail 'working CR LF with staged LF passed'
grep -qxF "$(line PRD.md)" "$T/out" || fail 'working CR LF: no R4 line'
# staged CR LF, working LF
g add PRD.md; printf '# PRD.md\nline one\nnew\n' > PRD.md
g show :PRD.md | grep -q "$CR" || fail 'the staged copy holds no CR (the case is wrong)'
sh checks/eol.sh check > "$T/out" 2>&1 && fail 'staged CR LF with working LF passed'
grep -qxF "$(line PRD.md)" "$T/out" || fail 'staged CR LF: no R4 line'
g add PRD.md; VID_ROLE=fix g commit -qm 'LF again' > "$T/out" 2>&1 || fail 'the all-LF commit after the repair was refused'
# write: the four pins, or only the missing ones
P4='*.md text eol=lf
*.sh text eol=lf
checks/** text eol=lf
docker-compose.test.yml text eol=lf'
mkdir "$T/w1" && ( cd "$T/w1" && sh "$CHECKS/eol.sh" write > /dev/null ) || fail 'write failed'
[ "$(cat "$T/w1/.gitattributes")" = "$P4" ] || fail 'write did not make the four pins'
mkdir "$T/w2" && printf '*.md text eol=lf\n*.png binary\n*.sh text eol=lf' > "$T/w2/.gitattributes"
( cd "$T/w2" && sh "$CHECKS/eol.sh" write > /dev/null && sh "$CHECKS/eol.sh" write > /dev/null ) || fail 'write on an existing file failed'
[ "$(cat "$T/w2/.gitattributes")" = "$(printf '*.md text eol=lf\n*.png binary\n*.sh text eol=lf\nchecks/** text eol=lf\ndocker-compose.test.yml text eol=lf')" ] || fail "write did not add only the missing pins: $(cat "$T/w2/.gitattributes")"
# git's conversion: the pins committed, autocrlf true, everything checked out again
sh checks/eol.sh write > /dev/null; printf 'a note\n' > notes.txt; g add -A; VID_ROLE=fix g commit -qm 'the pins' > "$T/out" 2>&1 || fail 'the pins commit was refused'
g config core.autocrlf true; g ls-files -z | xargs -0 rm -f; g checkout -- . || fail 'the checkout failed'
grep -q "$CR" notes.txt || fail 'autocrlf wrote no CR LF into an unpinned file (the case is wrong)'
! grep -rlq "$CR" checks || fail "checks/ holds CR LF after the checkout: $(grep -rl "$CR" checks | head -n 3)"
! grep -q "$CR" PRD.md || fail 'PRD.md was checked out CR LF despite its pin'
stage again; VID_ROLE=fix g commit -qm 'the hook runs' > "$T/out" 2>&1 || fail 'the hook did not run after the checkout'
[ -f .ran/placement ] || fail 'the hook ran no court after the checkout'
printf '# PRD.md\r\nline one\r\nnew\r\nedited by hand\r\n' > PRD.md; g add PRD.md 2>/dev/null
VID_ROLE=fix g commit -qm 'PRD.md by hand' > "$T/out" 2>&1 && fail 'a PRD.md saved CR LF by hand committed under autocrlf'
grep -qxF "$(line PRD.md)" "$T/out" || fail 'the hand-saved PRD.md: no R4 line'
exit 0
