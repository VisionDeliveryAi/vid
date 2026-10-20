#!/bin/sh
# Purpose: selftest case — init's initial commit holds the full shipped checks/ (v0.26.10.5 amendment 1, R18). A
# repository with no commit, the plugin's whole checks/ copied in as init copies it (the 17 surface-instrument
# fixture pages and styles with no Purpose: line among them), a CLAUDE.md, BASELINE.md and ARCHITECTURE.md, one product file with its
# Purpose: line: the real pre-commit hook, as init's initial commit runs it (VID_ROLE=fix), passes. Then a new
# product file without a Purpose: line is still refused (by=purpose-header). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "init-commit-fixtures: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks" "$T/r/app"; cd "$T/r"; git init -q
cp -R "$CHECKS/." checks/
N=$(git ls-files --others -- checks/selftest/fixtures | while IFS= read -r f; do case "$f" in (*.html|*.css) head -n 15 "$f" | grep -q 'Purpose:' || echo "$f" ;; esac; done | grep -c . || true)
[ "$N" -gt 0 ] || fail 'the copied checks/ holds no fixture without a Purpose: line — the case proves nothing'
printf '# toy\n\n```vid-placement\napp/\n```\n' > CLAUDE.md
FT="zq""xk"   # a forbidden term no shipped file holds (built here, so this file doesn't hold it either)
printf '# toy\n\n```vid-allowed-extensions\n.py .sh .md .yml .txt .html .css .xml .json\n```\n\n```vid-forbidden\n%s\n```\n' "$FT" > BASELINE.md
printf '# toy\n\n| Module | Owns |\n|---|---|\n| app | everything |\n\nImport court: off\n' > ARCHITECTURE.md
printf '# Purpose: the toy product\n' > app/main.py
printf '.vid/\n' > .gitignore
git add -A
VID_ROLE=fix sh checks/hooks/pre-commit > "$T/out" 2>&1 || fail "the initial commit holding the full shipped checks/ ($N fixture files with no Purpose: line) was refused"
git -c user.email=vid@selftest -c user.name=vid commit -qm 'the initial commit' --no-verify
printf 'print(1)\n' > app/other.py; git add app/other.py
if VID_ROLE=fix sh checks/hooks/pre-commit > "$T/out" 2>&1; then fail 'a new product file with no Purpose: line passed'; fi
grep -q "new source file 'app/other.py' has no \"Purpose:\" header" "$T/out" || fail 'the refusal does not name app/other.py'
exit 0
