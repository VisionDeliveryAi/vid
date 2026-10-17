#!/bin/sh
# Purpose: selftest case — every agent role is a ViD agent type (v0.9.7.1 spec 3.1, R1). Convicts unless agents/
# holds exactly builder, fixer, test-author, grader and test-analyst; each file's frontmatter names itself; the
# tools are builder and fixer `Bash, Read, Edit, Write`, test-author the same, grader and test-analyst `Bash, Read,
# Write` — each with the host's hand-back tool and nothing else, never the Skill tool; builder and fixer, and only
# they, preload `vid:vid-build` (skills:) and run in their own worktree (isolation: worktree); every file sets model
# inherit and effort high; and the preloaded skill exists. v0.9.8 (R1): test-author preloads vid:vid-test-writing,
# the craft, and runs in the run's checkout. Plugin repository only (a project has no agents/ of ViD's). Env: CHECKS.
set -eu
A="$CHECKS/../agents"
[ -d "$CHECKS/../skills/vid-build" ] || exit 0
fail() { echo "agent-files: $*" >&2; exit 1; }
[ -d "$A" ] || fail 'no agents/ folder'
[ "$(ls "$A" | sort | tr '\n' ' ')" = 'builder.md fixer.md grader.md test-analyst.md test-author.md ' ] || fail "agents/ holds: $(ls "$A" | tr '\n' ' ')"
fm() { awk 'NR == 1 && $0 == "---" { on = 1; next } on && $0 == "---" { exit } on' "$A/$1.md"; }
key() { fm "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -n 1; }
for r in builder fixer test-author grader test-analyst; do
  [ "$(key $r name)" = "$r" ] || fail "$r.md does not name itself"
  [ -n "$(key $r description)" ] || fail "$r.md has no description"
  case $r in builder|fixer|test-author) want='Bash, Read, Edit, Write, SubagentHandback' ;; *) want='Bash, Read, Write, SubagentHandback' ;; esac
  [ "$(key $r tools)" = "$want" ] || fail "$r.md tools are '$(key $r tools)', not '$want'"
  fm $r | grep -q 'Skill\b\|Skill,' && fail "$r.md lists the Skill tool"
  # today's values (3.1): the run's model, effort high — the effort live builders ran at; `.vid/budget` overrides per role
  [ "$(key $r model)" = inherit ] || fail "$r.md model is '$(key $r model)', not inherit (the run's model)"
  [ "$(key $r effort)" = high ] || fail "$r.md effort is '$(key $r effort)', not high (rehearsal R-1: without it an agent takes its session's effort)"
  case $r in
    builder|fixer)
      fm $r | grep -qx '  - vid:vid-build' || fail "$r.md does not preload vid:vid-build"
      [ "$(key $r isolation)" = worktree ] || fail "$r.md is not isolated in a worktree" ;;
    test-author)
      [ "$(fm $r | awk '/^skills:/ { on = 1; next } on && /^  - / { print } on && !/^  - / { on = 0 }' | tr '\n' ' ')" = '  - vid:vid-test-writing ' ] || fail "$r.md does not preload vid:vid-test-writing alone"
      fm $r | grep -q '^isolation:' && fail "$r.md is isolated (it keeps its checkout)" ;;
    *)
      fm $r | grep -q '^skills:' && fail "$r.md preloads a skill (its brief quotes its pass)"
      fm $r | grep -q '^isolation:' && fail "$r.md is isolated (it keeps its checkout)" ;;
  esac
done
[ -f "$CHECKS/../skills/vid-build/SKILL.md" ] || fail 'the preloaded skill vid-build is missing'
[ -f "$CHECKS/../skills/vid-test-writing/SKILL.md" ] || fail 'the preloaded skill vid-test-writing is missing'
exit 0
