#!/bin/sh
# Purpose: selftest case — seams without credentials (v0.9.2 spec 3.10, R15;
# §7.8), the court half. Under an inventory block carrying `grammar: 0.9.2`
# a seam row with `credentials: not-yet` born `probe: owed` convicts at the
# inventory court naming the row; the same row with
# `probe: unreachable-risk(credentials not-yet)` passes; a legacy block
# (no grammar line) is reported, never convicted; and checks/seams.sh
# (unchanged: only `owed` blocks) lets the unreachable-risk seam's client
# code through while still blocking the owed seam's. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
mkdir -p app
inv() { printf '# toy\n```vid-inventory\n%s\nseam | SEAM-002 | mailer | transactional mail | chosen: D-007 | credentials: not-yet | probe: %s | evidence: owed | quirks: none yet | match: mailerlib\n```\n' "$1" "$2" > INVENTORY.md; }
# the conviction
inv 'grammar: 0.9.2' 'owed'
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then echo 'seam-not-yet: a not-yet seam born owed passed under grammar 0.9.2' >&2; exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'GAP  SEAM-002 (mailer) — credentials: not-yet born probe: owed' || exit 1
# the legal shape
inv 'grammar: 0.9.2' 'unreachable-risk(credentials not-yet)'
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || { echo 'seam-not-yet: the unreachable-risk seam was refused' >&2; exit 1; }
# a legacy block is reported, never convicted
inv '' 'owed'
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'SEAM-002' && exit 1
# seams.sh: the unreachable-risk seam's client code lands; the owed seam's does not
inv 'grammar: 0.9.2' 'unreachable-risk(credentials not-yet)'
printf '# Purpose: the mail client, written against the documented contract\nimport mailerlib\n' > app/mail.py
git add -A
sh "$CHECKS/seams.sh" >/dev/null 2>&1 || { echo 'seam-not-yet: seams.sh blocked the unreachable-risk seam client' >&2; exit 1; }
inv 'grammar: 0.9.2' 'owed'
git add -A
if sh "$CHECKS/seams.sh" >/dev/null 2>&1; then exit 1; fi
exit 0
