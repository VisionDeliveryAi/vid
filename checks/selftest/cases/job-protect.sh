#!/bin/sh
# Purpose: selftest case — a Codex builder's protected paths (v0.9.7.1 spec 3.9, R9; the configuration rehearsal
# R-6 chose). Feeds the plugin's hooks/codex-protect.sh Codex PreToolUse inputs with a protected list (directories
# ending `/`, files). Plugin repository only. Convicts unless it denies a patch updating, adding, deleting or moving
# to a protected path; a redirection into one (relative and absolute under the worktree); mv, cp, sed -i, rm, touch
# and `git checkout … -- <path>` naming one; and an embedded script (-c, a here-document) naming one — and allows
# an ordinary patch and write, a read of a protected file redirected elsewhere, a branch checkout, and a commit;
# and `sh checks/brief.sh protected` prints the set job.sh hands it. Env: CHECKS.
set -eu
H="$CHECKS/../hooks/codex-protect.sh"
[ -f "$H" ] || exit 0
fail() { echo "job-protect: $*" >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
printf 'tests/invariants/\nchecks/\ndesign/\nPRD.md\ndocker-compose.test.yml\n' > "$T/pl"
inp() { printf '{"session_id":"s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"command":"%s"},"cwd":"/w"}' "$1" "$2"; }
deny() { inp "$1" "$2" | sh "$H" "$T/pl" | grep -q '"permissionDecision":"deny"' || fail "not denied ($1): $2"; }
allow() { o=$(inp "$1" "$2" | sh "$H" "$T/pl"); [ -z "$o" ] || fail "denied ($1): $2"; }
deny apply_patch '*** Begin Patch\n*** Update File: PRD.md\n@@\n-a\n+b\n*** End Patch'
deny apply_patch '*** Begin Patch\n*** Add File: tests/invariants/t.py\n+a\n*** End Patch'
deny apply_patch '*** Begin Patch\n*** Delete File: checks/x.sh\n*** End Patch'
deny apply_patch '*** Begin Patch\n*** Update File: lib/a.txt\n*** Move to: design/a.txt\n*** End Patch'
deny Bash 'echo x >> tests/invariants/a.txt'
deny Bash 'echo x > /w/PRD.md'
deny Bash 'mv checks/c.sh checks/d.sh'
deny Bash 'cp lib/a tests/invariants/b'
deny Bash 'sed -i s/a/b/ docker-compose.test.yml'
deny Bash 'rm -f design/x.md'
deny Bash 'touch checks/new.sh'
deny Bash 'git checkout HEAD~1 -- PRD.md'
deny Bash 'sh -c \"echo > PRD.md\"'
deny Bash 'cat <<EOF > x\nPRD.md\nEOF'
allow apply_patch '*** Begin Patch\n*** Add File: lib/x.txt\n+a\n*** End Patch'
allow Bash 'echo ok > lib/new.txt'
allow Bash 'grep x PRD.md > /tmp/o'
allow Bash 'git checkout -b vid/1-builder-1 abc123'
allow Bash 'git add lib/new.txt && git commit -qm work'
allow Bash 'cat checks/test.sh'
mkdir -p "$T/p/checks"; cp "$CHECKS/brief.sh" "$CHECKS/lawfiles" "$T/p/checks/"; cd "$T/p"
sh checks/brief.sh protected > "$T/set"
for p in tests/invariants/ checks/ design/ PRD.md DEPLOYMENT.md DESIGN-BRIEF.md docker-compose.test.yml INVENTORY.md; do grep -qx "$p" "$T/set" || fail "the protected set lacks $p"; done
grep -qx DECISIONS.md "$T/set" && fail 'DECISIONS.md is in the protected set'
exit 0
