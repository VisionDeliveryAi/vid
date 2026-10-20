#!/bin/sh
# Purpose: selftest case — where the product runs, recorded by access shape only (v0.26.10.8 spec R4; §5
# hosting-access). Under the real hook with stub courts: ARCHITECTURE.md's ```vid-hosting block (placed before the seam
# table) passes with `access: cli-login <the platform:>`, `access: env <NAME>` and `dns-access: none`; it is refused
# (by=hosting-access) with `access: env <a lowercase token-like word>`, `access: cli-login <another platform>`, and a
# value in place of a shape — for dns-access too. The seam table's readers see the same modules with the block
# present: checks/imports.sh --report prints the same lines with and without it, and a decision labelled with a module
# id passes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"; mkdir -p .vid
fail() { echo "hosting-access: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
hosting() { printf '```vid-hosting\nplatform: toyhost\nregion: eu-west\nstaging: the platform'"'"'s own\nproduction: notes.example.org\nsending: hello@mail.example.org\nspend-cap: 50 USD a month\naccess: %s\ndns-access: %s\nowner-only: create the mail provider account\nproviders: mail live-restricted, payments fake\n```\n' "$1" "$2"; }
table() { printf '| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| app/login | signing in | sessions | `app.login.api` | none |\n| app/notes | notes | notes | `app.notes.api` | none |\n'; }
arch() { { printf '# Architecture\n\n## Where it runs\n\n'; [ -n "$1" ] && hosting "$1" "$2"; printf '\n## Modules\n\n'; table; } > ARCHITECTURE.md; }
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\n```\n' > INVENTORY.md
printf '# DECISIONS\n\n## Log\n\n' > DECISIONS.md
arch '' ''; g add -A && g commit -qm 'the records'
try() { arch "$1" "$2"; g add -A; if sh checks/hooks/pre-commit > "$T/.vid/out" 2>&1; then echo pass; else echo refused; fi; }
[ "$(try 'cli-login toyhost' none)" = pass ] || fail 'cli-login <the platform> with dns-access none was refused'
[ "$(try 'env TOYHOST_TOKEN' 'env DNS_API_TOKEN')" = pass ] || fail 'env <NAME> was refused'
[ "$(try 'env tk_live_8f3k2' none)" = refused ] || fail 'env <a lowercase token-like word> passed'
grep -q 'access: takes cli-login toyhost, env <NAME> or none' "$T/.vid/out" || fail 'the refusal does not name the shapes'
tail -n 1 .vid/hook-times | grep -q ' by=hosting-access ' || fail 'hook-times does not name hosting-access'
[ "$(try 'cli-login otherhost' none)" = refused ] || fail 'cli-login <another platform> passed'
[ "$(try 'tk_live_8f3k2' none)" = refused ] || fail 'a bare value passed'
[ "$(try 'none' 'token abcdef123')" = refused ] || fail 'a value in dns-access passed'
# the seam table's readers, with the block present
cp "$CHECKS/imports.sh" checks/imports.sh
mkdir -p app/login app/notes; printf '# Purpose: notes\nfrom app.login.internal import x\n' > app/notes/n.py; printf '# Purpose: login\n' > app/login/api.py
arch '' ''; sh checks/imports.sh --report . > "$T/without" 2>&1 || true
arch 'cli-login toyhost' none; sh checks/imports.sh --report . > "$T/with" 2>&1 || true
grep -q 'app/notes' "$T/without" || fail "the imports reader found nothing to report: $(cat "$T/without")"
cmp -s "$T/without" "$T/with" || fail 'the imports reader reads differently with the block present'
g add -A; g commit -qm 'the block' --no-verify
cp DECISIONS.md "$T/.vid/dec"; printf -- '- **D-001** notes are private | why: trust | enforced: convention | applies-to: app/notes\n' >> DECISIONS.md; g add -A
sh checks/hooks/pre-commit > "$T/.vid/out" 2>&1 || fail 'a decision labelled with a module id was refused with the block present'
exit 0
