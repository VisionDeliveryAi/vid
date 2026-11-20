#!/bin/sh
# Purpose: selftest case — a draft's dry run runs the hooks the live commit runs (0.26.11.1.4, R5), checks/land.sh on the writer's toy and the
# fake gh. The toy's checks/hooks/pre-commit, a stand-in that refuses a staged PRD.md append with no `review:` line, is committed 100644
# with core.filemode off and executable in the working tree, as on a synced folder where every file reads executable: the live commit
# runs it. The dry run's scratch copy checks it out without the bit, and git skips a hook that is not executable. A draft whose append
# has no `review:` line is refused at the dry run's commits, and no draft is made; the same append with its line is drafted. The stand-in
# also refuses law edited but not staged, as the real hook does: a hook mode the scratch copy reads as changed would refuse every draft. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "land-dryrun-hook-mode: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
# the stand-in hook, committed 100644, then executable in the working tree with the mode not tracked
mkdir -p checks/hooks
cat > checks/hooks/pre-commit <<'EOF'
#!/bin/sh
d=$(git diff --name-only -- checks); [ -z "$d" ] || { echo "stand-in pre-commit: law edited but not staged: $d" >&2; exit 1; }
if git diff --cached -- PRD.md | grep -q '^+### ' && ! git diff --cached -- PRD.md | grep -q '^+review: '; then
  echo 'stand-in pre-commit: an append with no review: line' >&2; exit 1; fi
exit 0
EOF
chmod 644 checks/hooks/pre-commit; g add checks/hooks/pre-commit && g commit -qm 'the stand-in hook' || fail 'the hook was not committed'
[ "$(git ls-files -s checks/hooks/pre-commit | cut -d' ' -f1)" = 100644 ] || fail 'the hook is not recorded 100644'
git config core.filemode false; chmod +x checks/hooks/pre-commit; git config core.hooksPath checks/hooks
[ -z "$(git status --porcelain -- checks)" ] || fail 'the hook reads changed with the mode off'
printf 'none\n' > "$T/rv"
app() { cp PRD.md "$T/prd0"; { cat "$T/prd0"; printf '\n### 2026-11-19 (the self-test)\n\n```vid-prd\n'; grep '^REQ-001 |' "$T/prd0" | sed 's/^REQ-001 |/REQ-001 AMENDED |/; s/arrive in one day/arrive in one day, or one is sent before eight/'; printf '```\n%s' "$1"; } > PRD.md
  ! cmp -s PRD.md "$T/prd0" || fail 'no append'; }
dr() { RC=0; sh "$CHECKS/land.sh" draft --review "$T/rv" --why 'REQ-001 amended' > "$T/out" 2>&1 || RC=$?; }
# no review: line: refused by the hook in the dry run, no draft made
app ''; dr; [ "$RC" != 0 ] || fail 'a draft whose append has no review: line was made: the dry run skipped the hook'
grep -q "the dry run's commits were refused" "$T/out" || fail "the refusal is not the dry run's commit's"
[ -z "$(ls .vid/decide/drafts 2>/dev/null)" ] || fail "a draft folder is left: $(ls .vid/decide/drafts)"
# with its line: drafted
cp "$T/prd0" PRD.md; app "$(printf '\nreview: delta, 0 findings\n')"; dr; [ "$RC" = 0 ] || fail "the same append with its review: line was refused ($RC)"
grep -qx 'draft 1' "$T/out" || fail 'no draft 1'
exit 0
