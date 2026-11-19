#!/bin/sh
# Purpose: selftest case — the dev side is DevAgent, by name and by path (0.26.10.28.8, R1). devagent/ holds its 16 files and the example job note (0.26.10.28.8; the deployer's role file, 0.26.11.1.1 R2) and no folder of
# the old name is in the tree; the published set's files name the old folder only on the four lines that keep it (results.sh's three, the
# test-difference record, and the frozen grader.md:5) and the six lines that pin the frozen files to their commits; the two frozen files'
# blobs are those of 00109a8 and aa6e610, proved by id with no history; selftest/shipped lists each devagent-*.sh case and no case of
# the old name; the nine headings of the dev side name DevAgent. The old name is built from two pieces, so no line here matches it.
# Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$(cd "$CHECKS/.." && pwd -P); [ -d "$R/devagent" ] || { echo 'needs devagent/'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "devagent-name: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
O=stand; O=${O}in
# the files, and no folder of the old name
( cd "$R/devagent" && find . -type f | sed 's|^\./||' | LC_ALL=C sort ) > "$T/files"
printf '%s\n' README.md agents/builder.md agents/deployer.md agents/dev-manager.md agents/fixer.md agents/grader.md agents/second-reviewer.md agents/stage-grader.md \
  agents/test-analyst.md agents/test-author.md deployer/deploy.sh dev-manager/dm.sh job-note.example test-manager/SKILL.md test-manager/run.sh \
  test-manager/setup.md test-manager/untouched.sh | LC_ALL=C sort > "$T/want"
cmp -s "$T/files" "$T/want" || { diff "$T/want" "$T/files" > "$T/out" || true; fail 'devagent/ does not hold its 16 files and job-note.example'; }
[ -z "$(find "$R" -path "$R/.git" -prune -o -name "$O" -print -o -name "$O-*" -print | head -n 1)" ] || { find "$R" -path "$R/.git" -prune -o -name "$O*" -print > "$T/out"; fail "a path of the old name is in the tree"; }
# the token in the published set: the four kept lines and the six pin lines alone
SET=$(grep -v '^#' "$R/docs/PUBLISH-SET" | grep -v '^[[:space:]]*$')
printf '%s\n' "$SET" | while IFS= read -r p; do [ -e "$R/$p" ] || continue; ( cd "$R" && find "$p" -type f ); done | grep -v "selftest/cases/devagent-name.sh$" > "$T/set"
( cd "$R" && tr '\n' '\0' < "$T/set" | xargs -0 grep -nI "$O" 2>/dev/null | grep -v "${O}g" ) > "$T/hits" || true
{ grep -v '^checks/results\.sh:' "$T/hits" | grep -v '^devagent/agents/grader\.md:' | grep -vE "^checks/selftest/cases/devagent-(deploy-dm|prod-dm|stage-dm)\.sh:[0-9]+:.*rev-parse (00109a8|aa6e610):$O/agents/" || true; } > "$T/out"
[ ! -s "$T/out" ] || fail "the old name outside its kept lines"
[ "$(grep -c '^checks/results\.sh:' "$T/hits")" = 3 ] && [ "$(grep -c '^devagent/agents/grader\.md:' "$T/hits")" = 1 ] || { cp "$T/hits" "$T/out"; fail 'the kept lines are not results.sh three and grader.md one'; }
# the six pin lines, where their three cases are here (a scoped copy of the suite may leave them out)
if [ -f "$R/checks/selftest/cases/devagent-deploy-dm.sh" ] && [ -f "$R/checks/selftest/cases/devagent-prod-dm.sh" ] && [ -f "$R/checks/selftest/cases/devagent-stage-dm.sh" ]; then
  [ "$(grep -cE "^checks/selftest/cases/devagent-(deploy-dm|prod-dm|stage-dm)\.sh:[0-9]+:.*rev-parse (00109a8|aa6e610):$O/agents/" "$T/hits")" = 6 ] || { cp "$T/hits" "$T/out"; fail 'the six pin lines are not there'; }; fi
# the frozen two, by blob id
[ "$(sed -f "$CHECKS/selftest/fixtures/grader-dp1-r3.sed" "$R/devagent/agents/grader.md" | git hash-object --stdin)" = 01f37dead8eded63140b5fe2ac9e765991b2e9e7 ] || fail "grader.md is not 00109a8's, but for DP-1 R3's two sentences"
[ "$(sed -f "$CHECKS/selftest/fixtures/sr-high1-r3.sed" "$R/devagent/agents/second-reviewer.md" | git hash-object --stdin)" = d31079e4f468d8a2a9afac2858c47201acf6ca27 ] || fail "second-reviewer.md is not aa6e610's, but for 0.26.11.1.3 R3's prove it real"
# shipped
S=$R/checks/selftest/shipped; ! grep -q "^$O-" "$S" || fail "shipped lists a case of the old name"
for c in "$R"/checks/selftest/cases/devagent-*.sh; do grep -qxF "$(basename "$c")" "$S" || fail "shipped does not list $(basename "$c")"; done
# the nine headings
for f in README.md agents/builder.md agents/deployer.md agents/dev-manager.md agents/fixer.md agents/stage-grader.md agents/test-analyst.md agents/test-author.md test-manager/SKILL.md; do
  head -n 1 "$R/devagent/$f" | grep -q '^# .*DevAgent' || fail "devagent/$f's heading does not name DevAgent: $(head -n 1 "$R/devagent/$f")"; done
echo 'devagent-name: ok'
