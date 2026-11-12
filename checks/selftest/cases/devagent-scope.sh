#!/bin/sh
# Purpose: selftest case — what DevAgent and the results format may name (v0.26.10.24.1 R1, R2, R7).
# docs/RESULTS-FORMAT.md is titled ViD results format 1, holds the forms of a claim, a pull request's ticket line, the
# decision ask and a started run, and holds no version number but its own name, no .sh name, no .vid/ path, no "refus",
# no "owner" and no section sign; DevAgent's files name no ViD checks script and no .vid/ path; the test author's agent file
# names no product-code path to write; the test manager's rules give a comment in a format's form its role on the second line, and the
# test author is told the setup: word and where the format is; on this line of versions agents/ and skills/ are the base's.
# v0.26.10.24.2 R1, R7: the builder's file holds its Role: and Decisions: lines and its own runs; the test author's its correction line.
# v0.26.10.24.3 R1: the fixer's file names the builder's and its Role: line.
# v0.26.10.24.4: the grader's file reads its pass, names its six checks, runs nothing; the builder's, the test author's and the writer's lines are there; the format says a passed case's children mean nothing.
# Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
R=$CHECKS/..
[ -d "$R/devagent" ] || { echo 'needs devagent/'; exit 77; }
fail() { echo "devagent-scope: $*" >&2; exit 1; }
F=$R/docs/RESULTS-FORMAT.md
[ -f "$F" ] || fail 'no docs/RESULTS-FORMAT.md'
[ "$(head -n 1 "$F")" = '# ViD results format 1' ] || fail 'the format is not titled by its name'
for s in 'vid: claimed' 'ticket: #<n>' 'vid: decide <the head' 'vid: started'; do grep -qF "$s" "$F" || fail "the format lacks: $s"; done
H=$(sed 's/ViD results format 1//g' "$F" | grep -nE '[0-9]+\.[0-9]+' || true); [ -z "$H" ] || fail "a version number: $H"
H=$(grep -nE '\.sh\b|\.vid/|[Rr]efus|[Oo]wner|§' "$F" || true); [ -z "$H" ] || fail "an internal word: $H"
H=$(grep -rnE 'checks/|\.vid/' "$R/devagent" --exclude=README.md || true); [ -z "$H" ] || fail "DevAgent names ViD's checks or records: $H"
# 0.26.10.28.8 (R12): the dev side's verb is DevAgent's too, though it lives under skills/; missing, it fails
V=$R/skills/vid-devagent/SKILL.md; [ ! -d "$R/skills" ] || { [ -f "$V" ] || fail 'no skills/vid-devagent/SKILL.md'; H=$(grep -nE 'checks/|\.vid/' "$V" || true); [ -z "$H" ] || fail "the dev side's verb names ViD's checks or records: $H"; }
for c in "$CHECKS"/*.sh; do n=${c##*/}; [ "$n" != run.sh ] || continue
  H=$(grep -rnF "$n" "$R/devagent" --exclude=README.md || true); [ -z "$H" ] || fail "DevAgent names $n: $H"; done
