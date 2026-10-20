#!/bin/sh
# Purpose: selftest case — the commit hook judges a merge by what the merge itself adds (v0.26.10.4 spec R11, F-44;
# §5 merge-main-gate; the spec correction of 2026-10-19: the law-standalone rule too). A scratch repository with
# real courts: after an agent's branch left it, main gains a ledger file (tests/invariants/, a protected path), a
# law commit (a widened vid-placement block in CLAUDE.md) and an ordinary commit; on the branch, `git merge
# --no-commit main` stages all three. Convicts unless pre-commit, without VID_ROLE=fix, allows the merge (each staged
# file is main's own content); refuses it once the merge itself changes that protected file (the protected-path
# rule); refuses it once the merge itself adds a law change and a non-law change (the law-standalone rule); and, the
# control, refuses the same protected file staged with no merge in progress. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "merge-main-gate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
cd "$T"; git init -q
mkdir -p checks app tests/invariants
for c in placement.sh conformance.sh imports.sh inventory.sh design-cite.sh census.sh; do cp "$CHECKS/$c" checks/ 2>/dev/null || true; done
cp "$CHECKS/lawfiles" checks/lawfiles
printf '```vid-placement\napp/\ntests/\n```\n' > CLAUDE.md
printf '```vid-allowed-extensions\n.py .md .sh\n```\n```vid-forbidden\nnothing_forbidden_here\n```\n' > BASELINE.md
printf 'Import court: enforce\n' > ARCHITECTURE.md
printf '# Purpose: the app\n' > app/main.py
g add -A && g commit -qm root
B0=$(git symbolic-ref --short HEAD)
g checkout -q -b agent
printf '# Purpose: the agent'"'"'s work\n' > app/work.py; g add -A && g commit -qm 'agent work'
g checkout -q "$B0"
printf '# Purpose: a ledger test main gained\necho ok\n' > tests/invariants/t_main.sh; g add -A && g commit -qm 'main: a ledger test'
printf '```vid-placement\napp/\ntests/\nlib/\n```\n' > CLAUDE.md; g commit -qam 'main: law — lib/ admitted'
printf '# Purpose: main'"'"'s ordinary work\n' > app/b.py; g add -A && g commit -qm 'main: ordinary work'
g checkout -q agent
g merge -q --no-commit --no-ff "$B0" > /dev/null 2>&1 || fail 'the toy merge did not stage'
git rev-parse -q --verify MERGE_HEAD > /dev/null || fail 'no merge in progress'
for _f in tests/invariants/t_main.sh CLAUDE.md app/b.py; do git diff --cached --name-only | grep -qxF "$_f" || fail "the merge did not stage main's $_f"; done
sh "$CHECKS/hooks/pre-commit" > "$T/out" 2>&1 || fail 'merging a main that brings a protected path, a law commit and an ordinary commit was refused'
printf '# Purpose: a ledger test main gained\necho changed in the merge\n' > tests/invariants/t_main.sh; g add tests/invariants/t_main.sh
if sh "$CHECKS/hooks/pre-commit" > "$T/out" 2>&1; then fail 'a protected path the merge itself changes was allowed'; fi
grep -q 'protected paths staged' "$T/out" || fail 'the refusal is not the protected-path rule'
g checkout -q "$B0" -- tests/invariants/t_main.sh
sh "$CHECKS/hooks/pre-commit" > "$T/out" 2>&1 || fail 'the merge was refused once its own protected edit was undone'
# the merge itself adds a law change and a non-law change: the law-standalone rule, as in any commit
printf '```vid-placement\napp/\ntests/\nlib/\nrogue/\n```\n' > CLAUDE.md; printf '# Purpose: added in the merge\n' > app/c.py; g add CLAUDE.md app/c.py
if sh "$CHECKS/hooks/pre-commit" > "$T/out" 2>&1; then fail 'a merge that itself adds law and non-law was allowed'; fi
grep -q 'this commit changes law and must touch nothing else' "$T/out" || fail 'the refusal is not the law-standalone rule'
grep -q '^    app/b.py$' "$T/out" && fail "the law-standalone rule judged main's own ordinary file"
# the control: the same staged file with no merge in progress
g merge --abort; g checkout -q "$B0" -- tests/invariants/t_main.sh
git rev-parse -q --verify MERGE_HEAD > /dev/null && fail 'the merge was not aborted'
if sh "$CHECKS/hooks/pre-commit" > "$T/out" 2>&1; then fail 'a protected path staged with no merge was allowed'; fi
exit 0
