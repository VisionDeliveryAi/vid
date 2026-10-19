#!/bin/sh
# Purpose: selftest case — module items in a label (v0.26.10.2 spec R17a). Under the real hook with stub courts, from
# the staged INVENTORY.md and ARCHITECTURE.md (app/login; app.audit, a dotted label, so the id app/audit; a second
# table after it, never read): a module id beside a row id passes, a module id alone passes, a module added in the
# same commit passes; an id that is no module and no other item (app/nowhere, and a name only in the second table)
# is refused, named, as today. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"; mkdir -p .vid
fail() { echo "hook-label-module: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
printf '# Inventory\n\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | login | anon | LOGIN/form | x | REQ-001 | owed: prerequisite — later\n```\n' > INVENTORY.md
printf '# Architecture\n\n| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| app/login | signing in | sessions | `app.login.api` | none |\n| app.audit | the audit trail | audit | `app.audit.api` | all |\n\n| Module | Direction |\n|---|---|\n| billing | out |\n' > ARCHITECTURE.md
printf '# DECISIONS\n\n## Log\n\n' > DECISIONS.md
g add -A && g commit -qm 'the records'
try() { cp DECISIONS.md "$T/.vid/dec"; printf -- '- **D-001** sessions last a day | why: support load | enforced: convention | applies-to: %s\n' "$1" >> DECISIONS.md; g add -A
  if sh checks/hooks/pre-commit > "$T/.vid/out" 2>&1; then r=pass; else r=refused; fi
  cp "$T/.vid/dec" DECISIONS.md; g add DECISIONS.md; echo "$r"; }
[ "$(try 'ROW-001, app/login')" = pass ] || fail 'a module id beside a row id was refused'
[ "$(try 'app/audit')" = pass ] || fail 'a dotted module label read as a path was refused'
[ "$(try 'app/nowhere')" = refused ] || fail 'an id that is no module passed'; grep -q 'app/nowhere: not a screen code any INVENTORY row marks, nor a ROW, RULE, REQ or DIF id, nor a module id' "$T/.vid/out" || fail 'app/nowhere is not named'
[ "$(try 'ROW-001, billing')" = refused ] || fail 'a name of the second table passed as a module'
cp ARCHITECTURE.md "$T/.vid/arch"; awk '/^\| app\.audit/ { print; print "| app/mail | sending mail | none | `app.mail.api` | none |"; next } { print }' "$T/.vid/arch" > ARCHITECTURE.md
[ "$(try 'app/mail')" = pass ] || fail 'a module staged in the same commit was refused'
cp "$T/.vid/arch" ARCHITECTURE.md; g add ARCHITECTURE.md
[ "$(try 'app/mail')" = refused ] || fail 'a module no longer staged passed'
exit 0