H=$(grep -nE '(^|[ `(])(app|src|lib|product|server)/' "$R/devagent/agents/test-author.md" || true); [ -z "$H" ] || fail "a product-code path: $H"
grep -qF 'on the second, `by: <label>`' "$R/devagent/test-manager/SKILL.md" || fail 'a comment in a form of the format has no way to name its role'
grep -q 'beginning `setup:`' "$R/devagent/agents/test-author.md" && grep -qF docs/RESULTS-FORMAT.md "$R/devagent/agents/test-author.md" || fail 'the test author is not told the setup: word'
for l in 'Role: BU' 'Decisions:' 'never rebase' '--here'; do grep -qF -- "$l" "$R/devagent/agents/builder.md" || fail "the builder's file lacks: $l"; done
grep -q 'correction after the red run.*commit of its own' "$R/devagent/agents/test-author.md" || fail 'the test author has no correction line'
for l in devagent/agents/builder.md 'Role: FX' 'Decisions:'; do grep -qF -- "$l" "$R/devagent/agents/fixer.md" || fail "the fixer's file lacks: $l"; done
for l in skills/vid-verify/passes/grader.md 'You run nothing' 'one commit' '`protection`' 'clause by clause' 'with no row, decision or `stand-in:` line'; do grep -qF -- "$l" "$R/devagent/agents/grader.md" || fail "the grader's file lacks: $l"; done
for l in 'never that it was fixed' "the ticket's Further reading is the index" 'with neither behind it'; do grep -qF -- "$l" "$R/devagent/agents/builder.md" || fail "the builder's file lacks: $l"; done
for l in 'every clause of the row' 'a question, never a decision' 'however it is worded' "the ticket's Further reading is the index"; do grep -qF -- "$l" "$R/devagent/agents/test-author.md" || fail "the test author's file lacks: $l"; done
grep -qF 'A protection row names something that must never happen' "$CHECKS/writer.sh" || fail "the writer's ask lacks its sentence"
! grep -qF 'with no child' "$F" && grep -qF '`system-out`, `system-err` and `properties` may appear' "$F" || fail 'the format still says a passed case has no child'
# v0.26.10.24.7: the dev manager's never-list, its MR line and its once; the test author's requests and difference lines; the builder's; setup's measured:; J12's lines
for l in '**You never:**' 'Role: MR' 'once' 'ticket: accepted' 'known-limits.txt' 'requests-<ticket>.txt' 'route table'; do grep -qF -- "$l" "$R/devagent/agents/dev-manager.md" || fail "the dev manager's file lacks: $l"; done
for l in 'test it' 'note it' 'drop it' 'neither to find problems nor to clear them' 'You read nothing else' 'one reader'; do grep -qF -- "$l" "$R/devagent/agents/second-reviewer.md" || fail "the second reviewer's file lacks: $l"; done
for l in 'requests-<ticket>.txt' 'difference:' 'never by a set flag' 'Provenance: regression' 'outside its table'; do grep -qF -- "$l" "$R/devagent/agents/test-author.md" || fail "the test author's file lacks: $l"; done
grep -qF 'difference:' "$R/devagent/agents/builder.md" || fail "the builder's file lacks difference:"; grep -qF 'measured:' "$R/devagent/test-manager/setup.md" && grep -qF 'no restart policy' "$R/devagent/test-manager/setup.md" || fail "setup.md lacks measured: or a final stop"
grep -qF 'nothing outside the harm the rows name' "$R/devagent/agents/fixer.md" || fail "the fixer's file lacks J12's line"; grep -qF 'another path to the same harm' "$R/devagent/agents/grader.md" || fail "the grader's file lacks J12's line"; grep -qF 'Role: MR' "$R/devagent/test-manager/SKILL.md" || fail "SKILL.md lacks the one merge"
# v0.26.10.25.1 R1: the weak-test split
for l in 'A weak-test line,' 'skips the sort' 'the weak-test lines step 5 took' 'but for a weak-test line'; do grep -qF -- "$l" "$R/devagent/test-manager/SKILL.md" || fail "SKILL.md lacks: $l"; done
grep -qF "a list row's reason in its own break's job note alone excepted" "$R/devagent/agents/dev-manager.md" && grep -qF 'stands apart, and replaces no fault folder' "$F" || fail 'the weak-test split is not in the dev manager or the format'
# v0.26.10.24.8: R1, R3, R4, R7, R11
for l in 'its test could not run' 'never the fixer' "A read door's first use" 'with the Write tool' 'read it back before' '`retested:` line for any row'; do grep -qF -- "$l" "$R/devagent/agents/dev-manager.md" || fail "the dev manager's file lacks: $l"; done
for l in 'every reached row, whatever its red' 'or reads back' 'only adds cases' 'less the rows of `known-limits.txt`'; do grep -qF -- "$l" "$R/devagent/test-manager/SKILL.md" || fail "SKILL.md lacks: $l"; done
grep -qF 'adding a case' "$R/devagent/agents/test-author.md" || fail "the test author's file lacks R11"; for l in 'its test could not run' 'no case of its own passed under the fault' 'A proven fault stands' 'leaves out known-limit rows'; do grep -qF -- "$l" "$F" || fail "the format lacks: $l"; done
# v0.26.10.25.3 R3, R8: the close run, and a question's Question: form in place of a role's prefix
for l in '## A close run' 'req-<n>-<chunk>' 'vid: reported <chunk>-<k>' 'vid: again <chunk>' 'vid: started' 'lost <chunk> <k>' "phase 1's" 'Question:' 'cannot go on without the answer'; do grep -qF -- "$l" "$R/devagent/agents/dev-manager.md" || fail "the dev manager's file lacks: $l"; done
! grep -qF 'Each comment begins with the role that asked' "$R/devagent/agents/dev-manager.md" && ! grep -qF 'begun `TA:`, with no label' "$R/devagent/agents/dev-manager.md" || fail "the dev manager's file keeps a role-prefixed question"
for l in 'req-<issue>-<chunk>-<k>' 'vid: reported <chunk>-<k>' "a pull request's head runs" 'Question:'; do grep -qF -- "$l" "$R/devagent/test-manager/SKILL.md" || fail "SKILL.md lacks: $l"; done
grep -qF 'begins `Question:`' "$R/devagent/agents/test-author.md" || fail "the test author's file has no Question: form"
case $(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$R/.claude-plugin/plugin.json") in
  0.26.10.24.*) ! git -C "$R" cat-file -e 4ad92b0 2> /dev/null || git -C "$R" diff --quiet 4ad92b0 -- agents skills || fail 'agents/ or skills/ changed' ;;
esac
exit 0
