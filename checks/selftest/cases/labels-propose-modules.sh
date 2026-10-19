#!/bin/sh
# Purpose: selftest case — the labelling pass takes module ids (v0.26.10.2 spec R17c). The labels fixture with an
# ARCHITECTURE.md (app/login; app.audit, a dotted label). Convicts unless `propose`'s brief lists the module ids
# app/login and app/audit among the items a label may name and says a module item goes beside row items, never
# instead; and `apply` writes a sure module item as proposed — beside a rule id, and alone — through both hooks, not
# widened to scope: project, while an id that is no module is still widened. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/labels.sh"
fail() { echo "labels-propose-modules: $*" >&2; cat "$T/.vid/out" >&2 2>/dev/null; exit 1; }
lb_files
printf '# Architecture\n\n| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| app/login | signing in | sessions | `app.login.api` | none |\n| app.audit | the audit trail | audit | `app.audit.api` | all |\n' > ARCHITECTURE.md
g add -A && g commit -qm toy; lb_hooks
sh checks/decisions.sh propose > .vid/out 2>&1 || fail 'propose failed'
B=$(sed -n 's/^propose: [0-9]* decisions → //p' .vid/out); [ -f "$B" ] || fail "no brief: $(cat .vid/out)"
grep -qxF 'Module ids (ARCHITECTURE.md): app/login app/audit' "$B" || fail "the brief does not list the module ids: $(grep -i module "$B")"
grep -q 'beside its row, requirement or screen items, never instead of' "$B" || fail 'the brief does not say a module item goes beside row items'
lb_prop "D-002 $(lb_hash D-002) | applies-to: RULE-001, app/login | sure" "D-003 $(lb_hash D-003) | applies-to: app/audit | sure" "D-006 $(lb_hash D-006) | applies-to: app/nowhere | sure"
sh checks/decisions.sh apply > .vid/out 2>&1 || fail 'apply was refused'
grep -qxF -- '- **D-002** sessions last a day | why: load | enforced: convention | applies-to: RULE-001, app/login' DECISIONS.md || fail "D-002's module item was not written: $(grep D-002 DECISIONS.md)"
grep -qxF -- '- **D-003** one font everywhere | why: brand | enforced: convention | applies-to: app/audit' DECISIONS.md || fail "D-003's module item was not written: $(grep D-003 DECISIONS.md)"
grep -q '^D-006	scope: project	widened: no brief joins on app/nowhere' .vid/decision-labels.applied || fail 'an id that is no module was not widened'
git status --porcelain DECISIONS.md | grep -q . && fail 'the labels were not committed'
exit 0
